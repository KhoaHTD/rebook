# Các quyết định tự đưa ra khi làm theo SRS

> **2026-10-22 — làm lại UI theo style Apple Books.** File này lấy từ tag `backup/srs-frontend-2026-10-22`; các mục về nghiệp vụ
> vẫn giữ. Các mục về giao diện cũ (kính, theme tối tự động trên mobile, trang giới thiệu web) **không còn áp dụng**:
> giao diện chuẩn là `design-preview/png/apple-desktop.png` + `apple-mobile.png`, nền sáng, web mở thẳng trang chủ.
> Nhánh làm việc hiện tại: `design/apple-books` (không phải `feat/srs-frontend`).

Chủ dự án duyệt lại vào buổi sáng. Mỗi mục: quyết định, lý do, cách đổi nếu không đồng ý.

## Đã chốt cùng chủ dự án (2026-10-22)

- Web quản trị Staff/Admin nằm cùng project, entrypoint riêng `lib/main_admin.dart`.
- App người mua/bán chạy cả web lẫn mobile; bản web mở đầu bằng trang giới thiệu.
- Thêm package: stomp_dart_client, image_picker, url_launcher, firebase_core, firebase_messaging.
- Frontend viết hợp đồng OpenAPI từ SRS; backend Spring Boot bám theo.
- Chỉ làm frontend, dữ liệu giả (`USE_MOCK=true`); commit trên nhánh `feat/srs-frontend`, không push.

## Tự quyết

<!-- Thêm mục mới bên dưới theo dạng: ### Tiêu đề / Quyết định / Lý do / Đổi thế nào -->

### Theme "tự động"
- Quyết định: mặc định `ThemePref.auto` — cửa sổ hẹp (điện thoại) dùng theme tối, web rộng dùng theme sáng. Người dùng đổi được trong Cài đặt (Tự động / Theo hệ thống / Sáng / Tối).
- Lý do: mockup đã chốt web sáng, mobile tối.
- Đổi thế nào: `AppSettings.themeModeFor` trong `core/settings/app_settings_controller.dart`.

### Cài đặt chưa lưu bền
- Quyết định: theme / ngôn ngữ giữ trong bộ nhớ (mất khi mở lại app).
- Lý do: allowlist không có shared_preferences; secure storage chỉ dành cho token.
- Đổi thế nào: khi team duyệt shared_preferences, lưu trong `AppSettingsController`.

### Backend giả (FakeStore)
- Quyết định: một backend thu nhỏ trong `shared/data/fake/` cài đúng nghiệp vụ SRS (escrow, sổ cái ví, bước giá, soft close, ký gửi → kiểm định → lô). Mọi `Fake...Repository` gọi vào đây qua `fakeCall` (trễ ~220ms, lỗi thành AppException).
- Lý do: feature không được import nhau, nhưng dữ liệu giữa chúng phải nhất quán (đặt hàng xong thì ví, đơn của shop, thông báo cùng đổi).
- Tài khoản mẫu: mật khẩu và OTP đều là 123456 (xem đầu `fake_store.dart`).

### Mapper DTO tập trung
- Quyết định: mọi chuyển đổi DTO ↔ entity nằm ở `shared/data/api_mappers.dart` thay vì mỗi feature một file.
- Lý do: entity dùng chung nhiều feature; backend đổi tên trường chỉ sửa một chỗ.

### Đường dẫn và điều hướng
- Quyết định: app người dùng có 4 nhánh (Khám phá / Đấu giá / Thông báo / Tài khoản). Giỏ hàng, chi tiết sách, shop nằm trong nhánh Khám phá; kênh người bán và ký gửi nằm trong nhánh Tài khoản. Web: `/` là trang giới thiệu; mobile mở thẳng `/home`.
- Web quản trị dùng router riêng (`app/router/admin_router.dart`), tài khoản USER đăng nhập vào sẽ bị đăng xuất và báo không có quyền.

### Không tự mua sách của shop mình
- Quyết định: thêm giỏ sách của chính shop mình trả lỗi `OWN_LISTING` (409); đã ghi vào mô tả mã lỗi trong openapi.yaml.
- Lý do: SRS không nói rõ, nhưng tự mua sẽ tạo đơn giả và tiền đi vòng trong ví.

### Thanh toán VNPay ở chế độ mock
- Quyết định: `paymentUrl` bắt đầu bằng `mock://` → app mở màn "Thanh toán" có cổng VNPay giả lập (Giao dịch thành công / thất bại). Chế độ thật: mở URL VNPay trong cùng tab, VNPay quay về `/home/payments/{id}` (cấu hình PAYMENT_RETURN_URL ở backend), app đọc lại trạng thái bằng GET /payments/{id}.

