# ReBook: luồng test và kịch bản demo

Gộp ngày 2026-11-06 từ các file cũ. Dữ liệu mẫu cho test nằm ở `apps/backend/testdata/e2e_personas.sql`; script chạy test ở `apps/backend/testdata/e2e_flows.sh` và `e2e_restart.sh`.

| Phần | Nội dung | Tên file cũ |
|---|---|---|
| A | Kế hoạch test toàn diện (happy case đến hell case) | `TEST_PLAN_TOAN_DIEN.md` |
| B | Các câu chuyện đầu cuối S1–S8 | `E2E_TEST_PLAN.md` |
| C | Kịch bản demo (bản V2) | `DEMO_V2.md` |

---

# Phần A. Kế hoạch test toàn diện (happy case đến hell case)

*(Trước là `TEST_PLAN_TOAN_DIEN.md`.)*

Ngày 2026-11-06. Bổ sung cho [TEST_PLAN_TOAN_DIEN.md phần B](TEST_PLAN_TOAN_DIEN.md) (câu chuyện S1–S8). Căn cứ luật: SRS, [THAY_DOI_SO_VOI_CODE_CU.md phần C](THAY_DOI_SO_VOI_CODE_CU.md), [THAY_DOI_SO_VOI_CODE_CU.md phần B](THAY_DOI_SO_VOI_CODE_CU.md), [DANH_GIA_BA_TESTER.md phần A](DANH_GIA_BA_TESTER.md).

### 1. Ba tầng test và cách chạy

| Tầng | Là gì | Chạy | Thời gian |
|---|---|---|---|
| **A. Tích hợp** | Spring + PostgreSQL thật, gọi qua `MockMvc` như app gọi; chỉnh giờ bằng SQL rồi gọi đúng hàm job gọi | `cd apps/backend && ./mvnw test` | ~2 phút |
| **B. Đầu cuối qua HTTP** | Backend chạy thật (profile `dev`), job nền chạy thật, gọi bằng `curl`, kiểm DB bằng `psql` | xem mục 1.2 | ~6–8 phút (chờ job) |
| **C. Thủ công trên app** | Người test bấm trên app Flutter với cùng bộ dữ liệu | danh sách ở mục 5 | tuỳ |

#### 1.1 Môi trường

- PostgreSQL 16 ở `localhost:5432`, user / mật khẩu `rebook` / `rebook`, DB `rebook_dev` (tạo bằng `scripts/create-database.sql`).
- JDK 21 (máy Mac: `export JAVA_HOME=/opt/homebrew/opt/openjdk@21`).
- Tầng B: tắt ZaloPay để dùng cổng giả lập: `ZALOPAY_APP_ID=` (để trống).
- **Lưu ý:** test tầng A và DB dev dùng chung database. Extension `pgcrypto` nằm ở schema được tạo trước: chạy test trước rồi mới chạy dev thì seed dev báo `gen_salt does not exist`. Cách sửa (chạy một lần bằng superuser): `ALTER EXTENSION pgcrypto SET SCHEMA public;`

#### 1.2 Chạy tầng B

```bash
cd apps/backend
ZALOPAY_APP_ID= ./mvnw spring-boot:run                       # cửa sổ 1, chờ "Started ReBookApplication"
psql -h localhost -U rebook -d rebook_dev -f testdata/e2e_personas.sql   # cửa sổ 2, nạp (hoặc nạp lại) dữ liệu mẫu
bash testdata/e2e_flows.sh                                   # 133 ca, in PASS / FAIL từng ca, mã thoát 1 nếu có ca lỗi
```

Mỗi lần chạy lại script phải nạp lại `e2e_personas.sql` (script đổi dữ liệu: mua hết hàng, phiên đã kết thúc...). Bộ dọn dữ liệu xoá cả những thứ script tạo qua API (ký gửi, phiên có tiêu đề `E2E...`).

Ca khởi động lại backend giữa phiên (T-AUC-18) chạy riêng vì cần tắt / bật backend bằng tay:

```bash
bash testdata/e2e_restart.sh part1     # đăng ký, mở phiên 9003, trả giá
# tắt backend rồi bật lại: ngay (~25 giây) hoặc lâu hơn thời gian còn lại của lô (~75 giây, ca T-AUC-19)
bash testdata/e2e_restart.sh part2     # phiên chạy tiếp từ trạng thái trong DB
```

### 2. Bộ dữ liệu mẫu: [apps/backend/testdata/e2e_personas.sql](../../apps/backend/testdata/e2e_personas.sql)

Mật khẩu mọi tài khoản `Rebook@123`. Id 9001–9999, không đụng dữ liệu seed dev. Số dư ví khớp sổ cái.

| Id | Email | Đại diện cho | Dùng ở ca |
|---|---|---|---|
| 9001 | e2e.buyer.rich@rebook.vn | Người mua có 5 triệu, địa chỉ HCM | ORD-01..03, 09 |
| 9002 | e2e.buyer.poor@rebook.vn | Ví rỗng | ORD-04 |
| 9003 | e2e.buyer.new@rebook.vn | Chưa có đơn hoàn tất, **chưa xác thực SĐT** | ORD-06, AUC-04 |
| 9004 | e2e.buyer.bomber@rebook.vn | Đã có 2 đơn COD giao thất bại do người mua | ORD-05 |
| 9005 | e2e.buyer.debt@rebook.vn | Còn nợ phạt 200.000 | WAL-01, AUC-02 |
| 9006 | e2e.buyer.banned@rebook.vn | Đang bị cấm đấu giá (vi phạm lần 1) | AUC-01 |
| 9007 | e2e.buyer.locked@rebook.vn | Tài khoản bị khoá | AUTH-02 |
| 9008–9010 | e2e.bidder.a/b/c@rebook.vn | Ba người đấu giá, mỗi người 3 triệu | AUC-*, ORD-03, 10, WAL-02..05 |
| 9011 | e2e.shop.new@rebook.vn | Shop mới ở Hà Nội, chưa uy tín | ORD-* |
| 9012 | e2e.consignor@rebook.vn | Người ký gửi có hồ sơ ở nhiều bước | CON-*, lô đấu giá |
| 9013 | e2e.unverified@rebook.vn | Chưa xác thực email | (tầng C) |
| 9014 | e2e.staff@rebook.vn | Nhân viên kho | ORD-10, AUC-03 |

| Dữ liệu | Trạng thái | Để test |
|---|---|---|
| Tin 9001 | Còn 1 cuốn | Hai người tranh cuốn cuối |
| Tin 9002 | 45.000đ, còn 5 | Mua thường, giá đổi lúc đặt, giao thất bại |
| Tin 9003 / 9004 | Ẩn / chờ duyệt | Không mua được |
| Tin 9005 | 3.500.000đ | Vượt hạn mức COD |
| Ký gửi 9104 | Kiểm định đạt từ 8 ngày trước, người bán chưa quyết | Tự coi như rút |
| Ký gửi 9105 | Chờ người bán nhận lại đã 70 ngày | Nhắc rồi thanh lý sách vô chủ |
| Ký gửi 9106 | Đã duyệt, chưa hẹn lịch | Hẹn lịch quá khứ / hợp lệ |
| Phiên 9001 | Đã công bố, cọc 200.000, tối thiểu 2 người, mỗi lô 20 giây | Đấu giá đầu cuối |
| Lô 9101 | Khởi điểm 100.000, giá sàn 200.000 | Giá tối đa trên giá sàn được trả hộ lên giá sàn |
| Lô 9102 | Ước tính 15–20 triệu | Lô cao giá cần cọc thêm |
| Lô 9103 | Giá sàn 1.000.000 | Không đạt giá sàn, rồi người ký gửi chọn nhận lại sách |
| Lô 9104 | Giá sàn 150.000, phiên 9001 lô 4 | Người thắng bỏ thanh toán, người về nhì được mời mua lần hai |
| Phiên 9002 + lô 9105 | Cần 3 người | Huỷ đăng ký trước hạn, thiếu người thì dời lịch rồi huỷ phiên |
| Phiên 9003 + lô 9106 | Mỗi lô 60 giây, cần 1 người | Khởi động lại backend giữa phiên |

### 3. Bất biến phải đúng sau mọi ca

| Mã | Bất biến | Kiểm ở |
|---|---|---|
| INV-1 | Tổng tiền mọi ví (available + held, gồm ví sàn) chỉ đổi đúng bằng tiền nạp vào trừ tiền rút đã duyệt | `FullJourneyTest` (mọi câu chuyện), tầng B `MON-01` |
| INV-2 | Không ví nào âm (available, held) | Ràng buộc DB `CHECK` + `WalletService.move` |
| INV-3 | Số dư ví khớp tổng sổ cái | `WalletReconciliationJob` (`MoneyRulesTest`) |
| INV-4 | Tồn kho không âm; đặt hàng hỏng thì tồn kho không đổi | `ConcurrencyTest`, tầng B `ORD-03b`, `ORD-04b` |
| INV-5 | Mỗi lô tối đa một người thắng; giá tăng dần; không ai tự đẩy giá của mình | `MultiBidderTest` |
| INV-6 | Mọi chuyển trạng thái đi đúng luồng; sai thì 409 `INVALID_STATUS_TRANSITION` | `JourneyEdgeCasesTest` |
| INV-7 | Mỗi lần đổi tiền có một dòng sổ cái và một sự kiện `audit_events` | `MoneyRulesTest`, `SecurityAuditTest` |

### 4. Ma trận ca kiểm thử

