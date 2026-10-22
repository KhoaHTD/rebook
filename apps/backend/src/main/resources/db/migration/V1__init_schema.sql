-- =====================================================================
-- ReBook — schema khởi tạo
-- Tiền VNĐ: NUMERIC(15,0). Thời gian: TIMESTAMPTZ.
-- Trạng thái: VARCHAR + CHECK, khớp với enum trong code Java.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Người dùng
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id                   BIGSERIAL PRIMARY KEY,
    email                VARCHAR(255) NOT NULL UNIQUE,
    phone                VARCHAR(20) UNIQUE,
    password_hash        VARCHAR(100) NOT NULL,
    full_name            VARCHAR(120) NOT NULL,
    avatar_url           VARCHAR(500),
    role                 VARCHAR(20)  NOT NULL DEFAULT 'USER'
        CHECK (role IN ('USER', 'STAFF', 'ADMIN')),
    status               VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'LOCKED')),
    email_verified       BOOLEAN      NOT NULL DEFAULT FALSE,
    phone_verified       BOOLEAN      NOT NULL DEFAULT FALSE,
    auction_banned_until TIMESTAMPTZ,
    lock_reason          VARCHAR(500),
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(100) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ  NOT NULL,
    revoked    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);

CREATE TABLE otp_codes (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    purpose    VARCHAR(30) NOT NULL
        CHECK (purpose IN ('VERIFY_EMAIL', 'VERIFY_PHONE', 'RESET_PASSWORD')),
    code       VARCHAR(10) NOT NULL,
    attempts   INT         NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_otp_user_purpose ON otp_codes (user_id, purpose);

CREATE TABLE shops (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT       NOT NULL UNIQUE REFERENCES users (id),
    name                VARCHAR(120) NOT NULL UNIQUE,
    description         TEXT,
    pickup_address      VARCHAR(500) NOT NULL,
    pickup_province     VARCHAR(100) NOT NULL,
    bank_name           VARCHAR(100) NOT NULL,
    bank_account_number VARCHAR(50)  NOT NULL,
    bank_account_holder VARCHAR(120) NOT NULL,
    rating_avg          NUMERIC(3, 2) NOT NULL DEFAULT 0,
    rating_count        INT          NOT NULL DEFAULT 0,
    trusted             BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    receiver_name VARCHAR(120) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    province      VARCHAR(100) NOT NULL,
    district      VARCHAR(100) NOT NULL,
    ward          VARCHAR(100) NOT NULL,
    detail        VARCHAR(300) NOT NULL,
    is_default    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_addresses_user ON addresses (user_id);

-- ---------------------------------------------------------------------
-- 2. Sách & mua bán giá cố định
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    slug       VARCHAR(120) NOT NULL UNIQUE,
    parent_id  BIGINT REFERENCES categories (id),
    sort_order INT          NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Book tách khỏi Listing / Lot: một cuốn đấu giá không bán được
-- có thể chuyển sang bán giá cố định mà không nhập lại.
CREATE TABLE books (
    id              BIGSERIAL PRIMARY KEY,
    owner_id        BIGINT       NOT NULL REFERENCES users (id),
    title           VARCHAR(300) NOT NULL,
    author          VARCHAR(200) NOT NULL,
    publisher       VARCHAR(200),
    publish_year    INT,
    isbn            VARCHAR(20),
    language        VARCHAR(50)  NOT NULL DEFAULT 'Tiếng Việt',
    pages           INT,
    category_id     BIGINT       NOT NULL REFERENCES categories (id),
    condition_grade VARCHAR(20)  NOT NULL
        CHECK (condition_grade IN ('NEW', 'LIKE_NEW', 'VERY_GOOD', 'GOOD', 'ACCEPTABLE')),
    description     TEXT,
    weight_gram     INT          NOT NULL DEFAULT 300 CHECK (weight_gram > 0),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_books_category ON books (category_id);
CREATE INDEX idx_books_owner ON books (owner_id);

CREATE TABLE book_images (
    id         BIGSERIAL PRIMARY KEY,
    book_id    BIGINT       NOT NULL REFERENCES books (id) ON DELETE CASCADE,
    url        VARCHAR(500) NOT NULL,
    sort_order INT          NOT NULL DEFAULT 0,
    source     VARCHAR(10)  NOT NULL DEFAULT 'SELLER' CHECK (source IN ('SELLER', 'STAFF'))
);
CREATE INDEX idx_book_images_book ON book_images (book_id);

CREATE TABLE listings (
    id            BIGSERIAL PRIMARY KEY,
    book_id       BIGINT         NOT NULL UNIQUE REFERENCES books (id),
    shop_id       BIGINT         NOT NULL REFERENCES shops (id),
    price         NUMERIC(15, 0) NOT NULL CHECK (price > 0),
    stock         INT            NOT NULL CHECK (stock >= 0),
    sold_count    INT            NOT NULL DEFAULT 0,
    status        VARCHAR(20)    NOT NULL DEFAULT 'PENDING_REVIEW'
        CHECK (status IN ('PENDING_REVIEW', 'ACTIVE', 'OUT_OF_STOCK', 'HIDDEN', 'REJECTED')),
    reject_reason VARCHAR(500),
    version       BIGINT         NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_listings_shop ON listings (shop_id);
CREATE INDEX idx_listings_status ON listings (status);

CREATE TABLE cart_items (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    listing_id BIGINT      NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
    quantity   INT         NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, listing_id)
);

-- ---------------------------------------------------------------------
-- 3. Ký gửi, kiểm định, kho, đấu giá
-- ---------------------------------------------------------------------
CREATE TABLE consignments (
    id               BIGSERIAL PRIMARY KEY,
    code             VARCHAR(30)    NOT NULL UNIQUE,
    seller_id        BIGINT         NOT NULL REFERENCES users (id),
    book_id          BIGINT         NOT NULL UNIQUE REFERENCES books (id),
    expected_price   NUMERIC(15, 0) NOT NULL CHECK (expected_price > 0),
    provenance       TEXT,
    status           VARCHAR(30)    NOT NULL DEFAULT 'SUBMITTED'
        CHECK (status IN ('SUBMITTED', 'APPROVED', 'REJECTED', 'APPOINTMENT_BOOKED', 'EXPIRED',
                          'RECEIVED', 'INSPECTION_FAILED', 'AWAITING_SELLER', 'ACCEPTED',
                          'WITHDRAWN', 'RETURNED')),
    review_note      VARCHAR(500),
    appointment_at   TIMESTAMPTZ,
    appointment_code VARCHAR(30) UNIQUE,
    approved_at      TIMESTAMPTZ,
    received_at      TIMESTAMPTZ,
    received_by      BIGINT REFERENCES users (id),
    created_at       TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_consignments_seller ON consignments (seller_id);
CREATE INDEX idx_consignments_status ON consignments (status);

CREATE TABLE inspections (
    id                     BIGSERIAL PRIMARY KEY,
    consignment_id         BIGINT      NOT NULL UNIQUE REFERENCES consignments (id),
    inspector_id           BIGINT      NOT NULL REFERENCES users (id),
    result                 VARCHAR(10) NOT NULL CHECK (result IN ('PASS', 'FAIL')),
    checklist              JSONB,
    condition_grade        VARCHAR(20)
        CHECK (condition_grade IN ('NEW', 'LIKE_NEW', 'VERY_GOOD', 'GOOD', 'ACCEPTABLE')),
    condition_report       TEXT        NOT NULL,
    estimate_low           NUMERIC(15, 0),
    estimate_high          NUMERIC(15, 0),
    proposed_start         NUMERIC(15, 0),
    proposed_reserve       NUMERIC(15, 0),
    seller_decision        VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (seller_decision IN ('PENDING', 'ACCEPTED', 'COUNTER', 'WITHDRAWN')),
    seller_counter_reserve NUMERIC(15, 0),
    decided_at             TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE warehouse_items (
    id              BIGSERIAL PRIMARY KEY,
    consignment_id  BIGINT      NOT NULL UNIQUE REFERENCES consignments (id),
    code            VARCHAR(30) NOT NULL UNIQUE,
    shelf_code      VARCHAR(30),
    status          VARCHAR(20) NOT NULL DEFAULT 'IN_STOCK'
        CHECK (status IN ('IN_STOCK', 'RESERVED', 'SHIPPED', 'RETURNED')),
    checked_in_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    checked_out_at  TIMESTAMPTZ,
    checkout_reason VARCHAR(30),
    -- Thời điểm báo người bán đến nhận lại sách (tính phí lưu kho quá hạn từ đây)
    return_notified_at TIMESTAMPTZ,
    storage_fee     NUMERIC(15, 0),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE auction_sessions (
    id                    BIGSERIAL PRIMARY KEY,
    title                 VARCHAR(200)   NOT NULL,
    description           TEXT,
    cover_url             VARCHAR(500),
    start_at              TIMESTAMPTZ    NOT NULL,
    registration_deadline TIMESTAMPTZ    NOT NULL,
    min_participants      INT            NOT NULL DEFAULT 3 CHECK (min_participants > 0),
    deposit_amount        NUMERIC(15, 0) NOT NULL CHECK (deposit_amount >= 0),
    lot_duration_sec      INT            NOT NULL DEFAULT 60,
    soft_close_sec        INT            NOT NULL DEFAULT 15,
    lot_gap_sec           INT            NOT NULL DEFAULT 7,
    status                VARCHAR(20)    NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'POSTPONED', 'CONFIRMED', 'LIVE', 'PAUSED', 'ENDED', 'CANCELLED')),
    current_lot_id        BIGINT,
    next_lot_at           TIMESTAMPTZ,
    paused_remaining_ms   BIGINT,
    postpone_count        INT            NOT NULL DEFAULT 0,
    reminder_sent         BOOLEAN        NOT NULL DEFAULT FALSE,
    published_at          TIMESTAMPTZ,
    started_at            TIMESTAMPTZ,
    ended_at              TIMESTAMPTZ,
    created_by            BIGINT REFERENCES users (id),
    version               BIGINT         NOT NULL DEFAULT 0,
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
    CHECK (registration_deadline <= start_at)
);
CREATE INDEX idx_sessions_status ON auction_sessions (status);

-- reserve_price KHÔNG bao giờ trả ra API công khai.
CREATE TABLE lots (
    id                BIGSERIAL PRIMARY KEY,
    session_id        BIGINT REFERENCES auction_sessions (id),
    consignment_id    BIGINT         NOT NULL UNIQUE REFERENCES consignments (id),
    book_id           BIGINT         NOT NULL REFERENCES books (id),
    lot_number        INT,
    start_price       NUMERIC(15, 0) NOT NULL CHECK (start_price > 0),
    reserve_price     NUMERIC(15, 0) NOT NULL CHECK (reserve_price > 0),
    estimate_low      NUMERIC(15, 0) NOT NULL,
    estimate_high     NUMERIC(15, 0) NOT NULL,
    current_price     NUMERIC(15, 0),
    current_winner_id BIGINT REFERENCES users (id),
    bid_count         INT            NOT NULL DEFAULT 0,
    opened_at         TIMESTAMPTZ,
    ends_at           TIMESTAMPTZ,
    closed_at         TIMESTAMPTZ,
    status            VARCHAR(20)    NOT NULL DEFAULT 'READY'
        CHECK (status IN ('READY', 'SCHEDULED', 'OPEN', 'SOLD', 'UNSOLD', 'PAID', 'COMPLETED',
                          'CANCELLED', 'RETURNED', 'CONVERTED')),
    close_result      VARCHAR(20)
        CHECK (close_result IN ('SOLD', 'RESERVE_NOT_MET', 'NO_BIDS', 'CANCELLED')),
    hammer_price      NUMERIC(15, 0),
    winner_id         BIGINT REFERENCES users (id),
    rounds            INT            NOT NULL DEFAULT 0,
    version           BIGINT         NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
    UNIQUE (session_id, lot_number)
);
CREATE INDEX idx_lots_session ON lots (session_id);
CREATE INDEX idx_lots_status ON lots (status);

ALTER TABLE auction_sessions
    ADD CONSTRAINT fk_sessions_current_lot FOREIGN KEY (current_lot_id) REFERENCES lots (id);

CREATE TABLE auction_registrations (
    id             BIGSERIAL PRIMARY KEY,
    session_id     BIGINT         NOT NULL REFERENCES auction_sessions (id),
    user_id        BIGINT         NOT NULL REFERENCES users (id),
    paddle_number  INT            NOT NULL,
    deposit_amount NUMERIC(15, 0) NOT NULL,
    bid_limit      NUMERIC(15, 0) NOT NULL,
    status         VARCHAR(20)    NOT NULL DEFAULT 'PENDING_DEPOSIT'
        CHECK (status IN ('PENDING_DEPOSIT', 'APPROVED', 'REFUNDED', 'APPLIED', 'FORFEITED')),
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
    UNIQUE (session_id, user_id),
    UNIQUE (session_id, paddle_number)
);

-- Chỉ thêm, không sửa / xoá.
CREATE TABLE bids (
    id              BIGSERIAL PRIMARY KEY,
    lot_id          BIGINT         NOT NULL REFERENCES lots (id),
    user_id         BIGINT         NOT NULL REFERENCES users (id),
    registration_id BIGINT         NOT NULL REFERENCES auction_registrations (id),
    amount          NUMERIC(15, 0) NOT NULL,
    is_auto         BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_bids_lot ON bids (lot_id, amount DESC);

CREATE TABLE proxy_bids (
    id         BIGSERIAL PRIMARY KEY,
    lot_id     BIGINT         NOT NULL REFERENCES lots (id),
    user_id    BIGINT         NOT NULL REFERENCES users (id),
    max_amount NUMERIC(15, 0) NOT NULL,
    active     BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ    NOT NULL DEFAULT now(),
    UNIQUE (lot_id, user_id)
);

CREATE TABLE lot_watchers (
    user_id    BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    lot_id     BIGINT      NOT NULL REFERENCES lots (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, lot_id)
);

-- ---------------------------------------------------------------------
-- 4. Tiền: ví, sổ cái, thanh toán, đơn hàng
-- ---------------------------------------------------------------------
-- user_id NULL = ví của sàn (nhận phí).
CREATE TABLE wallets (
    id                BIGSERIAL PRIMARY KEY,
    user_id           BIGINT UNIQUE REFERENCES users (id),
    available_balance NUMERIC(15, 0) NOT NULL DEFAULT 0 CHECK (available_balance >= 0),
    held_balance      NUMERIC(15, 0) NOT NULL DEFAULT 0 CHECK (held_balance >= 0),
    version           BIGINT         NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_wallets_platform ON wallets ((user_id IS NULL)) WHERE user_id IS NULL;

-- Sổ cái: chỉ thêm. Sai thì tạo giao dịch điều chỉnh ngược lại.
CREATE TABLE wallet_transactions (
    id               BIGSERIAL PRIMARY KEY,
    wallet_id        BIGINT         NOT NULL REFERENCES wallets (id),
    type             VARCHAR(20)    NOT NULL
        CHECK (type IN ('TOP_UP', 'PAYMENT', 'REFUND', 'DEPOSIT_HOLD', 'DEPOSIT_RELEASE', 'DEPOSIT_FORFEIT',
                        'SALE_PENDING', 'SALE_RELEASE', 'FEE', 'WITHDRAW')),
    available_change NUMERIC(15, 0) NOT NULL DEFAULT 0,
    held_change      NUMERIC(15, 0) NOT NULL DEFAULT 0,
    available_after  NUMERIC(15, 0) NOT NULL,
    held_after       NUMERIC(15, 0) NOT NULL,
    ref_type         VARCHAR(30),
    ref_id           BIGINT,
    note             VARCHAR(500),
    created_at       TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_wallet_tx_wallet ON wallet_transactions (wallet_id, created_at DESC);

CREATE TABLE payments (
    id             BIGSERIAL PRIMARY KEY,
    code           VARCHAR(30)    NOT NULL UNIQUE,
    user_id        BIGINT         NOT NULL REFERENCES users (id),
    purpose        VARCHAR(20)    NOT NULL CHECK (purpose IN ('ORDER', 'TOP_UP')),
    method         VARCHAR(20)    NOT NULL CHECK (method IN ('COD', 'WALLET', 'VNPAY')),
    amount         NUMERIC(15, 0) NOT NULL CHECK (amount >= 0),
    status         VARCHAR(20)    NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'EXPIRED')),
    gateway_txn_id VARCHAR(100) UNIQUE, -- chống cộng trùng khi IPN gọi 2 lần
    raw_callback   TEXT,
    paid_at        TIMESTAMPTZ,
    expires_at     TIMESTAMPTZ,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id                    BIGSERIAL PRIMARY KEY,
    code                  VARCHAR(30)    NOT NULL UNIQUE,
    buyer_id              BIGINT         NOT NULL REFERENCES users (id),
    shop_id               BIGINT REFERENCES shops (id), -- NULL nếu là đơn đấu giá (kho giao)
    lot_id                BIGINT REFERENCES lots (id),
    order_type            VARCHAR(10)    NOT NULL CHECK (order_type IN ('NORMAL', 'AUCTION')),
    status                VARCHAR(20)    NOT NULL
        CHECK (status IN ('PENDING_PAYMENT', 'PENDING_CONFIRM', 'PREPARING', 'SHIPPING', 'DELIVERED',
                          'RETURN_REQUESTED', 'COMPLETED', 'CANCELLED', 'RETURNED', 'FAILED_DELIVERY')),
    payment_method        VARCHAR(20) CHECK (payment_method IN ('COD', 'WALLET', 'VNPAY')),
    payment_id            BIGINT REFERENCES payments (id),
    paid_at               TIMESTAMPTZ,
    subtotal              NUMERIC(15, 0) NOT NULL,
    shipping_fee          NUMERIC(15, 0) NOT NULL DEFAULT 0,
    buyer_premium         NUMERIC(15, 0) NOT NULL DEFAULT 0,
    deposit_applied       NUMERIC(15, 0) NOT NULL DEFAULT 0,
    total                 NUMERIC(15, 0) NOT NULL,
    address_snapshot      JSONB,
    pickup_at_warehouse   BOOLEAN        NOT NULL DEFAULT FALSE,
    tracking_code         VARCHAR(50),
    note                  VARCHAR(500),
    cancel_reason         VARCHAR(500),
    cancel_requested      BOOLEAN        NOT NULL DEFAULT FALSE,
    second_chance         BOOLEAN        NOT NULL DEFAULT FALSE,
    payment_due_at        TIMESTAMPTZ,
    confirm_due_at        TIMESTAMPTZ,
    delivered_at          TIMESTAMPTZ,
    completed_at          TIMESTAMPTZ,
    cancelled_at          TIMESTAMPTZ,
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_buyer ON orders (buyer_id, created_at DESC);
CREATE INDEX idx_orders_shop ON orders (shop_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders (status);
CREATE INDEX idx_orders_payment ON orders (payment_id);

-- Giá lưu cứng lúc đặt, không tham chiếu giá hiện tại.
CREATE TABLE order_items (
    id             BIGSERIAL PRIMARY KEY,
    order_id       BIGINT         NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    listing_id     BIGINT REFERENCES listings (id),
    lot_id         BIGINT REFERENCES lots (id),
    title_snapshot VARCHAR(300)   NOT NULL,
    image_snapshot VARCHAR(500),
    unit_price     NUMERIC(15, 0) NOT NULL,
    quantity       INT            NOT NULL CHECK (quantity > 0),
    CHECK (listing_id IS NOT NULL OR lot_id IS NOT NULL)
);
CREATE INDEX idx_order_items_order ON order_items (order_id);

CREATE TABLE order_status_history (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT      NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    from_status VARCHAR(20),
    to_status   VARCHAR(20) NOT NULL,
    actor_id    BIGINT REFERENCES users (id), -- NULL = hệ thống (job)
    note        VARCHAR(500),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_order_history_order ON order_status_history (order_id);

CREATE TABLE reviews (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT      NOT NULL UNIQUE REFERENCES orders (id),
    reviewer_id BIGINT      NOT NULL REFERENCES users (id),
    shop_id     BIGINT      NOT NULL REFERENCES shops (id),
    rating      SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     VARCHAR(1000),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_reviews_shop ON reviews (shop_id);

CREATE TABLE return_requests (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT        NOT NULL UNIQUE REFERENCES orders (id),
    reason      VARCHAR(30)   NOT NULL
        CHECK (reason IN ('WRONG_CONDITION', 'MISSING_PAGES', 'WRONG_EDITION', 'OTHER_NOT_AS_DESCRIBED')),
    description VARCHAR(1000) NOT NULL,
    images      JSONB         NOT NULL DEFAULT '[]',
    status      VARCHAR(20)   NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'DISPUTED', 'REJECTED')),
    seller_note VARCHAR(1000),
    resolution  VARCHAR(1000),
    resolved_by BIGINT REFERENCES users (id),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE withdraw_requests (
    id             BIGSERIAL PRIMARY KEY,
    user_id        BIGINT         NOT NULL REFERENCES users (id),
    amount         NUMERIC(15, 0) NOT NULL CHECK (amount > 0),
    bank_name      VARCHAR(100)   NOT NULL,
    account_number VARCHAR(50)    NOT NULL,
    account_holder VARCHAR(120)   NOT NULL,
    status         VARCHAR(20)    NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    note           VARCHAR(500),
    processed_by   BIGINT REFERENCES users (id),
    processed_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 5. Thông báo & cấu hình
-- ---------------------------------------------------------------------
CREATE TABLE notifications (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    type       VARCHAR(40)  NOT NULL,
    title      VARCHAR(200) NOT NULL,
    body       VARCHAR(1000) NOT NULL,
    data       JSONB,
    is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications (user_id, created_at DESC);

CREATE TABLE system_configs (
    key         VARCHAR(80) PRIMARY KEY,
    value       VARCHAR(500) NOT NULL,
    description VARCHAR(300),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

INSERT INTO system_configs (key, value, description) VALUES
    ('fee.fixed_price_percent',          '5',       'Phí sàn bán giá cố định (% giá sách, người bán trả)'),
    ('fee.buyer_premium_percent',        '10',      'Phí người mua đấu giá (% giá gõ búa)'),
    ('fee.seller_commission_percent',    '15',      'Hoa hồng đấu giá (% giá gõ búa, người bán trả)'),
    ('fee.storage_per_day',              '5000',    'Phí lưu kho mỗi cuốn mỗi ngày sau hạn miễn phí'),
    ('fee.storage_free_days',            '14',      'Số ngày lưu kho miễn phí sau khi báo người bán đến nhận'),
    ('order.payment_timeout_minutes',    '15',      'Hạn thanh toán online đơn thường'),
    ('order.confirm_timeout_hours',      '24',      'Hạn người bán xác nhận đơn'),
    ('order.auto_complete_days',         '3',       'Số ngày sau khi giao thì tự hoàn tất'),
    ('shipping.same_province',           '20000',   'Phí ship nội tỉnh (≤ 1kg)'),
    ('shipping.other_province',          '30000',   'Phí ship liên tỉnh (≤ 1kg)'),
    ('shipping.extra_per_500g',          '5000',    'Phụ phí mỗi 500g vượt 1kg'),
    ('shipping.warehouse_province',      'TP. Hồ Chí Minh', 'Tỉnh đặt kho của sàn (giao lô đấu giá)'),
    ('consignment.min_expected_price',   '300000',  'Giá mong muốn tối thiểu để nhận ký gửi'),
    ('consignment.appointment_days',     '7',       'Số ngày tối đa để mang sách tới kho'),
    ('consignment.max_rounds',           '2',       'Số phiên tối đa sàn giữ một lô'),
    ('auction.bid_increment_tiers',      '0:10000,200000:50000,1000000:100000,5000000:500000', 'Bậc bước giá: từ_giá:bước'),
    ('auction.bid_limit_multiplier',     '10',      'Hạn mức trả giá = tiền cọc × hệ số'),
    ('auction.payment_hours',            '48',      'Hạn thanh toán lô thắng'),
    ('auction.second_chance_hours',      '24',      'Hạn cho người trả giá cao thứ hai'),
    ('auction.ban_days',                 '90',      'Số ngày cấm đấu giá khi bỏ thanh toán'),
    ('auction.forfeit_seller_percent',   '50',      'Phần tiền cọc bị thu chia cho người bán (%)'),
    ('auction.postpone_days',            '7',       'Số ngày dời phiên khi thiếu người'),
    ('listing.auto_approve_trusted',     'true',    'Tự duyệt tin của shop uy tín');
