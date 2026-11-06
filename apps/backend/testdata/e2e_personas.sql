-- =====================================================================
-- Bộ dữ liệu mẫu cho test đầu cuối (docs/ra-soat-nghiep-vu/TEST_PLAN_TOAN_DIEN.md phần A).
-- KHÔNG phải migration: nạp tay vào DB dev SAU KHI backend đã khởi động một lần (Flyway đã tạo bảng + seed dev):
--   psql -h localhost -U rebook -d rebook_dev -f apps/backend/testdata/e2e_personas.sql
-- Chạy lại được nhiều lần: xoá dữ liệu cũ của bộ này (id 9001–9999) rồi nạp lại.
-- Mật khẩu mọi tài khoản: Rebook@123. Số dư ví khớp sổ cái (nạp 3 ngày trước, không bị khoá rút 24 giờ).
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---- Dọn bộ cũ (theo thứ tự khoá ngoại). Gồm cả dữ liệu script tạo qua API: id thường, nhưng gắn người dùng 9001–9999
--      hoặc phiên có tiêu đề bắt đầu bằng "E2E". ----
CREATE TEMP TABLE e2e_sessions AS SELECT id FROM auction_sessions WHERE id BETWEEN 9001 AND 9999 OR title LIKE 'E2E%';
CREATE TEMP TABLE e2e_consignments AS SELECT id FROM consignments WHERE id BETWEEN 9001 AND 9999 OR seller_id BETWEEN 9001 AND 9999;
CREATE TEMP TABLE e2e_lots AS SELECT id FROM lots
    WHERE id BETWEEN 9001 AND 9999 OR consignment_id IN (SELECT id FROM e2e_consignments) OR session_id IN (SELECT id FROM e2e_sessions);
CREATE TEMP TABLE e2e_orders AS SELECT id FROM orders WHERE buyer_id BETWEEN 9001 AND 9999 OR lot_id IN (SELECT id FROM e2e_lots)
    OR shop_id BETWEEN 9001 AND 9999;

DELETE FROM notifications        WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM bids                 WHERE lot_id IN (SELECT id FROM e2e_lots) OR user_id BETWEEN 9001 AND 9999;
DELETE FROM proxy_bids           WHERE lot_id IN (SELECT id FROM e2e_lots) OR user_id BETWEEN 9001 AND 9999;
DELETE FROM lot_watchers         WHERE lot_id IN (SELECT id FROM e2e_lots) OR user_id BETWEEN 9001 AND 9999;
DELETE FROM session_watchers     WHERE session_id IN (SELECT id FROM e2e_sessions) OR user_id BETWEEN 9001 AND 9999;
DELETE FROM auction_registrations WHERE session_id IN (SELECT id FROM e2e_sessions) OR user_id BETWEEN 9001 AND 9999;
DELETE FROM return_requests      WHERE order_id IN (SELECT id FROM e2e_orders);
DELETE FROM order_status_history WHERE order_id IN (SELECT id FROM e2e_orders);
DELETE FROM order_items          WHERE order_id IN (SELECT id FROM e2e_orders);
DELETE FROM reviews              WHERE order_id IN (SELECT id FROM e2e_orders) OR reviewer_id BETWEEN 9001 AND 9999;
DELETE FROM account_debts        WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM orders               WHERE id IN (SELECT id FROM e2e_orders);
DELETE FROM cart_items           WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM withdraw_transfers   WHERE withdraw_id IN (SELECT id FROM withdraw_requests WHERE user_id BETWEEN 9001 AND 9999);
DELETE FROM withdraw_requests    WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM bank_accounts        WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM payments             WHERE user_id BETWEEN 9001 AND 9999;
UPDATE auction_sessions SET current_lot_id = NULL WHERE id IN (SELECT id FROM e2e_sessions);
DELETE FROM lots                 WHERE id IN (SELECT id FROM e2e_lots);
DELETE FROM auction_sessions     WHERE id IN (SELECT id FROM e2e_sessions);
DELETE FROM warehouse_incidents  WHERE warehouse_item_id IN (SELECT id FROM warehouse_items WHERE consignment_id IN (SELECT id FROM e2e_consignments));
DELETE FROM warehouse_items      WHERE consignment_id IN (SELECT id FROM e2e_consignments);
DELETE FROM inspections          WHERE consignment_id IN (SELECT id FROM e2e_consignments);
DELETE FROM consignments         WHERE id IN (SELECT id FROM e2e_consignments);
DELETE FROM listing_favorites    WHERE user_id BETWEEN 9001 AND 9999
    OR listing_id IN (SELECT id FROM listings WHERE shop_id BETWEEN 9001 AND 9999 OR book_id IN (SELECT id FROM books WHERE owner_id BETWEEN 9001 AND 9999));
