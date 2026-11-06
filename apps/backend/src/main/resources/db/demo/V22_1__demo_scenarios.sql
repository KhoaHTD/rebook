-- =====================================================================
-- Dữ liệu DEMO cho buổi trình diễn (profile dev + REBOOK_DEMO=,classpath:db/demo; do scripts/reset-demo đặt, sau V21_1).
-- Mọi mốc thời gian tính theo lúc migration chạy (= lúc reset DB), nên chạy scripts/reset-demo luôn ra cùng một "câu chuyện":
--   * ~80 đơn mua rải 30 ngày gần nhất, đủ trạng thái; khiếu nại, COD chờ đối soát, rút tiền, nợ, chargeback.
--   * 5 phiên đấu giá: đã xong x2, sắp mở sau vài phút (tự LIVE), mở đăng ký ngày mai, nháp; các lô sách hiếm còn trong kho.
--   * Ký gửi ở mọi bước (chờ duyệt, đã duyệt, hẹn, đã nhận, kiểm định, chờ người bán); tin chờ duyệt, sự cố kho.
-- Mật khẩu mọi tài khoản: Rebook@123. Số dư ví luôn khớp sổ cái wallet_transactions.
-- =====================================================================

SELECT setseed(0.37);

-- ---------------------------------------------------------------------
-- Người dùng, shop, địa chỉ
-- ---------------------------------------------------------------------
INSERT INTO users (id, email, phone, password_hash, full_name, avatar_url, role, status, email_verified, phone_verified,
                   auction_banned_until, auction_strikes, lock_reason, created_at)
SELECT v.id, v.email, v.phone, (SELECT password_hash FROM users WHERE id = 5), v.full_name,
       'https://i.pravatar.cc/200?u=' || split_part(v.email, '@', 1), 'USER', v.status, TRUE, TRUE,
       v.banned_until, v.strikes, v.lock_reason, now() - v.age
FROM (VALUES
    (8,  'seller3@rebook.vn', '0966666666', 'Bùi Quang Huy',   'ACTIVE', NULL::timestamptz, 0, NULL::text,                       interval '38 days'),
    (9,  'seller4@rebook.vn', '0977777777', 'Ngô Thanh Mai',   'ACTIVE', NULL,              0, NULL,                             interval '2 days'),
    (10, 'buyer4@rebook.vn',  '0988888888', 'Hoàng Gia Bảo',   'ACTIVE', NULL,              0, NULL,                             interval '28 days'),
    (11, 'buyer5@rebook.vn',  '0999999991', 'Đỗ Khánh Linh',   'ACTIVE', NULL,              0, NULL,                             interval '27 days'),
    (12, 'buyer6@rebook.vn',  '0999999992', 'Lý Minh Tuấn',    'ACTIVE', NULL,              0, NULL,                             interval '22 days'),
    (13, 'buyer7@rebook.vn',  '0999999993', 'Phan Thảo Vy',    'ACTIVE', NULL,              0, NULL,                             interval '18 days'),
    (14, 'locked@rebook.vn',  '0999999994', 'Trịnh Văn Khoá',  'LOCKED', NULL,              0, 'Nhiều lần đăng thông tin sai sự thật', interval '35 days'),
    (15, 'banned@rebook.vn',  '0999999995', 'Cao Thị Bỏ Cọc',  'ACTIVE', now() + interval '60 days', 1, NULL,                   interval '33 days')
) AS v(id, email, phone, full_name, status, banned_until, strikes, lock_reason, age);

INSERT INTO shops (id, user_id, name, description, pickup_address, pickup_province, bank_name, bank_account_number,
                   bank_account_holder, rating_avg, rating_count, trusted, created_at) VALUES
    (3, 8, 'Sách Xưa Đà Nẵng', 'Chuyên sách cổ, tiểu thuyết kinh điển và truyện tranh sưu tầm.',
        '45 Bạch Đằng, P. Hải Châu 1, Hải Châu', 'Đà Nẵng', 'BIDV', '31410001234567', 'BUI QUANG HUY', 0, 0, TRUE, now() - interval '37 days'),
    (4, 9, 'Góc Sách Mai Mai', 'Shop mới mở: sách thiếu nhi và kỹ năng sống giá mềm.',
        '77 Lê Văn Sỹ, P. 13, Quận 3', 'TP. Hồ Chí Minh', 'MB Bank', '0123456789012', 'NGO THANH MAI', 0, 0, FALSE, now() - interval '2 days');

INSERT INTO addresses (id, user_id, receiver_name, phone, province, district, ward, detail, is_default) VALUES
    (7,  8,  'Bùi Quang Huy',  '0966666666', 'Đà Nẵng',         'Hải Châu',   'Phường Hải Châu 1', '45 Bạch Đằng', TRUE),
    (8,  9,  'Ngô Thanh Mai',  '0977777777', 'TP. Hồ Chí Minh', 'Quận 3',     'Phường 13',         '77 Lê Văn Sỹ', TRUE),
    (9,  10, 'Hoàng Gia Bảo',  '0988888888', 'Hà Nội',          'Cầu Giấy',   'Phường Dịch Vọng',  '18 Trần Thái Tông', TRUE),
    (10, 11, 'Đỗ Khánh Linh',  '0999999991', 'TP. Hồ Chí Minh', 'Quận 10',    'Phường 12',         '210 Sư Vạn Hạnh', TRUE),
    (11, 12, 'Lý Minh Tuấn',   '0999999992', 'Cần Thơ',         'Ninh Kiều',  'Phường Xuân Khánh', '5 Nguyễn Văn Cừ', TRUE),
    (12, 13, 'Phan Thảo Vy',   '0999999993', 'Hà Nội',          'Đống Đa',    'Phường Láng Hạ',    '66 Thái Hà', TRUE);

-- ---------------------------------------------------------------------
-- Ví: nạp tiền cho người mua, người bán có sẵn doanh thu (sổ cái khớp số dư)
-- ---------------------------------------------------------------------
INSERT INTO wallets (user_id, available_balance, held_balance) SELECT id, 0, 0 FROM users WHERE id BETWEEN 8 AND 15;

CREATE TEMP TABLE demo_topups (user_id bigint, amount numeric, days_ago int, note text);
INSERT INTO demo_topups VALUES
    (5, 3000000, 20, 'Nạp tiền vào ví'), (6, 2500000, 19, 'Nạp tiền vào ví'), (7, 2000000, 18, 'Nạp tiền vào ví'),
    (10, 4000000, 26, 'Nạp tiền vào ví'), (11, 3500000, 25, 'Nạp tiền vào ví'), (12, 3000000, 20, 'Nạp tiền vào ví'),
    (13, 3000000, 16, 'Nạp tiền vào ví'), (15, 1500000, 30, 'Nạp tiền vào ví');

-- Mỗi lần nạp có một payment TOP_UP đã thành công
INSERT INTO payments (code, user_id, purpose, method, amount, status, gateway_txn_id, paid_at, created_at, updated_at)
SELECT 'TOPUP-DEMO-' || user_id || '-' || days_ago, user_id, 'TOP_UP', 'ZALOPAY', amount, 'SUCCESS', 'ZP' || (1000000 + user_id * 31 + days_ago),
       now() - make_interval(days => days_ago), now() - make_interval(days => days_ago), now() - make_interval(days => days_ago)
FROM demo_topups;

INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after, ref_type, ref_id, note, created_at)
SELECT w.id, 'TOP_UP', t.amount, 0, w.available_balance + t.amount, w.held_balance, 'PAYMENT',
       (SELECT p.id FROM payments p WHERE p.code = 'TOPUP-DEMO-' || t.user_id || '-' || t.days_ago), t.note, now() - make_interval(days => t.days_ago)