Loại: **H** happy · **B** biên · **N** sai dữ liệu / sai quyền · **L** lạm dụng, gian lận · **Đ** đồng thời · **X** hell case (sự cố, thời gian, thứ tự bất thường, hệ thống ngoài báo chậm).

Cột "Ở đâu": tên lớp test tầng A, hoặc mã ca tầng B. Trạng thái: ✅ tự động, đạt · ⏳ chưa có test tự động · ⚠ hệ thống chưa hỗ trợ (đã ghi trong bản đánh giá).

#### 4.1 Tài khoản, đăng nhập, quyền

| Mã | Loại | Kịch bản | Kết quả mong đợi | Ở đâu | |
|---|---|---|---|---|---|
| T-AUTH-01 | H | Đăng ký, nhận OTP, xác thực email, đăng nhập | Có token; chưa xác thực email thì không đặt hàng / ký gửi | `JourneyEdgeCasesTest`, AUTH-01 | ✅ |
| T-AUTH-02 | N | Sai mật khẩu; tài khoản bị khoá; không token; USER gọi `/admin` | 401 / 403 / 401 / 403 | AUTH-02..05, `SecurityAuditTest` | ✅ |
| T-AUTH-03 | L | Dò mật khẩu 10 lần từ một IP | IP đó bị chặn 15 phút; chủ tài khoản ở IP khác vẫn vào được | `BaReviewBatch2Test` | ✅ |
| T-AUTH-04 | L | Dò OTP | Sai 5 lần thì mã đúng cũng bị từ chối | `SecurityAuditTest` | ✅ |
| T-AUTH-05 | L | Xin OTP mới liên tục; quên mật khẩu liên tục (kể cả email không tồn tại) | Cách nhau ≥ 60 giây, tối đa 5 mã / giờ, 10 mã / ngày: `TOO_MANY_REQUESTS` | `OtpAndEmailRulesTest` | ✅ |
| T-AUTH-05b | H/X | Xin OTP: mã tới hộp thư; SMTP lỗi | Thư chứa mã, tiêu đề không chứa mã, log không có mã / 503 `EMAIL_SEND_FAILED`, không giữ mã | `MailOutboxTest` | ✅ |
| T-AUTH-05c | L | Đăng ký bằng biến thể hộp thư đã có (`a.b+1@gmail.com` khi đã có `ab@gmail.com`) | `EMAIL_TAKEN` | `OtpAndEmailRulesTest` | ✅ |
| T-AUTH-06 | X | Bị khoá khi đang đăng nhập | Token cũ hết tác dụng ngay ở request kế tiếp | AUTH-06 | ✅ |
| T-AUTH-07 | L | Tạo tài khoản mới để lách cấm / nợ | Phải chặn theo CCCD / SĐT (hiện chỉ chặn biến thể của cùng hộp thư, T-AUTH-05c) | | ⚠ BR-1.3 |

#### 4.2 Ví và thanh toán

| Mã | Loại | Kịch bản | Kết quả mong đợi | Ở đâu | |
|---|---|---|---|---|---|
| T-WAL-01 | H | Nạp qua cổng (giả lập), xem số dư, sổ cái | Cộng đúng một lần | WAL-02, `ZaloPayTest` | ✅ |
| T-WAL-02 | X | Cổng báo thành công hai lần / sai số tiền / sai chữ ký | Cộng đúng một lần / không cộng / từ chối | WAL-02b, `ZaloPayTest` | ✅ |
| T-WAL-03 | B | Nạp 9.999đ, 10.000,5đ, 10^16đ | 400 | `JourneyEdgeCasesTest` | ✅ |
| T-WAL-04 | L | Nạp rồi rút ngay | `TOPUP_LOCKED` trong 24 giờ | WAL-03, `MoneyRulesTest` | ✅ |
| T-WAL-05 | N | Rút dưới 50.000, số lẻ, số tài khoản sai, vượt hạn mức ngày, còn nợ | 400 / 400 / 400 / `WITHDRAW_DAILY_LIMIT` / `DEBT_OPEN` | WAL-01, 04, 05, `MoneyRulesTest` | ✅ |
| T-WAL-06 | Đ | Hai lệnh rút song song vượt số dư | Chỉ một lệnh được khoá tiền | `ConcurrencyTest` | ✅ |
| T-WAL-07 | H/N | Admin duyệt rút: thiếu biên lai, sai số tiền, giờ tương lai, duyệt hai lần, từ chối | Bị chặn đúng từng trường hợp; từ chối thì hoàn tiền | WAL-06, `WithdrawApprovalTest` | ✅ |
| T-WAL-07b | H | Còn nợ: nạp tiền rồi thu nợ | Nợ PAID, hết bị chặn đăng ký phiên | WAL-07, AUC-29b | ✅ |
| T-WAL-08 | Đ | Thu nợ song song | Chỉ trừ ví một lần | `ConcurrencyTest` | ✅ |
| T-WAL-09 | L | Nạp thẻ trộm, mua của shop phụ, rút tiền bán | Shop mới bị giữ tiền bán 7 ngày (`SALE_HELD`), tiền cũ vẫn rút được; shop uy tín không bị giữ | `SellerHoldAndChargebackTest` | ✅ |
| T-WAL-10 | X | Ngân hàng đòi lại tiền nạp (chargeback) | Admin ghi nợ `CHARGEBACK`: thu ngay phần ví có, phần còn lại chặn rút (`DEBT_OPEN`); người không phải Admin bị 403 | `SellerHoldAndChargebackTest` | ✅ (ghi tay, chưa nhận tự động từ cổng) |

#### 4.3 Mua bán giá cố định

| Mã | Loại | Kịch bản | Kết quả mong đợi | Ở đâu | |
|---|---|---|---|---|---|
| T-ORD-01 | H | Giỏ → xem trước → đặt (ví) → shop xác nhận → giao → người mua nhận → đánh giá | Tiền đúng ở cả ba ví, đánh giá một lần | ORD-01, `FullJourneyTest` S1 | ✅ |
| T-ORD-02 | H | Giỏ nhiều shop | Mỗi shop một đơn, phí ship riêng | `MultiShopCheckoutTest` | ✅ |
| T-ORD-03 | H | COD: giao → Staff đối chiếu → người mua nhận → sàn nhận tiền thu hộ | Shop chỉ nhận tiền sau khi sàn nhận; nhập sai số tiền hoặc nhận hai lần bị chặn | ORD-14, `MoneyRulesTest`, S5 | ✅ |
| T-ORD-03b | H | Trả bằng ZaloPay (cổng giả lập) | Đơn chờ thanh toán → cổng báo thành công → chờ shop xác nhận | ORD-13 | ✅ |
| T-ORD-03c | H | Người mua huỷ trước khi shop xác nhận | Hoàn đủ, trả tồn kho | ORD-11 | ✅ |
| T-ORD-04 | X | Shop đổi giá đúng lúc người mua bấm đặt | `PRICE_CHANGED`, không trừ tiền, không giữ hàng | ORD-02, `BaReviewBatch2Test` | ✅ |
| T-ORD-05 | Đ | Hai người tranh cuốn cuối; bấm đặt hai lần | Một người mua được; không tạo trùng đơn | ORD-03, `ConcurrencyTest` | ✅ |
| T-ORD-06 | N | Ví không đủ; giỏ trống; vượt tồn; tin ẩn / chờ duyệt; mua của chính mình | 400 / 409 tương ứng, tồn kho không đổi | ORD-04, 07, 08, `JourneyEdgeCasesTest` | ✅ |
| T-ORD-07 | L | Người từng bom 2 đơn COD; người mới đặt COD lớn | `COD_NOT_ALLOWED` | ORD-05, 06 | ✅ |
| T-ORD-08 | X | ZaloPay báo thành công sau khi đơn đã huỷ / đơn đã trả bằng cách khác | Tiền hoàn vào ví | `RepayOrderTest` | ✅ |
| T-ORD-09 | X | Shop không xác nhận 24 giờ / không giao 3 ngày / im lặng trước yêu cầu huỷ | Tự huỷ, hoàn tiền, tính lỗi shop (trừ trường hợp yêu cầu huỷ) | `ShopSlaAndLockTest` | ✅ |
| T-ORD-10 | X | Shop "giao" mà không giao thật; đơn tự coi là đã giao sau 7 ngày | Người mua khiếu nại "không nhận được hàng", không cần ảnh; shop từ chối thì Admin hoàn tiền | ORD-09, `NotReceivedReturnTest` | ✅ |
| T-ORD-11 | H/N | Trả hàng: thiếu ảnh, quá hạn, trả hai lần; shop đồng ý → gửi trả → nhận lại | Bị chặn / hoàn tiền khi shop nhận lại | ORD-12, `JourneyEdgeCasesTest`, S2 | ✅ |
| T-ORD-12 | X | Được đồng ý trả mà người mua không gửi về; đã gửi mà shop không xác nhận | Tự hoàn tất / chuyển Admin | `MoneyRulesTest`, `ReturnDeadlineTest` | ✅ |
| T-ORD-13 | H | Giao thất bại: lỗi người mua / hãng / shop | Hoàn trừ ship (ship về shop) / hoàn đủ / hoàn đủ + tính lỗi shop | ORD-10, `BaReviewBatch2Test` | ✅ |
| T-ORD-14 | L | Người mua nhập mã gửi trả bịa | Cần ảnh biên nhận bưu cục / hãng thật | | ⚠ |
| T-ORD-15 | B | Hoàn một phần 10–50% | | | ⚠ BR-3.8 |
| T-ORD-16 | X | Shop bị khoá khi có đơn chưa giao | Đơn bị huỷ, hoàn tiền, tin bị ẩn | `ShopSlaAndLockTest` | ✅ |

