# PROJECT_STATE

Cập nhật: 2026-10-22

## Giai đoạn hiện tại: THIẾT KẾ (chưa code website)

Chỉ nghiên cứu + tạo mockup trong `design-preview/`. Không sửa code ứng dụng, không làm API/DB/nghiệp vụ.
Chỉ chuyển sang code khi người dùng gửi SRS **và** yêu cầu triển khai. Duyệt mockup ≠ cho phép code.

## Git

- Nhánh làm việc: `design/apple-books` (tạo từ `3326d28`, chưa push).
- `main` = `origin/main` = `3326d28` (không đổi).
- Code phát triển cũ (SRS frontend, 12 commit, chưa từng push) giữ nguyên trên nhánh local `feat/srs-frontend`
  + tag `backup/srs-frontend-2026-10-22` (= `77ccf9c`).
- Stash "giao diện paper" giữ nguyên (`stash@{0}`) + tag `backup/paper-ui-stash-2026-10-22` (= `71f3f5f`).
- Không reset lại trong các phiên sau trừ khi có yêu cầu mới.

## Đã làm

- [x] Khôi phục code về `3326d28` (nhánh mới, không viết lại lịch sử remote). Xác minh: build_runner OK,
      `dart analyze` sạch, arch_check OK, 9/9 test pass.
- [x] Dọn 131 file sinh tự động cũ bị ignore trong `lib/` (tạo lại được từ tag backup).
- [x] Kiểm tra công cụ: taste-skill:design-taste-frontend, frontend-design, playwright-cli, trình duyệt tích hợp.
- [x] Xem 2 ảnh Apple Books (desktop "My Books", mobile "Fiction & Literature").
- [ ] Hỏi người dùng câu hỏi thiết kế — **đang chờ trả lời**.

## Chưa làm

1. Home desktop
2. Home mobile
3. Trang khám phá / danh mục
4. Trang chi tiết sách (nhiều lựa chọn mua từ nhiều người bán)
5. About

## Trở ngại

- Video Pinterest cho trang About: chưa nhận được link/file trong phiên này.
- `docs/ReBook_SRS_Ver_2.docx` có trong repo; người dùng nói chưa cung cấp SRS → chưa đọc, chờ xác nhận.