FROM demo_topups t JOIN wallets w ON w.user_id = t.user_id;

UPDATE wallets w SET available_balance = w.available_balance + COALESCE((SELECT sum(amount) FROM demo_topups t WHERE t.user_id = w.user_id), 0);

-- ---------------------------------------------------------------------
-- ~80 đơn mua thường rải 30 ngày gần nhất, đủ trạng thái
-- ---------------------------------------------------------------------
-- Một phần sách chuyển sang shop ở Đà Nẵng để có đơn đa dạng giữa ba shop
UPDATE listings SET shop_id = 3 WHERE id % 9 = 0;

DO $$
DECLARE
    i int;
    r double precision;
    buyers bigint[] := ARRAY[5, 6, 7, 10, 11, 12, 13];
    buyer bigint;
    l record;
    addr record;
    st text;
    path text[];
    created timestamptz;
    pm text;
    qty int;
    ship numeric;
    sub numeric;
    oid bigint;
    k int;
    step_at timestamptz;
    step_count int;
BEGIN
    FOR i IN 1..80 LOOP
        buyer := buyers[1 + floor(random() * array_length(buyers, 1))::int];
        SELECT li.id, li.shop_id, li.price, b.title, (SELECT url FROM book_images bi WHERE bi.book_id = b.id ORDER BY sort_order LIMIT 1) AS img
          INTO l
          FROM listings li JOIN books b ON b.id = li.book_id
         WHERE li.status = 'ACTIVE' ORDER BY random() LIMIT 1;
        SELECT * INTO addr FROM addresses WHERE user_id = buyer AND is_default LIMIT 1;

        r := random();
        IF r < 0.52 THEN st := 'COMPLETED';
        ELSIF r < 0.60 THEN st := 'CANCELLED';
        ELSIF r < 0.68 THEN st := 'DELIVERED';
        ELSIF r < 0.77 THEN st := 'SHIPPING';
        ELSIF r < 0.84 THEN st := 'PREPARING';
        ELSIF r < 0.91 THEN st := 'PENDING_CONFIRM';
        ELSIF r < 0.95 THEN st := 'RETURN_REQUESTED';
        ELSE st := 'FAILED_DELIVERY';
        END IF;

        -- Ngày đặt: đơn đang xử lý thì mới, đơn đã xong thì rải đều cả tháng
        created := CASE st
            WHEN 'COMPLETED'        THEN now() - make_interval(days => 5 + floor(random() * 25)::int, hours => floor(random() * 20)::int)
            WHEN 'CANCELLED'        THEN now() - make_interval(days => 1 + floor(random() * 28)::int, hours => floor(random() * 20)::int)
            WHEN 'DELIVERED'        THEN now() - make_interval(days => 4, hours => floor(random() * 10)::int)
            WHEN 'SHIPPING'         THEN now() - make_interval(days => 2, hours => floor(random() * 12)::int)
            WHEN 'PREPARING'        THEN now() - make_interval(hours => 20 + floor(random() * 10)::int)
            WHEN 'PENDING_CONFIRM'  THEN now() - make_interval(hours => 1 + floor(random() * 8)::int)
            WHEN 'RETURN_REQUESTED' THEN now() - make_interval(days => 6)
            ELSE now() - make_interval(days => 5)
        END;
        IF st = 'FAILED_DELIVERY' THEN pm := 'COD';
        ELSE pm := (ARRAY['COD', 'WALLET', 'WALLET', 'ZALOPAY', 'ZALOPAY'])[1 + floor(random() * 5)::int];
        END IF;
        qty := CASE WHEN random() < 0.2 THEN 2 ELSE 1 END;
        sub := l.price * qty;
        ship := CASE WHEN addr.province = (SELECT pickup_province FROM shops WHERE id = l.shop_id) THEN 20000 ELSE 30000 END;

        path := CASE st
            WHEN 'COMPLETED'        THEN ARRAY['PENDING_CONFIRM', 'PREPARING', 'SHIPPING', 'DELIVERED', 'COMPLETED']
            WHEN 'CANCELLED'        THEN ARRAY['PENDING_CONFIRM', 'CANCELLED']
            WHEN 'DELIVERED'        THEN ARRAY['PENDING_CONFIRM', 'PREPARING', 'SHIPPING', 'DELIVERED']
            WHEN 'SHIPPING'         THEN ARRAY['PENDING_CONFIRM', 'PREPARING', 'SHIPPING']
            WHEN 'PREPARING'        THEN ARRAY['PENDING_CONFIRM', 'PREPARING']
            WHEN 'PENDING_CONFIRM'  THEN ARRAY['PENDING_CONFIRM']
            WHEN 'RETURN_REQUESTED' THEN ARRAY['PENDING_CONFIRM', 'PREPARING', 'SHIPPING', 'DELIVERED', 'RETURN_REQUESTED']
            ELSE ARRAY['PENDING_CONFIRM', 'PREPARING', 'SHIPPING', 'FAILED_DELIVERY']
        END;
        step_count := array_length(path, 1);

        INSERT INTO orders (code, buyer_id, shop_id, order_type, status, payment_method, paid_at, subtotal, shipping_fee, buyer_premium,
                            deposit_applied, total, address_snapshot, pickup_at_warehouse, tracking_code, cancel_reason, fee_percent,
                            confirm_due_at, ship_due_at, shipped_at, delivered_at, completed_at, cancelled_at, created_at, updated_at,
                            cod_remitted_at, cod_paid_out_at)
        VALUES ('RB' || to_char(created, 'YYMMDD') || lpad(i::text, 4, '0'), buyer, l.shop_id, 'NORMAL', st, pm,
                CASE WHEN pm <> 'COD' AND st <> 'CANCELLED' THEN created + interval '5 minutes' END,
                sub, ship, 0, 0, sub + ship,
                jsonb_build_object('receiverName', addr.receiver_name, 'phone', addr.phone, 'province', addr.province,
                                   'district', addr.district, 'ward', addr.ward, 'detail', addr.detail),
                FALSE,
                CASE WHEN st IN ('SHIPPING', 'DELIVERED', 'COMPLETED', 'RETURN_REQUESTED', 'FAILED_DELIVERY') THEN 'GHN' || (100000 + i * 37) END,
                CASE WHEN st = 'CANCELLED' THEN (ARRAY['Người mua đổi ý', 'Đặt nhầm sách', 'Shop hết hàng', 'Muốn đổi địa chỉ nhận'])[1 + floor(random() * 4)::int] END,
                5,
                CASE WHEN st = 'PENDING_CONFIRM' THEN created + interval '24 hours' END,
                CASE WHEN st = 'PREPARING' THEN now() + interval '2 days' END,
                CASE WHEN st IN ('SHIPPING', 'DELIVERED', 'COMPLETED', 'RETURN_REQUESTED', 'FAILED_DELIVERY') THEN created + interval '1 day' END,
                CASE WHEN st IN ('DELIVERED', 'COMPLETED', 'RETURN_REQUESTED') THEN
                    CASE WHEN st = 'DELIVERED' THEN now() - interval '1 day' WHEN st = 'RETURN_REQUESTED' THEN now() - interval '3 days' ELSE created + interval '3 days' END END,
                CASE WHEN st = 'COMPLETED' THEN created + interval '6 days' END,
                CASE WHEN st = 'CANCELLED' THEN created + interval '3 hours' END,
                created, created + interval '1 hour',
                -- COD đã hoàn tất: một nửa đã đối soát, nửa còn lại chờ Admin đối soát
                CASE WHEN pm = 'COD' AND st = 'COMPLETED' AND random() < 0.5 THEN created + interval '8 days' END,
                NULL)
        RETURNING id INTO oid;

        INSERT INTO order_items (order_id, listing_id, title_snapshot, image_snapshot, unit_price, quantity)
        VALUES (oid, l.id, l.title, l.img, l.price, qty);

        FOR k IN 1..step_count LOOP
            step_at := created + make_interval(hours => (k - 1) * 14);
            IF step_at > now() THEN step_at := now() - interval '10 minutes'; END IF;
            INSERT INTO order_status_history (order_id, from_status, to_status, actor_id, note, created_at)
            VALUES (oid, CASE WHEN k = 1 THEN NULL ELSE path[k - 1] END, path[k],
                    CASE WHEN path[k] IN ('PENDING_CONFIRM') THEN buyer WHEN path[k] = 'CANCELLED' THEN buyer
                         ELSE (SELECT user_id FROM shops WHERE id = l.shop_id) END, NULL, step_at);
        END LOOP;
    END LOOP;
