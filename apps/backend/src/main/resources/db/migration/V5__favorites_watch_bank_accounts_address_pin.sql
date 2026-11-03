-- Sách yêu thích (thả tim một tin bán).
CREATE TABLE listing_favorites (
    user_id    BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    listing_id BIGINT      NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, listing_id)
);

-- Theo dõi cả phiên đấu giá (phiên yêu thích), khác với lot_watchers theo dõi từng lô.
CREATE TABLE session_watchers (
    user_id    BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    session_id BIGINT      NOT NULL REFERENCES auction_sessions (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, session_id)
);

-- Tài khoản ngân hàng đã dùng để rút tiền; lưu / cập nhật mỗi lần tạo yêu cầu rút.
CREATE TABLE bank_accounts (
    id             BIGSERIAL PRIMARY KEY,
    user_id        BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    bank_name      VARCHAR(100) NOT NULL,
    account_number VARCHAR(30)  NOT NULL,
    account_holder VARCHAR(120) NOT NULL,
    favorite       BOOLEAN      NOT NULL DEFAULT FALSE,
    last_used_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (user_id, bank_name, account_number)
);

-- Địa chỉ: ghim bản đồ + loại (nhà riêng / văn phòng).
ALTER TABLE addresses
    ADD COLUMN latitude     DOUBLE PRECISION CHECK (latitude BETWEEN -90 AND 90),
    ADD COLUMN longitude    DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180),
    ADD COLUMN address_type VARCHAR(10) NOT NULL DEFAULT 'HOME' CHECK (address_type IN ('HOME', 'OFFICE'));

-- Thời điểm Admin phân xử yêu cầu trả hàng (resolved_by đã có).
ALTER TABLE return_requests ADD COLUMN resolved_at TIMESTAMPTZ;
UPDATE return_requests SET resolved_at = updated_at WHERE resolved_by IS NOT NULL;
