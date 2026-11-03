-- Link trang thanh toán ZaloPay (order_url), để app mở lại khi trình duyệt chặn tab mới hoặc người dùng lỡ đóng.
ALTER TABLE payments ADD COLUMN payment_url VARCHAR(500);
