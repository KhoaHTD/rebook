# Thiết kế gửi mail (xử lý P0 mục 2, 3, 4)

Ngày 2026-11-06. Nguồn mục: [DANH_GIA_BA_TESTER.md](DANH_GIA_BA_TESTER.md) phần A, mục 3, nhóm P0.

**Trạng thái: đã code (nhánh `improve_bussinessrule`, migration `V17`; bản tìm kiếm không dấu chưa push của nhóm dùng số kế tiếp, `V18`). `./mvnw test` 199/200 đạt** trên PostgreSQL 18 tạm (cổng 5433, `TEST_DB_URL`); ca còn lại là `SeedDataTest` (gắn cứng cổng 5432, như các lần chạy trước). Test mới: `MailOutboxTest`, `OtpAndEmailRulesTest`, `SellerHoldAndChargebackTest`. Cấu hình mail và DB: chép [`apps/backend/env.example`](../../apps/backend/env.example) thành `apps/backend/.env` rồi điền.

Khác với bản thiết kế dưới đây:

| Chỗ | Thiết kế | Đã làm |
|---|---|---|
| Gửi OTP | Sau commit | **Trong giao dịch**: mail lỗi thì mã bị huỷ cùng giao dịch, không có mã mồ côi. Đăng ký và quên mật khẩu không báo lỗi mail (quên mật khẩu không được lộ email nào có thật) |
| `dedupe_key` | Cột UNIQUE | Không làm: các job nhắc đã có cờ "nhắc một lần", job gửi khoá dòng và chỉ gửi dòng `PENDING` |
| Mail rút tiền được duyệt / từ chối, khoá tài khoản | Có trong bảng mục 3 | Chưa làm: hai việc này chưa có thông báo trong app để gắn vào |
| Mail "tiền đang giữ đến ngày X" | Có | Không gửi mail; `GET /wallet/withdrawable` trả `saleHeld`, `saleUnlockAt`, lỗi `SALE_HELD` ghi rõ ngày |
| Chặn mua khi trùng số tài khoản ngân hàng (mục 6) | Đề xuất | Không làm: kẻ gian dùng tài khoản mua không bao giờ khai ngân hàng nên gần như không bắt được ai |
| Shop uy tín | Không nói | Shop được Admin gắn uy tín không bị giữ tiền bán |
| Health check | Không nói | Tắt health check mail của actuator (`management.health.mail.enabled: false`): SMTP chậm không được làm `/actuator/health` báo DOWN, mail đã có hàng đợi và thử lại riêng |

| P0 | Vấn đề | Mail giải quyết được đến đâu |
|---|---|---|
| 2 | Không có thông báo ngoài app nhưng vẫn phạt theo hạn | **Giải quyết chính.** Mail cho mọi mốc có hạn + luật "mail không tới thì không phạt" |
| 3 | Không định danh: OTP chỉ ghi log, không CCCD | **Một phần.** OTP email thật + giới hạn xin OTP + chặn email trùng biến thể. OTP SMS và CCCD **không** làm bằng mail |
| 4 | Nạp thẻ trộm, rút qua shop phụ, chưa có chargeback | **Không.** Mail chỉ báo tin. Cách sửa là luật ví (mục 6), không liên quan kênh gửi |

## 1. Hiện trạng (đã đọc code)

- `NotificationService.notify(userId, type, title, body, data)` lưu bảng `notifications` và đẩy WebSocket. 21 chỗ gọi `notify` trong 9 file (đơn, đấu giá, ký gửi, kho, tin). Muốn thêm kênh thì gắn vào hàm này (comment ở đầu class đã ghi vậy).
- Các job nhắc đã có và đã có cờ "nhắc một lần" (`Order.*ReminderSent`, `AuctionSession.reminderSent`). Mail chỉ cần đi theo `notify`, **không viết lại job nhắc**.
- OTP: `AuthService.issueOtp` (dòng ~194–205) tạo mã, `log.info` mã ra log, trả `devOtp` khi `app.otp.expose-in-response`. Chưa có `spring-boot-starter-mail`, chưa có `spring.mail.*`.
- `User` đã có `email`, `emailVerified`, `phone`, `phoneVerified`.

