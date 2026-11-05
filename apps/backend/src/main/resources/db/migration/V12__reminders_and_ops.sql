-- Nhắc trước hạn, địa chỉ nhận hàng trả của kho (2026-11-06). Chỉ thêm.

INSERT INTO system_configs (key, value, description) VALUES
    ('notify.reminder_hours',       '24', 'Nhắc trước hạn bao nhiêu giờ: giao cho vận chuyển, thanh toán lô thắng, quyết định lô không bán'),
    ('shipping.warehouse_address',  'Kho ReBook, TP. Hồ Chí Minh', 'Địa chỉ kho nhận hàng trả của đơn đấu giá (Admin cập nhật địa chỉ chi tiết)')
ON CONFLICT (key) DO NOTHING;

-- Mỗi loại nhắc chỉ gửi một lần
ALTER TABLE orders ADD COLUMN ship_reminder_sent    BOOLEAN NOT NULL DEFAULT FALSE; -- nhắc shop sắp quá hạn giao cho vận chuyển
ALTER TABLE orders ADD COLUMN cancel_reminder_sent  BOOLEAN NOT NULL DEFAULT FALSE; -- nhắc shop trả lời yêu cầu huỷ
ALTER TABLE orders ADD COLUMN payment_reminder_sent BOOLEAN NOT NULL DEFAULT FALSE; -- nhắc người thắng thanh toán hoá đơn lô
ALTER TABLE lots   ADD COLUMN decision_reminder_sent BOOLEAN NOT NULL DEFAULT FALSE; -- nhắc người bán chọn hướng xử lý lô không bán

CREATE INDEX idx_orders_cod_in_transit ON orders (shipped_at) WHERE status = 'SHIPPING' AND payment_method = 'COD';