END $$;

UPDATE orders SET cod_paid_out_at = cod_remitted_at + interval '1 day'
 WHERE cod_remitted_at IS NOT NULL AND cod_remitted_at + interval '1 day' < now() AND random() < 0.7;

-- Đánh giá cho khoảng 60% đơn đã hoàn tất, rồi cập nhật điểm shop
INSERT INTO reviews (order_id, reviewer_id, shop_id, rating, comment, created_at)
SELECT o.id, o.buyer_id, o.shop_id, 3 + floor(random() * 3)::int,
       (ARRAY['Sách đúng mô tả, đóng gói cẩn thận.', 'Giao nhanh, sách sạch đẹp.', 'Giá tốt so với bìa, shop nhiệt tình.',
              'Sách hơi cũ hơn hình một chút nhưng vẫn ok.', 'Rất hài lòng, sẽ ủng hộ tiếp.'])[1 + floor(random() * 5)::int],
       o.completed_at + interval '1 day'
FROM orders o WHERE o.status = 'COMPLETED' AND o.order_type = 'NORMAL' AND random() < 0.6;

UPDATE shops s SET rating_avg = COALESCE((SELECT round(avg(rating)::numeric, 2) FROM reviews r WHERE r.shop_id = s.id), 0),
                   rating_count = (SELECT count(*) FROM reviews r WHERE r.shop_id = s.id);
UPDATE listings l SET sold_count = COALESCE((SELECT sum(oi.quantity) FROM order_items oi JOIN orders o ON o.id = oi.order_id
                                              WHERE oi.listing_id = l.id AND o.status IN ('COMPLETED', 'DELIVERED', 'SHIPPING')), 0);

-- ---------------------------------------------------------------------
-- Khiếu nại trả hàng: 1 chờ shop trả lời, 1 chờ Admin phân xử, 1 đã đồng ý trả đang chờ hàng về
-- ---------------------------------------------------------------------
WITH ret AS (
    SELECT id, row_number() OVER (ORDER BY id) AS n FROM orders WHERE status = 'RETURN_REQUESTED'
)
INSERT INTO return_requests (order_id, reason, description, status, seller_note, created_at, updated_at, approved_at)
SELECT ret.id,
       (ARRAY['MISSING_PAGES', 'WRONG_CONDITION', 'WRONG_EDITION'])[ret.n],
       (ARRAY['Sách bị thiếu mất mấy trang cuối, không như mô tả của shop.',
              'Bìa và ruột ố vàng nhiều hơn so với ảnh, tình trạng không phải "Tốt".',
              'Shop gửi bản in khác với bản trong hình đăng bán.'])[ret.n],
       (ARRAY['PENDING', 'DISPUTED', 'AWAITING_GOODS'])[ret.n],
       CASE WHEN ret.n = 2 THEN 'Sách đúng như mô tả, tôi đã chụp kỹ trước khi gửi. Đề nghị sàn xem lại.' END,
       now() - interval '6 hours' * ret.n, now() - interval '3 hours' * ret.n,
       CASE WHEN ret.n = 3 THEN now() - interval '1 day' END
FROM ret WHERE ret.n <= 3;

-- ---------------------------------------------------------------------
-- Tiền người bán: doanh thu từ đơn đã hoàn tất vào ví (sổ cái chạy theo thời gian), rồi các yêu cầu rút tiền
-- ---------------------------------------------------------------------
CREATE TEMP TABLE demo_ledger (user_id bigint, ts timestamptz, type text, avail numeric, held numeric, note text, ref_type text, ref_id bigint);

INSERT INTO demo_ledger
SELECT s.user_id, o.completed_at, 'SALE_RELEASE', round(o.subtotal * 0.95), 0, 'Tiền bán hàng đơn ' || o.code, 'ORDER', o.id
FROM orders o JOIN shops s ON s.id = o.shop_id WHERE o.status = 'COMPLETED' AND o.payment_method <> 'COD';

-- Shop Sách Xưa Đà Nẵng: doanh thu từ các đơn bán lẻ cũ (ngoài 30 ngày hiển thị)
INSERT INTO demo_ledger VALUES
    (8, now() - interval '20 days', 'SALE_RELEASE', 2300000, 0, 'Tiền bán hàng đơn RB-DN-0001', 'ORDER', NULL),
    (8, now() - interval '12 days', 'SALE_RELEASE', 1800000, 0, 'Tiền bán hàng đơn RB-DN-0002', 'ORDER', NULL);

-- Shop mới mở: hai đơn vừa hoàn tất, tiền còn bị giữ theo luật giữ tiền shop mới
INSERT INTO demo_ledger VALUES
    (9, now() - interval '30 hours', 'SALE_RELEASE', 142500, 0, 'Tiền bán hàng đơn RB-MOI-0001', 'ORDER', NULL),
    (9, now() - interval '12 hours', 'SALE_RELEASE', 213750, 0, 'Tiền bán hàng đơn RB-MOI-0002', 'ORDER', NULL);

-- Rút tiền: 2 đã chuyển, 1 bị từ chối, 3 đang chờ Admin
INSERT INTO withdraw_requests (id, user_id, amount, bank_name, account_number, account_holder, status, note, processed_by, processed_at, created_at, user_note) VALUES
    (1, 3, 1500000, 'Vietcombank', '0071000123456', 'TRAN MINH THU',  'APPROVED', 'Đã chuyển khoản', 1, now() - interval '9 days', now() - interval '10 days', 'Rút tiền bán sách tháng này'),
    (2, 4, 900000,  'Techcombank', '19033445566',   'LE HOANG NAM',   'APPROVED', 'Đã chuyển khoản', 1, now() - interval '5 days', now() - interval '6 days',  NULL),
    (3, 8, 3000000, 'BIDV',        '31410001234567', 'BUI QUANG HUY', 'REJECTED', 'Số tài khoản không khớp tên chủ shop', 1, now() - interval '3 days', now() - interval '4 days', NULL),
    (4, 3, 1200000, 'Vietcombank', '0071000123456', 'TRAN MINH THU',  'PENDING',  NULL, NULL, NULL, now() - interval '5 hours', NULL),
    (5, 4, 800000,  'Techcombank', '19033445566',   'LE HOANG NAM',   'PENDING',  NULL, NULL, NULL, now() - interval '3 hours', 'Cần tiền gấp, nhờ Admin duyệt sớm'),
    (6, 8, 2000000, 'BIDV',        '31410001234567', 'BUI QUANG HUY', 'PENDING',  NULL, NULL, NULL, now() - interval '1 hour', NULL);

INSERT INTO withdraw_transfers (withdraw_id, admin_id, sender_name, transfer_time, amount, proof_image_url, created_at) VALUES
    (1, 1, 'CONG TY REBOOK', now() - interval '9 days', 1500000, 'https://placehold.co/600x800/e8efff/14181f/png?text=Bien+lai+1', now() - interval '9 days'),
    (2, 1, 'CONG TY REBOOK', now() - interval '5 days', 900000,  'https://placehold.co/600x800/e8efff/14181f/png?text=Bien+lai+2', now() - interval '5 days');

