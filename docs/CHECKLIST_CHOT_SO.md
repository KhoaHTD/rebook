# Việc cần làm trước khi chốt sổ và đi demo (cập nhật 2026-11-07)

Tình trạng chi tiết của đợt làm qua đêm nằm ở `apps/frontend/docs/NIGHT_REPORT.md`. File này chỉ liệt kê **những gì còn phải làm / phải kiểm tra**.

## 1. Chưa được kiểm tra bằng tay (làm trước khi chốt)

Đã bấm tay trên máy ảo: toàn bộ màn Admin (điện thoại), Seller (thông báo, kênh người bán, xác nhận đơn, giao cho shipper), Buyer (khám phá, chi tiết sách, giỏ, thanh toán ví, đơn mua), sàn đấu giá và phòng đấu giá live, sổ địa chỉ + bản đồ. Còn thiếu:

- [ ] **Seller:** đăng bán sách (chụp ảnh, tách bìa), sửa / ẩn tin, ký gửi đấu giá từ đầu đến cuối, trả lời yêu cầu trả hàng, Ví và **rút tiền** (giao diện người dùng, có thông báo "tiền bán đang bị giữ" của shop mới: `seller4@rebook.vn`).
- [ ] **Buyer:** thanh toán ZaloPay sandbox, COD, huỷ đơn, yêu cầu trả hàng, đánh giá shop, đăng ký + cọc + trả giá thật trong phòng đấu giá (cần hai máy hoặc máy ảo + web), mua lô đã thắng, nạp ví.
- [ ] **Staff (web, desktop):** mọi màn: yêu cầu ký gửi, lịch hẹn & nhận sách, kho, đối chiếu vận chuyển, sự cố & kiểm lại, giao lô đấu giá, giám sát phiên đang chạy (tạm dừng / tiếp tục).
- [ ] **Admin (web, desktop):** dashboard + Báo cáo ở 1400px, bấm **Xuất PDF** và **Xuất CSV**, mở file PDF xem tiếng Việt có dấu (font tải từ Google Fonts, cần mạng) và bố cục.
- [ ] **Staff trên điện thoại:** mới kiểm bằng tài khoản Admin; đăng nhập `staff@rebook.vn` và duyệt các màn của Staff.
- [ ] **Bản đồ địa chỉ trên web:** đã sửa và kiểm trên Android, chưa mở trên web.
- [ ] **Đăng nhập Google:** mới có test backend (Google giả) và deep link; cần client ID thật để thử cả vòng (xem mục 3).

## 2. Việc bắt buộc ngay trước giờ demo

1. Bật Docker Desktop, rồi **reset dữ liệu** (mất khoảng 3 phút, in sẵn tài khoản):
   ```powershell
   cd apps/backend
   ./scripts/reset-demo.ps1 -Port 8081 -Db rebook_books
   node scripts/smoke.mjs http://localhost:8081      # kiểm tra nhanh API, kỳ vọng 0 lỗi
   ```
   Phiên đấu giá #3 tự mở sau ~4 phút kể từ lúc reset: reset xong thì nên dùng ngay, đừng để lâu mới mở app.
2. Chạy app nối **backend thật** bằng file env, không dùng `env/dev.json` (mock):
   - Web: `flutter run -d chrome --web-port 5199 --dart-define-from-file=env/local.8081.json`
   - Android: build APK với file env trỏ `10.0.2.2:8081` (bản sao của `env/local.8081.json`, đừng commit bản đã đổi).
3. Đóng chương trình đang chiếm cổng 8080 (MTAgentService) hoặc giữ backend ở 8081 như trên.
4. Có mạng ổn định: Cloudinary (ảnh bìa), Google Fonts (PDF), Photon + Esri (bản đồ địa chỉ). Mạng đang dùng **chặn tên miền openstreetmap.org**, app đã né nhưng đừng đổi nguồn ô bản đồ lại.
5. Đăng nhập thử từng vai một lần trước khi vào phòng (mật khẩu mọi tài khoản `Rebook@123`): `admin@`, `staff@`, `seller1..4@`, `buyer1..7@`, `locked@` (bị khoá), `banned@` (bị cấm đấu giá).

## 3. Cấu hình còn thiếu

