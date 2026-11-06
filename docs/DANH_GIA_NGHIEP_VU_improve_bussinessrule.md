# Đánh giá nghiệp vụ của nhánh `improve_bussinessrule`

Ngày 06/11/2026. Tổng hợp buổi trao đổi về nghiệp vụ mới ở nhánh `origin/improve_bussinessrule` (commit `5593dbf`, tác giả Phitruong, đặt trên `6af440c` của `main`) và việc chuẩn bị demo với thầy. Chỉ nói về **nghiệp vụ và xử lý ngoại lệ**; giao diện tính sau.

Cách đọc: mục 2–4 là những gì **đã kiểm chứng** (có nói rõ kiểm bằng gì). Mục 5–6 là những gì **chưa làm hoặc chưa kiểm**. Mục 7–8 là đề xuất, không phải sự thật đã xảy ra.

## 1. Phạm vi và cách đã kiểm

- Đọc `docs/BEFORE_AFTER.md` của nhánh, migration `V9__money_rules.sql` và `DebtService`. **Chưa đọc từng dòng** `OrderService` (thêm khoảng 300 dòng) và `AuctionSettlement`; phần đó chỉ dựa vào test.
- Chạy toàn bộ test backend của nhánh trong thư mục riêng: **144 test đạt**, riêng `SeedDataTest` lỗi khởi động (tài liệu của nhánh cũng ghi sẵn ngoại lệ này; chưa tra nguyên nhân).
- Dựng nhánh ở cổng 8082 với database riêng và chạy khoảng 40 tình huống lỗi qua API (mục 3).
- Chạy lại bộ kịch bản API cũ (viết cho luật cũ): 4 ca lệch, 2 ca do kịch bản và trạng thái dữ liệu, 2 ca còn lại do cách đo. DTO của nhánh chỉ **thêm** trường, không đổi hợp đồng. Chưa chạy phiên đấu giá trực tiếp trên nhánh mới.
- Đã dọn: tắt backend tạm, xoá thư mục tạm và database tạm. Không merge, không push gì từ nhánh này.

## 2. Nhánh đã cải thiện gì (cũ → mới)

| Nhóm | Trước | Bây giờ |
|---|---|---|
| Ví | Nạp xong rút ngay được; không có mức rút tối đa; không có công nợ | Tiền mới nạp khoá 24 giờ (cấu hình được, đặt 0 để tắt); hạn mức rút mỗi ngày; công nợ phạt / phí kho thu dần từ số dư; `GET /wallet/withdrawable` |
| Đơn hàng | Hoàn tất COD là cộng thẳng tiền cho shop; shop tự bấm "đã giao" | COD đối soát với hãng vận chuyển rồi mới trả shop; xác nhận giao do người mua / hãng; nút giả lập chỉ bật ở môi trường dev |
| Trả hàng | Shop đồng ý là hoàn tiền ngay | Theo bước: shop đồng ý → người mua gửi trả (mã vận đơn) → shop / kho xác nhận nhận sách → mới hoàn tiền |
| Phí sàn | Đọc cấu hình lúc hoàn tất, Admin đổi thì đơn cũ bị tính lại | Chụp tỷ lệ phí lúc đặt (`fee_percent`); hoa hồng đấu giá chụp lúc chấp nhận hợp đồng |
| Đặt hàng song song | Hai request cùng giỏ có thể tạo hai bộ đơn | Khoá ví khi đặt, chỉ một đơn được tạo |
| Shop ngâm đơn | Đơn đã xác nhận không có hạn | Quá 3 ngày chưa giao vận chuyển: tự huỷ, hoàn tiền, tính lỗi shop |
| Đấu giá | Người thắng bỏ thanh toán chỉ mất cọc ở lô đầu; không có huỷ đăng ký | Phạt theo từng lô bỏ (lớn hơn giữa cọc và 10% giá búa); huỷ đăng ký trước hạn hoàn đủ cọc; mời người trả giá thứ hai phải đủ điều kiện |
| Trả giá nhiều người | Có 3 lỗi: giá tối đa sau giờ chốt, hoà giá cướp vị trí, giá tối đa lúc tạm dừng | Đã sửa cả 3 (12 ca `MultiBidderTest`) |
| Nhật ký | Chỉ ghi thao tác Admin | Bảng `audit_events` thống nhất: tiền, đơn, đấu giá, xác thực |
| Mã lỗi | Nhiều lỗi dùng chung `FORBIDDEN` | Có `AUCTION_BANNED`, `NOT_REGISTERED`, `DEBT_OPEN` |

