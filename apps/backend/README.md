# ReBook Backend

REST API + WebSocket cho chợ sách cũ ReBook (bán giá cố định + đấu giá).
Spring Boot 3.5 · Java 21 · PostgreSQL · Flyway · JWT · WebSocket.

## Chạy lần đầu

Cần: JDK 21+ (JDK kèm IntelliJ cũng được), PostgreSQL đang chạy ở `localhost:5432`.

```bash
# 1. Tạo user + database (một lần, bằng tài khoản postgres)
psql -U postgres -h localhost -f scripts/create-database.sql

# 2. Chạy (profile dev: tự tạo bảng + nạp dữ liệu mẫu)
./mvnw spring-boot:run          # Windows: mvnw.cmd spring-boot:run
```

- API: http://localhost:8080 · Swagger UI: http://localhost:8080/swagger-ui.html
- Spec OpenAPI: http://localhost:8080/v3/api-docs.yaml (bản xuất sẵn: [openapi.yaml](openapi.yaml))
- Đổi kết nối DB bằng biến môi trường `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`.
- Muốn làm lại dữ liệu mẫu từ đầu: xoá và tạo lại database `rebook_dev`, rồi chạy lại.

## Tài khoản mẫu (mật khẩu `Rebook@123`)

| Email | Vai trò | Ghi chú |
|---|---|---|
| admin@rebook.vn | ADMIN | |
| staff@rebook.vn | STAFF | kho / kiểm định |
| seller1@rebook.vn | USER + shop "Nhà Sách Cũ Sài Gòn" (HCM, uy tín) | 6 tin đăng, 4 yêu cầu ký gửi |
| seller2@rebook.vn | USER + shop "Tiệm Sách Hà Nội Xưa" (HN) | 1 tin chờ duyệt, đơn chờ xác nhận |
| buyer1..3@rebook.vn | USER | ví 3–5 triệu, đã đăng ký + cọc phiên đấu giá #1 |

Dữ liệu mẫu có: 10 danh mục, 16 sách, 9 tin đăng, 3 đơn hàng (hoàn tất / đang giao / chờ xác nhận),
7 yêu cầu ký gửi ở các bước khác nhau, 1 phiên đấu giá 3 lô đã đủ người.

**Demo đấu giá nhanh:** đăng nhập admin → `POST /admin/sessions/1/start` → phiên chạy ngay,
mỗi lô 60 giây. Mở `ws://localhost:8080/ws/sessions/1` để xem sự kiện, buyer trả giá bằng `POST /lots/{id}/bids`.

## Cấu trúc

Modular monolith, mỗi package một module (entity, repository, service, controller, DTO):

| Package | Nội dung |
|---|---|
| `auth` | đăng ký, đăng nhập JWT, refresh token (xoay vòng), OTP email/SĐT, quên mật khẩu |
| `user` | hồ sơ, sổ địa chỉ, bật shop |
| `catalog` | danh mục cây, sách, tin đăng, tìm kiếm / lọc / sắp xếp, Admin duyệt tin |
| `order` | giỏ nhiều shop, checkout tách đơn theo shop, vòng đời đơn, trả hàng, đánh giá, job tự động |
| `wallet` | ví (available / held), sổ cái, VNPay sandbox, rút tiền |
| `consignment` | ký gửi, lịch hẹn, nhận sách, kiểm định, kho |
| `auction` | phiên, lô, đăng ký + cọc, trả giá, proxy bid, bộ máy chạy phiên, quyết toán sau phiên |
| `notification` | lưu thông báo + đẩy realtime qua WebSocket |
| `admin` | khoá tài khoản, phân quyền, cấu hình phí, duyệt rút tiền, dashboard |
| `system` | bảng `system_configs` (phí %, bước giá, thời hạn — Admin sửa được) |

Database: [V1__init_schema.sql](src/main/resources/db/migration/V1__init_schema.sql) (26 bảng),
dữ liệu mẫu: [V1_1__seed_demo_data.sql](src/main/resources/db/seed/V1_1__seed_demo_data.sql) (chỉ profile `dev`).

## Các điểm nghiệp vụ chính