-- Đã chuyển: tiền ra khỏi ví; đang chờ: tiền chuyển sang "đang giữ"
INSERT INTO demo_ledger
SELECT user_id, processed_at, 'WITHDRAW', -amount, 0, 'Rút tiền về ' || bank_name, 'WITHDRAW', id FROM withdraw_requests WHERE status = 'APPROVED'
UNION ALL
SELECT user_id, created_at, 'WITHDRAW', -amount, amount, 'Khoá tiền chờ duyệt rút', 'WITHDRAW', id FROM withdraw_requests WHERE status = 'PENDING';

INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after, ref_type, ref_id, note, created_at)
SELECT w.id, d.type, d.avail, d.held,
       w.available_balance + sum(d.avail) OVER (PARTITION BY d.user_id ORDER BY d.ts, d.ref_id ROWS UNBOUNDED PRECEDING),
       w.held_balance + sum(d.held) OVER (PARTITION BY d.user_id ORDER BY d.ts, d.ref_id ROWS UNBOUNDED PRECEDING),
       d.ref_type, d.ref_id, d.note, d.ts
FROM demo_ledger d JOIN wallets w ON w.user_id = d.user_id;

UPDATE wallets w SET available_balance = w.available_balance + COALESCE((SELECT sum(avail) FROM demo_ledger d WHERE d.user_id = w.user_id), 0),
                     held_balance = w.held_balance + COALESCE((SELECT sum(held) FROM demo_ledger d WHERE d.user_id = w.user_id), 0)
 WHERE w.user_id IN (SELECT user_id FROM demo_ledger);

-- ---------------------------------------------------------------------
-- Nợ và vi phạm
-- ---------------------------------------------------------------------
INSERT INTO account_debts (user_id, type, amount, paid_amount, status, ref_type, note, created_at, settled_at) VALUES
    (15, 'AUCTION_PENALTY', 250000, 0,      'OPEN', 'LOT',      'Bỏ thanh toán lô thắng đấu giá', now() - interval '12 days', NULL),
    (13, 'CHARGEBACK',      500000, 0,      'OPEN', 'PAYMENT',  'Ngân hàng đòi lại tiền nạp (mã tra soát CB-2026-0192)', now() - interval '2 days', NULL),
    (4,  'STORAGE_FEE',     80000,  0,      'OPEN', 'CONSIGNMENT', 'Phí lưu kho quá hạn nhận lại sách', now() - interval '4 days', NULL),
    (11, 'AUCTION_PENALTY', 150000, 150000, 'PAID', 'LOT',      'Bỏ thanh toán lô thắng đấu giá (đã nộp phạt)', now() - interval '25 days', now() - interval '20 days');

-- ---------------------------------------------------------------------
-- Tin đăng chờ duyệt / bị từ chối (shop 2 chưa là shop uy tín)
-- ---------------------------------------------------------------------
INSERT INTO books (id, owner_id, title, author, publisher, publish_year, language, pages, category_id, condition_grade, description, weight_gram) VALUES
    (95, 4, 'Tuổi Thơ Dữ Dội', 'Phùng Quán', 'NXB Kim Đồng', 2018, 'Tiếng Việt', 420, 2, 'GOOD', 'Bìa mềm, gáy hơi sờn, ruột sạch.', 380),
    (96, 4, 'Dạy Con Làm Giàu - Tập 1', 'Robert Kiyosaki', 'NXB Trẻ', 2019, 'Tiếng Việt', 280, 67, 'VERY_GOOD', 'Có ghi chú bút chì nhẹ vài trang.', 330),
    (97, 4, 'Lược Sử Loài Người', 'Yuval Noah Harari', 'NXB Tri Thức', 2020, 'Tiếng Việt', 548, 61, 'LIKE_NEW', 'Gần như mới, đọc một lần.', 600),
    (98, 4, 'Cho Tôi Xin Một Vé Đi Tuổi Thơ', 'Nguyễn Nhật Ánh', 'NXB Trẻ', 2017, 'Tiếng Việt', 208, 2, 'ACCEPTABLE', 'Bìa trầy, ố nhiều, thiếu tờ lót.', 240);

INSERT INTO book_images (book_id, url, sort_order, source)
SELECT b.id, (SELECT bi.url FROM book_images bi WHERE bi.book_id = ((b.id - 95) * 7 + 3) LIMIT 1), 0, 'SELLER'
FROM books b WHERE b.id BETWEEN 95 AND 98;

INSERT INTO listings (book_id, shop_id, price, stock, status, reject_reason, created_at, updated_at, reviewed_by, reviewed_at) VALUES
    (95, 2, 85000,  1, 'PENDING_REVIEW', NULL, now() - interval '3 hours',  now() - interval '3 hours', NULL, NULL),
    (96, 2, 62000,  2, 'PENDING_REVIEW', NULL, now() - interval '90 minutes', now() - interval '90 minutes', NULL, NULL),
    (97, 2, 145000, 1, 'PENDING_REVIEW', NULL, now() - interval '30 minutes', now() - interval '30 minutes', NULL, NULL),
    (98, 2, 30000,  1, 'REJECTED', 'Ảnh mờ và tình trạng ghi chưa khớp với ảnh thực tế', now() - interval '2 days', now() - interval '1 day', 1, now() - interval '1 day');

-- ---------------------------------------------------------------------
-- Thông báo và nhật ký Admin
-- ---------------------------------------------------------------------
INSERT INTO notifications (user_id, type, title, body, is_read, created_at) VALUES
    (5, 'ORDER',   'Đơn hàng đang được giao', 'Đơn của bạn đã được bàn giao cho đơn vị vận chuyển.', FALSE, now() - interval '5 hours'),
    (5, 'WALLET',  'Nạp tiền thành công', 'Ví của bạn đã được cộng 3.000.000 ₫.', TRUE, now() - interval '20 days'),
    (6, 'AUCTION', 'Phiên đấu giá sắp bắt đầu', 'Phiên "Sách văn học Mỹ thế kỷ 20" bắt đầu sau vài phút. Phòng chờ đã mở!', FALSE, now() - interval '2 minutes'),
    (7, 'ORDER',   'Đơn hàng đã hoàn tất', 'Cảm ơn bạn đã mua sắm. Hãy đánh giá shop nhé!', TRUE, now() - interval '3 days'),
    (3, 'ORDER',   'Có đơn mới', 'Bạn có đơn hàng mới đang chờ xác nhận.', FALSE, now() - interval '2 hours'),
    (3, 'WALLET',  'Yêu cầu rút tiền đang chờ duyệt', 'Yêu cầu rút 1.200.000 ₫ của bạn đang được Admin xem xét.', FALSE, now() - interval '5 hours'),
    (4, 'LISTING', 'Tin đăng bị từ chối', 'Tin "Cho Tôi Xin Một Vé Đi Tuổi Thơ" bị từ chối: ảnh mờ.', FALSE, now() - interval '1 day'),
    (8, 'WALLET',  'Yêu cầu rút tiền bị từ chối', 'Số tài khoản không khớp tên chủ shop.', TRUE, now() - interval '3 days'),
    (13, 'WALLET', 'Tiền nạp bị đòi lại', 'Ngân hàng đã đòi lại khoản nạp của bạn, khoản nợ 500.000 ₫ đã được ghi nhận.', FALSE, now() - interval '2 days'),
    (15, 'AUCTION', 'Bạn bị cấm đấu giá', 'Bạn bỏ thanh toán lô thắng nên bị cấm đấu giá 60 ngày.', TRUE, now() - interval '12 days');

