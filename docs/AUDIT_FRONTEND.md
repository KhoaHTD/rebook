# Rà soát frontend ReBook

Ngày 2026-11-05. Đọc hạ tầng và luồng chính của `apps/frontend` (core, realtime, auth, env, CI, tài liệu bàn giao); **chưa đọc từng màn hình**. Mỗi mục đã được kiểm lại với code (có `file:dòng`).
Lỗi backend ở [AUDIT_BACKEND.md](AUDIT_BACKEND.md). Mức: **P1** gây hỏng trải nghiệm hoặc rủi ro thật · **P2** thiếu cho bản chạy thật.
Cột "Người nhận" và "Trạng thái" để nhóm tự điền; trạng thái trống = chưa sửa. Đường dẫn tính từ `apps/frontend/`.

## Cập nhật sau khi pull (đến commit `6af440c`, 2026-11-05)

Đã đối chiếu các commit frontend mới (`3ea1ff6`, `48e8087`, `79b4123` và tài liệu QA `QA_FINDINGS_2026-11-05.md`, `FIXES_2026-11-05.md`) với bảng này.

| Mục | Kết quả | Ghi chú |
|---|---|---|
| FE-01 … FE-07, FE-10, FE-11 | Chưa đổi | `env/*.json`, `env.dart`, `auth_interceptor.dart`, `realtime_client.dart`, `push_service.dart`, `geocoder.dart`, `_normalizeCode` không có commit nào đụng tới |
| FE-08 | Sửa nhỏ | Lưu được cờ "đã xem giới thiệu"; theme / ngôn ngữ vẫn trong RAM |
| FE-09 | Tốt hơn | 38 file test (trước 30); vẫn chưa có test với backend thật |
| FE-12 | Mới | Nút giả lập giao hàng lộ ra ở mọi môi trường |

Các lỗi QA tìm ra và đã sửa (đều nằm ngoài danh sách audit, do test thủ công): Admin duyệt rút tiền gửi giờ không có múi giờ (400); đăng nhập sai báo "hết phiên"; mật khẩu 6–7 ký tự lọt form; `+84` không đổi thành `0`; số rút tối thiểu lệch (10.000 so với 50.000); xoá danh mục còn con báo sai; ảnh sản phẩm trong đơn là ảnh ngẫu nhiên; phí ship giỏ hàng khác bước xác nhận; mở shop báo lỗi khi chưa có shop; Staff vào màn phiên bị 403 tải mãi; trang phiên không tự cập nhật (nay làm mới mỗi 15 giây, xem mục bên dưới).

Mục mới đáng chú ý: trang phiên và danh sách phiên giờ **hỏi lại backend mỗi 15 giây** (`_refreshPeriodically`) thay vì nghe WebSocket. Đủ cho trang xem, nhưng nhân với số người mở app thì tải tăng; nếu muốn gọn hơn thì dùng lại sự kiện `SESSION_STARTED` đã có ở kênh WebSocket.

## Việc frontend phải làm sau thay đổi luồng tiền (2026-11-05)

Backend đã đổi các điểm sau; **chưa có thay đổi nào ở frontend**. `apps/backend/openapi.yaml` đã xuất lại; frontend chạy `/sync-api` để sinh lại client rồi sửa các mục dưới đây.

| Thay đổi backend | Frontend cần làm | Nếu chưa làm |
|---|---|---|
| Nút shop "Đã giao" / "Giao thất bại" chỉ chạy ở dev | Ẩn hai nút này ở bản production (cờ build riêng, không dùng `useMock`); đây là FE-12 | Shop bấm sẽ nhận 403 "Chức năng giả lập hãng vận chuyển đã tắt" |
| Người mua xác nhận đã nhận khi đơn đang `SHIPPING` | Hiện nút "Đã nhận hàng" cả khi đơn đang giao | Người mua phải chờ 7 ngày tự giao |
| Trả hàng có bước gửi hàng về: `ReturnStatus` thêm `AWAITING_GOODS`, `EXPIRED`; `ReturnResponse` thêm `returnTrackingCode`, `returnShippedAt`, `returnReceivedAt`, `shipBy` | Màn trả hàng: nút "Gửi hàng trả" (`POST /orders/{id}/return/shipment`), shop/kho nút "Đã nhận lại sách" (`/seller/orders/{id}/return-received`, `/staff/orders/{id}/return-received`); xử lý giá trị enum mới | Enum lạ rơi vào `$unknown` (không lỗi) nhưng `AWAITING_GOODS` bị hiển thị như "chờ phản hồi"; người mua không biết phải gửi hàng về |
| Rút tiền: lỗi `TOPUP_LOCKED`, `WITHDRAW_DAILY_LIMIT`; `GET /wallet/withdrawable` | Hiện số rút được ngay và giờ mở khoá ở màn rút tiền; dịch hai mã lỗi | Người dùng chỉ thấy lỗi chung |
| Đặt COD: lỗi `COD_NOT_ALLOWED` (vượt hạn mức hoặc bị chặn) | Dịch lỗi, gợi ý đổi sang ví / ZaloPay | Lỗi chung |
| Đối soát COD cho Admin: `GET /admin/cod/pending`, `POST /admin/cod/{orderId}/remit` | Màn "Đối soát COD" trong web quản trị | Admin phải gọi API tay |
| Số tiền shop nhận COD chỉ về sau khi đối soát | Ghi chú "Tiền COD về ví sau khi sàn đối soát với hãng vận chuyển" ở màn đơn của shop | Shop thắc mắc vì sao chưa thấy tiền |

