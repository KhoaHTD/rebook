# ReBook — Luật nghiệp vụ toàn hệ thống

Nov 6, 2026 · @Khoa

## Tổng quan

ReBook là chợ sách cũ có hai cách bán: **bán giá cố định** (shop tự đăng, tự giao) và **đấu giá** (sách ký gửi vào kho của sàn, sàn kiểm định rồi đem lên phiên). Mọi khoản tiền đi qua **ví ReBook theo kiểu escrow**: sàn giữ tiền của người mua và chỉ trả người bán khi đơn hoàn tất.

Tài liệu này mô tả luật trên nhánh `main` (bản có giao diện, dùng để demo). Mục "Nhánh improve\_bussinessrule" ở cuối liệt kê luật mới của backend chưa vào `main`. Mọi con số ở đây đã đối chiếu với code và migration, và Admin đổi được ở màn Cấu hình.

| Vai trò | Làm được gì | Không được làm |
| --- | --- | --- |
| Khách (Guest) | Xem sách, tìm kiếm, xem lịch phiên đấu giá | Mua, trả giá, ký gửi |
| Người dùng (USER) | Mua sách, nạp/rút ví, ký gửi, đăng ký và trả giá đấu giá; mở shop để bán giá cố định | Mua sách của chính shop mình |
| Staff | Sơ duyệt ký gửi, nhận sách và kiểm định tại kho, giao lô đấu giá, tạm dừng/tiếp tục phiên, huỷ lô | Duyệt tin, rút tiền, cấu hình |
| Admin | Duyệt tin đăng, khoá người dùng, đổi quyền, danh mục, tạo và công bố phiên, duyệt rút tiền, phân xử khiếu nại, cấu hình, xem nhật ký | Tự khoá mình, tự đổi quyền mình |

**Ba khoản phí của sàn:** 5% giá bán (đơn giá cố định, trừ vào tiền shop nhận), 10% phí người mua (cộng vào hoá đơn đấu giá), 15% hoa hồng người bán ký gửi (trừ vào giá gõ búa).

## Tài khoản và xác thực

Mỗi email và mỗi số điện thoại chỉ đăng ký được một tài khoản; sai mật khẩu 10 lần trong 15 phút thì bị chặn đăng nhập 15 phút.

| Luật | Giá trị | Mã lỗi |
| --- | --- | --- |
| Mật khẩu khi đăng ký / đổi / đặt lại | 8–72 ký tự (đăng nhập chỉ cần nhập) | 400 |
| Email trùng | Không cho đăng ký | `EMAIL_TAKEN` |
| Số điện thoại trùng | Không cho đăng ký / cập nhật; `+84` được đổi về `0` | `PHONE_TAKEN` |
| Sai mật khẩu | 10 lần / 15 phút theo email → chờ 15 phút | 429 |
| Mã OTP | 6 chữ số, sống 10 phút, sai tối đa 5 lần thì phải xin mã mới | `INVALID_OTP` |
| Access token (JWT) | 60 phút | 401 |
| Refresh token | 30 ngày, mỗi lần làm mới thì token cũ bị thu hồi (rotation) | `INVALID_REFRESH_TOKEN` |

- **Quên mật khẩu:** luôn trả "Nếu email tồn tại, mã OTP đã được gửi" để người lạ không dò được email nào có tài khoản. Đặt lại thành công thì email coi như đã xác minh và mọi phiên đăng nhập cũ bị đăng xuất.
- **OTP ở bản demo:** chưa gửi SMS/email thật; mã được in ra log và trả kèm trong phản hồi khi bật chế độ dev.
- **Khoá tài khoản (Admin):** bắt buộc nhập lý do, thu hồi mọi refresh token nên người bị khoá bị đăng xuất, đăng nhập lại bị từ chối. Admin không tự khoá hay tự đổi quyền của mình (`SELF_LOCK`, `SELF_ROLE`). Mọi thao tác ghi vào nhật ký Admin.
- **Mở shop:** người dùng nào cũng mở được, cần tên shop (không trùng, `SHOP_NAME_TAKEN`), địa chỉ lấy hàng và tài khoản ngân hàng. Shop có cờ **uy tín** (trusted): tin của shop uy tín được duyệt tự động.

## Ví và tiền

