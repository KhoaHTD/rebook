-- =====================================================================
-- Dữ liệu mẫu cho môi trường dev (chỉ chạy với profile dev).
-- Mật khẩu mọi tài khoản: Rebook@123
-- Số dư ví khớp với sổ cái wallet_transactions.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------
-- Người dùng
-- ---------------------------------------------------------------------
INSERT INTO users (id, email, phone, password_hash, full_name, avatar_url, role, email_verified, phone_verified, created_at) VALUES
    (1, 'admin@rebook.vn',   '0900000001', crypt('Rebook@123', gen_salt('bf', 10)), 'Quản trị ReBook',  NULL, 'ADMIN', TRUE, TRUE, now() - interval '60 days'),
    (2, 'staff@rebook.vn',   '0900000002', crypt('Rebook@123', gen_salt('bf', 10)), 'Nguyễn Văn Kho',   NULL, 'STAFF', TRUE, TRUE, now() - interval '60 days'),
    (3, 'seller1@rebook.vn', '0911111111', crypt('Rebook@123', gen_salt('bf', 10)), 'Trần Minh Thư',    'https://i.pravatar.cc/200?u=seller1', 'USER', TRUE, TRUE, now() - interval '45 days'),
    (4, 'seller2@rebook.vn', '0922222222', crypt('Rebook@123', gen_salt('bf', 10)), 'Lê Hoàng Nam',     'https://i.pravatar.cc/200?u=seller2', 'USER', TRUE, TRUE, now() - interval '40 days'),
    (5, 'buyer1@rebook.vn',  '0933333333', crypt('Rebook@123', gen_salt('bf', 10)), 'Phạm Thu Hà',      'https://i.pravatar.cc/200?u=buyer1',  'USER', TRUE, TRUE, now() - interval '30 days'),
    (6, 'buyer2@rebook.vn',  '0944444444', crypt('Rebook@123', gen_salt('bf', 10)), 'Võ Đức Anh',       'https://i.pravatar.cc/200?u=buyer2',  'USER', TRUE, TRUE, now() - interval '25 days'),
    (7, 'buyer3@rebook.vn',  '0955555555', crypt('Rebook@123', gen_salt('bf', 10)), 'Đặng Ngọc Lan',    'https://i.pravatar.cc/200?u=buyer3',  'USER', TRUE, TRUE, now() - interval '20 days');

INSERT INTO shops (id, user_id, name, description, pickup_address, pickup_province, bank_name, bank_account_number,
                   bank_account_holder, rating_avg, rating_count, trusted) VALUES
    (1, 3, 'Nhà Sách Cũ Sài Gòn', 'Sách văn học, kỹ năng và sách IT cũ, giao nhanh nội thành.',
        '12 Nguyễn Thị Minh Khai, P. Đa Kao, Quận 1', 'TP. Hồ Chí Minh', 'Vietcombank', '0071000123456', 'TRAN MINH THU', 5.00, 1, TRUE),
    (2, 4, 'Tiệm Sách Hà Nội Xưa', 'Sách cũ phố Đinh Lễ, chuyên văn học Việt Nam và khoa học xã hội.',
        '8 Đinh Lễ, P. Tràng Tiền, Hoàn Kiếm', 'Hà Nội', 'Techcombank', '19033445566', 'LE HOANG NAM', 0, 0, FALSE);

INSERT INTO addresses (id, user_id, receiver_name, phone, province, district, ward, detail, is_default) VALUES
    (1, 3, 'Trần Minh Thư', '0911111111', 'TP. Hồ Chí Minh', 'Quận 1', 'Phường Đa Kao', '12 Nguyễn Thị Minh Khai', TRUE),
    (2, 4, 'Lê Hoàng Nam',  '0922222222', 'Hà Nội', 'Hoàn Kiếm', 'Phường Tràng Tiền', '8 Đinh Lễ', TRUE),
    (3, 5, 'Phạm Thu Hà',   '0933333333', 'TP. Hồ Chí Minh', 'Quận 3', 'Phường Võ Thị Sáu', '45 Trần Quốc Thảo', TRUE),
    (4, 5, 'Phạm Thu Hà (công ty)', '0933333333', 'TP. Hồ Chí Minh', 'Quận 7', 'Phường Tân Phong', 'Tòa nhà ABC, 102 Nguyễn Lương Bằng', FALSE),
    (5, 6, 'Võ Đức Anh',    '0944444444', 'TP. Hồ Chí Minh', 'TP. Thủ Đức', 'Phường Linh Trung', 'KTX Khu A, ĐHQG', TRUE),
    (6, 7, 'Đặng Ngọc Lan', '0955555555', 'Đà Nẵng', 'Hải Châu', 'Phường Thạch Thang', '30 Lê Lợi', TRUE);