INSERT INTO admin_activity_logs (admin_id, action, target_type, target_id, summary, created_at) VALUES
    (1, 'APPROVE_LISTING',   'LISTING',    '12', 'Duyệt tin "Dế Mèn Phiêu Lưu Ký"', now() - interval '6 days'),
    (1, 'APPROVE_LISTING',   'LISTING',    '33', 'Duyệt tin "Nhà Giả Kim"', now() - interval '5 days'),
    (1, 'REJECT_LISTING',    'LISTING',    '73', 'Từ chối tin "Cho Tôi Xin Một Vé Đi Tuổi Thơ": ảnh mờ', now() - interval '1 day'),
    (1, 'LOCK_USER',         'USER',       '14', 'Khoá locked@rebook.vn: Nhiều lần đăng thông tin sai sự thật', now() - interval '8 days'),
    (1, 'APPROVE_WITHDRAWAL','WITHDRAWAL', '1',  'Duyệt rút tiền 1.500.000 ₫ cho Trần Minh Thư', now() - interval '9 days'),
    (1, 'APPROVE_WITHDRAWAL','WITHDRAWAL', '2',  'Duyệt rút tiền 900.000 ₫ cho Lê Hoàng Nam', now() - interval '5 days'),
    (1, 'REJECT_WITHDRAWAL', 'WITHDRAWAL', '3',  'Từ chối rút tiền của Bùi Quang Huy: số tài khoản không khớp', now() - interval '3 days'),
    (1, 'UPDATE_CONFIG',     'CONFIG',     'fee.buyer_premium_percent', 'Đổi phí người mua đấu giá từ 8% lên 10%', now() - interval '15 days');

-- ---------------------------------------------------------------------
-- Đấu giá: 5 phiên + 24 sách hiếm (đã có từ V21_1, mỗi cuốn có hợp đồng ký gửi, phiếu nhập kho, biên bản kiểm định)
-- ---------------------------------------------------------------------
INSERT INTO auction_sessions (id, title, description, start_at, registration_deadline, min_participants, deposit_amount, lot_duration_sec,
                              soft_close_sec, lot_gap_sec, status, published_at, started_at, ended_at, created_by, buyer_premium_percent,
                              bid_increment_tiers, bid_limit_multiplier, reminder_sent, created_at) VALUES
    (1, 'Văn học Mỹ thế kỷ 20 — Phiên mùa thu', 'Bốn bản gốc tiếng Anh của các tác giả Mỹ và Anh, đã kiểm định tại kho ReBook.',
        now() - interval '6 days', now() - interval '6 days 2 hours', 3, 500000, 120, 30, 20, 'ENDED',
        now() - interval '12 days', now() - interval '6 days', now() - interval '6 days' + interval '28 minutes', 1, 10,
        '0:10000,200000:50000,1000000:100000,5000000:500000', 10, TRUE, now() - interval '14 days'),
    (2, 'Kinh điển châu Âu — Phiên cuối tuần', 'Những cuốn tiểu thuyết kinh điển châu Âu nhiều lần tái bản.',
        now() - interval '20 hours', now() - interval '22 hours', 3, 500000, 120, 30, 20, 'ENDED',
        now() - interval '5 days', now() - interval '20 hours', now() - interval '20 hours' + interval '30 minutes', 1, 10,
        '0:10000,200000:50000,1000000:100000,5000000:500000', 10, TRUE, now() - interval '7 days'),
    (3, 'Hemingway & Steinbeck — Sắp mở', 'Phiên sắp bắt đầu: vào phòng chờ để chuẩn bị trả giá.',
        now() + interval '4 minutes', now() - interval '30 minutes', 3, 300000, 120, 30, 20, 'CONFIRMED',
        now() - interval '2 days', NULL, NULL, 1, 10,
        '0:10000,200000:50000,1000000:100000,5000000:500000', 10, FALSE, now() - interval '3 days'),
    (4, 'Trinh thám Mỹ & Kỳ ảo — Mở đăng ký', 'Đang mở đăng ký tham gia, còn thiếu người để phiên diễn ra.',
        now() + interval '1 day', now() + interval '20 hours', 3, 400000, 120, 30, 20, 'PUBLISHED',
        now() - interval '1 day', NULL, NULL, 1, 10,
        '0:10000,200000:50000,1000000:100000,5000000:500000', 10, FALSE, now() - interval '2 days'),
    (5, 'Tuyển tập sách hiếm tháng 12 (nháp)', 'Admin đang xếp lô, chưa công bố.',
        now() + interval '3 days', now() + interval '2 days', 3, 500000, 120, 30, 20, 'DRAFT',
        NULL, NULL, NULL, 1, 10,
        '0:10000,200000:50000,1000000:100000,5000000:500000', 10, FALSE, now() - interval '3 hours');

CREATE TEMP TABLE demo_rare AS
SELECT b.id::int AS book_id, b.owner_id, b.title,
       (800000 + ((b.id * 7) % 6) * 450000)::numeric AS est_low,
       CASE WHEN b.id BETWEEN 71 AND 74 THEN 1 WHEN b.id BETWEEN 75 AND 78 THEN 2 WHEN b.id BETWEEN 79 AND 83 THEN 3
            WHEN b.id BETWEEN 84 AND 87 THEN 4 END AS session_id,
       CASE WHEN b.id BETWEEN 71 AND 74 THEN b.id - 70 WHEN b.id BETWEEN 75 AND 78 THEN b.id - 74
            WHEN b.id BETWEEN 79 AND 83 THEN b.id - 78 WHEN b.id BETWEEN 84 AND 87 THEN b.id - 83 END AS lot_no
FROM books b WHERE b.id BETWEEN 71 AND 94;

-- Hợp đồng ký gửi đã được chấp nhận cho cả 24 cuốn
INSERT INTO consignments (code, seller_id, book_id, expected_price, provenance, status, appointment_at, appointment_code, approved_at,
                          received_at, received_by, created_at, updated_at)
SELECT 'CG' || to_char(now() - make_interval(days => 40 - (book_id - 70)), 'YYMMDD') || lpad(book_id::text, 3, '0'), owner_id, book_id,
       round(est_low * 0.9, -4), 'Sách thừa kế từ gia đình, giữ cẩn thận trong tủ kính.', 'ACCEPTED',
       now() - make_interval(days => 34 - (book_id - 70)), 'HEN' || lpad(book_id::text, 4, '0'), now() - make_interval(days => 38 - (book_id - 70)),
       now() - make_interval(days => 33 - (book_id - 70)), 2, now() - make_interval(days => 40 - (book_id - 70)), now() - make_interval(days => 20)
FROM demo_rare;

INSERT INTO inspections (consignment_id, inspector_id, result, checklist, condition_grade, condition_report, estimate_low, estimate_high,
                         proposed_start, proposed_reserve, seller_decision, decided_at, created_at)
SELECT c.id, 2, 'PASS', '{"authentic": true, "complete": true, "noWater": true, "binding": "good"}'::jsonb, 'GOOD',
       'Bìa và gáy còn chắc, ruột sạch, không mất trang. Đã đối chiếu ấn bản.', r.est_low, round(r.est_low * 1.6, -4),
       round(r.est_low * 0.5, -4), round(r.est_low * 0.8, -4), 'ACCEPTED', now() - make_interval(days => 28 - (r.book_id - 70)),
       now() - make_interval(days => 30 - (r.book_id - 70))
FROM demo_rare r JOIN consignments c ON c.book_id = r.book_id;

INSERT INTO warehouse_items (consignment_id, code, shelf_code, status, checked_in_at, updated_at)
SELECT c.id, 'KHO' || lpad(r.book_id::text, 4, '0'), 'K' || ((r.book_id % 4) + 1) || '-' || lpad((r.book_id % 9 + 1)::text, 2, '0'),
       'IN_STOCK', now() - make_interval(days => 33 - (r.book_id - 70)), now() - make_interval(days => 20)
