# Thiết kế ghi log ReBook (BA)

Ngày 2026-11-05. Mục tiêu: **mọi việc có ý nghĩa nghiệp vụ hoặc bảo mật đều để lại dấu vết, theo một khuôn duy nhất**, truy ngược được "ai, làm gì, lên cái gì, kết quả ra sao, lúc nào, từ đâu".
Đây là tài liệu thiết kế, chưa có code. Liên quan: [AUDIT_BACKEND.md](AUDIT_BACKEND.md) (mục 9 bên dưới ghi log nào giúp phát hiện lỗi nào).

## 1. Hiện trạng (đọc từ code)

| Có | Thiếu / sai |
|---|---|
| `admin_activity_logs` (10 chỗ gọi `activityLog.record`): duyệt / từ chối tin, duyệt / từ chối rút tiền, khoá / mở khoá, đổi vai trò, gỡ cấm đấu giá, shop uy tín, đổi cấu hình | Chỉ ghi thao tác **Admin**. Không có đăng nhập, OTP, đổi mật khẩu, mở shop, đổi tài khoản ngân hàng, ký gửi, kiểm định, tạo phiên, tạo đơn... |
| Các bảng lịch sử riêng: `wallet_transactions` (sổ cái), `order_status_history`, `bids`, `payments.raw_callback` | Mỗi bảng một khuôn, không có cột chung (request id, IP, vai trò người làm). Ký gửi, lô, phiên, đăng ký đấu giá **không có lịch sử trạng thái** |
| 23 dòng `log.info/warn/error/debug` ở 10 file | Văn bản tự do tiếng Việt, không mã sự kiện, không `requestId`, không `userId`; lỗi lặp (vừa log vừa ném); **`AuthService.java:168` ghi OTP nguyên văn và email ra log** |
| Lệnh bị từ chối (403, 429, sai OTP) | Không được ghi. Bài học: bộ đếm OTP sai từng bị mất vì ghi chung giao dịch với lỗi rồi bị rollback |

## 2. Nguyên tắc

1. **Một cửa**: mọi sự kiện nghiệp vụ đi qua một lớp `AuditLog.record(...)` với **mã sự kiện** lấy từ một danh mục cố định (mục 5). Không ghi log nghiệp vụ bằng `log.info("...")` tự do.
2. **Cùng giao dịch với việc nghiệp vụ**: việc thành công thì log commit cùng, việc lỗi thì log rollback cùng (không có log "ma").
3. **Việc bị từ chối cũng phải ghi**, trong giao dịch riêng (`REQUIRES_NEW`), vì giao dịch chính sẽ rollback.
4. **Chỉ thêm, không sửa, không xoá** (giống sổ cái ví). Sai thì ghi sự kiện đính chính.
5. **Không ghi bí mật**: mục 6.
6. **Tiền** luôn là số nguyên VNĐ (chuỗi), kèm trước / sau khi có thay đổi.
7. **Mọi dòng log truy ngược được về một yêu cầu**: có `requestId`, trả cùng id trong header `X-Request-Id` và trong `ErrorResponse` để người dùng báo lỗi chỉ cần đọc mã.

## 3. Ba lớp log

| Lớp | Là gì | Lưu ở đâu | Ai đọc | Giữ bao lâu (đề xuất) |
|---|---|---|---|---|
| **A. Kiểm toán nghiệp vụ** | Sự kiện đã xảy ra với dữ liệu nghiệp vụ (đơn, tiền, tin, phiên, ký gửi, tài khoản) | Bảng `audit_events` (mới) | Admin (màn Nhật ký), đối soát, giải quyết khiếu nại | 5 năm với sự kiện tiền; 2 năm còn lại (**chủ sàn và pháp lý chốt**) |
| **B. Bảo mật** | Đăng nhập, OTP, khoá, đổi quyền, đổi ngân hàng, bị chặn (429 / 403) | Cùng bảng `audit_events`, `category = SECURITY` | Admin, người trực | 2 năm |
| **C. Kỹ thuật** | Lỗi hệ thống, job, hiệu năng, kết nối cổng thanh toán | File / stdout, **JSON một dòng**, đẩy lên công cụ thu log | Dev, vận hành | 30 ngày |