## 3. Ngoại lệ đã thử trực tiếp trên nhánh (cổng 8082)

| Nhóm | Tình huống | Kết quả |
|---|---|---|
| Tài khoản | Sai mật khẩu | 401 "Email hoặc mật khẩu không đúng" |
| | Sai liên tiếp 11 lần | 429 "Sai mật khẩu quá nhiều lần, vui lòng thử lại sau 15 phút" |
| | Đăng ký trùng email | 409 "Email đã được đăng ký" |
| | Mật khẩu quá ngắn | 400 "Dữ liệu không hợp lệ" |
| Đặt hàng | Thanh toán khi giỏ trống | 400 "Giỏ hàng trống" |
| | Thêm vượt tồn kho (99 cuốn) | 409 "Chỉ còn 5 cuốn" |
| | Shop tự mua sách của mình | 400 "Không thể mua sách của chính shop mình" |
| | Thêm sách không tồn tại | 404 "Không tìm thấy tin đăng" |
| | Trả bằng ví nhưng ví không đủ | 400 "Số dư ví không đủ, vui lòng nạp thêm" |
| | Tài khoản mới chưa xác thực email đặt hàng | 403 "Cần xác thực email trước khi đặt hàng" |
| | COD 250.000đ, tài khoản mới | 201 (dưới hạn mức 500.000đ) |
| | COD 500.000đ hàng + phí ship, tài khoản mới | 409 "Đơn COD tối đa 500000đ, vui lòng thanh toán bằng ví hoặc ZaloPay" |
| | Bấm đặt hàng 2 lần cùng lúc | Một lần 201, lần kia 400 "Giỏ hàng trống" |
| Vòng đời đơn | Người mua nhận hàng khi shop chưa giao | 409 "Không thể chuyển trạng thái từ PENDING_CONFIRM sang COMPLETED" |
| | Shop giao vận chuyển khi chưa xác nhận đơn | 409 "… từ PENDING_CONFIRM sang SHIPPING" |
| | Shop khác xác nhận đơn không phải của mình | 404 "Không tìm thấy đơn hàng" |
| | Người khác xem đơn của buyer2 | 404 "Không tìm thấy đơn hàng" |
| | Người mua huỷ khi hàng đã giao vận chuyển | 409 "Đơn đã giao cho vận chuyển, không thể huỷ" |
| Trả hàng | Yêu cầu trả không kèm ảnh | 400 "Dữ liệu không hợp lệ" |
| | Yêu cầu trả sau khi đã bấm "đã nhận hàng" | 409 "Chỉ yêu cầu trả hàng trong thời hạn khiếu nại sau khi giao" |
| | Shop đồng ý, ví người mua | Chưa hoàn tiền (4.360.000 → 4.360.000) |
| | Shop xác nhận nhận sách khi người mua chưa gửi | 409 "Người mua chưa gửi hàng trả" |
| | Người mua gửi trả kèm mã, shop xác nhận | 200, hoàn đúng 70.000đ |
| Ví | Rút 10.000đ | 400 "Dữ liệu không hợp lệ" |
| | Rút nhiều hơn số dư | 400 "Số dư ví không đủ, vui lòng nạp thêm" |
| | Số tài khoản có chữ | 400 "Dữ liệu không hợp lệ" |
| | Nạp 1.000.000đ rồi rút ngay 500.000đ | 409 "Hiện rút được tối đa 0đ. Tiền mới nạp được rút sau …" |
| Đấu giá | Chưa xác thực số điện thoại | 403 "Cần xác thực số điện thoại trước khi tham gia đấu giá" |
| | Không đồng ý quy chế | 400 "Cần đồng ý quy chế phiên đấu giá" |
| | Đăng ký lần hai | 409 "Bạn đã đăng ký phiên này (số bài #003)" |
| | Huỷ đăng ký trước hạn | 200, ví từ khoá 500.000đ về 0, khả dụng 2.500.000 → 3.000.000 |
| | Trả giá khi phiên chưa mở | 409 "Phiên chưa diễn ra hoặc đã kết thúc" |
| | Staff đăng ký đấu giá | 400 nhưng lý do hiện là "Số dư ví không đủ" (xem mục 6) |