-- ---------------------------------------------------------------------
-- Danh mục
-- ---------------------------------------------------------------------
INSERT INTO categories (id, name, slug, parent_id, sort_order) VALUES
    (1,  'Văn học',                 'van-hoc',              NULL, 1),
    (2,  'Tiểu thuyết Việt Nam',    'tieu-thuyet-viet-nam', 1,    1),
    (3,  'Văn học nước ngoài',      'van-hoc-nuoc-ngoai',   1,    2),
    (4,  'Giáo trình',              'giao-trinh',           NULL, 2),
    (5,  'Công nghệ thông tin',     'cong-nghe-thong-tin',  4,    1),
    (6,  'Kinh tế',                 'kinh-te',              4,    2),
    (7,  'Kỹ năng sống',            'ky-nang-song',         NULL, 3),
    (8,  'Lịch sử – Khoa học xã hội', 'lich-su-khxh',       NULL, 4),
    (9,  'Thiếu nhi',               'thieu-nhi',            NULL, 5),
    (10, 'Sách hiếm – Sách cổ',     'sach-hiem-sach-co',    NULL, 6);

-- ---------------------------------------------------------------------
-- Sách bán giá cố định (book 1–9) và sách ký gửi đấu giá (book 10–16)
-- ---------------------------------------------------------------------
INSERT INTO books (id, owner_id, title, author, publisher, publish_year, isbn, language, pages, category_id,
                   condition_grade, description, weight_gram) VALUES
    (1, 3, 'Dế Mèn Phiêu Lưu Ký', 'Tô Hoài', 'NXB Kim Đồng', 2015, '9786042011237', 'Tiếng Việt', 144, 9, 'GOOD',
        'Bìa hơi ố, ruột sạch, đủ trang.', 250),
    (2, 3, 'Số Đỏ', 'Vũ Trọng Phụng', 'NXB Văn Học', 2016, '9786046976327', 'Tiếng Việt', 260, 2, 'VERY_GOOD',
        'Đọc một lần, không ghi chú.', 300),
    (3, 3, 'Nhà Giả Kim', 'Paulo Coelho', 'NXB Hội Nhà Văn', 2020, '9786049994953', 'Tiếng Việt', 228, 3, 'LIKE_NEW',
        'Như mới, còn bookmark tặng kèm.', 250),
    (4, 3, 'Đắc Nhân Tâm', 'Dale Carnegie', 'NXB Tổng hợp TP.HCM', 2019, '9786045893281', 'Tiếng Việt', 320, 7, 'GOOD',
        'Có gạch chân bút chì vài trang chương 2.', 350),
    (5, 4, 'Giáo trình Cấu trúc dữ liệu và giải thuật', 'Đỗ Xuân Lôi', 'NXB ĐHQG Hà Nội', 2010, NULL, 'Tiếng Việt', 404, 5, 'ACCEPTABLE',
        'Sách giáo trình đã dùng, nhiều ghi chú, gáy hơi lỏng nhưng đủ trang.', 500),
    (6, 3, 'Clean Code', 'Robert C. Martin', 'Prentice Hall', 2008, '9780132350884', 'English', 464, 5, 'VERY_GOOD',
        'Bản gốc tiếng Anh, bìa mềm, ít dấu hiệu sử dụng.', 700),
    (7, 4, 'Tắt Đèn', 'Ngô Tất Tố', 'NXB Văn Học', 2018, '9786049691234', 'Tiếng Việt', 180, 2, 'NEW',
        'Sách mới, còn màng co.', 200),
    (8, 4, 'Sapiens: Lược Sử Loài Người', 'Yuval Noah Harari', 'NXB Tri Thức', 2018, '9786047745557', 'Tiếng Việt', 556, 8, 'LIKE_NEW',
        'Đọc một lần, giữ gìn cẩn thận.', 600),
    (9, 4, 'Rừng Na Uy', 'Haruki Murakami', 'NXB Hội Nhà Văn', 2017, '9786045358414', 'Tiếng Việt', 556, 3, 'VERY_GOOD',
        'Bản dịch Trịnh Lữ, bìa còn đẹp.', 450),
    (10, 3, 'Truyện Kiều (Kim Vân Kiều) – bản in 1925', 'Nguyễn Du', NULL, 1925, NULL, 'Tiếng Việt', 180, 10, 'GOOD',
        'Bản in cũ chữ quốc ngữ, giấy ngả vàng, đóng gáy lại.', 400),
    (11, 4, 'Lều Chõng – bản in lần đầu', 'Ngô Tất Tố', 'NXB Mai Lĩnh', 1952, NULL, 'Tiếng Việt', 320, 10, 'GOOD',
        'Bản in lần đầu thành sách, có dấu thư viện cá nhân.', 450),
    (12, 3, 'Vang Bóng Một Thời – có chữ ký', 'Nguyễn Tuân', NULL, 1962, NULL, 'Tiếng Việt', 210, 10, 'VERY_GOOD',
        'Trang lót có chữ ký được cho là của tác giả.', 350),
    (13, 4, 'Bỉ Vỏ', 'Nguyên Hồng', NULL, 1938, NULL, 'Tiếng Việt', 240, 10, 'ACCEPTABLE',
        'Sách rất cũ, bìa sờn, ruột đọc tốt.', 380),
    (14, 3, 'Từ điển Annam – Lusitan – Latinh (tái bản)', 'Alexandre de Rhodes', 'NXB Khoa học Xã hội', 1991, NULL, 'Đa ngôn ngữ', 600, 10, 'VERY_GOOD',
        'Bản tái bản có chú giải, bìa cứng.', 1200),
    (15, 4, 'Nam Phong Tạp Chí – số 1', 'Phạm Quỳnh (chủ bút)', NULL, 1917, NULL, 'Tiếng Việt', 80, 10, 'GOOD',
        'Số đầu tiên, còn nguyên bìa.', 200),
    (16, 3, 'Thơ Thơ', 'Xuân Diệu', NULL, 1938, NULL, 'Tiếng Việt', 96, 10, 'GOOD',
        'Tập thơ đầu tay, bản in cũ.', 180);