#### 4.4 Ký gửi và kho

| Mã | Loại | Kịch bản | Kết quả mong đợi | Ở đâu | |
|---|---|---|---|---|---|
| T-CON-01 | H | Gửi yêu cầu → sơ duyệt → hẹn lịch → nhận sách → kiểm định đạt → người bán đồng ý → thành lô → Admin tạo phiên, xếp lô, công bố | Đúng từng bước; sai giá / thiếu lý do / không tích điều khoản / công bố phiên rỗng bị chặn | CON-06, S6 | ✅ |
| T-CON-02 | N | Giá mong muốn dưới mức; email chưa xác thực; hẹn ngoài giờ / quá hạn / trong quá khứ; xem ký gửi người khác | 400 / 403 / 400 / 404 | CON-01..03, `JourneyEdgeCasesTest` | ✅ |
| T-CON-03 | N | Giá kiểm định sai (≤ 0, sàn > ước tính thấp, khởi điểm > sàn); người bán đề nghị giá sàn ngoài khoảng | 400 | `JourneyEdgeCasesTest`, `BusinessRulesBatchTest` | ✅ |
| T-CON-04 | X | Không mang sách tới; không quyết sau kiểm định 7 ngày | Hết hạn / coi như rút | CON-04, `BaReviewGapsTest` | ✅ |
| T-CON-05 | X | Sách không ai nhận lại 60 ngày | Nhắc trước 7 ngày, rồi thu phí kho (thiếu thì nợ) và thanh lý | CON-05, `BaReviewGapsTest` | ✅ |
| T-CON-06 | X | Kho làm mất / hỏng sách ở từng giai đoạn | Bồi thường đúng mức, Admin duyệt | `BusinessRulesBatchTest` | ✅ |
| T-CON-07 | B | Lô không bán: vào phiên sau (tối đa 2), chuyển bán thường, nhận lại; im lặng 7 ngày | Đúng hướng; tự trả sách; trả trong hạn thì không thu phí kho | AUC-28, `AuctionMoneyTest` | ✅ |

#### 4.5 Đấu giá

| Mã | Loại | Kịch bản | Kết quả mong đợi | Ở đâu | |
|---|---|---|---|---|---|
| T-AUC-01 | H | Đăng ký + cọc → mở phiên → trả giá tay và giá tối đa → chốt lô → hoá đơn → trả → kho xác nhận, giao → người mua nhận → người bán nhận giá búa trừ hoa hồng | Tiền đúng, người thua được hoàn cọc ngay, người bán thường không xử lý được đơn đấu giá | AUC-06..26, S6 | ✅ |
| T-AUC-02 | N | Đăng ký khi bị cấm / còn nợ / là nhân viên / chưa xác thực SĐT / không đồng ý quy chế / hai lần / sau hạn | Mã lỗi riêng từng trường hợp | AUC-01..07, `JourneyEdgeCasesTest` | ✅ |
| T-AUC-03 | B | Trả giá thấp hơn mức tối thiểu, bằng giá hiện tại, số lẻ; người dẫn tự đẩy giá | 409 / 400 | AUC-12, 14, `MultiBidderTest` | ✅ |
| T-AUC-04 | B | Giá tối đa trên giá sàn, một mình / có người cạnh tranh; giá tối đa dưới giá sàn | Trả hộ lên giá sàn / chỉ tới giá sàn khi cần / giữ nguyên | AUC-11, `MultiBidderTest` | ✅ |
| T-AUC-05 | Đ | Nhiều người trả giá cùng lúc, kể cả giá tối đa | Một người dẫn, giá tăng dần | `MultiBidderTest`, `ConcurrencyTest` | ✅ |
| T-AUC-06 | X | Trả giá giây cuối (soft close); tạm dừng rồi tiếp tục; huỷ lô đang mở | Kéo dài đồng hồ / trả lại thời gian / vô hiệu lượt trả giá | `MultiBidderTest`, `JourneyEdgeCasesTest` | ✅ |
| T-AUC-07 | B | Lô cao giá chưa cọc thêm | `LOT_DEPOSIT_REQUIRED`; cọc thêm rồi trả giá được | AUC-17..18 | ✅ |
| T-AUC-08 | B | Không đạt giá sàn; không ai trả giá | `RESERVE_NOT_MET` / `NO_BIDS`, không lộ giá sàn | AUC-21 | ✅ |
| T-AUC-09 | X | Người thắng không trả 48 giờ (cọc lớn / nhỏ hơn phạt, ví thiếu thì nợ) | Mất cọc về sàn, phạt, cấm; mời người về nhì ở giá công bằng; người về nhì trả được | AUC-27, `AuctionMoneyTest`, S7 | ✅ |
| T-AUC-10 | X | Vi phạm lần 2, lần 3 trong 12 tháng | Cấm 365 ngày / vĩnh viễn | `BaReviewBatch2Test` | ✅ |
| T-AUC-11 | X | Trả ZaloPay sát hạn, cổng báo chậm | Ân hạn 15 phút, không phạt oan | `AuctionMoneyTest` | ✅ |
| T-AUC-11b | X | Người thắng không nhận được mail báo thắng và chưa đọc thông báo trong app | Không phạt, gia hạn 24 giờ một lần, báo Admin; quá hạn lần hai thì phạt. Đã nhận mail hoặc đã đọc: phạt đúng hạn | `MailOutboxTest` | ✅ |
| T-AUC-12 | X | Thắng, trả tiền rồi từ chối nhận hàng | Phạt như bỏ thanh toán + thu ship chiều đi | `AuctionMoneyTest` | ✅ |
| T-AUC-13 | X | Người thắng bị khoá khi hoá đơn chưa trả | Huỷ không phạt, hoàn cọc, mời người kế tiếp | AUC-25, `BaReviewGapsTest` | ✅ |
| T-AUC-14 | X | Huỷ đăng ký trước hạn; phiên thiếu người: dời một lần rồi huỷ | Hoàn cọc, lô về hàng chờ, không tính lượt | AUC-29, S8 | ✅ |
| T-AUC-15 | L | Người bán đẩy giá bằng tài khoản phụ | Cần IP / thiết bị để phát hiện | | ⚠ BE-25 |
| T-AUC-16 | X | Người về nhì bị cấm / nợ / bị khoá | Bỏ qua, mời người kế tiếp | `AuctionMoneyTest`, `BaReviewGapsTest` | ✅ |
| T-AUC-17 | X | Gõ nhầm thêm một số 0 | Cần hỏi xác nhận | | ⚠ BR-5.10 |
| T-AUC-18 | X | Backend khởi động lại giữa phiên (tắt ~25 giây, lô còn thời gian) | Phiên tiếp tục từ trạng thái trong DB, giữ giá và người dẫn, trả giá tiếp được, chạy tới cuối | `e2e_restart.sh` RST-01..07 | ✅ |
| T-AUC-19 | X | Backend tắt lâu hơn thời gian còn lại của lô (tắt 75 giây, lô còn 58 giây) | Trước đây: bật lại là lô chốt ngay theo giờ cũ, không ai kịp trả giá. **Đã sửa:** nhịp đầu tiên sau khi khởi động kéo dài lô đang mở cho còn ít nhất thời gian soft close, báo cả phòng (`SESSION_RESUMED`) | `MultiBidderTest` (2 ca), `e2e_restart.sh` chạy lại với 75 giây | ✅ |

#### 4.6 Admin, cấu hình, job

| Mã | Loại | Kịch bản | Kết quả mong đợi | Ở đâu | |
|---|---|---|---|---|---|
| T-ADM-01 | N | Đặt cấu hình phá luật (thời hạn 0) | `INVALID_CONFIG` | CFG-01, `BaReviewGapsTest` | ✅ |
| T-ADM-02 | H | Mọi thao tác Admin có nhật ký | Có dòng `activity_logs` | `AdminActivityLogTest` | ✅ |
| T-ADM-03 | X | Hoá đơn đấu giá đã trả mà kho quá hạn xử lý | Báo Staff / Admin một lần | `BaReviewGapsTest` | ✅ |
| T-ADM-04 | X | Job lỗi một bản ghi | Các bản ghi khác vẫn chạy (mỗi bản ghi một giao dịch) | Cấu trúc `each(...)` trong job; chưa có test tiêm lỗi | ⏳ |
| T-ADM-05 | L | Admin tự duyệt khoản rút lớn của mình | Cần người thứ hai | | ⚠ BE-28 |
| T-ADM-06 | X | Hàng đợi mail: việc quan trọng có thư, việc thường không; email chưa xác thực không có thư; giao dịch huỷ không có thư; SMTP lỗi | Gửi đúng một lần; thử lại sau 1 phút, 5 phút, 30 phút, 2 giờ rồi `FAILED` | `MailOutboxTest` | ✅ |
| T-ADM-07 | H | Gửi qua SMTP thật (Gmail / Brevo), thư vào hộp thư đến | | | ⏳ cần tài khoản SMTP |

### 5. Checklist thủ công trên app (tầng C)

Dùng cùng dữ liệu mẫu, mỗi ca kiểm cả điện thoại (375px) và desktop (≥ 1400px):

1. e2e.buyer.rich mua tin 9002 bằng ví, xem lịch sử ví và trạng thái đơn qua từng bước.
2. e2e.buyer.bomber chọn COD: thấy thông báo chặn COD rõ ràng, gợi ý trả bằng ví.
3. e2e.bidder.b vào lô 9102: thấy lỗi cần cọc thêm kèm số tiền, cọc thêm rồi trả giá được.
4. e2e.buyer.banned / e2e.buyer.debt mở phiên 9001: thấy lý do không đăng ký được.
5. e2e.consignor mở ký gửi 9104 (sau khi job chạy): thấy trạng thái "đã rút" và hạn nhận lại sách.
6. Màn trả hàng: lý do "Không nhận được hàng" (**frontend chưa có**, xem `DANH_GIA_BA_TESTER.md phần B` cập nhật 10).

