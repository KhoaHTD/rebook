# Sổ bàn giao frontend → backend

Giao diện đã làm **nhiều hơn SRS** (SRS ngày 21/10 + bản cập nhật 31/10). Phần dư đó là yêu cầu cho backend. File này liệt kê từng thứ;
`openapi/openapi.yaml` là hợp đồng máy đọc được; `tool/api_gap.dart` so hai spec và in ra backend còn thiếu gì.

## Cách backend dùng (đọc trước khi code)

1. Đọc file này, rồi chạy trong `apps/frontend` (cần cả `apps/backend/openapi.yaml`, tức là trên nhánh có backend, thường là `main`):
   ```bash
   dart run tool/api_gap.dart                  # in danh sách còn thiếu / lệch, mã thoát 1 nếu còn
   dart run tool/api_gap.dart --backend <file> # spec backend ở chỗ khác
   dart run tool/api_gap.dart --all-fields     # thêm mọi field frontend có mà backend chưa có (nhiều nhiễu)
   ```
2. Làm theo mục tương ứng bên dưới. **Frontend là nơi định nghĩa giao diện cần gì**; chỗ nào backend thấy không hợp lý thì **sửa
   `apps/frontend/openapi/openapi.yaml` (qua PR / báo chủ repo) rồi mới làm khác**, không lặng lẽ làm lệch.
3. Xong một mục: chạy lại `api_gap`, rồi báo frontend chạy `/sync-api` (sinh lại client) và cập nhật cột Tình trạng ở mục D. Giữ nguyên các dấu `x-origin` trong spec: công cụ tự bỏ qua những mục backend đã có.
4. Tên field / endpoint dưới đây là **đặt tạm** (SRS mục 10.4 không liệt kê). Backend được quyền đổi tên, miễn là sửa spec để hai bên khớp.

## Quy ước đánh dấu trong `openapi.yaml`

| Đánh dấu | Nghĩa |
|---|---|
| `x-origin: frontend` | endpoint / schema / field / tham số do frontend đặt thêm, backend chưa có trong SRS |
| `x-frontend-change: "..."` | endpoint đã có nhưng frontend cần thêm / đổi hành vi |
| `x-frontend-added: [A, B]` | giá trị enum frontend thêm |

Frontend: **mỗi lần thêm thứ ngoài SRS đều phải đánh dấu như trên và thêm một mục vào file này.**

## A. Từ SRS cập nhật 31/10 (backend nên làm theo SRS, spec bên dưới là phần frontend cần)

### A1. Hạn shop trả lời yêu cầu trả hàng (SRS 4.4)
- Field: `ReturnRequestDto.respondBy` (hạn trả lời, = lúc tạo yêu cầu + `order.return_response_days`).
- Cấu hình: `SystemConfigDto.returnResponseDays` (mặc định 2), Admin sửa được ở `PUT /admin/config`.
- **Job định kỳ:** quá `respondBy` mà `ReturnStatus = PENDING` thì chuyển `ESCALATED` (Admin phân xử), tiền vẫn do sàn giữ.
- Enum mới `ReturnStatus.WITHDRAWN`: người mua gọi `/orders/{id}/confirm-received` khi đơn đang `RETURN_REQUESTED` → đóng yêu cầu
  (`WITHDRAWN`), đơn sang `COMPLETED`, trả tiền người bán như thường. Không cần endpoint mới.
- Giao diện: đơn mua và đơn shop hiện hạn trả lời; đơn mua có nút "Đã nhận hàng, rút yêu cầu trả"; Cấu hình phí có ô số ngày.

### A2. Mời mua lần hai (SRS 6.6)
- `GET /me/offers` → `SecondChanceOfferDto[]` {id, lotId, lotNumber, bookTitle, coverUrl, amount, expiresAt, status}.
- `POST /me/offers/{id}/accept` → `OrderDto` (đơn `AUCTION`, giá = `amount`, hạn thanh toán 48h, không có cọc để trừ).
- `POST /me/offers/{id}/decline` → `SecondChanceOfferDto`.
- Luật: khi người thắng quá hạn 48h không thanh toán, **chỉ mời người trả giá cao thứ hai nếu giá của họ ≥ giá sàn**; hạn 24h
  (`expiresAt`); hết hạn thì `EXPIRED`; từ chối / hết hạn thì lô quay lại chờ xếp phiên sau. Gửi thông báo `AUCTION_WON` có link `/auctions/account/offers`.
- Giao diện: hồ sơ đấu giá có dòng "Lời mời mua lần hai (n)", màn danh sách có nút Mua với giá này / Từ chối.

