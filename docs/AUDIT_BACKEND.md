# Rà soát backend ReBook: lỗi business rule và vận hành

Ngày 2026-11-05. Đọc `apps/backend` đối chiếu SRS, mỗi mục đã được kiểm lại với code (có `file:dòng`). Chưa chạy test, chưa kiểm phân quyền từng controller.
Mức: **P0** mất tiền / sai tiền thật, hoặc hỏng cả hệ thống khi deploy · **P1** kẹt tiền, kẹt đơn, gian lận · **P2** thiếu cho vận hành thật.
Việc frontend đi kèm nằm ở [AUDIT_FRONTEND.md](AUDIT_FRONTEND.md) (mục "Việc đi kèm khi backend sửa").
Cột "Người nhận" và "Trạng thái" để nhóm tự điền; trạng thái trống = chưa sửa. Đường dẫn tính từ `apps/backend/src/main/java/com/rebook/`.

## Cập nhật sau khi pull (đến commit `6af440c`, 2026-11-05)

Đã đối chiếu 3 commit backend mới (`9d25426`, `1c04db7`, `1f69605`) với bảng này. Kết quả:

| Mục | Kết quả | Ghi chú |
|---|---|---|
| BE-26 | Sửa một phần | Chặn dò mật khẩu; sửa lỗi bộ đếm OTP bị rollback (lỗi này nặng hơn mô tả ban đầu: trước đó dò OTP vô hạn). Còn xin OTP mới không giới hạn, chưa gửi email / SMS |
| BE-33 | Sửa một phần | ISBN 10 / 13 ký tự, số tài khoản rút 6–19 chữ số. Còn cận trên giá / tồn kho, khoảng giá trị cấu hình |
| BE-42 | Mới | Khoá đăng nhập theo email có thể bị lợi dụng để khoá tài khoản người khác |
| BE-04 | Rõ hơn | Frontend đã bỏ điều kiện mock cho nút "Đã giao", giờ người bán thấy nút này ở mọi môi trường |
| BE-02 | Có quyết định | Nhóm chủ ý bỏ luật khớp họ tên khi rút tiền; các biện pháp khác vẫn chưa có |
| Các mục còn lại | Chưa đổi | Không có commit nào đụng tới |

Sửa ngoài danh sách audit (đáng ghi nhận): 405 thay cho 500 khi gọi sai phương thức; sơ duyệt ký gửi "Không đạt" bắt buộc lý do (`REASON_REQUIRED`); số người đăng ký của phiên đã kết thúc tính cả đăng ký đã hoàn cọc (`AuctionViews.COUNTED`). Lưu ý nhỏ cho mục cuối: nếu sau này thêm huỷ đăng ký (BE-18) thì người đã huỷ cũng thành `REFUNDED` và sẽ bị đếm vào số người đăng ký.

## Cập nhật 2: luồng tiền (2026-11-05, buổi tối)

Đã sửa BE-01 … BE-06 và BE-13 theo quyết định của chủ repo (xem `docs/SESSION_LOG_2026-11-05.md` mục B). **Đã chạy test: 64/64 đạt** (trừ `SeedDataTest` vì gắn cứng cổng 5432; thay bằng khởi động thử backend với dữ liệu mẫu, migration `V9` thành công). `apps/backend/openapi.yaml` đã xuất lại.
Migration `V9__money_rules.sql`; cấu hình mới có sẵn trong `system_configs`.

