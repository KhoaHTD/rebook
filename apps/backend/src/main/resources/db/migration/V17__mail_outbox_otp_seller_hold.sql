-- Gửi mail và các luật đi kèm (docs/ra-soat-nghiep-vu/THIET_KE_GUI_MAIL.md). Chỉ thêm.

-- 1. Chặn đăng ký lại bằng biến thể của cùng hộp thư (a.b+1@gmail.com = ab@gmail.com).
--    Phải khớp AuthService.normalizeEmail. Hai tài khoản cũ trùng dạng chuẩn thì migration này dừng: gộp tay trước.
ALTER TABLE users ADD COLUMN email_normalized VARCHAR(255) GENERATED ALWAYS AS (
    CASE WHEN split_part(lower(email), '@', 2) IN ('gmail.com', 'googlemail.com')
         THEN replace(split_part(split_part(lower(email), '@', 1), '+', 1), '.', '') || '@gmail.com'
         ELSE split_part(split_part(lower(email), '@', 1), '+', 1) || '@' || split_part(lower(email), '@', 2)
    END) STORED;
CREATE UNIQUE INDEX uq_users_email_normalized ON users (email_normalized);

-- 2. Hàng đợi mail: ghi cùng giao dịch với thông báo, job gửi sau và thử lại
CREATE TABLE email_outbox (
    id              BIGSERIAL PRIMARY KEY,
    notification_id BIGINT       REFERENCES notifications (id) ON DELETE SET NULL,
    user_id         BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    to_email        VARCHAR(255) NOT NULL,
    subject         VARCHAR(255) NOT NULL,
    body            TEXT         NOT NULL,
    status          VARCHAR(10)  NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
    attempts        INT          NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    last_error      VARCHAR(500),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    sent_at         TIMESTAMPTZ
);
CREATE INDEX idx_email_outbox_due ON email_outbox (next_attempt_at) WHERE status = 'PENDING';
CREATE INDEX idx_email_outbox_notification ON email_outbox (notification_id);

-- 3. Hoá đơn đấu giá đã được gia hạn một lần vì người thắng chưa nhận được thông báo
ALTER TABLE orders ADD COLUMN notice_extended BOOLEAN NOT NULL DEFAULT FALSE;

-- 4. Nợ do ngân hàng đòi lại tiền nạp (chargeback), Admin ghi tay
ALTER TABLE account_debts DROP CONSTRAINT IF EXISTS account_debts_type_check;
ALTER TABLE account_debts ADD CONSTRAINT account_debts_type_check
    CHECK (type IN ('AUCTION_PENALTY', 'STORAGE_FEE', 'CHARGEBACK'));

-- 5. Giữ tiền bán hàng của shop mới trước khi cho rút (P0 mục 4)
INSERT INTO system_configs (key, value, description) VALUES
    ('wallet.seller_hold_days',       '7',  'Tiền bán hàng của shop mới chỉ rút được sau bấy nhiêu ngày kể từ khi giải ngân (0 = không giữ)'),
    ('wallet.seller_hold_min_orders', '10', 'Shop có ít hơn bấy nhiêu đơn hoàn tất là shop mới'),
    ('wallet.seller_hold_shop_days',  '30', 'Shop mở chưa đủ bấy nhiêu ngày là shop mới')
ON CONFLICT (key) DO NOTHING;
