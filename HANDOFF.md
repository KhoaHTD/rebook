> **TRẠNG THÁI HIỆN TẠI (2026-10-22): ĐÃ TRIỂN KHAI XONG frontend theo SRS** — 8 giai đoạn trong `apps/frontend/docs/PROGRESS.md` đều `[x]`.
> Nhánh `design/liquid-glass-ui`, commit local, **chưa push**. Phần bên dưới là lịch sử giai đoạn thiết kế, giữ để tham khảo.
> Việc còn mở: backend thật (spec `apps/frontend/openapi/openapi.yaml`), các ghi chú "Nên thêm … vào openapi.yaml" trong `apps/frontend/docs/DECISIONS.md`, site Firebase thứ hai cho web quản trị.


# HANDOFF

Giai đoạn THIẾT KẾ, chưa code website. Nhánh `design/liquid-glass-ui` (chưa push). Không reset Git.

## Hiện trạng (2026-10-22)

- Người dùng chốt: làm **giống Apple Books** (2 ảnh mẫu), chỉ template sơ bộ, không bàn thiết kế dài.
- Template đã làm: `design-preview/ab-desktop.html` (sidebar + lưới bìa: Tuyển chọn, Đấu giá sắp kết thúc),
  `design-preview/ab-mobile.html` (trang thể loại: kệ cuộn ngang + tab bar). Ảnh: `design-preview/png/`.
- `design-preview/home.html` = hướng cũ "contact sheet", đã bị người dùng loại — giữ để tham khảo, không phát triển tiếp.
- Bìa: thật (Open Library) + tư liệu (Commons), nguồn trong các `credits.json`; bìa "concept" do `covers.js` vẽ.

## Bước tiếp theo

Chờ người dùng duyệt 2 template. Nếu cần thêm: trang chi tiết sách (nhiều bản / nhiều người bán) cùng style.
Sau khi duyệt: chờ SRS. Chỉ code khi có SRS + yêu cầu triển khai.
