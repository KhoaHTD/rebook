# ReBook: đánh giá hệ thống và việc cần sửa

Gộp ngày 2026-11-06 từ các file cũ. Mỗi phần giữ nguyên nội dung và mã mục (BE-xx, FE-xx). Chú thích trong code có thể còn ghi tên file cũ; bảng dưới cho biết tên cũ nằm ở phần nào.

| Phần | Nội dung | Tên file cũ |
|---|---|---|
| A | Đánh giá BA / tester toàn hệ thống (xếp P0 → P3) | `DANH_GIA_BA_TESTER_2026-11-06.md` |
| B | Audit backend (BE-xx) và các đợt sửa | `AUDIT_BACKEND.md` |
| C | Audit frontend (FE-xx) | `AUDIT_FRONTEND.md` |
| D | Việc để sau | `BACKLOG_LATER.md` |

---

# Phần A. Đánh giá BA / tester toàn hệ thống (xếp P0 → P3)

*(Trước là `DANH_GIA_BA_TESTER_2026-11-06.md`.)*

Phạm vi: luật nghiệp vụ và code backend trên nhánh `improve_bussinessrule`, gồm tài khoản, tiền và ví, mua bán giá cố định, ký gửi, kho, đấu giá, Admin. Không đánh giá giao diện.

Cách làm: đọc code `apps/backend/src/main/java/com/rebook/**`, đối chiếu với [THAY_DOI_SO_VOI_CODE_CU.md phần C](THAY_DOI_SO_VOI_CODE_CU.md), [THAY_DOI_SO_VOI_CODE_CU.md phần B](THAY_DOI_SO_VOI_CODE_CU.md), [DANH_GIA_BA_TESTER.md phần B](DANH_GIA_BA_TESTER.md).

- Mục có nhãn **Mới** là lỗ hổng mình tìm ra khi đọc code, chưa có trong các tài liệu trên.
- Mục có nhãn **Đã biết** lấy từ tài liệu, mình chỉ kiểm lại những mục có ghi "đã kiểm code".
- **Chưa chạy test** cho đợt sửa ngày 2026-11-06 vì máy không có PostgreSQL.

### 1. Kết luận nhanh

| Mảng | Mức sẵn sàng | Nhận xét |
|---|---|---|
| Sổ cái ví | Tốt | Mọi thay đổi tiền đi qua một hàm, khoá dòng ví, không cho âm, ghi sổ cái và nhật ký, có đối soát hằng đêm |
| Mua bán giá cố định | Trung bình | Đủ trạng thái và hạn xử lý. Yếu nhất là giao hàng không kiểm chứng được, và chưa có luật phí ship khi trả hàng |
| Ký gửi và kho | Trung bình | Luồng chính đủ. Thiếu hạn ở hai chỗ treo (chờ người bán quyết, chờ người bán nhận lại sách) và chưa tách vai trò định giá |
| Đấu giá | Khá | Trả giá đồng thời, soft close, phạt, nợ, giá mời lần hai công bằng đều đúng. Thiếu cọc lô cao giá, bán sau phiên và chống đẩy giá |
| Định danh và chống gian lận | Yếu | Chưa có OTP gửi thật, CCCD, IP / thiết bị. Mọi lệnh cấm và nợ đều lách được bằng tài khoản mới |
| Vận hành chạy thật | Chưa sẵn sàng | Profile mặc định là `dev`, chưa có thông báo ngoài app, chỉ chạy được một instance |

Hệ thống **đủ để demo đồ án**. **Chưa đủ để nhận tiền thật** khi chưa xong nhóm P0 dưới đây.

### 2. Đã sửa trong ngày 2026-11-06 (chưa chạy test)

| ID | Nội dung |
|---|---|
| BE-43 | Giá tối đa ≥ giá sàn thì được trả hộ lên giá sàn; trước đây lô bị chốt "Không đạt giá" dù có người sẵn sàng mua |
| BE-44 | Lý do trả hàng `NOT_RECEIVED`: đơn trả trước bị tự coi là đã giao mà người mua không nhận được thì được hoàn tiền, không bắt gửi trả |
| BE-45 | Thắng đấu giá, trả tiền rồi từ chối nhận: phạt như bỏ thanh toán và thu phí giao chiều đi |
| BE-46 | ZaloPay báo về chậm: hỏi lại ZaloPay và ân hạn 15 phút trước khi phạt |
| BE-47 | Thu nợ song song không còn trừ ví hai lần |

**Cập nhật cuối ngày 2026-11-06 (`./mvnw test` 199/200, trừ `SeedDataTest`):** P0 mục 2, 3, 4 làm một phần theo [THIET_KE_GUI_MAIL.md](THIET_KE_GUI_MAIL.md). Mục 2: mail cho các mốc có hạn, không phạt khi mail chưa tới và thông báo chưa đọc. Mục 3: OTP gửi qua email, giới hạn xin OTP (phần còn lại của BE-26), chặn biến thể email; chưa có SMS, CCCD. Mục 4: giữ tiền bán của shop mới 7 ngày, Admin ghi nợ chargeback.

### 3. Danh sách cần cải thiện, từ nặng đến nhẹ

Thang mức:
- **P0**: chặn chạy thật (mất tiền, lộ dữ liệu, hoặc gian lận không ngăn được).
- **P1**: mất tiền hoặc tranh chấp thường gặp.
- **P2**: tình huống ít gặp hơn, hoặc ảnh hưởng chất lượng vận hành.
- **P3**: hoàn thiện, pháp lý, quy mô.

#### P0: chặn chạy thật

| # | Vấn đề | Kịch bản lỗi (test case) | Đề xuất | Nguồn |
|---|---|---|---|---|
| 1 | Profile mặc định là `dev` | Deploy quên đặt `SPRING_PROFILES_ACTIVE`: OTP trả trong response, `POST /payments/{code}/simulate` bật. Ai cũng nạp ví miễn phí rồi mua hoặc rút | Mặc định `prod`. Thiếu `JWT_SECRET` thì không khởi động. Giả lập chỉ bật bằng biến môi trường tường minh | Đã biết BE-32 |
| 2 | Không có thông báo ngoài app nhưng vẫn phạt theo hạn | Người thắng tắt app, không biết đã thắng. Sau 48 giờ bị mất cọc, phạt 10%, cấm 90 ngày. Khiếu nại có lý | Push / email cho các mốc có hạn. Chưa gửi được ngoài app thì không phạt | Đã biết BE-36, BR-8.1, BR-8.2. **Đã làm phần email 2026-11-06** ([THIET_KE_GUI_MAIL.md](THIET_KE_GUI_MAIL.md)); còn push |
| 3 | Không định danh người: OTP chỉ ghi log, không có CCCD | Bị cấm hoặc còn nợ thì tạo tài khoản mới là xong. "Đã xác thực SĐT" để đấu giá không có giá trị | OTP SMS thật. CCCD trước khi ký gửi, rút tiền lần đầu, đấu giá lô ≥ 5 triệu. Cấm và nợ áp theo CCCD / SĐT | Đã biết BR-1.1 đến BR-1.3. **Đã làm một phần 2026-11-06:** OTP qua email, giới hạn xin OTP, chặn biến thể email; còn SMS, CCCD |
| 4 | **Rút tiền thẻ trộm / rửa tiền qua shop phụ** (Mới, đã kiểm code) | Khoá 24 giờ chỉ áp cho lệnh rút trực tiếp tiền vừa nạp. Kẻ gian nạp ZaloPay bằng thẻ trộm, mua sách của shop phụ, shop bấm "đã giao", người mua bấm "đã nhận" ngay. Tiền bán vào ví shop và rút được trong vài phút. Không có xử lý hoàn tiền bị đòi lại từ ngân hàng (chargeback) | Tiền bán của shop mới (ví dụ dưới 10 đơn hoàn tất hoặc tạo dưới 30 ngày) giữ thêm N ngày sau hoàn tất. Chặn mua bán giữa hai tài khoản chung thiết bị / IP / tài khoản ngân hàng. Có trạng thái và luồng ghi nợ khi bị chargeback | Mới. **Đã làm một phần 2026-11-06:** giữ tiền bán shop mới 7 ngày (`SALE_HELD`), Admin ghi nợ `CHARGEBACK`; chưa có IP / thiết bị, chưa nhận chargeback tự động |
| 5 | Giao hàng và trả hàng không kiểm chứng được | Shop để trống mã vận đơn thì hệ thống tự sinh mã. Người mua cũng nhập mã gửi trả tự do, nên nhập mã bịa là shop phải tự chứng minh. Admin phân xử không có dữ liệu thật nào. BE-44 mới giảm rủi ro phía người mua | Bắt buộc mã vận đơn của hãng có trong danh sách, kèm ảnh biên nhận bưu cục khi gửi trả. Lâu dài thì dùng webhook GHN / GHTK | Đã biết BE-04 (phần còn lại) + Mới |
| 6 | Ảnh biên lai chuyển khoản (có số tài khoản) để công khai | `GET /files/*` công khai, cache 7 ngày, chung thư mục với ảnh sách | Tách thư mục, file biên lai cần quyền xem | Đã biết BE-34 |

#### P1: mất tiền hoặc tranh chấp thường gặp