## Việc frontend phải làm sau thay đổi luồng tiền đấu giá (2026-11-05)

Backend đã đổi; **frontend chưa đổi gì**, `apps/backend/openapi.yaml` đã xuất lại (chạy `/sync-api`). Chi tiết quy tắc: [AUCTION_MONEY_FLOW.md](AUCTION_MONEY_FLOW.md).

| Thay đổi backend | Frontend cần làm | Nếu chưa làm |
|---|---|---|
| `DELETE /sessions/{id}/register`; `RegistrationStatus` thêm `CANCELLED` | Nút "Huỷ đăng ký" ở màn phiên / Của tôi khi còn trong hạn đăng ký; xử lý trạng thái mới | Người dùng không huỷ được; trạng thái `CANCELLED` rơi vào `$unknown` nên hiển thị sai (không lỗi) |
| Nợ phạt / phí kho: `GET /me/debts`, `POST /me/debts/collect`; lỗi `DEBT_OPEN` khi đăng ký, trả giá, rút tiền | Màn "Khoản nợ" (danh sách, nút thu nợ từ ví); dịch lỗi `DEBT_OPEN` và hướng người dùng tới màn nợ | Người dùng bị chặn mà không biết lý do |
| Phạt bỏ thanh toán: thông báo "Bạn bị phạt vì không thanh toán lô thắng" | Cảnh báo rõ ở màn hoá đơn lô thắng: quá hạn 48 giờ bị phạt 10% giá búa (mất cọc nếu cọc lớn hơn), cấm đấu giá 90 ngày | Người dùng không biết hậu quả |
| Phí giao hoá đơn lô thắng gộp theo kiện | Hiển thị ghi chú "đã gộp phí giao với các lô cùng phiên" | Phí các hoá đơn khác nhau gây thắc mắc |
| `LotStatus` thêm `INSPECTING` | Web quản trị: nhãn và bộ lọc "Chờ kiểm định lại"; màn Staff gọi `POST /staff/lots/{id}/reinspect` {passed, report} | Lô bị trả hiện trạng thái lạ, Staff không xử lý được |
| Admin miễn nợ: `POST /admin/debts/{id}/waive` | Nút "Miễn nợ" kèm lý do ở màn người dùng của Admin | Admin phải gọi API tay |
| Cấu hình mới `auction.default_penalty_percent`, `auction.unsold_decision_days` | Nhãn tiếng Việt trong màn Cấu hình phí (`_configLabels`) | Hiện khoá thô |
| Lô không bán quá 7 ngày không chọn sẽ tự trả sách | Hiển thị hạn quyết định còn lại ở màn kết quả ký gửi của người bán | Người bán bất ngờ khi lô tự chuyển |

## Việc frontend sau đợt thuần backend 2026-11-06

Spec API **không đổi** trong đợt này. Frontend chỉ cần biết hành vi mới (đa số là thông báo, không cần màn mới):

