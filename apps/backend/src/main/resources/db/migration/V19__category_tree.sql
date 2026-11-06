-- Cây thể loại sách hai cấp (sinh từ tools/books/gen.mjs, đừng sửa tay).
-- Thể loại đã có giữ id (slug trùng thì chỉ cập nhật tên / cha / thứ tự). Thể loại cũ không còn trong cây và không có
-- sách nào dùng thì bị xoá; cái còn sách dùng được giữ lại cho tới khi sách đó bị xoá.

-- 1. Nhóm cha.
INSERT INTO categories (name, slug, sort_order) VALUES
    ('Văn học', 'van-hoc', 1),
    ('Lịch sử – Chính trị', 'lich-su-chinh-tri', 2),
    ('Tiểu sử – Hồi ký', 'tieu-su-hoi-ky', 3),
    ('Kỹ năng sống', 'ky-nang-song', 4),
    ('Ẩm thực – Nấu ăn', 'am-thuc-nau-an', 5),
    ('Hài hước – Tiểu luận', 'hai-huoc-tieu-luan', 6),
    ('Kinh tế – Kinh doanh', 'kinh-te-kinh-doanh', 7),
    ('Khoa học – Công nghệ', 'khoa-hoc-cong-nghe', 8),
    ('Triết học – Tôn giáo', 'triet-hoc-ton-giao', 9),
    ('Giáo trình', 'giao-trinh', 10),
    ('Sở thích – Giải trí', 'so-thich-giai-tri', 11),
    ('Nghệ thuật', 'nghe-thuat', 12),
    ('Thiếu nhi', 'thieu-nhi', 13),
    ('Tham khảo', 'tham-khao', 14),
    ('Truyện tranh – Manga', 'truyen-tranh-manga', 15),
    ('Sức khỏe – Đời sống', 'suc-khoe-doi-song', 16),
    ('Sách hiếm – Sách cổ', 'sach-hiem-sach-co', 17)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, parent_id = NULL, sort_order = EXCLUDED.sort_order;

