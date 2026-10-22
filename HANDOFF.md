> **TRẠNG THÁI HIỆN TẠI (2026-10-22): STYLE ĐÃ DUYỆT — ĐANG CHỜ SRS.**
> Chuẩn giao diện: `design-preview/png/apple-desktop.png` + `design-preview/png/apple-mobile.png` (nguồn vẽ `design-preview/apple-style/`).
> Không làm gì thêm cho tới khi người dùng gửi SRS và yêu cầu triển khai. Khi có SRS: đọc SRS, phân tích nghiệp vụ,
> lập kế hoạch triển khai trên code nền tảng `3326d28` (nhánh `design/apple-books`), trình kế hoạch trước khi code.
> Duyệt mockup KHÔNG phải là cho phép code. Không reset Git, không đụng tag `backup/*`.

# HANDOFF

Giai đoạn THIẾT KẾ, chưa code website. Nhánh `design/apple-books` (chưa push). Không reset Git.

## Hiện trạng (2026-10-22)

- Người dùng chốt: làm **giống Apple Books** (2 ảnh mẫu), chỉ template sơ bộ, không bàn thiết kế dài.
- Template đã làm: `design-preview/ab-desktop.html` (sidebar + lưới bìa: Tuyển chọn, Đấu giá sắp kết thúc),
  `design-preview/ab-mobile.html` (trang thể loại: kệ cuộn ngang + tab bar). Ảnh: `design-preview/png/`.
- `design-preview/home.html` = hướng cũ "contact sheet", đã bị người dùng loại — giữ để tham khảo, không phát triển tiếp.
- Bìa: thật (Open Library) + tư liệu (Commons), nguồn trong các `credits.json`; bìa "concept" do `covers.js` vẽ.

## Bước tiếp theo

Chờ người dùng duyệt 2 template. Nếu cần thêm: trang chi tiết sách (nhiều bản / nhiều người bán) cùng style.
Sau khi duyệt: chờ SRS. Chỉ code khi có SRS + yêu cầu triển khai.
