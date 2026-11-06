-- Luồng tiền (2026-11-05): COD đối soát với hãng vận chuyển, khoá tiền mới nạp, trả hàng theo bước,
-- chụp tỷ lệ phí lúc chốt, xác nhận giao hàng, nhật ký sự kiện. Chỉ thêm, không sửa dữ liệu cũ (trừ backfill shipped_at).

-- 1. Cấu hình mới (Admin sửa được)
INSERT INTO system_configs (key, value, description) VALUES
    ('order.cod_max_amount',          '3000000',  'Giá trị tối đa một lần đặt COD (đ)'),
    ('order.cod_new_buyer_max_amount', '500000',  'Giá trị tối đa một lần đặt COD của người chưa có đơn hoàn tất (đ)'),
    ('order.cod_max_failures',        '2',        'Số đơn COD giao thất bại trong khoảng theo dõi thì bị chặn đặt COD'),
    ('order.cod_failure_window_days', '90',       'Khoảng ngày tính đơn COD giao thất bại'),
    ('order.auto_deliver_days',       '7',        'Số ngày sau khi giao cho vận chuyển mà người mua không xác nhận thì tự coi là đã giao'),
    ('order.return_ship_days',        '7',        'Số ngày người mua phải gửi trả hàng sau khi được đồng ý trả, quá hạn thì đơn hoàn tất'),
    ('order.return_confirm_days',     '7',        'Số ngày shop (hoặc kho) phải xác nhận đã nhận hàng trả, quá hạn thì chuyển Admin'),
    ('wallet.topup_hold_hours',       '24',       'Số giờ tiền mới nạp chưa được rút (0 = không khoá)'),
    ('wallet.withdraw_daily_limit',   '20000000', 'Tổng tiền một người được yêu cầu rút trong một ngày (đ)')
ON CONFLICT (key) DO NOTHING;

-- 2. Loại giao dịch ví mới: sàn nhận tiền COD từ hãng vận chuyển, sàn trả tiền COD cho shop
ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;
ALTER TABLE wallet_transactions ADD CONSTRAINT wallet_transactions_type_check
    CHECK (type IN ('TOP_UP', 'PAYMENT', 'REFUND', 'DEPOSIT_HOLD', 'DEPOSIT_RELEASE', 'DEPOSIT_FORFEIT',
                    'SALE_PENDING', 'SALE_RELEASE', 'FEE', 'WITHDRAW', 'COD_RECEIPT', 'COD_PAYOUT'));

-- 3. Đơn hàng
ALTER TABLE orders ADD COLUMN shipped_at         TIMESTAMPTZ;          -- lúc giao cho vận chuyển (mốc tự coi là đã giao)
ALTER TABLE orders ADD COLUMN fee_percent        NUMERIC(5, 2);        -- phí sàn chụp lúc đặt, NULL = đơn cũ dùng cấu hình hiện tại
ALTER TABLE orders ADD COLUMN cod_remitted_at    TIMESTAMPTZ;          -- sàn đã nhận tiền COD đối soát từ hãng vận chuyển
ALTER TABLE orders ADD COLUMN cod_paid_out_at    TIMESTAMPTZ;          -- đã trả tiền COD cho shop
ALTER TABLE orders ADD COLUMN cod_refund_pending BOOLEAN NOT NULL DEFAULT FALSE; -- trả hàng COD đang chờ sàn nhận tiền đối soát
CREATE INDEX idx_orders_shipped ON orders (shipped_at) WHERE status = 'SHIPPING';
CREATE INDEX idx_orders_cod_open ON orders (status) WHERE payment_method = 'COD' AND cod_remitted_at IS NULL;

UPDATE orders SET shipped_at = (SELECT max(h.created_at) FROM order_status_history h
                                WHERE h.order_id = orders.id AND h.to_status = 'SHIPPING')
 WHERE status IN ('SHIPPING', 'DELIVERED', 'RETURN_REQUESTED', 'COMPLETED', 'RETURNED', 'FAILED_DELIVERY');

-- 4. Lô đấu giá: hoa hồng chụp lúc người bán chấp nhận hợp đồng ký gửi
ALTER TABLE lots ADD COLUMN commission_percent NUMERIC(5, 2);

-- 5. Trả hàng theo bước: được đồng ý -> người mua gửi trả -> shop/kho xác nhận đã nhận -> hoàn tiền
ALTER TABLE return_requests DROP CONSTRAINT IF EXISTS return_requests_status_check;
ALTER TABLE return_requests ADD CONSTRAINT return_requests_status_check
    CHECK (status IN ('PENDING', 'APPROVED', 'DISPUTED', 'REJECTED', 'AWAITING_GOODS', 'EXPIRED'));
ALTER TABLE return_requests ADD COLUMN approved_at          TIMESTAMPTZ;
ALTER TABLE return_requests ADD COLUMN return_tracking_code VARCHAR(50);
ALTER TABLE return_requests ADD COLUMN return_shipped_at    TIMESTAMPTZ;
ALTER TABLE return_requests ADD COLUMN return_received_at   TIMESTAMPTZ;

-- 6. Rút tiền: ghi số tiền mới nạp đang bị khoá lúc yêu cầu để Admin thấy nguồn tiền
ALTER TABLE withdraw_requests ADD COLUMN topup_locked NUMERIC(15, 0) NOT NULL DEFAULT 0;

-- 7. Nhật ký sự kiện (docs/LOGGING_DESIGN.md): chỉ thêm, không sửa, không xoá
CREATE TABLE audit_events (
    id          BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    event_code  VARCHAR(60)  NOT NULL,
    category    VARCHAR(10)  NOT NULL CHECK (category IN ('BUSINESS', 'SECURITY', 'FINANCE', 'SYSTEM')),
    result      VARCHAR(10)  NOT NULL CHECK (result IN ('SUCCESS', 'DENIED', 'FAILED')),
    reason_code VARCHAR(60),
    actor_type  VARCHAR(10)  NOT NULL CHECK (actor_type IN ('USER', 'STAFF', 'ADMIN', 'SYSTEM', 'GATEWAY')),
    actor_id    BIGINT,
    actor_role  VARCHAR(10),
    target_type VARCHAR(30),
    target_id   VARCHAR(60),
    ref_code    VARCHAR(60),
    request_id  VARCHAR(40),
    channel     VARCHAR(10)  NOT NULL DEFAULT 'API' CHECK (channel IN ('API', 'JOB', 'WS', 'CALLBACK')),
    ip          VARCHAR(45),
    summary     VARCHAR(500),
    details     JSONB
);
CREATE INDEX idx_audit_events_time   ON audit_events (occurred_at DESC);
CREATE INDEX idx_audit_events_code   ON audit_events (event_code, occurred_at DESC);
CREATE INDEX idx_audit_events_target ON audit_events (target_type, target_id);
CREATE INDEX idx_audit_events_actor  ON audit_events (actor_id, occurred_at DESC);
CREATE INDEX idx_audit_events_ref    ON audit_events (ref_code);
