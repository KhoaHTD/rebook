# ReBook — Kịch bản demo (đọc để thuộc)

## 1. App này là gì (nói 30 giây đầu)

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

## 2. Chuẩn bị TRƯỚC giờ demo (làm tối nay, đừng để sáng mai)

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
- Dữ liệu mẫu chỉ có **một phiên đấu giá đã kết thúc**. Muốn demo đấu giá live thì **phải tạo phiên mới** (mục 3.5). Tập trước ít nhất một lần.
- Dùng **hai cửa sổ**: Chrome cho admin, máy ảo (hoặc cửa sổ ẩn danh) cho người mua. Như vậy không phải đăng xuất liên tục.
- Cắm sạc, tắt thông báo hệ thống, phóng to chữ nếu chiếu lên máy chiếu.

---

## 3. Các luồng demo (theo thứ tự nên trình bày)

### 3.1. Mua hàng giá cố định (`buyer1`) — luồng cơ bản, mở màn

1. Mở app → trang giới thiệu → **Đăng nhập** `buyer1@rebook.vn`.
2. **Mua sách** (trang chủ): băng chuyền, "Đang được săn", "Mới lên kệ", kệ theo danh mục ở thanh bên.
3. **Tìm kiếm**: gõ tên sách, lọc theo danh mục, tình trạng sách, khoảng giá; sắp xếp mới nhất / giá tăng / giá giảm / bán chạy.
4. Bấm vào một cuốn → **chi tiết**: ảnh bìa, tình trạng, giá, shop (điểm đánh giá), mô tả → **Thêm vào giỏ**.
5. **Giỏ hàng**: giỏ chia theo shop, đổi số lượng, xóa. Nhớ: tin chỉ còn 1 cuốn thì không tăng được.
6. **Thanh toán**: chọn địa chỉ nhận → app hiện **phí ship** (nội tỉnh rẻ hơn liên tỉnh, tính theo khối lượng) → chọn phương thức:
   - **COD** (trả khi nhận), **Ví ReBook**, hoặc **VNPay**.
   - Demo nên chọn **Ví ReBook** (nhanh, không cần cổng ngoài). buyer1 có ví khoảng 4,9 triệu.
7. Đặt xong, hệ thống **tách đơn theo shop**. Vào **Đơn mua** xem trạng thái.

> Điểm nói: "Giỏ nhiều shop thì tự tách thành nhiều đơn, mỗi shop giao riêng."

### 3.2. Người bán xử lý đơn (`seller1`)

1. Đăng nhập `seller1`. **Kênh người bán**: thống kê (doanh thu, đơn chờ xác nhận, đang giao…).
2. **Đơn của shop**: đơn mới ở trạng thái *Chờ xác nhận* → **Xác nhận** → **Giao hàng** (nhập mã vận đơn) → **Đã giao**.
3. **Tin đăng**: xem 6 tin, thêm tin mới (cần tối thiểu 3 ảnh), sửa tồn kho, ẩn / hiện tin.
   - Shop **uy tín** (seller1) thì tin **tự duyệt**. Shop mới thì tin vào hàng chờ admin duyệt.

> Vòng đời đơn: `Chờ thanh toán → Chờ xác nhận → Đang chuẩn bị → Đang giao → Đã giao → Hoàn tất`. Có nhánh Hủy, Trả hàng, Giao thất bại.

### 3.3. Hoàn tất đơn, đánh giá, trả hàng (quay lại `buyer1`)

1. **Đơn mua** → mở đơn đã giao → **Xác nhận đã nhận hàng**. Đơn hoàn tất, **tiền mới chuyển từ "giữ" sang ví người bán** (trừ phí sàn 5%).
2. **Đánh giá** shop (sao + nhận xét) sau khi hoàn tất.
3. Hoặc **Yêu cầu trả hàng** (kèm lý do, ảnh) khi hàng không đúng mô tả. Người bán đồng ý / từ chối; không đồng thuận thì **admin phân xử** ở mục Khiếu nại.
4. Nếu không bấm gì, đơn **tự hoàn tất sau 3 ngày**.

> Điểm nói: "Đây là escrow: tiền chưa vào tay người bán cho tới khi người mua nhận hàng."

### 3.4. Ví ReBook (`buyer1`)

- **Ví ReBook**: số dư khả dụng và số dư đang bị giữ (đặt cọc đấu giá, tiền chờ giải ngân).
- **Nạp tiền**: tạo giao dịch nạp; môi trường dev có nút **giả lập thanh toán thành công** (không cần VNPay thật).
- **Lịch sử giao dịch**: mỗi dòng là một bút toán (nạp, thanh toán, hoàn tiền, cọc, phí…). Sổ cái **chỉ ghi thêm, không sửa**.
- Người bán có thêm **Rút tiền** (dùng tài khoản ngân hàng đã khai khi mở shop), admin duyệt sau.

