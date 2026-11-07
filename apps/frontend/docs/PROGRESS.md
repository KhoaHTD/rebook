# Tiến độ frontend

Cập nhật 2026-11-07. Làm trên nhánh `main`. Đặc tả: [SRS.txt](SRS.txt) + 3 sơ đồ `srs-*.png`. Quyết định ở chỗ SRS chưa nói: [DECISIONS.md](DECISIONS.md), [DECISIONS_V2.md](DECISIONS_V2.md).
Việc còn lại trước demo: [docs/CHECKLIST_CHOT_SO.md](../../../docs/CHECKLIST_CHOT_SO.md).

## Đã xong theo SRS (giai đoạn 0 đến 7)

| Nhóm | Nội dung |
|---|---|
| Nền | Client sinh từ OpenAPI, entity + mapper, `FakeStore` (chạy không cần backend), core (auth, WebSocket realtime, FCM, data_changes) |
| Giao diện | Liquid Glass, chữ hệ thống, theme sáng (khu đấu giá luôn tối), `AppPage` / `Glass` / `InfoPanel`, `BookPoster` + `DrawnCover` |
| Người mua | Đăng nhập / đăng ký / OTP / quên mật khẩu, trang chủ, tìm kiếm, chi tiết sách, giỏ nhiều shop, thanh toán (COD / ví / ZaloPay), đơn mua, hủy, trả hàng, đánh giá, ví, thông báo, sổ địa chỉ + bản đồ |
| Đấu giá | Lịch phiên, catalogue, đăng ký + cọc, phòng trực tiếp (đồng hồ server, soft close, proxy bid), kết quả, hóa đơn lô thắng; khu đấu giá riêng (khung, theme tối, `ModeSwitch`) |
| Người bán | Mở shop, đăng / sửa / ẩn sách (chụp, làm phẳng bìa), tồn kho, xử lý đơn, ký gửi + lịch hẹn, kết quả kiểm định, doanh thu, rút tiền |
| Staff | Yêu cầu ký gửi, lịch hẹn và nhận sách, kho, đối chiếu vận chuyển, sự cố và kiểm lại, giao lô đấu giá, giám sát phiên |
| Admin | Dashboard, Báo cáo (biểu đồ, xuất PDF / CSV), duyệt tin, đối soát COD, khiếu nại, rút tiền, người dùng, danh mục, phiên đấu giá, cấu hình, nhật ký |

## Đợt 2026-11-04 đến 2026-11-07

- Ghép lại với backend thật; thanh toán ZaloPay sandbox thay VNPay.
- Intro + đăng nhập mới (splash, 3 trang giới thiệu, đăng nhập dùng chung giao diện ở mọi nền tảng, nút "Bỏ qua" vào bằng tài khoản khách).
- Đăng nhập Google (luồng OAuth chạy ở server, không thêm package): xem [apps/backend/README.md](../../backend/README.md).
- Admin / Staff đổi sang giao diện mới (sidebar thẻ nổi, KPI, biểu đồ), dùng được ở điện thoại (ngăn kéo dưới 900px).
- Bản đồ địa chỉ: ô Esri làm chính (một số mạng chặn openstreetmap.org), tìm toạ độ bằng Nominatim, dự phòng Photon.
- Sửa lỗi sau test: tải ảnh lên Cloudinary (backend), bố cục điện thoại ở Đối soát COD / Giao lô đấu giá / danh sách Người dùng.

## Kiểm tra

`dart analyze --fatal-infos` + `dart run tool/arch_check.dart` + `flutter test` sạch (201 test). Dữ liệu demo và kiểm tra API: `apps/backend/scripts/reset-demo.ps1`, `apps/backend/scripts/smoke.mjs`.