Các sổ chuyên biệt **giữ nguyên** (`wallet_transactions`, `order_status_history`, `bids`): đó là dữ liệu nghiệp vụ, không phải log. Mỗi dòng sổ đều có một sự kiện lớp A trỏ tới (`details.ledgerId`), và thêm cột `request_id` vào `wallet_transactions` để nối hai bên.
`admin_activity_logs` được **gộp vào `audit_events`** (migration chép dữ liệu cũ). API `GET /admin/activity-logs` giữ nguyên hình dạng trả về để màn Nhật ký không đổi.

## 4. Khuôn dữ liệu chung

Bảng `audit_events` và dòng JSON của lớp C dùng **cùng tên trường**:

| Trường | Kiểu | Ví dụ | Ghi chú |
|---|---|---|---|
| `occurredAt` | UTC, ISO-8601 | `2026-11-05T09:31:02.114Z` | Luôn UTC, hiển thị mới đổi múi giờ |
| `eventCode` | chuỗi | `ORDER.STATUS.CHANGED` | `MODULE.ĐỐI_TƯỢNG.HÀNH_ĐỘNG`, chữ hoa, tiếng Anh |
| `category` | enum | `BUSINESS` / `SECURITY` / `FINANCE` / `SYSTEM` | Dùng để lọc và đặt thời gian giữ |
| `result` | enum | `SUCCESS` / `DENIED` / `FAILED` | `DENIED` = bị luật chặn; `FAILED` = lỗi hệ thống |
| `reasonCode` | chuỗi | `BAD_CREDENTIALS`, `PRICE_CHANGED` | Dùng đúng `ErrorResponse.code` của API |
| `actorType` | enum | `USER` / `STAFF` / `ADMIN` / `SYSTEM` / `GATEWAY` | `SYSTEM` = job tự động, `GATEWAY` = callback ZaloPay |
| `actorId`, `actorRole` | số, enum | `42`, `USER` | `null` khi chưa đăng nhập; vai trò **lấy lúc thao tác** |
| `targetType`, `targetId` | chuỗi | `ORDER`, `1187` | Đối tượng chính bị tác động |
| `refCode` | chuỗi | `OD2611051234` | Mã nghiệp vụ người dùng nhìn thấy (đơn, thanh toán, ký gửi), để tìm bằng mã |
| `requestId` | UUID | `9f0c…` | Một yêu cầu HTTP / một lần chạy job / một sự kiện WS |
| `channel` | enum | `API` / `JOB` / `WS` / `CALLBACK` | |
| `ip`, `userAgent` | chuỗi | `203.0.113.7` | Chỉ với `channel = API / WS`; User-Agent cắt 120 ký tự |
| `summary` | chuỗi ≤ 500 | "Duyệt tin 'Số Đỏ' của shop X" | Tiếng Việt, **chỉ để hiển thị cho người**; không phân tích máy từ trường này |
| `details` | JSON | `{"from":"PREPARING","to":"SHIPPING"}` | Dữ liệu có cấu trúc: trước / sau, số tiền, tham số. Khoá tên camelCase |

Ví dụ một dòng lớp C (JSON) và một dòng lớp A cho cùng sự kiện:
```json
{"ts":"2026-11-05T09:31:02.114Z","level":"INFO","eventCode":"ORDER.DELIVERY.MARKED","result":"SUCCESS","actorType":"USER","actorId":42,"actorRole":"USER","targetType":"ORDER","targetId":1187,"refCode":"OD2611051234","requestId":"9f0c…","channel":"API","details":{"simulated":true,"shipToDeliverSec":2}}
```
Cột `details.simulated = true` và `shipToDeliverSec` (khoảng cách giữa "giao cho shipper" và "giao thành công") là thứ cho phép phát hiện lỗi BE-04.

## 5. Danh mục sự kiện

