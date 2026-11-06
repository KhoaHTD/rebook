-- Dữ liệu mẫu sách (sinh từ tools/books/gen.mjs, books.xlsx và covers.json, đừng sửa tay). Chỉ chạy với profile dev.
-- Xoá mọi dữ liệu nghiệp vụ cũ (sách, tin đăng, ký gửi, lô, phiên đấu giá, đơn, thanh toán, sổ cái ví, thông báo...),
-- giữ tài khoản, shop, địa chỉ, cấu hình; nạp 70 sách thành tin đăng bán giá cố định, mỗi sách một ảnh bìa trên Cloudinary.

TRUNCATE TABLE
    books, book_images, listings, consignments, inspections, warehouse_items, warehouse_incidents,
    auction_sessions, lots, auction_registrations, bids, proxy_bids, lot_watchers, session_watchers,
    orders, order_items, order_status_history, return_requests, reviews,
    payments, wallet_transactions, withdraw_requests, withdraw_transfers, account_debts,
    cart_items, listing_favorites, notifications, audit_events, admin_activity_logs, otp_codes, refresh_tokens
    RESTART IDENTITY CASCADE;

-- Thể loại cũ chỉ còn vì có sách dùng (V20 không xoá được): giờ xoá nốt.
DELETE FROM categories c
 WHERE c.slug NOT IN ('van-hoc', 'tieu-thuyet-viet-nam', 'tieu-thuyet-nuoc-ngoai', 'van-hoc-kinh-dien', 'van-hoc-duong-dai', 'trinh-tham-kinh-di', 'ky-ao-gia-tuong', 'ngon-tinh-lang-man', 'tieu-thuyet-lich-su', 'truyen-ngan', 'tho', 'lich-su-chinh-tri', 'lich-su-viet-nam', 'lich-su-the-gioi', 'chinh-tri', 'tieu-su-hoi-ky', 'hoi-ky-tu-truyen', 'chan-dung-nhan-vat', 'ky-nang-song', 'phat-trien-ban-than', 'tam-ly-hoc', 'gia-dinh-nuoi-day-con', 'am-thuc-nau-an', 'nau-an-gia-dinh', 'am-thuc-quoc-te', 'an-chay-dinh-duong', 'hai-huoc-tieu-luan', 'hai-huoc', 'tieu-luan-tuyen-tap', 'kinh-te-kinh-doanh', 'kinh-te-hoc', 'quan-tri-khoi-nghiep', 'marketing-ban-hang', 'khoa-hoc-cong-nghe', 'khoa-hoc-tu-nhien', 'khoa-hoc-thong-tin', 'truyen-thong-xa-hoi-hoc', 'triet-hoc-ton-giao', 'triet-hoc-phuong-tay', 'van-hoa-hoc', 'ton-giao-tam-linh', 'giao-trinh', 'cong-nghe-thong-tin', 'kinh-te-quan-tri', 'khoa-hoc-ky-thuat', 'y-duoc', 'luat-hanh-chinh', 'ngoai-ngu', 'so-thich-giai-tri', 'tro-choi-giai-do', 'thu-cung-thien-nhien', 'nghe-thuat', 'nhiep-anh', 'am-nhac', 'hoi-hoa-thiet-ke', 'thieu-nhi', 'truyen-thieu-nhi', 'sach-to-mau-ky-nang-cho-be', 'tham-khao', 'tu-dien-bach-khoa', 'sach-tra-cuu', 'truyen-tranh-manga', 'suc-khoe-doi-song', 'sach-hiem-sach-co')
   AND NOT EXISTS (SELECT 1 FROM books b WHERE b.category_id = c.id)
   AND NOT EXISTS (SELECT 1 FROM categories ch WHERE ch.parent_id = c.id);
DELETE FROM categories c
 WHERE c.slug NOT IN ('van-hoc', 'tieu-thuyet-viet-nam', 'tieu-thuyet-nuoc-ngoai', 'van-hoc-kinh-dien', 'van-hoc-duong-dai', 'trinh-tham-kinh-di', 'ky-ao-gia-tuong', 'ngon-tinh-lang-man', 'tieu-thuyet-lich-su', 'truyen-ngan', 'tho', 'lich-su-chinh-tri', 'lich-su-viet-nam', 'lich-su-the-gioi', 'chinh-tri', 'tieu-su-hoi-ky', 'hoi-ky-tu-truyen', 'chan-dung-nhan-vat', 'ky-nang-song', 'phat-trien-ban-than', 'tam-ly-hoc', 'gia-dinh-nuoi-day-con', 'am-thuc-nau-an', 'nau-an-gia-dinh', 'am-thuc-quoc-te', 'an-chay-dinh-duong', 'hai-huoc-tieu-luan', 'hai-huoc', 'tieu-luan-tuyen-tap', 'kinh-te-kinh-doanh', 'kinh-te-hoc', 'quan-tri-khoi-nghiep', 'marketing-ban-hang', 'khoa-hoc-cong-nghe', 'khoa-hoc-tu-nhien', 'khoa-hoc-thong-tin', 'truyen-thong-xa-hoi-hoc', 'triet-hoc-ton-giao', 'triet-hoc-phuong-tay', 'van-hoa-hoc', 'ton-giao-tam-linh', 'giao-trinh', 'cong-nghe-thong-tin', 'kinh-te-quan-tri', 'khoa-hoc-ky-thuat', 'y-duoc', 'luat-hanh-chinh', 'ngoai-ngu', 'so-thich-giai-tri', 'tro-choi-giai-do', 'thu-cung-thien-nhien', 'nghe-thuat', 'nhiep-anh', 'am-nhac', 'hoi-hoa-thiet-ke', 'thieu-nhi', 'truyen-thieu-nhi', 'sach-to-mau-ky-nang-cho-be', 'tham-khao', 'tu-dien-bach-khoa', 'sach-tra-cuu', 'truyen-tranh-manga', 'suc-khoe-doi-song', 'sach-hiem-sach-co')
   AND NOT EXISTS (SELECT 1 FROM books b WHERE b.category_id = c.id)
   AND NOT EXISTS (SELECT 1 FROM categories ch WHERE ch.parent_id = c.id);

-- Ví: về 0 rồi nạp lại cho ba người mua, sổ cái khớp số dư.
UPDATE wallets SET available_balance = 0, held_balance = 0;

INSERT INTO payments (code, user_id, purpose, method, amount, status, gateway_txn_id, paid_at, created_at) VALUES
    ('PMDEMO000001', 5, 'TOP_UP', 'ZALOPAY', 5000000, 'SUCCESS', 'SEED-14000001', now() - interval '15 days', now() - interval '15 days'),
    ('PMDEMO000002', 6, 'TOP_UP', 'ZALOPAY', 5000000, 'SUCCESS', 'SEED-14000002', now() - interval '14 days', now() - interval '14 days'),
    ('PMDEMO000003', 7, 'TOP_UP', 'ZALOPAY', 3000000, 'SUCCESS', 'SEED-14000003', now() - interval '13 days', now() - interval '13 days');

INSERT INTO wallet_transactions (wallet_id, type, available_change, held_change, available_after, held_after, ref_type, ref_id, note, created_at) VALUES
    ((SELECT id FROM wallets WHERE user_id = 5), 'TOP_UP', 5000000, 0, 5000000, 0, 'PAYMENT', (SELECT id FROM payments WHERE user_id = 5 AND purpose = 'TOP_UP'), 'Nạp tiền vào ví', now() - interval '14 days'),
    ((SELECT id FROM wallets WHERE user_id = 6), 'TOP_UP', 5000000, 0, 5000000, 0, 'PAYMENT', (SELECT id FROM payments WHERE user_id = 6 AND purpose = 'TOP_UP'), 'Nạp tiền vào ví', now() - interval '14 days'),
    ((SELECT id FROM wallets WHERE user_id = 7), 'TOP_UP', 3000000, 0, 3000000, 0, 'PAYMENT', (SELECT id FROM payments WHERE user_id = 7 AND purpose = 'TOP_UP'), 'Nạp tiền vào ví', now() - interval '14 days');

UPDATE wallets w SET available_balance = t.amount
  FROM (VALUES (5, 5000000), (6, 5000000), (7, 3000000)) AS t(user_id, amount)
 WHERE w.user_id = t.user_id;

-- Hai shop mẫu: tiểu thuyết / phi hư cấu.
UPDATE shops SET description = 'Tiểu thuyết tiếng Anh: văn học đương đại và kinh điển, kỳ ảo, trinh thám, lãng mạn. Tuyển chọn kỹ, giao nhanh.' WHERE id = 1;
UPDATE shops SET description = 'Sách tiếng Anh phi hư cấu: hồi ký, lịch sử, ẩm thực, phát triển bản thân, khoa học và hài hước.' WHERE id = 2;
UPDATE shops SET rating_avg = 0, rating_count = 0;

