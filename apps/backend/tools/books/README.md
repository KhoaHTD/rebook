# Dữ liệu sách mẫu từ Excel

`books.xlsx` là nguồn sách mẫu: 70 sách tiếng Anh (thông tin nhà xuất bản, tình trạng và khối lượng giả lập, **70 ảnh bìa nhúng
ở sheet "Ảnh bìa"**). Các script ở đây chỉ dùng Node, không cần cài thư viện.

| Script | Làm gì |
|---|---|
| `upload-covers.mjs` | Lấy ảnh nhúng trong Excel, upload lên Cloudinary (`rebook/covers/<isbn13>`), ghi URL vào `covers.json` |
| `gen.mjs` | Đọc Excel + `covers.json`, sinh migration thể loại, seed sách, và `REPORT.md` |
| `xlsx.mjs` | Bộ đọc xlsx dùng chung |

```bash
cd apps/backend
node tools/books/upload-covers.mjs   # chỉ cần khi có sách / ảnh mới (cần CLOUDINARY_URL, xem .env.example)
node tools/books/gen.mjs
```

| File sinh ra | Chạy khi nào | Nội dung |
|---|---|---|
| `src/main/resources/db/migration/V19__category_tree.sql` | mọi môi trường | cây thể loại hai cấp |
| `src/main/resources/db/seed/V20_1__seed_books_from_sheet.sql` | chỉ profile dev | xoá dữ liệu nghiệp vụ cũ, nạp sách + tin đăng + ảnh bìa, đặt lại ví mẫu |
| `tools/books/REPORT.md` | để duyệt | thể loại, shop, tình trạng, khối lượng, giá, tồn kho của từng sách |

Kết quả luôn giống nhau (giá và tồn kho tính theo ISBN, không dùng số ngẫu nhiên), nên máy nào tạo DB mới cũng ra cùng dữ liệu.
Các file `V19*.sql` được **sinh ra**, đừng sửa tay: sửa Excel hoặc các bảng ở đầu `gen.mjs` (`TREE`, `CATEGORY_BY_STT`,
`PRICE_RANGE`, ...) rồi chạy lại. DB đã chạy bản cũ của V19 thì tạo lại DB (Flyway kiểm tra checksum).

## Sách hiếm để đấu giá (rare.xlsx)

`rare.xlsx` có 24 sách hiếm / ấn bản đầu (1866 – 1962), không ISBN, ảnh bìa mặt trước nhúng ở sheet thứ hai. Seed nạp chúng thành **bản ghi sách
(thể loại "Sách hiếm – Sách cổ") kèm ảnh bìa, không có tin đăng bán thường**; ký gửi, kiểm định, lô và phiên đấu giá do script demo tạo sau.
Ảnh có khoá `rare-NN` trong `covers.json`. `upload-covers.mjs` dùng ảnh nhúng trước; nếu ảnh hỏng hoặc quá 10 MB thì thử lần lượt các cột link
("Link ảnh bìa gốc", "Nguồn ảnh và ấn bản", "Nguồn đối chiếu số trang"; cột nào tải về không phải ảnh thì bỏ qua). Ảnh gốc quá lớn mà link cũng
trỏ cùng ảnh đó (như Gatsby, 16 MB) thì thu nhỏ tay rồi `--only rare-01 --file <ảnh>`.
Tình trạng ghi `GOOD` (chưa kiểm định); khối lượng **ước tính** 160 g + 1,1 g/trang vì sheet ghi "chưa xác minh".

## Quy tắc đã dùng

- **ISBN**: lưu 13 chữ số, không gạch (script từ chối ISBN sai chữ số kiểm tra).
- **Tình trạng**: Mới, chưa sử dụng → `NEW`; Như mới → `LIKE_NEW`; Đã đọc, còn tốt → `VERY_GOOD`; Đã đọc, gáy hơi nhăn và
  Đã qua sử dụng, góc bìa hơi mòn → `GOOD`.
- **Khối lượng**: lấy từ sheet (giả lập theo số trang và loại bìa).
- **Shop**: tiểu thuyết ("Văn học") → "Nhà Sách Cũ Sài Gòn"; còn lại → "Tiệm Sách Hà Nội Xưa".
- **Giá**: 120.000 – 450.000 đồng, tình trạng tốt, nhiều trang, bìa cứng thì đắt hơn; làm tròn 1.000. **Tồn kho** 3 – 5 cuốn.
- **Thể loại**: mỗi sách một thể loại con chọn tay trong `CATEGORY_BY_STT` (sheet ghi nhiều nhãn gạch chéo).
- **Ví**: ba người mua được nạp lại 5.000.000 / 5.000.000 / 3.000.000 đồng, sổ cái khớp số dư.
- Seed xoá sạch sách, tin đăng, ký gửi, lô, phiên đấu giá, đơn hàng, thanh toán, sổ cái ví, thông báo, nhật ký; giữ tài khoản, shop,
  địa chỉ, cấu hình hệ thống.

## Ảnh bìa

Mỗi sách có đúng một dòng `book_images` (`SELLER`, thứ tự 0) trỏ tới URL Cloudinary trong `covers.json`; không file ảnh nào nằm trong
database hay repo (ảnh gốc chỉ nằm trong `books.xlsx`). Muốn đổi ảnh: sửa ảnh trong Excel, chạy `upload-covers.mjs --force`, rồi `gen.mjs`.