Cột "Ghi" : **A** = `audit_events`, **C** = chỉ log kỹ thuật, **L** = đã có sổ riêng, vẫn thêm một dòng A trỏ tới. Cột "Bắt buộc có trong `details`" là tối thiểu.
Mọi sự kiện đều có đủ trường chung ở mục 4; bảng chỉ ghi phần riêng.

### 5.1 Xác thực và tài khoản (SECURITY)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `AUTH.REGISTER.SUCCESS` | Đăng ký xong | A | `emailDomain` (không ghi email đầy đủ ở lớp C) |
| `AUTH.LOGIN.SUCCESS` | Đăng nhập đúng | A | `method` |
| `AUTH.LOGIN.FAILED` | Sai mật khẩu / email không tồn tại / tài khoản khoá | A | `reasonCode`, `failuresInWindow`. **Không phân biệt "email không tồn tại" và "sai mật khẩu" ở `reasonCode`** (giống phản hồi cho người dùng) |
| `AUTH.LOGIN.THROTTLED` | Bị 429 do sai quá nhiều | A | `key` (email băm), `retryAfterSec` |
| `AUTH.TOKEN.REFRESHED` / `AUTH.TOKEN.REFRESH_FAILED` | Đổi refresh token | A | `reasonCode` khi lỗi |
| `AUTH.LOGOUT` | Đăng xuất | A | |
| `AUTH.OTP.SENT` | Gửi OTP | A | `purpose`, `channel`, `recipientMasked` — **không ghi mã** |
| `AUTH.OTP.VERIFIED` / `AUTH.OTP.FAILED` / `AUTH.OTP.LOCKED` | Nhập OTP | A | `purpose`, `attempt` |
| `AUTH.PASSWORD.RESET_REQUESTED` / `AUTH.PASSWORD.RESET` / `AUTH.PASSWORD.CHANGED` | Quên / đổi mật khẩu | A | `revokedTokens` |
| `USER.PROFILE.UPDATED` | Đổi họ tên, SĐT, ảnh | A | `changedFields`; đổi SĐT thì ghi `phoneVerifiedReset=true` |
| `USER.ADDRESS.ADDED` / `.UPDATED` / `.DELETED` | Sổ địa chỉ | A | `addressId`, `province` |
| `USER.SHOP.OPENED` / `USER.SHOP.UPDATED` | Mở / sửa shop | A | `bankChanged` (đổi ngân hàng là sự kiện nhạy cảm) |
| `USER.LOCKED` / `USER.UNLOCKED` / `USER.ROLE.CHANGED` / `USER.AUCTION_BAN.SET` / `USER.AUCTION_BAN.LIFTED` / `SHOP.TRUSTED.CHANGED` | Admin tác động tài khoản, hoặc hệ thống cấm đấu giá | A | `reason`, `before`, `after`, `until` |
| `ACCESS.DENIED` | 401 / 403 trên đường dẫn nhạy cảm (`/admin`, `/staff`, ví, rút tiền) | A | `path`, `method`, `requiredRole` |

### 5.2 Tin đăng và danh mục (BUSINESS)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `LISTING.CREATED` / `LISTING.UPDATED` | Đăng, sửa tin | A | `priceBefore`, `priceAfter`, `stockBefore`, `stockAfter`, `changedFields` (cần cho BE-12) |
| `LISTING.HIDDEN` / `LISTING.SHOWN` | Ẩn / hiện | A | |
| `LISTING.REVIEW.SUBMITTED` / `.APPROVED` / `.REJECTED` | Chờ duyệt, Admin duyệt / từ chối | A | `reason`, `autoApproved` |
| `STOCK.RESERVED` / `STOCK.RESTORED` | Giữ hàng khi đặt, hoàn khi huỷ / trả | A | `listingId`, `qty`, `orderCode`, `stockAfter` |
| `CATEGORY.CREATED` / `.UPDATED` / `.DELETED` | Quản lý danh mục | A | `before`, `after` |

