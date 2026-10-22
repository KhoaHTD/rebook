# HANDOFF

Khi người dùng gõ `TIẾP TỤC` / `RESUME`:

1. Đọc `PROJECT_STATE.md`, `DESIGN_DECISIONS.md` (nếu có), file này.
2. Kiểm tra `git status`, nhánh phải là `design/apple-books`; kiểm tra `design-preview/` thực tế.
3. Tiếp tục từ mục "Bước tiếp theo". Không reset code, không hỏi lại câu đã trả lời.

## Bước tiếp theo

Đang chờ người dùng trả lời bộ câu hỏi thiết kế (thương hiệu, theme, dữ liệu mẫu, định dạng mockup,
video Pinterest, file SRS trong docs/). Khi có câu trả lời:

1. Ghi câu trả lời vào `DESIGN_DECISIONS.md`.
2. Load skill `taste-skill:design-taste-frontend` (+ `frontend-design`), lập design language.
3. Làm Home desktop + mobile trước trong `design-preview/` (HTML/CSS tĩnh, xuất PNG bằng playwright-cli),
   rồi tới Khám phá, Chi tiết sách, About.
4. Cập nhật file trạng thái sau mỗi nhóm mockup. Dừng ở bước duyệt, chờ SRS.