-- 2. Thể loại con.
INSERT INTO categories (name, slug, parent_id, sort_order)
SELECT v.name, v.slug, p.id, v.sort_order
  FROM (VALUES
    ('Tiểu thuyết Việt Nam', 'tieu-thuyet-viet-nam', 'van-hoc', 1),
    ('Tiểu thuyết nước ngoài', 'tieu-thuyet-nuoc-ngoai', 'van-hoc', 2),
    ('Văn học kinh điển', 'van-hoc-kinh-dien', 'van-hoc', 3),
    ('Văn học đương đại', 'van-hoc-duong-dai', 'van-hoc', 4),
    ('Trinh thám – Kinh dị', 'trinh-tham-kinh-di', 'van-hoc', 5),
    ('Kỳ ảo – Giả tưởng', 'ky-ao-gia-tuong', 'van-hoc', 6),
    ('Ngôn tình – Lãng mạn', 'ngon-tinh-lang-man', 'van-hoc', 7),
    ('Tiểu thuyết lịch sử', 'tieu-thuyet-lich-su', 'van-hoc', 8),
    ('Truyện ngắn', 'truyen-ngan', 'van-hoc', 9),
    ('Thơ', 'tho', 'van-hoc', 10),
    ('Lịch sử Việt Nam', 'lich-su-viet-nam', 'lich-su-chinh-tri', 1),
    ('Lịch sử thế giới', 'lich-su-the-gioi', 'lich-su-chinh-tri', 2),
    ('Chính trị', 'chinh-tri', 'lich-su-chinh-tri', 3),
    ('Hồi ký – Tự truyện', 'hoi-ky-tu-truyen', 'tieu-su-hoi-ky', 1),
    ('Chân dung nhân vật', 'chan-dung-nhan-vat', 'tieu-su-hoi-ky', 2),
    ('Phát triển bản thân', 'phat-trien-ban-than', 'ky-nang-song', 1),
    ('Tâm lý học', 'tam-ly-hoc', 'ky-nang-song', 2),
    ('Gia đình – Nuôi dạy con', 'gia-dinh-nuoi-day-con', 'ky-nang-song', 3),
    ('Nấu ăn gia đình', 'nau-an-gia-dinh', 'am-thuc-nau-an', 1),
    ('Ẩm thực quốc tế', 'am-thuc-quoc-te', 'am-thuc-nau-an', 2),
    ('Ăn chay – Dinh dưỡng', 'an-chay-dinh-duong', 'am-thuc-nau-an', 3),
    ('Hài hước', 'hai-huoc', 'hai-huoc-tieu-luan', 1),
    ('Tiểu luận – Tuyển tập', 'tieu-luan-tuyen-tap', 'hai-huoc-tieu-luan', 2),
    ('Kinh tế học', 'kinh-te-hoc', 'kinh-te-kinh-doanh', 1),
    ('Quản trị – Khởi nghiệp', 'quan-tri-khoi-nghiep', 'kinh-te-kinh-doanh', 2),
    ('Marketing – Bán hàng', 'marketing-ban-hang', 'kinh-te-kinh-doanh', 3),
    ('Khoa học tự nhiên', 'khoa-hoc-tu-nhien', 'khoa-hoc-cong-nghe', 1),
    ('Khoa học thông tin', 'khoa-hoc-thong-tin', 'khoa-hoc-cong-nghe', 2),
    ('Truyền thông – Xã hội học', 'truyen-thong-xa-hoi-hoc', 'khoa-hoc-cong-nghe', 3),
    ('Triết học phương Tây', 'triet-hoc-phuong-tay', 'triet-hoc-ton-giao', 1),
    ('Văn hóa học', 'van-hoa-hoc', 'triet-hoc-ton-giao', 2),
    ('Tôn giáo – Tâm linh', 'ton-giao-tam-linh', 'triet-hoc-ton-giao', 3),
    ('Công nghệ thông tin', 'cong-nghe-thong-tin', 'giao-trinh', 1),
    ('Kinh tế – Quản trị', 'kinh-te-quan-tri', 'giao-trinh', 2),
    ('Khoa học – Kỹ thuật', 'khoa-hoc-ky-thuat', 'giao-trinh', 3),
    ('Y – Dược', 'y-duoc', 'giao-trinh', 4),
    ('Luật – Hành chính', 'luat-hanh-chinh', 'giao-trinh', 5),
    ('Ngoại ngữ', 'ngoai-ngu', 'giao-trinh', 6),
    ('Trò chơi – Giải đố', 'tro-choi-giai-do', 'so-thich-giai-tri', 1),
    ('Thú cưng – Thiên nhiên', 'thu-cung-thien-nhien', 'so-thich-giai-tri', 2),
    ('Nhiếp ảnh', 'nhiep-anh', 'nghe-thuat', 1),
    ('Âm nhạc', 'am-nhac', 'nghe-thuat', 2),
    ('Hội họa – Thiết kế', 'hoi-hoa-thiet-ke', 'nghe-thuat', 3),
    ('Truyện thiếu nhi', 'truyen-thieu-nhi', 'thieu-nhi', 1),
    ('Sách tô màu – Kỹ năng cho bé', 'sach-to-mau-ky-nang-cho-be', 'thieu-nhi', 2),
    ('Từ điển – Bách khoa', 'tu-dien-bach-khoa', 'tham-khao', 1),
    ('Sách tra cứu', 'sach-tra-cuu', 'tham-khao', 2)
       ) AS v(name, slug, parent_slug, sort_order)
  JOIN categories p ON p.slug = v.parent_slug
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, sort_order = EXCLUDED.sort_order;

