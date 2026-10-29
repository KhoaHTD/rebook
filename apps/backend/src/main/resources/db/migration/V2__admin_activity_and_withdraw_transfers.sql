-- Nhật ký thao tác của Admin (duyệt tin, duyệt rút tiền, khoá tài khoản, đổi cấu hình...)
CREATE TABLE admin_activity_logs (
    id          BIGSERIAL PRIMARY KEY,
    admin_id    BIGINT       NOT NULL REFERENCES users (id),
    action      VARCHAR(40)  NOT NULL,
    target_type VARCHAR(30)  NOT NULL,
    target_id   VARCHAR(60),
    summary     VARCHAR(500) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_admin_logs_created ON admin_activity_logs (created_at DESC);
CREATE INDEX idx_admin_logs_target ON admin_activity_logs (target_type, target_id);
CREATE INDEX idx_admin_logs_admin ON admin_activity_logs (admin_id);

-- Biên lai chuyển khoản thủ công khi Admin duyệt một yêu cầu rút tiền (mỗi yêu cầu tối đa một biên lai)
CREATE TABLE withdraw_transfers (
    id              BIGSERIAL PRIMARY KEY,
    withdraw_id     BIGINT         NOT NULL UNIQUE REFERENCES withdraw_requests (id),
    admin_id        BIGINT         NOT NULL REFERENCES users (id),
    sender_name     VARCHAR(120)   NOT NULL,
    transfer_time   TIMESTAMPTZ    NOT NULL,
    amount          NUMERIC(15, 0) NOT NULL CHECK (amount > 0),
    proof_image_url VARCHAR(500)   NOT NULL,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now()
);