DELETE FROM listings             WHERE id BETWEEN 9001 AND 9999 OR shop_id BETWEEN 9001 AND 9999
    OR book_id IN (SELECT id FROM books WHERE owner_id BETWEEN 9001 AND 9999);
DELETE FROM book_images          WHERE book_id IN (SELECT id FROM books WHERE id BETWEEN 9001 AND 9999 OR owner_id BETWEEN 9001 AND 9999);
DELETE FROM books                WHERE id BETWEEN 9001 AND 9999 OR owner_id BETWEEN 9001 AND 9999;
DELETE FROM shops                WHERE id BETWEEN 9001 AND 9999 OR user_id BETWEEN 9001 AND 9999;
DELETE FROM addresses            WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM wallet_transactions  WHERE wallet_id IN (SELECT id FROM wallets WHERE user_id BETWEEN 9001 AND 9999);
DELETE FROM wallets              WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM refresh_tokens       WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM otp_codes            WHERE user_id BETWEEN 9001 AND 9999;
DELETE FROM users                WHERE id BETWEEN 9001 AND 9999;
DELETE FROM categories           WHERE id = 9001;
DROP TABLE e2e_sessions, e2e_consignments, e2e_lots, e2e_orders;

INSERT INTO categories (id, name, slug) VALUES (9001, 'Sách test E2E', 'e2e-test');