Mỗi người có một ví hai ngăn: **khả dụng** (tiêu, rút được) và **đang giữ** (cọc đấu giá, tiền đang chờ rút, tiền bán hàng chưa hoàn tất). Sàn có một ví riêng để nhận phí. Mọi biến động ghi thành một dòng sổ cái chỉ thêm, không sửa, không xoá.

| Việc | Luật |
| --- | --- |
| Nạp tiền | Tối thiểu 10.000đ, qua ZaloPay, link sống 15 phút |
| Rút tiền | Tối thiểu 50.000đ; số tài khoản 6–19 chữ số; tiền chuyển sang "đang giữ" ngay khi gửi yêu cầu |
| Admin duyệt rút | Phải nhập biên lai: người chuyển, giờ chuyển (không ở tương lai), số tiền đúng bằng số yêu cầu, ảnh biên lai |
| Admin từ chối rút | Tiền đang giữ trả lại ngăn khả dụng |
| Thanh toán bằng ví | Thiếu tiền → `INSUFFICIENT_BALANCE` |

**Loại giao dịch trong sổ cái:** nạp, thanh toán, hoàn tiền, giữ cọc, trả cọc, mất cọc, tiền bán chờ, tiền bán giải ngân, phí, rút.

**ZaloPay (sandbox) chốt tiền thế nào:**

1. Backend tạo đơn ZaloPay, mã giao dịch dạng `yyMMdd_<mã thanh toán>`, ký bằng HMAC-SHA256 (key1).
2. App mở trang ZaloPay; người dùng trả bằng thẻ test.
3. Backend **không tin tham số trên URL quay về**: nó kiểm checksum (key2) rồi tự hỏi ZaloPay `/v2/query`. App cũng hỏi lại 3 giây một lần khi chờ.
4. Số tiền ZaloPay báo khác số tiền đơn → không ghi nhận. Mã giao dịch ZaloPay là duy nhất trong DB nên không cộng tiền hai lần.
5. Quá 15 phút chưa trả → thanh toán hết hạn, đơn liên quan bị huỷ.

## Mua bán giá cố định

Shop đăng tin, Admin duyệt, người mua đặt hàng; tiền người mua nằm ở ngăn "đang giữ" của shop và chỉ về ví shop (trừ 5%) khi đơn hoàn tất.

**Tin đăng**

- Cần 3–10 ảnh thật, giá tối thiểu 1.000đ, cân nặng ≥ 1g (để tính phí ship), ISBN 10 hoặc 13 ký tự (không bắt buộc), năm xuất bản 1500–2100.
- Shop uy tín: tin được duyệt ngay. Shop thường: tin chờ Admin duyệt; Admin từ chối phải ghi lý do. Admin thấy được ai duyệt và lúc nào.
- Shop ẩn/hiện tin và sửa tồn kho; tin hết hàng hoặc bị ẩn thì không mua được (`LISTING_NOT_AVAILABLE`).

**Giỏ và đặt hàng**

- Mỗi dòng giỏ 1–99 cuốn; không mua sách của chính shop mình (`OWN_LISTING`); không vượt tồn kho (`OUT_OF_STOCK`).
- Đặt hàng tách giỏ thành **mỗi shop một đơn**, phí ship riêng, nhưng trả chung một lần.
- **Giữ hàng ngay khi đặt** bằng câu lệnh trừ kho có điều kiện: hai người cùng mua cuốn cuối thì chỉ một người được, người kia nhận `OUT_OF_STOCK`.
- Trả bằng ví, ZaloPay hoặc COD. Chưa trả trong 15 phút thì đơn tự huỷ và trả lại kho.

**Phí ship** (shop tự giao nên shop nhận cả phí ship):

| Trường hợp | Phí |
| --- | --- |
| Cùng tỉnh, ≤ 1kg | 20.000đ |
| Khác tỉnh, ≤ 1kg | 30.000đ |
| Mỗi 500g vượt quá 1kg | +5.000đ |

Tên tỉnh được chuẩn hoá trước khi so ("TP. Hồ Chí Minh" = "Hồ Chí Minh").

&#91;embedded content: trạng thái đơn giá cố định · 10 trạng thái\]

Đơn chỉ đi tới theo mũi tên; mọi nhánh huỷ, giao thất bại và trả hàng đều hoàn tiền vào ví người mua và rút lại tiền chờ của shop.

**Huỷ đơn**