## 2. Kiến trúc

```
Nghiệp vụ ──notify()──▶ notifications (như cũ) ─┬▶ WebSocket (như cũ)
                                                └▶ email_outbox (mới, cùng giao dịch, nếu loại thông báo thuộc danh sách mục 3)
EmailOutboxJob (mỗi 30 giây) ──▶ MailSender (SMTP) ──▶ đánh dấu SENT / thử lại / FAILED

OTP ──▶ MailSender gửi trực tiếp sau commit (không qua outbox, mục 4)
```

**Vì sao outbox:** `notify` chạy trong giao dịch tiền. SMTP chậm hay lỗi không được làm hỏng hay treo giao dịch ví; giao dịch rollback thì mail cũng không được gửi. Ghi một dòng cùng giao dịch rồi gửi sau là cách ngắn nhất đạt cả hai.

### Bảng `email_outbox` (migration `V17`)

| Cột | Ghi chú |
|---|---|
| `id`, `user_id`, `to_email` | Địa chỉ lấy lúc ghi, để user đổi email không gửi nhầm |
| `type`, `subject`, `body` | Văn bản thuần tiếng Việt (không HTML ở bản đầu) |
| `dedupe_key` UNIQUE | `type:orderId` / `type:lotId`... để job chạy lại không gửi trùng |
| `status` | `PENDING` → `SENT` / `FAILED` |
| `attempts`, `next_attempt_at`, `last_error` | Thử lại 1 phút, 5 phút, 30 phút, 2 giờ; quá 5 lần thì `FAILED` |
| `created_at`, `sent_at` | |

Job lấy bằng `FOR UPDATE SKIP LOCKED`, mỗi dòng một giao dịch (theo mẫu `each(...)` của các job hiện có). Xoá dòng `SENT` quá 30 ngày; `body` không chứa mã bí mật nên giữ được.

### Cấu hình

`spring-boot-starter-mail` (một dependency, đã nằm trong BOM Spring Boot). Biến môi trường: `MAIL_HOST`, `MAIL_PORT`, `MAIL_USER`, `MAIL_PASS`, `MAIL_FROM`; cờ `app.mail.enabled`.

- `enabled=false` (mặc định dev): chỉ `log.info("[MAIL] ...")` tiêu đề và người nhận, **không log nội dung OTP**.
- `enabled=true`: gửi SMTP thật. Thiếu `MAIL_HOST` mà bật cờ thì **không khởi động** (cùng tinh thần BE-32).
- Nhà cung cấp: dùng SMTP chung nên đổi được. Demo: Gmail với mật khẩu ứng dụng hoặc gói miễn phí của Brevo / Resend; **kiểm lại hạn mức gửi mỗi ngày của gói hiện hành** trước khi chọn. Chạy thật cần tên miền riêng với SPF / DKIM, nếu không mail vào thư rác.

## 3. Danh sách mail (P0 mục 2)

Mail giao dịch, **không có tuỳ chọn tắt** (đây là căn cứ để phạt). Không có mail quảng cáo.

| Sự kiện | Gửi cho | Có hạn? |
|---|---|---|
| Thắng đấu giá, hoá đơn 48 giờ (`AUCTION_WON`) | Người thắng | **Có**, ghi giờ hạn |
| Nhắc 24 giờ trước hạn thanh toán hoá đơn | Người thắng | Có |
| Mời mua lần hai (24 giờ) | Người về nhì | Có |
| Bị phạt và cấm đấu giá, có nợ | Người vi phạm | |
| Shop sắp quá hạn giao (24 giờ trước) và yêu cầu huỷ chờ trả lời | Shop | Có |
| Đơn bị tự huỷ vì shop ngâm | Người mua, shop | |
| Lô không bán, chọn hướng xử lý (nhắc 24 giờ trước hạn 7 ngày) | Người ký gửi | Có |
| Đề xuất giá sau kiểm định (7 ngày) | Người ký gửi | Có |
| Sách sắp thanh lý (7 ngày trước ngày 60) | Người ký gửi | Có |
| Rút tiền được duyệt / bị từ chối | Người rút | |
| Tài khoản bị khoá / mở khoá | Người đó | |
| Tiền bán hàng đang bị giữ và ngày giải phóng (mục 6) | Shop | |