### 6. Ngoài phạm vi (chưa test được)

Giao diện Flutter tự động; ZaloPay thật và callback từ Internet; push / email / SMS; tải lớn (hàng trăm người một phòng đấu giá); chạy nhiều instance; khôi phục sau sự cố DB.

### 7. Kết quả chạy (2026-11-06, máy Mac, PostgreSQL 16.15, JDK 21)

| Tầng | Kết quả |
|---|---|
| A. `./mvnw test` | **185/185 đạt** (gồm 2 ca khởi động lại của T-AUC-19) |
| B. `testdata/e2e_flows.sh` | **133/133 đạt** (bản mở rộng). Các lần chạy hỏng trước đó đều do script: bash 3.2 trên macOS; mong `200` cho API trả `201` (tạo đánh giá, đăng ký phiên); thứ tự ca (trả nợ chạy trước ca "còn nợ thì bị chặn"); cho người đấu giá trả dưới giá sàn rồi mong có hoá đơn |
| B. `testdata/e2e_restart.sh` | **7/7 đạt** hai lần: tắt backend ~25 giây giữa lô; và tắt 75 giây, quá giờ chốt của lô (sau khi sửa T-AUC-19) |
| C. Thủ công | Chưa chạy |

Bản mở rộng thêm các luồng chưa chạy đầu cuối trước đó: khoá tài khoản khi đang đăng nhập; huỷ đơn; trả hàng sai mô tả theo từng bước; trả bằng ZaloPay (cổng giả lập); COD đi hết luồng đến khi sàn nhận tiền thu hộ; rút tiền có Admin duyệt kèm biên lai; trả nợ rồi đăng ký phiên; ký gửi từ đầu qua API đến khi phiên được công bố; nửa sau luồng đấu giá (kho giao, người mua nhận, người bán nhận tiền); bỏ thanh toán và mời mua lần hai; lô không bán, người bán nhận lại sách; huỷ đăng ký; phiên thiếu người dời lịch rồi huỷ; bất biến không ví âm và tổng tiền khớp tiền vào / ra.

Không tìm thấy lỗi nghiệp vụ khi chạy. Một lỗi tìm thấy khi đọc code rồi đã sửa: T-AUC-19 (backend tắt lâu hơn thời gian còn lại của lô thì lô bị chốt ngay khi bật lại). Sau khi sửa: `./mvnw test` 185/185; `e2e_restart.sh` với 75 giây tắt máy 7/7.

Còn chưa tự động: T-ADM-04 (tiêm lỗi vào job); tầng C trên app; các mục ⚠ (cần dịch vụ ngoài hoặc quyết định của chủ sàn).

**Lần chạy tối 2026-11-06 (đợt gửi mail, máy Windows, PostgreSQL 18 tạm ở cổng 5433, JDK 21):** `./mvnw test` **199/200 đạt**; ca còn lại là `SeedDataTest` (gắn cứng cổng 5432). Ba lớp mới: `MailOutboxTest` (8 ca, bật mail với SMTP giả), `OtpAndEmailRulesTest` (4 ca), `SellerHoldAndChargebackTest` (3 ca). Hai lỗi tìm thấy khi chạy rồi đã sửa: health check mail của actuator làm hỏng khởi động khi SMTP là bean giả (và sẽ báo DOWN khi SMTP chậm), nên đã tắt; test gọi ví ngoài giao dịch. Chưa chạy lại tầng B (`e2e_flows.sh`).

Chạy test trên máy không có mật khẩu DB đúng (không cần sửa file nào):

```bash
initdb -D <thư mục tạm> -U postgres -A trust -E UTF8 --locale=C
pg_ctl -D <thư mục tạm> -o "-p 5433" start
psql -h localhost -p 5433 -U postgres -c "CREATE ROLE rebook LOGIN PASSWORD 'rebook';" -c "CREATE DATABASE rebook_dev OWNER rebook TEMPLATE template0;"
DB_URL=jdbc:postgresql://localhost:5433/rebook_dev TEST_DB_URL="jdbc:postgresql://localhost:5433/rebook_dev?currentSchema=rebook_test" ./mvnw test
```

---

# Phần B. Các câu chuyện đầu cuối S1–S8

*(Trước là `E2E_TEST_PLAN.md`.)*

Cập nhật 2026-11-06. Căn cứ: SRS mục 4 (bán giá cố định), 6 (đấu giá), 7 (luồng trạng thái), 8 (ví, phí, cọc) và các quy tắc đã làm thêm ở `DANH_GIA_BA_TESTER.md phần B`, `THAY_DOI_SO_VOI_CODE_CU.md phần B`.

Cách chạy: test tích hợp thật (Spring + PostgreSQL), gọi qua HTTP như app gọi (`MockMvc`), mỗi người dùng đóng đúng vai (USER, STAFF, ADMIN). Chỉ những chỗ không thể chờ thật (đồng hồ lô, hạn thanh toán) mới chỉnh giờ bằng SQL rồi gọi đúng hàm mà job gọi.

Hai lớp test, thư mục `src/test/java/com/rebook/journey/`:

- `FullJourneyTest`: các "câu chuyện" dài, mỗi câu chuyện đi hết một vòng và kiểm **bảo toàn tiền** (tổng ví người tham gia + ví sàn đổi đúng bằng số tiền nạp vào).
- `JourneyEdgeCasesTest`: nhiều ca ngắn: dữ liệu sai, sai quyền, sai trạng thái, đua nhau.

### A. Câu chuyện (FullJourneyTest)

| Mã | Câu chuyện | Kiểm gì |
|---|---|---|
| S1 | Nạp ví qua cổng (giả lập) → shop mới đăng tin → Admin duyệt → người mua bỏ giỏ, thanh toán ví → shop xác nhận, giao, đã giao → người mua xác nhận nhận → đánh giá | Tin shop mới chờ duyệt, người mua chưa thấy; tồn kho giảm; tiền: người mua trừ đúng tổng, người bán nhận giá trừ phí, ví sàn nhận phí; đánh giá một lần |
| S2 | Giao rồi trả hàng, shop đồng ý, người mua gửi trả, shop nhận lại | Hoàn đủ tiền cho người mua, người bán không nhận gì, ví sàn không giữ phí |
| S3 | Trả hàng bị shop từ chối → Admin phân xử (hai nhánh) | Nhánh giữ đơn: người bán nhận tiền; nhánh hoàn: người mua nhận lại tiền |
| S4 | Huỷ đơn: trước khi xác nhận (huỷ tự do), sau khi xác nhận (yêu cầu huỷ, shop đồng ý) | Hoàn tiền ví, trả lại tồn kho |
| S5 | COD: đặt → shop xác nhận, giao → Staff đối chiếu hãng vận chuyển → người mua xác nhận → Admin xác nhận đã nhận tiền thu hộ | Người bán chỉ được trả sau khi sàn nhận tiền COD |
| S6 | Ký gửi → sơ duyệt → hẹn lịch → nhận sách → kiểm định → người bán đồng ý → Admin lập phiên, xếp lô, công bố → đăng ký + cọc → mở phiên → nhiều người trả giá (tay + giá tối đa) → chốt lô → hết phiên → hoá đơn → thanh toán → Staff xuất kho, giao → người mua xác nhận → trả người bán | Cọc khoá/hoàn đúng; người thua nhận lại cọc; hoá đơn = giá búa + phí người mua + phí giao − cọc; người bán nhận giá búa − hoa hồng; bảo toàn tiền |
| S7 | Người thắng không thanh toán đúng hạn | Mất cọc/ bị phạt, bị cấm; người trả giá cao thứ hai được mời nếu đạt giá sàn; người đó thanh toán; người bán vẫn được trả |
| S8 | Phiên thiếu người: dời lịch một lần rồi huỷ | Hoàn cọc toàn bộ; lô quay về chờ xếp phiên |

### B. Ca ngắn (JourneyEdgeCasesTest)