### A3. Biên lai rút tiền (SRS 8.1)
- `POST /admin/withdrawals/{id}/complete` nhận `WithdrawalReceiptDto` {senderName, transferredAt, amount, proofImageUrl};
  **số tiền phải đúng số yêu cầu** (HTTP 422, mã `RECEIPT_AMOUNT_MISMATCH`).
- `WithdrawalDto.receipt` trả lại để người bán xem trong lịch sử rút tiền. Ảnh chứng từ upload qua chữ ký Cloudinary như các ảnh khác.
- Xem thêm A5 (ví bị trừ lúc duyệt).

### A4. Nhật ký hoạt động Admin (SRS 8.1)
- `GET /admin/activity-logs` → `ActivityLogDto[]` {id, adminName, action, target, note, createdAt}, mới nhất trước.
- `AdminAction`: `LISTING_APPROVED, LISTING_REJECTED, USER_LOCKED, USER_UNLOCKED, ROLE_CHANGED, AUCTION_BAN_LIFTED, SHOP_MARKED_TRUSTED,
  WITHDRAWAL_COMPLETED, CONFIG_CHANGED`. Backend ghi một dòng cho **mọi** thao tác Admin tương ứng (bảng `activity_logs`).
- `note` của `WITHDRAWAL_COMPLETED` là số tiền (số nguyên) để giao diện tự định dạng.

## B. Ngoài SRS (người dùng yêu cầu thêm, SRS chưa có, cần cập nhật SRS cho khớp)

### B1. Sách yêu thích
- `POST /listings/{id}/favorite` {favorite: bool} → `ListingDto`; `GET /me/favorites` → `ListingDto[]` (mới thả tim đứng đầu). Bảng gợi ý `listing_favorites(user_id, listing_id, created_at)`.

### B2. Phiên yêu thích (theo dõi cả phiên)
- `POST /sessions/{id}/watch` {watch: bool} → `AuctionSessionDto`; `GET /me/watched-sessions` → `AuctionSessionDto[]`. Khác với theo dõi từng lô (`lot_watchers`).
  Tab "Yêu thích" ở trang chủ đấu giá = phiên đã theo dõi hoặc phiên có lô đang theo dõi (frontend tự ghép).

### B3. Toạ độ và loại địa chỉ
- `AddressDto` / `AddressRequest` thêm `latitude`, `longitude` (double, tuỳ chọn); cột `addresses.latitude/longitude`.
  Đây là **toạ độ tâm bản đồ** người dùng chọn: màn sửa địa chỉ có bản đồ OpenStreetMap, ghim cố định giữa khung, người dùng kéo bản đồ cho tâm trúng chỗ.
  App tự định vị lần đầu từ địa chỉ gõ tay (Nominatim, gọi **thẳng từ app**, ~1 yêu cầu/giây, dò từ số nhà xuống phường / quận); kéo tay thì app ngừng tự định vị.
  Chưa kéo lần nào thì lưu điểm tự định vị hoặc tâm tỉnh. Backend chỉ **lưu** hai số này, không cần geocode.
  Chạy thật nhiều người: nên để backend gọi geocoder và cache, và dùng nhà cung cấp tile riêng (máy chủ tile công cộng của OSM cấm dùng nặng).
- Thêm `addressType` (`HOME` | `OFFICE`, mặc định `HOME`) cho nhãn Nhà riêng / Văn phòng; cột `addresses.address_type`.
- `province`: một trong 63 tên frontend cho chọn (`VietnamGeo.provinceNames`, vd "TP. Hồ Chí Minh").
  `district`, `ward`: **không còn gõ tay**, người dùng chọn từ danh sách tải về từ provinces.open-api.vn (63 tỉnh, địa giới trước 2025), nên giá trị là tên đầy đủ của API đó
  ("Quận 1", "Thành phố Thủ Đức", "Phường Nguyễn Thái Bình"). Lưu dạng chuỗi như nhận; **đừng đối chiếu với danh sách riêng** vì tên có thể khác kiểu viết (dữ liệu cũ vẫn có "P.", "Q.", "TP.").
  Nếu không tải được danh sách, người dùng nhập tay tên quận / phường (2–50 ký tự).
  Muốn đổi sang địa giới 2 cấp sau 2025 thì đổi nguồn ở `core/network/admin_units.dart`; backend nên cho phép `district` rỗng trong tương lai.

### B4. Chọn món trong giỏ
- `GET /cart?itemIds=a&itemIds=b`: chỉ tính các món đã chọn, **phí ship tính lại theo khối lượng các món này**; bỏ tham số = cả giỏ.
- `POST /orders/checkout` đã có `itemIds`: chỉ đặt các món đó, món còn lại ở lại giỏ.
- Trạng thái "đã chọn" **không** lưu ở backend (frontend giữ, mặc định chọn hết).