### 3.5. ĐẤU GIÁ TRỰC TIẾP — phần ăn điểm nhất, tập kỹ

**Khái niệm cần nói được:**
- Phiên có nhiều **lô**, mỗi lô chạy tuần tự, mặc định **60 giây/lô**.
- Muốn trả giá phải **đăng ký phiên và đặt cọc** trước. **Hạn mức trả giá = tiền cọc × 10.**
- **Bước giá** tăng theo mốc: dưới 200k nhảy 10k; từ 200k nhảy 50k; từ 1 triệu nhảy 100k; từ 5 triệu nhảy 500k.
- **Soft close**: trả giá khi còn dưới 15 giây thì đồng hồ **được kéo lại 15 giây** (chống "bắn tỉa" phút chót).
- **Giá sàn (reserve)**: giá thấp nhất người bán chấp nhận. Gõ búa mà chưa tới sàn thì lô **không bán được**.
- **Trả giá tự động (proxy bid)**: đặt mức tối đa, hệ thống tự đáp thay mình tới mức đó.
- **Người trả giá cao nhất khi hết giờ thắng.** Phải thanh toán trong **48 giờ**; bỏ thanh toán thì **mất cọc** (chia 50/50 người bán và sàn) và **bị cấm đấu giá 90 ngày**, người trả giá cao thứ hai được mời mua lại.
- Người thắng trả thêm **phí người mua 10%**, người bán trả **hoa hồng 15%**.
- Đồng hồ do **server giữ**, app chỉ đếm ngược theo giờ server (nên chạy máy nào cũng khớp).

**Cách chuẩn bị một phiên LIVE (làm trước khi demo vài phút):**

1. Đăng nhập `admin@rebook.vn` → **Phiên đấu giá** → **Tạo phiên**:
   - Tên, mô tả; **giờ bắt đầu** là vài phút nữa; **hạn đăng ký** trước giờ bắt đầu; số người tối thiểu **1**; tiền cọc ví dụ **500.000**; thời gian mỗi lô **30 giây** cho nhanh.
2. **Xếp lô**: chọn lô "sẵn sàng" (lô đã kiểm định và chờ xếp phiên) vào phiên.
3. **Công bố** phiên.
4. Đăng nhập `buyer1` (cửa sổ khác) → **Đấu giá** → vào phiên → **Đăng ký + đặt cọc**.
5. Đến giờ bắt đầu, hệ thống **tự mở phiên** (đủ người đăng ký). Muốn bắt đầu ngay: mở `http://localhost:8080/swagger-ui.html`, đăng nhập admin lấy token, bấm Authorize, gọi `POST /admin/sessions/{id}/start`.

**Trình diễn:**
1. `buyer1` vào **phòng đấu giá**: thấy lô đang mở, giá hiện tại, đồng hồ đếm ngược, danh sách người trả giá (hiện số paddle `#001`, không lộ tên).
2. Bấm **Trả giá** → giá nhảy lên ngay. Cửa sổ khác cũng cập nhật ngay (**WebSocket**).
3. Đặt **trả giá tự động** một mức cao hơn để minh họa proxy bid.
4. Trả giá phút chót để thấy **soft close** kéo đồng hồ.
5. Hết giờ: lô **bán / không bán** (chưa tới giá sàn). Sang lô kế tiếp.
6. Hết phiên: xem **Kết quả** từng lô; "Đấu giá của tôi" hiện các phiên đã đăng ký.
7. Admin có thể **Tạm dừng / Tiếp tục** phiên (nhắc: dùng khi có sự cố).

> Nếu bị hỏi "hai người cùng trả đúng một mức thì sao": người đến sau nhận lỗi *giá đã thay đổi* (khóa lạc quan trong DB), không bao giờ bán trùng.

### 3.6. Ký gửi sách đi đấu giá (`seller1` → `staff`) — luồng nghiệp vụ dài, kể bằng lời kết hợp 2-3 màn hình

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

### 3.7. Quản trị (`admin`)

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

### 3.8. Việc phụ nên lướt qua

- **Đăng ký tài khoản**: nhập thông tin → nhận mã **OTP** xác thực email. Môi trường dev không gửi mail thật nên mã in ở **log backend** (có dòng `devOtp`). Chuẩn bị sẵn mã trước nếu định demo.
- **Thông báo**: chuông ở thanh bên, hiện sự kiện đơn hàng, bị trả giá vượt, trúng đấu giá…
- **Hồ sơ / Địa chỉ**: sửa tên, SĐT, quản lý nhiều địa chỉ, chọn mặc định.
- **Giao diện**: kiểu **Liquid Glass** (kính mờ), chạy **responsive**: màn rộng có thanh bên, điện thoại có thanh tab dưới. Thu nhỏ cửa sổ Chrome để cho thấy.
- **Đổi ngôn ngữ**: vi / en trong Cài đặt (nếu có mục đó).