- [ ] **Google OAuth** (nếu muốn demo đăng nhập Google): tạo OAuth client loại *Web application*, khai báo redirect URI `http://localhost:<PORT>/auth/google/callback`, đặt `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI` trong `apps/backend/.env.local`. Máy ảo Android cần địa chỉ công khai (tunnel) vì không gọi được `localhost` của máy host. Hướng dẫn: `apps/backend/README.md`. Chưa cấu hình thì nút báo "chưa được cấu hình".
- [ ] **Thư mục `uploads` / Cloudinary:** `CLOUDINARY_URL` đã nằm trong `.env.local` (không commit). Ảnh biên lai chuyển khoản luôn lưu trên máy chủ (BE-34).

## 4. Phải báo cho team khi đẩy lên GitHub

- `tool/allowed_packages.yaml` đã thêm **`pdf`** và **`printing`** theo yêu cầu của chủ repo (bỏ qua hook chặn); team chưa được báo.
- Migration của backend đã **đánh lại số V18–V21** sau khi merge `improve_bussinessrule`; ai kéo bản cũ (V17/V18 trên `ui-sync-business-rules`) phải tạo lại DB.
- Backend nay **mặc định profile `prod`**: muốn có dữ liệu mẫu phải đặt `SPRING_PROFILES_ACTIVE=dev`. Dữ liệu demo nằm ở `db/demo`, chỉ nạp khi chạy `scripts/reset-demo` (biến `REBOOK_DEMO`).
- Seed mới `V21_2` cắt viền bìa 24 sách hiếm bằng Cloudinary `e_trim:40`. Sách hiếm thêm sau từ Excel cũng phải dùng địa chỉ có `e_trim:40`.
- Test backend: chạy `env -u CLOUDINARY_URL ./mvnw test` (nếu đã nạp `.env.local`, 3 test upload sẽ đỏ vì ảnh lên Cloudinary thật).
- Endpoint mới `GET /admin/reports` (mục B10 của `apps/frontend/docs/BACKEND_HANDOFF.md`) và `/auth/google/*`; spec `apps/backend/openapi.yaml` đã xuất lại.
- Frontend: web giữ landing cuộn, nhưng đăng nhập / đăng ký web nay dùng chung giao diện với điện thoại.

## 5. Việc nên làm nếu còn thời gian (không chặn demo)

- [ ] Màn splash gốc của Android vẫn là logo Flutter vài giây trước khi app lên (cấu hình hệ thống, chưa đổi).
- [ ] `env/dev.json` vẫn là mock (quy ước repo); nếu muốn bỏ hẳn mock thì sửa file này và cập nhật `CLAUDE.md`.
- [ ] `dart run tool/api_gap.dart` còn liệt kê vài endpoint cũ lệch spec frontend (có từ trước, không phải do đợt này).
- [ ] Danh sách Người dùng / Phiên đấu giá / Giao lô đã sửa cho điện thoại; các màn danh sách khác chưa rà hết ở 375px (test bố cục tự động đạt, nhưng không thay được mắt người).
- [ ] Chưa push nhánh `ui-sync-business-rules` (chỉ push lên `main`).

## 6. Việc cuối cùng

- [ ] Chạy `dart analyze --fatal-infos`, `dart run tool/arch_check.dart`, `flutter test` trong `apps/frontend` (kỳ vọng sạch, 201 test).
- [ ] Cập nhật `apps/frontend/docs/PROGRESS.md` nếu thầy cần xem tiến độ.
- [ ] Ghi tên các thành viên và phân công nếu bài nộp yêu cầu.

## 7. Nhật ký tiến độ chốt sổ (cập nhật sau mỗi bước, commit + push `main` từng bước)

> Nếu phiên làm việc bị ngắt (mất mạng...), phiên sau đọc mục này và các ô `[ ]` ở trên để làm tiếp.
> Cách dựng môi trường để test: bật Docker Desktop → `apps/backend/scripts/reset-demo.ps1 -Port 8081 -Db rebook_books` →
> web: `flutter run -d web-server --web-port 5199 --dart-define-from-file=env/local.8081.json` (trong `apps/frontend`);
> Android: build APK với `env` trỏ `10.0.2.2:8081`, máy ảo `rebook_pixel`.

- 2026-11-07: bắt đầu vòng chốt sổ. Chưa có bước nào xong.
