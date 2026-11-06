# Báo cáo làm việc qua đêm (2026-11-07)

## Đã làm

| Việc | Kết quả |
|---|---|
| 1. Intro + login (mobile) | Splash, 3 trang giới thiệu có tranh tự vẽ, đăng nhập / đăng ký nền trắng – đen – xanh nhạt, nút "Bỏ qua" vào bằng tài khoản khách. Web giữ landing cuộn, nhưng đăng nhập / đăng ký web dùng chung giao diện mới (thẻ nổi ở giữa). |
| 2. Admin (web) | Khung sidebar thẻ nổi, dashboard (KPI có xu hướng, biểu đồ hiệu suất, việc cần xử lý, hoạt động), trang **Báo cáo** (biểu đồ, bảng theo ngày) xuất **PDF** và **CSV**. Backend thêm `GET /admin/reports`. |
| 3. Đăng nhập Google | Luồng OAuth chạy ở server (không thêm package): `/auth/google/login → callback → exchange`. Nút trong app mở trình duyệt, deep link `rebook:///auth/google?ticket=…` đưa về app. **Đang tắt** cho tới khi đặt `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` (xem `apps/backend/README.md`). |
| 4. Dữ liệu demo | `apps/backend/scripts/reset-demo.ps1` (Windows) / `.sh`: xoá DB, tạo lại, nạp ~80 đơn, 5 phiên đấu giá, ký gửi ở mọi bước, rút tiền, khiếu nại, nợ… Phiên đấu giá #3 tự LIVE ~4 phút sau reset. |
| 5. Admin / staff trên điện thoại | Khung dùng chung (ngăn kéo) đã đúng style mới. Sửa các dòng danh sách bị bóp chữ ở Người dùng, Phiên đấu giá, Giao lô đấu giá (`AdaptiveTile`), tiêu đề Khiếu nại. |
| 6. Chốt sổ | Skeleton loading cho dashboard + báo cáo; kiểm tra toàn bộ API bằng `scripts/smoke.mjs` (96 lời gọi, 0 lỗi, gồm luồng đặt đơn → shop xác nhận / giao, duyệt tin, khoá người dùng, rút tiền); chạy tay trên máy ảo: admin (mọi màn trong ngăn kéo), buyer (khám phá, chi tiết sách, giỏ, thanh toán ví, đơn, sàn đấu giá, phòng đấu giá live). |

## Cách chạy trước buổi demo

```powershell
cd apps/backend
./scripts/reset-demo.ps1 -Port 8081 -Db rebook_books      # khoảng 3 phút; in sẵn tài khoản
node scripts/smoke.mjs http://localhost:8081              # kiểm tra nhanh API (tuỳ chọn)
```

Rồi chạy app bằng `env/local.8081.json` (web: `--web-port 5199`; Android: build với file env trỏ `10.0.2.2:8081`).
Mật khẩu mọi tài khoản demo: `Rebook@123`.

## Đã bấm tay thêm trên máy ảo (buổi sáng)

- Seller1: thông báo (có thông báo kết quả đấu giá do engine tự gửi), kênh người bán (số liệu), danh sách đơn của shop, chi tiết đơn, **Xác nhận đơn** (sang Đang chuẩn bị), **Giao cho shipper** (mã vận đơn bắt buộc 8–20 ký tự: nhập ngắn bị chặn đúng, nhập đủ thì sang Đang giao). Kết quả khớp DB.
- Buyer1: đặt đơn bằng ví (thêm giỏ → giỏ → thanh toán → đơn hiện trong Đơn mua).
- Phiên đấu giá #3 tự LIVE đúng giờ, phòng đấu giá hiện lô, giá, đồng hồ, nút trả giá; hết giờ lô không ai trả thì "Không bán được" và engine tự gửi thông báo cho người bán.
- Sửa dữ liệu demo: đơn hoàn tất không còn mốc `completed_at` ở tương lai (làm "Doanh thu tháng này" của shop sai).

## Chưa làm / chưa kiểm tra (nói thật)

- **Chưa bấm tay**: đăng bán sách (chụp ảnh), ký gửi, trả hàng, màn Ví / rút tiền của người dùng, và các màn Staff (web). Admin trên điện thoại đã duyệt hết màn; Staff dùng chung khung và nhiều màn với Admin nên chưa chắc đã đủ. Phần này chỉ được phủ bằng API smoke + test tự động (198 test frontend, test backend) chứ không phải test tay từng màn.
- Đăng nhập Google chưa thử với Google thật (cần client ID). Chỉ có test backend (6 test với Google giả) và đã kiểm deep link vào app.
- Bản PDF chưa xem bằng mắt (máy không có công cụ vẽ PDF); font tiếng Việt tải từ Google Fonts lúc xuất nên cần có mạng.
- `apps/backend/mvnw test` với `.env.local` đã nạp (có `CLOUDINARY_URL`) làm 3 test upload đỏ vì ảnh lên Cloudinary thật; chạy không có biến này thì xanh. Chạy test backend bằng `env -u CLOUDINARY_URL ./mvnw test`.
- Mock vẫn là mặc định của `env/dev.json` (quy ước repo); bản demo dùng `env/local*.json` nối backend thật.

## Lỗi giao diện đã sửa trong đêm

- Danh sách Người dùng / Phiên đấu giá trên điện thoại: tên bị bẻ từng chữ (nay cụm nút xuống dưới tiêu đề).
- Thẻ Giao lô đấu giá: nút "Xuất kho giao" ép thẻ hẹp, ngày tháng xuống dòng lung tung.
- Dashboard admin ở cửa sổ hẹp: thanh chọn 7/30/90 ngày và hàng "Cần xử lý" bị tràn.
- Khiếu nại trả hàng: tiêu đề dính vào số tiền và hiện "· →" khi thiếu tên người mua.
- Dữ liệu demo: bìa sai tên sách ở tin chờ duyệt (nay dùng đúng bìa).
