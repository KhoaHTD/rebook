-- Ảnh bìa 24 sách hiếm là ảnh chụp / scan nguyên khổ (còn viền trắng, nền xám, bóng đổ). Cloudinary tự cắt phần nền đồng màu
-- quanh cuốn sách khi giao ảnh (e_trim, dung sai 40) nên không phải tải lại ảnh gốc. Chạy lại nhiều lần không sao.
UPDATE book_images
   SET url = replace(url, '/image/upload/', '/image/upload/e_trim:40/')
 WHERE url LIKE '%/image/upload/%/rebook/covers/rare-%'
   AND url NOT LIKE '%e_trim%';
