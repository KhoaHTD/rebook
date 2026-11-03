-- Admin duyệt / từ chối tin gần nhất và lúc nào.
ALTER TABLE listings
    ADD COLUMN reviewed_by BIGINT REFERENCES users (id),
    ADD COLUMN reviewed_at TIMESTAMPTZ;

-- Ghi chú của người rút tiền (cột note là ghi chú của Admin khi xử lý).
ALTER TABLE withdraw_requests ADD COLUMN user_note VARCHAR(200);
