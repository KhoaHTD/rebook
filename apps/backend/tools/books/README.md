# Dữ liệu sách mẫu từ Excel

`books.xlsx` là nguồn sách mẫu (66 dòng). Script `gen.mjs` đọc file này (Node, không cần cài thư viện) và ghi:

| File sinh ra | Chạy khi nào | Nội dung |
|---|---|---|
| `src/main/resources/db/migration/V19__category_tree.sql` | mọi môi trường | cây thể loại hai cấp (14 nhóm cha, 38 thể loại con) |
| `src/main/resources/db/seed/V19_1__seed_books_from_sheet.sql` | chỉ profile dev | xoá dữ liệu nghiệp vụ cũ, nạp sách + tin đăng, đặt lại ví mẫu |
| `tools/books/REPORT.md` | để duyệt | ISBN cũ → mới, sửa chính tả, thể loại, shop, giá, tồn kho từng sách |

```bash
cd apps/backend
node tools/books/gen.mjs
```

Kết quả luôn giống nhau (giá và tồn kho tính theo ISBN, không dùng số ngẫu nhiên), nên máy nào tạo DB mới cũng ra cùng dữ liệu.
Các file `V19*.sql` được **sinh ra**, đừng sửa tay: sửa Excel hoặc các bảng ở đầu `gen.mjs` (`TREE`, `CORRECTIONS`,
`CATEGORY_OVERRIDES`, `PRICE_RANGE`, ...) rồi chạy lại. DB đã chạy bản cũ của V19 thì tạo lại DB (Flyway kiểm tra checksum).

## Quy tắc đã dùng

- **ISBN**: lưu 13 chữ số, không gạch. 35/66 ISBN trong sheet sai chữ số kiểm tra nên chữ số cuối được tính lại.
- **Tình trạng**: Mới → `NEW`, Như mới → `LIKE_NEW`, Tốt → `VERY_GOOD`, Khá → `GOOD`.
- **Shop theo ngôn ngữ**: sách tiếng Việt → "Tiệm Sách Hà Nội Xưa" (shop 2), sách tiếng Anh → "Nhà Sách Cũ Sài Gòn" (shop 1).
- **Giá**: tiếng Việt 30.000 – 150.000, tiếng Anh 80.000 – 400.000 đồng; tình trạng tốt, nhiều trang thì đắt hơn; sách xuất bản
  trước 1950 cộng 50%; làm tròn 1.000 đồng. **Tồn kho** 3 – 5 cuốn.
- **Thể loại**: tiểu thuyết tách theo ngôn ngữ (Việt Nam / nước ngoài); các giá trị gần nhau gộp (xem `categoryOf` trong `gen.mjs`).
- **Ví**: ba người mua được nạp lại 5.000.000 / 5.000.000 / 3.000.000 đồng, sổ cái khớp số dư.
- Seed xoá sạch sách, tin đăng, ký gửi, lô, phiên đấu giá, đơn hàng, thanh toán, sổ cái ví, thông báo, nhật ký; giữ tài khoản, shop,
  địa chỉ, cấu hình hệ thống.

## Ảnh bìa

Seed **không** ghi ảnh nào (`book_images` trống). Ảnh được thêm như mọi sách khác: upload qua `POST /files` (lưu trên
Cloudinary khi có biến môi trường `CLOUDINARY_URL`, xem README backend) rồi gắn URL vào sách. Sách chưa có ảnh hiện ảnh trống.
