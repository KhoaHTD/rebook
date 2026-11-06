# ReBook: luồng và nghiệp vụ, cũ và hiện tại

Cập nhật 2026-11-06. File này mô tả **hệ thống đang chạy thế nào** (luồng từng bước) và **luật nào đã đổi**.

- **Cũ** = code backend trước đợt rà soát (trước 2026-11-05).
- **Hiện tại** = nhánh `improve_bussinessrule` sau ngày 2026-11-06.
- Con số là giá trị mặc định trong bảng `system_configs`; Admin sửa được, có mức tối thiểu để không phá luật (mục 7).
- Mã trong ngoặc (BE-xx, BR-x.y, mục n) tra ở [THAY_DOI_SO_VOI_CODE_CU.md](THAY_DOI_SO_VOI_CODE_CU.md) và [DANH_GIA_BA_TESTER.md](DANH_GIA_BA_TESTER.md).

## Mục lục

1. [Vai trò và tài khoản](#1-vai-trò-và-tài-khoản)
2. [Ví và tiền](#2-ví-và-tiền)
3. [Sách, tin đăng, mua bán giá cố định](#3-sách-tin-đăng-mua-bán-giá-cố-định)
4. [Ký gửi và kho](#4-ký-gửi-và-kho)
5. [Đấu giá](#5-đấu-giá)
6. [Thời hạn và job tự động](#6-thời-hạn-và-job-tự-động)
7. [Cấu hình hiện hành](#7-cấu-hình-hiện-hành)
8. [Chưa có trong hệ thống](#8-chưa-có-trong-hệ-thống)

---

## 1. Vai trò và tài khoản

| Vai trò | Làm gì |
|---|---|
| Khách | Xem tin, xem phiên đấu giá, xem kết quả |
| Người dùng (USER) | Mua, bán (bật shop), ký gửi, đấu giá, ví |
| Staff | Kho: nhận sách, kiểm định, giao lô đấu giá, đối chiếu hãng vận chuyển, tạm dừng phiên, huỷ lô |
| Admin | Duyệt tin, duyệt rút tiền, phân xử khiếu nại, lập phiên, cấu hình, khoá tài khoản |

| Luật | Cũ | Hiện tại |
|---|---|---|
| Điều kiện để mua / ký gửi | Xác thực email | Giữ nguyên |
| Điều kiện để đấu giá | Xác thực SĐT (OTP chỉ ghi log) | Giữ nguyên. Thêm: **Staff / Admin không được đăng ký hay trả giá** (`STAFF_CANNOT_BID`, BR-5.0) |
| Mã OTP | Chỉ ghi ra log máy chủ | **Gửi qua email** (SMTP, bật bằng `MAIL_ENABLED`). Xin mã cách nhau ≥ 60 giây, tối đa 5 mã / giờ, 10 mã / ngày (`TOO_MANY_REQUESTS`). Mail lỗi khi xin mã: `EMAIL_SEND_FAILED`. Mã xác thực SĐT tạm gửi qua email vì chưa có SMS |
| Đăng ký bằng biến thể email | `a.b+1@gmail.com` và `ab@gmail.com` là hai tài khoản | Chặn (`EMAIL_TAKEN`): so theo dạng chuẩn (chữ thường, bỏ phần `+...`, Gmail bỏ dấu chấm) |
| Đăng nhập sai | Không giới hạn | Đếm sai theo **email + IP (10 lần)**, **IP (30)**, **email trên mọi IP (100)** trong 15 phút; một IP sai nhiều không khoá được chủ tài khoản ở IP khác (BE-42) |
| Bị khoá khi đang đăng nhập | Chỉ đổi trạng thái | Token cũ hết tác dụng ở request kế tiếp; tin bị ẩn, đơn chưa giao bị huỷ và hoàn tiền |
| Bị khoá khi đang có việc đấu giá | Hoá đơn đấu giá vẫn chạy 48 giờ rồi phạt người bị khoá | **Huỷ hoá đơn chưa trả, không phạt, hoàn cọc, mời người kế tiếp**; huỷ giá tối đa; rút lô của người bán khỏi phiên chưa chạy (mục 10) |

## 2. Ví và tiền

### Mô hình

Mỗi người có một ví với hai túi: **khả dụng** (dùng được) và **đang giữ** (cọc, tiền bán chờ hoàn tất, tiền chờ rút). Sàn có một ví riêng. Mọi thay đổi đi qua một hàm: khoá dòng ví, không cho âm, ghi một dòng sổ cái không sửa được, ghi sự kiện nhật ký. Đêm nào cũng đối soát số dư với sổ cái.

```
Nạp:     cổng ZaloPay ──▶ khả dụng (+)                         [tiền vào hệ thống]
Mua:     khả dụng người mua (−) ──▶ đang giữ người bán (+)      [giữ trung gian]
Xong:    đang giữ người bán ──▶ khả dụng người bán − phí ──▶ ví sàn (+ phí)
Rút:     khả dụng ──▶ đang giữ (chờ Admin) ──▶ ra ngân hàng     [tiền ra khỏi hệ thống]
Cọc:     khả dụng ──▶ đang giữ ──▶ hoàn / trừ vào hoá đơn / mất về sàn
Nợ:      phạt hoặc phí kho chưa thu đủ ──▶ khoản nợ, thu dần từ khả dụng
```

### Luồng rút tiền

1. Người dùng gửi yêu cầu (tối thiểu 50.000đ, số tài khoản 6–19 chữ số). Tiền chuyển sang túi đang giữ.
2. Admin chuyển khoản tay rồi duyệt, **bắt buộc** nhập người chuyển, giờ chuyển, số tiền bằng đúng số yêu cầu, ảnh biên lai. Từ chối thì tiền trả về túi khả dụng.

| Luật | Cũ | Hiện tại |
|---|---|---|
| Rút tiền vừa nạp | Rút ngay được | Tiền nạp chưa tiêu bị khoá **24 giờ** (`TOPUP_LOCKED`) |
| Rút tiền bán hàng | Rút ngay được | Shop uy tín và shop lâu năm rút ngay. **Shop mới** (mở dưới 30 ngày hoặc dưới 10 đơn hoàn tất, chưa được gắn uy tín): tiền bán giữ **7 ngày** kể từ lúc giải ngân (`SALE_HELD`), chặn nạp thẻ trộm, mua của shop phụ rồi rút ngay |
| Ngân hàng đòi lại tiền nạp | Không có cách xử lý | Admin ghi nợ `CHARGEBACK` (`POST /admin/debts/chargeback`): thu ngay phần ví đang có, phần còn lại là nợ (chặn rút, đấu giá) |
| Hạn mức rút | Không có | **20.000.000đ / ngày** |
| Còn nợ | Không có khái niệm nợ | Không rút, không đăng ký phiên, không trả giá được (`DEBT_OPEN`) |
| Rút song song | Có thể vượt số dư | Khoá ví, không vượt |
| Thu nợ song song | — | Khoá ví trước rồi mới đọc nợ, không trừ hai lần (BE-47) |
| Số tiền nhập | Nhận số lẻ, số quá lớn | Chỉ số nguyên đồng, tối đa 15 chữ số |

## 3. Sách, tin đăng, mua bán giá cố định

### Thông tin một cuốn sách

Một cuốn sách (bảng `books`) tách khỏi tin bán (`listings`) và lô đấu giá (`lots`): sách ký gửi không bán được ở đấu giá chuyển sang bán thường mà không phải nhập lại. Cùng một form dùng cho đăng bán và gửi ký gửi.

| Trường | Bắt buộc | Kiểm tra |
|---|---|---|
| Tên sách | Có | ≤ 300 ký tự |
| Tác giả | Có | ≤ 200 ký tự |
| Danh mục | Có | Phải tồn tại; danh mục dạng cây |
| Tình trạng | Có | Một trong 5 bậc dưới đây |
| Cân nặng | Có | ≥ 1 gam, dùng để tính phí ship |
| Ảnh thật | Có | **3–10 ảnh** của người bán |
| NXB | Không | ≤ 200 ký tự |
| Năm xuất bản | Không | 1500–2100 |
| ISBN | Không | Xem mục ISBN bên dưới |
| Ngôn ngữ, số trang | Không | Ngôn ngữ ≤ 50 ký tự; số trang ≥ 1 |
| Mô tả | Không | ≤ 5.000 ký tự |

**Thang tình trạng** (SRS 4.1, bắt buộc để người mua so sánh được):

| Mã | Tên | Nghĩa |
|---|---|---|
| `NEW` | Mới | Chưa đọc, còn nguyên |
| `LIKE_NEW` | Như mới | Đã đọc, không dấu vết |
| `VERY_GOOD` | Tốt | Dấu hiệu dùng nhẹ, không ghi chú |
| `GOOD` | Khá | Có ghi chú / gấp góc / ố vàng nhẹ, đủ trang |
| `ACCEPTABLE` | Trung bình | Hư hại rõ, vẫn đọc được |

**Ảnh:** có hai nguồn, ảnh người bán và ảnh Staff chụp lúc nhận sách / kiểm định. Ảnh bìa ưu tiên ảnh của Staff. Kiểm định đạt thì tình trạng sách đổi theo kết luận của Staff.

**Danh mục:** dạng cây, Admin thêm / sửa / xoá. Xoá danh mục còn danh mục con thì báo `HAS_CHILDREN`; còn sách thì 409. Lọc theo một danh mục là lọc cả danh mục con.

### ISBN và năm xuất bản (BR-2.1 đến BR-2.5)

| Luật | Chi tiết |
|---|---|
| Không bắt buộc | Sách trước 1970 và nhiều sách cũ không có ISBN |
| Nhập vào | Chỉ chữ số, `X`, dấu gạch và khoảng trắng, tối đa 20 ký tự. Bỏ gạch / khoảng trắng; nhận **ISBN-10** (ký tự cuối được là `X`) hoặc **ISBN-13** đầu 978 / 979 |
| Kiểm số kiểm tra | ISBN-10: tổng có trọng số chia hết cho 11. ISBN-13: trọng số 1-3 chia hết cho 10. Sai thì `INVALID_ISBN` |
| Lưu | Luôn lưu **ISBN-13**: ISBN-10 thêm 978 rồi tính lại số kiểm tra. Trang chi tiết hiện bản 13 số (không giữ bản người bán gõ) |
| Tìm kiếm | Ô tìm kiếm khớp tên, tác giả, một phần ISBN; gõ ISBN-10 hoặc ISBN có gạch vẫn ra đúng sách |
| Dữ liệu cũ | ISBN đã lưu mà người bán giữ nguyên khi sửa tin thì không kiểm lại (dữ liệu mẫu có ISBN sai số kiểm tra) |

| Năm xuất bản | Có ISBN | Không ISBN |
|---|---|---|
| **Trước 1970** (thời chưa có ISBN) | Nhận, gắn cờ `isbnWarning` cho người duyệt tin / Staff xem kỹ (có thể là bản in lại). **Không chặn** | Bình thường |
| **Từ 1970** | Bình thường | Bình thường, không cảnh báo |
| Không ghi năm | Bình thường | Bình thường |

Cờ `isbnWarning` có trong dữ liệu trả về nhưng **frontend chưa hiển thị** (mục 8).

### Luồng tin đăng

```
Đăng tin ─▶ PENDING_REVIEW ──Admin duyệt──▶ ACTIVE ⇄ OUT_OF_STOCK   (tồn kho về 0 / có lại)
  (shop uy tín: bỏ qua, vào thẳng ACTIVE)  │            │
            └──từ chối (lý do)─▶ REJECTED  └──ẩn──▶ HIDDEN ──hiện lại──▶ ACTIVE / OUT_OF_STOCK
                                   └─sửa─▶ PENDING_REVIEW
```

1. **Mở shop** trước khi đăng (tên, địa chỉ lấy hàng, tỉnh, tài khoản ngân hàng nhận tiền).
2. **Đăng tin**: thông tin sách + giá (≥ 1.000đ, số nguyên đồng) + tồn kho (≥ 0).
3. **Duyệt**: shop thường vào Chờ duyệt, Admin duyệt hoặc từ chối (bắt buộc lý do; app gợi ý "Ảnh không đạt", "Sai thông tin sách", "Nội dung bị cấm"). Shop uy tín được tự duyệt khi `listing.auto_approve_trusted` bật.
4. **Sửa tin**: đổi ISBN, NXB, năm, tên, tác giả, tình trạng, mô tả hoặc ảnh thì tin quay lại Chờ duyệt (trừ shop uy tín). Đổi **giá, tồn kho** thì không phải duyệt lại. Tin bị từ chối sửa xong luôn quay lại Chờ duyệt.
5. **Ẩn / hiện**: chỉ ẩn được tin đã duyệt; hiện lại không phải duyệt.
6. **Tìm kiếm**: chỉ tin **Đang bán** hiện trong kết quả. Lọc theo từ khoá, danh mục (cả con), tác giả, tình trạng, khoảng giá, shop. Sắp xếp: mới nhất, giá tăng, giá giảm, bán chạy. Tin Hết hàng vẫn mở được trang chi tiết và vẫn nằm trong "Sách yêu thích"; tin chưa duyệt / bị ẩn chỉ chủ shop xem được.
7. **Không tự mua sách của shop mình** (`OWN_LISTING`).
8. **Tin chuyển từ lô đấu giá không bán**: Admin chỉ duyệt được khi người bán đã nhận lại sách khỏi kho (`BOOK_IN_WAREHOUSE`).

| Luật | Cũ | Hiện tại |
|---|---|---|
| ISBN | Chỉ kiểm độ dài 10 / 13 | Kiểm số kiểm tra, lưu ISBN-13, tìm kiếm nhận mọi dạng |
| Sửa thông tin ấn bản | Chỉ một số trường bắt duyệt lại | ISBN / NXB / năm / tên / tác giả / tình trạng / mô tả / ảnh đều bắt duyệt lại |
| Duyệt tin của lô không bán | Duyệt ngay dù sách còn trong kho | Chờ người bán nhận lại sách |

### Luồng trạng thái đơn

```
                 ┌──────────── huỷ (người mua, shop, hệ thống, quá hạn) ─────────────┐
PENDING_PAYMENT ─┴▶ PENDING_CONFIRM ─▶ PREPARING ─▶ SHIPPING ─▶ DELIVERED ─▶ COMPLETED
  (trả ví/ZaloPay)    (shop xác nhận)  (đóng gói)   │            │
  COD vào thẳng ──────▲                             │            └▶ RETURN_REQUESTED ─▶ RETURNED
                                                    └▶ FAILED_DELIVERY               └▶ COMPLETED (từ chối / hết hạn)
```

### Từng bước

1. **Giỏ và xem trước**: giỏ nhiều shop, mỗi shop thành một đơn, phí ship riêng (nội tỉnh 20.000đ, liên tỉnh 30.000đ cho ≤ 1kg, +5.000đ mỗi 500g).
2. **Đặt hàng**: giữ hàng ngay (`stock >= qty`, hết hàng thì `OUT_OF_STOCK`). Chọn ví (trừ ngay), ZaloPay (15 phút) hoặc COD.
3. **Shop xác nhận** trong 24 giờ → **giao cho vận chuyển** trong 3 ngày.
4. **Giao**: người mua bấm "đã nhận"; không bấm thì đơn trả trước tự coi là đã giao sau 7 ngày (đơn COD chờ Staff đối chiếu hãng).
5. **Khiếu nại** trong 3 ngày sau khi giao; hết hạn thì tự hoàn tất, shop nhận tiền trừ phí sàn 5%.
6. **Đánh giá**: chỉ đơn mua thường đã hoàn tất, mỗi đơn một lần, 1–5 sao kèm nhận xét ≤ 1.000 ký tự. Điểm shop là trung bình mọi đánh giá; tên người đánh giá hiện rút gọn ("Minh N.").

### Giao hàng và nhận hàng (đơn thường)

Chưa nối hãng vận chuyển thật. Ai bấm gì ở từng bước:

| Bước | Ai làm | Trên app | Ghi chú |
|---|---|---|---|
| Xác nhận đơn | Shop | "Xác nhận đặt hàng" (đơn Chờ xác nhận) | Hạn 24 giờ; xác nhận xong có hạn giao 3 ngày |
| Giao cho vận chuyển | Shop | "Giao cho shipper", ô "Mã vận đơn (không bắt buộc)" | Bỏ trống thì hệ thống tự sinh mã `RB` + 10 số. Đơn đang có yêu cầu huỷ thì phải xử lý yêu cầu trước (`CANCEL_REQUESTED`) |
| Hãng báo đã giao | Shop (chỉ môi trường dev) | "Giả lập: đã giao thành công" / "Giao thất bại" | Ngoài dev hai nút trả 403. Đường thật: Staff đối chiếu hãng (`/staff/orders/in-transit`, `carrier-delivered`, `carrier-failed`, ghi ai gây lỗi) |
| Người mua nhận | Người mua | "Đã nhận hàng" | Backend nhận cả khi đơn còn Đang giao; app hiện nút khi đơn đã Giao (mục 8). Không bấm thì đơn trả trước tự coi là đã giao sau 7 ngày, rồi tự hoàn tất sau 3 ngày khiếu nại |
| Trả hàng | Người mua | "Yêu cầu trả hàng" (lý do + 1–10 ảnh; "Không nhận được hàng" không cần ảnh) | Chỉ trong 3 ngày sau khi giao. Lý do: sai tình trạng, thiếu trang, sai ấn bản, khác mô tả khác, không nhận được hàng. Không nhận trả vì đổi ý |
| COD về tay shop | Admin | Chưa có màn | Admin xác nhận đã nhận tiền thu hộ (`POST /admin/cod/{orderId}/remit`) thì shop mới được trả |

### Luật đơn hàng: cũ và hiện tại

| Luật | Cũ | Hiện tại |
|---|---|---|
| Giá đổi lúc người mua bấm đặt | Tính theo giá mới, người mua không biết | App gửi kèm tổng đã thấy (`expectedTotal`); lệch thì `PRICE_CHANGED`, không giữ hàng, không trừ tiền (mục 7, BR-2.13) |
| Bấm đặt hai lần | Có thể ra hai bộ đơn | Khoá ví, chỉ một bộ |
| COD | Hoàn tất là cộng tiền cho shop dù sàn chưa nhận | Hãng thu hộ: Staff đối chiếu, Admin xác nhận đã nhận đúng số tiền, **rồi mới trả shop**. Hạn mức 3.000.000đ/đơn, 500.000đ với người chưa có đơn hoàn tất; ≥ 2 lần giao thất bại **do người mua** trong 90 ngày thì chặn COD |
| Shop bấm "đã giao" | Shop tự bấm, 3 ngày sau tự hoàn tất | Nút giả lập chỉ có ở môi trường dev; người mua xác nhận, hoặc tự coi là đã giao sau 7 ngày |
| Shop ngâm đơn | Không có hạn | Không xác nhận 24 giờ / không giao 3 ngày: tự huỷ, hoàn tiền, **tính lỗi shop** |
| Người mua xin huỷ đơn đã xác nhận | Không có hạn | Shop im lặng 24 giờ thì tự đồng ý |
| Giao thất bại | Hoàn đủ, không phân biệt lỗi ai | Staff ghi **ai gây lỗi** (mục 8, BR-3.5–3.7): **người mua** thì hoàn tiền sách, phí giao chiều đi về shop; **hãng** thì hoàn đủ; **shop** thì hoàn đủ và tính lỗi shop |
| Trả hàng sai mô tả | Shop đồng ý là hoàn tiền + cộng lại tồn kho ngay | Theo bước: shop đồng ý → người mua gửi trả (mã vận đơn, 7 ngày) → shop xác nhận đã nhận (7 ngày) → hoàn tiền. Không tự cộng tồn kho. Shop không trả lời 2 ngày, hoặc không xác nhận hàng về, thì chuyển Admin |
| **Không nhận được hàng** | Không có lý do này; Admin hoàn tiền thì bắt người mua gửi trả sách họ không có | Lý do `NOT_RECEIVED`: **không cần ảnh**, shop đồng ý hoặc Admin phân xử là **hoàn tiền ngay** (BE-44). Chỉ cho đơn thường |
| Phí sàn | Đọc cấu hình lúc hoàn tất | Chụp tỷ lệ lúc đặt hàng |
| Uy tín shop | Admin bật tay, không bao giờ tự gỡ | Tỷ lệ đơn lỗi ≥ 10% (tối thiểu 5 đơn trong 90 ngày) thì tự gỡ |

## 4. Ký gửi và kho

### Luồng

```
SUBMITTED ─▶ APPROVED ─▶ APPOINTMENT_BOOKED ─▶ RECEIVED ─▶ AWAITING_SELLER ─▶ ACCEPTED ─▶ (thành lô đấu giá)
 (gửi yêu cầu) (sơ duyệt)  (hẹn mang sách)      (kho nhận)  (kiểm định đạt)    (người bán đồng ý)
     └▶ REJECTED            └▶ EXPIRED (7 ngày không mang tới)  └▶ INSPECTION_FAILED ─▶ RETURNED
                                                                └▶ WITHDRAWN ─▶ RETURNED (kho trả sách)
```

1. Người bán gửi yêu cầu: thông tin sách như mục 3 (cùng form, cùng luật ISBN), giá mong muốn ≥ 300.000đ, cần email đã xác thực. Mỗi yêu cầu là **một cuốn**, thành **một lô**. Staff sơ duyệt (từ chối phải có lý do).
2. Người bán hẹn mang sách tới kho trong 7 ngày, 8:00–17:00.
3. Kho nhận sách theo mã lịch hẹn, gắn mã kho và kệ, chụp ảnh lúc nhận; Staff kiểm định: chấm tình trạng (thang 5 bậc ở mục 3, ghi đè tình trạng người bán khai), checklist và báo cáo tình trạng, ảnh kiểm định (thành ảnh bìa); đạt thì đề xuất giá ước tính, giá khởi điểm, giá sàn (0 < khởi điểm ≤ sàn ≤ ước tính thấp ≤ ước tính cao).
4. Người bán đồng ý hợp đồng (có thể đề nghị giá sàn khác trong khoảng cho phép) → sách thành lô chờ xếp phiên, hoa hồng 15% chụp lúc này.
5. Lô không bán: người bán chọn vào phiên sau (tối đa 2 phiên), chuyển bán giá cố định, hoặc nhận lại sách. Nhận lại: miễn phí 14 ngày, sau đó 5.000đ/ngày.

| Luật | Cũ | Hiện tại |
|---|---|---|
| Giá kiểm định 0 / âm | Nhận, kẹt ở bước người bán | Chặn ngay lúc lập phiếu (`INVALID_PRICE`) |
| Hẹn lịch | Nhận cả giờ đã qua | Phải ở tương lai (`APPOINTMENT_IN_PAST`, mục 25) |
| Người bán không trả lời đề xuất giá | Sách nằm kho mãi | Quá **7 ngày** thì coi như rút, bắt đầu tính hạn nhận lại (mục 11) |
| Lô không bán, người bán im lặng | Sách nằm kho mãi | Quá 7 ngày tự chuyển sang trả sách |
| Sách không ai đến nhận | Nằm kho mãi, phí chỉ tính khi xuất kho | Đủ **53 ngày** thì nhắc; **60 ngày** thì thu phí kho tới hôm đó (thiếu thì ghi nợ), sàn thanh lý, tin chờ duyệt của cuốn đó bị từ chối (mục 12) |
| Phí kho thiếu tiền | Lỗi, Staff không xuất được sách | Ghi nợ, vẫn xuất sách |
| Lô bị trả hàng sau khi bán | Quay lại hàng chờ, dùng báo cáo cũ | Phải kiểm định lại (`INSPECTING`) |
| Kho làm mất / hỏng sách | Không có quy trình | Staff khai báo, Admin duyệt, sàn bồi thường theo giai đoạn (chưa kiểm định: giá mong muốn, tối đa 2.000.000đ; đã kiểm định: mức thấp ước tính; đã bán đã trả tiền: người bán nhận như bán xong, người mua được hoàn + 10% giá búa) |
| Chuyển lô sang bán thường | Tin được duyệt khi sách còn trong kho | Chỉ duyệt khi người bán đã nhận lại sách |

## 5. Đấu giá

### Luồng phiên

```
DRAFT ─▶ PUBLISHED ─▶ CONFIRMED ─▶ LIVE ⇄ PAUSED ─▶ ENDED
 (lập)   (công bố,     (đủ người     (chạy từng lô)
         nhận đăng ký)  khi hết hạn)
            │  thiếu người lần 1: dời lịch 7 ngày, mở lại đăng ký
            └▶ thiếu người lần 2 / Admin huỷ: CANCELLED (hoàn cọc, lô về hàng chờ, không tính lượt)
```

### Từng bước

1. **Lập và công bố**: Admin tạo phiên, xếp lô, công bố. Công bố phải trước giờ mở ≥ 72 giờ, hạn đăng ký trước giờ mở ≥ 24 giờ (môi trường demo đặt 0). Lúc công bố, **chốt vào phiên** phí người mua 10%, bảng bước giá, hệ số hạn mức.
2. **Đăng ký**: đồng ý quy chế, khoá **cọc** của phiên; nhận số bài ẩn danh; **hạn mức trả giá = cọc × 10**. Huỷ được trước hạn đăng ký (hoàn đủ). Cọc thêm được bất cứ lúc nào để nâng hạn mức.
3. **Chạy phiên**: từng lô một, mỗi lô có đồng hồ do server giữ; trả giá trong 15 giây cuối thì đồng hồ về 15 giây (soft close).
4. **Trả giá**: tay, hoặc **giá tối đa** (hệ thống trả hộ từng bước, đặt được trước khi lô mở). Bước giá: < 200.000đ là 10.000đ; < 1 triệu là 50.000đ; < 5 triệu là 100.000đ; từ 5 triệu là 500.000đ.
5. **Chốt lô**: đạt giá sàn là bán (`SOLD`); không đạt là `RESERVE_NOT_MET` (không lộ giá sàn); không ai trả là `NO_BIDS`.
6. **Hết phiên**: người không thắng lô nào được hoàn cọc ngay. Người thắng có **hoá đơn 48 giờ** = giá búa + phí người mua 10% + phí giao − cọc (cọc trừ vào hoá đơn đầu tiên). Thắng nhiều lô thì gộp kiện, lô sau chỉ trả phần ship tăng thêm.
7. **Sau khi trả**: kho xác nhận, giao (hoặc nhận tại kho), người mua nhận → người bán nhận **giá búa − hoa hồng 15%**; sàn giữ phí người mua và phí giao.

| Luật | Cũ | Hiện tại |
|---|---|---|
| Giá tối đa trên giá sàn | Hệ thống chỉ trả hộ ở giá khởi điểm → lô "không đạt giá" dù có người sẵn sàng mua | Hết người tranh mà giá còn dưới giá sàn thì **trả hộ lên đúng giá sàn** (BE-43) |
| Lô cao giá | Một mức cọc cho cả phiên | Lô ước tính cao ≥ **10 triệu**: chỉ trả giá khi tổng cọc ≥ cọc phiên + **10% mức thấp ước tính** (`LOT_DEPOSIT_REQUIRED`, mục 15) |
| Nhân viên sàn | Được đấu giá | Không được (BR-5.0) |
| Đặt giá tối đa sau giờ chốt | Vẫn nhận | `LOT_NOT_OPEN` |
| Giá tay bằng giá tối đa của người dẫn | Cướp được vị trí | Người đặt trước giữ vị trí |
| Mở phiên ngay | Admin bấm được mọi lúc | Chỉ ở môi trường demo (`DEMO_ONLY`) |
| **Backend tắt quá giờ chốt của lô** | Bật lại là lô chốt ngay theo giờ cũ, không ai kịp trả giá | Nhịp đầu tiên sau khi khởi động **kéo dài lô** cho còn ít nhất thời gian soft close (BE-48) |

### Thanh toán và giao lô đấu giá

Sách đấu giá nằm ở **kho của sàn**, nên **kho giao**, không phải người bán. Người bán (shop) mở đơn đấu giá sẽ bị chặn ("Đơn đấu giá do kho xử lý").

```
PENDING_PAYMENT ─trả─▶ PENDING_CONFIRM ─Staff xác nhận─▶ PREPARING ─┬─ Xuất kho giao ─▶ SHIPPING ─ Đã giao ─▶ DELIVERED ─▶ COMPLETED
 (hoá đơn 48 giờ)      (đã thanh toán)                               └─ nhận tại kho: bàn giao ──────────────▶ DELIVERED    (người mua nhận
                                                                                                                          hoặc sau 3 ngày)
```

| Bước | Ai làm | Chi tiết |
|---|---|---|
| Chọn cách nhận | Người thắng | Trên hoá đơn: **"Giao tận nơi"** (chọn địa chỉ) hoặc **"Nhận tại kho ReBook"** (phí giao 0đ). Chỉ đổi được khi chưa thanh toán (`POST /orders/{id}/delivery-option`). Phí giao tính từ tỉnh của kho tới tỉnh người nhận; thắng nhiều lô cùng phiên thì gộp kiện |
| Thanh toán | Người thắng | "Thanh toán hóa đơn": ví hoặc ZaloPay. Hoá đơn = giá búa + phí người mua + phí giao − cọc (cọc trừ vào hoá đơn đầu tiên). Trả xong: lô `PAID`, sách trong kho chuyển `RESERVED` (giữ cho người thắng), giá búa vào túi **đang giữ** của người bán, phí người mua + phí giao vào ví sàn |
| Xác nhận | Staff | Đơn chuyển `PREPARING`. Hạn **24 giờ** (quá hạn báo Staff, Admin một lần) |
| Xuất kho giao | Staff | "Xuất kho giao": mã vận đơn tự sinh nếu để trống; sách trong kho chuyển `SHIPPED`. Hạn **3 ngày** kể từ lúc thanh toán (quá hạn báo Staff, Admin; đơn nhận tại kho không tính hạn này vì chờ người thắng tới lấy) |
| Đã giao / bàn giao tại kho | Staff | "Đã giao" khi hãng báo giao thành công. Đơn nhận tại kho: Staff bàn giao khi người thắng tới lấy (`POST /staff/orders/{id}/delivered`, từ `PREPARING`) |
| Nhận hàng | Người thắng | "Đã nhận hàng" → `COMPLETED`: người bán nhận **giá búa − hoa hồng 15%** (tỷ lệ chụp lúc người bán chấp nhận hợp đồng); sàn bù chênh nếu lô từng bị bỏ (BR-6.2). Không bấm thì tự hoàn tất sau 3 ngày kể từ lúc giao |
| Trả hàng | Người thắng, Staff xử lý | Trong 3 ngày sau khi giao, lý do + ảnh. **Sàn chịu trách nhiệm** vì đã kiểm định: Staff đồng ý → người mua gửi về kho → kho nhận → hoàn đủ hoá đơn (cả phần cọc đã trừ), người bán không nhận tiền, lô chuyển `INSPECTING` chờ kiểm định lại. Lý do "Không nhận được hàng" không dùng cho đơn đấu giá (liên hệ sàn, xử lý như sự cố kho) |
| Giao thất bại | Staff | Ghi ai gây lỗi. Lỗi **người mua** (từ chối nhận, sai địa chỉ, không liên lạc được): hoàn tiền rồi **phạt như bỏ thanh toán** + thu phí giao chiều đi (BE-45). Lô về `INSPECTING` |

Trên app, màn Staff "Giao lô đấu giá" **chưa có** nút cho đơn vừa thanh toán (Chờ xác nhận) và nút bàn giao tại kho (mục 8). Tạm dùng Swagger: `POST /staff/orders/{id}/confirm`, `POST /staff/orders/{id}/delivered`.

### Bỏ thanh toán và sau phiên

```
Hết 48 giờ chưa trả ──▶ (đang mở ZaloPay? hỏi lại cổng, ân hạn 15 phút)
                    ──▶ huỷ hoá đơn ──▶ mất cọc + phạt ──▶ cấm đấu giá
                    ──▶ có người về nhì hợp lệ, giá ≥ giá sàn? ── có ──▶ mời mua lần hai 24 giờ ở giá công bằng
                                                              └─ không ─▶ lô về hàng chờ xếp phiên
```

| Luật | Cũ | Hiện tại |
|---|---|---|
| Phạt bỏ thanh toán | Mất cọc ở lô đầu; bỏ các lô sau không mất gì | **Mỗi lô bỏ**: phạt = max(cọc còn giữ, **10% giá búa**); thiếu thì thu từ ví, vẫn thiếu thì **ghi nợ** |
| Cọc / phạt về đâu | 50% người bán, 50% sàn (SRS) | **100% về sàn** (BR-6.1); lô bán lại thấp hơn thì sàn **bù chênh** cho người bán, tối đa bằng số đã thu từ người bỏ (BR-6.2) |
| Thời gian cấm | Luôn 90 ngày | **Luỹ tiến**: lần 1 cấm 90 ngày, lần 2 trong 12 tháng cấm 365 ngày, lần 3 **vĩnh viễn** (Admin vẫn gỡ được); bỏ nhiều lô cùng phiên tính một lần (mục 23) |
| Trả ZaloPay sát hạn, cổng báo chậm | Bị phạt như bỏ thanh toán | Hỏi lại ZaloPay trước; còn chờ thì **ân hạn 15 phút** (BE-46) |
| Người thắng không biết mình thắng | Vẫn bị phạt sau 48 giờ | Thắng lô có **mail báo**. Tới hạn mà mail chưa gửi được **và** thông báo trong app chưa đọc: **không phạt, gia hạn 24 giờ một lần**, nhắc lại, báo Admin. Mail đang tắt thì coi như đã báo bằng app (như cũ) |
| Trả tiền rồi **từ chối nhận hàng** | Hoàn đủ, không phạt (rẻ hơn bỏ thanh toán) | Staff ghi lỗi người mua: hoàn tiền rồi **phạt như bỏ thanh toán** + thu phí giao chiều đi (BE-45) |
| Người được mời mua lần hai | Người cao thứ hai, kể cả người bị cấm / nợ / người ký gửi | Người hợp lệ kế tiếp: không bị cấm, không nợ, không phải người bán, **không bị khoá** |
| Giá mời mua lần hai | Đúng giá người về nhì đã trả | **Giá công bằng**: max(giá sàn, min(giá người về nhì, giá người kế tiếp + 1 bước)); không có người kế tiếp thì bằng giá sàn (BR-6.5) |
| Từ chối lời mời lần hai | — | Không phạt; lô về hàng chờ |
| Người thắng bị khoá tài khoản | Bị phạt khi quá hạn | Không phạt, hoàn cọc, mời người kế tiếp |
| Kho quên xử lý hoá đơn đã trả | Không ai biết | Quá 24 giờ chưa xác nhận / 3 ngày chưa giao thì **báo Staff và Admin** một lần (mục 13) |

## 6. Thời hạn và job tự động

| Việc | Hạn | Quá hạn thì | Cũ |
|---|---|---|---|
| Thanh toán đơn thường | 15 phút | Tự huỷ, trả tồn kho | Có |
| Shop xác nhận | 24 giờ | Tự huỷ, hoàn tiền, tính lỗi shop | Có |
| Shop giao cho vận chuyển | 3 ngày | Tự huỷ, hoàn tiền, tính lỗi shop | Không có |
| Shop trả lời yêu cầu huỷ | 24 giờ | Tự đồng ý huỷ | Không có |
| Người mua xác nhận nhận hàng (trả trước) | 7 ngày từ lúc giao vận chuyển | Tự coi là đã giao | Shop tự bấm |
| Khiếu nại | 3 ngày sau khi giao | Tự hoàn tất | Có |
| Shop trả lời yêu cầu trả hàng | 2 ngày | Chuyển Admin | Không có |
| Người mua gửi hàng trả | 7 ngày | Đóng yêu cầu, đơn hoàn tất | Không có |
| Shop xác nhận hàng trả về | 7 ngày | Chuyển Admin | Không có |
| Hoá đơn đấu giá | 48 giờ (+15 phút nếu đang mở ZaloPay) | Phạt, cấm, mời người về nhì | 48 giờ, chỉ mất cọc |
| Lời mời mua lần hai | 24 giờ | Lô về hàng chờ, không phạt | Có |
| Kho xử lý hoá đơn đấu giá đã trả | 24 giờ xác nhận / 3 ngày giao | Báo Staff, Admin | Không có |
| Người ký gửi mang sách tới | 7 ngày sau khi duyệt | Hết hạn | Có |
| Người ký gửi trả lời đề xuất giá | 7 ngày | Coi như rút | Không có |
| Người ký gửi chọn hướng cho lô không bán | 7 ngày | Tự chuyển trả sách | Không có |
| Nhận lại sách | 14 ngày miễn phí, 5.000đ/ngày sau đó | Ngày 53 nhắc, ngày 60 thanh lý | Không giới hạn |
| Nhắc trước hạn | 24 giờ trước: giao hàng, trả lời huỷ, thanh toán hoá đơn, chọn hướng lô | | Không có |
| Đối soát ví với sổ cái | Mỗi đêm | Cảnh báo khi lệch | Không có |
| Gửi mail trong hàng đợi | Mỗi 30 giây | Lỗi thì thử lại sau 1 phút, 5 phút, 30 phút, 2 giờ; lần 5 vẫn lỗi thì `FAILED` | Không có mail |
| Tiền bán hàng của shop mới | 7 ngày từ lúc giải ngân | Rút được | Rút ngay |

## 7. Cấu hình hiện hành

Giá trị mặc định trên DB dev ngày 2026-11-06. Hai khoá lịch phiên trên dev đặt 0 cho demo; môi trường thật là 72 giờ và 24 giờ.

| Nhóm | Khoá | Giá trị | Mức tối thiểu |
|---|---|---|---|
| Phí | `fee.fixed_price_percent` / `fee.buyer_premium_percent` / `fee.seller_commission_percent` | 5% / 10% / 15% | 0–100 |
| Kho | `fee.storage_free_days` / `fee.storage_per_day` / `warehouse.abandon_days` | 14 ngày / 5.000đ / 60 ngày | abandon ≥ 14 |
| Bồi thường kho | `warehouse.compensation_cap_uninspected` / `warehouse.compensation_buyer_percent` | 2.000.000đ / 10% | |
| Đơn | `order.payment_timeout_minutes` / `confirm_timeout_hours` / `ship_deadline_days` / `auto_deliver_days` / `auto_complete_days` | 15 phút / 24 giờ / 3 / 7 / 3 ngày | 5 phút / 1 / 1 / 1 / 1 |
| Trả hàng | `order.return_response_days` / `return_ship_days` / `return_confirm_days` / `cancel_response_hours` | 2 / 7 / 7 ngày / 24 giờ | 1 |
| COD | `order.cod_max_amount` / `cod_new_buyer_max_amount` / `cod_max_failures` / `cod_failure_window_days` | 3.000.000đ / 500.000đ / 2 / 90 ngày | |
| Ship | `shipping.same_province` / `other_province` / `extra_per_500g` | 20.000đ / 30.000đ / 5.000đ | |
| Ví | `wallet.topup_hold_hours` / `withdraw_daily_limit` | 24 giờ / 20.000.000đ | |
| Shop mới | `wallet.seller_hold_days` / `seller_hold_min_orders` / `seller_hold_shop_days` | 7 ngày (0 = tắt) / 10 đơn / 30 ngày | |
| Ký gửi | `consignment.min_expected_price` / `appointment_days` / `seller_decision_days` / `max_rounds` | 300.000đ / 7 / 7 ngày / 2 phiên | 1 |
| Đấu giá | `auction.payment_hours` / `second_chance_hours` / `unsold_decision_days` / `postpone_days` | 48 / 24 giờ / 7 / 7 ngày | 1 |
| Phạt | `auction.default_penalty_percent` / `forfeit_seller_percent` / `ban_days` / `ban_days_repeat` | 10% / 0% / 90 / 365 ngày | |
| Lô cao giá | `auction.high_value_lot_threshold` / `high_value_deposit_percent` | 10.000.000đ / 10% | |
| Hạn mức | `auction.bid_limit_multiplier` | 10 | 1 |
| Bước giá | `auction.bid_increment_tiers` | `0:10000, 200000:50000, 1000000:100000, 5000000:500000` | |
| Lịch phiên | `auction.min_publish_lead_hours` / `min_registration_close_hours` | 72 / 24 giờ (dev: 0 / 0) | |
| Uy tín shop | `shop.fault_rate_percent` / `fault_min_orders` / `reputation_window_days` | 10% / 5 đơn / 90 ngày | |

Hằng số trong code (chưa đưa vào cấu hình): ân hạn ZaloPay 15 phút; báo trước thanh lý sách 7 ngày; đăng nhập sai 10 / 30 / 100 lần trong 15 phút; xin OTP 60 giây / 5 mã một giờ / 10 mã một ngày; gia hạn hoá đơn khi chưa báo được người thắng 24 giờ.

Cấu hình theo máy (biến môi trường hoặc `apps/backend/.env`, mẫu ở `apps/backend/env.example`): `MAIL_ENABLED`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USER`, `MAIL_PASS`, `MAIL_FROM`.

## 8. Chưa có trong hệ thống

Những luật đã bàn nhưng chưa làm. Chi tiết và mức nặng ở [DANH_GIA_BA_TESTER.md](DANH_GIA_BA_TESTER.md) phần A.

- **Cần dịch vụ ngoài:** OTP SMS thật, định danh CCCD, thông báo push, hãng vận chuyển thật để kiểm mã vận đơn, nhận báo chargeback tự động từ cổng thanh toán (hiện Admin ghi tay). Mail đã có, cần tài khoản SMTP và tên miền có SPF / DKIM khi chạy thật.
- **Cần chủ sàn quyết:** shop chịu ship chiều về khi sách sai mô tả; ngày nghỉ và công suất kho; bộ sách bán nguyên bộ hay cho bán lẻ từng tập; sách trước 1970 / lô đấu giá có bắt buộc ảnh trang bản quyền không; Staff có được sửa thông tin sách khi kiểm định không (BR-4.5).
- **Sách: SRS hoặc luật bổ sung đã có nhưng code chưa làm:**
  - **Bộ sách**: SRS 6.x cho phép "một lô có thể là một bộ sách", nhưng hệ thống chưa có số tập, tập thiếu, ISBN của bộ, lý do trả hàng "thiếu tập". Hiện chỉ đăng thành một tin / một lô đặt tên "Bộ X (n tập)".
  - **Phiếu kiểm định có cấu trúc** (BR-4.1 đến 4.5): checklist đang là JSON tự do; chưa bắt buộc bộ ảnh chuẩn (bìa trước, bìa sau, gáy, trang bản quyền, chỗ hỏng); chưa có trường chữ ký / bút tích đã xác thực hay chưa; Staff chưa đối chiếu được thông tin sách.
  - **Lần in / ấn bản** (BR-2.6): chưa có trường riêng, dù "sai ấn bản" là lý do trả hàng.
  - **Chính sách nội dung** (BR-2.8 đến 2.11): chưa cấm sách lậu / photocopy trong code, chưa có nút báo cáo tin, chưa có lý do trả hàng `COUNTERFEIT`, chưa khoá shop vi phạm 3 lần.
  - **Giới hạn** (BR-2.12): chưa có trần giá 500.000.000đ, tồn kho 999; năm xuất bản cho phép tới 2100 (nhập được năm tương lai).
  - Sách cũ tồn kho > 1 dùng chung một bộ ảnh chưa bị chặn (mục 24 bản đánh giá).
  - Chưa gợi ý tự điền thông tin từ ISBN (BR-2.7).
- **Cần frontend làm cùng:** hoàn một phần khi khiếu nại, xác nhận khi trả giá lớn, bán sau phiên cho người chưa đạt giá sàn, hai Admin cùng duyệt khoản rút lớn, OTP khi thêm tài khoản ngân hàng.
- **Frontend chưa theo kịp backend:** lựa chọn "Không nhận được hàng", ô "ai gây lỗi" khi báo giao thất bại, gửi `expectedTotal`, hiện lỗi `LOT_DEPOSIT_REQUIRED` / `PRICE_CHANGED`; màn rút tiền hiện `saleHeld` / `saleUnlockAt` và lỗi `SALE_HELD`; màn OTP hiện `TOO_MANY_REQUESTS` / `EMAIL_SEND_FAILED`; màn Admin ghi nợ chargeback; hiện cờ `isbnWarning` ở màn duyệt tin.
- **Frontend chưa đi hết luồng giao hàng** (đọc code app ngày 2026-11-06):
  - Màn Staff "Giao lô đấu giá" chỉ có nút cho đơn `PREPARING` / `SHIPPING`: hoá đơn vừa thanh toán (`PENDING_CONFIRM`) không có nút xác nhận; đơn **nhận tại kho** bấm "Xuất kho giao" sẽ bị `PICKUP_ORDER`, chưa có nút bàn giao tại kho.
  - Chưa có màn Staff đối chiếu hãng vận chuyển (`/staff/orders/in-transit`, `carrier-delivered`, `carrier-failed`) và màn Admin đối soát COD (`/admin/cod/pending`, `remit`): ngoài dev, đơn COD không tới được bước hoàn tất trên app.
  - Nút "Đã nhận hàng" của người mua chỉ hiện khi đơn đã Giao; backend nhận cả khi đơn đang giao.
