# Nhật ký phiên làm việc 2026-11-05 (Claude)

File này ghi lại **mọi việc đã làm trong phiên**, theo thứ tự thời gian, để người khác đối chiếu. Cập nhật liên tục; mục mới thêm vào cuối.
Quy ước chủ repo đặt ra giữa phiên: **không sửa phần code không liên quan, không xoá code** (chỉ thêm, hoặc sửa đúng dòng thuộc yêu cầu).
Trạng thái git: **chưa commit gì**, chưa push.

## A. Việc đã làm trước khi có quy ước trên

| # | Việc | Công cụ / lệnh | Kết quả | File thay đổi |
|---|---|---|---|---|
| 1 | Đọc SRS (`docs/Đặc-tả-ứng-dụng-…docx`): giải nén `word/document.xml` ra văn bản | PowerShell, ghi vào thư mục scratchpad ngoài repo | Đọc xong 562 dòng | Không (file tạm ngoài repo) |
| 2 | Đọc code backend: wallet, payment, order, checkout, settlement, job, auction, consignment, listing, auth, user, admin, security, file, WebSocket, cấu hình, migration | Read / Grep / Bash (chỉ đọc) | Rà soát nghiệp vụ | Không |
| 3 | Đọc frontend: `CLAUDE.md`, `DECISIONS.md`, `BACKEND_HANDOFF.md`, `core/` (realtime, auth, error, notifications, settings), `env/*.json`, workflow CI | Read / Bash (chỉ đọc) | Rà soát frontend | Không |
| 4 | Viết báo cáo rà soát gộp, rồi tách | Write | `BUSINESS_RULE_AUDIT.md` tạo ra, sau đó **xoá chính file này** (do tôi tạo, chưa từng commit) khi tách | Xem dòng 5 |
| 5 | Kiểm lại từng lỗi với code, sửa các mục viết sai / nói quá, tách theo BE / FE | Write | Tạo `docs/AUDIT_BACKEND.md` (41 mục), `docs/AUDIT_FRONTEND.md` (11 mục) | `docs/AUDIT_BACKEND.md`, `docs/AUDIT_FRONTEND.md` (mới) |
| 6 | Xem 14 commit mới sau lần rà soát (`git log`, `git diff 29d495d..HEAD`), chạy thử test backend | Bash | Chạy `./mvnw -Dtest=InputGuardsTest test` **3 lần, đều không chạy được**: (1) `JAVA_HOME` trỏ JDK 8, (2) sai đường dẫn JDK 21, (3) JDK 21 đúng nhưng Postgres báo sai mật khẩu user `rebook` (`FATAL: password authentication failed`). Không sửa cấu hình DB | Sinh thư mục `apps/backend/target/` (đã được `.gitignore`) |
| 7 | Cập nhật hai file audit theo code mới: BE-26, BE-33 sửa một phần; thêm BE-42, FE-12; ghi chú BE-02, BE-04; thêm mục "Việc test còn nợ" | Python (sửa text trong file của tôi) | Cập nhật xong | `docs/AUDIT_BACKEND.md`, `docs/AUDIT_FRONTEND.md` |
| 8 | Hook Stop báo 44 lỗi `dart analyze` do file sinh tự động chưa được tạo lại sau pull. Chạy `flutter gen-l10n` và `dart run build_runner build --delete-conflicting-outputs` trong `apps/frontend` | Bash nền | Sinh 339 file; `dart analyze --fatal-infos` sạch, `arch_check` OK | Chỉ file sinh (`*.g.dart`, l10n), đều nằm trong `.gitignore`, không hiện trong `git status` |
| 9 | Tắt tiến trình Dart theo yêu cầu: `dart` (PID 23264) và `dart_mcp_server` (PID 3444) | PowerShell `Stop-Process` | Kiểm lại còn 0 tiến trình | Không |
| 10 | Thiết kế ghi log thống nhất (BA): 3 lớp, khuôn trường chung, ~100 mã sự kiện, danh sách không được ghi, cảnh báo, lộ trình 7 bước | Write | Chưa có code | `docs/LOGGING_DESIGN.md` (mới) |
| 11 | Hỏi chủ repo 4 quyết định về luật tiền (COD, rút tiền, trả hàng, xác nhận giao hàng) | AskUserQuestion | Xem mục B | Không |

## B. Quyết định của chủ repo cho luồng tiền

| Vấn đề | Quyết định | Cách hiểu và áp dụng |
|---|---|---|
| COD | "Áp dụng cách chuyên nghiệp nhất các sàn dùng và xử lý các trường hợp liên quan" | Mô hình sàn TMĐT: **hãng vận chuyển thu hộ, sàn đối soát với hãng, rồi mới trả tiền shop sau khi trừ phí**. Tiền COD chỉ vào ví shop sau khi (đơn hoàn tất) **và** (sàn xác nhận đã nhận tiền đối soát). Trả hàng COD chỉ hoàn ví người mua khi sàn đã nhận tiền đối soát. Thêm hạn mức COD và chặn người bom hàng |
| Nạp ví rồi rút | Khoá 7 ngày "hay nhưng chưa ổn vì vừa nạp muốn rút ngay thì phải chờ tận 7 ngày" | Rút ngắn: khoá tiền nạp **24 giờ** (cấu hình được, đặt 0 để tắt), thêm gắn nguồn tiền (bán hàng / tiền nạp) vào yêu cầu rút để Admin thấy, và hạn mức rút từ tiền nạp mỗi ngày |
| Trả hàng | Hoàn khi shop nhận lại sách | Thêm bước người mua gửi trả (mã vận đơn) và shop / kho xác nhận đã nhận; tồn kho không tự cộng lại |
| Giao hàng khi chưa có hãng vận chuyển thật | "Cách 1 nhưng thêm trường hợp nếu khách không nhấn xác nhận thì sao" | Người mua xác nhận đã nhận khi đơn đang giao; nếu không bấm, sau **7 ngày** kể từ lúc giao shipper hệ thống tự coi là đã giao rồi mới chạy hạn khiếu nại 3 ngày. Hai nút giả lập của shop chỉ bật ở profile dev |