- **Luồng trạng thái**: mỗi enum trạng thái khai báo bước chuyển hợp lệ (`StatusFlow`); chuyển sai → `409 INVALID_STATUS_TRANSITION`.
- **Giữ hàng**: `UPDATE listings SET stock = stock - :qty WHERE stock >= :qty` — 0 dòng = vừa hết hàng.
- **Tiền**: `NUMERIC(15,0)` / `BigDecimal`; mọi thay đổi số dư khoá dòng ví (`FOR UPDATE`) và ghi một dòng sổ cái không sửa được.
  Escrow: tiền bán hàng vào `held` của người bán, hoàn tất đơn mới chuyển sang `available` và trừ phí sàn.
- **Trả giá**: `UPDATE lots ... WHERE version = :v AND ends_at > now` — hai người cùng mức giá thì người sau nhận `409 PRICE_CHANGED`.
  Soft close: trả giá khi còn < 15 giây thì đồng hồ về 15 giây. Hạn mức = cọc × 10.
- **Proxy bid**: đặt giá tối đa (kể cả trước khi lô mở); hệ thống tự đáp, hai proxy cạnh tranh nhảy thẳng tới "giá tối đa bên thua + 1 bước".
- **Job tự động**: mỗi giây (`AuctionEngine`): kiểm đủ người → dời lịch / huỷ, nhắc trước 15 phút, mở phiên, chạy / chốt lô, đóng phiên,
  tạo hoá đơn, hoàn cọc. Mỗi phút: hoá đơn quá 48h → mất cọc (50% người bán / 50% sàn), cấm 90 ngày, mời người trả giá cao thứ hai;
  huỷ đơn chưa thanh toán 15 phút, đơn shop không xác nhận 24h, tự hoàn tất đơn sau 3 ngày; hết hạn lịch hẹn ký gửi.

## Realtime (WebSocket thuần, JSON)

Khớp với `RealtimeClient` của frontend: mỗi kênh là `WS_BASE_URL/<kênh>?token=<jwt>`.

| Kênh | Ai nghe | Nội dung |
|---|---|---|
| `/ws/sessions/{id}` | mọi người (Guest không cần token) | `AuctionEvent`: `SESSION_STARTED`, `LOT_OPENED`, `BID_PLACED`, `LOT_CLOSED`, `SESSION_PAUSED`, `SESSION_RESUMED`, `SESSION_ENDED`, `SESSION_CANCELLED` |
| `/ws/notifications` | user đã đăng nhập (bắt buộc token) | `{type: "NOTIFICATION", notification}` |

Đồng hồ do server giữ: app nhận `endsAt` + `serverTime` rồi tự đếm ngược. Khi vào phòng / kết nối lại,
gọi `GET /sessions/{id}/state` trước rồi mới nghe tiếp WebSocket. Mọi thao tác (trả giá...) đi qua REST.

## Khác với đặc tả / giả lập

- **WebSocket thuần thay cho STOMP**: frontend đã viết `RealtimeClient` theo kiểu này và allowlist package không có thư viện STOMP.
- **Không gửi FCM**: frontend không dùng Firebase SDK. Thông báo lưu DB + đẩy qua `/ws/notifications`.
- **OTP**: chưa có dịch vụ email/SMS — mã ghi ra log; ở profile `dev` trả luôn trong response (`devOtp`).
- **VNPay**: cần `VNPAY_TMN_CODE` + `VNPAY_HASH_SECRET` (tài khoản sandbox). Chưa cấu hình thì `paymentUrl = null`,
  dùng `POST /payments/{code}/simulate` (chỉ bật ở `dev`) để giả lập thanh toán thành công.
  Chạy localhost VNPay không gọi được IPN, nên return URL cũng xác nhận giao dịch (có kiểm chữ ký, idempotent).
- **Vận chuyển**: giả lập bằng nút bấm (`/seller/orders/{id}/ship`, `/delivered`); phí ship theo bảng nội tỉnh / liên tỉnh + khối lượng.
- **Lô không bán được → bán giá cố định**: tạo tin đăng chờ duyệt trong shop người bán (dùng lại `Book`), người bán nhận sách về và tự giao.
- Bộ máy chạy phiên chỉ chạy đúng trên **một** instance backend.
