> **TRẠNG THÁI HIỆN TẠI (2026-10-22): ĐANG TRIỂN KHAI frontend theo SRS** (người dùng đã duyệt kế hoạch 8 giai đoạn, giao phó làm hết).
> Tiến độ chi tiết + bước tiếp theo: `apps/frontend/docs/PROGRESS.md` (làm mục `[ ]` đầu tiên). Nhánh `design/apple-books`, không push.

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