| # | Vấn đề | Kịch bản lỗi | Đề xuất | Nguồn |
|---|---|---|---|---|
| 7 | Giá đổi lúc người mua bấm đặt | Shop sửa giá từ 50.000 lên 500.000 (sửa giá không phải duyệt lại) đúng lúc người mua bấm đặt; người mua trả giá mới | Request đặt hàng gửi kèm giá đã thấy, lệch thì trả `PRICE_CHANGED`. Giá tăng quá X% thì tin phải duyệt lại | Đã biết BE-12, BR-2.13 |
| 8 | Phí ship khi trả hàng / giao thất bại chưa có luật trong code | Sách sai mô tả: người mua tự trả ship gửi về, không được hoàn. Người mua bom đơn trả trước: shop mất ship hai chiều, người mua được hoàn đủ | Làm BR-3.4 đến BR-3.7: lỗi shop thì shop chịu ship hai chiều; lỗi người mua thì trừ ship chiều đi; Staff ghi ai gây lỗi | Đã biết |
| 9 | Phân xử khiếu nại chỉ có hai lựa chọn, không có bằng chứng, không có hạn | Sách rách nhẹ: chỉ có hoàn toàn bộ (kèm trả hàng) hoặc từ chối. Shop không nộp ảnh phản biện được. Khiếu nại nằm chờ Admin mãi | Hoàn một phần 10–50%, ảnh phản biện, hạn Admin 3 ngày có nhắc | Đã biết BR-3.8 đến BR-3.11 |
| 10 | **Khoá tài khoản khi người đó đang có việc đấu giá dở** (Mới, đã kiểm code) | `AccountLockService.cleanUp` chỉ huỷ đơn **thường** chưa trả và hoàn cọc phiên **chưa diễn ra**. Người bị khoá đang dẫn giá ở lô đang mở vẫn thắng. Hoá đơn đấu giá chưa trả vẫn chạy 48 giờ, rồi người đó bị phạt dù không đăng nhập được để trả. Người bán bị khoá vẫn có lô lên phiên | Khi khoá: huỷ hoá đơn đấu giá chưa trả, không phạt, mời người kế tiếp; huỷ lượt dẫn ở lô đang mở (hoặc chặn khoá khi phiên đang chạy, chờ hết lô); rút lô của người bán bị khoá khỏi phiên chưa chạy | Mới |
| 11 | **Ký gửi treo ở bước chờ người bán quyết** (Mới, đã kiểm code) | Kiểm định đạt, chuyển `AWAITING_SELLER`. Người bán không chấp nhận cũng không rút: không có job nào, sách nằm kho mãi, không tính phí | Hạn quyết định (ví dụ 7 ngày, có nhắc). Quá hạn thì coi như rút và bắt đầu tính hạn lưu kho | Mới |
| 12 | **Sách vô chủ** (Mới, đã kiểm code) | Sách chờ người bán nhận lại: phí kho chỉ ghi nợ lúc Staff xuất kho. Người bán không bao giờ đến thì không phát sinh nợ, kho đầy mãi, không có quyền xử lý sách | Ghi nợ phí kho định kỳ (ví dụ mỗi tuần). Sau X ngày (ví dụ 60), có thông báo trước, sàn được thanh lý / quyên góp. Điều này phải ghi trong hợp đồng ký gửi điện tử | Mới (BE-19 có nhắc "sách vô chủ") |
| 13 | **Hoá đơn đấu giá không có hạn xử lý của kho** (Mới, đã kiểm code) | Hạn xác nhận và hạn giao chỉ đặt cho đơn thường. Người thắng đã trả mà Staff quên xác nhận / giao thì tiền kẹt, không nhắc ai | SLA cho kho (ví dụ xác nhận 24 giờ, giao 3 ngày), nhắc Staff, quá hạn thì báo Admin | Mới |
| 14 | Đẩy giá bằng tài khoản phụ không bị phát hiện | Người bán dùng tài khoản phụ đẩy giá rồi dừng đúng lúc (không thắng): người mua thật trả cao hơn. Luật "phạt về sàn 100%" chỉ chặn trường hợp phụ thắng rồi bỏ | Ghi IP / thiết bị cho đăng ký và lượt trả giá, cảnh báo cặp tài khoản liên quan. Khoá cả hai nếu người bỏ thanh toán liên quan tới người ký gửi | Đã biết BE-25, BR-5.13, BR-6.3 |
| 15 | Cọc cố định cho cả phiên, kể cả lô giá trị lớn | Cọc 500.000 với hệ số 10 cho trả giá tới 5 triệu: bỏ một lô 5 triệu chỉ mất 500.000 | Cọc riêng cho lô cao giá (≥ 10 triệu: cọc thêm 10% mức thấp ước tính) | Đã biết BR-5.6, BR-5.7 |
| 16 | Một Admin tự duyệt mọi thứ | Một Admin tự duyệt rút tiền lớn, tự đổi phí, tự đổi vai trò | Hai người xác nhận cho khoản rút ≥ 50 triệu và đổi vai trò | Đã biết BE-28, BR-7.4 |
| 17 | Khoá đăng nhập bị lợi dụng | 10 lần đăng nhập sai theo email là khoá tài khoản người khác 15 phút, kể cả lúc người đó đang đấu giá | Khoá theo IP kèm email; không khoá chủ tài khoản đang đăng nhập hợp lệ | Đã biết BE-42 |
| 18 | Thêm tài khoản ngân hàng mới để rút không cần xác thực | Ai chiếm được phiên đăng nhập là rút về tài khoản của mình ngay | OTP khi thêm tài khoản ngân hàng, chờ 24 giờ mới dùng | Đã biết BR-7.2 |

#### P2: ít gặp hơn hoặc ảnh hưởng chất lượng vận hành

| # | Vấn đề | Kịch bản lỗi | Đề xuất | Nguồn |
|---|---|---|---|---|
| 19 | **Một Staff vừa nhận sách, vừa kiểm định, vừa định giá** (Mới) | Staff thông đồng với người bán, hoặc đặt giá sàn thấp cho người quen mua. Staff không được đấu giá, nhưng tài khoản người thân thì được | Tách người nhận sách và người kiểm định; lô ước tính ≥ N triệu cần người thứ hai duyệt giá | Mới |
| 20 | Phiếu kiểm định là JSON tự do, không bắt buộc ảnh | Tranh chấp sau bán không có căn cứ: không biết lúc nhận sách đã có vết rách chưa | Checklist cố định, bộ ảnh chuẩn, trường chữ ký / bút tích | Đã biết BR-4.1 đến BR-4.5 |
| 21 | Sách lậu, sách cấm, báo cáo tin | Không có nút báo cáo tin, không có lý do trả hàng "sách lậu", không có ngưỡng khoá shop vi phạm | BR-2.8 đến BR-2.11 | Đã biết |
| 22 | Lô không đạt giá sàn thì không bán sau phiên | Người trả cao nhất chỉ thiếu ít so với giá sàn, nhưng người bán không có cách đồng ý bán | Bán sau phiên: người bán có 24 giờ để đồng ý, người mua có 24 giờ để nhận | Đã biết BR-6.8 đến BR-6.11 |
| 23 | Cấm đấu giá luôn 90 ngày | Người bỏ thanh toán lần thứ 3 vẫn chỉ bị cấm 90 ngày | Cấm luỹ tiến: 90 ngày, rồi 365 ngày, rồi vĩnh viễn | Đã biết BR-6.4 |
| 24 | **Tin bán sách cũ có tồn kho > 1 với một bộ ảnh** (Mới) | Shop đăng 5 cuốn "cũ 80%" chung một ảnh. Người mua nhận cuốn khác ảnh thì tranh chấp, mà cả hai đều có lý | Sách tình trạng cũ thì tồn kho = 1, hoặc bắt ghi "ảnh minh hoạ" và có lý do trả hàng tương ứng | Mới |
| 25 | **Lịch hẹn ký gửi nhận giờ trong quá khứ** (Mới, đã kiểm code) | `bookAppointment` chỉ kiểm trước hạn và trong giờ mở cửa, không kiểm là ở tương lai, ngày nghỉ hay công suất kho | Kiểm `appointmentAt > now`, chặn ngày nghỉ, giới hạn số lịch mỗi khung giờ | Mới |
| 26 | Sơ duyệt ký gửi 48 giờ không có nhắc / leo thang | Yêu cầu nằm chờ Staff mãi | Job nhắc Staff và báo Admin khi quá 48 giờ | Đã biết BE-24 |
| 27 | Cấu hình chấp nhận giá trị phá luật | Admin đặt `order.payment_timeout_minutes = 0` thì mọi đơn bị huỷ ngay; `order.auto_complete_days = 0` thì mất hạn khiếu nại | Khoảng min / max cho từng khoá cấu hình | Đã biết BE-33 |
| 28 | Phí ship so khớp tỉnh bằng chuỗi tên | Địa giới đã đổi từ 2025 nên dữ liệu 63 tỉnh lệch, tính sai cùng / khác tỉnh | Danh mục địa giới có mã | Đã biết BE-37 |
| 29 | Đánh giá không có kiểm duyệt | Tự mua của shop mình để tăng sao; không có báo cáo đánh giá hay phản hồi của shop | BR-3.12, BR-3.13 | Đã biết BE-16 |
| 30 | Trả giá lớn không hỏi lại | Gõ nhầm thêm một số 0 là thành lượt trả giá ràng buộc | Vượt 10 bước giá thì bắt xác nhận | Đã biết BR-5.10 |
| 31 | Phiên tạm dừng không có giới hạn | Sự cố kéo dài, phiên treo mãi, cọc kẹt | Quá 60 phút thì Admin phải chọn tiếp tục hoặc kết thúc | Đã biết BR-5.12 |
| 31b | **Backend tắt lâu hơn thời gian còn lại của lô** (Mới, đọc code) | Bật lại thì lô chốt ngay theo giờ cũ, không ai kịp trả giá trong lúc tắt | **Đã sửa 2026-11-06:** nhịp đầu tiên sau khi khởi động kéo dài lô đang mở cho còn ít nhất thời gian soft close | Mới, đã sửa (`TEST_PLAN_TOAN_DIEN.md phần A` T-AUC-19) |

#### P3: hoàn thiện, pháp lý, quy mô

| # | Vấn đề | Đề xuất | Nguồn |
|---|---|---|---|
| 32 | Dashboard "doanh thu" là tổng giá trị đơn, không phải phí sàn thực thu | Tách tổng giá trị đơn với phí thực thu từ ví sàn | BE-29 |
| 33 | Không có xoá / ẩn danh tài khoản; dữ liệu CCCD, IP sắp thu cần đối chiếu Nghị định 13/2023 | Luồng xoá tài khoản giữ sổ cái ẩn danh | BE-30, BR-1.6 |
| 34 | Chỉ chạy được một instance (WebSocket và nhịp đấu giá trong RAM) | Redis pub/sub, ShedLock | BE-39 |
| 35 | Không có CI backend, không có cảnh báo khi job lỗi hay nhịp đấu giá chậm | `backend-ci.yml` chạy `./mvnw test`; metrics và cảnh báo | BE-40 |
| 36 | Pháp lý: Luật Đấu giá tài sản, giữ tiền hộ, thuế người bán cá nhân, hoá đơn điện tử | Tham vấn trước khi chạy thật; ghi vào phần rủi ro của báo cáo | BE-31 |
| 37 | Ân hạn ZaloPay 15 phút là hằng số trong code | Đưa vào `system_configs` nếu cần chỉnh | BE-46 |

### 4. Bộ kịch bản kiểm thử nên có (để bao đủ trường hợp)

Mỗi dòng là một nhóm test. ✅ là đã có test trong `src/test`, ⏳ là chưa có.

**Tiền và ví**
- ✅ Nạp rồi rút ngay bị khoá 24 giờ; rút vượt hạn mức ngày; rút khi còn nợ.
- ✅ Hai lệnh rút song song; thu nợ song song (BE-47).
- ✅ ZaloPay báo hai lần chỉ cộng một lần; báo sai số tiền thì không cộng; sai chữ ký bị từ chối.
- ⏳ ZaloPay báo thành công sau khi hoá đơn đấu giá đã bị huỷ vì quá ân hạn (tiền hoàn vào ví, phạt vẫn giữ).
- ✅ Job đối soát ví với sổ cái (`MoneyRulesTest`). ⏳ Đối soát sau một chuỗi mua, hoàn, phạt, bù chênh liên tiếp.
- ⏳ Ví sàn không đủ tiền khi phải hoàn phí hoặc bồi thường.
- ✅ Shop mới không rút được tiền vừa bán, shop uy tín thì được; chargeback thu phần ví đang có và chặn rút phần còn lại (`SellerHoldAndChargebackTest`).

**Mail và OTP**
- ✅ Thư quan trọng vào hàng đợi, gửi đúng một lần; thông báo thường và email chưa xác thực không có thư; giao dịch huỷ thì không có thư; SMTP lỗi thử lại rồi `FAILED` (`MailOutboxTest`).
- ✅ OTP tới hộp thư, tiêu đề không chứa mã; SMTP lỗi thì `EMAIL_SEND_FAILED` và không giữ mã; xin lại trong 60 giây bị chặn; quên mật khẩu bị giới hạn kể cả email không tồn tại; biến thể Gmail không đăng ký được (`MailOutboxTest`, `OtpAndEmailRulesTest`).
- ✅ Người thắng chưa nhận được thư và chưa đọc thông báo: gia hạn một lần, lần sau mới phạt; đã nhận thư hoặc đã đọc: phạt đúng hạn (`MailOutboxTest`).
- ⏳ Gửi qua một SMTP thật (Gmail / Brevo) và kiểm thư vào hộp thư đến, không vào thư rác.