| Luật | Chi tiết |
|---|---|
| COD | Hãng vận chuyển thu hộ, sàn **đối soát**: Admin xác nhận đã nhận đúng số tiền (`POST /admin/cod/{orderId}/remit`, danh sách `GET /admin/cod/pending`). Shop chỉ nhận tiền khi đơn hoàn tất **và** sàn đã nhận tiền; trừ phí 5% trên tiền sách. Trả hàng COD chỉ hoàn ví người mua sau khi sàn đã nhận tiền. Hạn mức: 3.000.000đ/đơn, 500.000đ với người chưa có đơn hoàn tất; chặn COD khi có ≥ 2 đơn COD giao thất bại trong 90 ngày |
| Rút tiền | Tiền mới nạp chưa dùng bị khoá 24 giờ (`wallet.topup_hold_hours`, 0 = tắt); `GET /wallet/withdrawable`; hạn mức rút 20.000.000đ/ngày (`wallet.withdraw_daily_limit`); yêu cầu rút ghi số tiền nạp đang khoá (`topup_locked`) |
| Trả hàng | Shop/Admin đồng ý → trạng thái trả hàng `AWAITING_GOODS`, đơn vẫn `RETURN_REQUESTED` → người mua `POST /orders/{id}/return/shipment` → shop `POST /seller/orders/{id}/return-received` (kho: `/staff/orders/{id}/return-received`) → hoàn tiền. Quá 7 ngày không gửi hàng → `EXPIRED`, đơn hoàn tất; đã gửi mà shop không xác nhận 7 ngày → chuyển Admin. Tồn kho không tự cộng lại |
| Giao hàng | `/seller/orders/{id}/delivered` và `/delivery-failed` chỉ chạy khi `app.shipping.simulate-enabled=true` (dev/test), ngoài đó trả 403. Người mua xác nhận đã nhận ngay khi đơn đang giao; không bấm thì sau 7 ngày kể từ lúc giao shipper, hệ thống tự coi là đã giao |
| Phí | Phí sàn đơn thường chụp vào đơn lúc đặt; hoa hồng đấu giá chụp vào lô lúc người bán chấp nhận |
| Checkout | Khoá ví người mua đầu giao dịch đặt hàng, hai lần bấm không tạo hai bộ đơn |
| Đối soát | `WalletReconciliationJob` (3h sáng): mỗi ví phải bằng tổng sổ cái; cảnh báo đơn COD quá 7 ngày chưa đối soát |
| Ghi log | Bảng `audit_events` + `AuditLog` + `RequestIdFilter` (xem `LOGGING_DESIGN.md`); mọi dòng sổ cái ví, mọi lần đổi trạng thái đơn, COD, rút tiền, trả hàng, giao hàng đều có sự kiện |

Còn lại của nhóm tiền: BE-17 (cọc đấu giá), BE-22 (phí lưu kho trừ ví), đối soát tổng với ZaloPay, KYC khi rút tiền.

## Cập nhật 3: luồng tiền đấu giá (2026-11-05, đêm)

Phân tích và quy tắc đầy đủ ở [AUCTION_MONEY_FLOW.md](AUCTION_MONEY_FLOW.md). Đã sửa BE-15, BE-17, BE-18, BE-19, BE-20, BE-22 và chọn người về nhì hợp lệ. **Đã chạy test: 75/75 đạt** (trừ `SeedDataTest`); migration `V10` chạy tốt trên dữ liệu mẫu; `apps/backend/openapi.yaml` đã xuất lại.
Còn lại của đấu giá: BE-21 (chuyển bán thường do sàn giao hộ), BE-25 (thông đồng đẩy giá), người bị cấm vẫn giữ cọc ở phiên khác, sàn huỷ hoá đơn vì lỗi của sàn.

## Cập nhật 4: đợt thuần backend (2026-11-06)

Đã sửa BE-07, BE-08, BE-09, BE-27, BE-35, BE-41 và một phần BE-21. **Đã chạy test: 86/86 đạt** (trừ `SeedDataTest`); migration `V11` chạy tốt trên dữ liệu mẫu; spec API không đổi. Việc để sau (nhóm 1, việc cần làm cùng frontend, việc cần chủ repo quyết) ghi ở [BACKLOG_LATER.md](BACKLOG_LATER.md).