## C. Việc đã làm sau quy ước "không sửa code không liên quan, không xoá code"

*(Mục này được cập nhật khi làm; mỗi dòng ghi file đã sửa và lý do.)*

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 12 | Tạo file log phiên này | `docs/SESSION_LOG_2026-11-05.md` (mới) | |
| 13 | Migration luồng tiền: 9 cấu hình mới; loại giao dịch ví `COD_RECEIPT`, `COD_PAYOUT`; cột mới ở `orders`, `lots`, `return_requests`, `withdraw_requests`; bảng `audit_events`. Phát hiện cột `resolved_at` đã có từ V5 nên bỏ dòng thêm trùng | `apps/backend/src/main/resources/db/migration/V9__money_rules.sql` (mới) | Chỉ thêm; backfill `orders.shipped_at` từ `order_status_history` là lệnh `UPDATE` duy nhất trên dữ liệu cũ |
| 14 | Khung ghi sự kiện: `AuditLog` (cùng giao dịch / giao dịch riêng), `EventCode`, `AuditEvent`, `AuditEventRepository`, `RequestIdFilter` | `apps/backend/src/main/java/com/rebook/audit/` (5 file mới) | `admin_activity_logs` và `ActivityLogService` giữ nguyên, chạy song song |
| 15 | **COD** theo mô hình đối soát hãng vận chuyển: `CodService`, `CodController` (`GET /admin/cod/pending`, `POST /admin/cod/{orderId}/remit`); `OrderSettlement` chỉ trả shop khi đã đối soát, hoàn ví người mua khi đã đối soát; hạn mức COD và chặn bom hàng ở `CheckoutService` | `order/CodService.java`, `order/CodController.java` (mới); sửa `order/OrderSettlement.java`, `order/CheckoutService.java`, `order/OrderRepository.java`, `order/Order.java` | |
| 16 | **Rút tiền**: khoá tiền mới nạp 24h (trừ phần đã tiêu), hạn mức rút/ngày, ghi `topup_locked`; `GET /wallet/withdrawable`; khoá ví khi rút | sửa `wallet/WalletService.java`, `WalletController.java`, `WalletDtos.java`, `WithdrawRequest.java`, `WithdrawRequestRepository.java`, `WalletTransactionRepository.java`, `WalletTxType.java` | |
| 17 | **Trả hàng theo bước** (`AWAITING_GOODS`, `EXPIRED`), người mua gửi hàng trả, shop/kho xác nhận nhận lại, job quá hạn; tồn kho không tự cộng lại khi trả hàng | sửa `order/OrderService.java`, `OrderDtos.java`, `OrderController.java`, `OrderManagementController.java`, `OrderJobs.java`, `ReturnRequest.java`, `ReturnRequestRepository.java` | |
| 18 | **Giao hàng**: hai endpoint giả lập của shop chỉ chạy khi `app.shipping.simulate-enabled=true`; người mua xác nhận khi đang giao; job tự coi là đã giao sau 7 ngày; ghi `shippedAt` | sửa `order/OrderManagementController.java`, `OrderService.java`, `OrderJobs.java`, `OrderRepository.java`, `application.yml` (chỉ profile dev), `src/test/resources/application-test.yml` | Production không bật cờ này |
| 19 | **Chụp tỷ lệ phí**: phí đơn thường lúc đặt (`orders.fee_percent`), hoa hồng đấu giá lúc chấp nhận hợp đồng (`lots.commission_percent`) | sửa `order/CheckoutService.java`, `consignment/ConsignmentService.java`, `auction/AuctionSettlement.java`, `auction/Lot.java` | Đơn / lô cũ (cột null) vẫn dùng cấu hình hiện tại |
| 20 | **Đối soát ví** hằng đêm (ví so với sổ cái, đơn COD quá 7 ngày chưa đối soát) | `wallet/WalletReconciliationJob.java` (mới) | |
| 21 | Gắn ghi sự kiện vào các điểm tiền: mọi dòng sổ cái ví (`WalletService.move`), mọi lần đổi trạng thái đơn (`OrderService.transition`), COD, rút tiền, trả hàng, giao hàng, đặt hàng | các file ở dòng 15–20 | Mã sự kiện đã gắn: xem `docs/LOGGING_DESIGN.md` mục 12 |
| 22 | Test mới: `MoneyRulesTest` (14 test: COD, rút tiền, giao hàng, trả hàng, chụp phí, sổ cái / đối soát), `ShippingSimulationGateTest` (1 test) | `apps/backend/src/test/java/com/rebook/order/` (2 file mới) | Đã chạy, đạt (xem mục D) |
| 23 | Cập nhật tài liệu: trạng thái BE-01…06, BE-13; mục "Cập nhật 2: luồng tiền"; mục "Việc frontend phải làm sau thay đổi luồng tiền"; mục 12 trạng thái triển khai log | `docs/AUDIT_BACKEND.md`, `docs/AUDIT_FRONTEND.md`, `docs/LOGGING_DESIGN.md` | |

### Những dòng code cũ đã bị thay thế (không có dòng nào bị xoá không thay)

Chỉ những dòng thuộc đúng hành vi được yêu cầu đổi. Danh sách đầy đủ để người review đối chiếu:

