-- Bổ sung đủ các thể loại sách. Thể loại chia hai cấp: nhóm cha và thể loại con (xem CategoryService).
-- Thể loại đã có giữ nguyên id (sách đang dùng); thể loại chưa có thì thêm. Chạy lại không trùng nhờ slug duy nhất.

-- 1. Nhóm cha (đã có thì bỏ qua).
INSERT INTO categories (name, slug, parent_id, sort_order) VALUES
    ('Văn học',                    'van-hoc',            NULL, 1),
    ('Giáo trình',                 'giao-trinh',         NULL, 2),
    ('Kỹ năng sống',               'ky-nang-song',       NULL, 3),
    ('Lịch sử – Khoa học xã hội',  'lich-su-khxh',       NULL, 4),
    ('Thiếu nhi',                  'thieu-nhi',          NULL, 5),
    ('Sách hiếm – Sách cổ',        'sach-hiem-sach-co',  NULL, 6),
    ('Truyện tranh – Manga',       'truyen-tranh',       NULL, 7),
    ('Tôn giáo – Triết học',       'ton-giao-triet-hoc', NULL, 8),
    ('Nghệ thuật – Âm nhạc',       'nghe-thuat-am-nhac', NULL, 9),
    ('Sức khỏe – Đời sống',        'suc-khoe-doi-song',  NULL, 10)
ON CONFLICT (slug) DO NOTHING;

-- 2. Thể loại con của "Văn học".
INSERT INTO categories (name, slug, parent_id, sort_order)
SELECT v.name, v.slug, p.id, v.sort_order
  FROM categories p,
       (VALUES ('Tiểu thuyết Việt Nam',     'tieu-thuyet-viet-nam', 1),
               ('Văn học nước ngoài',       'van-hoc-nuoc-ngoai',   2),
               ('Truyện ngắn – Tản văn',    'truyen-ngan-tan-van',  3),
               ('Thơ',                      'tho',                  4),
               ('Trinh thám – Kinh dị',     'trinh-tham-kinh-di',   5),
               ('Ngôn tình – Lãng mạn',     'ngon-tinh-lang-man',   6)) AS v(name, slug, sort_order)
 WHERE p.slug = 'van-hoc'
ON CONFLICT (slug) DO NOTHING;

-- 3. Thể loại con của "Giáo trình".
INSERT INTO categories (name, slug, parent_id, sort_order)
SELECT v.name, v.slug, p.id, v.sort_order
  FROM categories p,
       (VALUES ('Công nghệ thông tin',      'cong-nghe-thong-tin',  1),
               ('Kinh tế',                  'kinh-te',              2),
               ('Khoa học – Kỹ thuật',      'khoa-hoc-ky-thuat',    3),
               ('Y – Dược',                 'y-duoc',               4),
               ('Luật – Hành chính',        'luat-hanh-chinh',      5),
               ('Ngoại ngữ',                'ngoai-ngu',            6)) AS v(name, slug, sort_order)
 WHERE p.slug = 'giao-trinh'
ON CONFLICT (slug) DO NOTHING;