### 5.3 Đơn hàng (BUSINESS)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `ORDER.CHECKOUT.CREATED` | Tạo một lần đặt (nhiều đơn) | A | `orderCodes`, `total`, `paymentMethod`, `idempotencyKey` |
| `ORDER.STATUS.CHANGED` | **Mọi** lần đổi trạng thái (đi qua `OrderService.transition`) | L + A | `from`, `to`, `note`; `actorType = SYSTEM` khi do job |
| `ORDER.SHIPPED` | Giao cho vận chuyển | A | `trackingCode`, `trackingProvided` (true nếu người dùng tự nhập) |
| `ORDER.DELIVERY.MARKED` | Bấm giao thành công / thất bại | A | `outcome`, `simulated`, `shipToDeliverSec` |
| `ORDER.CANCEL.REQUESTED` / `.ANSWERED` | Yêu cầu huỷ khi đã chuẩn bị, shop trả lời | A | `reason`, `approved` |
| `ORDER.RETURN.REQUESTED` / `.ANSWERED` / `.ESCALATED` / `.RESOLVED` | Vòng đời trả hàng | A | `reason`, `imageCount`, `approved`, `refundAmount`, `resolvedBy` |
| `ORDER.REVIEW.CREATED` | Đánh giá | A | `rating` |

### 5.4 Thanh toán, ví, rút tiền (FINANCE)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `PAYMENT.CREATED` | Tạo thanh toán | A | `paymentCode`, `purpose`, `method`, `amount`, `expiresAt` |
| `PAYMENT.CALLBACK.RECEIVED` | Cổng gọi về hoặc người dùng quay về | A | `source` (`CALLBACK` / `RETURN` / `POLL`), `signatureValid`, `amount`, `gatewayRef`. **Không ghi `data`/`mac` thô** (chỉ lưu `payments.raw_callback`) |
| `PAYMENT.SUCCEEDED` / `PAYMENT.FAILED` / `PAYMENT.EXPIRED` | Kết quả cuối | A | `paymentCode`, `amount`, `gatewayTxnId` |
| `PAYMENT.SIMULATED` | Gọi `/payments/{code}/simulate` | A (**category SECURITY**) | `paymentCode`, `purpose`, `amount` (cần cho BE-32) |
| `PAYMENT.LATE_REFUND` | Tiền về muộn, hoàn vào ví | A | `orderCode`, `amount`, `reason` |
| `WALLET.TX.POSTED` | Mỗi dòng sổ cái ví | L + A | `ledgerId`, `type`, `availableChange`, `heldChange`, `availableAfter`, `heldAfter`, `refType`, `refId` |
| `WITHDRAW.REQUESTED` | Tạo yêu cầu rút | A | `amount`, `bankName`, `accountMasked`, `balanceSource` (nạp / bán hàng, cần cho BE-02) |
| `WITHDRAW.APPROVED` / `WITHDRAW.REJECTED` | Admin duyệt / từ chối | A | `amount`, `transferTime`, `proofImageUrl`, `note` |
| `BANKACCOUNT.ADDED` / `.CHANGED` | Thêm / đổi tài khoản nhận tiền | A (SECURITY) | `bankName`, `accountMasked`, `minutesSinceLastLogin` |
| `RECONCILE.RUN` | Job đối soát đêm (BE-06) | A | `walletTotal`, `expectedTotal`, `diff` |