| File | Dòng cũ | Thay bằng |
|---|---|---|
| `OrderSettlement` | nhánh `else` COD cộng `gross` vào ví shop từ không có gì; tính phí bằng cấu hình hiện tại | nhánh `else if` chỉ trả shop khi đã đối soát; phí lấy từ `feePercentOf(o)` (đã chụp) |
| `OrderSettlement` | nhánh COD trả hàng cộng ví người mua từ không có gì; `restoreStock` chạy cho cả trả hàng | hoàn ví khi đã đối soát, chưa thì đánh dấu chờ; `restoreStock` bỏ qua trường hợp `RETURNED` |
| `OrderService` | `respondReturn` (đồng ý): đặt `APPROVED` rồi chuyển `RETURNED` ngay | gọi `approveReturn` (chờ gửi hàng) |
| `OrderService` | `resolveDispute` (hoàn tiền): chuyển `RETURNED` ngay | đã gửi hàng → `completeReturn` (logic cũ chuyển vào đây); chưa gửi → `approveReturn` |
| `OrderService` | `confirmReceived`: bộ lọc chỉ `PENDING`/`DISPUTED`; không xử lý đơn đang giao | thêm `AWAITING_GOODS`; thêm nhánh `SHIPPING` |
| `OrderService`, `OrderDtos` | `ReturnResponse.of(r, respondBy, resolvedByName)` và 13 trường | thêm tham số `shipBy` và 4 trường cuối |
| `CheckoutService` | `case COD -> null;` | `case COD -> { ensureCodAllowed(...); yield null; }` |
| `AuctionSettlement` | hoa hồng luôn lấy từ cấu hình | lấy từ lô nếu đã chụp |
| `ReturnRequest`, `WalletTxType`, `WalletService.move` | dòng khai báo enum / dòng `return` | thêm giá trị / lưu rồi ghi sự kiện rồi trả về |

## D. Rủi ro và việc chưa làm

- **Test backend đã chạy: 64 test đạt, 0 lỗi** (50 test cũ + 14 `MoneyRulesTest` + 1 `ShippingSimulationGateTest`, trừ `SeedDataTest`). Không chạy được `SeedDataTest` vì test cũ này gắn cứng `localhost:5432`, trong khi DB dùng để chạy nằm ở cổng 5433. Thay vào đó đã khởi động backend profile `dev` (có dữ liệu mẫu) trên cổng 8081: Flyway áp 11 migration đến `v9` thành công, `GET /wallet/withdrawable` và `X-Request-Id` hoạt động. Hai lỗi duy nhất trong lần chạy đầu là của chính test mới (đếm cả sự kiện bị từ chối); đã sửa test, không phải sửa code nghiệp vụ.
- Việc dựng môi trường chạy test (không thay đổi gì trong repo): (1) tạo cụm PostgreSQL tạm bằng `initdb` của Postgres 18 đã cài, nghe `127.0.0.1:5433`, dữ liệu trong thư mục scratchpad của phiên, user `rebook`/`rebook`, DB `rebook_dev`, **không đụng** Postgres chính trên cổng 5432; (2) lỗi môi trường riêng của máy này `Unable to establish loopback connection` khi JDK tạo `HttpClient` (Windows từ chối socket nội bộ trong thư mục tạm mặc định) khắc phục bằng cờ JVM `-Djdk.net.unixdomain.tmpdir=C:\rbtmp` (thư mục `C:\rbtmp` do tôi tạo); (3) JDK 21 của máy nằm ở `~/.jdks/graalvm-jdk-21.0.7` vì `JAVA_HOME` mặc định trỏ JDK 8. Sau khi xong đã tắt backend và cụm Postgres tạm.
- Lệnh chạy lại sau này (Git Bash): `cd apps/backend && export JAVA_HOME="$(cygpath -w ~/.jdks/graalvm-jdk-21.0.7)" TEST_DB_URL="jdbc:postgresql://localhost:5433/rebook_dev?currentSchema=rebook_test" && ./mvnw -DargLine="-Djdk.net.unixdomain.tmpdir=C:\\rbtmp" test` (cần bật lại cụm Postgres 5433 bằng `pg_ctl`, hoặc dùng DB riêng của bạn).
- `apps/backend/openapi.yaml` **đã xuất lại** từ `/v3/api-docs.yaml` của bản chạy thật: 219 dòng thêm, 0 dòng xoá (6 endpoint mới, `ReturnStatus` thêm `AWAITING_GOODS` / `EXPIRED`, 4 schema mới, 4 trường mới ở `ReturnResponse`). Frontend vẫn chưa đổi gì và chưa chạy `/sync-api`.
- Đây là thay đổi hành vi nghiệp vụ lớn (COD, trả hàng, rút tiền, giao hàng) chưa qua review của người khác.
- Giá trị mặc định do tôi chọn, chủ sàn nên duyệt: COD tối đa 3.000.000đ (500.000đ cho người chưa có đơn hoàn tất), chặn COD sau 2 đơn thất bại trong 90 ngày, khoá tiền nạp 24 giờ, hạn mức rút 20.000.000đ/ngày, tự coi là đã giao sau 7 ngày, hạn gửi hàng trả 7 ngày, hạn shop xác nhận hàng trả 7 ngày. Tất cả sửa được trong `system_configs`.
- Chưa làm: gỡ OTP khỏi log (`AuthService.java:168`), cấu hình log JSON, KYC / OTP khi đổi tài khoản ngân hàng, đối soát tổng với ZaloPay, BE-17 (cọc đấu giá), BE-22, và các mục khác trong `AUDIT_BACKEND.md`.
- Dùng hook `Stop` của frontend: chỉ chạy lệnh Dart khi hook yêu cầu; theo yêu cầu chủ repo, phần frontend không chạy nữa.