| Nhóm | Ca |
|---|---|
| Số tiền | Nạp 9.999 / 10.000,5 / 10^16: 400. Trả giá 50.000,4: 400; `50000.0`: nhận. Giá tối đa, cọc thêm, giá tin, giá mong muốn ký gửi: số lẻ 400 |
| Ví | Mô phỏng thanh toán của người khác: 403; mô phỏng hai lần: 409; rút dưới tối thiểu: 400; rút quá số dư: 4xx và ví không đổi; tiền vừa nạp chưa rút ngay được |
| Tin đăng | Dưới 3 ảnh, giá < 1.000, tồn kho âm: 400; từ chối không lý do: 400; người mua gọi API Admin: 403; không đăng nhập: 401; tin chờ duyệt không hiện trong danh sách công khai; sửa tin của shop khác: 403/404 |
| Giỏ & đặt hàng | Giỏ trống; số lượng vượt tồn; mua tin của chính mình; ví không đủ; tin đã ẩn; hai shop trong một giỏ ra hai đơn; hai người tranh cuốn cuối (đã có ở `ConcurrencyTest`) |
| Quyền đơn | Người lạ xem / huỷ đơn: 403/404; shop khác xác nhận: 403/404; sai thứ tự (giao trước khi xác nhận, nhận hàng trước khi giao, đánh giá khi chưa hoàn tất): 409 |
| Trả hàng | Thiếu ảnh / mô tả: 400; đơn chưa giao: 409; trả lần hai: 409; quá hạn khiếu nại: 409 |
| Ký gửi | Giá mong muốn dưới mức tối thiểu; email chưa xác thực; hẹn ngoài 8h–17h; hẹn quá hạn; xem ký gửi người khác; kiểm định khi chưa nhận sách; giá kiểm định sai (sàn > ước tính thấp, khởi điểm > sàn); không tích điều khoản; giá sàn đề nghị vượt / thấp hơn khởi điểm; kiểm định không đạt rồi không xếp được phiên |
| Phiên | Xếp lô chưa sẵn sàng / trùng lô; công bố khi chưa có lô, khi hạn đăng ký ở quá khứ; sửa phiên đã công bố; đăng ký khi chưa xác thực SĐT, chưa đồng ý quy chế, ví không đủ cọc, đăng ký hai lần, sau hạn; mở phiên khi chưa đủ người. Từ 2026-11-06: công bố thiếu 72 giờ / hạn đăng ký sát giờ mở, cọc 0, Staff / Admin đăng ký hoặc trả giá, mở phiên ngay ngoài demo (`BusinessRulesBatchTest`, `StartNowDemoGateTest`, `MultiBidderTest`) |
| Bảo mật | Mọi endpoint ví / đơn / đấu giá cần đăng nhập; vai USER không vào được `/staff`, `/admin` |

### C. Điều kiện hoàn thành

- Tất cả ca đạt hoặc được ghi rõ là lỗi tìm thấy kèm cách sửa.
- Mỗi câu chuyện S1–S8 kết thúc bằng kiểm bảo toàn tiền.
- Chạy cả bộ test cũ vẫn đạt (không phá `MoneyRulesTest`, `AuctionMoneyTest`, `MultiBidderTest`).

### D. Chưa nằm trong phạm vi

Giao diện Flutter, cổng ZaloPay thật, thông báo đẩy, tải lớn nhiều trăm người, WebSocket phòng đông.

### E. Kết quả chạy (2026-11-06)

`FullJourneyTest` 16 ca và `JourneyEdgeCasesTest` 15 ca đạt; toàn bộ bộ test backend **144/144 đạt**. Tìm được và sửa 2 lỗi nhờ các ca này: số tiền lẻ / quá lớn được nhận (giờ trả 400), và mất "gộp kiện" phí giao khi người thắng chọn giao tận nơi sau phiên. Chi tiết: [THAY_DOI_SO_VOI_CODE_CU.md phần E](THAY_DOI_SO_VOI_CODE_CU.md) mục J.

### F. Kế hoạch đầy đủ (2026-11-06)

Ma trận ca từ happy case đến hell case, bộ dữ liệu mẫu và test đầu cuối qua HTTP thật: [TEST_PLAN_TOAN_DIEN.md phần A](TEST_PLAN_TOAN_DIEN.md). Lần chạy 2026-11-06: `./mvnw test` 183/183, `testdata/e2e_flows.sh` 133/133, `testdata/e2e_restart.sh` 7/7.

---

# Phần C. Kịch bản demo (bản V2)

*(Trước là `DEMO_V2.md`.)*

> Bản V2 ngày 2026-11-06, thay cho [DEMO.md](../DEMO.md) (bản cũ giữ nguyên). Đổi so với bản cũ, theo luật mới ở [THAY_DOI_SO_VOI_CODE_CU.md phần C](THAY_DOI_SO_VOI_CODE_CU.md):
> cọc / phạt người bỏ thanh toán về sàn 100%, sàn bù chênh cho người bán; mời mua lần hai ở giá công bằng; nhân viên sàn không được đấu giá;
> phí và bước giá chốt lúc công bố phiên; lịch tối thiểu 72 giờ / 24 giờ (môi trường demo đặt 0); nút mở phiên ngay chỉ có ở môi trường demo; kho làm mất / hỏng sách thì sàn bồi thường; ISBN được kiểm số kiểm tra.

### 1. App này là gì (nói 30 giây đầu)

> "ReBook là chợ sách cũ có hai cách mua: **mua giá cố định** như Shopee, và **đấu giá trực tiếp** như phiên đấu giá thật.
> Sách quý được người bán **ký gửi** vào kho của sàn, nhân viên **kiểm định** rồi mới đưa lên đấu giá, nên người mua tin được hàng.
> Tiền đi qua **ví của sàn (escrow)**: người mua trả → sàn giữ → giao xong mới chuyển cho người bán."

**Ba loại người dùng:**

| Vai trò | Làm gì |
|---|---|
| **Người dùng** (`USER`) | Mua sách, đấu giá. Mở shop thì thành người bán, ký gửi sách. Một tài khoản làm được cả ba việc. |
| **Nhân viên kho** (`STAFF`) | Duyệt sơ bộ ký gửi, nhận sách tại kho, kiểm định, quản lý kho, xử lý đơn đấu giá. |
| **Quản trị** (`ADMIN`) | Duyệt tin đăng, quản lý người dùng, danh mục, tạo phiên đấu giá, cấu hình phí, duyệt rút tiền, xử lý khiếu nại. |

**Công nghệ (nếu bị hỏi):**
- Frontend: **Flutter** (một code chạy web, Android, iOS), quản lý state bằng Riverpod, điều hướng go_router.
- Backend: **Spring Boot 3.5 + PostgreSQL**, đăng nhập bằng JWT, đấu giá realtime bằng **WebSocket**.
- Frontend không gọi API thủ công: code client được **sinh tự động từ file OpenAPI** của backend.

**Tài khoản demo** (mật khẩu chung `Rebook@123`):

| Email | Dùng cho |
|---|---|
| `buyer1@rebook.vn` | Người mua: giỏ hàng, ví, đấu giá |
| `seller1@rebook.vn` | Người bán: shop "Nhà Sách Cũ Sài Gòn", tin đăng, đơn, ký gửi |
| `staff@rebook.vn` | Nhân viên kho |
| `admin@rebook.vn` | Quản trị |

---

### 2. Chuẩn bị TRƯỚC giờ demo (làm tối nay, đừng để sáng mai)

**Làm sạch dữ liệu** (xóa các thứ thừa do test; sau lệnh này dữ liệu về đúng như ban đầu):

**Tắt backend trước** (nếu không DB đang bị kết nối nên không xóa được), rồi chạy:

```bash
psql -U postgres -h localhost -c "DROP DATABASE rebook_dev;" -c "CREATE DATABASE rebook_dev OWNER rebook ENCODING 'UTF8' TEMPLATE template0;"
```

Mật khẩu của user `postgres` là mật khẩu bạn đặt lúc cài PostgreSQL. Xong thì bật lại backend, nó tự tạo bảng và nạp lại dữ liệu mẫu.

**Thứ tự bật:**
1. PostgreSQL (thường tự chạy).
2. Backend: IntelliJ chạy `ReBookApplication`, đợi thấy dòng `Started ReBookApplication`. Kiểm tra `http://localhost:8080/categories` ra JSON.
3. Frontend:
   - Demo trên **Chrome**: `flutter run -d chrome --dart-define-from-file=env/local.json`
   - Demo trên **máy ảo Android**: `flutter run -d emulator-5554 --dart-define-from-file=env/android.local.json`
4. Trước khi demo, đăng nhập thử cả 4 tài khoản một lần để chắc chắn chạy.

**Mẹo:**
- Dữ liệu mẫu (DB vừa làm sạch) có sẵn **phiên #1 "Sách cổ Việt Nam trước 1975"**: đã công bố, 3 lô, `buyer1`, `buyer2`, `buyer3` đã đăng ký và cọc 500.000đ. Mở ngay bằng Swagger (mục 3.5), không phải tạo phiên. Muốn tạo phiên mới thì dùng lô "sẵn sàng" có sẵn (dữ liệu mẫu có 1 lô, hiện ở bước **Xếp lô** của màn Phiên đấu giá). Tập trước ít nhất một lần; chạy xong phải làm sạch DB mới chạy lại được.
- Dùng **hai cửa sổ**: Chrome cho admin, máy ảo (hoặc cửa sổ ẩn danh) cho người mua. Như vậy không phải đăng xuất liên tục.
- Cắm sạc, tắt thông báo hệ thống, phóng to chữ nếu chiếu lên máy chiếu.

---

### 3. Các luồng demo (theo thứ tự nên trình bày)

#### 3.1. Mua hàng giá cố định (`buyer1`) — luồng cơ bản, mở màn

1. Mở app → trang giới thiệu → **Đăng nhập** `buyer1@rebook.vn`.
2. **Mua sách** (trang chủ): băng chuyền, "Đang được săn", "Mới lên kệ", kệ theo danh mục ở thanh bên.
3. **Tìm kiếm**: gõ tên sách, lọc theo danh mục, tình trạng sách, khoảng giá; sắp xếp mới nhất / giá tăng / giá giảm / bán chạy.
4. Bấm vào một cuốn → **chi tiết**: ảnh bìa, tình trạng, giá, shop (điểm đánh giá), mô tả → **Thêm vào giỏ**.
5. **Giỏ hàng**: giỏ chia theo shop, đổi số lượng, xóa. Nhớ: tin chỉ còn 1 cuốn thì không tăng được.
6. **Thanh toán**: chọn địa chỉ nhận → app hiện **phí ship** (nội tỉnh rẻ hơn liên tỉnh, tính theo khối lượng) → chọn phương thức:
   - **COD** (trả khi nhận), **Ví ReBook**, hoặc **ZaloPay** (sandbox).
   - Demo nên chọn **Ví ReBook** (nhanh, không cần cổng ngoài). buyer1 có ví khoảng 4,9 triệu.