- Người mua huỷ thẳng khi đơn còn chờ xác nhận. Đơn đang đóng gói thì người mua chỉ gửi yêu cầu huỷ, shop đồng ý mới huỷ. Đơn đã giao cho vận chuyển thì không huỷ được.
- Shop không xác nhận trong 24 giờ → đơn tự huỷ, hoàn tiền.
- Hoá đơn lô đấu giá đã thắng thì không huỷ như đơn thường (`AUCTION_ORDER`).

**Trả hàng và khiếu nại**

- Chỉ trong 3 ngày sau khi giao; cần mô tả và 1–10 ảnh minh chứng.
- Shop có 2 ngày trả lời. Shop đồng ý → hoàn tiền. Shop từ chối hoặc im lặng quá hạn → Admin phân xử: hoàn tiền hoặc bác (đơn hoàn tất).
- Hết 3 ngày không khiếu nại → đơn tự hoàn tất, tiền về shop.

**Đánh giá:** chỉ đơn mua thường đã hoàn tất, mỗi đơn một lần, 1–5 sao.

## Ký gửi và kho

Chỉ sách có giá mong muốn từ 300.000đ mới được ký gửi; sách phải qua kho và kiểm định của sàn trước khi lên phiên, nên người mua đấu giá tin được tình trạng sách.

1. **Gửi yêu cầu** (SUBMITTED): thông tin sách, giá mong muốn ≥ 300.000đ (`PRICE_TOO_LOW`), nguồn gốc.
2. **Staff sơ duyệt online** (hạn 48 giờ): đạt → APPROVED; không đạt → REJECTED, bắt buộc ghi lý do (`REASON_REQUIRED`).
3. **Đặt lịch mang sách tới kho** (APPOINTMENT\_BOOKED): trong 7 ngày kể từ khi được duyệt, giờ 8:00–17:00 (`OUTSIDE_HOURS`, `APPOINTMENT_TOO_LATE`). Quá 7 ngày không mang tới → EXPIRED (job chạy 5 phút một lần). Lịch hẹn có mã QR để Staff quét.
4. **Nhận sách tại kho** (RECEIVED): Staff lập biên nhận, gán mã kệ, chụp ảnh lúc nhận.
5. **Kiểm định:** không đạt → INSPECTION\_FAILED, người bán có 14 ngày đến nhận lại. Đạt → AWAITING\_SELLER, kèm biên bản tình trạng và bốn mức giá phải thỏa **khởi điểm ≤ giá sàn ≤ ước tính thấp ≤ ước tính cao**.
6. **Người bán quyết định:** đồng ý hợp đồng ký gửi điện tử (`TERMS_REQUIRED`) → ACCEPTED và thành **một lô chờ xếp phiên**; có thể đề nghị giá sàn khác nhưng vẫn phải nằm giữa giá khởi điểm và ước tính thấp. Hoặc rút sách → WITHDRAWN.
7. Người bán có thể rút yêu cầu bất cứ lúc nào trước khi sách tới kho.

**Lô không bán được** (không ai trả, không tới giá sàn, lô bị huỷ hay phiên bị huỷ), người bán chọn một trong ba:

| Lựa chọn | Luật |
| --- | --- |
| Đưa vào phiên sau | Tối đa 2 phiên (`MAX_ROUNDS`); được hạ giá sàn nhưng không dưới giá khởi điểm. Phiên bị huỷ thì không tính lượt |
| Chuyển sang bán giá cố định | Cần có shop và nhập giá; tin mới chờ Admin duyệt, người bán nhận sách về rồi tự giao |
| Nhận lại sách | Xuất kho trả người bán |

**Phí lưu kho:** 14 ngày đầu miễn phí, sau đó 5.000đ/ngày, tính từ lúc báo người bán đến nhận và thu khi xuất kho trả sách. Hoa hồng 15% chỉ thu khi lô bán được.

## Đấu giá

Phiên chạy tự động bằng đồng hồ của server (quét mỗi giây): đóng đăng ký, kiểm đủ người, mở phiên đúng giờ, chạy lần lượt từng lô, chốt lô, ra hoá đơn và hoàn cọc. Giá và thời gian luôn do server quyết, app chỉ hiển thị.

&#91;embedded content: vòng đời phiên đấu giá · 8 trạng thái\]

Admin huỷ được phiên bất cứ lúc nào trước khi phiên chạy; phiên bị huỷ thì hoàn hết cọc và lô không bị tính lượt.