## E. Việc làm sau khi có DB để chạy test

| # | Việc | File / công cụ | Kết quả |
|---|---|---|---|
| 24 | Tìm Postgres trên máy: Postgres 18 đang chạy ở 5432 (của chủ máy, không có mật khẩu quản trị), Docker Desktop tắt. Dựng cụm Postgres tạm bằng `initdb` / `pg_ctl` ở cổng 5433, tạo role và DB theo `scripts/create-database.sql` | thư mục scratchpad của phiên | Chạy được; đã tắt sau khi xong |
| 25 | Chẩn đoán lỗi `Unable to establish loopback connection`: tái hiện bằng chương trình Java nhỏ (`Selector.open()`), thử `preferIPv4Stack`, đổi JDK, đổi `java.io.tmpdir` đều không được; cờ `jdk.net.unixdomain.tmpdir` khắc phục | file thử trong scratchpad, thư mục `C:\rbtmp` | Khắc phục |
| 26 | Chạy toàn bộ test: lần 1 lỗi môi trường; lần 2 có 63/65 (1 lỗi test mới đếm sai sự kiện, 1 lỗi `SeedDataTest` gắn cứng cổng 5432); sửa hàm đếm trong test | `apps/backend/src/test/java/com/rebook/order/MoneyRulesTest.java` (hàm `auditCount` chỉ đếm `result = 'SUCCESS'`) | Lần 3: 64/64 đạt (bỏ `SeedDataTest`) |
| 27 | Khởi động backend profile `dev` trên DB mới để kiểm migration trên dữ liệu mẫu và gọi thử API | `./mvnw spring-boot:run` (cổng 8081) | Flyway lên `v9`; API chạy; đã tắt |
| 28 | Xuất lại spec API | `apps/backend/openapi.yaml` (ghi đè bằng bản xuất từ `/v3/api-docs.yaml`) | Chỉ thêm 219 dòng |
| 29 | Cập nhật trạng thái trong tài liệu: bỏ "chưa chạy test" | `docs/AUDIT_BACKEND.md`, `docs/AUDIT_FRONTEND.md` | |

## F. Nâng cấp luồng tiền đấu giá

Yêu cầu của chủ repo: tự đọc lại SRS, tự đánh giá chỗ cần cải thiện và làm lại như BA chuyên nghiệp, đủ sâu cho nhiều tình huống thực tế. Quyết định duy nhất do chủ repo chọn: **phạt % giá búa cho mỗi lô bỏ thanh toán**. Phần còn lại do tôi đề xuất (xem `docs/AUCTION_MONEY_FLOW.md` mục 7 để duyệt).

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 30 | Đọc lại SRS mục 6.4–6.6, 8.2–8.4 và code `auction/`, `consignment/`, `wallet/`; viết bản phân tích BA: mô hình tiền, 9 điểm lệch SRS, 7 quy tắc mới, 18 kịch bản, API / cấu hình / sự kiện, giả định cần duyệt | `docs/AUCTION_MONEY_FLOW.md` (mới) | |
| 31 | Migration V10: 2 cấu hình, loại giao dịch `AUCTION_PENALTY`, trạng thái `LotStatus.INSPECTING` và `RegistrationStatus.CANCELLED`, bảng `account_debts` | `apps/backend/src/main/resources/db/migration/V10__auction_money_rules.sql` (mới) | Chỉ thêm |
| 32 | **Nợ phạt / nợ phí kho**: thực thể, kho lưu trữ, `DebtService` (tạo nợ, thu từ ví, miễn nợ), `DebtController` (`GET /me/debts`, `POST /me/debts/collect`, `POST /admin/debts/{id}/waive`) | `wallet/AccountDebt.java`, `AccountDebtRepository.java`, `DebtService.java`, `DebtController.java` (mới); sửa `WalletService.java` (chặn rút khi còn nợ), `WalletController.java` (thu nợ trước khi rút), `WalletTxType.java` | |
| 33 | **Phạt bỏ thanh toán**: phạt = % giá búa mỗi lô; còn cọc thì mất cọc và phạt không thấp hơn cọc; phần vượt cọc thu từ ví, thiếu thì ghi nợ; chia người bán / sàn 50/50; chọn người về nhì hợp lệ (không bị cấm, không nợ, không phải người ký gửi) | sửa `auction/AuctionSettlement.java` | Dòng cũ thay: lời gọi `forfeitAndBan`, lấy người về nhì, nội dung thông báo |
| 34 | **Huỷ đăng ký** đến hạn đăng ký, hoàn cọc, huỷ giá tối đa tự động, đăng ký lại dùng số bài cũ; chặn đăng ký và trả giá khi còn nợ | sửa `auction/AuctionService.java`, `AuctionController.java`, `BidService.java`, `AuctionRegistration.java`, `ProxyBidRepository.java` | |
| 35 | **Lô không bán** quá 7 ngày không quyết định thì tự trả sách; **phí kho** thành nợ, vẫn xuất kho | `auction/AuctionMaintenanceJob.java` (mới); sửa `consignment/ConsignmentService.java`, `auction/LotRepository.java` | Dòng cũ thay: hai dòng trừ ví phí kho |
| 36 | **Gộp phí giao** nhiều lô cùng phiên | sửa `auction/AuctionSettlement.java` | Hàm `createInvoice` cũ giữ nguyên, thêm bản có tham số khối lượng đã gộp |
| 37 | **Kiểm định lại** khi lô bị trả về kho: `INSPECTING`, `POST /staff/lots/{id}/reinspect` | sửa `auction/LotStatus.java`, `consignment/ConsignmentService.java`, `ConsignmentController.java`, `ConsignmentDtos.java` | Dòng cũ thay: lô bị trả không còn tự về `READY` |
| 38 | Mã sự kiện log mới và cấu hình mới | `audit/EventCode.java`, `system/SystemConfigService.java` | |
| 39 | Test: `AuctionMoneyTest` (11 test) | `apps/backend/src/test/java/com/rebook/auction/AuctionMoneyTest.java` (mới) | Lần đầu 10/11; 1 test lỗi do cách test gọi ngoài giao dịch (sản phẩm gọi trong giao dịch), đã sửa test |
| 40 | Chạy lại toàn bộ test với Postgres tạm: **75/75 đạt** (trừ `SeedDataTest`); khởi động backend `dev` thấy Flyway lên `v10`, API mới trả đúng; xuất lại `openapi.yaml`; tắt backend và Postgres tạm | `apps/backend/openapi.yaml` | Diff 409 dòng thêm; 25 dòng "xoá" là schema `LotBrief` dời chỗ |
| 41 | Cập nhật tài liệu: trạng thái BE-15, 17, 18, 19, 20, 22; mục "Cập nhật 3"; việc frontend sau thay đổi; sự kiện log | `docs/AUDIT_BACKEND.md`, `docs/AUDIT_FRONTEND.md`, `docs/LOGGING_DESIGN.md` | |