7. Đặt xong, hệ thống **tách đơn theo shop**. Vào **Đơn mua** xem trạng thái.

> Điểm nói: "Giỏ nhiều shop thì tự tách thành nhiều đơn, mỗi shop giao riêng."

#### 3.1b. Đăng sách lên bán và duyệt tin (`seller2` → `admin`), có thể trình bày trước 3.1

Dùng `seller2@rebook.vn` (shop "Tiệm Sách Hà Nội Xưa", **chưa uy tín**) để khán giả thấy bước duyệt. `seller1` là shop uy tín nên tin tự duyệt, không có bước này.

1. `seller2` → **Bán sách** → **Tin đăng** → **Đăng sách**. Nhập:
   - Bắt buộc: tên, tác giả, danh mục, **tình trạng** (5 bậc: Mới, Như mới, Tốt, Khá, Trung bình), cân nặng, **ít nhất 3 ảnh**, giá (≥ 1.000đ), số lượng.
   - Tuỳ chọn: NXB, năm xuất bản, **ISBN**, ngôn ngữ, số trang, mô tả.
2. Minh hoạ luật ISBN (nói khi gõ):
   - Gõ ISBN có dấu gạch hoặc ISBN-10 vẫn nhận; hệ thống kiểm **số kiểm tra**, gõ sai một số là báo "ISBN không hợp lệ".
   - ISBN-10 được đổi và lưu thành ISBN-13; ô tìm kiếm gõ kiểu nào cũng ra.
   - Sách cũ trước 1970 thường **không có ISBN**: để trống vẫn đăng được. Có ISBN mà năm < 1970 thì hệ thống gắn cờ cảnh báo cho người duyệt (app chưa hiện cờ này).
3. Lưu → app báo "Đã lưu. Tin đăng chờ ReBook duyệt." Tin ở trạng thái **Chờ duyệt**, người mua chưa thấy.
4. `admin` → **Duyệt tin đăng**: mở tin vừa đăng (dữ liệu mẫu có sẵn một tin chờ duyệt của seller2) → **Duyệt**, hoặc **Từ chối** kèm lý do ("Ảnh không đạt", "Sai thông tin sách", "Nội dung bị cấm"). Shop nhận thông báo.
5. Quay lại `seller2`: tin đã **Đang bán**. Sửa **giá / số lượng** thì vẫn đang bán; sửa **tên, tác giả, ISBN, NXB, năm, tình trạng, mô tả hoặc ảnh** thì tin quay lại Chờ duyệt. **Ẩn tin** / **Hiện lại** không phải duyệt lại.

> Điểm nói: "Shop mới phải qua duyệt; shop uy tín được tự duyệt, nhưng tỷ lệ đơn lỗi vượt 10% thì tự mất uy tín."

#### 3.2. Người bán xử lý và giao đơn (`seller1`)

1. Đăng nhập `seller1`. **Kênh người bán**: thống kê (doanh thu, đơn chờ xác nhận, đang giao…).
2. Mở đơn `buyer1` vừa đặt (mục 3.1), trạng thái **Chờ xác nhận** (shop có 24 giờ):
   1. **Xác nhận đặt hàng** → đơn **Đang chuẩn bị**, bắt đầu hạn 3 ngày giao cho vận chuyển.
   2. **Giao cho shipper** → ô "Mã vận đơn (không bắt buộc)", để trống thì hệ thống tự sinh mã `RB…` → đơn **Đang giao**.
   3. **Giả lập: đã giao thành công** → đơn **Đã giao**. Nút này chỉ có ở môi trường dev (thay cho hãng vận chuyển báo về); môi trường thật nút trả lỗi, Staff đối chiếu với hãng.
3. **Tin đăng**: xem tin, sửa tồn kho, ẩn / hiện tin. Tin về 0 cuốn tự chuyển **Hết hàng**.

> Vòng đời đơn: `Chờ thanh toán → Chờ xác nhận → Đang chuẩn bị → Đang giao → Đã giao → Hoàn tất`. Có nhánh Hủy, Trả hàng, Giao thất bại.
> Đơn COD: tiền chỉ về ví shop sau khi Admin xác nhận đã nhận tiền thu hộ, mà màn này **chưa có trên app** (gọi `POST /admin/cod/{orderId}/remit` bằng Swagger). Vì vậy demo nên trả bằng **Ví ReBook**.

#### 3.3. Hoàn tất đơn, đánh giá, trả hàng (quay lại `buyer1`)

1. **Đơn mua** → mở đơn **Đã giao** → **Đã nhận hàng** → xác nhận. Đơn hoàn tất, **tiền mới chuyển từ "giữ" sang ví người bán** (trừ phí sàn 5%). Nút chỉ hiện sau khi shop bấm "Giả lập: đã giao thành công".
   - Shop uy tín (`seller1`) rút được tiền này ngay. Shop mới (chưa uy tín, mở dưới 30 ngày hoặc dưới 10 đơn hoàn tất) bị giữ tiền bán **7 ngày** trước khi rút (chống rửa tiền qua shop phụ).
2. **Đánh giá** shop (sao + nhận xét) sau khi hoàn tất.
3. Hoặc **Yêu cầu trả hàng** (kèm lý do, ảnh) khi hàng không đúng mô tả. Người bán đồng ý / từ chối; không đồng thuận thì **admin phân xử** ở mục Khiếu nại.
4. Nếu không bấm gì, đơn **tự hoàn tất sau 3 ngày**.

> Điểm nói: "Đây là escrow: tiền chưa vào tay người bán cho tới khi người mua nhận hàng."

#### 3.4. Ví ReBook (`buyer1`)

- **Ví ReBook**: số dư khả dụng và số dư đang bị giữ (đặt cọc đấu giá, tiền chờ giải ngân).
- **Nạp tiền**: tạo giao dịch nạp; môi trường dev có nút **giả lập thanh toán thành công** (không cần ZaloPay thật). Tiền mới nạp bị khoá **24 giờ** trước khi rút.
- **Lịch sử giao dịch**: mỗi dòng là một bút toán (nạp, thanh toán, hoàn tiền, cọc, phí…). Sổ cái **chỉ ghi thêm, không sửa**.
- Người bán có thêm **Rút tiền** (dùng tài khoản ngân hàng đã khai khi mở shop), admin duyệt sau.

#### 3.5. ĐẤU GIÁ TRỰC TIẾP — phần ăn điểm nhất, tập kỹ

**Khái niệm cần nói được:**
- Phiên có nhiều **lô**, mỗi lô chạy tuần tự, mặc định **60 giây/lô**.
- Muốn trả giá phải **đăng ký phiên và đặt cọc** trước. **Hạn mức trả giá = tiền cọc × 10.**
- **Bước giá** tăng theo mốc: dưới 200k nhảy 10k; từ 200k nhảy 50k; từ 1 triệu nhảy 100k; từ 5 triệu nhảy 500k.
- **Soft close**: trả giá khi còn dưới 15 giây thì đồng hồ **được kéo lại 15 giây** (chống "bắn tỉa" phút chót).
- **Giá sàn (reserve)**: giá thấp nhất người bán chấp nhận. Gõ búa mà chưa tới sàn thì lô **không bán được**.
- **Trả giá tự động (proxy bid)**: đặt mức tối đa, hệ thống tự đáp thay mình tới mức đó.
- **Người trả giá cao nhất khi hết giờ thắng.** Phải thanh toán trong **48 giờ**; bỏ thanh toán thì **mất cọc** (hoặc bị phạt 10% giá búa nếu lớn hơn), tiền **về sàn**, và **bị cấm đấu giá 90 ngày**.
- Người trả giá cao thứ hai được **mời mua lần hai ở giá công bằng**: giá họ lẽ ra phải trả nếu không có người bỏ (giá người kế tiếp + 1 bước), không vượt giá họ đã trả, không dưới giá sàn. Lô bán lại thấp hơn thì sàn **bù phần chênh** cho người bán.
- **Nhân viên sàn (Staff / Admin) không được đấu giá**, vì Staff kiểm định lô và biết giá sàn.
- Lúc **công bố** phiên, phí người mua và bảng bước giá được **chốt vào phiên**; Admin đổi cấu hình sau đó không ảnh hưởng phiên đã công bố.
- Người thắng trả thêm **phí người mua 10%**, người bán trả **hoa hồng 15%**.
- Đồng hồ do **server giữ**, app chỉ đếm ngược theo giờ server (nên chạy máy nào cũng khớp).

**Cách nhanh nhất: dùng phiên #1 có sẵn trong dữ liệu mẫu** (3 lô sách trước 1975, `buyer1/2/3` đã đăng ký):

1. Mở `http://localhost:8080/swagger-ui.html` → `POST /auth/login` với `admin@rebook.vn` / `Rebook@123` → chép `accessToken` → **Authorize** (dán token).
2. Gọi `POST /admin/sessions/1/start`: phiên chuyển sang chạy ngay (chỉ chạy ở profile `dev`).
3. Mở `buyer1` và `buyer2` ở hai cửa sổ để tranh nhau (hạn mức mỗi người 5.000.000đ = cọc × 10). Mỗi lô 60 giây, nghỉ 7 giây giữa hai lô.

**Hoặc tự tạo một phiên LIVE (làm trước khi demo vài phút):**

1. Đăng nhập `admin@rebook.vn` → **Phiên đấu giá** → **Tạo phiên**:
   - Tên, mô tả; **giờ bắt đầu** là vài phút nữa; **hạn đăng ký** trước giờ bắt đầu; số người tối thiểu **1**; tiền cọc ví dụ **500.000**; thời gian mỗi lô **30 giây** cho nhanh.