**Tạo và công bố phiên (Admin)**

- Chỉ sửa phiên và xếp lô khi phiên còn nháp (`SESSION_LOCKED`); phiên phải có ít nhất một lô, lô không trùng.
- Giờ bắt đầu và hạn đăng ký phải ở tương lai, hạn đăng ký trước giờ bắt đầu.
- Thông số mỗi phiên: số người tối thiểu ≥ 1, tiền cọc, thời gian mỗi lô 10–600 giây, soft close 5–120 giây, nghỉ giữa lô 0–60 giây.

**Đăng ký tham gia**

- Phải đã xác thực số điện thoại, không đang bị cấm đấu giá, đồng ý quy chế (`RULES_REQUIRED`), đăng ký trước hạn (`REGISTRATION_CLOSED`), mỗi người một lần (`ALREADY_REGISTERED`).
- Tiền cọc bị khoá trong ví (chuyển sang "đang giữ"). Người tham gia nhận **số bài ẩn danh**; bảng kết quả chỉ hiện số bài, không hiện tên.
- **Hạn mức trả giá = cọc × 10** (ví dụ cọc 500.000đ → giữ giá tổng cộng tối đa 5.000.000đ). Cọc thêm (tối thiểu 10.000đ) để nâng hạn mức, kể cả khi phiên đang chạy.

**Trả giá trong phiên**

| Khoảng giá hiện tại | Bước giá tối thiểu |
| --- | --- |
| Dưới 200.000đ | +10.000đ |
| 200.000đ – dưới 1.000.000đ | +50.000đ |
| 1.000.000đ – dưới 5.000.000đ | +100.000đ |
| Từ 5.000.000đ | +500.000đ |

- Giá mới ≥ giá hiện tại + bước giá; không tự đẩy giá khi đang dẫn (`ALREADY_LEADING`); tổng giá đang dẫn + lượt này không vượt hạn mức (`BID_LIMIT_EXCEEDED`).
- **Hai người bấm cùng một mức:** ai tới server trước thắng (khoá lạc quan theo version), người sau nhận `PRICE_CHANGED`.
- **Soft close 15 giây** (mặc định): có người trả giá trong những giây cuối thì đồng hồ lô được nối thêm, chống "bắn tỉa" giây chót.
- **Giá tối đa (proxy):** đặt trước khi lô mở (trả giá vắng mặt) hoặc trong lúc mở; hệ thống trả hộ từng bước. Hai proxy đấu nhau thì nhảy thẳng tới giá tối đa của bên thua + 1 bước; bằng nhau thì người đặt trước giữ giá. Proxy không vượt hạn mức còn lại.
- Giá sàn không được tiết lộ cho người trả giá.
- Staff tạm dừng khi có sự cố; tiếp tục thì lô được trả lại ít nhất thời gian soft close. Staff huỷ được một lô (bắt buộc ghi lý do), mọi lượt trả giá của lô bị huỷ bỏ.

**Sau khi lô chốt**

- Giá cao nhất ≥ giá sàn → bán được. Người không thắng lô nào được mở khoá cọc ngay khi phiên kết thúc.
- **Hoá đơn người thắng = giá gõ búa + 10% phí người mua + phí giao (0đ nếu nhận tại kho) − tiền cọc**, trả trong 48 giờ. Đổi cách nhận được khi chưa trả.
- Ví dụ: gõ búa 2.000.000đ, cọc 500.000đ, giao khác tỉnh 30.000đ → hoá đơn 2.000.000 + 200.000 + 30.000 − 500.000 = **1.730.000đ**. Người bán nhận 2.000.000 − 15% = **1.700.000đ** khi đơn hoàn tất.
- Trả hàng hoặc giao thất bại với đơn đấu giá: sàn chịu trách nhiệm (sàn đã kiểm định), không đẩy cho người bán.

**Bỏ thanh toán (quá 48 giờ)**

1. Người thắng **mất cọc** và **bị cấm đấu giá 90 ngày**. Trên `main`, tiền cọc chia 50% bù cho người bán, 50% về sàn.
2. Người trả giá cao thứ hai được **mời mua lần hai** đúng mức giá họ đã trả, hạn 24 giờ, chỉ khi mức đó ≥ giá sàn. Từ chối hoặc quá hạn thì không bị phạt.
3. Không có ai đủ điều kiện → lô quay lại chờ xếp phiên sau, người bán được báo.