| Hành vi backend mới | Frontend nên làm |
|---|---|
| Đơn `PREPARING` quá 3 ngày không giao cho vận chuyển tự chuyển `CANCELLED` và hoàn tiền | Ghi chú hạn giao ở màn đơn của shop; thông báo huỷ đã có |
| Yêu cầu huỷ không được shop trả lời trong 24 giờ tự được đồng ý | Hiện đếm ngược hạn trả lời ở màn đơn của shop |
| Shop bị gỡ uy tín khi tỷ lệ đơn lỗi vượt ngưỡng | Hiện trạng thái uy tín ở màn kênh người bán |
| Khoá tài khoản ẩn tin, huỷ đơn chưa giao, hoàn cọc | Không cần đổi |
| Mã lỗi `AUCTION_BANNED`, `NOT_REGISTERED` (trước đây dò chuỗi câu chữ) | Có thể bỏ đoạn dò chuỗi tiếng Việt trong `app_exception.dart` (FE-07); tạm thời vẫn chạy vì hằng số đã khớp |
| Duyệt tin chuyển từ lô không bán bị từ chối `BOOK_IN_WAREHOUSE` khi sách còn trong kho | Dịch lỗi ở màn duyệt tin của Admin |

## Việc test còn nợ

Theo chính tài liệu QA, các phần này **chưa ai test được**, nên chưa có bằng chứng chạy đúng: cổng ZaloPay thật (mở form thẻ), thông báo đẩy FCM, mất mạng giữa phiên đấu giá, các mốc chờ 15 phút đến 48 giờ (hết hạn thanh toán, tự huỷ đơn shop không xác nhận, quá hạn 48h lô thắng, mời mua lần hai), tải ảnh từ thư viện và lưu form địa chỉ trên máy ảo, bấm tay phần Admin duyệt rút tiền, TalkBack. Nhiều mục trong [AUDIT_BACKEND.md](AUDIT_BACKEND.md) (BE-07, BE-08, BE-17, BE-19, BE-36) nằm đúng ở các mốc này; cần job hoặc cách đẩy thời gian (chỉnh `payment_due_at` bằng SQL) để test.

