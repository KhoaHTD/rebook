-- Dữ liệu mẫu cũ chỉ có 1 cuốn mỗi tin nên không thử được mua nhiều cuốn / mua nhiều shop.
-- Tăng tồn kho các tin đang bán của cả hai shop.
UPDATE listings SET stock = 5 WHERE id IN (1, 2, 3, 5, 7) AND status = 'ACTIVE';
UPDATE listings SET stock = 8 WHERE id = 4 AND status = 'ACTIVE';
UPDATE listings SET stock = 3 WHERE id IN (6, 8) AND status = 'ACTIVE';