-- 3 ảnh người bán cho mỗi cuốn; sách đấu giá có thêm ảnh staff chụp khi kiểm định
INSERT INTO book_images (book_id, url, sort_order, source)
SELECT b.id, 'https://picsum.photos/seed/rebook-' || b.id || '-' || n || '/600/800', n - 1, 'SELLER'
FROM books b CROSS JOIN generate_series(1, 3) AS n;

INSERT INTO book_images (book_id, url, sort_order, source)
SELECT b.id, 'https://picsum.photos/seed/rebook-staff-' || b.id || '-' || n || '/600/800', n - 1, 'STAFF'
FROM books b CROSS JOIN generate_series(1, 2) AS n
WHERE b.id BETWEEN 10 AND 14;

INSERT INTO listings (id, book_id, shop_id, price, stock, sold_count, status, created_at) VALUES
    (1, 1, 1,  45000, 1, 0, 'ACTIVE',         now() - interval '20 days'),
    (2, 2, 1,  55000, 1, 1, 'ACTIVE',         now() - interval '19 days'),
    (3, 3, 1,  60000, 1, 0, 'ACTIVE',         now() - interval '15 days'),
    (4, 4, 1,  50000, 2, 0, 'ACTIVE',         now() - interval '12 days'),
    (5, 5, 2,  35000, 1, 0, 'ACTIVE',         now() - interval '10 days'),
    (6, 6, 1, 250000, 1, 0, 'ACTIVE',         now() - interval '8 days'),
    (7, 7, 2,  40000, 1, 1, 'ACTIVE',         now() - interval '7 days'),
    (8, 8, 2, 120000, 1, 1, 'ACTIVE',         now() - interval '5 days'),
    (9, 9, 2,  70000, 1, 0, 'PENDING_REVIEW', now() - interval '1 day');