### 5.5 Đấu giá (BUSINESS / FINANCE)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `SESSION.CREATED` / `.UPDATED` / `.PUBLISHED` / `.CONFIRMED` / `.POSTPONED` / `.STARTED` / `.PAUSED` / `.RESUMED` / `.ENDED` / `.CANCELLED` | Mọi bước vòng đời phiên | A | `from`, `to`, `registered`, `minParticipants`, `reason` |
| `LOT.ASSIGNED` / `.OPENED` / `.CLOSED` / `.CANCELLED` / `.RESET` | Vòng đời lô | A | `sessionId`, `lotNumber`, `result`, `hammerPrice`, `bidCount`; **không ghi `reservePrice` ở lớp C** |
| `REGISTRATION.CREATED` / `.DEPOSIT_ADDED` / `.REFUNDED` / `.APPLIED` / `.FORFEITED` | Đăng ký và cọc | A + L | `paddle`, `deposit`, `bidLimit`, `reason` |
| `BID.PLACED` | Trả giá thành công | A | `lotId`, `amount`, `isAuto`, `previousLeaderId`, `endsAtBefore`, `endsAtAfter`, `softCloseExtended` |
| `BID.REJECTED` | Trả giá bị chặn | A | `lotId`, `amount`, `reasonCode` (`PRICE_CHANGED`, `ALREADY_LEADING`, `BID_LIMIT_EXCEEDED`, `LOT_NOT_OPEN`...) — dùng khi người dùng khiếu nại "bấm mà không ăn" |
| `PROXY.SET` / `PROXY.CANCELLED` | Giá tối đa tự động | A | `lotId`, `maxAmount` |
| `INVOICE.CREATED` / `INVOICE.OVERDUE` | Hoá đơn lô thắng; quá hạn | A | `orderCode`, `hammer`, `buyerPremium`, `shipping`, `depositApplied`, `dueAt` |
| `SECONDCHANCE.OFFERED` / `.DECLINED` / `.EXPIRED` | Mời mua lần hai | A | `runnerUpAmount`, `reserveMet` |

### 5.6 Ký gửi và kho (BUSINESS)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `CONSIGN.CREATED` / `.REVIEWED` / `.APPOINTMENT_BOOKED` / `.EXPIRED` / `.WITHDRAWN` | Giai đoạn A | A | `expectedPrice`, `approved`, `reviewNote`, `appointmentAt` |
| `CONSIGN.RECEIVED` | Staff nhận sách | A | `receivedBy`, `shelfCode`, `photoCount` |
| `CONSIGN.INSPECTED` | Kiểm định | A | `result`, `estimateLow/High`, `proposedStart`, `proposedReserve`, `conditionGrade` |
| `CONSIGN.SELLER_DECIDED` | Người bán chấp nhận / thương lượng / rút | A | `decision`, `counterReserve`, `agreedTerms` |
| `CONSIGN.UNSOLD_DECIDED` | Quyết định với lô không bán | A | `action`, `newReserve`, `listingPrice` |
| `WAREHOUSE.SHELF.CHANGED` / `.CHECKED_OUT` / `.RETURNED_TO_SELLER` | Kho | A | `from`, `to`, `reason`, `storageFee` |
| `WAREHOUSE.INCIDENT` | Mất / hỏng sách (cho BE-24 khi làm) | A | `severity`, `description` |

### 5.7 Cấu hình, tệp, hệ thống
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `CONFIG.UPDATED` | Admin đổi cấu hình | A | `key`, `before`, `after` (cần cho BE-05: biết đổi phí lúc nào) |
| `FILE.UPLOADED` / `FILE.REJECTED` | Tải ảnh | A | `size`, `contentType`, `purpose`, `reasonCode` |
| `JOB.RUN` | Mỗi lần chạy job **có xử lý ≥ 1 mục**, hoặc có lỗi | C | `job`, `durationMs`, `processed`, `failed`. Không log các lần chạy rỗng |
| `JOB.ITEM.FAILED` | Một mục của job lỗi | C (ERROR) | `job`, `itemId`, `exception` |
| `REQUEST.ERROR` | Lỗi 5xx | C (ERROR) | `status`, `path`, `exception`; ghi **một lần duy nhất ở `GlobalExceptionHandler`** |
| `NOTIFICATION.SENT` / `NOTIFICATION.FAILED` | Gửi thông báo (app, FCM, email, SMS khi có) | C | `type`, `channel`, `recipientId` |

## 6. Cái gì không bao giờ được ghi