---

## 4. Thứ tự demo gợi ý (khoảng 10–12 phút)

| Phút | Nội dung |
|---|---|
| 0–1 | Giới thiệu app + 3 vai trò |
| 1–4 | **3.1 + 3.2 + 3.3**: mua, người bán xử lý, hoàn tất (nhấn escrow) |
| 4–9 | **3.5 Đấu giá live** (admin Chrome + buyer máy ảo cạnh nhau) |
| 9–11 | **3.6 Ký gửi** (kể ngắn, chỉ mở 2–3 màn của staff và seller) |
| 11–12 | **3.7 Admin**: cấu hình phí, duyệt tin; kết luận |

Nếu thiếu giờ, **bỏ 3.6 và 3.8**, giữ đấu giá.

---

## 5. Câu hỏi hay gặp & cách trả lời

| Hỏi | Trả lời |
|---|---|
| Hai người trả giá cùng lúc? | Mỗi lô có số phiên bản (khóa lạc quan). Người trả sau bị báo "giá đã thay đổi". |
| Chống bắn tỉa phút chót? | Soft close: còn dưới 15 giây mà có người trả thì đồng hồ về 15 giây. |
| Tiền người mua đi đâu? | Vào ví sàn, giữ ở trạng thái "held", chỉ giải ngân cho người bán khi hoàn tất đơn. |
| Người thắng không trả tiền? | Mất cọc (50% người bán, 50% sàn), bị cấm đấu giá 90 ngày, người trả cao thứ hai được mời mua lại. |
| Realtime làm bằng gì? | WebSocket thuần, server gửi JSON `LOT_OPENED`, `BID_PLACED`, `LOT_CLOSED`… Mất mạng thì tự nối lại và tải lại trạng thái. |
| Bảo mật đăng nhập? | JWT access token ngắn hạn + refresh token xoay vòng; mật khẩu băm BCrypt; phân quyền USER / STAFF / ADMIN ở backend. |
| Sao frontend gọi API gọn vậy? | Client được sinh tự động từ OpenAPI; backend đổi API thì sinh lại, không viết tay. |
| Số tiền có sai số không? | Dùng `BigDecimal` / `NUMERIC(15,0)`, mọi thay đổi số dư khóa dòng ví và ghi sổ cái bất biến. |
| Có chạy được trên điện thoại thật? | Cùng một codebase Flutter, đã chạy thử trên web và máy ảo Android. |

---

## 6. Những điều KHÔNG nên hứa / nên nói thật (tránh bị hỏi vặn)

- **VNPay** chưa nối cổng thật: dùng nút giả lập thanh toán thành công (chế độ dev).
- **Email / SMS OTP**: chưa gửi thật, mã hiện ở log / phản hồi dev.
- **Upload ảnh**: backend chưa có dịch vụ lưu ảnh (Cloudinary). Ảnh người dùng chọn hiện được trên máy nhưng gửi lên server là **ảnh mẫu thay thế**.
- **Vận chuyển**: giả lập bằng nút bấm (đã giao / giao thất bại), chưa nối hãng vận chuyển.
- **Thông báo đẩy (FCM)**: chưa làm; thông báo trong app qua WebSocket.
- **Trang chủ, thống kê người bán**: backend không có endpoint riêng, app tự ghép từ danh sách tin / đơn.
- Bộ máy chạy phiên đấu giá chỉ chạy đúng với **một** bản backend.

---

## 7. Sự cố thường gặp ngay lúc demo

| Hiện tượng | Xử lý |
|---|---|
| App quay mãi / lỗi mạng | Backend chưa chạy hoặc sai cổng. Kiểm tra `http://localhost:8080/categories`. |
| Máy ảo không vào được API | Phải chạy bằng `env/android.local.json` (dùng `10.0.2.2`). |
| "Cổng 8080 đang được sử dụng" | Còn một backend cũ đang chạy. Dùng luôn bản đó hoặc tắt rồi chạy lại. |
| Đấu giá báo "chưa đăng ký" | Quên đăng ký + cọc phiên cho tài khoản đang dùng. |
| Phiên không tự bắt đầu | Chưa đủ người đăng ký, hoặc chưa tới giờ. Dùng Swagger gọi `POST /admin/sessions/{id}/start`. |
| Trả giá bị từ chối "vượt hạn mức" | Cọc chưa đủ (hạn mức = cọc × 10). Đặt cọc thêm. |
| Đăng nhập báo sai mật khẩu | Mật khẩu mẫu là `Rebook@123` (phân biệt hoa thường). |
| Dữ liệu lộn xộn sau nhiều lần test | Chạy lại lệnh **làm sạch dữ liệu** ở mục 2. |