INSERT INTO cart_items (user_id, listing_id, quantity) VALUES
    (6, 3, 1),
    (6, 6, 1),
    (7, 1, 1);

-- ---------------------------------------------------------------------
-- Ví + thanh toán + sổ cái
-- ---------------------------------------------------------------------
INSERT INTO wallets (id, user_id, available_balance, held_balance) VALUES
    (1, NULL,       2750,      0),  -- ví sàn
    (2, 1,             0,      0),
    (3, 2,             0,      0),
    (4, 3,         72250,      0),
    (5, 4,             0, 150000),
    (6, 5,       4275000, 500000),
    (7, 6,       4500000, 500000),
    (8, 7,       2500000, 500000);

INSERT INTO payments (id, code, user_id, purpose, method, amount, status, gateway_txn_id, paid_at, created_at) VALUES
    (1, 'PMDEMO000001', 5, 'TOP_UP', 'VNPAY', 5000000, 'SUCCESS', 'SEED-14000001', now() - interval '15 days', now() - interval '15 days'),
    (2, 'PMDEMO000002', 6, 'TOP_UP', 'VNPAY', 5000000, 'SUCCESS', 'SEED-14000002', now() - interval '14 days', now() - interval '14 days'),
    (3, 'PMDEMO000003', 7, 'TOP_UP', 'VNPAY', 3000000, 'SUCCESS', 'SEED-14000003', now() - interval '13 days', now() - interval '13 days'),
    (4, 'PMDEMO000004', 5, 'ORDER',  'WALLET',  75000, 'SUCCESS', NULL,            now() - interval '10 days', now() - interval '10 days'),
    (5, 'PMDEMO000005', 5, 'ORDER',  'WALLET', 150000, 'SUCCESS', NULL,            now() - interval '2 hours', now() - interval '2 hours');

-- ---------------------------------------------------------------------
-- Đơn hàng giá cố định
--  1: buyer1 mua "Số Đỏ" của shop 1 — đã hoàn tất, đã đánh giá
--  2: buyer2 mua "Tắt Đèn" của shop 2 — COD, đang giao
--  3: buyer1 mua "Sapiens" của shop 2 — đã trả bằng ví, chờ shop xác nhận
-- ---------------------------------------------------------------------
INSERT INTO orders (id, code, buyer_id, shop_id, order_type, status, payment_method, payment_id, paid_at, subtotal,
                    shipping_fee, total, address_snapshot, tracking_code, confirm_due_at, delivered_at, completed_at, created_at) VALUES
    (1, 'ODDEMO000001', 5, 1, 'NORMAL', 'COMPLETED', 'WALLET', 4, now() - interval '10 days', 55000, 20000, 75000,
        '{"receiverName":"Phạm Thu Hà","phone":"0933333333","province":"TP. Hồ Chí Minh","district":"Quận 3","ward":"Phường Võ Thị Sáu","detail":"45 Trần Quốc Thảo"}',
        'RB0000000001', now() - interval '9 days', now() - interval '7 days', now() - interval '6 days', now() - interval '10 days'),
    (2, 'ODDEMO000002', 6, 2, 'NORMAL', 'SHIPPING', 'COD', NULL, NULL, 40000, 30000, 70000,
        '{"receiverName":"Võ Đức Anh","phone":"0944444444","province":"TP. Hồ Chí Minh","district":"TP. Thủ Đức","ward":"Phường Linh Trung","detail":"KTX Khu A, ĐHQG"}',
        'RB0000000002', now() - interval '2 days', NULL, NULL, now() - interval '3 days'),
    (3, 'ODDEMO000003', 5, 2, 'NORMAL', 'PENDING_CONFIRM', 'WALLET', 5, now() - interval '2 hours', 120000, 30000, 150000,
        '{"receiverName":"Phạm Thu Hà","phone":"0933333333","province":"TP. Hồ Chí Minh","district":"Quận 3","ward":"Phường Võ Thị Sáu","detail":"45 Trần Quốc Thảo"}',
        NULL, now() + interval '22 hours', NULL, NULL, now() - interval '2 hours');