### Dòng code cũ bị thay trong phần đấu giá
`AuctionSettlement`: lời gọi `forfeitAndBan(lot, buyer)`, đoạn lấy người về nhì, `lot.resetToReady()` ở nhánh trả hàng, nội dung thông báo mất cọc, `createInvoice` ba dòng phí giao (giờ tính theo kiện). `ConsignmentService`: hai dòng `walletService.debit/credit` phí kho. `AuctionService.register`: kiểm tra `ALREADY_REGISTERED` (nay cho đăng ký lại khi `CANCELLED`). `LotStatus`, `AuctionRegistration.Status`, `WalletTxType`: thêm giá trị. Không xoá hàm hay file nào.

### Rủi ro
- Chưa qua review của người khác; chủ sàn nên duyệt các giá trị: phạt 10%, hạn tự trả sách 7 ngày, chặn rút tiền khi còn nợ.
- `LotStatus.INSPECTING`, `RegistrationStatus.CANCELLED` là giá trị enum mới trong API. Client frontend không lỗi khi gặp (enum lạ rơi vào `$unknown`, mapper về `pending`) nhưng hiển thị sai trạng thái cho tới khi đồng bộ.
- Smoke test trên DB tạm: lệnh `DELETE /sessions/1/register` thật sự huỷ đăng ký mẫu của `buyer1` trong DB tạm (DB tạm không còn giá trị).
- Thư mục rỗng `D:\rbtmp` do tôi tạo nhầm ở lượt trước vẫn cần chủ máy xoá tay.

## G. Đợt thuần backend (2026-11-06)

Yêu cầu của chủ repo: nhóm 1 (BE-32, gỡ OTP khỏi log, BE-33) để sau; việc cần làm cùng frontend thì ghi lại để sau; bây giờ chỉ sửa phần thuần backend. Danh sách việc để sau: `docs/BACKLOG_LATER.md` (mới).

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 42 | Ghi backlog: nhóm 1, việc cần làm cùng frontend, việc cần chủ repo / hạ tầng / luật, đấu giá còn dang dở | `docs/BACKLOG_LATER.md` (mới) | |
| 43 | Migration V11: 5 cấu hình mới, cột `ship_due_at`, `cancel_requested_at`, `seller_fault` ở `orders` | `db/migration/V11__order_sla_and_shop_reputation.sql` (mới) | Đơn đang `PREPARING` lúc migrate được tính hạn từ lúc đó, không phạt oan |
| 44 | **BE-07** hạn giao cho vận chuyển 3 ngày: job tự huỷ, hoàn tiền người mua, tính lỗi shop (bỏ qua đơn đang có yêu cầu huỷ chờ shop trả lời) | sửa `order/OrderService.java`, `OrderJobs.java`, `OrderRepository.java`, `Order.java` | |
| 45 | **BE-08** shop im lặng 24 giờ trước yêu cầu huỷ: tự đồng ý huỷ (không tính lỗi shop) | như dòng 44 | |
| 46 | **BE-09** điểm uy tín shop: `ShopReputation` gỡ uy tín khi tỷ lệ đơn lỗi ≥ 10% với tối thiểu 5 đơn trong 90 ngày; tính lỗi khi shop huỷ, không xác nhận đúng hạn, không giao đúng hạn | `order/ShopReputation.java` (mới); sửa `OrderService.java` | Chỉ gỡ uy tín, Admin gắn lại được |
| 47 | **BE-27** khoá tài khoản: ẩn tin đang bán, huỷ và hoàn tiền đơn shop chưa giao cho vận chuyển, huỷ đơn chưa thanh toán của người mua, hoàn cọc phiên chưa chốt; đơn đã giao, hoá đơn lô thắng và yêu cầu rút tiền giữ nguyên | `admin/AccountLockService.java` (mới); sửa `admin/AdminService.java`, `catalog/ListingRepository.java`, `order/OrderService.java` (`cancelBySystem`), `OrderRepository.java` | |
| 48 | Người bị cấm đấu giá vì bỏ thanh toán: hoàn cọc các phiên chưa chốt (trước đó cọc kẹt) | sửa `auction/AuctionSettlement.java` (`releaseFutureRegistrations`), `AuctionRegistrationRepository.java` | |
| 49 | **BE-35** mã lỗi riêng `AUCTION_BANNED`, `NOT_REGISTERED` (vẫn HTTP 403) | sửa `common/ApiException.java`, `auction/BidService.java`, `auction/AuctionService.java` | Frontend đã có hằng số trùng mã nên tương thích |
| 50 | **BE-21 một phần**: không duyệt tin của cuốn sách còn nằm trong kho (`BOOK_IN_WAREHOUSE`) | sửa `catalog/ListingService.java`, `consignment/ConsignmentRepository.java` | |
| 51 | Mã sự kiện log và hằng số cấu hình mới | `audit/EventCode.java`, `system/SystemConfigService.java` | |
| 52 | Test: `ShopSlaAndLockTest` (7 test), `ConcurrencyTest` (4 test: 2 lần đặt cùng giỏ, 2 người tranh cuốn cuối, 2 yêu cầu rút cùng lúc, 2 lượt trả giá cùng mức) | `apps/backend/src/test/java/com/rebook/order/` (2 file mới) | Lần đầu chạy đạt hết |
| 53 | Chạy toàn bộ test với Postgres tạm: **86/86 đạt** (trừ `SeedDataTest`); khởi động backend `dev` thấy Flyway lên `v11`; spec API không đổi nên không ghi đè `openapi.yaml`; tắt backend và Postgres tạm | | |
| 54 | Cập nhật tài liệu: trạng thái BE-07, 08, 09, 21, 27, 35, 41; mục "Cập nhật 4"; việc frontend; sự kiện log | `docs/AUDIT_BACKEND.md`, `docs/AUDIT_FRONTEND.md`, `docs/LOGGING_DESIGN.md` | |