| Không ghi | Thay bằng |
|---|---|
| Mật khẩu, hash mật khẩu, JWT, refresh token | Không ghi gì; chỉ `AUTH.*` với `tokenId` nếu cần |
| **Mã OTP** (hiện đang ghi ở `AuthService.java:168`) | `AUTH.OTP.SENT` với người nhận đã che. Môi trường dev vẫn cần xem mã: đọc bằng cờ `expose-in-response`, không qua log |
| Số tài khoản ngân hàng đầy đủ | `accountMasked` = 4 số cuối |
| Email, SĐT, họ tên ở lớp C | `userId`. Lớp A cho phép `summary` có tên hiển thị (dữ liệu nội bộ, quyền xem hạn chế) |
| Khoá ZaloPay, `mac`, `data` thô của callback | `signatureValid`, `amount`, `gatewayRef`. Dữ liệu thô chỉ nằm ở `payments.raw_callback` |
| Giá sàn (`reservePrice`) của lô | Chỉ ở lớp A và chỉ Admin xem; không ra response, không ra log kỹ thuật |
| Nội dung ảnh, mô tả dài | Chỉ URL / kích thước |

## 7. Mức log kỹ thuật (lớp C)

| Mức | Dùng cho |
|---|---|
| `ERROR` | Lỗi hệ thống cần người xử lý: 5xx, job lỗi, cổng thanh toán không phản hồi, ví không khớp sổ cái |
| `WARN` | Bất thường nhưng đã tự xử lý: thanh toán về muộn, proxy bid dừng sau 50 vòng, callback sai chữ ký, bị 429 liên tục |
| `INFO` | Ranh giới nghiệp vụ lớn và tóm tắt job (mỗi sự kiện một dòng, không lặp) |
| `DEBUG` | Chi tiết chẩn đoán; chỉ bật ở dev. Production mặc định `INFO` |

Quy tắc: **một lỗi chỉ log một lần**, ở nơi bắt cuối cùng; không `log.error` rồi `throw` ở tầng dưới.

## 8. Cảnh báo (rút từ log)

| Điều kiện | Dựa vào | Ý nghĩa |
|---|---|---|
| ≥ 20 `AUTH.LOGIN.FAILED` / phút từ một IP hoặc ≥ 10 / 15 phút một email | lớp B | Dò mật khẩu / khoá tài khoản người khác (BE-42) |
| ≥ 1 `PAYMENT.SIMULATED` ở môi trường production | lớp B | Cấu hình dev lọt ra production (BE-32), **cảnh báo tức thì** |
| `ORDER.DELIVERY.MARKED` với `simulated = true` ở production | lớp A | Người bán tự đánh dấu giao (BE-04) |
| `WITHDRAW.REQUESTED` có `balanceSource = TOPUP` và nạp cách < 24h | lớp A | Nạp rồi rút (BE-02) |
| `BANKACCOUNT.ADDED` rồi `WITHDRAW.REQUESTED` trong 10 phút | lớp A | Chiếm tài khoản rồi rút |
| `RECONCILE.RUN` có `diff ≠ 0` | lớp A | Ví lệch sổ (BE-06, BE-01) |
| `PAYMENT.CALLBACK.RECEIVED` với `signatureValid = false` | lớp A | Giả mạo callback |
| `JOB.RUN` có `failed > 0` hoặc `AuctionEngine` tick > 1 giây | lớp C | Phiên đấu giá có nguy cơ treo |
| `ORDER.STATUS.CHANGED` ở `PREPARING` quá hạn bàn giao | lớp A | Đơn ngâm (BE-07) |

## 9. Mỗi lỗi trong báo cáo audit cần log gì
| Lỗi | Sự kiện cần có |
|---|---|
| BE-01 COD | `ORDER.STATUS.CHANGED → COMPLETED` với `paymentMethod = COD` và `WALLET.TX.POSTED` tương ứng, để đối soát COD |
| BE-02 nạp rồi rút | `WITHDRAW.REQUESTED.balanceSource`, `BANKACCOUNT.ADDED` |
| BE-03 trả hàng | `ORDER.RETURN.*` có `refundAmount`, `STOCK.RESTORED` |
| BE-04 / FE-12 | `ORDER.DELIVERY.MARKED.simulated`, `shipToDeliverSec` |
| BE-05 phí đổi giữa chừng | `CONFIG.UPDATED` + lưu `feeRate` vào `details` của `ORDER.STATUS.CHANGED → COMPLETED` |
| BE-12 đổi giá | `LISTING.UPDATED.priceBefore/After`, `ORDER.CHECKOUT.CREATED` có giá người mua thấy |
| BE-17 cọc | `REGISTRATION.APPLIED / FORFEITED`, `INVOICE.OVERDUE` |
| BE-25 thông đồng đẩy giá | `BID.PLACED` có `ip`, `userAgent` |
| BE-26, BE-42 | `AUTH.LOGIN.*`, `AUTH.OTP.*` |
| BE-32 | `PAYMENT.SIMULATED` |
| BE-35 | `ACCESS.DENIED` có `reasonCode` riêng |