## A. Dòng tiền (làm trước)

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-01 | P0 | COD: khi hoàn tất, ví người bán được cộng `gross` dù sàn chưa nhận đồng nào (shop tự giao thì shop giữ tiền mặt rồi vẫn rút được ví). Hoàn trả COD cũng cộng ví người mua từ không có gì, người bán không bị trừ | `order/OrderSettlement.java:56-57`, `:67-70` | Đối soát COD với đơn vị vận chuyển, hoặc COD chỉ trừ phí vào công nợ shop; hạn mức COD cho tài khoản mới; phạt bom hàng (BE-10) | | Đã sửa, test đạt (COD đối soát, hạn mức, chặn bom hàng) |
| BE-02 | P0 | Nạp ví xong rút ngay: ví không phân biệt tiền nạp với tiền bán hàng, mọi user đều rút được, chỉ cần tối thiểu 50.000đ, không có tối đa. Không kiểm tên chủ tài khoản (nhóm đã chủ ý bỏ luật khớp họ tên ở đợt rollback, xem QA_FINDINGS #15; các biện pháp còn lại vẫn thiếu), không cần OTP khi đổi tài khoản ngân hàng | `wallet/WalletService.java:154-167`, `wallet/WalletDtos.java:36-42` | KYC + tên chủ tài khoản khớp; OTP và thời gian chờ khi thêm tài khoản ngân hàng mới; hạn mức rút/ngày; tiền nạp chỉ rút sau N ngày hoặc về đúng nguồn | | Sửa một phần: khoá tiền mới nạp 24h + hạn mức rút/ngày + gắn nguồn tiền. Chưa có KYC, OTP khi đổi tài khoản ngân hàng |
| BE-03 | P0 | Trả hàng không có bước hàng quay về: shop đồng ý hoặc Admin phán là hoàn tiền người mua và cộng lại tồn kho ngay. Người mua giữ cả sách lẫn tiền; tin bán lại một cuốn chưa về tay | `order/OrderService.java:409-424`, `:448-465`; `order/OrderSettlement.java:63-71` | Thêm `RETURN_SHIPPING` → `RETURN_RECEIVED`; quy định ai chịu ship trả; hoàn một phần; không tự lên bán lại | | Đã sửa, test đạt (trả hàng theo bước, không tự cộng tồn kho) |
| BE-04 | P0 | Shop tự gọi `ship` (mã vận đơn bỏ trống thì tự sinh) rồi `delivered` ngay, không chứng cứ giao. Đồng hồ 3 ngày chạy từ đó, hết hạn tự hoàn tất và trả tiền. **Sau pull:** frontend đã bỏ điều kiện `Env.useMock`, nên nút "Giả lập: đã giao thành công" hiện cho người bán ở mọi môi trường; comment nói "backend chỉ nhận ở môi trường dev" là sai, hai endpoint không có kiểm tra môi trường nào | `order/OrderManagementController.java:57-68`, `order/OrderService.java:347-369` | Webhook hãng vận chuyển (GHN/GHTK), hoặc mã vận đơn thật + thời gian tối thiểu giữa SHIPPING và DELIVERED | | Đã sửa, test đạt (tắt nút giả lập ngoài dev, người mua xác nhận, tự coi là đã giao sau 7 ngày). Chưa có hãng vận chuyển thật |
| BE-05 | P1 | Phí đọc cấu hình lúc hoàn tất, không lưu tỷ lệ lúc chốt. Admin đổi hoa hồng 15% → 25% thì hợp đồng ký gửi đã chấp nhận 15% bị tính 25%. Bước giá cũng đọc trực tiếp từ cấu hình, đổi giữa phiên là đổi luật | `order/OrderSettlement.java:59`, `auction/AuctionSettlement.java:274`, `system/SystemConfigService.java:83` | Lưu tỷ lệ phí vào đơn và hợp đồng ký gửi; chốt bước giá theo phiên | | Đã sửa, test đạt (phí đơn thường và hoa hồng đấu giá chụp lúc chốt). Bước giá vẫn đọc cấu hình trực tiếp |
| BE-06 | P2 | Không có job đối soát (tổng ví so với nạp − rút ± phí) và báo cáo công nợ sàn | toàn `src/main` (không có) | Job đối soát hằng đêm, cảnh báo khi lệch | | Sửa một phần: job đối soát ví với sổ cái hằng đêm. Chưa có đối soát tổng với cổng thanh toán |

## B. Đơn hàng

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-07 | P1 | Đơn `PREPARING` không có hạn; shop xác nhận rồi ngâm thì tiền người mua kẹt vô hạn | `order/OrderJobs.java:31-41` (chỉ có 4 job, không có job này) | Hạn bàn giao ship (vd 3 ngày) → tự huỷ, hoàn tiền, phạt shop | | Đã sửa, test đạt (quá 3 ngày không giao cho vận chuyển thì tự huỷ, hoàn tiền, tính lỗi shop) |
| BE-08 | P1 | Yêu cầu huỷ của người mua (đơn `PREPARING`) không có hạn shop trả lời | `order/OrderService.java:218-226` | Tự duyệt hoặc chuyển Admin sau 24h | | Đã sửa, test đạt (shop im lặng 24 giờ thì tự đồng ý huỷ) |
| BE-09 | P1 | Không có điểm uy tín người bán (huỷ đơn, trễ xác nhận, tỷ lệ trả hàng); `trusted` chỉ Admin bật tay và không bao giờ tự gỡ | `admin/AdminService.java:109`, `catalog/ListingService.java:226` | Chỉ số huỷ / trễ / trả hàng, tự gỡ `trusted` khi vượt ngưỡng | | Đã sửa, test đạt (tỷ lệ đơn lỗi ≥ 10% với tối thiểu 5 đơn trong 90 ngày thì gỡ uy tín shop) |
| BE-10 | P1 | Người mua bom hàng COD hoặc giao thất bại không có hệ quả | `order/OrderSettlement.java:63-72` | Điểm uy tín người mua, chặn COD khi vi phạm | | |
| BE-11 | P1 | Phân xử khiếu nại thô: chỉ hoàn toàn bộ hoặc không hoàn; shop chỉ có ghi chú chữ (`sellerNote`), không nộp ảnh phản biện; không có SLA cho Admin | `order/OrderService.java:414, 448-465` | Hoàn một phần, shop nộp bằng chứng, job nhắc / leo thang đơn `DISPUTED` quá hạn | | |
| BE-12 | P1 | Checkout lấy giá hiện tại, request không mang giá người mua đã thấy. Shop sửa giá / tồn kho tin đang bán không cần duyệt lại vì `BookService.update` không tính giá | `order/CheckoutService.java:112, 117`, `catalog/BookService.java:30-39`, `catalog/ListingService.java:90-104` | Request gửi kèm giá mong đợi, lệch thì trả `PRICE_CHANGED`; tính giá vào điều kiện duyệt lại | | |
| BE-13 | P1 | Checkout không idempotent: hai request song song cùng giỏ đều đọc giỏ trước khi xoá, tồn kho đủ thì tạo hai bộ đơn. Rút tiền, đăng ký cũng không có `Idempotency-Key` | `order/CheckoutService.java:80-132, 235-259` | Khoá dòng giỏ theo user (`FOR UPDATE`) hoặc nhận `Idempotency-Key` | | Sửa một phần: khoá ví khi đặt hàng để không tạo trùng đơn. Rút tiền và đăng ký chưa có Idempotency-Key |
| BE-14 | P2 | Thời hạn khiếu nại 3 ngày cố định cho mọi đơn | `system/SystemConfigService.java:31` | Cấu hình theo giá trị đơn và tuyến vận chuyển | | |
| BE-15 | P2 | Người thắng nhiều lô trong một phiên bị tính ship riêng từng lô | `auction/AuctionSettlement.java:94-140` | Gộp kiện | | Đã sửa, test đạt (gộp phí giao: lô sau chỉ trả phần tăng thêm) |
| BE-16 | P2 | Review: không chống review farming (tài khoản phụ tự mua), không báo cáo / kiểm duyệt review, shop không phản hồi được (bảng `Review` không có trường phản hồi) | `order/OrderService.java:266-286`, `order/Review.java` | Báo cáo review, phản hồi của shop, phát hiện mẫu bất thường | | |

## C. Đấu giá và ký gửi

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-17 | P1 | Cọc không đủ răn đe: cọc chỉ áp vào lô đầu của người thắng, hạn mức = cọc × 10. Thắng 5 lô, trả lô 1, bỏ 4 lô còn lại thì cọc đã `APPLIED`, không còn gì để thu, chỉ bị cấm đấu giá; người bán chịu phần lớn rủi ro | `auction/AuctionSettlement.java:79-80, 191-212` | Phạt theo % giá gõ búa thu vào ví, cọc bổ sung khi thắng, hoặc hạ hệ số hạn mức | | Đã sửa, test đạt (phạt 10% giá búa mỗi lô bỏ, mất cọc nếu cọc lớn hơn; thiếu thì ghi nợ) |
| BE-18 | P1 | Không có huỷ đăng ký trước hạn đăng ký; cọc kẹt đến hết phiên (controller chỉ có `DELETE` cho proxy-bid và watch) | `auction/AuctionService.java:135-166`, `auction/AuctionController.java` | Thêm huỷ đăng ký + hoàn cọc đến `registrationDeadline` | | Đã sửa, test đạt (DELETE /sessions/{id}/register đến hạn đăng ký) |
| BE-19 | P1 | Lô `UNSOLD` không có hạn quyết định: người bán im lặng thì sách nằm kho mãi, `returnNotifiedAt` không được đặt nên không tính phí lưu kho và Staff cũng không trả sách được (`NOT_RETURNABLE`). Engine chỉ có job hoá đơn quá hạn | `auction/AuctionSettlement.java:81-83`, `auction/AuctionEngine.java:46-52`, `consignment/ConsignmentService.java:363` | Job mốc N ngày sau `UNSOLD` → tự đặt trả sách + tính phí lưu kho; chính sách sách vô chủ | | Đã sửa, test đạt (7 ngày không quyết định thì tự trả sách, bắt đầu hạn lưu kho) |
| BE-20 | P1 | Lô bị trả hàng quay về `READY` rồi lên phiên lại mà không kiểm định lại; sách đã qua tay người mua nhưng vẫn dùng báo cáo tình trạng cũ | `auction/AuctionSettlement.java:293`, `auction/Lot.java:72` | Đưa về chờ kiểm định lại | | Đã sửa, test đạt (lô bị trả sang INSPECTING, Staff kiểm định lại) |
| BE-21 | P1 | `CONVERT_TO_LISTING` lệch SRS 6.6 ("sàn giao hộ"): người bán phải nhận sách về rồi tự giao; trong lúc chờ, tin được Admin duyệt là lên bán dù sách còn trong kho | `consignment/ConsignmentService.java:209-224` | Khoá tin đến khi người bán lấy sách, hoặc kho giao hộ như đơn đấu giá | | Sửa một phần, test đạt (chặn duyệt tin khi sách còn trong kho; chưa làm kho giao hộ) |
| BE-22 | P1 | Phí lưu kho trừ thẳng ví người bán; không đủ số dư thì ném `INSUFFICIENT_BALANCE`, Staff không xuất kho trả sách được | `consignment/ConsignmentService.java:370-373` | Ghi công nợ hoặc thu tại quầy | | Đã sửa, test đạt (phí kho thành nợ, vẫn xuất kho) |
| BE-23 | P1 | Ký gửi chỉ cần email xác thực; không cần shop, KYC hay thông tin nhận tiền dù lô giá trị cao | `consignment/ConsignmentService.java:68-77` | KYC cho người ký gửi và người thắng giá trị cao | | |
| BE-24 | P2 | Kho chưa có quy trình mất / hỏng sách (trạng thái kho chỉ `IN_STOCK/RESERVED/SHIPPED/RETURNED`); không nhắc Staff khi quá hạn sơ duyệt 48h (job duy nhất là hết hạn lịch hẹn) | `V1__init_schema.sql:206`, `consignment/ConsignmentJobs.java` | Luồng sự cố kho, job nhắc hạn sơ duyệt | | |
| BE-25 | P2 | Chống thông đồng đẩy giá mỏng: chỉ chặn người ký gửi trả giá bằng chính tài khoản đó; bảng `Bid` không lưu IP / thiết bị | `auction/BidService.java:284-287`, `auction/Bid.java` | Ghi IP / thiết bị cho lượt trả giá, cảnh báo tài khoản liên quan | | |

## D. Tài khoản, xác thực, Admin

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-26 | P0 | **Đã sửa một phần.** Đã sửa: đăng nhập sai 10 lần trong 15 phút thì 429 `TOO_MANY_REQUESTS`, đếm theo email (email không tồn tại cũng bị đếm, không lộ email nào có thật); bộ đếm OTP sai trước đây bị rollback cùng lỗi nên thực tế dò OTP vô hạn, nay lưu bằng giao dịch riêng (`REQUIRES_NEW`), sai 5 lần thì mã đúng cũng bị từ chối. **Còn lại:** xin OTP mới (`sendOtp`, `forgotPassword`) không giới hạn, mỗi mã mới cho thêm 5 lần đoán; OTP vẫn chỉ ghi log, không gửi email / SMS nên "đã xác thực SĐT" để đấu giá không có nghĩa ngoài dev; SĐT `UNIQUE` kể cả chưa xác thực nên chiếm được số của người khác | `auth/AuthService.java:79-93` (đã sửa), `auth/OtpAttempts.java`, `auth/AuthService.java:114-130, 145-155` (còn lại), `V1__init_schema.sql:13` | Giới hạn tần suất `sendOtp` / `forgotPassword` theo user và email bằng `RateLimiter` sẵn có; dịch vụ email / SMS thật; `UNIQUE` chỉ cho SĐT đã xác thực | | Đã sửa một phần (`9d25426`, `1c04db7`) |
| BE-27 | P1 | Khoá tài khoản chỉ đổi trạng thái và thu hồi token; tin vẫn `ACTIVE`, yêu cầu rút tiền vẫn chờ, đơn dở và cọc đấu giá không được xử lý | `admin/AdminService.java:64-74` | Khoá có quy trình: ẩn tin, đóng băng ví, xử lý đơn dở | | Đã sửa, test đạt (ẩn tin, huỷ đơn chưa giao, hoàn cọc phiên chưa chốt) |
| BE-28 | P2 | Admin một cấp: một người tự duyệt rút tiền, đổi vai trò, đổi phí; chỉ chặn tự khoá / tự đổi quyền chính mình | `admin/AdminService.java:64-97`, `wallet/WalletService.java:216` | Xác nhận hai người cho rút lớn và đổi quyền | | |
| BE-29 | P2 | Dashboard "doanh thu" là tổng giá trị đơn hoàn tất (GMV), không phải phí sàn thực thu | `order/OrderRepository.java:75`, `admin/AdminService.java:128-129` | Tách GMV với phí thu được từ ví sàn | | |
| BE-30 | P2 | Không có xoá / ẩn danh tài khoản và xuất dữ liệu cá nhân (controller user chỉ có xoá địa chỉ); cần đối chiếu Nghị định 13/2023 (chưa xác minh) | `user/UserController.java` | Luồng xoá tài khoản giữ sổ cái ẩn danh | | |
| BE-31 | P2 | **Chưa xác minh pháp lý**, cần người am hiểu luật: giữ tiền hộ trong ví nội bộ có thể cần mô hình trung gian thanh toán hoặc tài khoản đảm bảo; khấu trừ thuế người bán cá nhân; hóa đơn điện tử cho phí sàn; sách cấm / lậu | toàn hệ thống | Tham vấn pháp lý trước khi chạy thật | | |

## E. Hạ tầng, cấu hình, API

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-32 | P0 | Profile mặc định là `dev` (`${SPRING_PROFILES_ACTIVE:dev}`). Quên đặt biến khi deploy thì OTP trả thẳng trong response và `POST /payments/{code}/simulate` bật: gọi cho đơn nạp ví là tự nạp tiền miễn phí (`markSuccess` cộng ví với `TOP_UP`). JWT secret và khoá ZaloPay cũng có giá trị mặc định | `application.yml:13, 60-61, 72-80, 88-99`, `wallet/PaymentService.java:147-161`, `wallet/WalletController.java:101-105` | Mặc định profile `prod` hoặc bỏ default; thiếu `JWT_SECRET` thì không khởi động; `simulate` chỉ bật bằng biến môi trường tường minh | | |
| BE-33 | P1 | **Đã sửa một phần.** Đã sửa: ISBN rỗng hoặc đúng 10 / 13 ký tự (`^$\|^(\d{9}[\dXx]\|\d{13})$`, chỉ kiểm định dạng, không kiểm số kiểm tra, không nhận dấu gạch); số tài khoản khi rút `\d{6,19}`. **Còn lại:** không có cận trên giá / tồn kho (`price ≥ 1000`, `stock ≥ 0`, không `@Max`); tên chủ tài khoản không có pattern; số tài khoản của shop (`ShopRequest`) vẫn chỉ `@Size(max=50)`; cấu hình chỉ cần số nguyên ≥ 0 nên Admin đặt `order.payment_timeout_minutes=0` thì mọi đơn bị huỷ ngay, `order.auto_complete_days=0` thì hết thời hạn khiếu nại. (SĐT và mật khẩu 8–72 ký tự đã được kiểm đúng) | `catalog/CatalogDtos.java:41, 70-71`, `wallet/WalletDtos.java:40`, `user/UserDtos.java:71`, `system/SystemConfigService.java:116-121` | Khoảng min/max theo từng khoá cấu hình; cận trên giá / tồn kho; pattern tên chủ tài khoản và số tài khoản shop; cân nhắc kiểm số kiểm tra ISBN | | Đã sửa một phần (`9d25426`) |
| BE-34 | P1 | Upload: biên lai chuyển khoản (có số tài khoản) và ảnh sách chung một thư mục, `GET /files/*` công khai và cache `public` 7 ngày; chỉ tin `Content-Type` do client khai; không quota; không dọn file mồ côi; lưu đĩa cục bộ nên mất khi deploy lại (SRS ghi Cloudinary) | `file/FileController.java:35-77`, `security/SecurityConfig.java:50-51` | Object storage; biên lai cần quyền xem; kiểm nội dung thật; giới hạn theo user; job dọn file mồ côi | | |
| BE-35 | P1 | Nhiều lỗi nghiệp vụ dùng chung mã `FORBIDDEN`; frontend phải dò chuỗi tiếng Việt để phân biệt, đổi câu chữ là hỏng. Sửa cùng [FE-07](AUDIT_FRONTEND.md) | `common/ApiException.java:32-34`, `auction/BidService.java:279, 283` | Thêm mã riêng `AUCTION_BANNED`, `NOT_REGISTERED`… | | Đã sửa, test đạt (AUCTION_BANNED, NOT_REGISTERED) |
| BE-36 | P1 | Thông báo ngoài app: không gửi push / email / SMS (code ghi rõ không gửi FCM) và không có endpoint đăng ký thiết bị. Người thắng có 48h để trả, app tắt thì không biết rồi mất cọc oan. Làm cùng [FE-03](AUDIT_FRONTEND.md) | `notification/NotificationService.java:16`, `openapi.yaml` (không có `device`) | Endpoint đăng ký FCM token; gửi FCM trong `notify`; email / SMS cho các mốc có hạn (thắng lô, hạn thanh toán, mời mua lần hai) | | |
| BE-37 | P1 | Phí ship so khớp "cùng tỉnh" bằng chuỗi tên; dữ liệu địa chỉ phía frontend là 63 tỉnh, trong khi địa giới đã đổi từ giữa 2025 (**cần xác minh lại**) nên so khớp và bảng phí sẽ lệch | `order/ShippingCalculator.java:20-39` | Danh mục địa giới có mã, bảng phí theo vùng, cân nặng thực; về lâu dài dùng API hãng vận chuyển | | |
| BE-38 | P2 | WebSocket nhận JWT qua `?token=` trên URL (lộ trong log proxy); token chỉ kiểm lúc nối, hết hạn giữa phiên vẫn kết nối | `notification/RealtimeHub.java:55-57` | Vé WS ngắn hạn dùng một lần | | |
| BE-39 | P2 | Chỉ chạy được một instance: `RealtimeHub` giữ kênh WS trong RAM, `AuctionEngine` tick trong tiến trình. Đây là giới hạn nhóm đã biết (ghi ở `AuctionEngine.java:19`), cần xử lý nếu mở rộng | `notification/RealtimeHub.java:41`, `auction/AuctionEngine.java:19` | Redis pub/sub cho kênh WS; ShedLock cho job | | |
| BE-40 | P2 | Không có CI / deploy cho backend (`.github/workflows` chỉ có `frontend-ci.yml`, `frontend-deploy.yml`); chỉ có actuator `health,info`, không metrics hay cảnh báo khi job lỗi hoặc tick đấu giá chậm | `.github/workflows/`, `application.yml:49-53` | `backend-ci.yml` chạy `./mvnw test`; metrics + cảnh báo | | |
| BE-41 | P2 | Không có test đồng thời cho trả giá, tồn kho, ví (không test nào dùng `ExecutorService`/`CountDownLatch`) | `src/test` | Test song song cho `applyBid`, `reserveStock`, `WalletService.move` | | Đã sửa, test đạt (ConcurrencyTest: đặt hàng, tồn kho, rút tiền, trả giá song song) |
| BE-42 | P1 | **Mới (từ code vừa thêm).** Khoá đăng nhập chỉ đếm theo email, không theo IP: ai cũng khoá được tài khoản của người khác 15 phút bằng 10 lần đăng nhập sai (đăng nhập đúng cũng bị chặn trong thời gian đó). Bộ đếm nằm trong RAM (mất khi khởi động lại, không dùng được khi chạy nhiều instance); dọn rác chỉ xoá khoá đã hết hạn nên gửi hàng loạt email giả trong 15 phút làm bảng phình tới khi hết hạn | `common/RateLimiter.java:20-32`, `auth/AuthService.java:79-93` | Thêm khoá theo IP (kèm email), trả `Retry-After`; giới hạn kích thước bảng; chuyển sang Redis khi chạy nhiều instance (cùng BE-39) | | |

## Thứ tự gợi ý
1. **BE-32** (sửa nhỏ, sai là hỏng cả hệ thống khi deploy).
2. **BE-01 → BE-04, BE-26** (P0 còn lại).
3. **BE-05, BE-13**: lưu tỷ lệ phí lúc chốt, chống checkout trùng; sửa nhỏ.
4. **BE-07, BE-08, BE-09**: hạn và uy tín người bán.
5. **BE-17, BE-18, BE-36**: cọc đấu giá công bằng và thông báo ngoài app.


---

## Cập nhật 5: đợt vá sau đánh giá lại (2026-11-06)

Vá các lỗ hổng tìm thấy khi đánh giá lại: COD vận hành thật (Staff đối chiếu hãng vận chuyển, đơn COD không tự giao), địa chỉ nhận hàng trả, danh sách lô chờ kiểm định lại, nhắc việc trước hạn, phủ nhật ký bảo mật (BE-26, BE-42 phần log), cảnh báo COD đang giao quá lâu. Chi tiết: [SESSION_LOG_2026-11-05.md](SESSION_LOG_2026-11-05.md) mục H. Migration `V12`; `apps/backend/openapi.yaml` đã xuất lại (chỉ thêm). **Đã chạy test: 101/101 đạt** (trừ `SeedDataTest`).

Còn lại không đổi: nhóm 1 (BE-32, OTP trong log, BE-33), việc cần làm cùng frontend, việc cần chủ repo — xem [BACKLOG_LATER.md](BACKLOG_LATER.md).


---

## Cập nhật 6: kiểm tra đấu giá nhiều người (2026-11-06)

Thêm `MultiBidderTest` và sửa 2 lỗi trong `BidService` (đặt giá tối đa sau giờ chốt; giá tay bằng giá tối đa của người đặt trước). Chi tiết: [SESSION_LOG_2026-11-05.md](SESSION_LOG_2026-11-05.md) mục I. **Đã chạy test: 112/112 đạt** (trừ `SeedDataTest`).


---

## Cập nhật 7: ép số nguyên cho tiền, kiểm thử đầu cuối (2026-11-06)

Thêm `@WholeVnd` cho mọi ô nhập tiền chính; sửa mất gộp kiện phí giao hoá đơn đấu giá; thêm 31 test luồng đầu cuối. **Đã chạy test: 144/144 đạt** (trừ `SeedDataTest`). Chi tiết: [SESSION_LOG_2026-11-05.md](SESSION_LOG_2026-11-05.md) mục J, kế hoạch [E2E_TEST_PLAN.md](E2E_TEST_PLAN.md).