### Dòng code cũ bị thay trong đợt này
`OrderService`: thêm dòng vào `confirm`, `buyerCancel`, `sellerCancel`, `autoCancelUnconfirmed` (không xoá dòng nào). `BidService` / `AuctionService`: hai câu `ApiException.forbidden("...")` thành bản có mã. `AdminService.lock`: thêm một dòng gọi dọn việc dở. `ListingService.approve`: thêm đoạn kiểm tra đầu hàm. Không xoá hàm hay file nào.

### Rủi ro
- Thay đổi hành vi vận hành đơn của shop (tự huỷ khi trễ giao) chưa qua review; các hạn 3 ngày / 24 giờ / ngưỡng 10% do tôi chọn, đổi được trong `system_configs`.
- `ConcurrencyTest` kiểm trên Postgres tạm, một máy; chưa thay thế được kiểm thử tải thật.
- Thư mục rỗng `D:\rbtmp` vẫn cần chủ máy xoá tay.

## H. Đợt vá sau đánh giá lại (2026-11-06)

Sau khi đánh giá lại toàn bộ việc đã làm, tôi vá các lỗ hổng tìm thấy. Chủ repo yêu cầu "vá đi"; vẫn giữ quy ước không sửa code không liên quan, không xoá code.

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 55 | Migration V12: cấu hình `notify.reminder_hours` (24) và `shipping.warehouse_address`; cột cờ nhắc `ship_reminder_sent`, `cancel_reminder_sent`, `payment_reminder_sent` ở `orders`, `decision_reminder_sent` ở `lots`; index cho đơn COD đang giao | `db/migration/V12__reminders_and_ops.sql` (mới) | Chỉ thêm |
| 56 | **COD chạy được ngoài đời thật**: đơn COD không còn tự giao sau N ngày (không có chứng cứ giao). Staff đối chiếu hãng vận chuyển: danh sách đơn đang giao, bấm "đã giao" hoặc "giao thất bại" | `order/OrderService.java` (`carrierConfirm`, `inTransit`), `OrderManagementController.java`, `OrderRepository.java` (`findShippedBefore` loại COD, `findNormalInTransit`), `OrderDtos.java` (`InTransitOrder`) | Endpoint mới: `GET /staff/orders/in-transit`, `POST /staff/orders/{id}/carrier-delivered`, `POST /staff/orders/{id}/carrier-failed` |
| 57 | Trả hàng: người mua biết gửi về đâu. Trả về địa chỉ shop (tin thường) hoặc địa chỉ kho sàn (hàng ký gửi / đấu giá) | `OrderService.returnDestination`, `OrderDtos.ReturnResponse` (`returnToName`, `returnToAddress`) | Địa chỉ kho đọc từ cấu hình `shipping.warehouse_address` |
| 58 | Staff thấy danh sách lô bị trả về kho đang chờ kiểm định lại | `consignment/ConsignmentService.inspectingLots`, `ConsignmentController` | Endpoint mới: `GET /staff/lots/inspecting` |
| 59 | Nhắc việc trước hạn (24 giờ): shop giao cho vận chuyển, shop trả lời yêu cầu huỷ, người mua thanh toán, người bán chọn hướng xử lý lô không bán. Mỗi việc nhắc đúng một lần (cờ ở mục 55) | `order/OrderJobs.java`, `OrderService.send*Reminder`, `auction/AuctionMaintenanceJob.java`, `ConsignmentService.sendDecisionReminder`, `OrderRepository`, `LotRepository` | |
| 60 | Đối soát đêm cảnh báo thêm đơn COD đang giao quá 7 ngày chưa có kết quả | `wallet/WalletReconciliationJob.java` | Chỉ log + ghi vào sự kiện `RECONCILE.RUN`, không đổi dữ liệu |
| 61 | Phủ nhật ký bảo mật: đăng ký, đăng nhập (đúng / sai / bị chặn), OTP (gửi / sai / đúng), đặt lại và đổi mật khẩu, khoá / mở khoá, đổi vai trò, gắn / gỡ uy tín shop, đổi cấu hình, tải tệp lên (cả bị từ chối), 403 trên mọi đường dẫn. Email không bao giờ nằm trong log (chỉ băm); mã OTP không nằm trong log | `audit/AuditLog.java` (`recordBy`, `recordDeniedBy`), `audit/EventCode.java`, `auth/AuthService.java`, `user/UserService.java`, `admin/AdminService.java`, `file/FileController.java`, `security/SecurityConfig.java` | Dòng log OTP cũ ở `AuthService.java:168` **vẫn còn** (nhóm 1, hoãn theo yêu cầu) |
| 62 | Test mới: `OpsGapsTest` (9), `SecurityAuditTest` (6); sửa `MoneyRulesTest` cho khớp luật mới (tự giao chỉ áp cho đơn ví, đơn COD vẫn `SHIPPING`) | `apps/backend/src/test/java/com/rebook/` | `SecurityAuditTest` lần đầu sai 3 chỗ kỳ vọng mã HTTP (đăng ký trả 201, xác thực OTP và đổi mật khẩu trả 204), đã sửa test, không sửa code |
| 63 | Chạy toàn bộ test với Postgres tạm: **101/101 đạt** (trừ `SeedDataTest`). Khởi động backend `dev` trên DB tạm: Flyway lên `v12`, `/staff/orders/in-transit` và `/staff/lots/inspecting` trả 200; xuất lại `apps/backend/openapi.yaml` từ `/v3/api-docs.yaml`: **chỉ thêm** (0 dòng cũ bị đổi / xoá) | `apps/backend/openapi.yaml` | 4 endpoint mới + schema `InTransitOrder`, `InspectingLot`, hai trường mới trong `ReturnResponse` |