INSERT INTO order_items (order_id, listing_id, title_snapshot, image_snapshot, unit_price, quantity) VALUES
    (1, 2, 'Số Đỏ',                       'https://picsum.photos/seed/rebook-2-1/600/800',  55000, 1),
    (2, 7, 'Tắt Đèn',                     'https://picsum.photos/seed/rebook-7-1/600/800',  40000, 1),
    (3, 8, 'Sapiens: Lược Sử Loài Người', 'https://picsum.photos/seed/rebook-8-1/600/800', 120000, 1);

INSERT INTO order_status_history (order_id, from_status, to_status, actor_id, note, created_at) VALUES
    (1, NULL,              'PENDING_PAYMENT', 5,    'Đặt hàng',                                  now() - interval '10 days'),
    (1, 'PENDING_PAYMENT', 'PENDING_CONFIRM', 5,    'Đã thanh toán (WALLET)',                    now() - interval '10 days'),
    (1, 'PENDING_CONFIRM', 'PREPARING',       3,    'Đã xác nhận, đang chuẩn bị hàng',           now() - interval '9 days'),
    (1, 'PREPARING',       'SHIPPING',        3,    'Đã giao cho đơn vị vận chuyển, mã vận đơn RB0000000001', now() - interval '8 days'),
    (1, 'SHIPPING',        'DELIVERED',       3,    'Giao hàng thành công',                      now() - interval '7 days'),
    (1, 'DELIVERED',       'COMPLETED',       5,    'Người mua xác nhận đã nhận hàng',           now() - interval '6 days'),
    (2, NULL,              'PENDING_CONFIRM', 6,    'Đặt hàng',                                  now() - interval '3 days'),
    (2, 'PENDING_CONFIRM', 'PREPARING',       4,    'Đã xác nhận, đang chuẩn bị hàng',           now() - interval '2 days'),
    (2, 'PREPARING',       'SHIPPING',        4,    'Đã giao cho đơn vị vận chuyển, mã vận đơn RB0000000002', now() - interval '1 day'),
    (3, NULL,              'PENDING_PAYMENT', 5,    'Đặt hàng',                                  now() - interval '2 hours'),
    (3, 'PENDING_PAYMENT', 'PENDING_CONFIRM', 5,    'Đã thanh toán (WALLET)',                    now() - interval '2 hours');

INSERT INTO reviews (order_id, reviewer_id, shop_id, rating, comment, created_at) VALUES
    (1, 5, 1, 5, 'Sách đúng mô tả, đóng gói rất cẩn thận. Sẽ ủng hộ shop tiếp!', now() - interval '6 days');

