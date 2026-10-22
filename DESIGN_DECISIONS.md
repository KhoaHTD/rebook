# DESIGN_DECISIONS

Quyết định đã được người dùng xác nhận (2026-10-22).

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | Thương hiệu | **ReBook**, có thể kèm dòng phụ tiếng Việt ("Chợ sách cũ & đấu giá") |
| 2 | Theme | Nền sáng hoàn thiện cho mọi trang; chỉ 1 bản Home tối để kiểm tra bảng màu |
| 3 | Dữ liệu mẫu | Văn học Việt + sách dịch kinh điển. Ưu tiên bìa thật có nguồn; thiếu thì bìa concept, ghi rõ |
| 4 | File SRS `docs/ReBook_SRS_Ver_2.docx` | Bỏ qua, không đọc, chờ người dùng gửi SRS |
| 5 | Tham khảo | 2 ảnh Apple Books (desktop "My Books", mobile "Fiction & Literature"). Không sao chép nguyên xi |
| 6 | Trọng tâm | Sách là trung tâm; người bán là nguồn cung, không nổi bật trên Home |
| 7 | Video Pinterest (About) | Chưa nhận được link/file — About làm theo định hướng chung, ghi rõ chưa tham khảo video |
| 8 | Phong cách (2026-10-22, thay quyết định cũ) | **Bám sát Apple Books** theo 2 ảnh mẫu: nền trắng, sidebar xám nhạt trên desktop (mục chọn nền đen), tiêu đề serif đậm, lưới bìa có bóng mềm + dòng meta nhỏ (badge, giá, "···"); mobile: nút back tròn, tiêu đề giữa, kệ cuộn ngang với tiêu đề đậm "›", nền xám xen kẽ, tab bar bo tròn nổi. Hướng "contact sheet" (home.html) bị BỎ. |
| 9 | Mức độ chi tiết | Chỉ cần template sơ bộ để thấy style, không tốn công bàn thiết kế |
| 10 | Mức bám mẫu (2026-10-22) | Người dùng muốn **y chang** Apple Books: sidebar nổi bo góc, font kiểu SF (Inter), tiêu đề serif đậm (Newsreader 800), bìa có gáy sáng + bóng đổ, badge MỚI/ĐẤU GIÁ + "···", mobile: header mờ kính, kệ nền xám/trắng xen kẽ, tab bar pill mờ kính. Luật "no shadow/glass/gradient" của taste-skill KHÔNG áp dụng cho dự án này. |
| 11 | Template sơ bộ style Apple Books (2026-10-22) | `design-preview/png/apple-desktop.png` (sidebar + lưới **4 poster lớn/hàng**), `design-preview/png/apple-mobile.png` (kệ ngang, poster lớn, tab bar nổi). Nguồn vẽ: `design-preview/apple-style/`. Bản 6 poster/hàng của phiên trước (`ab-desktop.html`, `png/desktop-home.jpg`) giữ lại để so sánh |
| 12 | **ĐÃ DUYỆT (2026-10-22)** | Người dùng duyệt style Apple Books theo `design-preview/png/apple-desktop.png` (4 poster lớn/hàng) + `design-preview/png/apple-mobile.png`. Đây là chuẩn giao diện khi triển khai sau này. Giai đoạn thiết kế xong, chờ SRS |

## Triển khai theo SRS (2026-10-22)

SRS: `D:\Study\FPTUniversity\Semester8\PRM393\Đặc-tả-ứng-dụng-mua-bán-đấu-giá-sách-cũ.docx` (người dùng gửi, @Khoa, 21/10/2026).

| # | Chủ đề | Quyết định của người dùng |
|---|---|---|
| S1 | Tái dụng nhánh backup `feat/srs-frontend` | Lấy logic (OpenAPI, entity, FakeStore, provider, test), **vẽ lại toàn bộ UI** theo style Apple Books đã duyệt |
| S2 | Package mới | Duyệt cả 5: stomp_dart_client, image_picker, url_launcher, firebase_core, firebase_messaging (lấy lại allowlist đã duyệt từ backup) |
| S3 | Nền tảng | App người mua/bán chạy mobile + web (web dùng bố cục sidebar 4 poster/hàng); web quản trị Staff/Admin là entrypoint riêng, cùng style |
| S4 | Cách chạy | Trình kế hoạch 1 lần → tự làm theo giai đoạn, mỗi giai đoạn analyze + test + commit local, ghi tiến độ; không push khi chưa được bảo |
| S5 | Giao diện | Giao diện Apple Books hiện tại là **khung**; người dùng sẽ thêm thắt sau. Mọi màn mới tuân theo style này |