**Mua bán**
- ✅ Hai người cùng mua cuốn cuối; bấm đặt hai lần; COD vượt hạn mức; người bom COD bị chặn.
- ✅ Shop không xác nhận / không giao đúng hạn; yêu cầu huỷ không được trả lời; trả hàng theo từng bước.
- ✅ Không nhận được hàng (BE-44).
- ⏳ Giá đổi giữa lúc xem trước và lúc đặt (sau khi làm BE-12).
- ⏳ Người mua bấm "đã nhận" rồi mới phát hiện sách lỗi (hiện không còn đường khiếu nại; cần quyết định có cho không).
- ⏳ Shop bị khoá khi đơn đang giao hoặc đang trả hàng.

**Đấu giá**
- ✅ Nhiều người trả giá song song; proxy đấu proxy; soft close; tạm dừng rồi tiếp tục.
- ✅ Bỏ thanh toán (cọc lớn hơn / nhỏ hơn phạt, ví thiếu thì ghi nợ); mời mua lần hai ở giá công bằng; bù chênh cho người bán.
- ✅ Giá tối đa trên / dưới giá sàn (BE-43); từ chối nhận hàng (BE-45); ZaloPay báo chậm (BE-46).
- ⏳ Người dẫn giá bị khoá giữa lô (mục 10).
- ⏳ Thắng nhiều lô, trả một phần, đổi địa chỉ ở một hoá đơn (phí ship gộp phải tính lại).
- ⏳ Huỷ lô đang mở khi phiên đang tạm dừng.
- ⏳ Người về nhì vừa bị cấm sau khi phiên đóng nhưng trước lúc mời mua lần hai.

**Ký gửi và kho**
- ✅ Không mang sách tới thì hết hạn; lô không bán thì tự trả sách sau 7 ngày; phí kho thành nợ; sự cố kho được bồi thường theo giai đoạn.
- ⏳ Người bán không quyết sau khi kiểm định đạt (mục 11); sách vô chủ (mục 12).
- ⏳ Lịch hẹn trong quá khứ (mục 25).

### 5. Thứ tự làm đề xuất

1. **Trước khi nhận tiền thật:** mục 1, 2, 3, 4, 5, 6. Phần lớn cần dịch vụ ngoài (SMS, push / email, eKYC, hãng vận chuyển), nên cần lên lịch sớm.
2. **Thuần backend:** mục 10, 11, 12, 13, 25, 27 **đã làm** (cập nhật 11 trong `DANH_GIA_BA_TESTER.md phần B`, chưa chạy test). Phần còn lại: nhắc trước hạn ở mục 11; ngày nghỉ / công suất kho ở mục 25.
3. **Đợt 2 thuần backend đã làm** (cập nhật 12): mục 7, 8 (trừ ship chiều về khi sai mô tả), 15, 17, 23. Frontend cần gửi `expectedTotal`, ô "ai gây lỗi" khi báo giao thất bại, và hiện lỗi `LOT_DEPOSIT_REQUIRED`.
4. **Cần frontend đổi theo:** mục 9, 22, 30 và hai thay đổi của ngày 2026-11-06 (lý do "Không nhận được hàng", ô "Lỗi do người mua").
5. **Sau cùng:** P3.

---

# Phần B. Audit backend (BE-xx) và các đợt sửa

*(Trước là `AUDIT_BACKEND.md`.)*

Ngày 2026-11-05. Đọc `apps/backend` đối chiếu SRS, mỗi mục đã được kiểm lại với code (có `file:dòng`). Chưa chạy test, chưa kiểm phân quyền từng controller.
Mức: **P0** mất tiền / sai tiền thật, hoặc hỏng cả hệ thống khi deploy · **P1** kẹt tiền, kẹt đơn, gian lận · **P2** thiếu cho vận hành thật.
Việc frontend đi kèm nằm ở [DANH_GIA_BA_TESTER.md phần C](DANH_GIA_BA_TESTER.md) (mục "Việc đi kèm khi backend sửa").
Cột "Người nhận" và "Trạng thái" để nhóm tự điền; trạng thái trống = chưa sửa. Đường dẫn tính từ `apps/backend/src/main/java/com/rebook/`.

### Cập nhật sau khi pull (đến commit `6af440c`, 2026-11-05)

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

### Cập nhật 2: luồng tiền (2026-11-05, buổi tối)

Đã sửa BE-01 … BE-06 và BE-13 theo quyết định của chủ repo (xem `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần E` mục B). **Đã chạy test: 64/64 đạt** (trừ `SeedDataTest` vì gắn cứng cổng 5432; thay bằng khởi động thử backend với dữ liệu mẫu, migration `V9` thành công). `apps/backend/openapi.yaml` đã xuất lại.
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
| Ghi log | Bảng `audit_events` + `AuditLog` + `RequestIdFilter` (xem `THAY_DOI_SO_VOI_CODE_CU.md phần D`); mọi dòng sổ cái ví, mọi lần đổi trạng thái đơn, COD, rút tiền, trả hàng, giao hàng đều có sự kiện |

Còn lại của nhóm tiền: BE-17 (cọc đấu giá), BE-22 (phí lưu kho trừ ví), đối soát tổng với ZaloPay, KYC khi rút tiền.

### Cập nhật 3: luồng tiền đấu giá (2026-11-05, đêm)

Phân tích và quy tắc đầy đủ ở [THAY_DOI_SO_VOI_CODE_CU.md phần B](THAY_DOI_SO_VOI_CODE_CU.md). Đã sửa BE-15, BE-17, BE-18, BE-19, BE-20, BE-22 và chọn người về nhì hợp lệ. **Đã chạy test: 75/75 đạt** (trừ `SeedDataTest`); migration `V10` chạy tốt trên dữ liệu mẫu; `apps/backend/openapi.yaml` đã xuất lại.
Còn lại của đấu giá: BE-21 (chuyển bán thường do sàn giao hộ), BE-25 (thông đồng đẩy giá), người bị cấm vẫn giữ cọc ở phiên khác, sàn huỷ hoá đơn vì lỗi của sàn.

### Cập nhật 4: đợt thuần backend (2026-11-06)

Đã sửa BE-07, BE-08, BE-09, BE-27, BE-35, BE-41 và một phần BE-21. **Đã chạy test: 86/86 đạt** (trừ `SeedDataTest`); migration `V11` chạy tốt trên dữ liệu mẫu; spec API không đổi. Việc để sau (nhóm 1, việc cần làm cùng frontend, việc cần chủ repo quyết) ghi ở [DANH_GIA_BA_TESTER.md phần D](DANH_GIA_BA_TESTER.md).