FROM demo_rare r JOIN consignments c ON c.book_id = r.book_id;

-- Lô: phiên 1–4 đã xếp lô, 7 cuốn còn lại chờ Admin xếp phiên
INSERT INTO lots (session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low, estimate_high, current_price,
                  status, commission_percent, created_at)
SELECT r.session_id, c.id, r.book_id, r.lot_no, round(r.est_low * 0.5, -4), round(r.est_low * 0.8, -4), r.est_low, round(r.est_low * 1.6, -4),
       round(r.est_low * 0.5, -4), CASE WHEN r.session_id IS NULL THEN 'READY' ELSE 'SCHEDULED' END, 15, now() - interval '20 days'
FROM demo_rare r JOIN consignments c ON c.book_id = r.book_id ORDER BY r.book_id;

-- Kết quả hai phiên đã xong (giờ mở / chốt từng lô theo giờ phiên)
UPDATE lots l SET
    opened_at = s.started_at + make_interval(mins => (l.lot_number - 1) * 6),
    ends_at   = s.started_at + make_interval(mins => (l.lot_number - 1) * 6 + 4),
    closed_at = s.started_at + make_interval(mins => (l.lot_number - 1) * 6 + 4),
    rounds = 1
FROM auction_sessions s WHERE s.id = l.session_id AND s.id IN (1, 2);

UPDATE lots SET status = 'COMPLETED', close_result = 'SOLD', winner_id = 5,  hammer_price = round(reserve_price * 1.4, -4) WHERE book_id = 71;
UPDATE lots SET status = 'PAID',      close_result = 'SOLD', winner_id = 10, hammer_price = round(reserve_price * 1.35, -4) WHERE book_id = 72;
UPDATE lots SET status = 'UNSOLD',    close_result = 'NO_BIDS' WHERE book_id = 73;
UPDATE lots SET status = 'COMPLETED', close_result = 'SOLD', winner_id = 11, hammer_price = round(reserve_price * 1.2, -4) WHERE book_id = 74;
UPDATE lots SET status = 'SOLD',      close_result = 'SOLD', winner_id = 6,  hammer_price = round(reserve_price * 1.5, -4) WHERE book_id = 75;
UPDATE lots SET status = 'SOLD',      close_result = 'SOLD', winner_id = 12, hammer_price = round(reserve_price * 1.25, -4) WHERE book_id = 76;
UPDATE lots SET status = 'UNSOLD',    close_result = 'RESERVE_NOT_MET', current_price = round(reserve_price * 0.9, -4) WHERE book_id = 77;
UPDATE lots SET status = 'PAID',      close_result = 'SOLD', winner_id = 7,  hammer_price = round(reserve_price * 1.45, -4) WHERE book_id = 78;
UPDATE lots SET current_price = hammer_price, current_winner_id = winner_id WHERE hammer_price IS NOT NULL;

UPDATE warehouse_items w SET status = 'RESERVED' FROM consignments c JOIN lots l ON l.consignment_id = c.id
 WHERE w.consignment_id = c.id AND l.status IN ('SOLD', 'PAID');
UPDATE warehouse_items w SET status = 'SHIPPED', checked_out_at = now() - interval '3 days', checkout_reason = 'Giao cho người thắng đấu giá'
  FROM consignments c JOIN lots l ON l.consignment_id = c.id WHERE w.consignment_id = c.id AND l.status = 'COMPLETED';
UPDATE consignments c SET updated_at = now() - interval '2 days' FROM lots l WHERE l.consignment_id = c.id AND l.status = 'COMPLETED';

-- Đăng ký của hai phiên đã xong: người thắng đã trừ cọc vào đơn (APPLIED), còn lại hoàn cọc (REFUNDED)
INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status, created_at, updated_at)
SELECT s.id, u.user_id, u.n, 500000, 5000000,
       CASE WHEN EXISTS (SELECT 1 FROM lots l WHERE l.session_id = s.id AND l.winner_id = u.user_id) THEN 'APPLIED' ELSE 'REFUNDED' END,
       s.created_at + interval '1 day', s.ended_at
FROM auction_sessions s CROSS JOIN (VALUES (5, 1), (6, 2), (7, 3), (10, 4), (11, 5), (12, 6)) AS u(user_id, n)
WHERE s.id IN (1, 2);

-- Các lượt trả giá: tăng dần từ giá khởi điểm tới giá búa, người thắng trả cuối cùng
INSERT INTO bids (lot_id, user_id, registration_id, amount, is_auto, created_at)
SELECT l.id, reg.user_id, reg.id,
       CASE WHEN k = 5 THEN l.hammer_price ELSE round((l.start_price + (l.hammer_price - l.start_price) * k / 6) / 10000) * 10000 END,
       (k = 3), l.opened_at + make_interval(secs => k * 40)
FROM lots l
JOIN generate_series(1, 5) AS k ON TRUE
JOIN LATERAL (SELECT r.id, r.user_id FROM auction_registrations r
               WHERE r.session_id = l.session_id
                 AND r.user_id = CASE WHEN k = 5 THEN l.winner_id ELSE (ARRAY[5, 6, 7, 10, 11, 12])[1 + ((l.id + k) % 6)] END LIMIT 1) reg ON TRUE
WHERE l.hammer_price IS NOT NULL;
-- Lô không đạt giá sàn: 3 lượt trả giá thấp hơn giá sàn
INSERT INTO bids (lot_id, user_id, registration_id, amount, is_auto, created_at)
SELECT l.id, r.user_id, r.id, round((l.start_price + (l.reserve_price - l.start_price) * k / 5) / 10000) * 10000, FALSE, l.opened_at + make_interval(secs => k * 50)
FROM lots l JOIN generate_series(1, 3) k ON TRUE
JOIN auction_registrations r ON r.session_id = l.session_id AND r.user_id = (ARRAY[6, 7, 12])[k]
WHERE l.close_result = 'RESERVE_NOT_MET';
UPDATE lots l SET bid_count = (SELECT count(*) FROM bids b WHERE b.lot_id = l.id);

-- Đơn của các lô đã bán (người thắng trả phí người mua 10%, trừ tiền cọc đã nộp)
DO $$
DECLARE
    lt record;
    a record;
    st text;
    oid bigint;
    prem numeric;
    created timestamptz;
