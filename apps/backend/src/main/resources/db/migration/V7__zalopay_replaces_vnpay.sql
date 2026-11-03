-- Cổng thanh toán đổi từ VNPay sang ZaloPay (2026-11-04). Dữ liệu cũ ghi VNPAY được đổi sang ZALOPAY.
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_method_check;
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;

UPDATE payments SET method = 'ZALOPAY' WHERE method = 'VNPAY';
UPDATE orders SET payment_method = 'ZALOPAY' WHERE payment_method = 'VNPAY';

ALTER TABLE payments ADD CONSTRAINT payments_method_check CHECK (method IN ('COD', 'WALLET', 'ZALOPAY'));
ALTER TABLE orders ADD CONSTRAINT orders_payment_method_check CHECK (payment_method IN ('COD', 'WALLET', 'ZALOPAY'));

-- Mã đơn phía ZaloPay (app_trans_id, dạng yyMMdd_<mã thanh toán>), để truy vấn / đối chiếu callback.
ALTER TABLE payments ADD COLUMN gateway_ref VARCHAR(40) UNIQUE;