### Dòng code cũ bị thay trong đợt này
`OrderRepository.findShippedBefore`: thêm điều kiện loại đơn COD (đổi hành vi có chủ đích). `OrderJobs.autoDeliver` dùng lại truy vấn đó nên tự hưởng. Các dòng gọi `audit.record` thêm vào `AuthService`, `UserService`, `AdminService`, `FileController`, `SecurityConfig`. Không xoá hàm hay file nào.

### Rủi ro
- Đơn COD không còn tự hoàn tất nếu Staff không đối chiếu: tiền người bán kẹt đến khi có người bấm. Đã có cảnh báo 7 ngày ở đối soát đêm, chưa có màn Staff ở frontend.
- Nhắc việc dựa vào cờ trong DB: nếu thông báo gửi lỗi sau khi bật cờ thì không nhắc lại (chấp nhận, cùng giao dịch nên thông thường cờ và thông báo cùng thành công hoặc cùng huỷ).
- Cổng ZaloPay thật, push FCM, tải thật chưa kiểm được.
- `D:btmp` rỗng vẫn cần chủ máy xoá tay (`C:btmp` là thư mục test cần).

## I. Kiểm tra lại đấu giá nhiều người trong một phiên (2026-11-06)

Yêu cầu của chủ repo: kiểm tra lại luồng đấu giá khi có nhiều người cùng trả giá trong một phiên. Viết `MultiBidderTest` (11 test, 5 người dùng đã đăng ký cùng một phiên): lượt tay luân phiên, từ chối người chưa đăng ký / bị cấm / đã huỷ đăng ký / chính người ký gửi, hạn mức, giá tối đa tự động đấu nhau, giá tối đa trả lời lượt tay, đồng hồ kéo dài khi trả giá phút chót, lượt trả sau giờ chốt, 20 lượt tay song song, 5 giá tối đa đặt song song, và cả phiên hai lô từ chốt lô, lập hoá đơn đến hoàn cọc người thua.

| # | Phát hiện | Cách xử lý | File |
|---|---|---|---|
| 64 | **Lỗi:** đặt giá tối đa (`PUT /lots/{id}/proxy-bid`) sau khi lô đã hết giờ nhưng engine chưa kịp chốt (tối đa ~1 giây) vẫn được nhận và đổi người dẫn đầu | Từ chối `409 LOT_NOT_OPEN` khi lô đang mở mà hết giờ | `auction/BidService.setProxy` |
| 65 | **Lỗi luật:** người trả giá tay đúng bằng giá tối đa của người đang dẫn lại cướp được vị trí dẫn (hai giá tối đa bằng nhau thì người đặt trước giữ, nhưng giá tay thì không) | Giá tay bằng giá tối đa đã đặt trước: người đặt trước giữ vị trí dẫn ở cùng mức giá, ghi một lượt tự động và báo người kia bị vượt | `auction/BidService.resolveProxies`, `takeLeadAtSamePrice` (mới) |

Không có phát hiện ở: tranh giá song song (không trùng, không vượt, `bid_count` khớp số dòng, mỗi lượt cao hơn lượt trước, người dẫn là người trả lượt cuối), nhiều giá tối đa đặt cùng lúc (người đặt cao nhất luôn dẫn), hoàn cọc người thua và giữ cọc người thắng, lô không đạt giá sàn.

**Kết quả:** `MultiBidderTest` 11/11, lặp lại 3 lần cùng `ConcurrencyTest` không lần nào lỗi; chạy toàn bộ **112/112 đạt** (trừ `SeedDataTest`). Spec API không đổi (không đụng chữ ký endpoint).

### Dòng code cũ bị thay trong đợt này
Không xoá dòng nào; `BidService` chỉ thêm một kiểm tra trong `setProxy` và một khối ở đầu mỗi vòng xét proxy.

### Chưa kiểm
Tải thật nhiều trăm người, WebSocket phát tin cho phòng đông, mất mạng giữa phiên. Test chạy một máy, một cụm Postgres.

### I.2 Rà soát tiếp (tạm dừng / tiếp tục phiên)

