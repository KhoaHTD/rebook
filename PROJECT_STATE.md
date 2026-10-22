# PROJECT_STATE

Cập nhật: 2026-10-22 — style Apple Books ĐÃ DUYỆT, đang chờ SRS

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

## Cập nhật 2026-10-22 (sau khi người dùng trả lời)

- [x] Ghi quyết định vào `DESIGN_DECISIONS.md`.
- [x] taste-skill: hướng **The contact sheet** (seed 1431430296), palette "Three stones". Đổi font (Archivo → Newsreader +
      Be Vietnam Pro, lý do: văn học + dấu tiếng Việt). Bỏ lớp animation (người dùng cấm animation trang trí).
- [x] Ảnh: 12 bìa thật Open Library (`design-preview/assets/covers/`, nguồn trong `credits.json`), 6 ảnh tư liệu
      Wikimedia Commons PD/CC (`design-preview/assets/`, nguồn trong `assets/credits.json`).
- [x] `design-preview/styles.css` (token + component dùng chung), `design-preview/covers.js` (10 bìa concept có nhãn).
- [~] `design-preview/home.html` — Home responsive (desktop 1440 + mobile 390 cùng một file). Đã qua 4 vòng inspector + xem ảnh.
      Inspector lần cuối: 2 FAIL, 5 WARN.
      * FAIL still-page (không animation) — CỐ Ý, theo yêu cầu người dùng cấm animation trang trí.
      * FAIL eyebrow @768px: ô tìm kiếm trên thanh nav bị đo nhầm là nhãn trên tiêu đề → CHƯA SỬA (ở 768 nav xuống dòng?).
      * WARN giữ có lý do: no-footage, font-not-dealt (đổi font có chủ đích), side-scroll (dải bìa kéo ngang),
        size-count (chữ trong bìa concept), measure 112 ký tự (do thanh ghi chú mockup).
      * Vừa sửa nhưng CHƯA xem lại ảnh: khối 3 ý dưới tiêu đề hero, hàng đấu giá trên điện thoại, nhãn concept chuyển xuống đáy bìa.
- [ ] Chưa làm: explore.html, book.html (chi tiết sách + nhiều người bán), about.html, home-dark (data-theme="dark"),
      index.html (mục lục mockup), credits.html, xuất PNG vào design-preview/png/.

## Cập nhật 2026-10-22 (đổi hướng)

- Người dùng không thích hướng "contact sheet"; yêu cầu làm giống Apple Books, template sơ bộ.
- [x] `design-preview/ab-desktop.html`, `design-preview/ab-mobile.html` + ảnh `design-preview/png/`.
- [ ] Chờ người dùng duyệt. Sau đó chờ SRS.
- [x] Làm lại 2 template sát Apple Books hơn (theo yêu cầu "y chang"), ảnh mới trong `design-preview/png/`. Chờ duyệt.

## Cập nhật 2026-10-22 (duyệt)

- [x] Người dùng duyệt style Apple Books (`design-preview/png/apple-desktop.png`, `apple-mobile.png`).
- [ ] **Chờ SRS.** Chưa code website.