INSERT INTO books (id, owner_id, title, author, publisher, publish_year, isbn, language, pages, category_id,
                   condition_grade, description, weight_gram) VALUES
    (1, 4, 'Atomic Habits', 'James Clear', 'Avery', 2018, '9780735211292', 'Tiếng Anh', 320,
        (SELECT id FROM categories WHERE slug = 'phat-trien-ban-than'), 'NEW', 'Hướng dẫn xây dựng thói quen tốt và giảm thói quen xấu bằng những thay đổi nhỏ hằng ngày. James Clear trình bày cách thiết kế môi trường, duy trì động lực và xây dựng hệ thống giúp việc cải thiện bản thân trở nên bền vững.', 540),
    (2, 3, 'The French Illusion', 'John Grisham', 'Doubleday', 2026, '9780385550543', 'Tiếng Anh', 352,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'NEW', 'Tuần trăng mật tại Paris của Paul và Chelsea Tanner biến thành cơn ác mộng khi họ bị bắt cóc ở vùng nông thôn Pháp. Cuộc điều tra kéo theo nhiều cơ quan tình báo và một luật sư trẻ được tuyển làm mồi nhử trong chiến dịch của CIA.', 520),
    (3, 3, 'Ruthless', 'Danielle Steel', 'Delacorte Press', 2026, '9780593973301', 'Tiếng Anh', 272,
        (SELECT id FROM categories WHERE slug = 'ngon-tinh-lang-man'), 'VERY_GOOD', 'Một nhà báo gặp gỡ các nhân vật giàu có và quyền lực trong chuyến công tác tại Saint Barts. Những cuộc gặp giữa cô, một tỷ phú công nghệ và ông trùm vận tải John Randall Williams dẫn đến cuộc đối đầu về bí mật, quyền lực và sự thật.', 480),
    (4, 3, 'Cursed City', 'Kate Golden', 'Ace', 2026, '9780593953457', 'Tiếng Anh', 528,
        (SELECT id FROM categories WHERE slug = 'ky-ao-gia-tuong'), 'VERY_GOOD', 'Viv Abbot tìm cách cứu Reid Graveheart và buộc phải hợp tác với người anh nguy hiểm của anh. Giữa những bí mật của Harker Academy và thế giới ngầm Astera, cô phải bảo vệ bạn bè khi chính mình trở thành mục tiêu bị săn đuổi.', 590),
    (5, 3, 'Dawn of the Cursed Queen: Deluxe Special Edition', 'Amber V. Nicole', 'Kensington', 2026, '9781496758088', 'Tiếng Anh', 704,
        (SELECT id FROM categories WHERE slug = 'ky-ao-gia-tuong'), 'LIKE_NEW', 'Sau trận chiến khốc liệt, nữ thần chiến tranh Nismera nắm quyền còn Samkiel phải ẩn náu và hồi phục. Dianna tìm mọi cách bảo vệ anh, kể cả đánh đổi mối quan hệ của họ, trong cuộc xung đột giữa thần linh và quái vật.', 850),
    (6, 3, 'Hollywood, Ending', 'John Green', 'Dutton Books', 2026, '9780525426073', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'van-hoc-duong-dai'), 'GOOD', 'Hai diễn viên trẻ Kai Laramie và Juniper Castillo được chọn vào bộ phim về Andy Warhol, mở ra cơ hội nổi tiếng và tình yêu. Câu chuyện khám phá áp lực của sự chú ý công chúng cùng hành trình tìm kiếm lòng tin và bản sắc cá nhân.', 510),
    (7, 3, 'Free Falling', 'Lyla Sage', 'Dial Press Trade Paperback', 2026, '9780593977798', 'Tiếng Anh', 336,
        (SELECT id FROM categories WHERE slug = 'ngon-tinh-lang-man'), 'NEW', 'Chủ tiệm đồ cổ Clarke Cartwright và người thừa kế trang trại Leith Wilkes giả vờ yêu nhau để bảo vệ những gì gia đình để lại. Các bí mật thừa kế, bóng ma quá khứ và cảm xúc thật khiến kế hoạch của họ trở nên phức tạp.', 400),
    (8, 3, 'Exit Party', 'Emily St. John Mandel', 'Knopf', 2026, '9780593321461', 'Tiếng Anh', 320,
        (SELECT id FROM categories WHERE slug = 'van-hoc-duong-dai'), 'NEW', 'Tại Los Angeles năm 2031 sau sự tan rã của nước Mỹ, một người đàn ông biến mất giữa bữa tiệc. Cuộc tìm kiếm của Ari Waker mở ra những bản sao kỳ lạ, thế giới song song và các dòng thời gian đứt gãy.', 530),
    (9, 3, 'Hollow Bones', 'Jodi Picoult', 'Ballantine Books', 2026, '9780593726259', 'Tiếng Anh', 464,
        (SELECT id FROM categories WHERE slug = 'van-hoc-duong-dai'), 'GOOD', 'Mất mẹ trong vụ tấn công ngày 11 tháng 9, Molly Fitzgerald trưởng thành với nỗi lo thường trực về thảm họa và làm việc trong lĩnh vực ứng phó khẩn cấp. Một biến cố trong cuộc hôn nhân khiến cô phải nhìn lại tình yêu, ký ức và nhu cầu kiểm soát bất trắc.', 650),
    (10, 3, 'The Pirate Queen', 'Ariel Lawhon', 'Doubleday', 2026, '9780385550345', 'Tiếng Anh', 528,
        (SELECT id FROM categories WHERE slug = 'tieu-thuyet-lich-su'), 'GOOD', 'Tiểu thuyết lịch sử lấy cảm hứng từ Grace O’Malley, người phụ nữ Ireland khao khát làm thuyền trưởng. Vượt qua cuộc hôn nhân bị sắp đặt và những giới hạn của gia đình, bà trở lại biển để bảo vệ đất đai, hạm đội và cộng đồng của mình.', 750),
    (11, 3, 'The Disappearers', 'Marlon James', 'Riverhead Books', 2026, '9780593717202', 'Tiếng Anh', 640,
        (SELECT id FROM categories WHERE slug = 'van-hoc-duong-dai'), 'LIKE_NEW', 'Tám người đàn ông đồng tính ở Kingston, Jamaica, cùng tập một vở kịch vào năm 1988. Sau một vụ tấn công khiến một người thiệt mạng, những người sống sót phải đối diện với mất mát, định kiến và những lựa chọn khác nhau về cách tiếp tục sống.', 880),
    (12, 3, 'My Dreadful Darling', 'H. D. Carlton', 'ZPN', 2026, '9781638936015', 'Tiếng Anh', 608,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'NEW', 'Reverie Adams cố xây dựng cuộc sống đại học bình thường dù mang di sản đáng sợ của người cha sát nhân. Dreadful Sharpe muốn trả thù gia đình cô, nhưng những bí mật trong quá khứ khiến mối quan hệ giữa họ trở nên nguy hiểm và khó đoán.', 680),
    (13, 3, 'Big Little Truths: Reese''s Book Club', 'Liane Moriarty', 'Crown', 2026, '9780593798638', 'Tiếng Anh', 464,
        (SELECT id FROM categories WHERE slug = 'van-hoc-duong-dai'), 'VERY_GOOD', 'Phần tiếp nối Big Little Lies trở lại với Madeline, Celeste, Jane, Renata và Bonnie khi con họ đã bước vào tuổi thiếu niên. Một gói đồ đe dọa gửi tới hiệu trưởng khơi dậy những căng thẳng mới về gia đình, tình bạn và các sự thật bị che giấu.', 620),
    (14, 3, 'The Poison Daughter', 'Sheila Masterson', 'Slowburn', 2026, '9781638935971', 'Tiếng Anh', 672,
        (SELECT id FROM categories WHERE slug = 'ky-ao-gia-tuong'), 'LIKE_NEW', 'Harlow Carrenwell sở hữu nụ hôn có thể giết người và bí mật trừng phạt những kẻ bạo hành trong thành phố. Khi vị hôn phu Henry Havenwood sống sót sau nụ hôn của cô, Harlow phải tìm hiểu khả năng miễn nhiễm của anh và âm mưu của gia đình anh.', 930),
    (15, 3, 'The True Meaning of Love', 'Danielle Steel', 'Delacorte Press', 2026, '9780593973141', 'Tiếng Anh', 256,
        (SELECT id FROM categories WHERE slug = 'ngon-tinh-lang-man'), 'NEW', 'Cuộc tấn công vào Ukraine năm 2022 làm đảo lộn cuộc đời các nhân vật bình thường, trong đó có đôi học viên múa ballet Vlad và Tatyanna. Tiểu thuyết theo chân những người phải lựa chọn giữa chiến đấu, tìm nơi an toàn và ở lại bên người thân.', 430),
    (16, 3, 'The Butcher Legacy', 'Alaina Urquhart', 'Zando', 2026, '9781638933403', 'Tiếng Anh', 384,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'LIKE_NEW', 'Bác sĩ pháp y Wren Muller trở lại nhà xác New Orleans sau những biến cố trước đó. Khi các cô gái trẻ tiếp tục mất tích và một mục sư biến mất, cô cùng John Leroux bị kéo vào mạng lưới bí mật liên quan đến Jeremy Rose.', 530),
    (17, 3, 'Insatiable', 'Leigh Rivers', 'ZPN', 2026, '9781638935469', 'Tiếng Anh', 416,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'VERY_GOOD', 'Kade Mitchell trở về với nỗi ám ảnh dành cho Stacey Rhodes, người từng khiến anh tổn thương. Phần mở đầu bộ Edge of Darkness theo đuổi mối quan hệ u tối, nơi tình cảm, thù hận và thế giới tội phạm đan xen.', 460),
    (18, 3, 'A Trade of Blood', 'Robert Jackson Bennett', 'Del Rey', 2026, '9780593723852', 'Tiếng Anh', 400,
        (SELECT id FROM categories WHERE slug = 'ky-ao-gia-tuong'), 'NEW', 'Thám tử Ana Dolabra phải chứng minh sự vô tội của một người thừa kế bị kết tội giết người để ngăn một cuộc chiến. Cùng trợ lý Dinios Kol, cô lần theo chuỗi án mạng dẫn tới một công nghệ phép thuật cổ xưa và đáng sợ.', 630),
    (19, 3, 'The Amateur', 'Chris Bohjalian', 'Doubleday', 2026, '9780385551298', 'Tiếng Anh', 336,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'NEW', 'Năm 1978, quả bóng golf của cô gái trẻ Mira Winston khiến một caddie tử vong. Cuộc điều tra từ một tai nạn tưởng chừng đơn giản dần hé lộ những quan hệ bí mật và biến cô thành tâm điểm phán xét của cộng đồng giàu có.', 490),
    (20, 3, 'Getting Away with Murder', 'Shari Lapena', 'Pamela Dorman Books', 2026, '9780593832479', 'Tiếng Anh', 352,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'VERY_GOOD', 'Jill và Ted đứng trước nguy cơ mất căn nhà yêu quý sau khi tiền thừa kế cạn kiệt và việc đầu tư thất bại. Họ tin rằng cái chết của một người thân giàu có sẽ giải quyết mọi chuyện, nhưng kế hoạch phụ thuộc vào lòng tin mong manh giữa hai người.', 580),
    (21, 4, 'Simply Ina', 'Ina Garten', 'Clarkson Potter', 2026, '9780593234174', 'Tiếng Anh', 256,
        (SELECT id FROM categories WHERE slug = 'nau-an-gia-dinh'), 'NEW', 'Ina Garten chia sẻ cách nấu ăn và tiếp đãi khách với những công thức dễ thực hiện hơn. Sách nhấn mạnh việc chuẩn bị trước, lựa chọn nguyên liệu mua sẵn hợp lý và các bước giúp giảm áp lực trong bếp mà vẫn tạo ra bữa ăn hấp dẫn.', 760),
    (22, 4, 'Mediterranean All the Way', 'Ayesha Nurdjaja', 'Clarkson Potter', 2026, '9780593799901', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'am-thuc-quoc-te'), 'GOOD', 'Ayesha Nurdjaja giới thiệu hơn 120 công thức lấy cảm hứng từ ẩm thực Địa Trung Hải và Levant. Rau củ theo mùa, thảo mộc, gia vị, bánh mì dẹt và các loại sốt tạo nên những món ăn nhiều hương vị dành cho bữa ăn chia sẻ.', 860),
    (23, 4, 'Love and Lemons Pop of Flavor', 'Jeanine Donofrio', 'Avery', 2026, '9780593853146', 'Tiếng Anh', 336,
        (SELECT id FROM categories WHERE slug = 'an-chay-dinh-duong'), 'GOOD', 'Jeanine Donofrio hướng dẫn làm mới bữa ăn hằng ngày bằng các thành phần tăng hương vị như sốt, đồ chua và lớp phủ giòn. Công thức được tổ chức theo đặc điểm vị giác, giúp người nấu phối hợp và tái sử dụng phần chuẩn bị sẵn linh hoạt.', 880),
    (24, 4, 'Why Am I Like This?', 'Sabrina Zohar', 'Penguin Life', 2026, '9780593994849', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'tam-ly-hoc'), 'NEW', 'Sabrina Zohar xem xét những khuôn mẫu như chiều lòng người khác, né tránh và nghi ngờ giá trị bản thân trong tình yêu. Từ trải nghiệm cá nhân và công việc tư vấn, tác giả đưa ra cách nhận diện thói quen phản ứng và xây dựng sự tin tưởng vào chính mình.', 480),
    (25, 4, 'The Rush', 'Nathaniel Philbrick', 'Viking', 2026, '9780525562238', 'Tiếng Anh', 464,
        (SELECT id FROM categories WHERE slug = 'lich-su-the-gioi'), 'NEW', 'Nathaniel Philbrick kể lại cơn sốt vàng California bắt đầu năm 1848 và tác động của nó tới lịch sử Hoa Kỳ. Sách theo dõi người di cư, cộng đồng bản địa và các nhân vật chính trị giữa cuộc cạnh tranh về tài sản, quyền lực và chế độ nô lệ.', 670),
    (26, 4, 'Ottolenghi Simple Too', 'Yotam Ottolenghi', 'Ten Speed Press', 2026, '9781984860088', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'am-thuc-quoc-te'), 'LIKE_NEW', 'Yotam Ottolenghi giới thiệu 135 công thức mới cho bữa sáng, bữa trưa, bữa tối và món tráng miệng. Các món được xây dựng quanh những cách đơn giản hóa việc nấu ăn như chuẩn bị trước, dùng một nồi hoặc giảm thời gian thực hiện.', 840),
    (27, 4, 'Into the quiet', 'John Mark Comer', 'WaterBrook', 2026, '9780593193808', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'ton-giao-tam-linh'), 'LIKE_NEW', 'John Mark Comer khám phá nhu cầu tìm lại sự yên tĩnh giữa nhịp sống bận rộn và sự phân tâm kỹ thuật số. Dựa trên truyền thống chiêm niệm Kitô giáo, sách bàn về thực hành cô tịch, im lặng và tĩnh tâm trong đời sống tinh thần.', 490),
    (28, 4, 'Sleeping Beauties', 'David Byrne', 'Penguin Press', 2026, '9780593655276', 'Tiếng Anh', 400,
        (SELECT id FROM categories WHERE slug = 'khoa-hoc-tu-nhien'), 'NEW', 'David Byrne tìm hiểu vì sao nhiều phát minh, khám phá và tác phẩm nghệ thuật từng bị bỏ quên rồi mới được công nhận. Qua các trường hợp thuộc khoa học và văn hóa, sách suy ngẫm về cách ý tưởng được tiếp nhận và điều kiện để chúng hồi sinh.', 630),
    (29, 4, 'How to Win at Chess, Next Level', 'Levy Rozman', 'Ten Speed Press', 2026, '9780593837818', 'Tiếng Anh', 240,
        (SELECT id FROM categories WHERE slug = 'tro-choi-giai-do'), 'LIKE_NEW', 'Levy Rozman hướng dẫn người chơi cờ vua trình độ trung cấp phát triển vượt khỏi kiến thức cơ bản. Sách đề cập cách sử dụng tốt và quân, chiến thuật, tấn công, phòng thủ, tàn cuộc và lập kế hoạch, kèm nhiều hình minh họa thế cờ.', 410),
    (30, 4, 'What Could Possibly Go Right?', 'Danny Meyer', 'Random House', 2026, '9780593731772', 'Tiếng Anh', 336,
        (SELECT id FROM categories WHERE slug = 'hoi-ky-tu-truyen'), 'VERY_GOOD', 'Doanh nhân ngành nhà hàng Danny Meyer chia sẻ những bài học về lãnh đạo và xây dựng văn hóa làm việc. Từ cả thành công lẫn việc đóng cửa nhà hàng, ông phân tích cách đối diện thất bại, phát triển tổ chức và tạo động lực cho đội ngũ.', 930),
    (31, 4, 'Man in the Mirror', 'Anand Giridharadas', 'Knopf', 2026, '9780593802014', 'Tiếng Anh', 480,
        (SELECT id FROM categories WHERE slug = 'lich-su-the-gioi'), 'GOOD', 'Anand Giridharadas điều tra cuộc chạm trán gây chết người giữa Jordan Neely và Daniel Penny trên tàu điện ngầm New York năm 2023. Qua nhiều góc nhìn và diễn biến tại tòa, sách xem xét sự cô lập, nhu cầu thuộc về cộng đồng và những chia rẽ xã hội.', 650),
    (32, 4, 'A Fabulous Debt', 'Robin Wigglesworth', 'Portfolio', 2026, '9780593719183', 'Tiếng Anh', 416,
        (SELECT id FROM categories WHERE slug = 'kinh-te-hoc'), 'LIKE_NEW', 'Robin Wigglesworth kể lịch sử thị trường trái phiếu và vai trò của nợ trong việc hình thành thế giới hiện đại. Sách kết nối các công cụ tài chính với con người, chiến tranh, hạ tầng và những tổ chức đã mở rộng ảnh hưởng của thị trường này.', 570),
    (33, 4, 'Work in Progress', 'Devon Rodriguez', 'One World', 2026, '9780593734483', 'Tiếng Anh', 368,
        (SELECT id FROM categories WHERE slug = 'hoi-ky-tu-truyen'), 'NEW', 'Họa sĩ Devon Rodriguez kể về tuổi thơ khó khăn và hành trình phát triển sự nghiệp vẽ chân dung. Những trải nghiệm trên tàu điện ngầm New York, sự hỗ trợ từ người thân và sức mạnh của nghệ thuật giúp ông tìm thấy phương hướng sống.', 540),
    (34, 4, 'The Cauldron', 'Simon Sebag Montefiore', 'Knopf', 2026, '9780593805053', 'Tiếng Anh', 528,
        (SELECT id FROM categories WHERE slug = 'lich-su-the-gioi'), 'LIKE_NEW', 'Simon Sebag Montefiore trình bày lịch sử Trung Đông từ đầu thế kỷ XX tới thời hiện đại. Tác phẩm kết nối các chuyển biến chính trị, tôn giáo và xã hội thông qua những nhân vật và xung đột đã định hình khu vực.', 680),
    (35, 4, 'An Unexpected Life', 'Gloria Steinem', 'Random House', 2026, '9780593978177', 'Tiếng Anh', 256,
        (SELECT id FROM categories WHERE slug = 'chan-dung-nhan-vat'), 'NEW', 'Gloria Steinem nhìn lại tuổi thơ, những chuyến đi và các bước ngoặt dẫn bà đến hoạt động vì quyền bình đẳng. Hồi ký ghi nhận những con người, phong trào và trải nghiệm đã hình thành quan điểm của bà về cộng đồng và quyền lực.', 410),
    (36, 4, 'Meals You Can''t Mess Up', 'Shay Spence', 'DK', 2026, '9780593968710', 'Tiếng Anh', 256,
        (SELECT id FROM categories WHERE slug = 'nau-an-gia-dinh'), 'NEW', 'Shay Spence đưa ra hơn 100 công thức nhằm giúp người ít kinh nghiệm tự tin nấu ăn. Sách tập trung vào món ít nguyên liệu, hạn chế dụng cụ và công đoạn chuẩn bị, với các nhóm công thức nhanh, một nồi và không cần thái cắt.', 730),
    (37, 4, 'Saved by the Pack', 'Lee Asher', 'National Geographic', 2026, '9781426224706', 'Tiếng Anh', 320,
        (SELECT id FROM categories WHERE slug = 'thu-cung-thien-nhien'), 'GOOD', 'Lee Asher kể hành trình tìm thấy mục đích sống qua công việc cứu hộ động vật tại The Asher House. Câu chuyện của 50 trường hợp cứu hộ làm nổi bật sự gắn bó giữa con người và động vật, cùng những thử thách của công việc chăm sóc chúng.', 510),
    (38, 4, 'Redwood', 'Ben Macintyre', 'Crown', 2026, '9780593728123', 'Tiếng Anh', 416,
        (SELECT id FROM categories WHERE slug = 'lich-su-the-gioi'), 'VERY_GOOD', 'Ben Macintyre kể câu chuyện điệp viên thời Chiến tranh Lạnh về sĩ quan KGB Vladimir Kuzichkin tại Iran và mối liên hệ của ông với MI6. Những hoạt động tình báo, bí mật cá nhân và nguy cơ bị phát hiện tạo nên một cuộc đối đầu căng thẳng.', 590),
    (39, 4, 'Veg Everything', 'Tanya Sichynsky, New York Times Cooking', 'Ten Speed Press', 2026, '9780593836620', 'Tiếng Anh', 240,
        (SELECT id FROM categories WHERE slug = 'an-chay-dinh-duong'), 'NEW', 'Tuyển tập 101 công thức chay từ NYT Cooking do Tanya Sichynsky tuyển chọn, trải rộng từ bữa sáng đến món chính và tiệc đãi khách. Sách giới thiệu cách khai thác rau củ, đậu và đậu phụ để tạo bữa ăn phong phú, kèm gợi ý thực đơn.', 730),
    (40, 4, 'The Portable Feminist Reader', 'Nhiều tác giả', 'Penguin Classics', 2025, '9780143110392', 'Tiếng Anh', 672,
        (SELECT id FROM categories WHERE slug = 'tieu-luan-tuyen-tap'), 'GOOD', 'Roxane Gay tuyển chọn các văn bản nữ quyền từ nhiều thời kỳ và góc nhìn khác nhau. Tuyển tập đề cập chủng tộc, lao động, khuyết tật, sinh thái và giới, khuyến khích người đọc xem tư tưởng nữ quyền như một truyền thống luôn được tranh luận và phát triển.', 760),
    (41, 3, 'Dark Tales', 'Shirley Jackson', 'Penguin Classics', 2017, '9780143132004', 'Tiếng Anh', 208,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'NEW', 'Tuyển tập truyện ngắn kinh dị của Shirley Jackson biến những tình huống đời thường thành trải nghiệm bất an. Đằng sau khu phố, căn nhà và các quan hệ tưởng quen thuộc là sự đe dọa, bí mật cùng những mặt tối khó lường của con người.', 290),
    (42, 3, 'It Can''t Happen Here', 'Sinclair Lewis', 'Berkley', 2005, '9780451216588', 'Tiếng Anh', 400,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'NEW', 'Tiểu thuyết châm biếm chính trị của Sinclair Lewis hình dung sự trỗi dậy của chế độ độc tài tại Hoa Kỳ. Tác phẩm xem xét tính mong manh của nền dân chủ và cách lời hứa cứu đất nước có thể trở thành công cụ tập trung quyền lực.', 470),
    (43, 4, 'Twelve Years a Slave', 'Solomon Northup', 'Penguin Classics', 2012, '9780143106708', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'hoi-ky-tu-truyen'), 'LIKE_NEW', 'Solomon Northup kể lại việc mình, một người tự do ở New York, bị bắt cóc và bán làm nô lệ năm 1841. Hồi ký ghi lại mười hai năm bị giam hãm tại Louisiana, cung cấp lời chứng trực tiếp về bạo lực và đời sống dưới chế độ nô lệ.', 380),
    (44, 4, 'The Collected Autobiographies of Maya Angelou', 'Maya Angelou', 'Modern Library', 2004, '9780679643258', 'Tiếng Anh', 1184,
        (SELECT id FROM categories WHERE slug = 'hoi-ky-tu-truyen'), 'LIKE_NEW', 'Ấn bản tập hợp sáu cuốn tự truyện của Maya Angelou, từ tuổi thơ ở miền Nam Hoa Kỳ đến sự nghiệp viết văn. Các hồi ức đi qua trải nghiệm làm mẹ, biểu diễn, sống ở nước ngoài và tham gia phong trào dân quyền.', 1530),
    (45, 4, 'Vera', 'Stacy Schiff', 'Modern Library', 2000, '9780375755347', 'Tiếng Anh', 496,
        (SELECT id FROM categories WHERE slug = 'chan-dung-nhan-vat'), 'VERY_GOOD', 'Stacy Schiff khắc họa cuộc đời Véra Nabokov và cuộc hôn nhân kéo dài hơn nửa thế kỷ với nhà văn Vladimir Nabokov. Tiểu sử làm rõ vai trò của bà trong đời sống riêng, công việc văn chương và những năm tháng di cư của hai người.', 600),
    (46, 4, 'The Rise of Theodore Roosevelt', 'Edmund Morris', 'Random House', 2010, '9781400069651', 'Tiếng Anh', 960,
        (SELECT id FROM categories WHERE slug = 'chan-dung-nhan-vat'), 'VERY_GOOD', 'Edmund Morris theo dõi Theodore Roosevelt từ thời thơ ấu yếu ớt đến lúc trở thành một nhân vật chính trị nổi bật. Tiểu sử tái hiện quá trình hình thành tính cách, hoạt động cải cách, trải nghiệm miền Tây và sự nghiệp quân sự của ông.', 1150),
    (47, 4, 'The Diary of a Young Girl', 'Anne Frank', 'Everyman''s Library', 2010, '9780307594006', 'Tiếng Anh', 320,
        (SELECT id FROM categories WHERE slug = 'hoi-ky-tu-truyen'), 'LIKE_NEW', 'Nhật ký của Anne Frank ghi lại hai năm sống trong hoàn cảnh phải lẩn trốn dưới sự đe dọa của Đức Quốc xã. Những trang viết kết hợp nỗi sợ, các va chạm gia đình và suy tư của một cô gái trẻ về bản thân và con người.', 470),
    (48, 3, 'The Short Novels of John Steinbeck', 'John Steinbeck', 'Penguin Classics', 2009, '9780143105770', 'Tiếng Anh', 624,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'VERY_GOOD', 'Tuyển tập sáu tiểu thuyết ngắn của John Steinbeck, trong đó có Of Mice and Men, Cannery Row và The Pearl. Các tác phẩm khám phá tình bạn, cô đơn, hy vọng và cuộc sống của những con người ở bên lề xã hội.', 720),
    (49, 3, 'Shadow Country', 'Peter Matthiessen', 'Modern Library', 2008, '9780812980622', 'Tiếng Anh', 912,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'GOOD', 'Peter Matthiessen tái cấu trúc bộ tiểu thuyết về E. J. Watson, một chủ đồn điền và nhân vật ngoài vòng pháp luật ở Florida. Tác phẩm nhìn lại vùng biên Everglades đầu thế kỷ XX qua nhiều tiếng nói, ký ức và những xung đột bạo lực.', 1040),
    (50, 3, 'The Stone Diaries', 'Carol Shields', 'Penguin Classics', 2008, '9780143105503', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'NEW', 'Carol Shields kể cuộc đời Daisy Goodwill Flett dưới hình thức tự truyện hư cấu. Từ ký ức thời thơ ấu đến tuổi già, tiểu thuyết làm nổi bật thế giới nội tâm phong phú đằng sau một cuộc sống tưởng như bình thường.', 400),
    (51, 3, 'A Death in the Family', 'James Agee', 'Penguin Classics', 2009, '9780143105718', 'Tiếng Anh', 320,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'NEW', 'Một tai nạn xe hơi cướp đi sinh mạng Jay Follet khi anh đang trở về Knoxville, Tennessee. James Agee miêu tả cách cái chết bất ngờ làm tan vỡ sự yên ổn của gia đình và những trải nghiệm đau buồn của người ở lại.', 370),
    (52, 3, 'The Winter of Our Discontent', 'John Steinbeck', 'Penguin Classics', 2008, '9780143039488', 'Tiếng Anh', 336,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'NEW', 'Ethan Allen Hawley làm thuê tại cửa hàng từng thuộc về gia đình mình và chịu áp lực từ những mong muốn vật chất của người thân. Cuộc khủng hoảng đạo đức khiến anh cân nhắc từ bỏ các nguyên tắc, mở ra câu chuyện về tham vọng và sự trung thực.', 380),
    (53, 3, 'Excellent Women', 'Barbara Pym', 'Penguin Classics', 2006, '9780143104872', 'Tiếng Anh', 256,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'VERY_GOOD', 'Mildred Lathbury, một phụ nữ độc thân hiền hòa ở nước Anh thập niên 1950, bị cuốn vào cuộc sống của hàng xóm và giáo xứ. Barbara Pym dùng sự hài hước kín đáo để quan sát những kỳ vọng xã hội, quan hệ tình cảm và khát vọng bị kìm nén.', 330),
    (54, 3, 'The Haunting of Hill House', 'Shirley Jackson', 'Penguin Classics', 2016, '9780143129370', 'Tiếng Anh', 272,
        (SELECT id FROM categories WHERE slug = 'trinh-tham-kinh-di'), 'LIKE_NEW', 'Bốn người đến Hill House để khảo sát những hiện tượng được cho là siêu nhiên trong căn nhà nổi tiếng đáng sợ. Khi các sự kiện khó giải thích xuất hiện, ranh giới giữa nỗi ám ảnh tâm lý và sức mạnh của ngôi nhà dần trở nên bất ổn.', 320),
    (55, 3, 'We Have Always Lived in the Castle', 'Shirley Jackson', 'Penguin Classics', 2021, '9780143134831', 'Tiếng Anh', 160,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'GOOD', 'Merricat sống tách biệt với chị gái Constance và chú Julian sau vụ đầu độc khiến nhiều thành viên gia đình thiệt mạng. Sự xuất hiện của người anh họ Charles đe dọa cuộc sống khép kín ấy và khơi dậy những bí mật của gia đình Blackwood.', 330),
    (56, 3, 'Beloved (Pulitzer Prize Winner)', 'Toni Morrison', 'Knopf', 2019, '9780525659273', 'Tiếng Anh', 288,
        (SELECT id FROM categories WHERE slug = 'van-hoc-duong-dai'), 'LIKE_NEW', 'Sethe trốn thoát khỏi chế độ nô lệ nhưng vẫn bị những ký ức đau đớn đeo bám nhiều năm sau. Sự ám ảnh trong ngôi nhà của bà trở thành trung tâm câu chuyện về tình mẫu tử, mất mát và hậu quả lâu dài của bạo lực lịch sử.', 440),
    (57, 3, 'The Grapes of Wrath', 'John Steinbeck', 'Penguin Classics', 2006, '9780143039433', 'Tiếng Anh', 528,
        (SELECT id FROM categories WHERE slug = 'van-hoc-kinh-dien'), 'VERY_GOOD', 'Gia đình Joad bị đẩy khỏi trang trại ở Oklahoma trong thời Đại suy thoái và lên đường tới California tìm cuộc sống mới. John Steinbeck khắc họa hành trình của người lao động di cư, sự bất công kinh tế và sức bền của tình thân.', 650),
    (58, 3, 'Kristin Lavransdatter', 'Sigrid Undset', 'Penguin Classics', 2005, '9780143039167', 'Tiếng Anh', 1168,
        (SELECT id FROM categories WHERE slug = 'tieu-thuyet-lich-su'), 'LIKE_NEW', 'Lấy bối cảnh Na Uy thế kỷ XIV, tác phẩm theo chân Kristin từ tuổi trẻ đến hôn nhân và những biến động gia đình. Lựa chọn tình yêu trái ý cha mẹ của cô gắn với các xung đột về đức tin, bổn phận và tham vọng chính trị.', 1180),
    (59, 4, 'How to Be Okay When Nothing Is Okay', 'Jenny Lawson', 'Penguin Life', 2026, '9780593833216', 'Tiếng Anh', 288,
        (SELECT id FROM categories WHERE slug = 'hai-huoc'), 'GOOD', 'Jenny Lawson chia sẻ những cách riêng giúp bà tiếp tục sống và sáng tạo khi đối diện trầm cảm, lo âu và ADHD. Với giọng văn hài hước, sách tập trung vào lòng tự cảm thông, việc tìm sự hỗ trợ và nhận ra niềm vui trong những ngày khó khăn.', 450),
    (60, 4, 'I''ll Have What She''s Having', 'Chelsea Handler', 'The Dial Press', 2025, '9780593596579', 'Tiếng Anh', 320,
        (SELECT id FROM categories WHERE slug = 'hai-huoc'), 'NEW', 'Chelsea Handler kể hành trình trở thành người phụ nữ độc lập mà mình từng mong muốn qua những bài viết vừa hài hước vừa riêng tư. Các câu chuyện trải từ tuổi thơ, công việc và những cuộc phiêu lưu đến gia đình, tình yêu và việc học cách ở một mình.', 510),
    (61, 4, 'What in the World?!', 'Leanne Morgan', 'Convergent Books', 2026, '9780593594414', 'Tiếng Anh', 240,
        (SELECT id FROM categories WHERE slug = 'hai-huoc'), 'VERY_GOOD', 'Diễn viên hài Leanne Morgan nhìn lại hành trình tìm thấy tiếng nói riêng sau nhiều năm chăm sóc gia đình và thử sức với nghề. Hồi ký kể về cuộc sống ở Tennessee, hôn nhân, tuổi trung niên và những tình huống đời thường bằng giọng hài hước gần gũi.', 300),
    (62, 4, 'Democracy or Else', 'Jon Favreau, Jon Lovett, Tommy Vietor', 'Crooked Media Reads', 2024, '9781638931430', 'Tiếng Anh', 192,
        (SELECT id FROM categories WHERE slug = 'chinh-tri'), 'NEW', 'Nhóm dẫn chương trình Pod Save America giới thiệu cách tham gia đời sống chính trị Hoa Kỳ. Sách đề cập việc tìm hiểu thông tin, quyên góp, tình nguyện, tổ chức hoạt động và duy trì sự tham gia mà không đánh mất động lực.', 380),
    (63, 4, 'A City on Mars', 'Kelly Weinersmith, Zach Weinersmith', 'Penguin Books', 2025, '9781984881748', 'Tiếng Anh', 448,
        (SELECT id FROM categories WHERE slug = 'khoa-hoc-tu-nhien'), 'NEW', 'Kelly và Zach Weinersmith khảo sát những thách thức của việc xây dựng khu định cư ngoài Trái Đất. Từ sức khỏe, thực phẩm và sinh sản tới luật pháp và quản trị, sách xem xét các khoảng trống kiến thức đằng sau giấc mơ sống trên Mặt Trăng hoặc Sao Hỏa.', 490),
    (64, 4, 'Where the Deer and the Antelope Play', 'Nick Offerman', 'Dutton', 2023, '9781101984703', 'Tiếng Anh', 352,
        (SELECT id FROM categories WHERE slug = 'hai-huoc'), 'VERY_GOOD', 'Nick Offerman kể ba hành trình qua công viên quốc gia, nông trại và các cung đường để suy nghĩ về mối quan hệ với thiên nhiên. Những trải nghiệm đi bộ, thăm bạn và du lịch cùng vợ dẫn tới câu hỏi về đất đai, bảo tồn và đời sống ngoài trời.', 440),
    (65, 4, 'Quietly Hostile', 'Samantha Irby', 'Vintage', 2023, '9780593315699', 'Tiếng Anh', 304,
        (SELECT id FROM categories WHERE slug = 'tieu-luan-tuyen-tap'), 'LIKE_NEW', 'Samantha Irby kể những chuyện ngượng ngùng, khó chịu và buồn cười phía sau hình ảnh công khai của mình. Tuyển tập tiểu luận kết nối sức khỏe, công việc, văn hóa đại chúng và sinh hoạt thường ngày bằng lối tự trào thẳng thắn.', 400),
    (66, 4, 'What If? 2', 'Randall Munroe', 'Riverhead Books', 2022, '9780525537113', 'Tiếng Anh', 368,
        (SELECT id FROM categories WHERE slug = 'khoa-hoc-tu-nhien'), 'LIKE_NEW', 'Randall Munroe dùng kiến thức khoa học để trả lời các câu hỏi giả định kỳ quặc, từ di chuyển giữa Mặt Trăng và Trái Đất đến làm nguội khí quyển bằng tủ lạnh. Các lời giải và hình minh họa biến những ý tưởng phi thực tế thành cơ hội hiểu các nguyên lý khoa học.', 550),
    (67, 4, 'Yearbook', 'Seth Rogen', 'Crown', 2023, '9781984825421', 'Tiếng Anh', 272,
        (SELECT id FROM categories WHERE slug = 'hai-huoc'), 'NEW', 'Seth Rogen tập hợp những câu chuyện thật về gia đình, tuổi thiếu niên, biểu diễn hài và các trải nghiệm ở Los Angeles. Những kỷ niệm và cuộc gặp trong giới giải trí được kể bằng giọng văn hài hước, trực diện và mang tính tự sự.', 360),
    (68, 4, 'Leaving Isn''t the Hardest Thing', 'Lauren Hough', 'Vintage', 2021, '9780593080764', 'Tiếng Anh', 320,
        (SELECT id FROM categories WHERE slug = 'hoi-ky-tu-truyen'), 'NEW', 'Lauren Hough nhìn lại tuổi thơ trong một giáo phái, thời gian phục vụ Không quân Hoa Kỳ và những công việc mưu sinh sau đó. Các bài tiểu luận khám phá bản sắc, xu hướng tính dục, sự sống sót và việc xây dựng đời sống riêng ngoài những ràng buộc quá khứ.', 390),
    (69, 4, 'Humor, Seriously', 'Jennifer Aaker, Naomi Bagdonas', 'Crown Currency', 2021, '9780593135280', 'Tiếng Anh', 272,
        (SELECT id FROM categories WHERE slug = 'phat-trien-ban-than'), 'NEW', 'Jennifer Aaker và Naomi Bagdonas trình bày cách sử dụng sự hài hước trong công việc và đời sống, dựa trên khóa học của họ tại Stanford. Sách kết nối nghiên cứu hành vi với các kỹ thuật giúp tạo quan hệ, giảm căng thẳng và phát triển phong cách hài hước cá nhân.', 470),
    (70, 4, 'Wow, No Thank You.', 'Samantha Irby', 'Vintage', 2020, '9780525563488', 'Tiếng Anh', 336,
        (SELECT id FROM categories WHERE slug = 'hai-huoc'), 'LIKE_NEW', 'Samantha Irby kể về đời sống ở tuổi bốn mươi sau khi rời Chicago, kết hôn và chuyển tới một môi trường mới. Tuyển tập khai thác sức khỏe, tình bạn, công việc và các kỳ vọng về cuộc sống trưởng thành bằng giọng hài hước sắc sảo, không né tránh sự vụng về.', 390);