### Đồng bộ dữ liệu giữa các feature
- Quyết định: `core/utils/data_changes.dart` — bộ đếm phiên bản theo vùng (cart, orders, wallet...). Provider đọc dữ liệu gọi `ref.watchArea(DataArea.x)`; thao tác ghi gọi `bump`. Ở chế độ mock, FakeStore tự phát sự kiện đổi dữ liệu (kể cả từ bộ máy đấu giá).
- Lý do: feature không import nhau nhưng thêm giỏ ở trang sách phải cập nhật số trên icon giỏ.

### Preview web chạy bản release
- Quyết định: `.claude/launch.json` chạy `flutter run -d web-server --release`: bản debug của web-server hay rớt kết nối dwds và trang trắng.

### Phòng đấu giá
- Quyết định: phòng LIVE là route phủ toàn màn hình (không dock/sidebar). Trạng thái = ảnh chụp GET /sessions/{id}/state + sự kiện STOMP áp qua `applyAuctionEvent` (features/auction/domain/live_reducer.dart, có test). Kết nối lại → tải lại ảnh chụp. Đồng hồ đếm theo giờ server (bù chênh lệch từ serverTime).
- Nút trả giá luôn trả đúng mức tối thiểu kế tiếp (`nextBidAmount`); muốn trả cao hơn thì dùng trả giá tự động (proxy bid). Lý do: SRS mô tả nút "Trả Xđ" theo bước giá; tránh gõ nhầm số.
- Mức cọc chọn nhanh ×1/×2/×5/×10 mức cọc tối thiểu của phiên; đăng ký lại với mức cao hơn = cọc thêm để tăng hạn mức.
- Hóa đơn lô thắng là một đơn loại AUCTION trong "Đơn mua"; thanh toán (ví/VNPay, giao tận nơi/nhận tại kho) ở màn chi tiết đơn.

### Người bán và ký gửi
- Form thông tin sách dùng chung (shared/widgets/book_form.dart) cho đăng bán và ký gửi; tối thiểu 3 ảnh, 5 mức tình trạng có mô tả.
- Ký gửi có giá mong muốn dưới 300.000đ bị từ chối sơ duyệt tự động (FakeStore làm như backend nên làm).
- Đơn của shop đang giao: chế độ mock có nút "Giả lập: đã giao thành công" thay cho webhook đơn vị vận chuyển; chế độ thật ẩn nút này.
- Spec chưa có GET một đơn của shop → ApiSellerRepository.shopOrder lấy từ danh sách. Nên thêm GET /seller/orders/{id} vào openapi.yaml.

### Web quản trị
- Hai feature riêng: `staff` (ký gửi, nhận sách, kiểm định, kho, giao lô) và `admin` (tổng quan, phiên, duyệt tin, người dùng, danh mục, cấu hình, rút tiền, khiếu nại). Staff chỉ thấy và vào được phần kho; vào trang Admin bị chuyển về "Yêu cầu ký gửi".
- Màn giám sát phiên hỏi lại GET /sessions/{id}/state mỗi 2 giây thay vì mở STOMP (đủ cho người vận hành, đỡ phụ thuộc feature auction).
- Chạy: `flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/dev.json` (tài khoản staff@rebook.vn / admin@rebook.vn, mật khẩu 123456).

### Giao diện Apple Books (2026-10-22)
- Theme mặc định **sáng** (bỏ "tự động tối trên điện thoại" của UI cũ); người dùng vẫn chọn Tối / Theo hệ thống trong Cài đặt.
- Ngôn ngữ mặc định **tiếng Việt** (không theo ngôn ngữ trình duyệt); đổi được sang tiếng Anh trong Cài đặt.
- Điều hướng giữ 4 nhánh theo SRS 11.2 (Mua sách · Đấu giá · Thông báo · Tài khoản). Nhãn tab trong mockup mobile
  (Thư viện, Chợ sách, Tìm kiếm) là minh họa; tìm kiếm nằm ở sidebar desktop và thanh đầu trang Mua sách trên mobile.
- Desktop: sidebar nổi 3 nhóm — Khám phá (Tìm kiếm, Mua sách, Đấu giá, Thông báo, Giỏ hàng) · Của tôi (Đơn mua, Đấu giá của tôi,
  Ví, Kênh người bán, Ký gửi) · Kệ sách (danh mục gốc). Người dùng / nút Đăng nhập ở đáy sidebar.
- Web mở thẳng trang Mua sách (bỏ trang giới thiệu của UI cũ).
- Sách chưa có ảnh (dữ liệu mẫu) dùng bìa tự vẽ `DrawnCover`: màu + hình chọn ổn định theo id sách.
