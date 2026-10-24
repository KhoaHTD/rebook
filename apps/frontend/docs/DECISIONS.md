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
- Hai feature riêng: `staff` (ký gửi, nhận sách, kiểm định, kho, giao lô) và `admin` (tổng quan, phiên, duyệt tin, người dùng, danh mục, cấu hình, rút tiền, khiếu nại). Staff thấy và vào được phần kho + danh sách phiên và màn giám sát (SRS 2: Staff / Auctioneer giám sát phiên tự động — tạm dừng / tiếp tục / hủy lô); tạo / sửa phiên và các trang Admin khác bị chuyển về "Yêu cầu ký gửi". Màn giám sát gọi các endpoint admin pause/resume/cancelLot — backend cần cho phép cả role STAFF.
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
- Phòng đấu giá trực tiếp (`/auctions/sessions/:id/live`) **không cần đăng nhập** để xem — SRS mục 2: khách xem trực tiếp
  phiên, không được trả giá. Chưa đăng ký thì phòng hiện lời nhắc + nút "Đăng ký tham gia" (đăng ký vẫn cần đăng nhập).
- Màn hình con mở từ sidebar desktop (Đơn mua, Ví…) giữ sidebar; phòng đấu giá phủ toàn màn hình.

### Giao diện Liquid Glass + chữ SF (2026-10-22)
- Người dùng duyệt bản vẽ `design-preview/png/lg-desktop.png`, `lg-mobile.png`, thay style Apple Books (nền trắng, serif Newsreader).
- Chữ: người dùng muốn toàn bộ chữ là San Francisco. Giấy phép SF của Apple chỉ cho dùng trên nền tảng Apple, không cho đóng gói
  vào app web / Android → iPhone / Mac dùng SF có sẵn của hệ điều hành, web và Android dùng **Inter** (OFL, gần SF nhất). Người dùng đồng ý.
- Thêm màu nhấn xanh (`AppColors.tint`) — trước đây chỉ đen trắng. Người dùng đồng ý.
- Kính làm mờ tốn GPU → chỉ dùng cho phần nổi; khối trong danh sách dùng kính trong không làm mờ.
- Mobile: chi tiết sách có thanh mua hàng kính nổi phía trên tab bar (nút mua trong trang chỉ còn ở desktop). Tab bar kèm nút tìm kiếm tròn kiểu iOS 26.

### Sách mẫu thật + băng chuyền (2026-10-23)
- Toàn bộ sách mock được thay bằng **16 cuốn** từ 16 thư mục Google Drive người dùng cung cấp. Tên sách = tên thư mục (các tên viết thường hoàn toàn được viết hoa chữ đầu mỗi từ cho đồng nhất: Dế Mèn Phiêu Lưu Ký, Số Đỏ, Đắc Nhân Tâm). Ảnh nén JPEG (cao ≤ 1000px, ~3 MB tổng) đặt ở `assets/books/`.
- **Mỗi ảnh trong thư mục là một ấn bản (bìa) khác nhau** của cùng cuốn → mỗi ảnh thành một tin bán từ một shop khác nhau (32 tin), nên khối "Các bản khác của cuốn này" có dữ liệu thật. Ấn bản xếp theo: cổ điển → bìa khác → hiện đại → trừu tượng.
- Tác giả, nhà xuất bản, năm, số trang, giá, mô tả tình trạng là **dữ liệu mẫu do dev điền** (thư mục chỉ cung cấp tên + ảnh) — nằm trong `lib/shared/data/fake/fake_catalog.dart`, sửa tại đó.
- Danh mục không còn sách bị bỏ: Truyện tranh, Kinh tế, Ngoại ngữ. Còn: Văn học VN, Văn học nước ngoài, Giáo trình (CNTT), Kỹ năng sống, Thiếu nhi, Sách hiếm & cổ.
- Phiên đấu giá, lô, ký gửi mẫu cũng dùng 16 cuốn này (tên phiên đổi theo: "Văn học Việt Nam bản xưa", "Sách hay, bìa hiện đại", "Ấn bản đặc biệt", "Giáo trình và tư liệu", "Sách hiếm Việt Nam").
- Font: tiêu đề + dòng sự kiện đổi sang serif mềm Newsreader (theo ảnh tham chiếu Apple Books); nội dung vẫn SF / Inter. Sidebar tràn hết chiều cao thay cho khối bo góc.

### Trang giới thiệu web (2026-10-23)
- Người dùng gửi một video Pinterest (trang giới thiệu của một sàn tác phẩm nghệ thuật, 43 s) và yêu cầu dựng trang giới thiệu "giống video, animation y chang".
  Video chỉ cho thấy bố cục và chuyển động, không có chữ của ReBook → nội dung được viết lại cho ReBook; ảnh là bìa sách mẫu; "membership" của video thành ba mức phí theo SRS 8.2 (5% bán thường, 15% hoa hồng ký gửi, 10% phí người mua đấu giá).
- Bảng màu theo video (nền trắng ngà, cam, băng vàng chanh, hồng, xanh dương) — khác với phần còn lại của app (Liquid Glass + xanh); trang này là trang giới thiệu riêng.
- Web mở `/` là trang giới thiệu; người đã đăng nhập vào thẳng `/home`; app điện thoại không có trang này. Đổi lại bằng `initialLocation` trong `app_router.dart`.