## Quản trị và cấu hình

Mọi con số nghiệp vụ nằm trong bảng `system_configs`, Admin sửa ở màn Cấu hình mà không cần sửa code; mỗi lần sửa ghi vào nhật ký Admin.

| Khoá cấu hình | Mặc định trên `main` | Ý nghĩa |
| --- | --- | --- |
| `fee.fixed_price_percent` | 5 | Phí sàn đơn giá cố định (%) |
| `fee.buyer_premium_percent` | 10 | Phí người mua đấu giá (%) |
| `fee.seller_commission_percent` | 15 | Hoa hồng người bán ký gửi (%) |
| `fee.storage_free_days` / `fee.storage_per_day` | 14 / 5.000 | Lưu kho miễn phí (ngày) / phí mỗi ngày sau đó (đ) |
| `order.payment_timeout_minutes` | 15 | Hạn thanh toán đơn |
| `order.confirm_timeout_hours` | 24 | Hạn shop xác nhận |
| `order.auto_complete_days` | 3 | Hạn khiếu nại, hết thì tự hoàn tất |
| `order.return_response_days` | 2 | Hạn shop trả lời yêu cầu trả hàng |
| `shipping.same_province` / `other_province` | 20.000 / 30.000 | Phí ship ≤ 1kg (+5.000đ mỗi 500g thêm) |
| `shipping.warehouse_province` | TP. Hồ Chí Minh | Tỉnh của kho, dùng tính phí giao lô đấu giá |
| `consignment.min_expected_price` | 300.000 | Giá mong muốn tối thiểu để ký gửi |
| `consignment.appointment_days` | 7 | Hạn mang sách tới kho |
| `consignment.max_rounds` | 2 | Số phiên tối đa một lô được lên |
| `auction.bid_increment_tiers` | 0:10k, 200k:50k, 1M:100k, 5M:500k | Bậc bước giá |
| `auction.bid_limit_multiplier` | 10 | Hạn mức = cọc × hệ số |
| `auction.payment_hours` | 48 | Hạn trả hoá đơn lô thắng |
| `auction.second_chance_hours` | 24 | Hạn lời mời mua lần hai |
| `auction.ban_days` | 90 | Số ngày cấm khi bỏ thanh toán |
| `auction.forfeit_seller_percent` | 50 | Phần cọc bị thu chia cho người bán (%) |
| `auction.postpone_days` | 7 | Dời phiên bao nhiêu ngày khi thiếu người |
| `listing.auto_approve_trusted` | true | Duyệt tự động tin của shop uy tín |

**Việc của Admin**

- Duyệt / từ chối tin đăng (từ chối phải ghi lý do).
- Khoá / mở khoá người dùng, đổi quyền (không làm với chính mình).
- Danh mục sách: tên và slug không trùng, không chọn danh mục con làm cha, xoá danh mục con trước rồi mới xoá cha (`HAS_CHILDREN`).
- Tạo, xếp lô, công bố, huỷ phiên đấu giá.
- Duyệt rút tiền kèm biên lai chuyển khoản, hoặc từ chối (hoàn tiền vào ví).
- Phân xử khiếu nại trả hàng: hoàn tiền cho người mua hoặc bác.
- Xem dashboard, nhật ký thao tác (duyệt tin, khoá người dùng, đổi cấu hình, xử lý rút tiền…), ví sàn.

## Thời hạn và job tự động

Không hạn nào cần người bấm: bốn job nền của backend tự xử lý khi quá hạn, mỗi đơn / phiên xử lý trong transaction riêng nên một cái lỗi không kéo cái khác.

