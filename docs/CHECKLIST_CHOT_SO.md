# Việc còn lại trước khi chốt sổ và đi demo (cập nhật 2026-11-07)

Ô `[x]` là đã xong, `[ ]` là còn phải làm hoặc phải kiểm. Lịch sử từng bước nằm trong git.

## 1. Đã kiểm xong

- [x] **Tự động:** `dart analyze --fatal-infos`, `dart run tool/arch_check.dart`, `flutter test` (201 test) sạch; `node apps/backend/scripts/smoke.mjs` (96 lời gọi, 0 lỗi).
- [x] **Admin (web):** dashboard, Báo cáo, xuất **CSV** và **PDF** (tiếng Việt đủ dấu, biểu đồ, bảng), duyệt tin, danh mục, khiếu nại (hoàn tiền người mua), đối soát COD, danh sách rút tiền. Tất cả màn Admin trên điện thoại (máy ảo).
- [x] **Staff:** mọi màn trên web và trên điện thoại (yêu cầu ký gửi, lịch hẹn, kho, đối chiếu vận chuyển, sự cố, giao lô đấu giá, phiên đấu giá).
- [x] **Buyer (máy ảo):** khám phá, chi tiết sách, giỏ, thanh toán bằng ví, đơn mua, huỷ đơn, ví, mở cổng ZaloPay khi nạp tiền, sàn đấu giá, phòng đấu giá live, sổ địa chỉ + bản đồ.
- [x] **Seller (máy ảo):** thông báo, kênh người bán, xác nhận đơn, giao cho shipper, chọn ảnh bìa + làm phẳng + tải lên.
- [x] **Qua API trên backend thật:** đăng bán 3 ảnh, sửa tin, ẩn / hiện, sửa tồn kho; đặt COD, huỷ, nhận hàng, đánh giá, yêu cầu trả hàng + shop quyết định, nạp ví (ra link ZaloPay sandbox); phiên đấu giá LIVE (trả giá hợp lệ, "đang giữ giá cao nhất", giá đã đổi, người nợ phạt bị chặn).
- [x] **Lỗi đã sửa trong vòng chốt sổ:** tải ảnh lên Cloudinary trả 409 (cột `audit_events.target_id` 60 ký tự, URL Cloudinary dài hơn); Staff "Giao lô đấu giá" trắng trang trên màn rộng; Admin "Đối soát COD" bị bóp chữ trên điện thoại; ảnh bìa không hiện trên máy ảo (DNS, xem mục 2).

## 2. Việc bắt buộc ngay trước giờ demo

1. Bật Docker Desktop, rồi **reset dữ liệu** (khoảng 3 phút, in sẵn tài khoản):
   ```powershell
   cd apps/backend
   ./scripts/reset-demo.ps1 -Port 8081 -Db rebook_books
   node scripts/smoke.mjs http://localhost:8081      # kiểm nhanh API, kỳ vọng 0 lỗi
   ```
   Phiên đấu giá #3 tự mở sau khoảng 4 phút kể từ lúc reset: reset xong thì dùng ngay, đừng để lâu mới mở app.
   Dữ liệu hiện tại đã lẫn thao tác kiểm thử (đơn, tin "QA", một khoản COD đã đối soát), nên **phải reset lại**.
2. Chạy máy ảo Android bằng `emulator -avd <tên> -dns-server 1.1.1.1,8.8.8.8`. Không có cờ này máy ảo có thể không phân giải được `res.cloudinary.com` / `accounts.google.com`: mọi ảnh bìa rơi về bìa vẽ và Google báo `DNS_PROBE_FINISHED_BAD_CONFIG`.
3. Chạy app nối **backend thật** bằng file env, không dùng `env/dev.json` (mock):
   - Web: `flutter run -d chrome --web-port 5199 --dart-define-from-file=env/local.8081.json` (trong `apps/frontend`).
   - Android: chép `env/local.8081.json`, đổi `localhost` thành `10.0.2.2` (đừng commit bản đã đổi).
4. Có mạng ổn định: Cloudinary (ảnh bìa), Google Fonts (xuất PDF), Photon + Esri (bản đồ địa chỉ). Mạng đang dùng **chặn openstreetmap.org**, app đã né nhưng đừng đổi nguồn ô bản đồ lại.
5. Đăng nhập thử từng vai một lần trước khi vào phòng (mật khẩu mọi tài khoản `Rebook@123`): `admin@`, `staff@`, `seller1..4@`, `buyer1..7@`, `locked@` (bị khoá), `banned@` (bị cấm đấu giá).

## 3. Chưa làm / cần người thật