## 10. Lộ trình làm

Làm theo thứ tự này, mỗi bước chạy độc lập được:

| Bước | Việc | Phụ thuộc | Ghi chú |
|---|---|---|---|
| 1 | Bộ lọc gán `requestId` (đọc / sinh `X-Request-Id`), đưa vào `MDC` cùng `userId`, `role`, `ip`; thêm `requestId` vào `ErrorResponse`; cấu hình log JSON (Logback) | — | Nhỏ, có tác dụng ngay |
| 2 | **Gỡ OTP khỏi log** (`AuthService.java:168`), che email / tài khoản ngân hàng trong mọi `log.*` còn lại | — | Làm ngay, là lỗi bảo mật |
| 3 | Migration `V9`: bảng `audit_events` (cột như mục 4, chỉ INSERT: tạo role DB không có UPDATE / DELETE), chép dữ liệu `admin_activity_logs`; lớp `AuditLog` + enum `EventCode`; `record` (cùng giao dịch) và `recordDenied` (`REQUIRES_NEW`) | 1 | Giữ `GET /admin/activity-logs` trả cùng hình dạng |
| 4 | Gắn vào `OrderService.transition`, `WalletService.move`, `PaymentService`, `AuthService` (bảo mật), `BidService` | 3 | Chỗ tập trung nên ít chỗ phải sửa: `transition` và `move` là hai cửa duy nhất |
| 5 | Gắn nốt: ký gửi, kho, phiên, lô, đăng ký, tin, cấu hình, tệp | 3 | |
| 6 | Job `RECONCILE.RUN` và các cảnh báo mục 8 | 4, 5 | Cần công cụ thu log; nếu chưa có thì cảnh báo bằng truy vấn định kỳ trên `audit_events` |
| 7 | Màn Nhật ký của Admin: lọc theo `category`, `eventCode`, `refCode`, `requestId` | 3 | Phần frontend (khi cần) |

Kiểm thử cho mỗi bước: (a) một test duyệt qua mọi `EventCode` đảm bảo có trong danh mục tài liệu này; (b) test "việc bị từ chối vẫn có dòng log" (đăng nhập sai, trả giá thấp); (c) test "log không chứa bí mật" (chạy luồng OTP, chụp output, khẳng định không có mã).

## 11. Câu hỏi cần chủ sàn chốt
1. **Thời gian giữ** từng lớp (mục 3 mới là đề xuất; sự kiện tiền thường do luật kế toán quy định).
2. Có cho **người dùng xem lịch sử hoạt động của chính mình** (đăng nhập, đổi mật khẩu, rút tiền) không? Đề xuất: có, đủ cho phát hiện chiếm tài khoản; cần thêm một API đọc `audit_events` theo `actorId`.
3. Có **gộp** `admin_activity_logs` vào `audit_events` (đề xuất) hay giữ hai bảng?
4. Công cụ thu log lớp C: dùng gì (file xoay vòng, ELK, dịch vụ đám mây)? Quyết định ảnh hưởng bước 6.
5. Có ghi **IP** người dùng không? Cần cho BE-25 nhưng là dữ liệu cá nhân, cần thông báo trong chính sách bảo mật.

## 12. Trạng thái triển khai (cập nhật 2026-11-05)