## A. Lỗi cần sửa

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| FE-01 | P1 | Cấu hình build: `env/prod.json` là chỗ giữ chỗ (`https://api.example.com/api`, `wss://api.example.com/ws`) và còn tiền tố `/api` trong khi backend không có tiền tố này (`env/local.json` dùng `http://localhost:8080`). `frontend-deploy.yml` build bằng `prod.json` mỗi lần push `main`, nên bản live trỏ vào API không tồn tại. Ngoài ra `USE_MOCK` mặc định `true`: bản Android / iOS build thủ công mà quên `--dart-define-from-file` sẽ chạy bằng dữ liệu giả | `env/prod.json`, `env/dev.json`, `env/tunnel.json`, `lib/app/env.dart:14`, `.github/workflows/frontend-deploy.yml` | Điền URL thật, bỏ `/api`; đặt mặc định `USE_MOCK=false` (hoặc dừng khi thiếu cấu hình ở release) | | |
| FE-02 | P1 | Đăng xuất oan: `catch (_)` coi mọi lỗi lúc refresh token (rớt mạng, timeout, 500) là hết phiên và gọi `_onSessionExpired` | `lib/core/network/auth_interceptor.dart:64-67` | Chỉ đăng xuất khi refresh trả 401 / `INVALID_REFRESH_TOKEN`; lỗi mạng thì giữ phiên và báo thử lại | | |
| FE-03 | P1 | Thông báo đẩy chưa nối: `pushServiceProvider` không được gọi ở đâu (chỉ có dòng định nghĩa), `FCM_ENABLED=false` ở mọi file env kể cả `prod.json`, và backend chưa có endpoint đăng ký thiết bị. "Bị trả giá cao hơn", "thắng đấu giá" chỉ tới khi app đang mở. Làm cùng [BE-36](AUDIT_BACKEND.md) | `lib/core/notifications/push_service.dart:77-79`, `env/*.json` | Gọi `init()` sau đăng nhập, gửi token lên endpoint đăng ký thiết bị, xử lý `opened` để mở đúng màn | | |
| FE-04 | P1 | Realtime: nối lại cố định 3 giây, không backoff / jitter; không heartbeat nên kết nối chết nửa vời (mạng yếu, máy ngủ) không phát hiện. Đã có tải lại ảnh chụp trạng thái sau khi nối lại, nhưng phòng đấu giá chưa có thông báo trạng thái kết nối hay khoá nút trả giá khi chưa đồng bộ | `lib/core/realtime/realtime_client.dart:22, 108-114`, `lib/features/auction/presentation/screens/live_room_screen.dart` | Ping / pong định kỳ, backoff luỹ tiến, banner "mất kết nối", khoá trả giá khi chưa đồng bộ lại | | |
| FE-05 | P1 | Gọi thẳng dịch vụ công cộng từ app: Nominatim (giới hạn ~1 yêu cầu/giây, cấm dùng nặng), tile OSM công cộng `tile.openstreetmap.org`, `provinces.open-api.vn` (dữ liệu 63 tỉnh). Sổ bàn giao đã tự ghi rủi ro này | `lib/core/network/geocoder.dart:31-33`, `lib/shared/widgets/osm_map.dart:120`, `lib/core/network/admin_units.dart` | Proxy qua backend + cache; nhà cung cấp tile riêng; danh mục địa giới mới (liên quan [BE-37](AUDIT_BACKEND.md)) | | |
| FE-06 | P2 | Token trên web nằm trong `flutter_secure_storage` (thực chất lưu ở trình duyệt, XSS đọc được); refresh token sống 30 ngày. Cần xác nhận lại hành vi chính xác trên web | `lib/core/auth/token_storage.dart:54-56`, `apps/backend/src/main/resources/application.yml:62` | Cookie `httpOnly` cho web hoặc refresh ngắn hơn, thêm CSP | | |
| FE-07 | P1 | Xử lý lỗi dò chuỗi tiếng Việt: `FORBIDDEN` được chia thành `auctionBanned` / `notRegistered` bằng `message.contains('cấm tham gia đấu giá')`; backend đổi câu chữ là hỏng. Sửa cùng [BE-35](AUDIT_BACKEND.md) | `lib/core/error/app_exception.dart:33-38` | Dùng mã lỗi riêng khi backend thêm xong | | |
| FE-08 | P2 | Cài đặt (theme, ngôn ngữ, vị trí nút điều hướng) chỉ giữ trong RAM, mất khi mở lại app (sau pull: chỉ cờ "đã xem giới thiệu" được lưu qua `TokenStorage`, theme / ngôn ngữ vẫn chưa). Lý do ghi ở `DECISIONS.md`: allowlist không có `shared_preferences` | `lib/core/settings/app_settings_controller.dart:41-56` | Xin duyệt `shared_preferences` hoặc lưu qua `TokenStorage` | | |
| FE-09 | P2 | Kiểm thử mỏng: 38 file test cho 245 file nguồn (không tính file sinh; sau pull đã thêm test cho skeleton, cuộn tới ô lỗi, map lỗi, rút tiền của Admin, làm mới phiên, shop chưa mở, mapper, layout người mua); không thấy test nào gọi backend thật. Chưa có end-to-end (đặt hàng → thanh toán → hoàn tất; nhiều máy trả giá cùng lúc) | `test/` | Test tích hợp với `env/local.json`; dùng `tool/api_gap.dart` làm kiểm hợp đồng trong CI | | |
| FE-10 | P2 | Trợ năng và quan sát: chỉ 5 chỗ dùng `Semantics`/`semanticLabel`; không có Sentry / Crashlytics nên lỗi production không ai thấy; không có package phát hiện trạng thái mạng (`connectivity`) | `lib/`, `pubspec.yaml` | Nhãn đọc màn hình cho đồng hồ / nút trả giá, báo lỗi tập trung, banner offline | | |
| FE-11 | P2 | Sổ bàn giao đã cũ: mục B9 vẫn ghi mật khẩu "≥ 6 ký tự" và cột D ghi "chưa kiểm tra lại phía server", trong khi code (frontend và backend) đã là 8–72 ký tự và server đã kiểm SĐT / mật khẩu | `docs/BACKEND_HANDOFF.md` (mục B9, bảng D), `lib/core/utils/input_rules.dart:137-142` | Cập nhật tài liệu cho khớp code | | |
| FE-12 | P1 | **Mới (từ code vừa thêm).** Nút "Giả lập: đã giao thành công" (và "Giao thất bại") đã bỏ điều kiện `Env.useMock`, nên người bán thấy nút này ở mọi môi trường. Comment trong code nói "backend chỉ nhận ở môi trường dev" là sai: hai endpoint backend không kiểm tra môi trường nào. Kết quả: người bán tự bấm giao thành công cho đơn của chính mình rồi nhận tiền sau 3 ngày. Làm cùng [BE-04](AUDIT_BACKEND.md) | `lib/features/seller/presentation/screens/seller_order_detail_screen.dart:259-274`, `apps/backend/src/main/java/com/rebook/order/OrderManagementController.java:57-68` | Ẩn nút khỏi bản production (cờ build riêng, không dùng `useMock`) cho tới khi có webhook hãng vận chuyển; backend chặn các endpoint này ngoài profile dev | | |