### A. Dòng tiền (làm trước)

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-01 | P0 | COD: khi hoàn tất, ví người bán được cộng `gross` dù sàn chưa nhận đồng nào (shop tự giao thì shop giữ tiền mặt rồi vẫn rút được ví). Hoàn trả COD cũng cộng ví người mua từ không có gì, người bán không bị trừ | `order/OrderSettlement.java:56-57`, `:67-70` | Đối soát COD với đơn vị vận chuyển, hoặc COD chỉ trừ phí vào công nợ shop; hạn mức COD cho tài khoản mới; phạt bom hàng (BE-10) | | Đã sửa, test đạt (COD đối soát, hạn mức, chặn bom hàng) |
| BE-02 | P0 | Nạp ví xong rút ngay: ví không phân biệt tiền nạp với tiền bán hàng, mọi user đều rút được, chỉ cần tối thiểu 50.000đ, không có tối đa. Không kiểm tên chủ tài khoản (nhóm đã chủ ý bỏ luật khớp họ tên ở đợt rollback, xem QA_FINDINGS #15; các biện pháp còn lại vẫn thiếu), không cần OTP khi đổi tài khoản ngân hàng | `wallet/WalletService.java:154-167`, `wallet/WalletDtos.java:36-42` | KYC + tên chủ tài khoản khớp; OTP và thời gian chờ khi thêm tài khoản ngân hàng mới; hạn mức rút/ngày; tiền nạp chỉ rút sau N ngày hoặc về đúng nguồn | | Sửa một phần: khoá tiền mới nạp 24h + hạn mức rút/ngày + gắn nguồn tiền. Chưa có KYC, OTP khi đổi tài khoản ngân hàng |
| BE-03 | P0 | Trả hàng không có bước hàng quay về: shop đồng ý hoặc Admin phán là hoàn tiền người mua và cộng lại tồn kho ngay. Người mua giữ cả sách lẫn tiền; tin bán lại một cuốn chưa về tay | `order/OrderService.java:409-424`, `:448-465`; `order/OrderSettlement.java:63-71` | Thêm `RETURN_SHIPPING` → `RETURN_RECEIVED`; quy định ai chịu ship trả; hoàn một phần; không tự lên bán lại | | Đã sửa, test đạt (trả hàng theo bước, không tự cộng tồn kho) |
| BE-04 | P0 | Shop tự gọi `ship` (mã vận đơn bỏ trống thì tự sinh) rồi `delivered` ngay, không chứng cứ giao. Đồng hồ 3 ngày chạy từ đó, hết hạn tự hoàn tất và trả tiền. **Sau pull:** frontend đã bỏ điều kiện `Env.useMock`, nên nút "Giả lập: đã giao thành công" hiện cho người bán ở mọi môi trường; comment nói "backend chỉ nhận ở môi trường dev" là sai, hai endpoint không có kiểm tra môi trường nào | `order/OrderManagementController.java:57-68`, `order/OrderService.java:347-369` | Webhook hãng vận chuyển (GHN/GHTK), hoặc mã vận đơn thật + thời gian tối thiểu giữa SHIPPING và DELIVERED | | Đã sửa, test đạt (tắt nút giả lập ngoài dev, người mua xác nhận, tự coi là đã giao sau 7 ngày). Chưa có hãng vận chuyển thật |
| BE-05 | P1 | Phí đọc cấu hình lúc hoàn tất, không lưu tỷ lệ lúc chốt. Admin đổi hoa hồng 15% → 25% thì hợp đồng ký gửi đã chấp nhận 15% bị tính 25%. Bước giá cũng đọc trực tiếp từ cấu hình, đổi giữa phiên là đổi luật | `order/OrderSettlement.java:59`, `auction/AuctionSettlement.java:274`, `system/SystemConfigService.java:83` | Lưu tỷ lệ phí vào đơn và hợp đồng ký gửi; chốt bước giá theo phiên | | Đã sửa, test đạt (phí đơn thường và hoa hồng đấu giá chụp lúc chốt). Bước giá vẫn đọc cấu hình trực tiếp |
| BE-06 | P2 | Không có job đối soát (tổng ví so với nạp − rút ± phí) và báo cáo công nợ sàn | toàn `src/main` (không có) | Job đối soát hằng đêm, cảnh báo khi lệch | | Sửa một phần: job đối soát ví với sổ cái hằng đêm. Chưa có đối soát tổng với cổng thanh toán |

### B. Đơn hàng

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

### C. Đấu giá và ký gửi

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

### D. Tài khoản, xác thực, Admin

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-26 | P0 | **Đã sửa một phần.** Đã sửa: đăng nhập sai 10 lần trong 15 phút thì 429 `TOO_MANY_REQUESTS`, đếm theo email (email không tồn tại cũng bị đếm, không lộ email nào có thật); bộ đếm OTP sai trước đây bị rollback cùng lỗi nên thực tế dò OTP vô hạn, nay lưu bằng giao dịch riêng (`REQUIRES_NEW`), sai 5 lần thì mã đúng cũng bị từ chối. **Còn lại:** xin OTP mới (`sendOtp`, `forgotPassword`) không giới hạn, mỗi mã mới cho thêm 5 lần đoán; OTP vẫn chỉ ghi log, không gửi email / SMS nên "đã xác thực SĐT" để đấu giá không có nghĩa ngoài dev; SĐT `UNIQUE` kể cả chưa xác thực nên chiếm được số của người khác | `auth/AuthService.java:79-93` (đã sửa), `auth/OtpAttempts.java`, `auth/AuthService.java:114-130, 145-155` (còn lại), `V1__init_schema.sql:13` | Giới hạn tần suất `sendOtp` / `forgotPassword` theo user và email bằng `RateLimiter` sẵn có; dịch vụ email / SMS thật; `UNIQUE` chỉ cho SĐT đã xác thực | | Đã sửa một phần (`9d25426`, `1c04db7`). Cập nhật 14: giới hạn xin OTP, OTP gửi qua email; còn SMS, `UNIQUE` SĐT |
| BE-27 | P1 | Khoá tài khoản chỉ đổi trạng thái và thu hồi token; tin vẫn `ACTIVE`, yêu cầu rút tiền vẫn chờ, đơn dở và cọc đấu giá không được xử lý | `admin/AdminService.java:64-74` | Khoá có quy trình: ẩn tin, đóng băng ví, xử lý đơn dở | | Đã sửa, test đạt (ẩn tin, huỷ đơn chưa giao, hoàn cọc phiên chưa chốt) |
| BE-28 | P2 | Admin một cấp: một người tự duyệt rút tiền, đổi vai trò, đổi phí; chỉ chặn tự khoá / tự đổi quyền chính mình | `admin/AdminService.java:64-97`, `wallet/WalletService.java:216` | Xác nhận hai người cho rút lớn và đổi quyền | | |
| BE-29 | P2 | Dashboard "doanh thu" là tổng giá trị đơn hoàn tất (GMV), không phải phí sàn thực thu | `order/OrderRepository.java:75`, `admin/AdminService.java:128-129` | Tách GMV với phí thu được từ ví sàn | | |
| BE-30 | P2 | Không có xoá / ẩn danh tài khoản và xuất dữ liệu cá nhân (controller user chỉ có xoá địa chỉ); cần đối chiếu Nghị định 13/2023 (chưa xác minh) | `user/UserController.java` | Luồng xoá tài khoản giữ sổ cái ẩn danh | | |
| BE-31 | P2 | **Chưa xác minh pháp lý**, cần người am hiểu luật: giữ tiền hộ trong ví nội bộ có thể cần mô hình trung gian thanh toán hoặc tài khoản đảm bảo; khấu trừ thuế người bán cá nhân; hóa đơn điện tử cho phí sàn; sách cấm / lậu | toàn hệ thống | Tham vấn pháp lý trước khi chạy thật | | |

### E. Hạ tầng, cấu hình, API

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| BE-32 | P0 | Profile mặc định là `dev` (`${SPRING_PROFILES_ACTIVE:dev}`). Quên đặt biến khi deploy thì OTP trả thẳng trong response và `POST /payments/{code}/simulate` bật: gọi cho đơn nạp ví là tự nạp tiền miễn phí (`markSuccess` cộng ví với `TOP_UP`). JWT secret và khoá ZaloPay cũng có giá trị mặc định | `application.yml:13, 60-61, 72-80, 88-99`, `wallet/PaymentService.java:147-161`, `wallet/WalletController.java:101-105` | Mặc định profile `prod` hoặc bỏ default; thiếu `JWT_SECRET` thì không khởi động; `simulate` chỉ bật bằng biến môi trường tường minh | | Đã sửa 2026-11-07: mặc định `prod`, dev đặt `SPRING_PROFILES_ACTIVE=dev`; ngoài dev / test thiếu `JWT_SECRET` thì không khởi động (`ProductionGuard`); `devOtp` không trả khi mail thật đang bật. Còn: khoá ZaloPay vẫn có mặc định sandbox |
| BE-33 | P1 | **Đã sửa một phần.** Đã sửa: ISBN rỗng hoặc đúng 10 / 13 ký tự (`^$\|^(\d{9}[\dXx]\|\d{13})$`, chỉ kiểm định dạng, không kiểm số kiểm tra, không nhận dấu gạch); số tài khoản khi rút `\d{6,19}`. **Còn lại:** không có cận trên giá / tồn kho (`price ≥ 1000`, `stock ≥ 0`, không `@Max`); tên chủ tài khoản không có pattern; số tài khoản của shop (`ShopRequest`) vẫn chỉ `@Size(max=50)`; cấu hình chỉ cần số nguyên ≥ 0 nên Admin đặt `order.payment_timeout_minutes=0` thì mọi đơn bị huỷ ngay, `order.auto_complete_days=0` thì hết thời hạn khiếu nại. (SĐT và mật khẩu 8–72 ký tự đã được kiểm đúng) | `catalog/CatalogDtos.java:41, 70-71`, `wallet/WalletDtos.java:40`, `user/UserDtos.java:71`, `system/SystemConfigService.java:116-121` | Khoảng min/max theo từng khoá cấu hình; cận trên giá / tồn kho; pattern tên chủ tài khoản và số tài khoản shop; cân nhắc kiểm số kiểm tra ISBN | | Đã sửa một phần (`9d25426`) |
| BE-34 | P1 | Upload: biên lai chuyển khoản (có số tài khoản) và ảnh sách chung một thư mục, `GET /files/*` công khai và cache `public` 7 ngày; chỉ tin `Content-Type` do client khai; không quota; không dọn file mồ côi; lưu đĩa cục bộ nên mất khi deploy lại (SRS ghi Cloudinary) | `file/FileController.java:35-77`, `security/SecurityConfig.java:50-51` | Object storage; biên lai cần quyền xem; kiểm nội dung thật; giới hạn theo user; job dọn file mồ côi | | Sửa một phần 2026-11-07: Admin duyệt rút tiền thì ảnh biên lai chuyển sang `uploads/private/`, xem qua `GET /files/private/{tên}` (cần đăng nhập; chỉ người rút và Admin / Staff, người khác nhận 404; `Cache-Control: no-store`); app tải ảnh này kèm token. Còn: object storage, kiểm nội dung thật, quota, dọn file mồ côi |
| BE-35 | P1 | Nhiều lỗi nghiệp vụ dùng chung mã `FORBIDDEN`; frontend phải dò chuỗi tiếng Việt để phân biệt, đổi câu chữ là hỏng. Sửa cùng [FE-07](DANH_GIA_BA_TESTER.md) | `common/ApiException.java:32-34`, `auction/BidService.java:279, 283` | Thêm mã riêng `AUCTION_BANNED`, `NOT_REGISTERED`… | | Đã sửa, test đạt (AUCTION_BANNED, NOT_REGISTERED) |
| BE-36 | P1 | Thông báo ngoài app: không gửi push / email / SMS (code ghi rõ không gửi FCM) và không có endpoint đăng ký thiết bị. Người thắng có 48h để trả, app tắt thì không biết rồi mất cọc oan. Làm cùng [FE-03](DANH_GIA_BA_TESTER.md) | `notification/NotificationService.java:16`, `openapi.yaml` (không có `device`) | Endpoint đăng ký FCM token; gửi FCM trong `notify`; email / SMS cho các mốc có hạn (thắng lô, hạn thanh toán, mời mua lần hai) | | Sửa một phần (cập nhật 14): email cho các mốc có hạn, không phạt khi chưa báo được. Còn FCM, SMS |
| BE-37 | P1 | Phí ship so khớp "cùng tỉnh" bằng chuỗi tên; dữ liệu địa chỉ phía frontend là 63 tỉnh, trong khi địa giới đã đổi từ giữa 2025 (**cần xác minh lại**) nên so khớp và bảng phí sẽ lệch | `order/ShippingCalculator.java:20-39` | Danh mục địa giới có mã, bảng phí theo vùng, cân nặng thực; về lâu dài dùng API hãng vận chuyển | | |
| BE-38 | P2 | WebSocket nhận JWT qua `?token=` trên URL (lộ trong log proxy); token chỉ kiểm lúc nối, hết hạn giữa phiên vẫn kết nối | `notification/RealtimeHub.java:55-57` | Vé WS ngắn hạn dùng một lần | | |
| BE-39 | P2 | Chỉ chạy được một instance: `RealtimeHub` giữ kênh WS trong RAM, `AuctionEngine` tick trong tiến trình. Đây là giới hạn nhóm đã biết (ghi ở `AuctionEngine.java:19`), cần xử lý nếu mở rộng | `notification/RealtimeHub.java:41`, `auction/AuctionEngine.java:19` | Redis pub/sub cho kênh WS; ShedLock cho job | | |
| BE-40 | P2 | Không có CI / deploy cho backend (`.github/workflows` chỉ có `frontend-ci.yml`, `frontend-deploy.yml`); chỉ có actuator `health,info`, không metrics hay cảnh báo khi job lỗi hoặc tick đấu giá chậm | `.github/workflows/`, `application.yml:49-53` | `backend-ci.yml` chạy `./mvnw test`; metrics + cảnh báo | | |
| BE-41 | P2 | Không có test đồng thời cho trả giá, tồn kho, ví (không test nào dùng `ExecutorService`/`CountDownLatch`) | `src/test` | Test song song cho `applyBid`, `reserveStock`, `WalletService.move` | | Đã sửa, test đạt (ConcurrencyTest: đặt hàng, tồn kho, rút tiền, trả giá song song) |
| BE-42 | P1 | **Mới (từ code vừa thêm).** Khoá đăng nhập chỉ đếm theo email, không theo IP: ai cũng khoá được tài khoản của người khác 15 phút bằng 10 lần đăng nhập sai (đăng nhập đúng cũng bị chặn trong thời gian đó). Bộ đếm nằm trong RAM (mất khi khởi động lại, không dùng được khi chạy nhiều instance); dọn rác chỉ xoá khoá đã hết hạn nên gửi hàng loạt email giả trong 15 phút làm bảng phình tới khi hết hạn | `common/RateLimiter.java:20-32`, `auth/AuthService.java:79-93` | Thêm khoá theo IP (kèm email), trả `Retry-After`; giới hạn kích thước bảng; chuyển sang Redis khi chạy nhiều instance (cùng BE-39) | | |

### Thứ tự gợi ý
1. **BE-32** (sửa nhỏ, sai là hỏng cả hệ thống khi deploy).
2. **BE-01 → BE-04, BE-26** (P0 còn lại).
3. **BE-05, BE-13**: lưu tỷ lệ phí lúc chốt, chống checkout trùng; sửa nhỏ.
4. **BE-07, BE-08, BE-09**: hạn và uy tín người bán.
5. **BE-17, BE-18, BE-36**: cọc đấu giá công bằng và thông báo ngoài app.


---

### Cập nhật 5: đợt vá sau đánh giá lại (2026-11-06)

Vá các lỗ hổng tìm thấy khi đánh giá lại: COD vận hành thật (Staff đối chiếu hãng vận chuyển, đơn COD không tự giao), địa chỉ nhận hàng trả, danh sách lô chờ kiểm định lại, nhắc việc trước hạn, phủ nhật ký bảo mật (BE-26, BE-42 phần log), cảnh báo COD đang giao quá lâu. Chi tiết: [THAY_DOI_SO_VOI_CODE_CU.md phần E](THAY_DOI_SO_VOI_CODE_CU.md) mục H. Migration `V12`; `apps/backend/openapi.yaml` đã xuất lại (chỉ thêm). **Đã chạy test: 101/101 đạt** (trừ `SeedDataTest`).

Còn lại không đổi: nhóm 1 (BE-32, OTP trong log, BE-33), việc cần làm cùng frontend, việc cần chủ repo — xem [DANH_GIA_BA_TESTER.md phần D](DANH_GIA_BA_TESTER.md).


---

### Cập nhật 6: kiểm tra đấu giá nhiều người (2026-11-06)

Thêm `MultiBidderTest` và sửa 2 lỗi trong `BidService` (đặt giá tối đa sau giờ chốt; giá tay bằng giá tối đa của người đặt trước). Chi tiết: [THAY_DOI_SO_VOI_CODE_CU.md phần E](THAY_DOI_SO_VOI_CODE_CU.md) mục I. **Đã chạy test: 112/112 đạt** (trừ `SeedDataTest`).


---

### Cập nhật 7: ép số nguyên cho tiền, kiểm thử đầu cuối (2026-11-06)

Thêm `@WholeVnd` cho mọi ô nhập tiền chính; sửa mất gộp kiện phí giao hoá đơn đấu giá; thêm 31 test luồng đầu cuối. **Đã chạy test: 144/144 đạt** (trừ `SeedDataTest`). Chi tiết: [THAY_DOI_SO_VOI_CODE_CU.md phần E](THAY_DOI_SO_VOI_CODE_CU.md) mục J, kế hoạch [TEST_PLAN_TOAN_DIEN.md phần B](TEST_PLAN_TOAN_DIEN.md).


---

### Cập nhật 8: chặn nhân viên sàn đấu giá (2026-11-06)

Lỗ hổng mới (phát hiện khi đối chiếu bản đánh giá của nhóm, mục 6.6): đăng ký phiên và trả giá không kiểm vai trò, nên Staff / Admin có số dư và đã xác thực SĐT đăng ký và trả giá được, dù Staff là người kiểm định lô và biết giá sàn. Đã sửa: tài khoản `STAFF` / `ADMIN` bị chặn ở đăng ký phiên, trả giá tay và đặt giá tối đa (403 `STAFF_CANNOT_BID`), kể cả khi đã có đăng ký từ trước; cọc thêm cần đăng ký hợp lệ nên cũng bị chặn theo. `User.isPlatformOperator()`, `AuctionService.register`, `BidService.requireBidder`; test `MultiBidderTest.platformStaffCannotRegisterOrBid`. **Đã chạy test: 145/145 đạt** (trừ `SeedDataTest`). Spec API không đổi (chỉ thêm mã lỗi); frontend hiện câu thông báo của server nên không cần sửa.


---

### Cập nhật 9: luật nghiệp vụ nhóm 1 và nhóm 4 của SRS bổ sung (2026-11-06)

Làm theo [THAY_DOI_SO_VOI_CODE_CU.md phần C](THAY_DOI_SO_VOI_CODE_CU.md) mục 11, nhóm 1 và 4 (chi tiết và chỗ làm khác thiết kế ghi ngay trong tài liệu đó). Migration `V13__business_rules_batch1.sql` và seed dev `V13_1__demo_auction_schedule.sql`; `apps/backend/openapi.yaml` đã xuất lại (thêm 4 endpoint sự cố kho, trường `isbnWarning`; đổi mẫu ISBN và cọc tối thiểu). **Đã chạy test: 158/158 đạt** (trừ `SeedDataTest`); khởi động thử profile `dev` trên DB trống: 16 migration chạy tốt.

| Luật | Đã làm |
|---|---|
| BR-2.2–2.5 | ISBN bỏ gạch, kiểm số kiểm tra (`INVALID_ISBN`), lưu dạng ISBN-13, tìm được bằng ISBN-10 / có gạch; đổi ISBN, NXB, năm thì tin duyệt lại; ISBN cũ giữ nguyên không bị kiểm lại (7/8 ISBN dữ liệu mẫu sai số kiểm tra) |
| BR-4.6, BR-5.5 | Phiếu kiểm định chặn giá ≤ 0 ngay lúc lập (`INVALID_PRICE`), trước đây làm yêu cầu ký gửi kẹt; cọc phiên tối thiểu 1.000đ |
| BR-5.1–5.4 | Công bố phải trước giờ mở 72 giờ, hạn đăng ký trước giờ mở 24 giờ; chốt % phí người mua, bảng bước giá, hệ số hạn mức vào phiên lúc công bố; "mở phiên ngay" chỉ khi `app.auction.demo-enabled` (`DEMO_ONLY`) |
| BR-6.1, BR-6.2, BR-6.5 | Cọc / phạt người bỏ thanh toán về sàn 100%; mời mua lần hai ở giá công bằng; sàn bù chênh cho người bán khi lô bán lại thấp hơn (trần = số đã thu từ người bỏ) |
| BR-4.2, BR-4.8, BR-4.9 | Sự cố kho: Staff khai báo, Admin duyệt; bồi thường theo giai đoạn; mất → lô / kho / ký gửi `LOST`; hỏng → Admin chọn 0–100%, trả sách miễn phí lưu kho |

Việc đi kèm: frontend chưa có màn sự cố kho, chưa hiện `isbnWarning`, chưa biết các mã lỗi mới (ghi ở `DANH_GIA_BA_TESTER.md phần D`). Bản sửa tìm kiếm không dấu của nhóm (chưa push, đang là `V9__unaccent_search.sql`) phải đổi số thành **V17** (V14 đến V16 đã dùng ở cập nhật 10 đến 12). *Cập nhật 14: V17 đã dùng cho gửi mail, bản này đổi thành **V18**.*

### Cập nhật 10: sửa hai lỗi P0 tìm thấy khi đánh giá lại luồng tiền, mua bán, đấu giá (2026-11-06)

| ID | Lỗi | Đã sửa |
|---|---|---|
| BE-43 | Người dẫn đặt giá tối đa ≥ giá sàn nhưng giá chỉ được trả hộ tới giá khởi điểm / 1 bước trên người thua, nên lô chốt `RESERVE_NOT_MET` dù có người sẵn sàng mua (`auction/BidService.java` `resolveProxies`) | Hết người thách đấu mà giá còn dưới giá sàn và giá tối đa của người dẫn ≥ giá sàn thì trả hộ lên đúng giá sàn (`liftLeaderToReserve`). Giá tối đa dưới giá sàn không đổi. Hệ quả chấp nhận được: giá nhảy đúng bằng giá sàn nên người xem đoán được giá sàn (giống eBay "đạt giá sàn") |
| BE-44 | Đơn trả trước bị tự coi là đã giao sau 7 ngày (shop tự sinh mã vận đơn được) mà người mua không có cách đòi tiền: chỉ có lý do "sai mô tả", Admin hoàn tiền thì đơn chuyển sang chờ người mua gửi trả sách họ không có | Lý do trả hàng mới `NOT_RECEIVED` (migration `V14`): không cần ảnh, chỉ cho đơn thường (đơn đấu giá do kho của sàn giao, báo lỗi `RETURN_NOT_ALLOWED`); shop đồng ý hoặc Admin phân xử hoàn tiền là đơn `RETURNED` và hoàn tiền ngay, không qua bước gửi trả. Lý do khác vẫn bắt 1–10 ảnh (`IMAGES_REQUIRED`). **Frontend chưa có lựa chọn này** |
| BE-45 | Thắng đấu giá, trả tiền rồi từ chối nhận hàng thì được hoàn đủ, không phạt, không cấm: rẻ hơn hẳn bỏ thanh toán (`AuctionSettlement` nhánh `FAILED_DELIVERY`) | Staff báo giao thất bại gửi thêm `buyerFault` (`DeliveryFailedRequest`). `true` với đơn đấu giá: vẫn hoàn tiền và trả lô về kiểm định lại, rồi phạt như bỏ thanh toán (10% giá búa, cấm đấu giá, ghi `defaulted_hammer` để bù chênh người bán) và thu phí giao chiều đi (BR-3.5, chỉ cho đơn đấu giá). Không gửi thì như cũ. Phí giao ghi nợ với `ref_type = ORDER_SHIPPING` để không tính vào trần bù chênh. **Frontend chưa có ô chọn này** |
| BE-46 | Trả ZaloPay sát hạn mà cổng báo về chậm thì job vẫn huỷ hoá đơn, thu cọc, cấm đấu giá (K18) | Trước khi phạt, job hỏi lại ZaloPay (`PaymentService.refresh`); đã trả thì ghi nhận hoá đơn; còn chờ thì ân hạn thêm 15 phút sau hạn thanh toán (hằng số trong code). Quá ân hạn mới phạt như cũ |
| BE-47 | `DebtService.collect` đọc danh sách nợ trước khi khoá ví, bảng nợ không có `@Version`: hai lượt thu song song trừ ví hai lần cho cùng một khoản nợ | Khoá ví trước rồi mới đọc nợ |

`apps/backend/openapi.yaml` sửa tay (thêm `NOT_RECEIVED`, `images` không bắt buộc) vì chưa chạy được app để xuất lại. Test mới: `NotReceivedReturnTest`, hai test giá sàn trong `MultiBidderTest` (bốn test cũ sửa kỳ vọng theo luật mới), bốn test trong `AuctionMoneyTest` (ân hạn ZaloPay, giao thất bại do / không do người mua), một test thu nợ song song trong `ConcurrencyTest`. `apps/backend/openapi.yaml` thêm `DeliveryFailedRequest`. **Chưa chạy test** vì máy không có PostgreSQL.

### Cập nhật 11: nhóm thuần backend của bản đánh giá BA / tester (2026-11-06)

Theo [DANH_GIA_BA_TESTER.md phần A](DANH_GIA_BA_TESTER.md). Migration `V15__consignment_deadlines_and_warehouse_sla.sql` (2 cấu hình mới, 2 cột). Không đổi API. Test mới: `BaReviewGapsTest`. **Chưa chạy test** (máy không có PostgreSQL).

| Mục | Đã làm |
|---|---|
| 10. Khoá tài khoản giữa đấu giá | Khoá thì huỷ ngay hoá đơn đấu giá chưa trả, không phạt, hoàn cọc, mời người về nhì; huỷ mọi giá tối đa còn hiệu lực; rút lô của người bán khỏi phiên chưa chạy (không tính lượt). Hoá đơn của người đang bị khoá mà quá hạn cũng huỷ không phạt. Người bị khoá không được mời mua lần hai. Còn lại: lô người bị khoá đang dẫn trong phiên đang chạy vẫn có thể thắng, hoá đơn đó chờ quá hạn mới chuyển cho người về nhì |
| 11. Người bán không quyết sau kiểm định | `consignment.seller_decision_days` = 7: quá hạn thì coi như rút, bắt đầu tính hạn nhận lại sách. Chưa có nhắc trước hạn |
| 12. Sách vô chủ | `warehouse.abandon_days` = 60 (tối thiểu 14): còn 7 ngày thì nhắc một lần; nhắc đủ 7 ngày mà chưa nhận thì thu phí kho đến hôm nay (thiếu thì nợ), xuất kho lý do `ABANDONED`, ký gửi `RETURNED`, tin chờ duyệt của cuốn đó bị từ chối. Dùng lại trạng thái `RETURNED` để giao diện không gặp giá trị lạ. **Cần ghi điều khoản thanh lý vào hợp đồng ký gửi điện tử** |
| 13. Kho quá hạn xử lý hoá đơn đấu giá | Cùng hạn với shop (`order.confirm_timeout_hours`, `order.ship_deadline_days`), tính từ lúc trả: báo mọi Staff / Admin một lần. Không tự huỷ. Đơn nhận tại kho không tính hạn giao |
| 25. Lịch hẹn ký gửi | Chặn giờ trong quá khứ (`APPOINTMENT_IN_PAST`). Chưa chặn ngày nghỉ / công suất kho: cần chủ sàn quyết lịch nghỉ |
| 27. Cấu hình phá luật | Mức tối thiểu cho 16 khoá thời hạn (ví dụ thời hạn thanh toán ≥ 5 phút, các hạn ngày ≥ 1) |

### Cập nhật 12: đợt 2 thuần backend của bản đánh giá BA / tester (2026-11-06)

Migration `V16__delivery_fault_high_value_lots_progressive_ban.sql` (3 cấu hình, 3 cột). Test mới: `BaReviewBatch2Test`. **Chưa chạy test** (máy không có PostgreSQL).

| Mục | Đã làm | Đổi API |
|---|---|---|
| 7. Giá đổi lúc đặt hàng (BE-12, BR-2.13) | `CheckoutRequest.expectedTotal` (tuỳ chọn): khác tổng mới thì `PRICE_CHANGED` 409, không giữ hàng, không trừ tiền. Chỉ kiểm khi app gửi; khi mọi bản app đã gửi thì nên bắt buộc. Chưa làm "giá tăng quá X% thì duyệt lại tin" | Thêm field tuỳ chọn |
| 8. Giao thất bại đơn thường (BR-3.5 đến BR-3.7) | `POST /staff/orders/{id}/carrier-failed` nhận `fault` (`BUYER` / `CARRIER` / `SHOP`, lưu ở `orders.delivery_fault`). `BUYER` + đã trả trước: hoàn tiền sách, phí giao chiều đi về shop. `SHOP`: tính lỗi shop. Chặn COD chỉ đếm lần giao thất bại do người mua (hoặc chưa ghi lỗi). Ô `buyerFault` của cập nhật 10 (chưa commit) đổi thành `fault` cho cả đơn đấu giá. Chưa làm BR-3.4 (shop chịu ship chiều về khi sai mô tả) vì cần quyết ví sàn ứng tiền trước hay trừ thẳng shop | Body `carrier-failed` đổi sang `DeliveryFailedRequest` (vẫn có `reason`) |
| 15. Lô cao giá (BR-5.6) | Ước tính cao ≥ `auction.high_value_lot_threshold` (10 triệu): trả giá / đặt giá tối đa cần tổng cọc ≥ cọc phiên + `auction.high_value_deposit_percent` (10%) mức thấp ước tính, thiếu thì `LOT_DEPOSIT_REQUIRED` kèm số cần cọc thêm. Ngưỡng đọc cấu hình hiện tại, chưa chốt vào phiên. Chưa làm BR-5.7 (catalogue ghi "lô cao giá") | Mã lỗi mới |
| 17. Khoá đăng nhập bị lợi dụng (BE-42) | Ba bộ đếm: email + IP (10 lần), IP (30), email trên mọi IP (100). Một IP sai 10 lần không còn khoá chủ tài khoản ở IP khác. Vẫn giữ trong RAM (BE-39); sau proxy phải bật `server.forward-headers-strategy` để lấy đúng IP | Không |
| 23. Cấm luỹ tiến (BR-6.4) | Lần 1 cấm `auction.ban_days` (90), lần 2 trong 12 tháng cấm `auction.ban_days_repeat` (365), lần 3 vĩnh viễn (Admin vẫn gỡ được bằng `lift-auction-ban`, số lần vẫn giữ). Bỏ nhiều lô khi đang bị cấm (cùng phiên) chỉ tính một lần. Từ chối nhận lô cũng tính | Không |

### Cập nhật 13: khởi động lại backend giữa phiên đấu giá (2026-11-06)

| ID | Lỗi | Đã sửa |
|---|---|---|
| BE-48 | Backend tắt lâu hơn thời gian còn lại của lô đang mở: bật lại thì nhịp đầu tiên chốt lô ngay theo `ends_at` cũ, người trả giá không có cơ hội trong lúc hệ thống tắt (`AuctionRunner.tick`) | `AuctionEngine` gọi `AuctionRunner.recoverAfterRestart` một lần ở nhịp đầu tiên: lô đang mở còn ít hơn thời gian soft close thì kéo dài cho đủ, báo cả phòng `SESSION_RESUMED`, ghi log WARN. Không đổi API, không migration. Test: 2 ca trong `MultiBidderTest`; chạy thật bằng `testdata/e2e_restart.sh` với 75 giây tắt máy. Giới hạn: chỉ nhận biết khởi động lại của chính tiến trình (một instance, BE-39) |

### Cập nhật 14: gửi mail, OTP thật, giữ tiền shop mới (2026-11-06, tối)

P0 mục 2, 3, 4 của phần A, theo [THIET_KE_GUI_MAIL.md](THIET_KE_GUI_MAIL.md). Migration `V17`; bản tìm kiếm không dấu chưa push của nhóm giờ phải đổi số thành **V18** (Flyway không nhận migration số nhỏ hơn số đã chạy). Thêm `spring-boot-starter-mail`. **Đã chạy test: 199/200 đạt** (trừ `SeedDataTest`). `apps/backend/openapi.yaml` **chưa xuất lại** (cần bật backend có DB).

| ID | Đã sửa | API |
|---|---|---|
| BE-36 (phần email) | Bảng `email_outbox` ghi cùng giao dịch với thông báo, `EmailOutboxJob` gửi mỗi 30 giây, thử lại 4 lần. Thư cho: thắng lô / mời mua lần hai, nhắc thanh toán, bị phạt, shop sắp quá hạn giao / trả lời huỷ, các mốc ký gửi có hạn. Hoá đơn đấu giá tới hạn mà thư báo thắng chưa gửi được và thông báo chưa đọc: gia hạn 24 giờ một lần, báo Admin. Tắt health check mail của actuator | Không |
| BE-26 (phần còn lại) | OTP gửi qua email, bỏ dòng log mã OTP. Xin mã cách nhau ≥ 60 giây, tối đa 5 / giờ, 10 / ngày cho mỗi tài khoản hoặc mỗi email (`TOO_MANY_REQUESTS`). Lỗi SMTP khi xin mã: 503 `EMAIL_SEND_FAILED`. Cột sinh `users.email_normalized` UNIQUE chặn đăng ký bằng biến thể của cùng hộp thư | Mã lỗi mới |
| P0 mục 4 | Shop mới (chưa uy tín, mở < 30 ngày hoặc < 10 đơn hoàn tất) bị giữ tiền bán 7 ngày (`SALE_HELD`; `GET /wallet/withdrawable` thêm `saleHeld`, `saleUnlockAt`). Loại nợ `CHARGEBACK`, `POST /admin/debts/chargeback` | Thêm trường, endpoint, enum |

Còn lại: SMS, CCCD, push (FE-03), mail khi duyệt rút tiền / khoá tài khoản, nhận chargeback tự động từ cổng, xuất lại spec.

---

# Phần C. Audit frontend (FE-xx)

*(Trước là `AUDIT_FRONTEND.md`.)*

Ngày 2026-11-05. Đọc hạ tầng và luồng chính của `apps/frontend` (core, realtime, auth, env, CI, tài liệu bàn giao); **chưa đọc từng màn hình**. Mỗi mục đã được kiểm lại với code (có `file:dòng`).
Lỗi backend ở [DANH_GIA_BA_TESTER.md phần B](DANH_GIA_BA_TESTER.md). Mức: **P1** gây hỏng trải nghiệm hoặc rủi ro thật · **P2** thiếu cho bản chạy thật.
Cột "Người nhận" và "Trạng thái" để nhóm tự điền; trạng thái trống = chưa sửa. Đường dẫn tính từ `apps/frontend/`.

### Cập nhật sau khi pull (đến commit `6af440c`, 2026-11-05)

Đã đối chiếu các commit frontend mới (`3ea1ff6`, `48e8087`, `79b4123` và hai tài liệu QA ngày 05/11 đã xoá khỏi repo, xem lịch sử git) với bảng này.

| Mục | Kết quả | Ghi chú |
|---|---|---|
| FE-01 … FE-07, FE-10, FE-11 | Chưa đổi | `env/*.json`, `env.dart`, `auth_interceptor.dart`, `realtime_client.dart`, `push_service.dart`, `geocoder.dart`, `_normalizeCode` không có commit nào đụng tới |
| FE-08 | Sửa nhỏ | Lưu được cờ "đã xem giới thiệu"; theme / ngôn ngữ vẫn trong RAM |
| FE-09 | Tốt hơn | 38 file test (trước 30); vẫn chưa có test với backend thật |
| FE-12 | Mới | Nút giả lập giao hàng lộ ra ở mọi môi trường |

Các lỗi QA tìm ra và đã sửa (đều nằm ngoài danh sách audit, do test thủ công): Admin duyệt rút tiền gửi giờ không có múi giờ (400); đăng nhập sai báo "hết phiên"; mật khẩu 6–7 ký tự lọt form; `+84` không đổi thành `0`; số rút tối thiểu lệch (10.000 so với 50.000); xoá danh mục còn con báo sai; ảnh sản phẩm trong đơn là ảnh ngẫu nhiên; phí ship giỏ hàng khác bước xác nhận; mở shop báo lỗi khi chưa có shop; Staff vào màn phiên bị 403 tải mãi; trang phiên không tự cập nhật (nay làm mới mỗi 15 giây, xem mục bên dưới).

Mục mới đáng chú ý: trang phiên và danh sách phiên giờ **hỏi lại backend mỗi 15 giây** (`_refreshPeriodically`) thay vì nghe WebSocket. Đủ cho trang xem, nhưng nhân với số người mở app thì tải tăng; nếu muốn gọn hơn thì dùng lại sự kiện `SESSION_STARTED` đã có ở kênh WebSocket.

### Việc frontend phải làm sau thay đổi luồng tiền (2026-11-05)

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

### Việc frontend phải làm sau thay đổi luồng tiền đấu giá (2026-11-05)

Backend đã đổi; **frontend chưa đổi gì**, `apps/backend/openapi.yaml` đã xuất lại (chạy `/sync-api`). Chi tiết quy tắc: [THAY_DOI_SO_VOI_CODE_CU.md phần B](THAY_DOI_SO_VOI_CODE_CU.md).

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

### Việc frontend sau đợt thuần backend 2026-11-06

Spec API **không đổi** trong đợt này. Frontend chỉ cần biết hành vi mới (đa số là thông báo, không cần màn mới):

| Hành vi backend mới | Frontend nên làm |
|---|---|
| Đơn `PREPARING` quá 3 ngày không giao cho vận chuyển tự chuyển `CANCELLED` và hoàn tiền | Ghi chú hạn giao ở màn đơn của shop; thông báo huỷ đã có |
| Yêu cầu huỷ không được shop trả lời trong 24 giờ tự được đồng ý | Hiện đếm ngược hạn trả lời ở màn đơn của shop |
| Shop bị gỡ uy tín khi tỷ lệ đơn lỗi vượt ngưỡng | Hiện trạng thái uy tín ở màn kênh người bán |
| Khoá tài khoản ẩn tin, huỷ đơn chưa giao, hoàn cọc | Không cần đổi |
| Mã lỗi `AUCTION_BANNED`, `NOT_REGISTERED` (trước đây dò chuỗi câu chữ) | Có thể bỏ đoạn dò chuỗi tiếng Việt trong `app_exception.dart` (FE-07); tạm thời vẫn chạy vì hằng số đã khớp |
| Duyệt tin chuyển từ lô không bán bị từ chối `BOOK_IN_WAREHOUSE` khi sách còn trong kho | Dịch lỗi ở màn duyệt tin của Admin |

### Việc frontend sau đợt gửi mail 2026-11-06 (tối)

Spec **có đổi** (chỉ thêm) nhưng `apps/backend/openapi.yaml` chưa xuất lại; xuất xong thì chạy `/sync-api`.

| Thay đổi backend | Frontend cần làm | Nếu chưa làm |
|---|---|---|
| `POST /auth/send-otp`, `/auth/forgot-password`: `TOO_MANY_REQUESTS` khi xin lại trong 60 giây hoặc quá 5 mã / giờ; `send-otp` có thể trả 503 `EMAIL_SEND_FAILED` | Đếm ngược 60 giây trước khi cho bấm "Gửi lại mã"; dịch hai mã lỗi | Người dùng thấy lỗi chung |
| Câu trả lời `send-otp` là "Đã gửi mã OTP tới email a***@..." | Hiện câu này, nhắc kiểm hộp thư rác | Không lỗi |
| `GET /wallet/withdrawable` thêm `saleHeld`, `saleUnlockAt`; rút tiền lỗi `SALE_HELD` | Màn rút tiền hiện "tiền bán hàng đang giữ đến ..."; dịch lỗi | Shop mới không hiểu vì sao không rút được |
| `POST /admin/debts/chargeback` {userId, amount, reason}; `DebtType` thêm `CHARGEBACK` | Nút "Ghi nợ chargeback" ở màn người dùng của Admin; nhãn loại nợ mới | Admin phải gọi API tay; loại nợ mới rơi vào `$unknown` |
| Cấu hình mới `wallet.seller_hold_days`, `wallet.seller_hold_min_orders`, `wallet.seller_hold_shop_days` | Nhãn tiếng Việt trong màn Cấu hình | Hiện khoá thô |

### Việc test còn nợ

Theo chính tài liệu QA, các phần này **chưa ai test được**, nên chưa có bằng chứng chạy đúng: cổng ZaloPay thật (mở form thẻ), thông báo đẩy FCM, mất mạng giữa phiên đấu giá, các mốc chờ 15 phút đến 48 giờ (hết hạn thanh toán, tự huỷ đơn shop không xác nhận, quá hạn 48h lô thắng, mời mua lần hai), tải ảnh từ thư viện và lưu form địa chỉ trên máy ảo, bấm tay phần Admin duyệt rút tiền, TalkBack. Nhiều mục trong [DANH_GIA_BA_TESTER.md phần B](DANH_GIA_BA_TESTER.md) (BE-07, BE-08, BE-17, BE-19, BE-36) nằm đúng ở các mốc này; cần job hoặc cách đẩy thời gian (chỉnh `payment_due_at` bằng SQL) để test.

### A. Lỗi cần sửa

| ID | Mức | Lỗi | Bằng chứng | Cách sửa | Người nhận | Trạng thái |
|---|---|---|---|---|---|---|
| FE-01 | P1 | Cấu hình build: `env/prod.json` là chỗ giữ chỗ (`https://api.example.com/api`, `wss://api.example.com/ws`) và còn tiền tố `/api` trong khi backend không có tiền tố này (`env/local.json` dùng `http://localhost:8080`). `frontend-deploy.yml` build bằng `prod.json` mỗi lần push `main`, nên bản live trỏ vào API không tồn tại. Ngoài ra `USE_MOCK` mặc định `true`: bản Android / iOS build thủ công mà quên `--dart-define-from-file` sẽ chạy bằng dữ liệu giả | `env/prod.json`, `env/dev.json`, `env/tunnel.json`, `lib/app/env.dart:14`, `.github/workflows/frontend-deploy.yml` | Điền URL thật, bỏ `/api`; đặt mặc định `USE_MOCK=false` (hoặc dừng khi thiếu cấu hình ở release) | | |
| FE-02 | P1 | Đăng xuất oan: `catch (_)` coi mọi lỗi lúc refresh token (rớt mạng, timeout, 500) là hết phiên và gọi `_onSessionExpired` | `lib/core/network/auth_interceptor.dart:64-67` | Chỉ đăng xuất khi refresh trả 401 / `INVALID_REFRESH_TOKEN`; lỗi mạng thì giữ phiên và báo thử lại | | |
| FE-03 | P1 | Thông báo đẩy chưa nối: `pushServiceProvider` không được gọi ở đâu (chỉ có dòng định nghĩa), `FCM_ENABLED=false` ở mọi file env kể cả `prod.json`, và backend chưa có endpoint đăng ký thiết bị. "Bị trả giá cao hơn", "thắng đấu giá" chỉ tới khi app đang mở. Làm cùng [BE-36](DANH_GIA_BA_TESTER.md) | `lib/core/notifications/push_service.dart:77-79`, `env/*.json` | Gọi `init()` sau đăng nhập, gửi token lên endpoint đăng ký thiết bị, xử lý `opened` để mở đúng màn | | |
| FE-04 | P1 | Realtime: nối lại cố định 3 giây, không backoff / jitter; không heartbeat nên kết nối chết nửa vời (mạng yếu, máy ngủ) không phát hiện. Đã có tải lại ảnh chụp trạng thái sau khi nối lại, nhưng phòng đấu giá chưa có thông báo trạng thái kết nối hay khoá nút trả giá khi chưa đồng bộ | `lib/core/realtime/realtime_client.dart:22, 108-114`, `lib/features/auction/presentation/screens/live_room_screen.dart` | Ping / pong định kỳ, backoff luỹ tiến, banner "mất kết nối", khoá trả giá khi chưa đồng bộ lại | | |
| FE-05 | P1 | Gọi thẳng dịch vụ công cộng từ app: Nominatim (giới hạn ~1 yêu cầu/giây, cấm dùng nặng), tile OSM công cộng `tile.openstreetmap.org`, `provinces.open-api.vn` (dữ liệu 63 tỉnh). Sổ bàn giao đã tự ghi rủi ro này | `lib/core/network/geocoder.dart:31-33`, `lib/shared/widgets/osm_map.dart:120`, `lib/core/network/admin_units.dart` | Proxy qua backend + cache; nhà cung cấp tile riêng; danh mục địa giới mới (liên quan [BE-37](DANH_GIA_BA_TESTER.md)) | | |
| FE-06 | P2 | Token trên web nằm trong `flutter_secure_storage` (thực chất lưu ở trình duyệt, XSS đọc được); refresh token sống 30 ngày. Cần xác nhận lại hành vi chính xác trên web | `lib/core/auth/token_storage.dart:54-56`, `apps/backend/src/main/resources/application.yml:62` | Cookie `httpOnly` cho web hoặc refresh ngắn hơn, thêm CSP | | |
| FE-07 | P1 | Xử lý lỗi dò chuỗi tiếng Việt: `FORBIDDEN` được chia thành `auctionBanned` / `notRegistered` bằng `message.contains('cấm tham gia đấu giá')`; backend đổi câu chữ là hỏng. Sửa cùng [BE-35](DANH_GIA_BA_TESTER.md) | `lib/core/error/app_exception.dart:33-38` | Dùng mã lỗi riêng khi backend thêm xong | | |
| FE-08 | P2 | Cài đặt (theme, ngôn ngữ, vị trí nút điều hướng) chỉ giữ trong RAM, mất khi mở lại app (sau pull: chỉ cờ "đã xem giới thiệu" được lưu qua `TokenStorage`, theme / ngôn ngữ vẫn chưa). Lý do ghi ở `DECISIONS.md`: allowlist không có `shared_preferences` | `lib/core/settings/app_settings_controller.dart:41-56` | Xin duyệt `shared_preferences` hoặc lưu qua `TokenStorage` | | |
| FE-09 | P2 | Kiểm thử mỏng: 38 file test cho 245 file nguồn (không tính file sinh; sau pull đã thêm test cho skeleton, cuộn tới ô lỗi, map lỗi, rút tiền của Admin, làm mới phiên, shop chưa mở, mapper, layout người mua); không thấy test nào gọi backend thật. Chưa có end-to-end (đặt hàng → thanh toán → hoàn tất; nhiều máy trả giá cùng lúc) | `test/` | Test tích hợp với `env/local.json`; dùng `tool/api_gap.dart` làm kiểm hợp đồng trong CI | | |
| FE-10 | P2 | Trợ năng và quan sát: chỉ 5 chỗ dùng `Semantics`/`semanticLabel`; không có Sentry / Crashlytics nên lỗi production không ai thấy; không có package phát hiện trạng thái mạng (`connectivity`) | `lib/`, `pubspec.yaml` | Nhãn đọc màn hình cho đồng hồ / nút trả giá, báo lỗi tập trung, banner offline | | |
| FE-11 | P2 | Sổ bàn giao đã cũ: mục B9 vẫn ghi mật khẩu "≥ 6 ký tự" và cột D ghi "chưa kiểm tra lại phía server", trong khi code (frontend và backend) đã là 8–72 ký tự và server đã kiểm SĐT / mật khẩu | `docs/BACKEND_HANDOFF.md` (mục B9, bảng D), `lib/core/utils/input_rules.dart:137-142` | Cập nhật tài liệu cho khớp code | | |
| FE-12 | P1 | **Mới (từ code vừa thêm).** Nút "Giả lập: đã giao thành công" (và "Giao thất bại") đã bỏ điều kiện `Env.useMock`, nên người bán thấy nút này ở mọi môi trường. Comment trong code nói "backend chỉ nhận ở môi trường dev" là sai: hai endpoint backend không kiểm tra môi trường nào. Kết quả: người bán tự bấm giao thành công cho đơn của chính mình rồi nhận tiền sau 3 ngày. Làm cùng [BE-04](DANH_GIA_BA_TESTER.md) | `lib/features/seller/presentation/screens/seller_order_detail_screen.dart:259-274`, `apps/backend/src/main/java/com/rebook/order/OrderManagementController.java:57-68` | Ẩn nút khỏi bản production (cờ build riêng, không dùng `useMock`) cho tới khi có webhook hãng vận chuyển; backend chặn các endpoint này ngoài profile dev | | |

### B. Việc đi kèm khi backend sửa

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

### C. Đã kiểm tra, không phải lỗi
- **Bấm đúp / gửi lặp ở giao diện**: đơn hàng, thanh toán, rút tiền và nút trả giá đều khoá khi đang gửi (`busy`/`isLoading`, ví dụ `order_detail_screen.dart:220`, `checkout_screen.dart:323`, `withdraw_screens.dart:326`, `live_room_screen.dart:336`). Rủi ro còn lại là hai tab / hai thiết bị, thuộc [BE-13](DANH_GIA_BA_TESTER.md).
- **Mật khẩu 8–72 ký tự**: frontend và backend đã khớp (`input_rules.dart:137`, `AuthDtos.java:18`).
- **Làm mới token đồng thời**: `QueuedInterceptor` đảm bảo chỉ refresh một lần.
- **Nối lại WebSocket**: đã tải lại ảnh chụp trạng thái sau khi nối lại (`auction_providers.dart:86-90`).

### Việc frontend sau đợt vá 2026-11-06

Spec API **có thêm** (`apps/backend/openapi.yaml`, chỉ thêm). Cần chạy `/sync-api` ở frontend.

| Thay đổi backend | Frontend nên làm |
|---|---|
| `GET /staff/orders/in-transit`, `POST /staff/orders/{id}/carrier-delivered`, `POST /staff/orders/{id}/carrier-failed` | Màn Staff "Đơn đang giao" với hai nút đối chiếu hãng vận chuyển. **Cần có để đơn COD hoàn tất được** |
| Đơn COD không còn tự chuyển "đã giao" | Màn đơn người mua / shop: không hứa "tự xác nhận sau N ngày" cho đơn COD |
| `ReturnResponse.returnToName`, `returnToAddress` | Màn trả hàng của người mua: hiện địa chỉ gửi trả cùng nút nhập mã vận đơn |
| `GET /staff/lots/inspecting` | Màn Staff "Lô chờ kiểm định lại" |
| Thông báo nhắc trước hạn (giao hàng, trả lời huỷ, thanh toán, chọn hướng xử lý lô) | Không cần màn mới; kiểm tra loại thông báo mới hiển thị đúng |

### Việc frontend sau đợt 2026-11-06 (ép số nguyên cho tiền)

Backend nay trả 400 khi số tiền lẻ hoặc quá 15 chữ số. Frontend đang gửi `int` nên không bị ảnh hưởng. Nếu sau này đổi sang `double`, giữ giá trị nguyên (`50000` hoặc `50000.0` đều được nhận, `50000.4` thì không). Phí giao của hoá đơn đấu giá có thể đổi (giảm) sau khi người thắng chọn giao tận nơi cho hoá đơn thứ hai: màn hoá đơn nên đọc lại chi tiết đơn sau mỗi lần đổi cách nhận.

---

# Phần D. Việc để sau

*(Trước là `BACKLOG_LATER.md`.)*

Ngày 2026-11-06. Danh sách những việc **chưa làm**, tách theo lý do. Mã `BE-xx` / `FE-xx` nằm ở [DANH_GIA_BA_TESTER.md phần B](DANH_GIA_BA_TESTER.md) và [DANH_GIA_BA_TESTER.md phần C](DANH_GIA_BA_TESTER.md).
Đã làm xong thì xoá khỏi đây hoặc ghi vào `SESSION_LOG_*.md`.

### A. Nhóm 1: hoãn theo yêu cầu chủ repo (làm sau, nhỏ nhưng quan trọng)

| Việc | Mã | Ghi chú |
|---|---|---|
| Đổi profile mặc định khỏi `dev`; thiếu `JWT_SECRET` thì không khởi động; `simulate-enabled` chỉ bật bằng biến môi trường tường minh | BE-32 | **P0**: quên đặt biến khi deploy thì OTP lộ và ai cũng tự nạp tiền miễn phí qua endpoint giả lập thanh toán |
| Gỡ mã OTP và email khỏi log (`AuthService.java:168`) | `LOGGING_DESIGN` bước 2 | Lỗi bảo mật |
| Khoảng min/max cho từng khoá cấu hình; cận trên giá, tồn kho; pattern tên chủ tài khoản và số tài khoản của shop | BE-33 | Nay có thêm 18 khoá cấu hình mới nên Admin đặt nhầm (vd hạn 0) dễ hơn |

### B. Phải làm cùng frontend (hoặc frontend đổi trước)

| Việc | Mã | Vì sao cần frontend |
|---|---|---|
| Đồng bộ client: `/sync-api`, enum mới (`INSPECTING`, `CANCELLED` của đăng ký, `AWAITING_GOODS`, `EXPIRED`), mã lỗi mới (`DEBT_OPEN`, `COD_NOT_ALLOWED`, `TOPUP_LOCKED`, `WITHDRAW_DAILY_LIMIT`, `AUCTION_BANNED`, `NOT_REGISTERED`, `BOOK_IN_WAREHOUSE`), ẩn nút giả lập giao hàng ở production, sửa `env/prod.json` | `DANH_GIA_BA_TESTER.md phần C` | Điều kiện để dùng được những gì backend đã đổi |
| Checkout gửi kèm giá người mua đã thấy; backend trả `PRICE_CHANGED` khi lệch; hộp thoại xác nhận lại | BE-12 | Hợp đồng API đổi |
| Ảnh biên lai chuyển khoản không công khai (cần token khi xem) | BE-34 | Ảnh đang tải bằng URL công khai, không kèm header |
| Thông báo ngoài app: endpoint đăng ký thiết bị, gửi FCM, email, SMS; frontend gọi `init()` và gửi token | BE-36, FE-03 | Cần frontend gửi token. **Email đã có (cập nhật 14)**, người thắng chưa nhận được thư thì không bị phạt; còn FCM, SMS |
| Xin lại OTP có đếm ngược, giới hạn tần suất gửi OTP; gửi OTP thật qua email / SMS | BE-26 (phần còn lại) | **Backend đã làm giới hạn và email (cập nhật 14)**; còn giao diện đếm ngược 60 giây, SMS |
| OTP hoặc thời gian chờ khi thêm tài khoản ngân hàng mới | BE-02 (phần còn lại) | Thêm bước nhập OTP ở luồng rút tiền |
| Hoàn một phần khi phân xử khiếu nại; shop nộp ảnh bằng chứng phản biện | BE-11 | Màn khiếu nại và đơn shop đổi |
| KYC người ký gửi và người thắng giá trị cao | BE-23 | Màn tải giấy tờ |
| Sự cố kho: mất, hỏng sách, khai báo giá trị, bồi thường | BE-24 | API và màn Staff mới |
| Xác nhận hai người cho rút lớn và đổi quyền | BE-28 | Màn Admin |
| Dashboard tách doanh thu thực (phí thu được) khỏi GMV (thêm trường, không đổi trường cũ) | BE-29 | Màn tổng quan hiển thị trường mới |
| Báo cáo review, shop phản hồi review, phát hiện review ảo | BE-16 | Màn đánh giá |
| Xoá / ẩn danh tài khoản, xuất dữ liệu cá nhân | BE-30 | Màn tài khoản |
| Phạt luỹ tiến cho người tái phạm; hiển thị mức phạt cho người dùng | (chưa mã) | Cần chủ sàn chốt mức; giao diện cảnh báo |
| Cấu hình mới hiện nhãn tiếng Việt ở màn Cấu hình phí | `DANH_GIA_BA_TESTER.md phần C` | `_configLabels` |
| Màn sự cố kho: Staff khai báo mất / hỏng sách (ảnh, mô tả), Admin duyệt (chọn % khi hỏng) hoặc từ chối; hiện giai đoạn và số tiền bồi thường | BR-4.2, BR-4.8 | API đã có (`/staff/warehouse/{id}/incidents`, `/staff/warehouse-incidents`, `/admin/warehouse-incidents/{id}/approve | reject`), chưa có màn hình |
| Mã lỗi mới: `INVALID_ISBN`, `INVALID_PRICE`, `DEMO_ONLY`, `STAFF_CANNOT_BID`, `INCIDENT_PENDING`, `INCIDENT_DECIDED`, `LOT_LIVE`, `LOT_AWAITING_PAYMENT`, `PLATFORM_FUNDS_INSUFFICIENT`, `SELLER_PERCENT_REQUIRED`; trạng thái `LOST` (lô, ký gửi, kho); loại giao dịch `COMPENSATION`; cờ `isbnWarning` ở màn duyệt tin | SRS bổ sung nhóm 1, 4 | Cần `/sync-api` và nhãn tiếng Việt |

### C. Cần quyết định của chủ sàn, quyền hạ tầng, hoặc người am hiểu luật

| Việc | Mã | Ghi chú |
|---|---|---|
| Workflow CI / deploy cho backend (`.github/workflows/backend-ci.yml`, cần Postgres service) | BE-40 | `.github/` thuộc nhóm file hạ tầng cần chủ repo duyệt (xem `CLAUDE.md`) |
| Chạy nhiều instance: Redis cho kênh WebSocket, khoá job | BE-39 | Chưa cần khi còn một node |
| Địa giới hành chính mới (34 tỉnh) và bảng phí giao theo vùng | BE-37 | Cần xác minh quy định hiện hành; frontend cũng đổi nguồn địa chỉ |
| Mô hình giữ tiền hộ, thuế người bán cá nhân, hoá đơn điện tử, kiểm duyệt sách | BE-31 | Cần tham vấn pháp lý |
| Vé WebSocket ngắn hạn thay JWT trên URL | BE-38 | Đổi giao thức nối của frontend |
| Duyệt các giá trị mặc định đã đề xuất (COD, khoá 24 giờ, phạt 10%, hạn 7 ngày, hạn giao 3 ngày, gỡ uy tín 10%) | `SESSION_LOG` mục D, `THAY_DOI_SO_VOI_CODE_CU.md phần B` mục 7 | Đổi được trong `system_configs` |
| `SeedDataTest` gắn cứng cổng 5432 nên không chạy trên DB ở cổng khác | | Sửa test để đọc URL từ `TEST_DB_URL` |
| Test thật với ZaloPay, FCM, các mốc chờ 15 phút đến 48 giờ, TalkBack | `DANH_GIA_BA_TESTER.md phần C` | Cần môi trường và thiết bị thật |

### D. Đấu giá còn dang dở (thuần backend nhưng lớn hoặc cần bàn thiết kế)

| Việc | Ghi chú |
|---|---|
| ~~Sàn huỷ hoá đơn đã thanh toán vì lỗi của sàn (mất, hỏng sách trong kho), hoàn tiền kèm bồi thường~~ | Đã làm 2026-11-06 (sự cố kho, SRS bổ sung BR-4.2). Còn: chưa có cách nạp vốn ví sàn (hai lỗ nhỏ khác đã vá, SESSION_LOG #87) |
| Bán sau phiên cho người trả giá cao nhất khi chưa đạt giá sàn | Cần luật mới và đồng ý của người bán |
| Chuyển lô không bán sang bán thường do sàn giao hộ (đúng SRS 6.6) | BE-21: nay chỉ chặn duyệt tin khi sách còn trong kho |
| Chống thông đồng đẩy giá: ghi IP / thiết bị lượt trả giá, cảnh báo tài khoản liên quan | BE-25; cần chốt chính sách thu thập IP |
| Hạn mức cọc theo giá trị lô | Đổi công thức hạn mức |
| Người ký gửi bị khoá còn lô đang xếp phiên | `AccountLockService` chưa xử lý lô của người ký gửi |

### E. Đã làm ở đợt thuần backend 2026-11-06 (để tham chiếu)

BE-07 hạn giao hàng cho vận chuyển, BE-08 hạn trả lời yêu cầu huỷ, BE-09 điểm uy tín shop và tự gỡ uy tín, BE-27 dọn việc dở khi khoá tài khoản, hoàn cọc phiên chưa chốt khi bị cấm đấu giá, BE-35 mã lỗi riêng `AUCTION_BANNED` / `NOT_REGISTERED`, BE-21 chặn duyệt tin khi sách còn trong kho, BE-41 test chạy song song. Chi tiết ở `THAY_DOI_SO_VOI_CODE_CU.md phần E` mục G.

### F. Đã làm ở đợt vá 2026-11-06 (để tham chiếu)

COD vận hành thật (Staff đối chiếu, đơn COD không tự giao), địa chỉ nhận hàng trả, danh sách lô chờ kiểm định lại, nhắc việc trước hạn, phủ nhật ký bảo mật, cảnh báo COD đang giao quá lâu. Việc frontend đi kèm: [DANH_GIA_BA_TESTER.md phần C](DANH_GIA_BA_TESTER.md) mục "Việc frontend sau đợt vá 2026-11-06".

Còn để sau (thêm sau đợt vá): gỡ dòng log OTP (`AuthService.java:168`) vẫn thuộc nhóm 1; ngưỡng 7 ngày của cảnh báo COD đang cứng trong `WalletReconciliationJob` (chưa đọc từ cấu hình).

### G. Thêm sau rà soát đấu giá nhiều người (2026-11-06)

- ~~Số tiền trả giá / giá tối đa chưa ép số nguyên~~: đã làm (SESSION_LOG mục J, `@WholeVnd`).
- Chưa kiểm tải thật (vài trăm người cùng phòng, WebSocket phát tin cho phòng đông, mất mạng giữa phiên).