BEGIN
    FOR lt IN SELECT l.*, b.title, (SELECT url FROM book_images bi WHERE bi.book_id = b.id ORDER BY sort_order LIMIT 1) AS img
               FROM lots l JOIN books b ON b.id = l.book_id WHERE l.winner_id IS NOT NULL ORDER BY l.id LOOP
        SELECT * INTO a FROM addresses WHERE user_id = lt.winner_id AND is_default LIMIT 1;
        prem := round(lt.hammer_price * 0.10);
        created := lt.closed_at + interval '2 minutes';
        st := CASE lt.status WHEN 'COMPLETED' THEN 'COMPLETED' WHEN 'PAID' THEN 'PREPARING' ELSE 'PENDING_PAYMENT' END;
        INSERT INTO orders (code, buyer_id, shop_id, lot_id, order_type, status, payment_method, paid_at, subtotal, shipping_fee, buyer_premium,
                            deposit_applied, total, address_snapshot, pickup_at_warehouse, payment_due_at, ship_due_at, shipped_at, delivered_at,
                            completed_at, fee_percent, created_at, updated_at)
        VALUES ('RBA' || to_char(created, 'YYMMDD') || lpad(lt.id::text, 3, '0'), lt.winner_id, NULL, lt.id, 'AUCTION', st,
                CASE WHEN st <> 'PENDING_PAYMENT' THEN 'WALLET' END,
                CASE WHEN st <> 'PENDING_PAYMENT' THEN created + interval '3 hours' END,
                lt.hammer_price, 30000, prem, 500000, lt.hammer_price + 30000 + prem - 500000,
                jsonb_build_object('receiverName', a.receiver_name, 'phone', a.phone, 'province', a.province, 'district', a.district,
                                   'ward', a.ward, 'detail', a.detail),
                FALSE,
                CASE WHEN st = 'PENDING_PAYMENT' THEN now() + (CASE WHEN lt.book_id = 75 THEN interval '28 hours' ELSE interval '6 hours' END) END,
                CASE WHEN st = 'PREPARING' THEN now() + interval '2 days' END,
                CASE WHEN st = 'COMPLETED' THEN created + interval '1 day' END,
                CASE WHEN st = 'COMPLETED' THEN created + interval '3 days' END,
                CASE WHEN st = 'COMPLETED' THEN created + interval '4 days' END,
                15, created, created)
        RETURNING id INTO oid;
        INSERT INTO order_items (order_id, lot_id, title_snapshot, image_snapshot, unit_price, quantity)
        VALUES (oid, lt.id, lt.title, lt.img, lt.hammer_price, 1);
        INSERT INTO order_status_history (order_id, from_status, to_status, actor_id, note, created_at)
        VALUES (oid, NULL, CASE WHEN st = 'PENDING_PAYMENT' THEN 'PENDING_PAYMENT' ELSE 'PENDING_CONFIRM' END, lt.winner_id, 'Thắng lô đấu giá', created);
        IF st = 'PREPARING' THEN
            INSERT INTO order_status_history (order_id, from_status, to_status, actor_id, created_at)
            VALUES (oid, 'PENDING_CONFIRM', 'PREPARING', 2, created + interval '5 hours');
        ELSIF st = 'COMPLETED' THEN
            INSERT INTO order_status_history (order_id, from_status, to_status, actor_id, created_at) VALUES
                (oid, 'PENDING_CONFIRM', 'PREPARING', 2, created + interval '5 hours'),
                (oid, 'PREPARING', 'SHIPPING', 2, created + interval '1 day'),
                (oid, 'SHIPPING', 'DELIVERED', 2, created + interval '3 days'),
                (oid, 'DELIVERED', 'COMPLETED', 2, created + interval '4 days');
        END IF;
    END LOOP;
END $$;

-- Hai phiên sắp tới: người đăng ký đã khoá cọc (ví khớp sổ cái)
INSERT INTO auction_registrations (session_id, user_id, paddle_number, deposit_amount, bid_limit, status, created_at, updated_at)
SELECT v.session_id, v.user_id, v.n, s.deposit_amount, s.deposit_amount * 10, 'APPROVED', now() - make_interval(hours => v.hours), now() - make_interval(hours => v.hours)
FROM (VALUES (3, 5, 1, 30), (3, 6, 2, 28), (3, 7, 3, 20), (3, 10, 4, 12), (3, 11, 5, 5), (4, 12, 1, 6), (4, 13, 2, 2)) AS v(session_id, user_id, n, hours)
JOIN auction_sessions s ON s.id = v.session_id;

INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after, ref_type, ref_id, note, created_at)
SELECT w.id, 'DEPOSIT_HOLD', -r.deposit_amount, r.deposit_amount,
       w.available_balance - sum(r.deposit_amount) OVER (PARTITION BY r.user_id ORDER BY r.created_at ROWS UNBOUNDED PRECEDING) + 0,
       w.held_balance + sum(r.deposit_amount) OVER (PARTITION BY r.user_id ORDER BY r.created_at ROWS UNBOUNDED PRECEDING),
       'SESSION', r.session_id, 'Khoá cọc đăng ký phiên đấu giá', r.created_at
FROM auction_registrations r JOIN wallets w ON w.user_id = r.user_id WHERE r.status = 'APPROVED';
UPDATE wallets w SET available_balance = w.available_balance - COALESCE((SELECT sum(deposit_amount) FROM auction_registrations r WHERE r.user_id = w.user_id AND r.status = 'APPROVED'), 0),
                     held_balance = w.held_balance + COALESCE((SELECT sum(deposit_amount) FROM auction_registrations r WHERE r.user_id = w.user_id AND r.status = 'APPROVED'), 0)
 WHERE w.user_id IN (SELECT user_id FROM auction_registrations WHERE status = 'APPROVED');

INSERT INTO session_watchers (user_id, session_id, created_at) VALUES (5, 4, now() - interval '5 hours'), (6, 4, now() - interval '4 hours'), (7, 3, now() - interval '1 day');

-- ---------------------------------------------------------------------
-- Ký gửi ở mọi bước (Staff duyệt, hẹn, nhận, kiểm định) + sự cố kho
-- ---------------------------------------------------------------------
INSERT INTO books (id, owner_id, title, author, publisher, publish_year, language, pages, category_id, condition_grade, description, weight_gram) VALUES
    (99,  3, 'Truyện Kiều (bản Kiều Oánh Mậu)', 'Nguyễn Du', 'Phúc Văn đường', 1902, 'Tiếng Việt', 220, 10, 'GOOD', 'Bản in chữ Nôm, giấy dó, gáy chỉ khâu tay.', 400),
    (100, 4, 'Nam Phong Tạp Chí (đóng tập 1917-1918)', 'Phạm Quỳnh (chủ biên)', 'Nam Phong', 1918, 'Tiếng Việt', 640, 10, 'ACCEPTABLE', 'Đóng bìa da, các số 1–12.', 1100),
    (101, 8, 'The Old Curiosity Shop', 'Charles Dickens', 'Chapman & Hall', 1841, 'English', 480, 10, 'GOOD', 'Ấn bản đầu tiên, bìa vải xanh.', 700),
    (102, 3, 'Việt Nam Sử Lược', 'Trần Trọng Kim', 'Tân Việt', 1949, 'Tiếng Việt', 560, 10, 'VERY_GOOD', 'Bản in 1949, bìa cứng.', 750),
    (103, 4, 'Vang Bóng Một Thời (in lần đầu)', 'Nguyễn Tuân', 'Tân Dân', 1940, 'Tiếng Việt', 180, 10, 'GOOD', 'Có chữ ký tác giả trang lót.', 280),
    (104, 8, 'Don Quixote', 'Miguel de Cervantes', 'Penguin Classics', 1950, 'English', 940, 10, 'VERY_GOOD', 'Hai tập, bìa hộp.', 1200),
    (105, 3, 'Tắt Đèn (bản 1939)', 'Ngô Tất Tố', 'Mai Linh', 1939, 'Tiếng Việt', 150, 10, 'ACCEPTABLE', 'Giấy ngả vàng, đủ trang.', 220),
    (106, 4, 'Số Đỏ (ấn bản 1946)', 'Vũ Trọng Phụng', 'Hà Nội', 1946, 'Tiếng Việt', 260, 10, 'GOOD', 'Bìa gốc, gáy hơi bung.', 320),
    (107, 8, 'Wuthering Heights', 'Emily Brontë', 'Thomas Newby', 1847, 'English', 520, 10, 'ACCEPTABLE', 'Bản in cũ, nhiều vết ẩm.', 650),
    (108, 3, 'Hoàng Lê Nhất Thống Chí', 'Ngô Gia Văn Phái', 'Nhà in Trung Bắc', 1932, 'Tiếng Việt', 410, 10, 'VERY_GOOD', 'Bản in 1932, bìa mềm nguyên.', 480),
    (109, 4, 'Sách ôn thi đại học (tuyển tập)', 'Nhiều tác giả', 'NXB Giáo Dục', 2012, 'Tiếng Việt', 300, 10, 'GOOD', 'Sách phổ thông.', 400),
    (110, 3, 'Hồn Bướm Mơ Tiên', 'Khái Hưng', 'Đời Nay', 1933, 'Tiếng Việt', 200, 10, 'GOOD', 'Bìa gốc.', 260);