| Hạn | Quá hạn thì | Job (chu kỳ) |
| --- | --- | --- |
| Thanh toán đơn / nạp tiền 15 phút | Thanh toán hết hạn, đơn huỷ, trả lại kho | Đơn hàng (1 phút) |
| Shop xác nhận 24 giờ | Đơn huỷ, hoàn tiền người mua | Đơn hàng (1 phút) |
| Khiếu nại 3 ngày sau khi giao | Đơn tự hoàn tất, tiền về shop (trừ 5%) | Đơn hàng (1 phút) |
| Shop trả lời trả hàng 2 ngày | Chuyển Admin phân xử | Đơn hàng (1 phút) |
| Mang sách ký gửi tới kho 7 ngày | Yêu cầu EXPIRED | Ký gửi (5 phút) |
| Hạn đăng ký phiên | Đủ người → CONFIRMED; thiếu lần 1 → dời 7 ngày; thiếu lần 2 → huỷ, hoàn cọc | Bộ máy đấu giá (1 giây) |
| Giờ mở phiên, giờ đóng từng lô | Mở phiên, chốt lô, mở lô kế, đóng phiên; nhắc người đăng ký 15 phút trước | Bộ máy đấu giá (1 giây) |
| Trả hoá đơn lô thắng 48 giờ | Mất cọc, cấm 90 ngày, mời người thứ hai | Hoá đơn đấu giá (1 phút) |
| Lời mời mua lần hai 24 giờ | Huỷ lời mời, lô về chờ xếp phiên, không phạt | Hoá đơn đấu giá (1 phút) |

Bộ máy đấu giá chỉ chạy trên một instance backend (đủ cho đồ án); mỗi bước khoá dòng phiên (`FOR UPDATE`) nên job và thao tác của Staff không giẫm lên nhau.

## Nhánh improve\_bussinessrule (chưa vào main)

Nhánh này thêm migration V9–V16 và khoảng 3.400 dòng backend để vá lỗ hổng tiền và đấu giá mà nhóm BA/tester tìm ra; giao diện chưa theo kịp nên **đừng demo các luật dưới đây trên app**, chỉ nói như hướng phát triển đã code xong ở backend. Chi tiết: `docs/ra-soat-nghiep-vu/NGHIEP_VU.md` trên nhánh đó.

| Mảng | Trên `main` | Trên nhánh improve |
| --- | --- | --- |
| Ai được đấu giá | Mọi tài khoản đã xác thực SĐT | Staff và Admin bị cấm (`STAFF_CANNOT_BID`) |
| Chặn đoán mật khẩu | 10 lần / 15 phút theo email | Thêm giới hạn theo IP (30) và theo email qua nhiều IP (100) |
| Khoá tài khoản | Thu hồi refresh token | Mất token ngay request kế; ẩn tin; huỷ đơn chưa giao và hoàn tiền; huỷ hoá đơn đấu giá không phạt, mời người kế |
| Rút tiền | Tối thiểu 50.000đ | Thêm: tiền nạp khoá 24 giờ (`TOPUP_LOCKED`), tối đa 20.000.000đ/ngày, đang nợ thì không rút (`DEBT_OPEN`) |
| Đặt hàng | Giá lấy tại thời điểm đặt | App gửi `expectedTotal`, giá đổi thì báo `PRICE_CHANGED` |
| Phí sàn 5% | Thu khi đơn hoàn tất | Thu ngay khi đặt |
| Hạn giao hàng | Không có | Shop gửi trong 3 ngày; người mua không bấm thì coi như đã nhận sau 7 ngày |
| COD | Không giới hạn | Tối đa 3.000.000đ/đơn (500.000đ với người chưa có đơn hoàn tất); khoá COD sau 2 lần lỗi trong 90 ngày; Staff đối soát, Admin xác nhận mới trả shop |
| Trả hàng | Shop đồng ý là hoàn tiền | Người mua gửi lại kèm mã vận đơn trong 7 ngày, shop xác nhận nhận trong 7 ngày rồi mới hoàn; lý do `NOT_RECEIVED` hoàn ngay, không cần ảnh |
| Huỷ đơn đang đóng gói | Chờ shop | Shop im lặng 24 giờ thì tự duyệt |
| Uy tín shop | Admin đặt tay | Tự mất uy tín khi tỉ lệ lỗi ≥ 10% với ≥ 5 đơn trong 90 ngày |
| Công bố phiên | Chỉ cần giờ ở tương lai | Công bố trước giờ mở ≥ 72 giờ, đóng đăng ký trước ≥ 24 giờ; phí, bước giá, hệ số hạn mức bị "đóng băng" lúc công bố |
| Lô giá trị cao | Như lô thường | Ước tính thấp ≥ 10 triệu: cọc thêm 10% ước tính thấp (`LOT_DEPOSIT_REQUIRED`) |
| Phạt bỏ thanh toán | Mất cọc, 50% cho người bán; cấm 90 ngày | Phạt mỗi lô = max(cọc, 10% giá gõ búa), 100% về sàn; cấm tăng dần 90 ngày → 365 ngày → vĩnh viễn; người từ chối nhận hàng cũng bị phạt |
| Mời mua lần hai | Giá của người về nhì, phải ≥ giá sàn | Giá công bằng = max(giá sàn, min(giá người về nhì, giá người kế + 1 bước)) |
| Proxy không ai tranh | Dừng ở giá khởi điểm | Được nâng lên giá sàn nếu giá tối đa đủ |
| Ký gửi | Không có hạn trả lời giá | Người bán có 7 ngày trả lời giá đề xuất; lô ế im lặng 7 ngày thì tự trả sách; nhắc ở ngày 53, thanh lý ở ngày 60, thiếu tiền ghi thành nợ |
| Mất sách trong kho | Không có luật | Bồi thường tối đa 2.000.000đ trước kiểm định, bằng ước tính thấp sau kiểm định; đã bán thì hoàn người mua + 10% giá gõ búa |
| Tiền |  | Chỉ nhận số đồng nguyên, tối đa 15 chữ số; đối soát sổ cái mỗi đêm |