2. **Xếp lô**: chọn lô "sẵn sàng" (lô đã kiểm định và chờ xếp phiên) vào phiên.
3. **Công bố** phiên.
4. Đăng nhập `buyer1` (cửa sổ khác) → **Đấu giá** → vào phiên → **Đăng ký + đặt cọc**.
5. Đến giờ bắt đầu, hệ thống **tự mở phiên** (đủ người đăng ký). Muốn bắt đầu ngay: mở `http://localhost:8080/swagger-ui.html`, đăng nhập admin lấy token, bấm Authorize, gọi `POST /admin/sessions/{id}/start`. Nút này **chỉ chạy ở profile `dev`** (môi trường demo); môi trường thật trả `DEMO_ONLY`.
   - Ở môi trường thật, catalogue phải công bố **trước giờ mở ít nhất 72 giờ** và hạn đăng ký **trước giờ mở ít nhất 24 giờ**. Dữ liệu demo (profile `dev`) đặt hai mốc này bằng 0 nên vẫn tạo phiên "vài phút nữa" được.

**Trình diễn:**
1. `buyer1` vào **phòng đấu giá**: thấy lô đang mở, giá hiện tại, đồng hồ đếm ngược, danh sách người trả giá (hiện số paddle `#001`, không lộ tên).
2. Bấm **Trả giá** → giá nhảy lên ngay. Cửa sổ khác cũng cập nhật ngay (**WebSocket**).
3. Đặt **trả giá tự động** một mức cao hơn để minh họa proxy bid.
4. Trả giá phút chót để thấy **soft close** kéo đồng hồ.
5. Hết giờ: lô **bán / không bán** (chưa tới giá sàn). Sang lô kế tiếp.
6. Hết phiên: xem **Kết quả** từng lô; "Đấu giá của tôi" hiện các phiên đã đăng ký.
7. Admin có thể **Tạm dừng / Tiếp tục** phiên (nhắc: dùng khi có sự cố).

> Nếu bị hỏi "hai người cùng trả đúng một mức thì sao": người đến sau nhận lỗi *giá đã thay đổi* (khóa lạc quan trong DB), không bao giờ bán trùng.

#### 3.5b. Sau phiên: thanh toán hoá đơn và kho giao lô (`buyer1` → `staff` → `buyer1`)

Sách đấu giá nằm ở **kho của sàn**, nên **nhân viên kho giao**, không phải người bán.

1. **`buyer1` thắng một lô** → nhận thông báo (và mail nếu bật `MAIL_ENABLED`) "Bạn đã thắng đấu giá!" kèm hạn **48 giờ**. Người không thắng lô nào được hoàn cọc ngay khi phiên kết thúc.
2. `buyer1` → **Đơn mua** → mở **Hóa đơn đấu giá**: hoá đơn = giá búa + **phí người mua 10%** + phí giao − **cọc 500.000đ** (cọc trừ vào hoá đơn đầu tiên).
3. **Thanh toán hóa đơn** → chọn **Cách nhận sách**:
   - **Giao tận nơi**: chọn địa chỉ; phí giao tính từ tỉnh của kho tới tỉnh người nhận. Thắng nhiều lô cùng phiên thì phí giao gộp thành một kiện.
   - **Nhận tại kho ReBook**: phí giao 0đ.
   - Trả bằng **Ví ReBook** (nhanh nhất) hoặc ZaloPay. Trả xong: hoá đơn **Chờ xác nhận**, sách trong kho được giữ cho người thắng, **giá búa vào túi "đang giữ" của người bán**.
4. **`staff` → Giao lô đấu giá**:
   1. **Xác nhận hoá đơn** (đơn Chờ xác nhận → Đang chuẩn bị). Màn này **chưa có nút cho bước này**: dùng Swagger, đăng nhập `staff@rebook.vn`, gọi `GET /staff/orders?status=PENDING_CONFIRM` lấy `id`, rồi `POST /staff/orders/{id}/confirm`. Hạn thật là 24 giờ, quá hạn hệ thống báo Staff và Admin.
   2. **Xuất kho giao** → đơn **Đang giao**, mã vận đơn tự sinh, sách trong kho chuyển "đã xuất".
   3. **Đã giao** → đơn **Đã giao**.
   - Đơn **nhận tại kho**: không bấm "Xuất kho giao" (sẽ báo lỗi đơn nhận tại kho); khi người thắng tới lấy, gọi `POST /staff/orders/{id}/delivered` bằng Swagger (app chưa có nút bàn giao tại kho).
5. **`buyer1` → Đã nhận hàng** → hoá đơn **Hoàn tất**. Lúc này người ký gửi mới nhận **giá búa − hoa hồng 15%**; sàn giữ phí người mua và phí giao. Không bấm thì tự hoàn tất sau 3 ngày.
6. Đăng nhập người ký gửi của lô (lô "Truyện Kiều" và lô số 3 là của `seller1`, lô số 1 là của `seller2`) → **Ví**: thấy dòng giải ngân và dòng hoa hồng.

> Điểm nói: "Người mua trả tiền vào sàn, sàn giữ tới khi người mua nhận sách. Vì sàn đã kiểm định, nếu sách khác báo cáo tình trạng thì **sàn chịu trách nhiệm**: Staff xử lý trả hàng, hoàn đủ cho người mua, lô quay về kiểm định lại."
> Nếu bị hỏi "người thắng nhận rồi từ chối hàng": Staff báo giao thất bại do người mua → hoàn tiền nhưng **phạt như bỏ thanh toán** và thu phí giao chiều đi.

#### 3.6. Ký gửi sách đi đấu giá (`seller1` → `staff`) — luồng nghiệp vụ dài, kể bằng lời kết hợp 2-3 màn hình

Chuỗi trạng thái: **Gửi yêu cầu → Sơ duyệt → Đặt lịch hẹn → Mang sách tới kho → Kiểm định → Người bán chấp nhận → Lên lô đấu giá.**

1. **`seller1`: Ký gửi đấu giá → Tạo yêu cầu**: thông tin sách, ảnh, **giá mong muốn** (tối thiểu **300.000**, thấp hơn bị từ chối ngay), câu chuyện / nguồn gốc cuốn sách.
2. **`staff`**: **Ký gửi** → duyệt sơ bộ (đạt / không đạt kèm lý do).
3. **`seller1`**: yêu cầu đã duyệt → **đặt lịch hẹn** mang sách tới kho (giờ nhận **8:00–17:00**, trong vòng **7 ngày**) → nhận **mã lịch hẹn**.
4. **`staff`**: **Lịch hẹn** → nhập mã → **nhận sách (check-in)**, gán kệ kho.
5. **`staff`**: **Kiểm định**: tick checklist (đủ trang, đúng ấn bản, bìa, gáy, ẩm mốc, chữ ký…), chấm tình trạng, **ước giá thấp – cao**, đề xuất **giá khởi điểm** và **giá sàn**, chụp ảnh. Kết quả đạt / không đạt.
6. **`seller1`**: xem kết quả kiểm định → **đồng ý**, **đề xuất giá sàn khác** (counter), hoặc **rút lại**.
7. Sau khi đồng ý, sách thành **lô sẵn sàng**, admin xếp vào phiên (mục 3.5).
8. Lô **không bán được**: người bán chọn **đưa vào phiên sau**, **chuyển bán giá cố định**, hoặc **nhận sách về**.

> Dữ liệu mẫu đã có sẵn 4 yêu cầu của seller1 ở các bước khác nhau (đã đặt hẹn, đã kiểm định chờ quyết định, đã chấp nhận) và 7 yêu cầu bên phía staff, nên không cần làm từ đầu. Chọn 1-2 yêu cầu có sẵn để thao tác.
> Phí lưu kho: miễn phí **14 ngày**, sau đó **5.000đ/ngày/cuốn**.

#### 3.7. Quản trị (`admin`)

Mở bằng `admin@rebook.vn`, giao diện quản trị riêng:

| Mục | Làm gì |
|---|---|
| **Tổng quan** | Doanh thu tháng, số đơn, tin chờ duyệt, tỷ lệ lô bán được |
| **Tin đăng** | Duyệt / từ chối tin chờ duyệt (từ chối phải có lý do). Dữ liệu mẫu có 1 tin chờ duyệt của seller2. |
| **Người dùng** | Tìm, **khóa / mở khóa** tài khoản (khóa cần lý do) |
| **Danh mục** | Thêm / sửa / xóa (danh mục dạng cây, có con thì không xóa được) |
| **Phiên đấu giá** | Tạo, xếp lô, công bố, tạm dừng / tiếp tục |
| **Cấu hình** | Phí sàn %, phí người mua, hoa hồng, phí kho, bước giá, thời hạn thanh toán… **Sửa là áp dụng cho giao dịch sau đó** |
| **Rút tiền** | Duyệt yêu cầu rút tiền của người bán |
| **Khiếu nại** | Phân xử trả hàng: hoàn tiền hoặc không |

#### 3.8. Việc phụ nên lướt qua

