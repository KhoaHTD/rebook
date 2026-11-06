-- Lý do trả hàng mới: người mua không nhận được sách (đơn bị coi là đã giao). Đồng ý là hoàn tiền ngay, không chờ gửi trả.
ALTER TABLE return_requests DROP CONSTRAINT IF EXISTS return_requests_reason_check;
ALTER TABLE return_requests ADD CONSTRAINT return_requests_reason_check
    CHECK (reason IN ('WRONG_CONDITION', 'MISSING_PAGES', 'WRONG_EDITION', 'OTHER_NOT_AS_DESCRIBED', 'NOT_RECEIVED'));