- [ ] **Đăng nhập Google:** cấu hình đã có trong `apps/backend/.env.local` (không commit). Cần **bạn** bấm "Tiếp tục với Google" ở `http://localhost:5199/login` bằng tài khoản của mình, và tài khoản đó phải nằm trong danh sách **Test users** ở Google console. Máy ảo Android cần địa chỉ công khai (tunnel) làm redirect URI vì không gọi được `localhost` của máy host: nên demo Google trên web.
- [ ] **ZaloPay sandbox:** cần nhập thẻ test trên cổng ZaloPay (thẻ test: README backend, mục ZaloPay). Mới kiểm tới bước mở cổng.
- [ ] **Bấm tay trên giao diện (mới kiểm bằng API):** điền hết form đăng sách, sửa / ẩn tin, ký gửi đấu giá từ đầu đến cuối, trả lời yêu cầu trả hàng, ví và rút tiền của người bán (có thông báo "tiền bán đang bị giữ" ở `seller4@`), yêu cầu trả hàng / đánh giá của người mua, đăng ký + cọc + trả giá + mua lô thắng (cần hai máy: web và máy ảo).
- [ ] **Buyer / Seller trên web** (desktop và 375px) và **bản đồ địa chỉ trên web**: chưa mở bằng tay (bản đồ đã chạy trên Android).
- [ ] **Admin web:** các màn còn lại chưa bấm (Người dùng, Phiên đấu giá, Cấu hình, Nhật ký hoạt động); nút "Đã chuyển khoản" của Rút tiền cần tải ảnh biên lai.

## 4. Phải báo cho team khi đẩy lên GitHub

- `tool/allowed_packages.yaml` đã thêm **`pdf`** và **`printing`** theo yêu cầu của chủ repo (bỏ qua hook chặn); team chưa được báo.
- Migration của backend đã **đánh lại số V18–V21** sau khi merge `improve_bussinessrule`; ai kéo bản cũ (V17/V18 trên `ui-sync-business-rules`) phải tạo lại DB.
- Backend nay **mặc định profile `prod`**: muốn có dữ liệu mẫu phải đặt `SPRING_PROFILES_ACTIVE=dev`. Dữ liệu demo nằm ở `db/demo`, chỉ nạp khi chạy `scripts/reset-demo` (biến `REBOOK_DEMO`).
- Seed mới `V21_2` cắt viền bìa 24 sách hiếm bằng Cloudinary `e_trim:40`. Sách hiếm thêm sau từ Excel cũng phải dùng địa chỉ có `e_trim:40`.
- Endpoint mới `GET /admin/reports` (mục B10 của `apps/frontend/docs/BACKEND_HANDOFF.md`) và `/auth/google/*`; spec `apps/backend/openapi.yaml` đã xuất lại.
- Sửa lỗi backend: `POST /files` lên Cloudinary không còn 409 (xem `FileController`). Chưa có test hồi quy riêng cho trường hợp URL dài.
- Frontend: web giữ landing cuộn, nhưng đăng nhập / đăng ký web dùng chung giao diện với điện thoại.
- Đã **xoá tài liệu cũ**: báo cáo QA 05/11, `UI_TEST_PROGRESS`, `qa-tools/`, `NIGHT_REPORT`, hai file prompt / brief vẽ banner. Lịch sử vẫn trong git.

## 5. Việc nên làm nếu còn thời gian (không chặn demo)

- [ ] Màn splash gốc của Android vẫn là logo Flutter vài giây trước khi app lên (cấu hình hệ thống, chưa đổi).
- [ ] `env/dev.json` vẫn là mock (quy ước repo); muốn bỏ hẳn mock thì sửa file này và cập nhật `CLAUDE.md`.
- [ ] `dart run tool/api_gap.dart` còn liệt kê vài endpoint cũ lệch spec frontend (có từ trước).
- [ ] Gói `stomp_dart_client` vẫn nằm trong `pubspec.yaml` và allowlist nhưng không còn code nào dùng (realtime là WebSocket JSON thuần): có thể gỡ.
- [ ] `env/android.tunnel.json` đang giữ một link Cloudflare đã hết hạn.
- [ ] Ảnh banner `upcoming`, `season-school`, `season-tet`, `auth` chưa được code gọi tới.
- [ ] Rà thêm các màn danh sách ở 375px (test bố cục tự động đạt, nhưng không thay được mắt người).
- [ ] Chưa push nhánh `ui-sync-business-rules` (chỉ push lên `main`).

## 6. Việc cuối cùng

- [ ] Chạy lại `dart analyze --fatal-infos`, `dart run tool/arch_check.dart`, `flutter test` trong `apps/frontend` sau mọi thay đổi cuối.
- [ ] Ghi tên các thành viên và phân công nếu bài nộp yêu cầu.