- **Đăng ký tài khoản**: nhập thông tin → nhận mã **OTP** xác thực email. Bật mail (`MAIL_ENABLED=true` trong `apps/backend/.env`) thì mã tới hộp thư thật; không bật thì profile `dev` trả mã trong phản hồi API (trường `devOtp`), log backend **không còn in mã**. Xin lại mã phải chờ 60 giây.
- **Thông báo**: chuông ở thanh bên, hiện sự kiện đơn hàng, bị trả giá vượt, trúng đấu giá…
- **Hồ sơ / Địa chỉ**: sửa tên, SĐT, quản lý nhiều địa chỉ, chọn mặc định.
- **Giao diện**: kiểu **Liquid Glass** (kính mờ), chạy **responsive**: màn rộng có thanh bên, điện thoại có thanh tab dưới. Thu nhỏ cửa sổ Chrome để cho thấy.
- **Đổi ngôn ngữ**: vi / en trong Cài đặt (nếu có mục đó).

---

### 4. Thứ tự demo gợi ý (khoảng 10–12 phút)

| Phút | Nội dung |
|---|---|
| 0–1 | Giới thiệu app + 3 vai trò |
| 1–3 | **3.1b**: `seller2` đăng sách (nói luật ISBN, tình trạng, 3 ảnh) → `admin` duyệt |
| 3–6 | **3.1 + 3.2 + 3.3**: `buyer1` mua bằng ví → `seller1` xác nhận, giao cho shipper, giả lập đã giao → `buyer1` đã nhận hàng, đánh giá (nhấn escrow) |
| 6–10 | **3.5 Đấu giá live** trên phiên #1 có sẵn (`buyer1` và `buyer2` hai cửa sổ cạnh nhau) |
| 10–12 | **3.5b**: `buyer1` thanh toán hoá đơn (giao tận nơi) → `staff` xác nhận (Swagger), xuất kho giao, đã giao → `buyer1` đã nhận hàng → ví người ký gửi |
| 12–13 | **3.6 Ký gửi** (kể ngắn, chỉ mở 2–3 màn của staff và seller) |
| 13–14 | **3.7 Admin**: cấu hình phí; kết luận |

Nếu thiếu giờ, **bỏ 3.6 và 3.8**, giữ đấu giá và 3.5b. Mở sẵn Swagger đã Authorize bằng tài khoản `staff` trước khi demo để bước xác nhận hoá đơn không bị chậm.

---

### 5. Câu hỏi hay gặp & cách trả lời

| Hỏi | Trả lời |
|---|---|
| Hai người trả giá cùng lúc? | Mỗi lô có số phiên bản (khóa lạc quan). Người trả sau bị báo "giá đã thay đổi". |
| Chống bắn tỉa phút chót? | Soft close: còn dưới 15 giây mà có người trả thì đồng hồ về 15 giây. |
| Tiền người mua đi đâu? | Vào ví sàn, giữ ở trạng thái "held", chỉ giải ngân cho người bán khi hoàn tất đơn. |
| Người thắng không trả tiền? | Mất cọc hoặc phạt 10% giá búa (lấy mức lớn hơn), tiền về sàn; thiếu thì ghi nợ, còn nợ thì không đăng ký, trả giá, rút tiền được; bị cấm đấu giá 90 ngày. Người trả cao thứ hai được mời mua ở giá công bằng; lô bán thấp hơn thì sàn bù chênh cho người bán. |
| Người thắng tắt app, không biết mình thắng thì sao? | Có mail báo thắng và mail nhắc trước hạn. Tới hạn mà mail chưa gửi được và người đó chưa đọc thông báo trong app thì không phạt, hệ thống gia hạn 24 giờ một lần và báo Admin. |
| Lấy thẻ trộm nạp ví, mua của shop phụ rồi rút? | Tiền mới nạp khoá 24 giờ; tiền bán hàng của shop mới giữ 7 ngày. Ngân hàng đòi lại tiền thì Admin ghi nợ chargeback, người đó không rút được tới khi trả. |
| Người bán dùng tài khoản phụ đẩy giá rồi bỏ? | Không còn lợi: cọc bị thu về sàn hết (không chia cho người bán), và người mua thật chỉ được mời ở giá họ lẽ ra phải trả, không phải giá tối đa họ đã đặt. |
| Nhân viên có đấu giá được không? | Không. Tài khoản Staff / Admin bị chặn đăng ký và trả giá (`STAFF_CANNOT_BID`), vì họ biết giá sàn. |
| Kho làm mất / hỏng sách thì sao? | Staff khai báo sự cố, Admin duyệt rồi sàn bồi thường theo giai đoạn: chưa kiểm định = giá mong muốn (tối đa 2 triệu); đã kiểm định = mức thấp của giá ước tính; người thắng đã trả tiền = hoàn đủ + 10% giá búa, người bán nhận giá búa − hoa hồng. |
| Kiểm ISBN thế nào? | Không bắt buộc (sách cũ trước 1970 không có ISBN). Có nhập thì bỏ dấu gạch, kiểm số kiểm tra, đổi ISBN-10 sang ISBN-13; đổi ISBN / NXB / năm thì tin phải duyệt lại. |
| Realtime làm bằng gì? | WebSocket thuần, server gửi JSON `LOT_OPENED`, `BID_PLACED`, `LOT_CLOSED`… Mất mạng thì tự nối lại và tải lại trạng thái. |
| Bảo mật đăng nhập? | JWT access token ngắn hạn + refresh token xoay vòng; mật khẩu băm BCrypt; phân quyền USER / STAFF / ADMIN ở backend. |
| Sao frontend gọi API gọn vậy? | Client được sinh tự động từ OpenAPI; backend đổi API thì sinh lại, không viết tay. |
| Số tiền có sai số không? | Dùng `BigDecimal` / `NUMERIC(15,0)`, mọi thay đổi số dư khóa dòng ví và ghi sổ cái bất biến. |
| Có chạy được trên điện thoại thật? | Cùng một codebase Flutter, đã chạy thử trên web và máy ảo Android. |

---

### 6. Những điều KHÔNG nên hứa / nên nói thật (tránh bị hỏi vặn)

- **ZaloPay** chỉ là sandbox (không trừ tiền thật); demo thường dùng ví hoặc nút giả lập thanh toán thành công (chế độ dev).
- **Màn Staff chưa đủ nút** cho hoá đơn đấu giá vừa thanh toán và cho bàn giao tại kho; **chưa có màn đối chiếu hãng vận chuyển và đối soát COD**. Các bước này đang gọi bằng Swagger.
- **Bộ sách** (nhiều tập) chưa có khái niệm riêng: đăng thành một tin / một lô đặt tên "Bộ X (n tập)".
- **Email**: gửi thật qua SMTP khi bật `MAIL_ENABLED` (OTP, thắng đấu giá, nhắc hạn). **SMS** chưa có: mã xác thực SĐT tạm gửi qua email. Không bật mail thì mã nằm trong phản hồi dev (`devOtp`).
- **Upload ảnh**: backend chưa có dịch vụ lưu ảnh (Cloudinary). Ảnh người dùng chọn hiện được trên máy nhưng gửi lên server là **ảnh mẫu thay thế**.
- **Vận chuyển**: giả lập bằng nút bấm (đã giao / giao thất bại), chưa nối hãng vận chuyển.
- **Thông báo đẩy (FCM)**: chưa làm; thông báo trong app qua WebSocket.
- **Trang chủ, thống kê người bán**: backend không có endpoint riêng, app tự ghép từ danh sách tin / đơn.
- Bộ máy chạy phiên đấu giá chỉ chạy đúng với **một** bản backend.

---

### 7. Sự cố thường gặp ngay lúc demo

| Hiện tượng | Xử lý |
|---|---|
| App quay mãi / lỗi mạng | Backend chưa chạy hoặc sai cổng. Kiểm tra `http://localhost:8080/categories`. |
| Máy ảo không vào được API | Phải chạy bằng `env/android.local.json` (dùng `10.0.2.2`). |
| "Cổng 8080 đang được sử dụng" | Còn một backend cũ đang chạy. Dùng luôn bản đó hoặc tắt rồi chạy lại. |
| Đấu giá báo "chưa đăng ký" | Quên đăng ký + cọc phiên cho tài khoản đang dùng. |
| Phiên không tự bắt đầu | Chưa đủ người đăng ký, hoặc chưa tới giờ. Dùng Swagger gọi `POST /admin/sessions/{id}/start`. |
| Mở phiên ngay báo `DEMO_ONLY` | Backend không chạy profile `dev`. Chạy lại backend profile `dev` (mặc định). |
| Công bố phiên báo "phải công bố ít nhất 72 giờ…" | DB không có dữ liệu demo (seed `V13_1`). Chạy profile `dev`, hoặc Admin đặt `auction.min_publish_lead_hours` và `auction.min_registration_close_hours` bằng 0 ở màn Cấu hình. |
| Tài khoản Staff / Admin trả giá bị chặn | Đúng luật mới: dùng tài khoản người mua (`buyer1`…) để đấu giá. |
| Shop rút tiền bán hàng báo `SALE_HELD` | Đúng luật mới: shop mới (chưa uy tín, mở dưới 30 ngày hoặc dưới 10 đơn hoàn tất) bị giữ tiền bán 7 ngày. Demo thì dùng shop uy tín (`seller1`), hoặc Admin đặt `wallet.seller_hold_days` = 0. |
| Backend không khởi động, báo "app.mail.enabled=true nhưng chưa đặt MAIL_HOST" | Đặt `MAIL_HOST` trong `.env`, hoặc `MAIL_ENABLED=false`. |
| Trả giá bị từ chối "vượt hạn mức" | Cọc chưa đủ (hạn mức = cọc × 10). Đặt cọc thêm. |
| Đăng nhập báo sai mật khẩu | Mật khẩu mẫu là `Rebook@123` (phân biệt hoa thường). |
| Dữ liệu lộn xộn sau nhiều lần test | Chạy lại lệnh **làm sạch dữ liệu** ở mục 2. |
