-- Luồng tiền đấu giá (docs/AUCTION_MONEY_FLOW.md): phạt % giá búa mỗi lô bỏ, nợ phạt / nợ phí kho,
-- huỷ đăng ký, kiểm định lại khi lô bị trả hàng. Chỉ thêm.

INSERT INTO system_configs (key, value, description) VALUES
    ('auction.default_penalty_percent', '10', 'Phạt bỏ thanh toán lô thắng (% giá búa mỗi lô); lô bỏ đầu tiên mất toàn bộ cọc nếu cọc lớn hơn'),
    ('auction.unsold_decision_days',    '7',  'Số ngày người bán phải chọn hướng xử lý lô không bán, quá hạn thì tự trả sách')
ON CONFLICT (key) DO NOTHING;

-- Loại giao dịch ví: tiền phạt bỏ thanh toán
ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;
ALTER TABLE wallet_transactions ADD CONSTRAINT wallet_transactions_type_check
    CHECK (type IN ('TOP_UP', 'PAYMENT', 'REFUND', 'DEPOSIT_HOLD', 'DEPOSIT_RELEASE', 'DEPOSIT_FORFEIT',
                    'SALE_PENDING', 'SALE_RELEASE', 'FEE', 'WITHDRAW', 'COD_RECEIPT', 'COD_PAYOUT', 'AUCTION_PENALTY'));

-- Lô bị trả về kho chờ kiểm định lại; đăng ký đã huỷ
ALTER TABLE lots DROP CONSTRAINT IF EXISTS lots_status_check;
ALTER TABLE lots ADD CONSTRAINT lots_status_check
    CHECK (status IN ('READY', 'SCHEDULED', 'OPEN', 'SOLD', 'UNSOLD', 'PAID', 'COMPLETED',
                      'CANCELLED', 'RETURNED', 'CONVERTED', 'INSPECTING'));
ALTER TABLE auction_registrations DROP CONSTRAINT IF EXISTS auction_registrations_status_check;
ALTER TABLE auction_registrations ADD CONSTRAINT auction_registrations_status_check
    CHECK (status IN ('PENDING_DEPOSIT', 'APPROVED', 'REFUNDED', 'APPLIED', 'FORFEITED', 'CANCELLED'));

-- Nợ của người dùng với sàn: phạt bỏ thanh toán chưa thu đủ, phí lưu kho chưa thu đủ.
-- Còn nợ OPEN thì không đăng ký phiên, không trả giá, không rút tiền.
CREATE TABLE account_debts (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT         NOT NULL REFERENCES users (id),
    type                VARCHAR(20)    NOT NULL CHECK (type IN ('AUCTION_PENALTY', 'STORAGE_FEE')),
    amount              NUMERIC(15, 0) NOT NULL CHECK (amount > 0),
    paid_amount         NUMERIC(15, 0) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    status              VARCHAR(10)    NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'PAID', 'WAIVED')),
    ref_type            VARCHAR(30),
    ref_id              BIGINT,
    beneficiary_id      BIGINT REFERENCES users (id),   -- người nhận phần chia khi thu nợ (người bán); NULL = cả khoản về sàn
    beneficiary_percent NUMERIC(5, 2)  NOT NULL DEFAULT 0,
    note                VARCHAR(500),
    waived_by           BIGINT REFERENCES users (id),
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT now(),
    settled_at          TIMESTAMPTZ
);
CREATE INDEX idx_account_debts_user_open ON account_debts (user_id) WHERE status = 'OPEN';