Đã làm (bước 1, 3 và một phần bước 4 của mục 10):
- Migration `V9__money_rules.sql` tạo bảng `audit_events` (chưa tạo role DB không có UPDATE / DELETE).
- `audit/AuditLog` (`record` cùng giao dịch, `recordDenied` giao dịch riêng), `audit/EventCode` (danh mục mã đã gắn), `audit/AuditEvent`, `audit/RequestIdFilter` (gán `X-Request-Id`, IP vào MDC).
- Mã sự kiện đã gắn vào code: `WALLET.TX.POSTED` (mọi dòng sổ cái, trong `WalletService.move`), `WITHDRAW.REQUESTED`, `WITHDRAW.BLOCKED`, `ORDER.CHECKOUT.CREATED`, `ORDER.STATUS.CHANGED` (mọi lần đổi trạng thái đơn), `ORDER.DELIVERY.MARKED / CONFIRMED / AUTO`, `ORDER.RETURN.APPROVED / SHIPPED / RECEIVED / EXPIRED / ESCALATED`, `COD.BLOCKED / REMITTED / PAID_OUT / REFUND_PENDING / REFUNDED`, `RECONCILE.RUN / MISMATCH`.

Chưa làm: bước 2 (**gỡ OTP khỏi log**, `AuthService.java:168`), bước 5 (ký gửi, kho, phiên, lô, đăng ký, tin, cấu hình, tệp, xác thực), bước 6 (cảnh báo), bước 7 (màn Nhật ký), cấu hình log JSON, gộp `admin_activity_logs` vào `audit_events`, và `requestId` trong `ErrorResponse`. `admin_activity_logs` vẫn hoạt động song song, chưa đụng tới.

Bổ sung (luồng tiền đấu giá): `AUCTION.REGISTRATION.CANCELLED`, `AUCTION.DEFAULT.PENALIZED` (phạt bỏ thanh toán: giá búa, % phạt, phần thu từ cọc, phần thu từ ví hoặc ghi nợ), `AUCTION.LOT.AUTO_RETURNED`, `AUCTION.LOT.REINSPECTED`, `DEBT.CREATED`, `DEBT.COLLECTED`, `DEBT.WAIVED`, `WAREHOUSE.STORAGE_FEE.CHARGED`.

Bổ sung (đợt 2026-11-06): `ORDER.AUTO_CANCELLED` (quá hạn giao, shop không trả lời yêu cầu huỷ, hệ thống huỷ khi khoá tài khoản; có `reason`), `SHOP.TRUST.REVOKED`, `ACCOUNT.LOCK.CLEANUP` (số tin ẩn, đơn huỷ, đăng ký đấu giá hoàn cọc).

Bổ sung (đợt vá 2026-11-06): `AUTH.REGISTER.SUCCESS`, `AUTH.LOGIN.SUCCESS` / `AUTH.LOGIN.FAILED` / `AUTH.LOGIN.THROTTLED` (đăng nhập sai ghi băm email, không lưu email), `AUTH.OTP.SENT` / `AUTH.OTP.FAILED` / `AUTH.OTP.VERIFIED` (không ghi mã), `AUTH.PASSWORD.RESET_REQUESTED` / `AUTH.PASSWORD.RESET` / `AUTH.PASSWORD.CHANGED`, `USER.LOCKED` / `USER.UNLOCKED`, `USER.ROLE.CHANGED`, `SHOP.TRUST.CHANGED`, `CONFIG.UPDATED`, `FILE.UPLOADED` / `FILE.REJECTED`, `ACCESS.DENIED` (401/403 kèm `path`, `method`), `ORDER.DELIVERY.MARKED` dùng lại cho Staff đối chiếu hãng vận chuyển (đơn COD; chi tiết kết quả giao / thất bại nằm trong `details`). Nhắc việc trước hạn chỉ gửi thông báo, chưa có mã audit riêng. `AuditLog` có thêm `recordBy` / `recordDeniedBy` cho chỗ chưa có người đăng nhập trong ngữ cảnh. Còn nợ: gỡ OTP khỏi log (`AuthService.java:168`, nhóm 1), màn Nhật ký, cảnh báo tự động, role DB chỉ-INSERT.