-- ---------------------------------------------------------------------
-- Nhân vật (persona). Mỗi người đại diện cho một tình huống thực tế.
-- ---------------------------------------------------------------------
INSERT INTO users (id, email, phone, password_hash, full_name, role, status, email_verified, phone_verified,
                   auction_banned_until, auction_strikes, auction_last_strike_at, lock_reason) VALUES
 (9001, 'e2e.buyer.rich@rebook.vn',   '0990009001', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người mua nhiều tiền', 'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9002, 'e2e.buyer.poor@rebook.vn',   '0990009002', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người mua ví rỗng',    'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9003, 'e2e.buyer.new@rebook.vn',    '0990009003', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người mua mới (COD)',  'USER', 'ACTIVE', TRUE, FALSE, NULL, 0, NULL, NULL),
 (9004, 'e2e.buyer.bomber@rebook.vn', '0990009004', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người hay bom COD',    'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9005, 'e2e.buyer.debt@rebook.vn',   '0990009005', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người còn nợ phạt',    'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9006, 'e2e.buyer.banned@rebook.vn', '0990009006', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người bị cấm đấu giá', 'USER', 'ACTIVE', TRUE, TRUE,  now() + interval '30 days', 1, now() - interval '60 days', NULL),
 (9007, 'e2e.buyer.locked@rebook.vn', '0990009007', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Tài khoản bị khoá',    'USER', 'LOCKED', TRUE, TRUE,  NULL, 0, NULL, 'Gian lận (dữ liệu test)'),
 (9008, 'e2e.bidder.a@rebook.vn',     '0990009008', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người đấu giá A',      'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9009, 'e2e.bidder.b@rebook.vn',     '0990009009', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người đấu giá B',      'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9010, 'e2e.bidder.c@rebook.vn',     '0990009010', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người đấu giá C',      'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9011, 'e2e.shop.new@rebook.vn',     '0990009011', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Shop mới (chưa uy tín)', 'USER', 'ACTIVE', TRUE, TRUE, NULL, 0, NULL, NULL),
 (9012, 'e2e.consignor@rebook.vn',    '0990009012', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Người ký gửi',         'USER', 'ACTIVE', TRUE, TRUE,  NULL, 0, NULL, NULL),
 (9013, 'e2e.unverified@rebook.vn',   '0990009013', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Chưa xác thực email',  'USER', 'ACTIVE', FALSE, FALSE, NULL, 0, NULL, NULL),
 (9014, 'e2e.staff@rebook.vn',        '0990009014', crypt('Rebook@123', gen_salt('bf', 10)), 'E2E Nhân viên kho',        'STAFF', 'ACTIVE', TRUE, TRUE, NULL, 0, NULL, NULL);

-- Ví: số dư = tổng dòng TOP_UP (đối soát ví với sổ cái không báo lệch)
INSERT INTO wallets (user_id, available_balance) VALUES
 (9001, 5000000), (9002, 0), (9003, 1000000), (9004, 2000000), (9005, 0), (9006, 3000000), (9007, 500000),
 (9008, 3000000), (9009, 3000000), (9010, 3000000), (9011, 0), (9012, 0), (9013, 500000), (9014, 0);
INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after, ref_type, note, created_at)
SELECT w.id, 'TOP_UP', w.available_balance, 0, w.available_balance, 0, 'E2E', 'Nạp sẵn cho test E2E', now() - interval '3 days'
FROM wallets w WHERE w.user_id BETWEEN 9001 AND 9999 AND w.available_balance > 0;

INSERT INTO addresses (user_id, receiver_name, phone, province, district, ward, detail, is_default) VALUES
 (9001, 'E2E Người mua nhiều tiền', '0990009001', 'TP. Hồ Chí Minh', 'Quận 3', 'Phường 6', '10 Pasteur', TRUE),
 (9002, 'E2E Người mua ví rỗng',    '0990009002', 'Hà Nội', 'Ba Đình', 'Phường Kim Mã', '5 Kim Mã', TRUE),
 (9003, 'E2E Người mua mới',        '0990009003', 'TP. Hồ Chí Minh', 'Quận 1', 'Phường Bến Nghé', '1 Lê Lợi', TRUE),
 (9004, 'E2E Người hay bom COD',    '0990009004', 'Đà Nẵng', 'Hải Châu', 'Phường Thạch Thang', '2 Bạch Đằng', TRUE),
 (9008, 'E2E Người đấu giá A',      '0990009008', 'TP. Hồ Chí Minh', 'Quận 5', 'Phường 1', '3 An Dương Vương', TRUE),
 (9009, 'E2E Người đấu giá B',      '0990009009', 'Hà Nội', 'Đống Đa', 'Phường Láng Hạ', '9 Láng Hạ', TRUE);

-- Nợ phạt còn mở: chặn đăng ký phiên, trả giá, rút tiền
INSERT INTO account_debts (user_id, type, amount, ref_type, note) VALUES
 (9005, 'AUCTION_PENALTY', 200000, 'E2E', 'Nợ phạt mẫu cho test E2E');

-- ---------------------------------------------------------------------
-- Shop mới (Hà Nội, chưa uy tín: tin mới phải chờ duyệt) và tin đăng ở các trạng thái
-- ---------------------------------------------------------------------
INSERT INTO shops (id, user_id, name, description, pickup_address, pickup_province, bank_name, bank_account_number, bank_account_holder, trusted)
VALUES (9001, 9011, 'E2E Tiệm Sách Test', 'Shop dùng cho test đầu cuối', '1 Hàng Bài, Hoàn Kiếm', 'Hà Nội', 'Vietcombank', '0011009011', 'E2E SHOP', FALSE);

INSERT INTO books (id, owner_id, title, author, category_id, condition_grade, weight_gram, publish_year) VALUES
 (9001, 9011, 'E2E Cuốn cuối cùng (tồn 1)',        'Tác giả A', 9001, 'GOOD',      400, 2010),
 (9002, 9011, 'E2E Sách nhiều bản (tồn 5)',        'Tác giả B', 9001, 'VERY_GOOD', 300, 2015),
 (9003, 9011, 'E2E Tin đang ẩn',                   'Tác giả C', 9001, 'GOOD',      300, 2001),
 (9004, 9011, 'E2E Tin chờ duyệt',                 'Tác giả D', 9001, 'LIKE_NEW',  300, 2020),
 (9005, 9011, 'E2E Sách đắt (vượt hạn mức COD)',   'Tác giả E', 9001, 'GOOD',     1200, 1985),
 (9101, 9012, 'E2E Lô thường',                     'Tác giả F', 9001, 'GOOD',      500, 1990),
 (9102, 9012, 'E2E Lô cao giá',                    'Tác giả G', 9001, 'VERY_GOOD', 800, 1965),
 (9103, 9012, 'E2E Lô giá sàn cao',                'Tác giả H', 9001, 'GOOD',      400, 1975),
 (9104, 9012, 'E2E Ký gửi chờ người bán quyết',    'Tác giả I', 9001, 'GOOD',      300, 1980),
 (9105, 9012, 'E2E Sách vô chủ trong kho',         'Tác giả K', 9001, 'GOOD',      300, 1970),
 (9106, 9012, 'E2E Ký gửi đã duyệt, chờ hẹn lịch', 'Tác giả L', 9001, 'GOOD',      300, 1995),
 (9107, 9012, 'E2E Lô mời mua lần hai',            'Tác giả M', 9001, 'GOOD',      300, 1988),
 (9108, 9012, 'E2E Lô của phiên thiếu người',      'Tác giả N', 9001, 'GOOD',      300, 1992),
 (9109, 9012, 'E2E Lô test khởi động lại',         'Tác giả O', 9001, 'GOOD',      300, 1999);
INSERT INTO book_images (book_id, url, sort_order)
SELECT id, '/files/e2e-' || id || '-' || n || '.png', n FROM books, generate_series(0, 2) n WHERE id BETWEEN 9001 AND 9999;

INSERT INTO listings (id, book_id, shop_id, price, stock, status) VALUES
 (9001, 9001, 9001,  120000, 1, 'ACTIVE'),
 (9002, 9002, 9001,   45000, 5, 'ACTIVE'),
 (9003, 9003, 9001,   80000, 2, 'HIDDEN'),
 (9004, 9004, 9001,   60000, 1, 'PENDING_REVIEW'),
 (9005, 9005, 9001, 3500000, 1, 'ACTIVE');

-- Người hay bom: 2 đơn COD giao thất bại do người mua trong 90 ngày → bị chặn COD
INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, subtotal, shipping_fee, total, delivery_fault, cancelled_at)
VALUES ('E2E-BOMB-1', 9004, 9001, 'NORMAL', 'FAILED_DELIVERY', 'COD', 45000, 30000, 75000, 'BUYER', now() - interval '20 days'),
       ('E2E-BOMB-2', 9004, 9001, 'NORMAL', 'FAILED_DELIVERY', 'COD', 45000, 30000, 75000, 'BUYER', now() - interval '10 days');

-- ---------------------------------------------------------------------
-- Ký gửi ở các bước (người ký gửi 9012)
-- ---------------------------------------------------------------------
INSERT INTO consignments (id, code, seller_id, book_id, expected_price, status, approved_at, received_at, received_by) VALUES
 (9101, 'E2E-KG-LOT1', 9012, 9101,   300000, 'ACCEPTED',        now() - interval '10 days', now() - interval '9 days', 9014),
 (9102, 'E2E-KG-LOT2', 9012, 9102, 18000000, 'ACCEPTED',        now() - interval '10 days', now() - interval '9 days', 9014),
 (9103, 'E2E-KG-LOT3', 9012, 9103,  1200000, 'ACCEPTED',        now() - interval '10 days', now() - interval '9 days', 9014),
 (9104, 'E2E-KG-WAIT', 9012, 9104,   400000, 'AWAITING_SELLER', now() - interval '12 days', now() - interval '10 days', 9014),
 (9105, 'E2E-KG-ABND', 9012, 9105,   400000, 'WITHDRAWN',       now() - interval '90 days', now() - interval '88 days', 9014),
 (9106, 'E2E-KG-APPR', 9012, 9106,   500000, 'APPROVED',        now() - interval '1 day',  NULL, NULL),
 (9107, 'E2E-KG-LOT4', 9012, 9107,   200000, 'ACCEPTED',        now() - interval '10 days', now() - interval '9 days', 9014),
 (9108, 'E2E-KG-LOT5', 9012, 9108,   300000, 'ACCEPTED',        now() - interval '10 days', now() - interval '9 days', 9014),
 (9109, 'E2E-KG-LOT6', 9012, 9109,   300000, 'ACCEPTED',        now() - interval '10 days', now() - interval '9 days', 9014);

INSERT INTO inspections (consignment_id, inspector_id, result, condition_report, condition_grade, estimate_low, estimate_high,
                         proposed_start, proposed_reserve, seller_decision, created_at) VALUES
 (9101, 9014, 'PASS', 'Bìa sờn nhẹ, đủ trang', 'GOOD',      250000,   400000,  100000,  200000, 'ACCEPTED', now() - interval '8 days'),
 (9102, 9014, 'PASS', 'Bản in đầu, còn rất tốt', 'VERY_GOOD', 15000000, 20000000, 5000000, 8000000, 'ACCEPTED', now() - interval '8 days'),
 (9103, 9014, 'PASS', 'Ố vàng nhẹ',            'GOOD',      1000000,  1500000,   50000, 1000000, 'ACCEPTED', now() - interval '8 days'),
 (9104, 9014, 'PASS', 'Còn tốt',               'GOOD',       300000,   500000,  100000,  250000, 'PENDING',  now() - interval '8 days'),
 (9105, 9014, 'PASS', 'Còn tốt',               'GOOD',       300000,   500000,  100000,  250000, 'WITHDRAWN', now() - interval '85 days'),
 (9107, 9014, 'PASS', 'Còn tốt',               'GOOD',       150000,   250000,  100000,  150000, 'ACCEPTED',  now() - interval '8 days'),
 (9108, 9014, 'PASS', 'Còn tốt',               'GOOD',       200000,   300000,  100000,  150000, 'ACCEPTED',  now() - interval '8 days'),
 (9109, 9014, 'PASS', 'Còn tốt',               'GOOD',       200000,   300000,  100000,  150000, 'ACCEPTED',  now() - interval '8 days');

-- Kho: 9105 chờ người bán nhận lại đã 70 ngày (quá 60 ngày → bị nhắc rồi thanh lý)
INSERT INTO warehouse_items (consignment_id, code, shelf_code, status, return_notified_at) VALUES
 (9101, 'E2E-WH-1', 'E2E-A1', 'IN_STOCK', NULL),
 (9102, 'E2E-WH-2', 'E2E-A2', 'IN_STOCK', NULL),
 (9103, 'E2E-WH-3', 'E2E-A3', 'IN_STOCK', NULL),
 (9104, 'E2E-WH-4', 'E2E-A4', 'IN_STOCK', NULL),
 (9105, 'E2E-WH-5', 'E2E-A5', 'IN_STOCK', now() - interval '70 days'),
 (9107, 'E2E-WH-7', 'E2E-A7', 'IN_STOCK', NULL),
 (9108, 'E2E-WH-8', 'E2E-A8', 'IN_STOCK', NULL),
 (9109, 'E2E-WH-9', 'E2E-A9', 'IN_STOCK', NULL);

-- ---------------------------------------------------------------------
-- Phiên đấu giá ngắn cho demo / E2E: đã công bố, còn nhận đăng ký, đủ người khi có 2 người.
-- Mỗi lô 20 giây, soft close 5 giây, nghỉ 3 giây. Admin mở ngay bằng POST /admin/sessions/9001/start (chỉ ở demo).
-- ---------------------------------------------------------------------
INSERT INTO auction_sessions (id, title, description, start_at, registration_deadline, min_participants, deposit_amount,
                              lot_duration_sec, soft_close_sec, lot_gap_sec, status, published_at, created_by)
VALUES (9001, 'E2E Phiên test đầu cuối', 'Phiên dùng cho test đầu cuối', now() + interval '2 hour', now() + interval '1 hour',
        2, 200000, 20, 5, 3, 'PUBLISHED', now(), 1);

INSERT INTO lots (id, session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                  status, rounds, commission_percent) VALUES
 (9101, 9001, 9101, 9101, 1,  100000,  200000,   250000,   400000, 'SCHEDULED', 1, 15),
 (9102, 9001, 9102, 9102, 2, 5000000, 8000000, 15000000, 20000000, 'SCHEDULED', 1, 15),
 (9103, 9001, 9103, 9103, 3,   50000, 1000000,  1000000,  1500000, 'SCHEDULED', 1, 15),
 (9104, 9001, 9107, 9107, 4,  100000,  150000,   150000,   250000, 'SCHEDULED', 1, 15);

-- Phiên thiếu người (cần 3, chỉ có 1): hạn đăng ký qua thì dời lịch một lần, qua lần nữa thì huỷ, hoàn cọc, lô về hàng chờ
INSERT INTO auction_sessions (id, title, start_at, registration_deadline, min_participants, deposit_amount, lot_duration_sec,
                              soft_close_sec, lot_gap_sec, status, published_at, created_by)
VALUES (9002, 'E2E Phiên thiếu người', now() + interval '2 hour', now() + interval '1 hour', 3, 100000, 20, 5, 3, 'PUBLISHED', now(), 1);
INSERT INTO lots (id, session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                  status, rounds, commission_percent)
VALUES (9105, 9002, 9108, 9108, 1, 100000, 150000, 200000, 300000, 'SCHEDULED', 1, 15);

-- Phiên test khởi động lại backend giữa lúc đang chạy (testdata/e2e_restart.sh): mỗi lô 60 giây
INSERT INTO auction_sessions (id, title, start_at, registration_deadline, min_participants, deposit_amount, lot_duration_sec,
                              soft_close_sec, lot_gap_sec, status, published_at, created_by)
VALUES (9003, 'E2E Phiên khởi động lại', now() + interval '2 hour', now() + interval '1 hour', 1, 100000, 60, 10, 3, 'PUBLISHED', now(), 1);
INSERT INTO lots (id, session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high,
                  status, rounds, commission_percent)
VALUES (9106, 9003, 9109, 9109, 1, 100000, 150000, 200000, 300000, 'SCHEDULED', 1, 15);