## 4. Chỉ chứng minh được bằng test (cần chờ giờ nên không demo trực tiếp)

- Người thắng bỏ thanh toán (hạn 48 giờ): mất cọc, bị cấm, mời người trả giá thứ hai.
- Shop ngâm đơn quá 3 ngày: tự huỷ và hoàn tiền; người mua im lặng quá hạn trả hàng; người mua không gửi hàng trả quá 7 ngày.
- Trả giá đồng thời trong phiên trực tiếp, trả giá sau giờ chốt, tự mở lại khi tạm dừng (`MultiBidderTest`, `AuctionMoneyTest`).
- Bảo toàn tiền cả vòng đời: `FullJourneyTest` (16 câu chuyện), `JourneyEdgeCasesTest` (15 ca).

## 5. Chưa xử lý (đã biết, lấy từ hai file audit)

- Mất mạng khi đang đấu giá: nối lại sau 3 giây, chưa báo "mất kết nối", nút trả giá vẫn bấm được (FE-04).
- Rớt mạng đúng lúc làm mới đăng nhập thì bị đăng xuất oan (FE-02).
- Giá đổi giữa lúc xem và lúc đặt không được báo trước (BE-12).
- Thanh toán trên hai thiết bị cùng lúc không có khoá chống trùng `Idempotency-Key` (BE-13).
- Phân xử trả hàng chưa có hoàn một phần (BE-11); người mua "bom" hàng ngoài COD, đánh giá giả (BE-10, BE-16).
- Cổng thanh toán thật: callback trùng, timeout, đóng trang giữa chừng. Chưa test với ZaloPay thật, chỉ có test dùng cổng giả.
- Backend mặc định profile `dev` và còn log mã OTP (BE-32).

## 6. Rủi ro khi merge và khi demo

1. **Xung đột migration:** nhánh có `V9__money_rules.sql`; bản sửa tìm kiếm không dấu của tôi (chưa push, commit `bd9b768`) cũng là `V9__unaccent_search.sql`. Flyway không chạy nếu trùng số; một bên phải đổi số.
2. **Frontend chưa đổi gì:** đơn COD kẹt vì chưa có màn Staff đối chiếu (nhánh ghi rõ là bắt buộc); màn trả hàng chưa có bước gửi lại; nút "Đã giao" của shop sẽ bị 403 ở bản production; người mua chưa có nút "Đã nhận hàng" khi đơn đang giao.
3. **Luật trái hướng đã chọn trước đó:** hôm 05/11 bạn đã cho rollback các luật nghiệp vụ thêm (COD, trả hàng có bước, …); nhánh này đưa lại đúng những thứ đó.
4. **Đổi hành vi khi demo:** tiền nạp bị khoá 24 giờ, kịch bản "nạp rồi rút ngay" sẽ bị chặn (đặt cấu hình `wallet.topup_hold_hours` = 0 để tắt).
5. **Quá nhiều luật so với SRS:** khoảng 7.000 dòng thêm; thầy hỏi "tại sao" mà nhóm không giải thích được thì mất điểm.
6. **Lỗi nhỏ thầy dễ để ý:** Staff đăng ký đấu giá bị chặn vì "Số dư ví không đủ" thay vì "người vận hành không đấu giá"; nhiều lỗi dữ liệu cùng ra thông báo chung "Dữ liệu không hợp lệ", chi tiết nằm ở trường lỗi.
7. **Bản web tự deploy dùng `env/prod.json`** với API giữ chỗ `https://api.example.com/api`. Chưa kiểm workflow có chạy không. Không demo trên bản web đã deploy; chạy app với backend local.