INSERT INTO book_images (book_id, url, sort_order, source) VALUES
    (1, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980864/rebook/covers/9780735211292.jpg', 0, 'SELLER'),
    (2, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980878/rebook/covers/9780385550543.jpg', 0, 'SELLER'),
    (3, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980879/rebook/covers/9780593973301.jpg', 0, 'SELLER'),
    (4, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980879/rebook/covers/9780593953457.jpg', 0, 'SELLER'),
    (5, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980880/rebook/covers/9781496758088.jpg', 0, 'SELLER'),
    (6, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980881/rebook/covers/9780525426073.jpg', 0, 'SELLER'),
    (7, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980881/rebook/covers/9780593977798.jpg', 0, 'SELLER'),
    (8, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980882/rebook/covers/9780593321461.jpg', 0, 'SELLER'),
    (9, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980883/rebook/covers/9780593726259.jpg', 0, 'SELLER'),
    (10, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980883/rebook/covers/9780385550345.jpg', 0, 'SELLER'),
    (11, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980885/rebook/covers/9780593717202.jpg', 0, 'SELLER'),
    (12, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980886/rebook/covers/9781638936015.jpg', 0, 'SELLER'),
    (13, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980887/rebook/covers/9780593798638.jpg', 0, 'SELLER'),
    (14, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980888/rebook/covers/9781638935971.jpg', 0, 'SELLER'),
    (15, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980889/rebook/covers/9780593973141.jpg', 0, 'SELLER'),
    (16, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980890/rebook/covers/9781638933403.jpg', 0, 'SELLER'),
    (17, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980891/rebook/covers/9781638935469.jpg', 0, 'SELLER'),
    (18, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980891/rebook/covers/9780593723852.jpg', 0, 'SELLER'),
    (19, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980892/rebook/covers/9780385551298.jpg', 0, 'SELLER'),
    (20, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980893/rebook/covers/9780593832479.jpg', 0, 'SELLER'),
    (21, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980894/rebook/covers/9780593234174.jpg', 0, 'SELLER'),
    (22, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980895/rebook/covers/9780593799901.jpg', 0, 'SELLER'),
    (23, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980895/rebook/covers/9780593853146.jpg', 0, 'SELLER'),
    (24, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980896/rebook/covers/9780593994849.jpg', 0, 'SELLER'),
    (25, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980897/rebook/covers/9780525562238.jpg', 0, 'SELLER'),
    (26, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980897/rebook/covers/9781984860088.jpg', 0, 'SELLER'),
    (27, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980898/rebook/covers/9780593193808.jpg', 0, 'SELLER'),
    (28, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980899/rebook/covers/9780593655276.jpg', 0, 'SELLER'),
    (29, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980900/rebook/covers/9780593837818.jpg', 0, 'SELLER'),
    (30, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980901/rebook/covers/9780593731772.jpg', 0, 'SELLER'),
    (31, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980901/rebook/covers/9780593802014.jpg', 0, 'SELLER'),
    (32, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980902/rebook/covers/9780593719183.jpg', 0, 'SELLER'),
    (33, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980903/rebook/covers/9780593734483.jpg', 0, 'SELLER'),
    (34, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980903/rebook/covers/9780593805053.jpg', 0, 'SELLER'),
    (35, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980904/rebook/covers/9780593978177.jpg', 0, 'SELLER'),
    (36, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980905/rebook/covers/9780593968710.jpg', 0, 'SELLER'),
    (37, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980905/rebook/covers/9781426224706.jpg', 0, 'SELLER'),
    (38, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980906/rebook/covers/9780593728123.jpg', 0, 'SELLER'),
    (39, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980907/rebook/covers/9780593836620.jpg', 0, 'SELLER'),
    (40, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980907/rebook/covers/9780143110392.jpg', 0, 'SELLER'),
    (41, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980908/rebook/covers/9780143132004.jpg', 0, 'SELLER'),
    (42, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980909/rebook/covers/9780451216588.jpg', 0, 'SELLER'),
    (43, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980910/rebook/covers/9780143106708.jpg', 0, 'SELLER'),
    (44, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980911/rebook/covers/9780679643258.jpg', 0, 'SELLER'),
    (45, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980912/rebook/covers/9780375755347.jpg', 0, 'SELLER'),
    (46, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980912/rebook/covers/9781400069651.jpg', 0, 'SELLER'),
    (47, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980913/rebook/covers/9780307594006.jpg', 0, 'SELLER'),
    (48, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980914/rebook/covers/9780143105770.jpg', 0, 'SELLER'),
    (49, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980915/rebook/covers/9780812980622.jpg', 0, 'SELLER'),
    (50, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980916/rebook/covers/9780143105503.jpg', 0, 'SELLER'),
    (51, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980917/rebook/covers/9780143105718.jpg', 0, 'SELLER'),
    (52, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980918/rebook/covers/9780143039488.jpg', 0, 'SELLER'),
    (53, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980918/rebook/covers/9780143104872.jpg', 0, 'SELLER'),
    (54, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980919/rebook/covers/9780143129370.jpg', 0, 'SELLER'),
    (55, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980920/rebook/covers/9780143134831.jpg', 0, 'SELLER'),
    (56, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980920/rebook/covers/9780525659273.jpg', 0, 'SELLER'),
    (57, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980921/rebook/covers/9780143039433.jpg', 0, 'SELLER'),
    (58, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980922/rebook/covers/9780143039167.jpg', 0, 'SELLER'),
    (59, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980922/rebook/covers/9780593833216.jpg', 0, 'SELLER'),
    (60, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980923/rebook/covers/9780593596579.jpg', 0, 'SELLER'),
    (61, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980924/rebook/covers/9780593594414.jpg', 0, 'SELLER'),
    (62, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980925/rebook/covers/9781638931430.jpg', 0, 'SELLER'),
    (63, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980925/rebook/covers/9781984881748.jpg', 0, 'SELLER'),
    (64, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980926/rebook/covers/9781101984703.jpg', 0, 'SELLER'),
    (65, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980927/rebook/covers/9780593315699.jpg', 0, 'SELLER'),
    (66, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980928/rebook/covers/9780525537113.jpg', 0, 'SELLER'),
    (67, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980929/rebook/covers/9781984825421.jpg', 0, 'SELLER'),
    (68, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980930/rebook/covers/9780593080764.jpg', 0, 'SELLER'),
    (69, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980930/rebook/covers/9780593135280.jpg', 0, 'SELLER'),
    (70, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793980931/rebook/covers/9780525563488.jpg', 0, 'SELLER');

INSERT INTO listings (id, book_id, shop_id, price, stock, sold_count, status, created_at) VALUES
    (1, 1, 2, 306000, 5, 0, 'ACTIVE', now() - interval '8 days'),
    (2, 2, 1, 406000, 3, 0, 'ACTIVE', now() - interval '15 days'),
    (3, 3, 1, 253000, 4, 0, 'ACTIVE', now() - interval '22 days'),
    (4, 4, 1, 295000, 3, 0, 'ACTIVE', now() - interval '29 days'),
    (5, 5, 1, 390000, 5, 0, 'ACTIVE', now() - interval '6 days'),
    (6, 6, 1, 224000, 4, 0, 'ACTIVE', now() - interval '13 days'),
    (7, 7, 1, 304000, 5, 0, 'ACTIVE', now() - interval '20 days'),
    (8, 8, 1, 401000, 5, 0, 'ACTIVE', now() - interval '27 days'),
    (9, 9, 1, 350000, 4, 0, 'ACTIVE', now() - interval '4 days'),
    (10, 10, 1, 332000, 5, 0, 'ACTIVE', now() - interval '11 days'),
    (11, 11, 1, 364000, 5, 0, 'ACTIVE', now() - interval '18 days'),
    (12, 12, 1, 372000, 3, 0, 'ACTIVE', now() - interval '25 days'),
    (13, 13, 1, 293000, 3, 0, 'ACTIVE', now() - interval '2 days'),
    (14, 14, 1, 346000, 3, 0, 'ACTIVE', now() - interval '9 days'),
    (15, 15, 1, 274000, 4, 0, 'ACTIVE', now() - interval '16 days'),
    (16, 16, 1, 348000, 5, 0, 'ACTIVE', now() - interval '23 days'),
    (17, 17, 1, 176000, 5, 0, 'ACTIVE', now() - interval '30 days'),
    (18, 18, 1, 379000, 4, 0, 'ACTIVE', now() - interval '7 days'),
    (19, 19, 1, 423000, 4, 0, 'ACTIVE', now() - interval '14 days'),
    (20, 20, 1, 254000, 4, 0, 'ACTIVE', now() - interval '21 days'),
    (21, 21, 2, 302000, 5, 0, 'ACTIVE', now() - interval '28 days'),
    (22, 22, 2, 214000, 3, 0, 'ACTIVE', now() - interval '5 days'),
    (23, 23, 2, 302000, 3, 0, 'ACTIVE', now() - interval '12 days'),
    (24, 24, 2, 276000, 4, 0, 'ACTIVE', now() - interval '19 days'),
    (25, 25, 2, 380000, 4, 0, 'ACTIVE', now() - interval '26 days'),
    (26, 26, 2, 327000, 3, 0, 'ACTIVE', now() - interval '3 days'),
    (27, 27, 2, 293000, 4, 0, 'ACTIVE', now() - interval '10 days'),
    (28, 28, 2, 329000, 3, 0, 'ACTIVE', now() - interval '17 days'),
    (29, 29, 2, 267000, 5, 0, 'ACTIVE', now() - interval '24 days'),
    (30, 30, 2, 295000, 4, 0, 'ACTIVE', now() - interval '1 days'),
    (31, 31, 2, 300000, 3, 0, 'ACTIVE', now() - interval '8 days'),
    (32, 32, 2, 411000, 5, 0, 'ACTIVE', now() - interval '15 days'),
    (33, 33, 2, 359000, 5, 0, 'ACTIVE', now() - interval '22 days'),
    (34, 34, 2, 450000, 4, 0, 'ACTIVE', now() - interval '29 days'),
    (35, 35, 2, 280000, 5, 0, 'ACTIVE', now() - interval '6 days'),
    (36, 36, 2, 308000, 4, 0, 'ACTIVE', now() - interval '13 days'),
    (37, 37, 2, 194000, 5, 0, 'ACTIVE', now() - interval '20 days'),
    (38, 38, 2, 337000, 5, 0, 'ACTIVE', now() - interval '27 days'),
    (39, 39, 2, 375000, 3, 0, 'ACTIVE', now() - interval '4 days'),
    (40, 40, 2, 269000, 3, 0, 'ACTIVE', now() - interval '11 days'),
    (41, 41, 1, 186000, 4, 0, 'ACTIVE', now() - interval '18 days'),
    (42, 42, 1, 255000, 5, 0, 'ACTIVE', now() - interval '25 days'),
    (43, 43, 2, 209000, 3, 0, 'ACTIVE', now() - interval '2 days'),
    (44, 44, 2, 395000, 3, 0, 'ACTIVE', now() - interval '9 days'),
    (45, 45, 2, 217000, 4, 0, 'ACTIVE', now() - interval '16 days'),
    (46, 46, 2, 383000, 3, 0, 'ACTIVE', now() - interval '23 days'),
    (47, 47, 2, 246000, 4, 0, 'ACTIVE', now() - interval '30 days'),
    (48, 48, 1, 353000, 4, 0, 'ACTIVE', now() - interval '7 days'),
    (49, 49, 1, 335000, 3, 0, 'ACTIVE', now() - interval '14 days'),
    (50, 50, 1, 238000, 4, 0, 'ACTIVE', now() - interval '21 days'),
    (51, 51, 1, 267000, 3, 0, 'ACTIVE', now() - interval '28 days'),
    (52, 52, 1, 252000, 5, 0, 'ACTIVE', now() - interval '5 days'),
    (53, 53, 1, 156000, 4, 0, 'ACTIVE', now() - interval '12 days'),
    (54, 54, 1, 276000, 5, 0, 'ACTIVE', now() - interval '19 days'),
    (55, 55, 1, 236000, 3, 0, 'ACTIVE', now() - interval '26 days'),
    (56, 56, 1, 315000, 5, 0, 'ACTIVE', now() - interval '3 days'),
    (57, 57, 1, 288000, 3, 0, 'ACTIVE', now() - interval '10 days'),
    (58, 58, 1, 384000, 5, 0, 'ACTIVE', now() - interval '17 days'),
    (59, 59, 2, 274000, 5, 0, 'ACTIVE', now() - interval '24 days'),
    (60, 60, 2, 315000, 5, 0, 'ACTIVE', now() - interval '1 days'),
    (61, 61, 2, 120000, 5, 0, 'ACTIVE', now() - interval '8 days'),
    (62, 62, 2, 237000, 3, 0, 'ACTIVE', now() - interval '15 days'),
    (63, 63, 2, 375000, 4, 0, 'ACTIVE', now() - interval '22 days'),
    (64, 64, 2, 290000, 4, 0, 'ACTIVE', now() - interval '29 days'),
    (65, 65, 2, 193000, 3, 0, 'ACTIVE', now() - interval '6 days'),
    (66, 66, 2, 258000, 3, 0, 'ACTIVE', now() - interval '13 days'),
    (67, 67, 2, 230000, 3, 0, 'ACTIVE', now() - interval '20 days'),
    (68, 68, 2, 235000, 4, 0, 'ACTIVE', now() - interval '27 days'),
    (69, 69, 2, 297000, 3, 0, 'ACTIVE', now() - interval '4 days'),
    (70, 70, 2, 301000, 4, 0, 'ACTIVE', now() - interval '11 days');

-- 24 sách hiếm để đấu giá (ấn bản đầu / sưu tầm, không ISBN, chưa có tin đăng bán thường): chỉ là bản ghi sách
-- kèm ảnh bìa; ký gửi, kiểm định, lô và phiên đấu giá do script demo tạo.
INSERT INTO books (id, owner_id, title, author, publisher, publish_year, isbn, language, pages, category_id,
                   condition_grade, description, weight_gram) VALUES
    (71, 3, 'The Great Gatsby', 'F. Scott Fitzgerald', 'Charles Scribner’s Sons', 1925, NULL, 'Tiếng Anh', 218,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Nick Carraway kể lại cuộc sống của người hàng xóm giàu có Jay Gatsby tại Long Island. Tình yêu dành cho Daisy và những bữa tiệc xa hoa dần hé lộ khoảng cách giữa giấc mơ, địa vị xã hội và thực tế nước Mỹ thập niên 1920.

Ấn bản: Ấn bản đầu tại Mỹ, 1925. Ấn bản đầu với áo bìa do Francis Cugat thiết kế là đối tượng sưu tầm có giá trị; áo bìa còn nguyên đặc biệt khó tìm.', 400),
    (72, 4, 'The Hobbit, or There and Back Again', 'J. R. R. Tolkien', 'George Allen & Unwin', 1937, NULL, 'Tiếng Anh', 310,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Bilbo Baggins rời ngôi nhà yên bình để cùng Gandalf và đoàn người lùn tìm lại kho báu bị rồng Smaug chiếm giữ. Cuộc hành trình qua núi, rừng và hang động thử thách lòng can đảm, trí khôn và khả năng thay đổi của một người hobbit.

Ấn bản: Ấn bản Anh đầu, 1937. Ấn bản đầu của tác phẩm mở đầu thế giới Trung Địa; bản có áo bìa nguyên gốc do Tolkien thiết kế được giới sưu tầm tìm kiếm.', 500),
    (73, 3, 'Ulysses', 'James Joyce', 'Shakespeare and Company', 1922, NULL, 'Tiếng Anh', 732,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Tác phẩm theo chân Leopold Bloom, Stephen Dedalus và Molly Bloom tại Dublin trong ngày 16 tháng 6 năm 1904. Joyce kết hợp độc thoại nội tâm, nhại văn phong và những liên hệ với Odyssey để khám phá đời sống thường ngày, ký ức và bản sắc.

Ấn bản: Ấn bản đầu, Paris, 1922. Ấn bản sách đầu tiên do Sylvia Beach xuất bản ở Paris; mốc quan trọng của văn chương hiện đại và sưu tầm Joyce.', 970),
    (74, 4, 'Dracula', 'Bram Stoker', 'Archibald Constable and Company', 1897, NULL, 'Tiếng Anh', 390,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Qua nhật ký, thư từ và các ghi chép, câu chuyện tái hiện hành trình của bá tước Dracula từ Transylvania đến nước Anh. Jonathan Harker, Mina, Van Helsing và những người đồng hành tìm cách ngăn chặn sức mạnh của ma cà rồng.

Ấn bản: Ấn bản Anh đầu, 1897. Ấn bản đầu với bìa vải vàng chữ đỏ nổi tiếng; một ấn bản nền tảng trong sưu tầm tiểu thuyết kinh dị.', 590),
    (75, 3, 'Nineteen Eighty-Four', 'George Orwell', 'Secker & Warburg', 1949, NULL, 'Tiếng Anh', 328,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Winston Smith sống trong một xã hội giám sát toàn diện, nơi lịch sử bị sửa lại và ngôn ngữ bị kiểm soát. Những suy nghĩ riêng tư và mối quan hệ với Julia khiến anh đối đầu với bộ máy quyền lực của Big Brother.

Ấn bản: Ấn bản Anh đầu, 1949; áo bìa màu đỏ. Ấn bản Anh đầu có áo bìa nguyên gốc là dạng sách sưu tầm; tồn tại hai biến thể màu áo bìa đỏ và xanh.', 520),
    (76, 4, 'Animal Farm: A Fairy Story', 'George Orwell', 'Secker & Warburg', 1945, NULL, 'Tiếng Anh', 92,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Các con vật nổi dậy chống lại người chủ trang trại để xây dựng một cộng đồng bình đẳng. Khi đàn lợn thâu tóm quyền lực, những lời hứa ban đầu bị biến đổi, tạo nên một ngụ ngôn về tuyên truyền và sự tha hóa của cách mạng.

Ấn bản: Ấn bản Anh đầu, 1945. Ấn bản đầu thời chiến với áo bìa giấy còn giữ được là dạng được sưu tầm; phải phân biệt với nhiều lần in sau.', 260),
    (77, 3, 'Brave New World', 'Aldous Huxley', 'Chatto & Windus', 1932, NULL, 'Tiếng Anh', 306,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Trong một thế giới con người được sản xuất và phân tầng ngay từ khi sinh ra, hạnh phúc được duy trì bằng điều kiện hóa và thuốc soma. Sự xuất hiện của John, người lớn lên ngoài xã hội ấy, đặt ra câu hỏi về tự do, đau khổ và phẩm giá.

Ấn bản: Ấn bản Anh đầu, 1932. Ấn bản đầu với áo bìa do Leslie Holland thiết kế được tìm kiếm trong thị trường sách hiếm và văn học phản địa đàng.', 500),
    (78, 4, 'Alice’s Adventures in Wonderland', 'Lewis Carroll; minh họa John Tenniel', 'D. Appleton and Co.', 1866, NULL, 'Tiếng Anh', 192,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Alice đi theo Thỏ Trắng xuống hang và bước vào xứ sở nơi kích thước, ngôn ngữ và quy tắc thông thường liên tục thay đổi. Những cuộc gặp với Mèo Cheshire, Mad Hatter và Nữ hoàng Cơ kết hợp trò chơi logic với trí tưởng tượng.

Ấn bản: Ấn bản đầu, đợt phát hành thứ hai tại Mỹ — Appleton Alice, 1866. Dùng các tờ in Oxford năm 1865 bị thu hồi, thay trang nhan đề để phát hành tại Mỹ năm 1866; một ấn bản sưu tầm có lịch sử đặc biệt.', 370),
    (79, 3, 'Fahrenheit 451', 'Ray Bradbury', 'Ballantine Books', 1953, NULL, 'Tiếng Anh', 199,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Guy Montag làm nghề đốt sách trong một xã hội coi việc đọc là mối đe dọa. Những cuộc gặp gỡ và trải nghiệm khiến anh nghi ngờ công việc của mình, rồi tìm cách gìn giữ tri thức trước một nền văn hóa giải trí và kiểm soát.

Ấn bản: Ấn bản Mỹ đầu, bìa cứng, 1953. Ấn bản bìa cứng đầu của tác phẩm với áo bìa Joe Mugnaini; bản còn áo bìa là sách sưu tầm có giá trị.', 380),
    (80, 4, 'Lord of the Flies', 'William Golding', 'Faber & Faber', 1954, NULL, 'Tiếng Anh', 248,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Một nhóm học sinh sống sót sau tai nạn máy bay trên đảo hoang cố lập ra quy tắc và tổ chức cứu hộ. Nỗi sợ cùng tranh chấp quyền lực dần phá vỡ trật tự, phơi bày sự mong manh của các chuẩn mực văn minh.

Ấn bản: Ấn bản Anh đầu, 1954. Tiểu thuyết đầu tay của Golding; ấn bản đầu kèm áo bìa nguyên gốc là một mục sưu tầm văn học Anh thế kỷ XX.', 430),
    (81, 3, 'Catch-22', 'Joseph Heller', 'Simon and Schuster', 1961, NULL, 'Tiếng Anh', 443,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Phi công Yossarian tìm cách sống sót trong Thế chiến II khi nhiệm vụ chiến đấu ngày càng tăng. Cấu trúc phi tuyến và những tình huống phi lý cho thấy một bộ máy quan liêu trong đó mọi lối thoát đều bị khóa bởi nghịch lý Catch-22.

Ấn bản: Ấn bản Mỹ đầu, 1961. Ấn bản đầu của tiểu thuyết chiến tranh có ảnh hưởng; nguồn ảnh là hồ sơ một bản ký tên được Sotheby’s giới thiệu.', 650),
    (82, 4, 'The Sun Also Rises', 'Ernest Hemingway', 'Charles Scribner’s Sons', 1926, NULL, 'Tiếng Anh', 259,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Jake Barnes và những người bạn lưu vong đi từ Paris đến lễ hội đấu bò ở Pamplona. Dưới những cuộc uống rượu, du lịch và tình yêu dang dở là cảm giác mất phương hướng của thế hệ trải qua Thế chiến I.

Ấn bản: Ấn bản Mỹ đầu, lần in đầu, 1926. Ấn bản đầu kèm áo bìa đợt đầu là mục sưu tầm quan trọng của Hemingway; nguồn ảnh ghi nhận áo bìa có hao mòn.', 440),
    (83, 3, 'A Farewell to Arms', 'Ernest Hemingway', 'Charles Scribner’s Sons', 1929, NULL, 'Tiếng Anh', 355,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Frederic Henry, một người Mỹ phục vụ trong lực lượng cứu thương tại Ý, yêu nữ y tá Catherine Barkley giữa Thế chiến I. Cuộc tình của họ gắn với thương tích, cuộc rút lui và mong muốn tìm một đời sống riêng ngoài chiến tranh.

Ấn bản: Ấn bản thương mại Mỹ đầu, 1929. Ấn bản đầu với áo bìa gốc do Cleonike Damianakes thiết kế được sưu tầm; không nhầm với bản giới hạn hoặc bản in sau.', 550),
    (84, 4, 'The Old Man and the Sea', 'Ernest Hemingway', 'Charles Scribner’s Sons', 1952, NULL, 'Tiếng Anh', 140,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Sau chuỗi ngày đánh bắt thất bại, lão ngư Santiago ra khơi một mình và mắc được con cá kiếm khổng lồ. Cuộc vật lộn trên biển trở thành thử thách về sức bền, lòng tự trọng và khả năng chấp nhận mất mát.

Ấn bản: Ấn bản Mỹ đầu, 1952. Ấn bản đầu có dấu A và dấu nhà xuất bản trên trang bản quyền; áo bìa nguyên gốc là yếu tố quan trọng với người sưu tầm.', 310),
    (85, 3, 'The Grapes of Wrath', 'John Steinbeck', 'The Viking Press', 1939, NULL, 'Tiếng Anh', 619,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Gia đình Joad rời Oklahoma trong thời Đại suy thoái, hướng đến California với hy vọng có việc làm. Trên đường và tại các trại lao động, họ đối diện cảnh nghèo đói, bóc lột và sức ép buộc con người phải lựa chọn giữa chia rẽ và đoàn kết.

Ấn bản: Ấn bản Mỹ đầu, 1939. Ấn bản đầu còn áo bìa Elmer Hader, có dòng First Edition trên tai bìa, là dạng được giới sưu tầm tìm kiếm.', 840),
    (86, 4, 'Of Mice and Men', 'John Steinbeck', 'Covici Friede', 1937, NULL, 'Tiếng Anh', 186,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'George và Lennie đi làm thuê tại các trang trại California, cùng nuôi giấc mơ sở hữu một mảnh đất nhỏ. Tình bạn của họ bị thử thách bởi sự cô độc, những giới hạn cá nhân và một biến cố không thể cứu vãn.

Ấn bản: Ấn bản Mỹ đầu, 1937. Ấn bản đầu với áo bìa gốc là mục sưu tầm Steinbeck; dấu hiệu của từng đợt phát hành phải kiểm tra ở trang 9 và 88.', 360),
    (87, 3, 'East of Eden', 'John Steinbeck', 'The Viking Press', 1952, NULL, 'Tiếng Anh', 602,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Lấy bối cảnh thung lũng Salinas, truyện theo dõi nhiều thế hệ hai gia đình Trask và Hamilton. Qua những xung đột giữa cha mẹ, con cái và anh em, Steinbeck suy ngẫm về thiện ác, di sản gia đình và quyền lựa chọn của mỗi người.

Ấn bản: Ấn bản thương mại Mỹ đầu, 1952. Ấn bản đầu của tiểu thuyết gia đình nổi tiếng; khác với bản giới hạn ký tên và bản câu lạc bộ sách.', 820),
    (88, 4, 'The Maltese Falcon', 'Dashiell Hammett', 'Alfred A. Knopf', 1930, NULL, 'Tiếng Anh', 267,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Thám tử Sam Spade bị cuốn vào cuộc truy tìm một tượng chim ưng quý giá sau khi cộng sự bị sát hại. Những lời nói dối, lòng tham và các liên minh không bền vững khiến anh phải quyết định đâu là ranh giới nghề nghiệp của mình.

Ấn bản: Ấn bản sách Mỹ đầu, 1930. Ấn bản đầu còn áo bìa vàng nguyên gốc đặc biệt được săn tìm; một cột mốc của trinh thám hard-boiled.', 450),
    (89, 3, 'The Little Prince', 'Antoine de Saint-Exupéry; dịch Katherine Woods', 'Reynal & Hitchcock', 1943, NULL, 'Tiếng Anh', 94,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Một phi công gặp hoàng tử bé giữa sa mạc và lắng nghe câu chuyện về những hành tinh em từng ghé qua. Những cuộc trò chuyện về bông hồng, con cáo và người lớn đặt ra các câu hỏi giản dị mà sâu sắc về tình yêu và trách nhiệm.

Ấn bản: Ấn bản Mỹ đầu, lần in thứ sáu (theo hồ sơ người bán). Bản in sớm có áo bìa, thuộc thị trường sách sưu tầm; đây là lần in thứ sáu, KHÔNG phải lần in đầu.', 260),
    (90, 4, 'Lolita', 'Vladimir Nabokov', 'G. P. Putnam’s Sons', 1958, NULL, 'Tiếng Anh', 319,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Tiểu thuyết được trình bày qua lời kể của Humbert Humbert, một người đàn ông tìm cách biện hộ cho việc xâm hại và kiểm soát cô bé Dolores Haze. Ngôn ngữ tinh vi và người kể không đáng tin buộc độc giả đối diện sự thao túng của lời tự sự.

Ấn bản: Ấn bản Mỹ đầu, 1958. Ấn bản Mỹ đầu, khác với bản Olympia Press xuất bản tại Paris năm 1955; có vị trí riêng trong sưu tầm Nabokov.', 510),
    (91, 3, 'The Catcher in the Rye', 'J. D. Salinger', 'Little, Brown and Company', 1951, NULL, 'Tiếng Anh', 277,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Holden Caulfield kể lại vài ngày lang thang ở New York sau khi rời trường nội trú. Giọng kể vừa châm biếm vừa dễ tổn thương bộc lộ nỗi cô đơn, mất mát và sự chống đối của một thiếu niên trước thế giới người lớn.

Ấn bản: Ấn bản Mỹ đầu, 1951. Ấn bản đầu với áo bìa ngựa gỗ màu đỏ do E. Michael Mitchell thiết kế là một mục sưu tầm văn học Mỹ nổi bật.', 460),
    (92, 4, 'A Clockwork Orange', 'Anthony Burgess', 'William Heinemann', 1962, NULL, 'Tiếng Anh', 196,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Alex, một thiếu niên bạo lực, bị đưa vào chương trình cải tạo nhằm loại bỏ khả năng làm điều ác bằng điều kiện hóa. Qua tiếng lóng Nadsat và những nghịch cảnh của nhân vật, tác phẩm chất vấn mối quan hệ giữa tự do lựa chọn và đạo đức.

Ấn bản: Ấn bản Anh đầu, 1962. Ấn bản Anh đầu với áo bìa Barry Trengrove; văn bản Anh có chương kết không có trong ấn bản Mỹ đầu.', 380),
    (93, 3, 'Tender Is the Night', 'F. Scott Fitzgerald', 'Charles Scribner’s Sons', 1934, NULL, 'Tiếng Anh', 408,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Trên vùng Riviera, bác sĩ Dick Diver và người vợ giàu có Nicole xuất hiện như một cặp đôi lý tưởng. Những mối quan hệ và tổn thương tinh thần dần hé lộ sự suy sụp đằng sau vẻ hào nhoáng của họ.

Ấn bản: Ấn bản Mỹ đầu, 1934. Ấn bản đầu với áo bìa nguyên gốc là sách sưu tầm; tiểu thuyết cuối cùng Fitzgerald hoàn thành trong đời.', 610),
    (94, 4, 'The Fellowship of the Ring', 'J. R. R. Tolkien', 'George Allen & Unwin', 1954, NULL, 'Tiếng Anh', 423,
        (SELECT id FROM categories WHERE slug = 'sach-hiem-sach-co'), 'GOOD', 'Frodo Baggins rời Shire để đưa Chiếc Nhẫn khỏi tay Sauron. Cùng những người bạn và Đoàn Hộ Nhẫn, anh vượt qua các vùng đất Trung Địa trong hành trình mà lòng trung thành và sự cám dỗ của quyền lực luôn bị thử thách.

Ấn bản: Ấn bản Anh đầu, 1954; tập I của The Lord of the Rings. Ấn bản đầu, lần in đầu của tập I chỉ có 3.000 bản; áo bìa và bản đồ đi kèm là những yếu tố sưu tầm quan trọng.', 630);

INSERT INTO book_images (book_id, url, sort_order, source) VALUES
    (71, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985265/rebook/covers/rare-01.jpg', 0, 'SELLER'),
    (72, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985178/rebook/covers/rare-02.jpg', 0, 'SELLER'),
    (73, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985179/rebook/covers/rare-03.jpg', 0, 'SELLER'),
    (74, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985245/rebook/covers/rare-04.jpg', 0, 'SELLER'),
    (75, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985182/rebook/covers/rare-05.jpg', 0, 'SELLER'),
    (76, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985183/rebook/covers/rare-06.jpg', 0, 'SELLER'),
    (77, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985183/rebook/covers/rare-07.jpg', 0, 'SELLER'),
    (78, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985184/rebook/covers/rare-08.png', 0, 'SELLER'),
    (79, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985185/rebook/covers/rare-09.jpg', 0, 'SELLER'),
    (80, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985186/rebook/covers/rare-10.jpg', 0, 'SELLER'),
    (81, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985186/rebook/covers/rare-11.jpg', 0, 'SELLER'),
    (82, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985187/rebook/covers/rare-12.jpg', 0, 'SELLER'),
    (83, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985188/rebook/covers/rare-13.jpg', 0, 'SELLER'),
    (84, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985189/rebook/covers/rare-14.jpg', 0, 'SELLER'),
    (85, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985190/rebook/covers/rare-15.jpg', 0, 'SELLER'),
    (86, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985191/rebook/covers/rare-16.jpg', 0, 'SELLER'),
    (87, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985192/rebook/covers/rare-17.jpg', 0, 'SELLER'),
    (88, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985193/rebook/covers/rare-18.jpg', 0, 'SELLER'),
    (89, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985193/rebook/covers/rare-19.jpg', 0, 'SELLER'),
    (90, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985195/rebook/covers/rare-20.jpg', 0, 'SELLER'),
    (91, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985195/rebook/covers/rare-21.jpg', 0, 'SELLER'),
    (92, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985196/rebook/covers/rare-22.jpg', 0, 'SELLER'),
    (93, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985197/rebook/covers/rare-23.jpg', 0, 'SELLER'),
    (94, 'https://res.cloudinary.com/dppc2tng8/image/upload/v1793985198/rebook/covers/rare-24.jpg', 0, 'SELLER');

-- Lượt yêu thích mẫu (để thứ tự "phổ biến" có dữ liệu thật); favorite_count khớp bảng listing_favorites.
INSERT INTO listing_favorites (user_id, listing_id, created_at) VALUES
    (7, 2, now() - interval '9 days'),
    (5, 2, now() - interval '10 days'),
    (6, 2, now() - interval '1 days'),
    (7, 3, now() - interval '8 days'),
    (5, 3, now() - interval '9 days'),
    (6, 4, now() - interval '10 days'),
    (7, 4, now() - interval '1 days'),
    (5, 5, now() - interval '2 days'),
    (5, 6, now() - interval '3 days'),
    (6, 6, now() - interval '4 days'),
    (5, 7, now() - interval '1 days'),
    (6, 7, now() - interval '2 days'),
    (7, 7, now() - interval '3 days'),
    (6, 9, now() - interval '6 days'),
    (7, 9, now() - interval '7 days'),
    (5, 11, now() - interval '1 days'),
    (6, 11, now() - interval '2 days'),
    (7, 11, now() - interval '3 days'),
    (5, 14, now() - interval '6 days'),
    (5, 17, now() - interval '3 days'),
    (5, 21, now() - interval '6 days'),
    (5, 22, now() - interval '4 days'),
    (7, 27, now() - interval '1 days'),
    (5, 27, now() - interval '2 days'),
    (6, 27, now() - interval '3 days'),
    (5, 28, now() - interval '3 days'),
    (6, 29, now() - interval '9 days'),
    (5, 34, now() - interval '10 days'),
    (6, 34, now() - interval '1 days'),
    (7, 34, now() - interval '2 days'),
    (6, 36, now() - interval '4 days'),
    (7, 36, now() - interval '5 days'),
    (7, 40, now() - interval '9 days'),
    (5, 40, now() - interval '10 days'),
    (6, 40, now() - interval '1 days'),
    (5, 42, now() - interval '4 days'),
    (6, 42, now() - interval '5 days'),
    (7, 42, now() - interval '6 days'),
    (7, 43, now() - interval '4 days'),
    (5, 43, now() - interval '5 days'),
    (6, 43, now() - interval '6 days'),
    (7, 44, now() - interval '5 days'),
    (5, 44, now() - interval '6 days'),
    (6, 44, now() - interval '7 days'),
    (7, 45, now() - interval '1 days'),
    (7, 49, now() - interval '4 days'),
    (5, 50, now() - interval '1 days'),
    (7, 56, now() - interval '8 days'),
    (6, 57, now() - interval '5 days'),
    (7, 57, now() - interval '6 days'),
    (5, 57, now() - interval '7 days'),
    (5, 58, now() - interval '4 days'),
    (6, 58, now() - interval '5 days'),
    (6, 61, now() - interval '1 days'),
    (7, 61, now() - interval '2 days'),
    (5, 65, now() - interval '6 days'),
    (6, 65, now() - interval '7 days'),
    (7, 67, now() - interval '4 days'),
    (7, 69, now() - interval '5 days'),
    (7, 70, now() - interval '7 days');

UPDATE listings l SET favorite_count = (SELECT count(*) FROM listing_favorites f WHERE f.listing_id = l.id);

SELECT setval(pg_get_serial_sequence('books', 'id'),    (SELECT max(id) FROM books));
SELECT setval(pg_get_serial_sequence('listings', 'id'), (SELECT max(id) FROM listings));
