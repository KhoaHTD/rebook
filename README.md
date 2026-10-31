# ReBook — Chợ sách cũ

ReBook là chợ mua bán sách cũ có **hai cách mua**:

- **Mua giá cố định**, như một sàn thương mại điện tử: bỏ vào giỏ, thanh toán, theo dõi đơn.
- **Đấu giá trực tiếp** (realtime): sách quý được người bán **ký gửi** vào kho của sàn, nhân viên **kiểm định** rồi mới đưa lên đấu giá, nên người mua yên tâm về hàng.

Tiền đi qua **ví của sàn (escrow)**: người mua trả, sàn giữ, người mua nhận hàng xong tiền mới chuyển cho người bán.

---

## Mục lục

1. [Cấu trúc dự án](#1-cấu-trúc-dự-án)
2. [Chạy thử nhanh](#2-chạy-thử-nhanh)
3. [Tài khoản mẫu](#3-tài-khoản-mẫu)
4. [Hướng dẫn sử dụng](#4-hướng-dẫn-sử-dụng)
   - [4.1 Tài khoản](#41-đăng-ký-đăng-nhập-và-tài-khoản)
   - [4.2 Tìm và xem sách](#42-tìm-và-xem-sách)
   - [4.3 Giỏ hàng và đặt hàng](#43-giỏ-hàng-và-đặt-hàng)
   - [4.4 Theo dõi đơn, nhận hàng, đánh giá, trả hàng](#44-theo-dõi-đơn-nhận-hàng-đánh-giá-trả-hàng)
   - [4.5 Ví ReBook](#45-ví-rebook)
   - [4.6 Đấu giá](#46-đấu-giá)
   - [4.7 Mở shop và bán sách](#47-mở-shop-và-bán-sách)
   - [4.8 Ký gửi sách đi đấu giá](#48-ký-gửi-sách-đi-đấu-giá)
   - [4.9 Nhân viên kho](#49-nhân-viên-kho-staff)
   - [4.10 Quản trị viên](#410-quản-trị-viên-admin)
5. [Các quy tắc cần biết](#5-các-quy-tắc-cần-biết)
6. [Câu hỏi thường gặp](#6-câu-hỏi-thường-gặp)
7. [Tài liệu cho lập trình viên](#7-tài-liệu-cho-lập-trình-viên)

---

## 1. Cấu trúc dự án

| Thư mục | Nội dung |
|---|---|
| `apps/frontend/` | Ứng dụng Flutter (web, Android, iOS). Xem [apps/frontend/README.md](apps/frontend/README.md) |
| `apps/backend/` | Spring Boot 3.5 + PostgreSQL: REST API và WebSocket. Xem [apps/backend/README.md](apps/backend/README.md) |
| `demo/` | Script bật app ra Internet bằng một link (Cloudflare Tunnel), chạy app Android trên máy ảo |
| `docs/` | Đặc tả (SRS), kịch bản demo, hướng dẫn demo online |

Ba loại người dùng:

| Vai trò | Làm được gì |
|---|---|
| **Người dùng** (`USER`) | Mua sách, đấu giá. Mở shop thì thành người bán, ký gửi sách. Một tài khoản làm được cả ba việc |
| **Nhân viên kho** (`STAFF`) | Duyệt sơ bộ ký gửi, nhận sách tại kho, kiểm định, quản lý kho, xử lý đơn đấu giá |
| **Quản trị** (`ADMIN`) | Duyệt tin đăng, quản lý người dùng và danh mục, tạo phiên đấu giá, cấu hình phí, duyệt rút tiền, xử lý khiếu nại |

---

## 2. Chạy thử nhanh

### Cách 1: chạy không cần backend (dữ liệu giả)

Chỉ cần Flutter 3.47.x. Chạy trong `apps/frontend`:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run -d chrome --dart-define-from-file=env/dev.json
```

Chế độ này dùng backend giả trong bộ nhớ, có cả phiên đấu giá chạy thật với người trả giá ảo. Tài khoản mẫu của chế độ này nằm trong [apps/frontend/README.md](apps/frontend/README.md).

### Cách 2: chạy đầy đủ (backend + PostgreSQL thật)

Cần JDK 21+ và PostgreSQL chạy ở `localhost:5432`.

```bash
# Tạo user + database (một lần, bằng tài khoản postgres)
psql -U postgres -h localhost -f apps/backend/scripts/create-database.sql

# Chạy backend (tự tạo bảng và nạp dữ liệu mẫu)
cd apps/backend
./mvnw spring-boot:run
```

Đợi thấy dòng `Started ReBookApplication`. Kiểm tra bằng cách mở <http://localhost:8080/categories> (ra JSON là được). Swagger UI ở <http://localhost:8080/swagger-ui.html>.

Sau đó chạy frontend trong `apps/frontend`:

```bash
# App người dùng trên Chrome
flutter run -d chrome --dart-define-from-file=env/local.json

# App người dùng trên máy ảo Android
flutter run -d emulator-5554 --dart-define-from-file=env/android.local.json

# Web quản trị (Staff, Admin)
flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/local.json
```

> Nên dùng **hai cửa sổ**: một cho admin, một cho người mua (hoặc cửa sổ ẩn danh), để khỏi đăng xuất liên tục.

### Cách 3: cho bạn bè ở xa vào xem bằng một link

Chạy backend rồi nhấp đúp `demo\start-demo.cmd`. Script mở ra Internet một link dạng `https://xxxx.trycloudflare.com`. Hướng dẫn chi tiết: [docs/DEMO_ONLINE.md](docs/DEMO_ONLINE.md).

### Làm lại dữ liệu mẫu từ đầu

Tắt backend, rồi chạy:

```bash
psql -U postgres -h localhost -c "DROP DATABASE rebook_dev;" -c "CREATE DATABASE rebook_dev OWNER rebook ENCODING 'UTF8' TEMPLATE template0;"
```

Bật lại backend, nó tự tạo bảng và nạp lại dữ liệu mẫu.

---

## 3. Tài khoản mẫu

Với backend thật, mật khẩu chung là **`Rebook@123`**.

| Email | Vai trò | Ghi chú |
|---|---|---|
| `buyer1@rebook.vn` | Người mua | Ví khoảng 4,9 triệu, đã đăng ký và đặt cọc phiên đấu giá #1 |
| `buyer2@rebook.vn`, `buyer3@rebook.vn` | Người mua | Ví 3 đến 5 triệu, cũng đã đăng ký phiên #1 |
| `seller1@rebook.vn` | Người bán | Shop "Nhà Sách Cũ Sài Gòn" (HCM, uy tín), 6 tin đăng, 4 yêu cầu ký gửi |
| `seller2@rebook.vn` | Người bán | Shop "Tiệm Sách Hà Nội Xưa" (Hà Nội), 1 tin chờ duyệt |
| `staff@rebook.vn` | Nhân viên kho | |
| `admin@rebook.vn` | Quản trị | |

Dữ liệu mẫu có: 10 danh mục, 16 sách, 9 tin đăng (mỗi tin còn từ 3 đến 8 cuốn để thử mua nhiều cuốn), 3 đơn hàng, 7 yêu cầu ký gửi ở các bước khác nhau và 1 phiên đấu giá 3 lô.

---

## 4. Hướng dẫn sử dụng

### 4.1 Đăng ký, đăng nhập và tài khoản

- **Đăng ký**: nhập họ tên, email, mật khẩu. Hệ thống gửi mã **OTP** để xác thực email. *Cần xác thực email mới đặt hàng được.*
- **Đăng nhập**: dùng email và mật khẩu. Phiên đăng nhập tự gia hạn, không phải đăng nhập lại liên tục.
- **Quên mật khẩu**: nhập email, nhận mã OTP, đặt mật khẩu mới.
- **Hồ sơ**: đổi họ tên, số điện thoại, ảnh đại diện.
- **Sổ địa chỉ**: thêm nhiều địa chỉ nhận hàng, chọn một địa chỉ mặc định.
- **Thông báo**: biểu tượng chuông hiện các sự kiện như đơn đổi trạng thái, bị người khác trả giá vượt, trúng đấu giá.
- **Cài đặt**: đổi ngôn ngữ và các tuỳ chọn hiển thị.

> Môi trường dev chưa gửi email thật. Mã OTP hiện trong phản hồi của API (trường `devOtp`) và ghi trong log backend.

### 4.2 Tìm và xem sách

- **Trang chủ**: băng chuyền nổi bật, sách đang được quan tâm, sách mới lên kệ, kệ theo danh mục.
- **Tìm kiếm**: gõ tên sách hoặc tác giả; lọc theo danh mục, tình trạng sách, khoảng giá; sắp xếp theo mới nhất, giá tăng, giá giảm, bán chạy.
- **Chi tiết sách**: ảnh bìa, tình trạng, giá, số cuốn còn lại, mô tả và thông tin shop (điểm đánh giá). Bấm vào tên shop để xem toàn bộ sách của shop đó.
- Khách chưa đăng nhập vẫn xem được sách, shop và lịch phiên đấu giá.

### 4.3 Giỏ hàng và đặt hàng

1. Ở trang chi tiết, chọn **số lượng** rồi bấm **Thêm vào giỏ**. Không thêm quá số cuốn còn lại, và không mua được sách của chính shop mình.
2. Vào **Giỏ hàng**: sách được **chia theo shop**. Bạn có thể đổi số lượng hoặc xoá từng dòng.
3. **Một giỏ có thể chứa sách của nhiều shop.** Khi đặt hàng, hệ thống **tự tách thành mỗi shop một đơn**, mỗi đơn có phí ship riêng và được giao riêng.
4. **Chọn sách muốn mua**: bạn không cần mua hết giỏ. Chỉ những sách được chọn mới vào đơn, phần còn lại vẫn nằm trong giỏ cho lần sau.
5. **Thanh toán**: chọn địa chỉ nhận hàng, xem phí ship, chọn phương thức:
   - **COD**: trả tiền khi nhận hàng.
   - **Ví ReBook**: trừ thẳng vào ví (cần đủ số dư).
   - **VNPay**: thanh toán qua cổng VNPay (môi trường dev dùng nút giả lập thanh toán thành công).
6. Đơn chưa thanh toán sẽ **tự huỷ sau 15 phút**. Hàng được giữ ngay khi đặt, nên nếu người khác vừa mua hết, bạn sẽ nhận thông báo hết hàng.

**Phí ship**: tính theo tỉnh gửi và tỉnh nhận (nội tỉnh rẻ hơn liên tỉnh) cộng thêm theo khối lượng sách.

### 4.4 Theo dõi đơn, nhận hàng, đánh giá, trả hàng

Vào **Đơn mua** để xem các đơn và trạng thái:

`Chờ thanh toán → Chờ xác nhận → Đang chuẩn bị → Đang giao → Đã giao → Hoàn tất`

Ngoài ra có các nhánh **Huỷ**, **Trả hàng** và **Giao thất bại**.

- **Huỷ đơn**: được phép khi đơn chưa giao. Nếu shop đã bắt đầu chuẩn bị thì gửi yêu cầu huỷ để shop đồng ý.
- **Xác nhận đã nhận hàng**: đơn hoàn tất, lúc này tiền mới chuyển cho người bán (đã trừ phí sàn). Nếu bạn không bấm gì, đơn **tự hoàn tất sau 3 ngày** kể từ khi giao.
- **Đánh giá shop**: chấm sao và viết nhận xét sau khi đơn hoàn tất.
- **Yêu cầu trả hàng**: khi hàng không đúng mô tả, gửi yêu cầu kèm lý do và ảnh. Người bán đồng ý hoặc từ chối; nếu hai bên không thống nhất, **quản trị viên phân xử** ở mục Khiếu nại.

### 4.5 Ví ReBook

- Ví có hai số: **khả dụng** (dùng được ngay) và **đang giữ** (tiền cọc đấu giá, tiền chờ giải ngân, tiền đang chờ duyệt rút).
- **Nạp tiền**: tạo giao dịch nạp qua VNPay (dev có nút giả lập thành công).
- **Lịch sử giao dịch**: mỗi dòng là một bút toán (nạp, thanh toán, hoàn tiền, cọc, phí...). Sổ cái chỉ ghi thêm, không sửa được.
- **Rút tiền** (người bán):
  1. Nhập số tiền (tối thiểu **50.000đ**) và thông tin ngân hàng nhận tiền (tên ngân hàng, số tài khoản, chủ tài khoản).
  2. Số tiền được **giữ lại** ngay trong ví trong lúc chờ duyệt.
  3. Quản trị viên chuyển khoản thủ công rồi duyệt. Khi duyệt, hệ thống lưu **biên lai chuyển khoản** (người chuyển, giờ chuyển, số tiền, ảnh biên lai) và trừ tiền khỏi ví của bạn.
  4. Nếu bị **từ chối**, tiền được trả lại số dư khả dụng.
  5. Theo dõi trạng thái ở danh sách yêu cầu rút tiền của bạn.

### 4.6 Đấu giá

**Khái niệm chính**

- Một **phiên** có nhiều **lô**, mỗi lô là một cuốn sách. Các lô chạy lần lượt, mặc định **60 giây mỗi lô**.
- Muốn trả giá phải **đăng ký phiên và đặt cọc** trước hạn đăng ký. Sau hạn đó không đăng ký được nữa.
- **Hạn mức trả giá = tiền cọc × 10.**
- **Bước giá** tăng theo mốc: dưới 200 nghìn nhảy 10 nghìn; từ 200 nghìn nhảy 50 nghìn; từ 1 triệu nhảy 100 nghìn; từ 5 triệu nhảy 500 nghìn.
- **Soft close**: nếu có người trả giá khi còn dưới **15 giây**, đồng hồ được kéo lại 15 giây. Cách này chống "bắn tỉa" phút chót.
- **Giá sàn (reserve)**: mức giá thấp nhất người bán chấp nhận. Hết giờ mà chưa tới giá sàn thì lô **không bán được**.
- **Trả giá tự động (proxy bid)**: bạn đặt mức tối đa, hệ thống tự đáp giá thay bạn tới mức đó. Đặt được cả trước khi lô mở.
- Đồng hồ do **server giữ**, app chỉ đếm ngược theo giờ server, nên máy nào cũng khớp.
- Tên người trả giá được ẩn, chỉ hiện **số paddle** (ví dụ `#027`).

**Cách tham gia**

1. Vào **Đấu giá**, chọn một phiên sắp diễn ra.
2. Bấm **Đăng ký và đặt cọc**. Tiền cọc được khoá trong ví của bạn.
3. Đến giờ, phiên **tự bắt đầu** nếu đủ số người đăng ký tối thiểu (nếu thiếu người, phiên được dời lịch hoặc huỷ và cọc được hoàn).
4. Vào **phòng đấu giá**: xem lô đang mở, giá hiện tại, đồng hồ, danh sách lượt trả giá. Bấm **Trả giá** hoặc đặt **trả giá tự động**. Mọi người trong phòng thấy giá thay đổi ngay.
5. Hết giờ, người trả cao nhất thắng lô. Xem **Kết quả** từng lô, và **Đấu giá của tôi** để xem các phiên đã đăng ký.

**Sau khi thắng**

- Bạn phải **thanh toán trong 48 giờ**, trả thêm **phí người mua 10%**. Tiền cọc được trừ vào hoá đơn.
- Không thanh toán: **mất cọc** (chia đôi cho người bán và sàn), **bị cấm đấu giá 90 ngày**, và người trả giá cao thứ hai được mời mua lại.
- Người không thắng được **hoàn cọc** khi phiên kết thúc.

### 4.7 Mở shop và bán sách

1. **Mở shop**: vào Kênh người bán, nhập tên shop, mô tả, địa chỉ lấy hàng, tỉnh và tài khoản ngân hàng nhận tiền.
2. **Đăng tin**: chọn sách (tên, tác giả, nhà xuất bản, năm, danh mục, tình trạng, mô tả, khối lượng), nhập **giá** và **số lượng tồn kho**, thêm ảnh (tối thiểu 3 ảnh).
   - Shop **uy tín** được tự duyệt tin. Shop mới thì tin vào hàng chờ **admin duyệt**; nếu bị từ chối bạn thấy lý do và có thể sửa lại.
3. **Quản lý tin**: sửa giá, sửa tồn kho, **ẩn / hiện** tin. Tin hết hàng tự chuyển sang "Hết hàng" và tự bán lại khi bạn nhập thêm.
4. **Xử lý đơn**: đơn mới ở trạng thái *Chờ xác nhận*. Bạn **xác nhận** (trong 24 giờ, quá hạn đơn tự huỷ), **giao hàng** (nhập mã vận đơn), rồi đánh dấu **đã giao**.
5. **Thống kê**: doanh thu, số đơn chờ xác nhận, số đơn đang giao.
6. Phí sàn được trừ khi đơn hoàn tất (mặc định 5%, admin chỉnh được).

### 4.8 Ký gửi sách đi đấu giá

Dành cho sách quý, giá trị cao. Chuỗi bước:

**Gửi yêu cầu → Sơ duyệt → Đặt lịch hẹn → Mang sách tới kho → Kiểm định → Người bán chấp nhận → Lên lô đấu giá**

1. **Tạo yêu cầu ký gửi**: nhập thông tin sách, ảnh, **giá mong muốn** (tối thiểu **300.000đ**) và câu chuyện, nguồn gốc cuốn sách.
2. **Nhân viên sơ duyệt**: đạt hoặc không đạt (kèm lý do).
3. **Đặt lịch hẹn** mang sách tới kho: trong vòng **7 ngày**, giờ nhận **8:00 đến 17:00**. Bạn nhận một **mã lịch hẹn** để đưa cho nhân viên. Quá hạn mà không đến, lịch hẹn tự hết hiệu lực.
4. **Nhân viên nhận sách** tại kho (nhập mã lịch hẹn) và **kiểm định**.
5. Xem **kết quả kiểm định** (tình trạng, giá ước tính, giá khởi điểm và giá sàn đề xuất) rồi chọn:
   - **Đồng ý**: sách thành lô sẵn sàng để admin xếp vào phiên.
   - **Đề xuất giá sàn khác**.
   - **Rút lại**: nhận sách về.
6. Nếu lô **không bán được**, bạn chọn: đưa vào phiên sau, chuyển sang **bán giá cố định** trong shop, hoặc nhận sách về.
7. **Phí lưu kho**: miễn phí 14 ngày đầu, sau đó 5.000đ mỗi ngày mỗi cuốn.
8. Khi lô bán được, người bán nhận tiền sau khi trừ **hoa hồng 15%**.

### 4.9 Nhân viên kho (Staff)

Đăng nhập `staff@rebook.vn` ở web quản trị.

- **Ký gửi**: danh sách yêu cầu chờ sơ duyệt, duyệt đạt hoặc không đạt kèm lý do.
- **Lịch hẹn**: nhập mã lịch hẹn của người bán để **nhận sách (check-in)** và gán vị trí kệ trong kho.
- **Kiểm định**: tick checklist (đủ trang, đúng ấn bản, bìa, gáy, ẩm mốc, chữ ký...), chấm tình trạng, ước giá thấp và cao, đề xuất giá khởi điểm và giá sàn, chụp ảnh, kết luận đạt hoặc không.
- **Kho**: xem sách đang lưu, vị trí, số ngày lưu kho.
- **Đơn đấu giá**: xử lý đóng gói, giao các đơn của lô đã bán.

### 4.10 Quản trị viên (Admin)

Đăng nhập `admin@rebook.vn` ở web quản trị.

| Mục | Làm gì |
|---|---|
| **Tổng quan** | Doanh thu tháng, số đơn, tin chờ duyệt, phiên đang chạy, tỷ lệ lô bán được, số dư ví sàn |
| **Tin đăng** | Duyệt hoặc từ chối tin chờ duyệt (từ chối phải có lý do) |
| **Người dùng** | Tìm kiếm, **khoá / mở khoá** tài khoản (khoá cần lý do, người bị khoá bị đăng xuất ngay), đổi vai trò, gỡ lệnh cấm đấu giá, đánh dấu shop **uy tín** |
| **Danh mục** | Thêm, sửa, xoá danh mục dạng cây (danh mục còn con thì không xoá được) |
| **Phiên đấu giá** | Tạo phiên, xếp lô, công bố, **tạm dừng / tiếp tục**, theo dõi phiên đang chạy |
| **Cấu hình** | Phí sàn, phí người mua, hoa hồng, phí kho, bước giá, thời hạn thanh toán... Sửa là áp dụng cho giao dịch sau đó |
| **Rút tiền** | Xem yêu cầu chờ duyệt và lịch sử đã xử lý (kèm tên admin duyệt, thời gian duyệt) |
| **Khiếu nại** | Phân xử yêu cầu trả hàng |
| **Lịch sử hoạt động** | Nhật ký mọi thao tác của admin: ai làm gì, lúc nào |

**Duyệt yêu cầu rút tiền**

1. Chuyển khoản thủ công cho người rút theo thông tin ngân hàng họ khai.
2. Khi duyệt, nhập thông tin chuyển khoản: **người chuyển** (tài khoản của sàn), **giờ chuyển thực tế**, **số tiền thực chuyển** (phải bằng số tiền yêu cầu rút), và **ảnh biên lai** (tải lên, tối đa 5MB, PNG / JPEG / WebP).
3. Hệ thống ghi **hai bản ghi** trong cùng một giao dịch: bút toán trừ tiền trong ví người rút, và biên lai chuyển khoản kèm mã admin duyệt. Trạng thái yêu cầu chuyển sang đã duyệt.
4. Có thể **từ chối** kèm ghi chú; tiền được hoàn về ví người rút.
5. Mỗi yêu cầu chỉ duyệt được một lần, hai admin không thể cùng duyệt.

**Nhật ký hoạt động admin** ghi lại: duyệt hoặc từ chối tin đăng, duyệt hoặc từ chối rút tiền, khoá và mở khoá tài khoản, đổi vai trò, gỡ cấm đấu giá, đánh dấu shop uy tín, đổi cấu hình. Có thể lọc theo loại đối tượng, hành động và người thực hiện.

---

## 5. Các quy tắc cần biết

| Nội dung | Giá trị mặc định |
|---|---|
| Hạn thanh toán đơn thường | 15 phút |
| Hạn shop xác nhận đơn | 24 giờ |
| Tự hoàn tất đơn sau khi giao | 3 ngày |
| Phí sàn cho đơn giá cố định | 5% |
| Nạp tối thiểu / rút tối thiểu | 10.000đ / 50.000đ |
| Giá mong muốn tối thiểu khi ký gửi | 300.000đ |
| Hạn mức trả giá | Tiền cọc × 10 |
| Soft close | Còn dưới 15 giây thì kéo về 15 giây |
| Hạn thanh toán sau khi thắng đấu giá | 48 giờ |
| Phí người mua / hoa hồng người bán (đấu giá) | 10% / 15% |
| Cấm đấu giá khi bỏ thanh toán | 90 ngày |
| Lưu kho miễn phí / phí sau đó | 14 ngày / 5.000đ mỗi ngày mỗi cuốn |

Admin chỉnh được các con số này ở mục **Cấu hình**.

---

## 6. Câu hỏi thường gặp

**Mua hai cuốn của hai shop khác nhau được không?**
Được. Bỏ cả hai vào giỏ; khi đặt hàng hệ thống tự tách thành hai đơn, mỗi đơn một shop, phí ship tính riêng.

**Tôi chỉ muốn mua một vài cuốn trong giỏ?**
Chọn những cuốn muốn mua ở bước thanh toán. Các cuốn còn lại vẫn ở trong giỏ.

**Sao tôi không thêm được nhiều cuốn vào giỏ?**
Mỗi tin có số lượng tồn kho giới hạn. Thông báo "Chỉ còn N cuốn" cho biết số tối đa bạn mua được.

**Tiền của tôi đi đâu khi mua hàng?**
Vào ví sàn ở trạng thái "giữ". Chỉ khi bạn nhận hàng (hoặc sau 3 ngày tự hoàn tất), tiền mới chuyển cho người bán.

**Hai người cùng trả đúng một mức giá thì sao?**
Người đến sau nhận thông báo "giá đã thay đổi" và trả lại theo giá mới. Hệ thống không bao giờ bán trùng một lô.

**Tôi thắng đấu giá nhưng chưa có tiền?**
Hãy nạp ví và thanh toán trong 48 giờ. Quá hạn bạn sẽ mất cọc và bị cấm đấu giá 90 ngày.

**Tôi quên mã OTP / không nhận được mã?**
Môi trường dev không gửi email thật. Mã nằm trong log backend (hoặc trường `devOtp` trong phản hồi API).

**Đăng nhập báo sai mật khẩu?**
Mật khẩu mẫu là `Rebook@123`, phân biệt hoa thường. Với chế độ dữ liệu giả (`USE_MOCK`), mật khẩu là `123456`.

**App quay mãi hoặc báo lỗi mạng?**
Backend chưa chạy hoặc sai cổng. Kiểm tra <http://localhost:8080/categories>. Trên máy ảo Android phải dùng `env/android.local.json` (địa chỉ `10.0.2.2`).

**Báo "Cổng 8080 đang được sử dụng"?**
Đang có một backend khác chạy sẵn. Dùng luôn bản đó hoặc tắt rồi chạy lại.

**Đấu giá báo "chưa đăng ký" hoặc "vượt hạn mức"?**
Tài khoản đang dùng chưa đăng ký và đặt cọc cho phiên đó, hoặc tiền cọc chưa đủ (hạn mức bằng cọc nhân 10).

**Phiên không tự bắt đầu?**
Chưa tới giờ hoặc chưa đủ người đăng ký. Admin có thể bắt đầu ngay bằng `POST /admin/sessions/{id}/start` ở Swagger, hoặc chạy `powershell -File demo\start-auction.ps1 -Session 1`.

**Đọc log backend ở đâu?**
Backend chạy trong IntelliJ thì xem cửa sổ **Run** (Alt+4) hoặc **Services** (Alt+8). Chạy bằng `./mvnw spring-boot:run` thì log in ngay trong terminal đó.

---

## 7. Tài liệu cho lập trình viên

- Backend: [apps/backend/README.md](apps/backend/README.md): cấu trúc module, điểm nghiệp vụ chính, realtime WebSocket, cách chạy test (`./mvnw test`).
- Frontend: [apps/frontend/README.md](apps/frontend/README.md), [apps/frontend/docs/ARCHITECTURE.md](apps/frontend/docs/ARCHITECTURE.md), [apps/frontend/docs/DECISIONS.md](apps/frontend/docs/DECISIONS.md).
- Hợp đồng API giữa frontend và backend: `apps/frontend/openapi/openapi.yaml`. Spec do backend sinh ra: `apps/backend/openapi.yaml` (xuất từ `/v3/api-docs.yaml`).
- Kịch bản demo và câu hỏi hay gặp: [docs/DEMO.md](docs/DEMO.md). Chạy online cho bạn bè: [docs/DEMO_ONLINE.md](docs/DEMO_ONLINE.md).
- Đặc tả nghiệp vụ gốc: [apps/frontend/docs/SRS.txt](apps/frontend/docs/SRS.txt).

### Những điểm còn giả lập

- **VNPay**: chưa nối cổng thật; dùng nút giả lập thanh toán thành công ở môi trường dev.
- **Email / SMS OTP**: chưa gửi thật.
- **Vận chuyển**: giả lập bằng nút bấm (đã giao, giao thất bại), chưa nối hãng vận chuyển.
- **Thông báo đẩy (FCM)**: chưa làm; thông báo trong app đi qua WebSocket.
- **Biên lai rút tiền**: backend đã nhận đủ thông tin và ảnh biên lai (`POST /files`, `POST /admin/withdrawals/{id}`), màn hình quản trị trên app đang được bổ sung form nhập tương ứng.
- Bộ máy chạy phiên đấu giá chỉ chạy đúng với **một** bản backend.