## B. Việc đi kèm khi backend sửa

Mỗi dòng là việc giao diện phải làm cùng lúc, nếu không sửa backend xong giao diện vẫn thiếu.

| Backend | Việc frontend |
|---|---|
| BE-03 Trả hàng có bước gửi hàng về | Màn trả hàng: trạng thái gửi lại, mã vận đơn trả, xác nhận đã nhận; hiển thị ai chịu ship trả |
| BE-11 Phân xử, bằng chứng của shop | Màn đơn shop: nộp ảnh phản biện; màn Admin: hoàn một phần |
| BE-12 Giá lệch khi checkout | Hộp thoại "giá đã đổi, xác nhận lại" ở giỏ và thanh toán |
| BE-13 `Idempotency-Key` | Sinh khoá mỗi lần mở màn thanh toán / rút tiền (UI đã khoá nút khi đang gửi, xem mục C) |
| BE-18 Huỷ đăng ký phiên | Nút "Huỷ đăng ký" ở màn đăng ký và Của tôi, trước hạn đăng ký |
| BE-19, BE-21 Lô không bán / chuyển bán thường | Màn quyết định cho người bán: hạn còn lại, cảnh báo phí lưu kho |
| BE-26 OTP thật | Đếm ngược gửi lại OTP, báo khoá tạm khi nhập sai |
| BE-02 Rút tiền an toàn | Bước OTP khi thêm tài khoản ngân hàng mới, hiển thị hạn mức rút / ngày |
| BE-36 Thông báo ngoài app | Xem [FE-03](#a-lỗi-cần-sửa) |
| BE-09 Điểm uy tín | Hiển thị chỉ số trên trang shop |

## C. Đã kiểm tra, không phải lỗi
- **Bấm đúp / gửi lặp ở giao diện**: đơn hàng, thanh toán, rút tiền và nút trả giá đều khoá khi đang gửi (`busy`/`isLoading`, ví dụ `order_detail_screen.dart:220`, `checkout_screen.dart:323`, `withdraw_screens.dart:326`, `live_room_screen.dart:336`). Rủi ro còn lại là hai tab / hai thiết bị, thuộc [BE-13](AUDIT_BACKEND.md).
- **Mật khẩu 8–72 ký tự**: frontend và backend đã khớp (`input_rules.dart:137`, `AuthDtos.java:18`).
- **Làm mới token đồng thời**: `QueuedInterceptor` đảm bảo chỉ refresh một lần.
- **Nối lại WebSocket**: đã tải lại ảnh chụp trạng thái sau khi nối lại (`auction_providers.dart:86-90`).

## Việc frontend sau đợt vá 2026-11-06

Spec API **có thêm** (`apps/backend/openapi.yaml`, chỉ thêm). Cần chạy `/sync-api` ở frontend.

| Thay đổi backend | Frontend nên làm |
|---|---|
| `GET /staff/orders/in-transit`, `POST /staff/orders/{id}/carrier-delivered`, `POST /staff/orders/{id}/carrier-failed` | Màn Staff "Đơn đang giao" với hai nút đối chiếu hãng vận chuyển. **Cần có để đơn COD hoàn tất được** |
| Đơn COD không còn tự chuyển "đã giao" | Màn đơn người mua / shop: không hứa "tự xác nhận sau N ngày" cho đơn COD |
| `ReturnResponse.returnToName`, `returnToAddress` | Màn trả hàng của người mua: hiện địa chỉ gửi trả cùng nút nhập mã vận đơn |
| `GET /staff/lots/inspecting` | Màn Staff "Lô chờ kiểm định lại" |
| Thông báo nhắc trước hạn (giao hàng, trả lời huỷ, thanh toán, chọn hướng xử lý lô) | Không cần màn mới; kiểm tra loại thông báo mới hiển thị đúng |

## Việc frontend sau đợt 2026-11-06 (ép số nguyên cho tiền)

Backend nay trả 400 khi số tiền lẻ hoặc quá 15 chữ số. Frontend đang gửi `int` nên không bị ảnh hưởng. Nếu sau này đổi sang `double`, giữ giá trị nguyên (`50000` hoặc `50000.0` đều được nhận, `50000.4` thì không). Phí giao của hoá đơn đấu giá có thể đổi (giảm) sau khi người thắng chọn giao tận nơi cho hoá đơn thứ hai: màn hoá đơn nên đọc lại chi tiết đơn sau mỗi lần đổi cách nhận.
