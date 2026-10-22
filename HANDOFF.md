# HANDOFF

Trạng thái: **TẠM DỪNG** (2026-10-22) giữa lúc hoàn thiện Home. Đang ở giai đoạn THIẾT KẾ, chưa code website.

Khi người dùng gõ `TIẾP TỤC` / `RESUME`:

1. Đọc `PROJECT_STATE.md`, `DESIGN_DECISIONS.md`, file này. Không hỏi lại câu đã trả lời.
2. `git status`: nhánh phải là `design/apple-books`. Không reset Git.
3. Kiểm tra `design-preview/` thực tế (home.html, styles.css, covers.js, assets/).

## Bước tiếp theo chính xác

1. Chạy lại inspector cho Home:
   `node C:/Users/Lenovo/.claude/plugins/cache/taste-skill/taste-skill/2.1.4/skills/taste-skill/scripts/inspect.mjs design-preview/home.html`
   (chạy từ gốc repo; ảnh ở `.taste-skill/inspect/`). Sửa FAIL `eyebrow` @768px (nav: ô tìm kiếm bị coi là nhãn trên h1),
   xem lại ảnh desktop-fold, desktop-page-01, mobile-page-01.
2. Làm `explore.html` (kệ theo thể loại kiểu Apple Books "Fiction & Literature" + bộ lọc hình thức/tình trạng/giá).
3. Làm `book.html`: tác phẩm "Trăm năm cô đơn" → các ấn bản → danh sách bản đang bán từ nhiều người bán (+1 phiên đấu giá);
   "live thing": chọn một bản để xem ảnh/ghi chú của bản đó.
4. Làm `about.html` (chưa có video Pinterest — ghi rõ), bản Home tối, `index.html`, `credits.html`.
5. Xuất PNG bằng Edge headless:
   `"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless=new --hide-scrollbars --window-size=1440,900 --screenshot=<out.png> file:///.../design-preview/<page>.html`
   (dùng `--window-size=390,844` cho điện thoại; ảnh full page lấy từ inspector).
6. Cập nhật file trạng thái, commit (không Co-Authored-By), trình bày cho người dùng, chờ duyệt rồi chờ SRS.

## Ghi chú kỹ thuật

- Hướng thiết kế: taste-skill "The contact sheet", seed 1431430296 (`.taste-skill/direction.json`).
  Đã đổi font → Newsreader + Be Vietnam Pro; bỏ animation; ảnh = bìa thật + tư liệu thay bộ ảnh cây cỏ.
- Nguồn ảnh: `design-preview/assets/credits.json` (Commons), `design-preview/assets/covers/credits.json` (Open Library;
  còn ghi 2 bìa đã xoá: hoang-tu-be, nguoi-xa-la — cần dọn khi làm credits.html).