| # | Phát hiện | Cách xử lý | File |
|---|---|---|---|
| 66 | **Lỗi do chính tôi gây ở mục 64:** kiểm "hết giờ" trong `setProxy` chặn nhầm lúc phiên đang tạm dừng (`ends_at` cũ chưa được đặt lại) | Chỉ kiểm khi phiên đang `LIVE` | `auction/BidService.setProxy` |
| 67 | **Lỗi có sẵn:** giá tối đa đặt trong lúc tạm dừng không được xét khi tiếp tục phiên, người đặt có thể không bao giờ được trả giá hộ trước khi lô chốt | `AuctionRunner.resume` chạy `resolveProxies` và báo người bị vượt; `afterPriceChange` thành package-private | `auction/AuctionRunner.java`, `BidService.java` |

Test mới `maxBidPlacedWhilePausedIsAppliedWhenTheSessionResumes`. **Toàn bộ 113/113 đạt** (trừ `SeedDataTest`).

Chưa sửa (ghi để sau): `BidRequest.amount` / `ProxyBidRequest.maxAmount` không ép số nguyên (`50000.4` được nhận rồi làm tròn khi lưu); chưa thêm `@Digits` vì chưa biết frontend gửi `50000` hay `50000.0`, ép sai thì chặn nhầm mọi lượt trả giá.

## J. Ép số nguyên cho tiền và kiểm thử luồng đầu cuối (2026-11-06)

Yêu cầu của chủ repo: sửa lỗi số lẻ ở tiền trả giá; sau đó đọc lại SRS và thiết kế, lên kế hoạch test luồng từ nạp tiền, đăng sách, mua bán, duyệt, tổ chức đấu giá, giao hàng, trả hàng, rồi chạy test nhiều trường hợp. Kế hoạch: [E2E_TEST_PLAN.md](E2E_TEST_PLAN.md).

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 68 | Xem frontend: gửi số tiền bằng `int` của Dart (`api_auction_repository.dart`), JSON ra `50000`, không phải `50000.0` | đọc `apps/frontend/lib/features/auction/data/` | Ép số nguyên không làm hỏng frontend |
| 69 | **Lỗi:** số lẻ (`50000.4`) được nhận rồi làm tròn khi lưu; số quá lớn (10^16) làm tràn cột NUMERIC(15,0) | `common/WholeVnd.java` (mới): nhận `50000` và `50000.0`, từ chối `50000.4`, tối đa 15 chữ số. Gắn vào: trả giá, giá tối đa, cọc thêm, tiền cọc của phiên, nạp ví, rút ví, giá tin, giá mong muốn ký gửi, giá sàn đề nghị / giá sàn mới / giá bán cố định của lô không bán, 4 giá của phiếu kiểm định | `auction/AuctionDtos.java`, `wallet/WalletDtos.java`, `catalog/CatalogDtos.java`, `consignment/ConsignmentDtos.java` |
| 70 | **Lỗi:** người thắng chọn giao tận nơi sau phiên (đường thường gặp nhất) thì mỗi hoá đơn bị tính phí giao như một kiện riêng; "gộp kiện" chỉ chạy khi người mua đã có địa chỉ mặc định từ trước | Sau mỗi lần đổi cách nhận, tính lại phí giao của các hoá đơn chưa thanh toán cùng phiên theo thứ tự lập (lô sau chỉ trả phần tăng thêm) | `auction/AuctionSettlement.reconsolidateShipping`, `order/OrderRepository.findAuctionOrdersInSession` |
| 71 | Lập kế hoạch test | `docs/E2E_TEST_PLAN.md` (mới) | |
| 72 | Test mới: `FullJourneyTest` 16 ca (S1–S14: nạp ví → đăng tin → duyệt → mua → giao → nhận → đánh giá; trả hàng; phân xử; huỷ; COD; ký gửi → phiên → nhiều người trả giá → hoá đơn → nhận hàng → trả người bán; không thanh toán; thiếu người; không bán được → chuyển bán thường; không đạt giá sàn → hạ giá sàn → bán; huỷ lô khi đang chạy; một người thắng hai lô; rút tiền; hai lượt trả cùng hoá đơn), `JourneyEdgeCasesTest` 15 ca (số tiền, ví, tin đăng, giỏ, quyền, trả hàng, ký gửi, kiểm định, xếp phiên, đăng ký, trả giá, bảo mật). Các câu chuyện kiểm bảo toàn tiền | `apps/backend/src/test/java/com/rebook/journey/` (3 file mới) | |

**Kết quả:** toàn bộ **144/144 đạt**, chạy hai lần liên tiếp (trừ `SeedDataTest`).

### Điều đã hiểu sai lúc viết test (không phải lỗi code)
- Người bán nhận cả phí ship (shop tự giao), sàn chỉ thu phí trên tiền sách: `OrderSettlement` đã ghi rõ.
- Tên trạng thái tin: `PENDING_REVIEW`, `OUT_OF_STOCK`. Đánh giá trả 201.
- Đo bảo toàn tiền bằng toàn bộ ví sàn bị lệch vì job định kỳ của ứng dụng xử lý đơn do test khác để lại. Đã đổi sang chỉ tính giao dịch ví sàn gắn với đơn / đăng ký của người tham gia (`JourneySupport.platformShare`).

### Dòng code cũ bị thay trong đợt này
Không xoá dòng nào. Chỉ thêm annotation `@WholeVnd` vào tham số record có sẵn và một lời gọi `reconsolidateShipping(o)` cuối `updateDelivery`.

### Chưa kiểm
Giao diện Flutter, ZaloPay thật, thông báo đẩy, tải lớn, WebSocket phòng đông, và đường ZaloPay trả tiền đơn thường (có `ZaloPayTest` riêng). Hoá đơn đấu giá có nhiều tỉnh nhận khác nhau tính theo từng tỉnh (ghi `shortcut` trong code).