INSERT INTO book_images (book_id, url, sort_order, source)
SELECT b.id, (SELECT bi.url FROM book_images bi WHERE bi.book_id = 71 + ((b.id - 99) % 20) LIMIT 1), 0, 'SELLER' FROM books b WHERE b.id BETWEEN 99 AND 110;

INSERT INTO consignments (code, seller_id, book_id, expected_price, provenance, status, review_note, appointment_at, appointment_code, approved_at, received_at,
                          received_by, created_at, updated_at) VALUES
    ('CG-DEMO-099', 3, 99,  4500000, 'Gia đình giữ ba đời.',            'SUBMITTED', NULL, NULL, NULL, NULL, NULL, NULL, now() - interval '3 hours',  now() - interval '3 hours'),
    ('CG-DEMO-100', 4, 100, 3200000, 'Mua lại từ nhà sưu tầm Huế.',     'SUBMITTED', NULL, NULL, NULL, NULL, NULL, NULL, now() - interval '20 hours', now() - interval '20 hours'),
    ('CG-DEMO-101', 8, 101, 12000000, 'Nhập từ nhà đấu giá Anh năm 2015.', 'SUBMITTED', NULL, NULL, NULL, NULL, NULL, NULL, now() - interval '1 hour',  now() - interval '1 hour'),
    ('CG-DEMO-102', 3, 102, 1800000, 'Sách của ông nội, còn hoá đơn mua.', 'APPROVED', 'Sơ duyệt đạt: đúng chủ đề sách cổ.', NULL, NULL, now() - interval '1 day', NULL, NULL, now() - interval '2 days', now() - interval '1 day'),
    ('CG-DEMO-103', 4, 103, 5500000, 'Có chữ ký tác giả.',                'APPOINTMENT_BOOKED', 'Sơ duyệt đạt.', now() + interval '1 day', 'HEN-DEMO-1', now() - interval '3 days', NULL, NULL, now() - interval '4 days', now() - interval '1 day'),
    ('CG-DEMO-104', 8, 104, 2600000, 'Bộ hai tập nhập khẩu.',            'APPOINTMENT_BOOKED', 'Sơ duyệt đạt.', now() + interval '3 hours', 'HEN-DEMO-2', now() - interval '3 days', NULL, NULL, now() - interval '4 days', now() - interval '1 day'),
    ('CG-DEMO-105', 3, 105, 1500000, 'Mua ở hiệu sách cũ Hà Nội.',       'RECEIVED', 'Sơ duyệt đạt.', now() - interval '6 hours', 'HEN-DEMO-3', now() - interval '5 days', now() - interval '5 hours', 2, now() - interval '6 days', now() - interval '5 hours'),
    ('CG-DEMO-106', 4, 106, 2200000, 'Sách gia đình.',                    'RECEIVED', 'Sơ duyệt đạt.', now() - interval '4 hours', 'HEN-DEMO-4', now() - interval '5 days', now() - interval '2 hours', 2, now() - interval '6 days', now() - interval '2 hours'),
    ('CG-DEMO-107', 8, 107, 900000,  'Mua trên mạng.',                    'INSPECTION_FAILED', 'Sơ duyệt đạt.', now() - interval '4 days', 'HEN-DEMO-5', now() - interval '8 days', now() - interval '3 days', 2, now() - interval '9 days', now() - interval '2 days'),
    ('CG-DEMO-108', 3, 108, 2000000, 'Sách bạn tặng.',                    'AWAITING_SELLER', 'Sơ duyệt đạt.', now() - interval '3 days', 'HEN-DEMO-6', now() - interval '8 days', now() - interval '2 days', 2, now() - interval '9 days', now() - interval '1 day'),
    ('CG-DEMO-109', 4, 109, 300000,  'Sách giáo dục.',                    'REJECTED', 'Sách phổ thông, giá trị thấp, không nhận ký gửi.', NULL, NULL, NULL, NULL, NULL, now() - interval '5 days', now() - interval '4 days'),
    ('CG-DEMO-110', 3, 110, 1000000, 'Bìa gốc.',                          'EXPIRED', 'Quá 7 ngày không mang sách tới kho.', NULL, 'HEN-DEMO-7', now() - interval '12 days', NULL, NULL, now() - interval '14 days', now() - interval '5 days');

INSERT INTO warehouse_items (consignment_id, code, shelf_code, status, checked_in_at, return_notified_at, updated_at)
SELECT c.id, 'KHO-' || right(c.code, 3), 'N-0' || (c.book_id % 5 + 1), 'IN_STOCK', c.received_at,
       CASE WHEN c.status = 'INSPECTION_FAILED' THEN now() - interval '2 days' END, now()
FROM consignments c WHERE c.code LIKE 'CG-DEMO-%' AND c.received_at IS NOT NULL;

INSERT INTO inspections (consignment_id, inspector_id, result, checklist, condition_grade, condition_report, estimate_low, estimate_high,
                         proposed_start, proposed_reserve, seller_decision, created_at)
SELECT c.id, 2, CASE WHEN c.status = 'INSPECTION_FAILED' THEN 'FAIL' ELSE 'PASS' END,
       '{"authentic": true, "complete": true}'::jsonb, CASE WHEN c.status = 'INSPECTION_FAILED' THEN 'ACCEPTABLE' ELSE 'GOOD' END,
       CASE WHEN c.status = 'INSPECTION_FAILED' THEN 'Nhiều trang bị mối mọt và vết ẩm nặng, không đủ điều kiện đấu giá.'
            ELSE 'Sách thật, đủ trang, tình trạng tốt so với năm in.' END,
       CASE WHEN c.status = 'AWAITING_SELLER' THEN 1800000 END, CASE WHEN c.status = 'AWAITING_SELLER' THEN 2800000 END,
       CASE WHEN c.status = 'AWAITING_SELLER' THEN 900000 END, CASE WHEN c.status = 'AWAITING_SELLER' THEN 1500000 END,
       'PENDING', c.received_at + interval '1 hour'
FROM consignments c WHERE c.status IN ('INSPECTION_FAILED', 'AWAITING_SELLER');

-- Sự cố kho đang chờ Admin: một cuốn sách hiếm chưa xếp phiên bị hư do dột nước
INSERT INTO warehouse_incidents (warehouse_item_id, consignment_id, type, description, reported_by, status, stage, base_amount, seller_percent,
                                 seller_amount, created_at)
SELECT w.id, c.id, 'DAMAGED', 'Kệ K3 bị dột nước đêm qua, bìa cuốn sách bị ướt và cong vênh.', 2, 'PENDING', 'INSPECTED', 3000000, 50, 1500000,
       now() - interval '6 hours'
FROM consignments c JOIN warehouse_items w ON w.consignment_id = c.id WHERE c.book_id = 90;

-- ---------------------------------------------------------------------
-- Chốt: sổ cái id, số liệu tổng hợp
-- ---------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('users', 'id'), (SELECT max(id) FROM users));
SELECT setval(pg_get_serial_sequence('shops', 'id'), (SELECT max(id) FROM shops));
SELECT setval(pg_get_serial_sequence('addresses', 'id'), (SELECT max(id) FROM addresses));
SELECT setval(pg_get_serial_sequence('books', 'id'), (SELECT max(id) FROM books));
SELECT setval(pg_get_serial_sequence('withdraw_requests', 'id'), (SELECT max(id) FROM withdraw_requests));
SELECT setval(pg_get_serial_sequence('auction_sessions', 'id'), (SELECT max(id) FROM auction_sessions));
UPDATE auction_sessions s SET current_lot_id = NULL;