## 7. Đề xuất (chưa làm)

**Nên lấy từ nhánh** (dễ giải thích, ít đụng giao diện): khoá tiền nạp, hạn mức rút, hoàn tiền trả hàng chỉ sau khi sách về, chụp phí sàn lúc đặt, chặn đặt hàng song song, nhật ký sự kiện.

**Nên bỏ khỏi bản demo** (khó giải thích, cần thêm màn hình): COD đối soát hãng vận chuyển, công nợ phí kho, uy tín shop tự gỡ.

**Việc nhỏ có lợi cho điểm:**
1. Bảng "luật nghiệp vụ": luật, lý do, SRS nói gì, chặn ở đâu, test nào chứng minh.
2. Kiểm xem các mốc thời gian (3 ngày, 48 giờ, 7 ngày) đã đọc từ cấu hình chưa; nếu rồi thì chỉnh còn vài phút ngay trên Admin để demo.
3. Báo khi giá đổi lúc đặt hàng (BE-12); khoá chống trùng thanh toán và rút tiền (BE-13).
4. Báo "mất kết nối" và khoá nút trả giá khi nối lại (FE-04); sửa đăng xuất oan (FE-02).
5. Gỡ log OTP và đặt profile mặc định an toàn (BE-32).
6. Sửa hai lỗi nhỏ ở mục 6.6.

Không đề xuất thêm luật mới (KYC, phân xử hoàn một phần, chống đẩy giá bằng IP): vượt mức môn học.

## 8. Chuẩn bị demo

- Chạy app với backend local, reset database trước, dùng tài khoản mẫu (mật khẩu `Rebook@123`).
- Chọn khoảng 8 tình huống từ bảng mục 3: đặt hàng 2 lần cùng lúc, nhảy sai trạng thái đơn, huỷ khi đã giao vận chuyển, rút ngay sau khi nạp, trả hàng chưa gửi sách thì chưa hoàn tiền, huỷ đăng ký hoàn cọc, sai mật khẩu nhiều lần, vượt tồn kho.
- Câu "tại sao" cần thuộc: khoá tiền nạp 24 giờ để chặn rửa tiền; hoàn tiền sau khi nhận sách để người mua không giữ cả sách lẫn tiền; chụp phí lúc đặt để Admin đổi phí không ảnh hưởng đơn cũ.
- Mục chưa làm (mục 5) nên nói thẳng với thầy là "đã nhận diện, để sau", kèm `AUDIT_BACKEND.md` làm bằng chứng.
- Bằng chứng quy trình: `TEST_GUIDE.md`, `apps/frontend/docs/QA_FINDINGS_2026-11-05.md` (20 lỗi đã sửa), `docs/FIXES_2026-11-05.md`, số lượng test.

## 9. So với bản demo cũ (`2c3eb5b`, 24/10/2026)

- 122 commit, 472 file đổi, frontend thêm khoảng 19.000 dòng.
- Backend lúc đó có 128 file Java và 0 test; nay `main` có 14 lớp test, nhánh nghiệp vụ thêm nhiều lớp nữa.
- Đã thêm ZaloPay sandbox, tải ảnh thật, yêu thích, theo dõi phiên, sổ tài khoản ngân hàng, địa chỉ có ghim; đợt test 05/11 sửa 3 lỗi chặn luồng, 7 lỗi nặng và nhiều lỗi nhỏ.
- Tôi không biết thầy đã nhận xét cụ thể những gì lần trước, nên không thể đảm bảo kết quả. Nhận xét nguyên văn của thầy là thông tin cần có nhất để đối chiếu việc còn thiếu.