-- 3. Dọn thể loại cũ không còn dùng (hai lượt: con trước, cha sau).
DELETE FROM categories c
 WHERE c.slug NOT IN ('van-hoc', 'tieu-thuyet-viet-nam', 'tieu-thuyet-nuoc-ngoai', 'van-hoc-kinh-dien', 'van-hoc-duong-dai', 'trinh-tham-kinh-di', 'ky-ao-gia-tuong', 'ngon-tinh-lang-man', 'tieu-thuyet-lich-su', 'truyen-ngan', 'tho', 'lich-su-chinh-tri', 'lich-su-viet-nam', 'lich-su-the-gioi', 'chinh-tri', 'tieu-su-hoi-ky', 'hoi-ky-tu-truyen', 'chan-dung-nhan-vat', 'ky-nang-song', 'phat-trien-ban-than', 'tam-ly-hoc', 'gia-dinh-nuoi-day-con', 'am-thuc-nau-an', 'nau-an-gia-dinh', 'am-thuc-quoc-te', 'an-chay-dinh-duong', 'hai-huoc-tieu-luan', 'hai-huoc', 'tieu-luan-tuyen-tap', 'kinh-te-kinh-doanh', 'kinh-te-hoc', 'quan-tri-khoi-nghiep', 'marketing-ban-hang', 'khoa-hoc-cong-nghe', 'khoa-hoc-tu-nhien', 'khoa-hoc-thong-tin', 'truyen-thong-xa-hoi-hoc', 'triet-hoc-ton-giao', 'triet-hoc-phuong-tay', 'van-hoa-hoc', 'ton-giao-tam-linh', 'giao-trinh', 'cong-nghe-thong-tin', 'kinh-te-quan-tri', 'khoa-hoc-ky-thuat', 'y-duoc', 'luat-hanh-chinh', 'ngoai-ngu', 'so-thich-giai-tri', 'tro-choi-giai-do', 'thu-cung-thien-nhien', 'nghe-thuat', 'nhiep-anh', 'am-nhac', 'hoi-hoa-thiet-ke', 'thieu-nhi', 'truyen-thieu-nhi', 'sach-to-mau-ky-nang-cho-be', 'tham-khao', 'tu-dien-bach-khoa', 'sach-tra-cuu', 'truyen-tranh-manga', 'suc-khoe-doi-song', 'sach-hiem-sach-co')
   AND NOT EXISTS (SELECT 1 FROM books b WHERE b.category_id = c.id)
   AND NOT EXISTS (SELECT 1 FROM categories ch WHERE ch.parent_id = c.id);
DELETE FROM categories c
 WHERE c.slug NOT IN ('van-hoc', 'tieu-thuyet-viet-nam', 'tieu-thuyet-nuoc-ngoai', 'van-hoc-kinh-dien', 'van-hoc-duong-dai', 'trinh-tham-kinh-di', 'ky-ao-gia-tuong', 'ngon-tinh-lang-man', 'tieu-thuyet-lich-su', 'truyen-ngan', 'tho', 'lich-su-chinh-tri', 'lich-su-viet-nam', 'lich-su-the-gioi', 'chinh-tri', 'tieu-su-hoi-ky', 'hoi-ky-tu-truyen', 'chan-dung-nhan-vat', 'ky-nang-song', 'phat-trien-ban-than', 'tam-ly-hoc', 'gia-dinh-nuoi-day-con', 'am-thuc-nau-an', 'nau-an-gia-dinh', 'am-thuc-quoc-te', 'an-chay-dinh-duong', 'hai-huoc-tieu-luan', 'hai-huoc', 'tieu-luan-tuyen-tap', 'kinh-te-kinh-doanh', 'kinh-te-hoc', 'quan-tri-khoi-nghiep', 'marketing-ban-hang', 'khoa-hoc-cong-nghe', 'khoa-hoc-tu-nhien', 'khoa-hoc-thong-tin', 'truyen-thong-xa-hoi-hoc', 'triet-hoc-ton-giao', 'triet-hoc-phuong-tay', 'van-hoa-hoc', 'ton-giao-tam-linh', 'giao-trinh', 'cong-nghe-thong-tin', 'kinh-te-quan-tri', 'khoa-hoc-ky-thuat', 'y-duoc', 'luat-hanh-chinh', 'ngoai-ngu', 'so-thich-giai-tri', 'tro-choi-giai-do', 'thu-cung-thien-nhien', 'nghe-thuat', 'nhiep-anh', 'am-nhac', 'hoi-hoa-thiet-ke', 'thieu-nhi', 'truyen-thieu-nhi', 'sach-to-mau-ky-nang-cho-be', 'tham-khao', 'tu-dien-bach-khoa', 'sach-tra-cuu', 'truyen-tranh-manga', 'suc-khoe-doi-song', 'sach-hiem-sach-co')
   AND NOT EXISTS (SELECT 1 FROM books b WHERE b.category_id = c.id)
   AND NOT EXISTS (SELECT 1 FROM categories ch WHERE ch.parent_id = c.id);
