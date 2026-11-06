-- Đợt luật nghiệp vụ theo docs/SRS_BO_SUNG_NGHIEP_VU.md (nhóm 1 và nhóm 4).

-- Cấu hình mới. Môi trường demo / dev đặt hai khoá lịch bằng 0 (db/seed/V13_1).
INSERT INTO system_configs (key, value, description) VALUES
    ('auction.min_publish_lead_hours',         '72',      'Catalogue phải công bố ít nhất bao nhiêu giờ trước giờ mở phiên (BR-5.1)'),
    ('auction.min_registration_close_hours',   '24',      'Hạn đăng ký phải trước giờ mở phiên ít nhất bao nhiêu giờ (BR-5.2)'),
    ('warehouse.compensation_cap_uninspected', '2000000', 'Bồi thường tối đa khi kho làm mất / hỏng sách chưa kiểm định (BR-4.2)'),
    ('warehouse.compensation_buyer_percent',   '10',      'Bồi thường thêm cho người thắng đã thanh toán, % giá búa (BR-4.2)')
ON CONFLICT (key) DO NOTHING;

-- BR-6.1: cọc / phạt của người bỏ thanh toán về sàn 100% (sàn bù chênh cho người bán khi bán lại thấp hơn, BR-6.2)
UPDATE system_configs SET value = '0' WHERE key = 'auction.forfeit_seller_percent';

-- BR-5.3: điều khoản chốt vào phiên lúc công bố
ALTER TABLE auction_sessions ADD COLUMN buyer_premium_percent NUMERIC(5, 2);
ALTER TABLE auction_sessions ADD COLUMN bid_increment_tiers   VARCHAR(500);
ALTER TABLE auction_sessions ADD COLUMN bid_limit_multiplier  INT;

-- BR-6.2: giá búa bị bỏ và phần cọc bị thu sàn giữ, theo lô
ALTER TABLE lots ADD COLUMN defaulted_hammer        NUMERIC(15, 0);
ALTER TABLE lots ADD COLUMN forfeited_platform_take NUMERIC(15, 0) NOT NULL DEFAULT 0;

-- BR-4.2: kho làm mất sách
ALTER TABLE lots DROP CONSTRAINT IF EXISTS lots_status_check;
ALTER TABLE lots ADD CONSTRAINT lots_status_check
    CHECK (status IN ('READY', 'SCHEDULED', 'OPEN', 'SOLD', 'UNSOLD', 'PAID', 'COMPLETED',
                      'CANCELLED', 'RETURNED', 'CONVERTED', 'INSPECTING', 'LOST'));
ALTER TABLE consignments DROP CONSTRAINT IF EXISTS consignments_status_check;
ALTER TABLE consignments ADD CONSTRAINT consignments_status_check
    CHECK (status IN ('SUBMITTED', 'APPROVED', 'REJECTED', 'APPOINTMENT_BOOKED', 'EXPIRED',
                      'RECEIVED', 'INSPECTION_FAILED', 'AWAITING_SELLER', 'ACCEPTED',
                      'WITHDRAWN', 'RETURNED', 'LOST'));
ALTER TABLE warehouse_items DROP CONSTRAINT IF EXISTS warehouse_items_status_check;
ALTER TABLE warehouse_items ADD CONSTRAINT warehouse_items_status_check
    CHECK (status IN ('IN_STOCK', 'RESERVED', 'SHIPPED', 'RETURNED', 'LOST'));
-- Sách bị kho làm hỏng trả lại người bán: không tính phí lưu kho
ALTER TABLE warehouse_items ADD COLUMN storage_fee_waived BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;
ALTER TABLE wallet_transactions ADD CONSTRAINT wallet_transactions_type_check
    CHECK (type IN ('TOP_UP', 'PAYMENT', 'REFUND', 'DEPOSIT_HOLD', 'DEPOSIT_RELEASE', 'DEPOSIT_FORFEIT',
                    'SALE_PENDING', 'SALE_RELEASE', 'FEE', 'WITHDRAW', 'COD_RECEIPT', 'COD_PAYOUT', 'AUCTION_PENALTY',
                    'COMPENSATION'));

-- Sự cố kho: Staff khai báo, Admin duyệt rồi mới chi bồi thường (BR-4.8)
CREATE TABLE warehouse_incidents (
    id                BIGSERIAL PRIMARY KEY,
    warehouse_item_id BIGINT         NOT NULL REFERENCES warehouse_items (id),
    consignment_id    BIGINT         NOT NULL REFERENCES consignments (id),
    type              VARCHAR(10)    NOT NULL CHECK (type IN ('LOST', 'DAMAGED')),
    description       VARCHAR(2000)  NOT NULL,
    images            JSONB          NOT NULL DEFAULT '[]',
    reported_by       BIGINT         NOT NULL REFERENCES users (id),
    status            VARCHAR(10)    NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    stage             VARCHAR(20)    CHECK (stage IN ('UNINSPECTED', 'INSPECTED', 'SOLD_PAID')),
    base_amount       NUMERIC(15, 0),
    seller_percent    INT            CHECK (seller_percent BETWEEN 0 AND 100),
    seller_amount     NUMERIC(15, 0),
    buyer_id          BIGINT         REFERENCES users (id),
    buyer_amount      NUMERIC(15, 0),
    order_id          BIGINT         REFERENCES orders (id),
    decided_by        BIGINT         REFERENCES users (id),
    decided_at        TIMESTAMPTZ,
    decision_note     VARCHAR(1000),
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_warehouse_incidents_status ON warehouse_incidents (status, created_at);
-- Mỗi cuốn chỉ một sự cố đang chờ duyệt
CREATE UNIQUE INDEX uq_warehouse_incidents_pending ON warehouse_incidents (warehouse_item_id) WHERE status = 'PENDING';

-- BR-2.3: ISBN lưu dạng 13 số, bỏ dấu gạch / khoảng trắng; ISBN-10 đổi sang ISBN-13
UPDATE books SET isbn = NULLIF(upper(regexp_replace(isbn, '[^0-9Xx]', '', 'g')), '') WHERE isbn IS NOT NULL;
UPDATE books b
SET isbn = x.p || ((10 - (SELECT sum(substr(x.p, i, 1)::int * CASE WHEN i % 2 = 1 THEN 1 ELSE 3 END)
                          FROM generate_series(1, 12) AS i) % 10) % 10)::text
FROM (SELECT id, '978' || substr(isbn, 1, 9) AS p FROM books WHERE isbn ~ '^[0-9]{9}[0-9X]$') x
WHERE b.id = x.id;
