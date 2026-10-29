-- Ví của sàn (user_id NULL) nhận phí, hoa hồng, tiền cọc bị thu. Trước đây chỉ dữ liệu mẫu tạo ví này,
-- nên chạy không có seed thì mọi giao dịch ghi vào ví sàn đều lỗi "Không tìm thấy ví".
INSERT INTO wallets (user_id, available_balance, held_balance)
SELECT NULL, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM wallets WHERE user_id IS NULL);