**Lưu ý khi gộp:** nhánh `ui-sync-business-rules` cũng có file `V14__unaccent_search.sql`, trùng số V14 với nhánh này; khi gộp cần đổi file đó thành V17.

## Câu hỏi hay gặp khi thuyết trình

**Hỏi: Làm sao tránh hai người cùng mua được cuốn sách cuối cùng?** Trừ kho bằng một câu `UPDATE … WHERE stock >= số lượng`. Database chỉ cho một câu thành công; câu còn lại ảnh hưởng 0 dòng và người đó nhận `OUT_OF_STOCK`.

**Hỏi: Hai người trả cùng một giá cùng lúc thì sao?** Lô có cột `version`. Lượt trả giá chỉ ghi được nếu version chưa đổi, nên ai tới server trước thắng; người sau nhận `PRICE_CHANGED` và thấy giá mới.

**Hỏi: Sao không trả tiền thẳng cho người bán?** Escrow bảo vệ người mua: tiền nằm ở ngăn "đang giữ" tới khi hết 3 ngày khiếu nại. Có tranh chấp thì sàn hoàn được ngay mà không phải đòi lại từ người bán.

**Hỏi: Nếu người dùng sửa URL trả về từ ZaloPay thành "thành công" thì sao?** Backend không tin URL: nó kiểm chữ ký HMAC rồi tự gọi `/v2/query` của ZaloPay, đối chiếu cả số tiền. Mã giao dịch ZaloPay là duy nhất trong DB nên callback gọi lại nhiều lần cũng không cộng tiền hai lần.

**Hỏi: Người thắng đấu giá bỏ không trả thì ai chịu?** Họ mất cọc và bị cấm 90 ngày; tiền cọc chia đôi người bán và sàn. Người về nhì được mời mua trong 24 giờ nếu giá của họ ≥ giá sàn.

**Hỏi: Sao hạn mức trả giá lại là cọc × 10?** Cọc là cam kết: nếu bỏ thanh toán thì mất cọc. Giới hạn tổng giá đang giữ ở 10 lần cọc giúp khoản mất cọc vẫn đủ răn đe; muốn trả cao hơn thì cọc thêm. Hệ số này Admin chỉnh được.

**Hỏi: Soft close để làm gì?** Chống trả giá ở giây cuối (sniping). Ai trả giá khi lô sắp hết giờ thì lô được nối thêm 15 giây để người khác kịp trả lại.

**Hỏi: Sao đấu giá phải ký gửi vào kho, không cho shop tự đăng?** Sách đấu giá thường hiếm và đắt. Người trả giá không xem tận tay được, nên sàn giữ sách, kiểm định và định giá để họ tin. Vì vậy khi giao hỏng hay trả hàng, sàn chịu trách nhiệm.

**Hỏi: Thay phí hay thời hạn có phải sửa code không?** Không. Mọi con số nằm trong bảng `system_configs`, Admin đổi ở màn Cấu hình và lần đổi đó được ghi nhật ký.

**Hỏi: Chưa làm được gì?** Gửi OTP qua SMS/email thật, xác minh CCCD, thông báo đẩy thật, nối hãng vận chuyển thật, hoàn tiền một phần. ZaloPay đang chạy sandbox. Các luật ở mục nhánh improve đã code ở backend nhưng chưa lên giao diện.