-- ---------------------------------------------------------------------
-- Ký gửi đấu giá
--  1–4: đã kiểm định + người bán đồng ý → thành lô (1–3 đã xếp vào phiên 1, lô 4 chờ xếp phiên)
--  5: đạt kiểm định, chờ người bán chấp nhận giá
--  6: mới gửi, chờ Staff sơ duyệt
--  7: đã đặt lịch mang sách tới kho ngày mai 10:00
-- ---------------------------------------------------------------------
INSERT INTO consignments (id, code, seller_id, book_id, expected_price, provenance, status, review_note, appointment_at,
                          appointment_code, approved_at, received_at, received_by, created_at) VALUES
    (1, 'KGDEMO000001', 3, 10, 4000000, 'Sách gia đình lưu giữ từ thời ông nội, bản in năm 1925.', 'ACCEPTED', 'Sách hiếm, nhận ký gửi',
        now() - interval '19 days', 'APDEMO0001', now() - interval '20 days', now() - interval '19 days', 2, now() - interval '21 days'),
    (2, 'KGDEMO000002', 4, 11, 1000000, 'Mua lại từ một nhà sưu tầm ở phố Hàng Bài.', 'ACCEPTED', NULL,
        now() - interval '17 days', 'APDEMO0002', now() - interval '18 days', now() - interval '17 days', 2, now() - interval '19 days'),
    (3, 'KGDEMO000003', 3, 12, 2000000, 'Có chữ ký ở trang lót, được tặng năm 1963.', 'ACCEPTED', NULL,
        now() - interval '15 days', 'APDEMO0003', now() - interval '16 days', now() - interval '15 days', 2, now() - interval '17 days'),
    (4, 'KGDEMO000004', 4, 13, 2500000, 'Bản in năm 1938.', 'ACCEPTED', NULL,
        now() - interval '9 days', 'APDEMO0004', now() - interval '10 days', now() - interval '9 days', 2, now() - interval '11 days'),
    (5, 'KGDEMO000005', 3, 14, 800000, 'Mua tại hội sách cũ năm 2005.', 'AWAITING_SELLER', NULL,
        now() - interval '3 days', 'APDEMO0005', now() - interval '4 days', now() - interval '3 days', 2, now() - interval '5 days'),
    (6, 'KGDEMO000006', 4, 15, 1500000, 'Số tạp chí đầu tiên, giữ trong hộp kín.', 'SUBMITTED', NULL,
        NULL, NULL, NULL, NULL, NULL, now() - interval '6 hours'),
    (7, 'KGDEMO000007', 3, 16, 1200000, 'Tập thơ đầu tay của Xuân Diệu.', 'APPOINTMENT_BOOKED', NULL,
        ((date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh') + interval '1 day 10 hours') AT TIME ZONE 'Asia/Ho_Chi_Minh'),
        'APDEMO0007', now() - interval '1 day', NULL, NULL, now() - interval '2 days');

INSERT INTO inspections (consignment_id, inspector_id, result, checklist, condition_grade, condition_report, estimate_low,
                         estimate_high, proposed_start, proposed_reserve, seller_decision, decided_at, created_at) VALUES
    (1, 2, 'PASS', '{"fullPages": true, "editionVerified": true, "mold": false, "notes": false, "signature": null}', 'GOOD',
        'Đủ 180 trang. Bìa trước có vết rách nhỏ đã được dán lại, gáy đóng lại. Giấy ngả vàng đều, không ẩm mốc.',
        3000000, 5000000, 1500000, 2500000, 'ACCEPTED', now() - interval '17 days', now() - interval '18 days'),
    (2, 2, 'PASS', '{"fullPages": true, "editionVerified": true, "mold": false, "notes": true, "signature": null}', 'GOOD',
        'Đủ trang, có dấu mộc thư viện cá nhân ở trang 1. Bìa còn tốt, ruột ố nhẹ.',
        800000, 1200000, 500000, 700000, 'ACCEPTED', now() - interval '15 days', now() - interval '16 days'),
    (3, 2, 'PASS', '{"fullPages": true, "editionVerified": true, "mold": false, "notes": false, "signature": "chưa xác thực"}', 'VERY_GOOD',
        'Tình trạng tốt. Chữ ký ở trang lót CHƯA XÁC THỰC được là của tác giả.',
        1500000, 2500000, 900000, 1200000, 'ACCEPTED', now() - interval '13 days', now() - interval '14 days'),
    (4, 2, 'PASS', '{"fullPages": true, "editionVerified": true, "mold": true, "notes": false, "signature": null}', 'ACCEPTABLE',
        'Bìa sờn, góc gáy rách. Có vết ẩm mốc nhẹ ở 5 trang cuối, không ảnh hưởng chữ.',
        2000000, 3000000, 1000000, 1800000, 'ACCEPTED', now() - interval '7 days', now() - interval '8 days'),
    (5, 2, 'PASS', '{"fullPages": true, "editionVerified": true, "mold": false, "notes": false, "signature": null}', 'VERY_GOOD',
        'Bìa cứng còn chắc, ruột sạch, bản tái bản năm 1991.',
        600000, 900000, 350000, 500000, 'PENDING', NULL, now() - interval '1 day');

INSERT INTO warehouse_items (consignment_id, code, shelf_code, status, checked_in_at) VALUES
    (1, 'WHDEMO0001', 'A-01-01', 'IN_STOCK', now() - interval '19 days'),
    (2, 'WHDEMO0002', 'A-01-02', 'IN_STOCK', now() - interval '17 days'),
    (3, 'WHDEMO0003', 'A-01-03', 'IN_STOCK', now() - interval '15 days'),
    (4, 'WHDEMO0004', 'A-02-01', 'IN_STOCK', now() - interval '9 days'),
    (5, 'WHDEMO0005', 'B-01-01', 'IN_STOCK', now() - interval '3 days');

-- ---------------------------------------------------------------------
-- Phiên đấu giá: đã công bố, đã có 3/3 người đăng ký + cọc.
-- Admin gọi POST /admin/sessions/1/start để chạy demo ngay.
-- ---------------------------------------------------------------------
INSERT INTO auction_sessions (id, title, description, cover_url, start_at, registration_deadline, min_participants,
                              deposit_amount, lot_duration_sec, soft_close_sec, lot_gap_sec, status, published_at, created_by) VALUES
    (1, 'Sách cổ Việt Nam trước 1975',
        'Ba ấn phẩm văn học Việt Nam xuất bản trước 1975, đã được kho ReBook kiểm định.',
        'https://picsum.photos/seed/rebook-session-1/1200/600',
        now() + interval '2 days', now() + interval '1 day', 3, 500000, 60, 15, 7, 'PUBLISHED', now() - interval '1 day', 1);

-- Lô hấp dẫn nhất (Truyện Kiều) đặt ở giữa để giữ người xem
INSERT INTO lots (id, session_id, consignment_id, book_id, lot_number, start_price, reserve_price, estimate_low,
                  estimate_high, status, rounds) VALUES
    (1, 1,    1, 10, 2,    1500000, 2500000, 3000000, 5000000, 'SCHEDULED', 1),
    (2, 1,    2, 11, 1,     500000,  700000,  800000, 1200000, 'SCHEDULED', 1),
    (3, 1,    3, 12, 3,     900000, 1200000, 1500000, 2500000, 'SCHEDULED', 1),
    (4, NULL, 4, 13, NULL, 1000000, 1800000, 2000000, 3000000, 'READY',     0);

INSERT INTO auction_registrations (id, session_id, user_id, paddle_number, deposit_amount, bid_limit, status, created_at) VALUES
    (1, 1, 5, 1, 500000, 5000000, 'APPROVED', now() - interval '20 hours'),
    (2, 1, 6, 2, 500000, 5000000, 'APPROVED', now() - interval '18 hours'),
    (3, 1, 7, 3, 500000, 5000000, 'APPROVED', now() - interval '12 hours');

INSERT INTO lot_watchers (user_id, lot_id) VALUES
    (5, 1),
    (6, 1),
    (6, 3);

-- Sổ cái (khớp với số dư ví ở trên)
INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after, ref_type, ref_id, note, created_at) VALUES
    -- buyer1
    (6, 'TOP_UP',        5000000,       0, 5000000,      0, 'PAYMENT',      1, 'Nạp tiền qua VNPay',        now() - interval '15 days'),
    (6, 'PAYMENT',        -75000,       0, 4925000,      0, 'ORDER',        1, 'Thanh toán đơn ODDEMO000001', now() - interval '10 days'),
    (6, 'PAYMENT',       -150000,       0, 4775000,      0, 'ORDER',        3, 'Thanh toán đơn ODDEMO000003', now() - interval '2 hours'),
    (6, 'DEPOSIT_HOLD',  -500000,  500000, 4275000, 500000, 'REGISTRATION', 1, 'Đặt cọc phiên Sách cổ Việt Nam trước 1975', now() - interval '20 hours'),
    -- buyer2
    (7, 'TOP_UP',        5000000,       0, 5000000,      0, 'PAYMENT',      2, 'Nạp tiền qua VNPay',        now() - interval '14 days'),
    (7, 'DEPOSIT_HOLD',  -500000,  500000, 4500000, 500000, 'REGISTRATION', 2, 'Đặt cọc phiên Sách cổ Việt Nam trước 1975', now() - interval '18 hours'),
    -- buyer3
    (8, 'TOP_UP',        3000000,       0, 3000000,      0, 'PAYMENT',      3, 'Nạp tiền qua VNPay',        now() - interval '13 days'),
    (8, 'DEPOSIT_HOLD',  -500000,  500000, 2500000, 500000, 'REGISTRATION', 3, 'Đặt cọc phiên Sách cổ Việt Nam trước 1975', now() - interval '12 hours'),
    -- seller1: tiền bán đơn 1
    (4, 'SALE_PENDING',        0,   75000,       0,  75000, 'ORDER',        1, 'Tiền bán đơn ODDEMO000001 chờ hoàn tất', now() - interval '10 days'),
    (4, 'SALE_RELEASE',    75000,  -75000,   75000,      0, 'ORDER',        1, 'Giải ngân đơn ODDEMO000001',  now() - interval '6 days'),
    (4, 'FEE',             -2750,       0,   72250,      0, 'ORDER',        1, 'Phí sàn đơn ODDEMO000001',    now() - interval '6 days'),
    -- seller2: tiền bán đơn 3 đang chờ
    (5, 'SALE_PENDING',        0,  150000,       0, 150000, 'ORDER',        3, 'Tiền bán đơn ODDEMO000003 chờ hoàn tất', now() - interval '2 hours'),
    -- ví sàn
    (1, 'FEE',              2750,       0,    2750,      0, 'ORDER',        1, 'Phí sàn đơn ODDEMO000001',    now() - interval '6 days');

-- ---------------------------------------------------------------------
-- Thông báo mẫu
-- ---------------------------------------------------------------------
INSERT INTO notifications (user_id, type, title, body, data, is_read, created_at) VALUES
    (5, 'ORDER',   'Cập nhật đơn hàng', 'Đơn ODDEMO000001 đã hoàn tất. Hãy đánh giá shop nhé!', '{"orderId": 1}', TRUE,  now() - interval '6 days'),
    (5, 'AUCTION_REMINDER', 'Đăng ký thành công', 'Bạn đã đăng ký phiên "Sách cổ Việt Nam trước 1975" với số bài #001', '{"sessionId": 1}', FALSE, now() - interval '20 hours'),
    (6, 'ORDER',   'Cập nhật đơn hàng', 'Đơn ODDEMO000002 đang được giao', '{"orderId": 2}', FALSE, now() - interval '1 day'),
    (4, 'ORDER',   'Đơn hàng mới',      'Đơn ODDEMO000003 đã thanh toán, vui lòng xác nhận trong 24h', '{"orderId": 3}', FALSE, now() - interval '2 hours'),
    (3, 'CONSIGNMENT', 'Ký gửi đấu giá', 'Sách của yêu cầu KGDEMO000005 đạt kiểm định. Hãy xem và chấp nhận đề xuất', '{"consignmentId": 5}', FALSE, now() - interval '1 day');

-- ---------------------------------------------------------------------
-- Đồng bộ sequence sau khi chèn id cố định
-- ---------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('users', 'id'),                 (SELECT max(id) FROM users));
SELECT setval(pg_get_serial_sequence('shops', 'id'),                 (SELECT max(id) FROM shops));
SELECT setval(pg_get_serial_sequence('addresses', 'id'),             (SELECT max(id) FROM addresses));
SELECT setval(pg_get_serial_sequence('categories', 'id'),            (SELECT max(id) FROM categories));
SELECT setval(pg_get_serial_sequence('books', 'id'),                 (SELECT max(id) FROM books));
SELECT setval(pg_get_serial_sequence('listings', 'id'),              (SELECT max(id) FROM listings));
SELECT setval(pg_get_serial_sequence('wallets', 'id'),               (SELECT max(id) FROM wallets));
SELECT setval(pg_get_serial_sequence('payments', 'id'),              (SELECT max(id) FROM payments));
SELECT setval(pg_get_serial_sequence('orders', 'id'),                (SELECT max(id) FROM orders));
SELECT setval(pg_get_serial_sequence('consignments', 'id'),          (SELECT max(id) FROM consignments));
SELECT setval(pg_get_serial_sequence('auction_sessions', 'id'),      (SELECT max(id) FROM auction_sessions));
SELECT setval(pg_get_serial_sequence('lots', 'id'),                  (SELECT max(id) FROM lots));
SELECT setval(pg_get_serial_sequence('auction_registrations', 'id'), (SELECT max(id) FROM auction_registrations));
