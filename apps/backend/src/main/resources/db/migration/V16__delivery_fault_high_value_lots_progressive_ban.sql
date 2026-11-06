-- Ai gây giao thất bại (BR-3.5 đến BR-3.7), cọc lô cao giá (BR-5.6), cấm đấu giá luỹ tiến (BR-6.4).
ALTER TABLE orders ADD COLUMN delivery_fault VARCHAR(10) CHECK (delivery_fault IN ('BUYER', 'CARRIER', 'SHOP'));

ALTER TABLE users ADD COLUMN auction_strikes INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN auction_last_strike_at TIMESTAMPTZ;

INSERT INTO system_configs (key, value, description) VALUES
    ('auction.high_value_lot_threshold',   '10000000', 'Lô có ước tính cao từ mức này là lô cao giá, cần cọc thêm (BR-5.6)'),
    ('auction.high_value_deposit_percent', '10',       'Lô cao giá: tổng cọc phải ≥ cọc phiên + bấy nhiêu % mức thấp ước tính (BR-5.6)'),
    ('auction.ban_days_repeat',            '365',      'Cấm đấu giá lần thứ 2 trong 12 tháng (lần 3 cấm vĩnh viễn, BR-6.4)');