Cách gắn: thêm một `Set<String>` loại thông báo cần mail trong `NotificationService`. Loại hiện có chưa phân biệt đủ (ví dụ `ORDER` dùng chung cho nhiều việc), nên các chỗ gọi `notify` ở bảng trên truyền thêm cờ `emailed=true` thay vì đoán theo loại. Việc sửa là thêm một tham số hoặc một overload, không đổi chữ ký 21 chỗ gọi cũ.

### Luật đi kèm: mail không tới thì không phạt

Căn cứ BE-36 và [NGHIEP_VU.md mục 5](NGHIEP_VU.md#5-đấu-giá). Khi hoá đơn đấu giá quá hạn, **trước khi phạt**:

1. Nếu mail `AUCTION_WON` của hoá đơn đó ở trạng thái `FAILED` hoặc chưa `SENT` **và** người dùng chưa đọc thông báo `AUCTION_WON` trong app (`notifications.read=false`): **không phạt, không cấm**, gia hạn hoá đơn thêm 24 giờ một lần, báo Admin.
2. Ngược lại phạt như hiện nay.

"Mail SENT" nghĩa là SMTP nhận, không chứng minh người đó đã đọc; chủ sàn cần chấp nhận mức bằng chứng này (câu hỏi 3).

## 4. OTP bằng email (P0 mục 3, phần làm được)

- `issueOtp` gửi mail **trực tiếp sau commit**, không qua outbox, để mã không nằm trong bảng. Gửi lỗi thì trả `EMAIL_SEND_FAILED` (503), người dùng bấm gửi lại.
- **Gỡ `log.info("[OTP] ...")`** (nhóm 1 đã ghi trong tài liệu). `devOtp` chỉ còn khi `expose-in-response=true` (profile dev).
- **Giới hạn xin OTP** (BE-26 phần còn lại), dùng `RateLimiter` có sẵn: cách nhau ≥ 60 giây; tối đa 5 mã / giờ / tài khoản; tối đa 10 mã / ngày / địa chỉ email. Vượt thì `TOO_MANY_REQUESTS`.
- **Không làm bằng mail:** OTP SMS cho số điện thoại và CCCD. `phoneVerified` hiện chỉ là cờ tự xác nhận; đấu giá vẫn đòi nó, nên điều kiện này **vẫn chưa có giá trị** cho tới khi có nhà cung cấp SMS (tách việc, xem câu hỏi 2). Giao diện `OtpSender { send(user, purpose, code) }` chỉ cần khi có SMS; **bản đầu không tạo**, `AuthService` gọi thẳng `MailService`.
- **Chặn lách bằng email biến thể** (rẻ, làm cùng): chuẩn hoá email khi đăng ký (chữ thường; với `gmail.com` bỏ dấu chấm và phần sau `+`), thêm cột `email_normalized` UNIQUE. Không chống được người có nhiều hộp thư thật; chỉ chặn trò `a+1@gmail.com`.

## 5. Chống lạm dụng và riêng tư

- Mail OTP và thông báo chỉ gửi tới email **đã xác thực** (`emailVerified`), trừ chính mail OTP xác thực email.
- Không đưa số tài khoản ngân hàng, CCCD, mật khẩu, hay đường dẫn tới ảnh biên lai vào nội dung mail.
- Nội dung chỉ có tiêu đề việc, mã đơn / lô, số tiền, hạn, và một đường dẫn vào app (`APP_URL` đã có). Không có liên kết đăng nhập sẵn.
- Ghi `audit_events`: `MAIL.SENT`, `MAIL.FAILED` (địa chỉ chỉ ở dạng băm, như các sự kiện hiện có).

## 6. P0 mục 4: luật ví (không phải mail)

Đây là thiết kế sơ bộ, **cần chủ sàn quyết trước khi làm**:

- **Giữ tiền bán của shop mới:** shop dưới `shop.new_hold_orders` (mặc định 10) đơn hoàn tất, hoặc tạo dưới 30 ngày, thì tiền bán chỉ rút được sau `wallet.seller_hold_days` ngày (mặc định 7) kể từ lúc hoàn tất. Cùng cơ chế với khoá nạp 24 giờ hiện có (`TOPUP_LOCKED`): thêm khoản "tiền bán bị giữ đến ngày X" vào `GET /wallet/withdrawable`.
- **Chặn tự mua của mình qua tài khoản phụ:** từ chối đặt hàng khi số tài khoản ngân hàng đã khai của shop trùng với số đã khai ở yêu cầu rút của người mua. Chưa có IP / thiết bị nên chỉ làm được đối chiếu này.
- **Chargeback:** thêm loại nợ `CHARGEBACK` vào `account_debts` (đã có, đã chặn rút / đăng ký / trả giá); Admin ghi tay khi ngân hàng đòi tiền; tiền bán của shop liên quan bị khoá. Không có luồng tự động.
- Mail cho mục này: một thư "tiền đang giữ đến ngày X" (dòng cuối bảng mục 3).

## 7. Kiểm thử

Không thêm thư viện: test dùng một bean `JavaMailSender` giả ghi lại thư.

- Thắng đấu giá → có một dòng outbox; job chạy → gửi một thư; chạy lại không gửi trùng (`dedupe_key`).
- SMTP lỗi → `attempts` tăng, `next_attempt_at` lùi; sau 5 lần `FAILED`; giao dịch tiền không bị ảnh hưởng.
- Giao dịch rollback → không có dòng outbox.
- Hoá đơn quá hạn khi mail `FAILED` và chưa đọc → không phạt, gia hạn 24 giờ một lần, báo Admin; khi mail `SENT` → phạt như cũ.
- OTP: nhận mã qua mail giả; xin lại trong 60 giây bị `TOO_MANY_REQUESTS`; log không chứa mã.
- Email `a.b+x@gmail.com` và `ab@gmail.com` không đăng ký được cả hai.

## 8. Thứ tự làm

1. `MailService` + cấu hình + OTP bằng email + giới hạn xin OTP + gỡ log OTP (mục 4). Làm được ngay, không cần quyết gì thêm ngoài chọn nhà cung cấp.
2. `email_outbox` + job + gắn vào `notify` cho các mail ở mục 3.
3. Luật "mail không tới thì không phạt".
4. Luật ví mục 6 (sau khi chủ sàn trả lời).

Frontend không phải đổi để mail chạy. Cần thêm: hiện mã lỗi `EMAIL_SEND_FAILED` và `TOO_MANY_REQUESTS` ở màn OTP; ghi chú trong `BACKEND_HANDOFF.md` nếu spec đổi.

## 9. Việc cần chủ sàn quyết

1. Nhà cung cấp SMTP cho demo và cho chạy thật, và có sẵn tên miền để cấu hình SPF / DKIM chưa.
2. OTP SMS và CCCD (mục 3 của P0): làm riêng bằng dịch vụ ngoài, hay chấp nhận email là định danh duy nhất ở bản đồ án.
3. Luật "mail không tới thì không phạt" ở mục 3: chấp nhận "SMTP đã nhận" làm bằng chứng đã báo hay không.
4. Các con số ở mục 6 (10 đơn, 30 ngày, 7 ngày) và có làm chặn trùng số tài khoản ngân hàng hay không.