### B5. Rút tiền có thông tin ngân hàng + trừ ví khi duyệt
- `POST /wallet/withdrawals` nhận `WithdrawalRequest` {amount, bankName, bankAccountNumber, bankAccountName (IN HOA không dấu), note}.
  Validate: số tài khoản 6–19 chữ số, tên IN HOA không dấu, `amount ≤ available_balance`. Cột mới `withdrawal_requests.bank_name,
  bank_account_number, bank_account_name, note`.
- **Ví chỉ bị trừ khi Admin duyệt** (`WITHDRAW`, một `@Transactional` cùng với lưu biên lai A3 và đổi trạng thái sang `COMPLETED`),
  và **duyệt phải kiểm tra lại `available_balance`** (`INSUFFICIENT_BALANCE` nếu người bán đã tiêu mất). Lưu ý: trong lúc chờ duyệt tiền vẫn
  nằm ở `available`, nên cân nhắc khoá tạm (`held`) nếu muốn chặn rút trùng, nếu đổi thì sửa spec và báo frontend.
- `WithdrawalDto` trả lại các trường ngân hàng, `approvedBy`, `approvedAt`, `receipt`.

### B6. Tài khoản ngân hàng đã dùng ("Gần đây" + ngôi sao)
- `GET /wallet/bank-accounts` → `BankAccountDto[]` {id, bankName, accountNumber, accountName, favorite, lastUsedAt}; sắp xếp: yêu thích trước,
  rồi `lastUsedAt` mới nhất.
- `POST /wallet/bank-accounts/{id}/favorite` {favorite} → `BankAccountDto`.
- Backend **tự lưu / cập nhật** tài khoản mỗi lần tạo yêu cầu rút (khoá `bankName + accountNumber`, cập nhật tên và `lastUsedAt`).
- Danh sách ngân hàng trong dropdown viết cứng ở frontend (`shared/data/vietnam_banks.dart`); `bankName` là tên hiển thị đó (vd "Vietcombank", "MB Bank").

### B7. Người duyệt và thời gian duyệt
- `WithdrawalDto.approvedBy/approvedAt`, `ListingDto.reviewedBy/reviewedAt` (duyệt hoặc từ chối), `ReturnRequestDto.resolvedBy/resolvedAt` (Admin phân xử).
- `GET /admin/returns?resolved=true` trả các đơn đã phân xử (mặc định chỉ các đơn đang chờ phân xử).

### B8. Ảnh bìa đại diện (không cần endpoint mới)
- Khi đăng bán / ký gửi, frontend cho người bán chọn ảnh bìa trước, kéo 4 góc, **tự làm phẳng ở máy** (nắn phối cảnh, xuất PNG) rồi upload như ảnh thường.
  Ảnh bìa đó được đặt **đứng đầu** `imageUrls`, theo sau là các ảnh thật. Backend **giữ nguyên thứ tự ảnh** (`book_images.sort_order`): ảnh đầu = bìa đại diện (`Book.coverUrl`).
- Số ảnh tối thiểu (SRS 4.1: 3 ảnh thật) tính trên các ảnh thật, **không tính** ảnh bìa đại diện.
- Đề xuất (chưa làm, chờ backend): `POST /uploads/cover-check` nhận ảnh, dùng model đọc ảnh trả `{type: FRONT_COVER|BACK_COVER|SPINE|OTHER|NOT_A_BOOK, issues: [BLURRY, GLARE, TOO_DARK, CROPPED], corners}`;
  frontend dùng để chặn ảnh rác (ảnh chụp màn hình…) và gợi ý sẵn 4 góc. Khoá API model chỉ để ở backend.

### B9. Luật nhập liệu (backend nên kiểm tra lại cùng luật)
Frontend chặn ký tự và kiểm tra ở `lib/core/utils/input_rules.dart`; backend **phải kiểm tra lại** (không tin client) và trả lỗi 400 cùng luật. Cột "Nguồn": **SRS** = có trong SRS, **FE** = frontend tự đề xuất theo thông lệ (backend góp ý được; đổi thì sửa spec rồi báo frontend). Chỉ ngưỡng ký gửi ≥ 300.000đ (SRS 6.1) và việc ISBN là tuỳ chọn là có trong SRS; mọi con số khác là đề xuất.

