# Tiến độ triển khai frontend theo SRS

Nhánh `design/apple-books` (commit local, **không push**). SRS: `docs/SRS.txt` + `docs/srs-*.png`.
Quyết định tự đưa ra: `docs/DECISIONS.md`. Giao diện chuẩn: `../../design-preview/png/apple-desktop.png`, `apple-mobile.png`.
Logic lấy từ tag `backup/srs-frontend-2026-10-22`; UI làm mới theo style Apple Books.

## Khi bị ngắt

1. `git switch design/apple-books` trong `D:\Study\FPTUniversity\Semester8\PRM393\rebook`.
2. Đọc file này, làm tiếp mục `[ ]` đầu tiên. Đọc `CLAUDE.md` + `docs/ARCHITECTURE.md` trước khi code.
3. Xong mỗi mục: `dart analyze --fatal-infos && dart run tool/arch_check.dart && flutter test` → commit → đánh `[x]`.

## Giai đoạn 0 — Chuẩn bị
- [x] SRS (`docs/SRS.txt`, 3 sơ đồ), `docs/DECISIONS.md` từ backup
- [x] Allowlist + 5 package đã duyệt: stomp_dart_client, image_picker, url_launcher, firebase_core, firebase_messaging
- [x] Font Newsreader (500–800) + Be Vietnam Pro (400–800) trong `assets/fonts`, khai báo pubspec
- [x] Luật mới trong CLAUDE.md (Firebase chỉ cho FCM, style Apple Books)

## Giai đoạn 1 — Tầng dữ liệu (từ backup)
- [x] `openapi/openapi.yaml` đầy đủ + sinh client
- [x] Entity `shared/domain`, mapper `shared/data/api_mappers.dart`, `FakeStore` + bộ máy phiên giả lập
- [x] Core: data_changes, realtime STOMP, notifications (FCM), auth/session, settings (mặc định theme sáng)
- [x] Repository + provider của từng feature (không lấy màn hình), 43 test logic pass
- Ghi chú: `app_router.dart` đang là router TẠM (1 trang chờ); `ErrorView` tối giản; `status_labels` cũ đã bỏ (làm lại ở GĐ2).
  Bảng đường dẫn đầy đủ: `lib/app/router/routes.dart` (từ backup).

## Giai đoạn 2 — Bộ giao diện Apple Books + khung app
- [x] Theme sáng/tối (`app/theme`), token `AppColors`, `CoverPalette`; mặc định nền sáng + tiếng Việt
- [x] Widget: `book_poster.dart` (BookPoster gáy + bóng, DrawnCover), `poster_grid.dart` (PosterTile, PosterGrid 4/3/2 cột, Shelf),
      `ui.dart` (AppPage, CircleBackButton, DotsButton, SectionHeader, PillBadge, PriceText, EmptyState, InfoPanel), `status_labels.dart`
- [x] AppShell: sidebar nổi (`sidebar.dart` dùng chung) · tab bar viên thuốc nổi; router đủ cây SRS, màn chưa làm = `PlaceholderPage`
- [x] Hai entrypoint: `main.dart` (người dùng), `main_admin.dart` (Staff/Admin, `admin_router` + `admin_shell`)
- Xem trước: `flutter build web --release --dart-define-from-file=env/dev.json` rồi phục vụ `build/web` (SPA).

## Giai đoạn 3 — Người mua
- [ ] Đăng nhập / đăng ký / OTP / quên mật khẩu
- [ ] Trang chủ, tìm kiếm + lọc + sắp xếp, chi tiết sách (nhiều bản / nhiều người bán), trang shop
- [ ] Giỏ nhiều shop, checkout (COD / ví / VNPay), đơn của tôi, chi tiết + lịch sử trạng thái, hủy, đã nhận, đánh giá, trả hàng
- [ ] Ví (số dư, nạp, lịch sử), thông báo, hồ sơ, sổ địa chỉ, cài đặt

## Giai đoạn 4 — Đấu giá
- [ ] Lịch phiên, catalogue, chi tiết lô (báo cáo tình trạng), theo dõi lô
- [ ] Đăng ký + đặt cọc (hạn mức = cọc × 10), số bài
- [ ] Phòng trực tiếp: đồng hồ server, soft close, "Lần thứ nhất / thứ hai / Bán!", nút "Trả Xđ", proxy bid
- [ ] Kết quả phiên, hóa đơn lô thắng (đơn AUCTION)

## Giai đoạn 5 — Người bán
- [ ] Bật shop, đăng / sửa / ẩn sách, quản lý tin, tồn kho
- [ ] Đơn của shop: xác nhận, chuẩn bị, giao, hủy
- [ ] Ký gửi + đặt lịch, kết quả kiểm định, quyết định giá, kết quả phiên, doanh thu / rút tiền

## Giai đoạn 6 — Web quản trị (Flutter Web)
- [ ] Staff: lịch hẹn, nhận sách, phiếu kiểm định, kho, giám sát phiên
- [ ] Admin: duyệt tin, khóa tài khoản, danh mục, tạo phiên + xếp lô, cấu hình phí, khiếu nại, dashboard

## Giai đoạn 7 — Hoàn thiện
- [ ] analyze + arch_check + test sạch, build web 2 app, chụp màn hình so mockup, cập nhật README/ARCHITECTURE
