-- Hạn xử lý đơn của shop và điểm uy tín (2026-11-06). Chỉ thêm.
-- Đơn PREPARING phải giao cho vận chuyển trong hạn; yêu cầu huỷ của người mua phải được trả lời trong hạn;
-- shop uy tín mà tỷ lệ đơn lỗi do shop vượt ngưỡng thì bị gỡ uy tín (mất quyền tự duyệt tin).

INSERT INTO system_configs (key, value, description) VALUES
    ('order.ship_deadline_days',      '3',  'Số ngày shop phải giao đơn cho vận chuyển sau khi xác nhận, quá hạn thì tự huỷ và hoàn tiền'),
    ('order.cancel_response_hours',   '24', 'Số giờ shop phải trả lời yêu cầu huỷ của người mua, quá hạn thì tự đồng ý huỷ'),
    ('shop.fault_rate_percent',       '10', 'Tỷ lệ đơn lỗi do shop (huỷ, trễ xác nhận, không giao) trong khoảng theo dõi để gỡ uy tín shop (%)'),
    ('shop.fault_min_orders',         '5',  'Số đơn tối thiểu trong khoảng theo dõi mới xét gỡ uy tín shop'),
    ('shop.reputation_window_days',   '90', 'Khoảng ngày tính điểm uy tín shop')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE orders ADD COLUMN ship_due_at          TIMESTAMPTZ;                    -- hạn giao cho vận chuyển (đơn PREPARING)
ALTER TABLE orders ADD COLUMN cancel_requested_at  TIMESTAMPTZ;                    -- lúc người mua gửi yêu cầu huỷ
ALTER TABLE orders ADD COLUMN seller_fault         BOOLEAN NOT NULL DEFAULT FALSE; -- đơn hỏng do lỗi của shop (tính điểm uy tín)

-- Đơn đang chuẩn bị từ trước migration: tính hạn từ lúc này, không phạt oan
UPDATE orders SET ship_due_at = now() + interval '3 days' WHERE status = 'PREPARING' AND order_type = 'NORMAL';
UPDATE orders SET cancel_requested_at = now() WHERE cancel_requested;

CREATE INDEX idx_orders_ship_due ON orders (ship_due_at) WHERE status = 'PREPARING';
CREATE INDEX idx_orders_shop_created ON orders (shop_id, created_at DESC);