| Trường | Luật | Nguồn |
|---|---|---|
| email | `^[^@\s]+@[^@\s]+\.[^@\s]+$`, ≤ 100 | FE |
| phone | `^(0\|\+84)\d{9,10}$` | FE |
| password | ≥ 6 ký tự, ≤ 64 (giữ 6 để tài khoản mẫu `123456` còn dùng) | FE |
| otp | đúng 6 chữ số | FE |
| fullName | chữ cái (có dấu), dấu cách, `. ' -`; 2–60 | FE |
| district, ward | 2–50 (chọn từ danh sách, xem B3) | FE |
| street (số nhà, tên đường) | 5–120 | FE |
| bankNumber | `^\d{6,19}$` | FE |
| bankHolder | `^[A-Z ]{2,50}$` (IN HOA không dấu) | FE |
| bankName | 2–40 | FE |
| shopName | 3–40; pickupAddress 8–150 | FE |
| bookTitle | 2–120; author, publisher 2–80; language 2–30 | FE |
| year | số nguyên 1450 → năm hiện tại | FE |
| isbn | bỏ gạch / cách, ISBN-10 hoặc ISBN-13 đúng số kiểm tra | FE |
| pages | 1–5000; weightGram 20–5000; stock 0–999 | FE |
| price (giá bán) | 1.000–100.000.000, **bội số 1.000** | FE |
| expectedPrice (ký gửi) | ≥ 300.000 | SRS |
| story, conditionReport | 20–1000; description 5–2000 | FE |
| amount (nạp / rút) | ≥ 10.000 | FE |
| proxyMax (trả giá tự động) | ≥ 1.000, bội số 1.000 | FE |
| estimate / proposedStart | 1.000–1.000.000.000; reserve 0–1.000.000.000; ước tính thấp ≤ cao, giá sàn ≤ thấp | FE |
| appointmentCode | `^[A-Z0-9-]+$` | FE |
| **shelfCode** | `^[A-Z]\d{1,2}-\d{1,3}$` (vd "A3-12") | **FE** |
| **trackingCode** | `^[A-Z0-9]{8,20}$` | **FE** |
| returnReason | 10–500; review 2–500 (tuỳ chọn) | FE |
| sessionTitle | 5–80; categoryName 2–40 | FE |
| minParticipants | 1–500; deposit 10.000–100.000.000 | FE |
| lotSeconds | 30–600; softCloseSeconds 5–60 | FE |
| phí % (cố định, người mua, người bán) | 0–100, tối đa 1 chữ số thập phân | FE |
| cấu hình số nguyên | phí lưu kho 0–1.000.000; ngày lưu kho miễn phí 0–365; hạn thanh toán đơn 5–1440 phút; hạn thanh toán đấu giá 1–168 giờ; hệ số cọc 1–100; ngày cấm đấu giá 0–365; hạn trả lời trả hàng 1–30 ngày; bậc giá 1.000–1.000.000.000 | FE |

Chuẩn hoá trước khi lưu: cắt khoảng trắng hai đầu, gộp khoảng trắng liên tiếp (tên, địa chỉ), ISBN bỏ gạch / cách và viết hoa. Backend nên làm tương tự để dữ liệu không lệch.

## C. Frontend suy ra từ dữ liệu có sẵn (không cần endpoint mới, có thể tối ưu)
- **Khu mua sách / khu đấu giá tách hồ sơ:** đơn lọc theo `Order.type` (`NORMAL` / `AUCTION`); ví lọc theo loại giao dịch (`DEPOSIT_*` là của đấu giá).
  Đề xuất: `GET /orders?type=` và `GET /wallet/transactions?group=` để khỏi tải rồi lọc.
- **Lịch sử trả giá:** frontend ghép từ `GET /me/registrations` (số bài) + `GET /lots/{id}/bids` từng lô. Đề xuất `GET /me/bids` (lô, số tiền, giờ, đang dẫn đầu hay bị vượt) để tránh nhiều lần gọi.
- **Trang chủ đấu giá:** mỗi phiên hiện kệ các lô của phiên đó (gọi `GET /sessions/{id}` từng phiên). Đề xuất `GET /sessions` trả kèm vài bìa đầu (`previewLots`) để khỏi gọi N lần.

## D. Tình trạng

| Mục | Backend |
|---|---|
| A1 Hạn trả lời trả hàng | chưa |
| A2 Mời mua lần hai | chưa |
| A3 Biên lai rút tiền | chưa |
| A4 Nhật ký Admin | chưa |
| B1 Sách yêu thích | chưa |
| B2 Phiên yêu thích | chưa |
| B3 Toạ độ địa chỉ + chọn quận / phường từ danh sách | chưa (chỉ lưu thêm 3 cột: lat, lon, address_type) |
| B4 Chọn món trong giỏ | chưa |
| B5 Rút tiền + ngân hàng | chưa |
| B6 Tài khoản ngân hàng đã dùng | chưa |
| B7 Người duyệt | chưa |
| B9 Luật nhập liệu (bảng ở B9) | chưa kiểm tra lại phía server |
| B8 Ảnh bìa đại diện | giữ thứ tự ảnh (chưa); AI kiểm tra loại ảnh (đề xuất) |

Backend cập nhật cột này khi làm xong từng mục (và chạy lại `api_gap`).
