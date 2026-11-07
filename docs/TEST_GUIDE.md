# ReBook — Hướng dẫn test theo vai người dùng

Cập nhật 04/11/2026 · Khoa. Bản sống (bình luận, ghi lỗi trực tiếp): [Claude Docs](https://claude.ai/artifact/JY6erATfWUB7QMgEB86Fic)

## Cách dùng tài liệu này

Mỗi tester đóng một vai (khách, người mua, người bán, người đấu giá, nhân viên kho, quản trị), đăng nhập đúng tài khoản của vai đó rồi làm theo kịch bản. Mỗi bước có **kết quả mong đợi**; thấy khác thì báo lỗi theo mẫu ở cuối tài liệu.

- Làm theo thứ tự các vai: nhiều kịch bản dùng lại kết quả của vai trước (ví dụ người bán đăng tin → admin duyệt → người mua mới thấy).
- Mọi tài khoản mẫu dùng chung mật khẩu `Rebook@123`.
- Thanh toán chỉ là **sandbox** (tiền giả), dùng thẻ test ở mục Thanh toán thử.
- Test cả **web (máy tính)** lẫn **điện thoại (Android hoặc trình duyệt ở chế độ 375px)**: web và app là một sản phẩm.
- Khu **mua sách** và khu **đấu giá** tách riêng; chuyển qua lại bằng nút đổi khu (biểu tượng búa / cửa hàng) trên thanh điều hướng.

## Chuẩn bị trước khi test

Tester chỉ cần trình duyệt và **link do Khoa gửi** (cách 1). Tự chạy trên máy mình thì làm theo cách 2.

**Cách 1 — link online (khuyên dùng cho tester).** Khoa chạy `demo\start-demo.cmd` trên PC nhà và gửi link dạng `https://xxxx.trycloudflare.com` (hướng dẫn đầy đủ: `docs/DEMO_ONLINE.md`).

- Mở link bằng Chrome / Edge / Safari trên máy tính hoặc điện thoại. Lần đầu tải mất khoảng 20 giây.
- Link đổi mỗi lần Khoa bật lại demo; link cũ báo lỗi 1033 / 502 thì xin link mới.
- Muốn test app Android trên máy ảo: chạy `demo\run-android.cmd` với link đó (cần Flutter + Android Studio).

**Cách 2 — tự chạy trên máy.** Cần PostgreSQL, Java 21, Flutter.

1. Backend: trong `apps/backend` chạy `./scripts/reset-demo.ps1 -Port 8081 -Db rebook_books` (làm lại DB, nạp dữ liệu demo, chạy backend; khoảng 3 phút). Chạy tay thì phải đặt `SPRING_PROFILES_ACTIVE=dev`, nếu không backend ở profile `prod` và không có dữ liệu mẫu. Kiểm tra `http://localhost:8081/categories` ra chữ JSON. Các lệnh `localhost:8080` / `env/local.json` bên dưới đổi thành `8081` / `env/local.8081.json` nếu bạn chạy ở cổng 8081.
2. App web: trong `apps/frontend` chạy `dart run build_runner build --delete-conflicting-outputs` (lần đầu hoặc sau khi pull), rồi `flutter run -d chrome --web-port 5199 --dart-define-from-file=env/local.json`. Giữ đúng cổng **5199** để trang thanh toán quay về đúng app.
3. App Android (máy ảo): chép `env/local.json` thành `env/android.local.json`, đổi mọi `localhost` thành `10.0.2.2` (máy ảo gọi máy thật qua địa chỉ này, file này không commit), rồi chạy `flutter run -d emulator-5554 --dart-define-from-file=env/android.local.json`.

**Một app cho mọi vai.** Đăng nhập bằng tài khoản Staff hoặc Admin thì app tự chuyển sang giao diện quản trị (nền sáng, thanh bên). Test hai vai cùng lúc thì dùng hai cửa sổ: một cửa sổ thường và một cửa sổ ẩn danh (hoặc máy ảo).

**Làm sạch dữ liệu** (đưa về đúng dữ liệu mẫu, nên làm trước mỗi đợt test): tắt backend, chạy lệnh dưới, bật lại backend — nó tự tạo bảng và nạp dữ liệu mẫu. Chỉ người giữ máy chủ (Khoa) làm bước này.

```bash
psql -U postgres -h localhost -c "DROP DATABASE rebook_dev;" -c "CREATE DATABASE rebook_dev OWNER rebook ENCODING 'UTF8' TEMPLATE template0;"
```

Nhiều tester dùng chung một máy chủ thì **chia tài khoản**: mỗi người một tài khoản ở bảng dưới, không dùng chung, để giỏ hàng và ví không đạp lên nhau.

## Tài khoản test

Mọi tài khoản dùng mật khẩu `Rebook@123` (phân biệt hoa thường). Số liệu dưới đây đúng khi vừa làm sạch dữ liệu.

| Email | Vai | Tên hiển thị | Có sẵn để test |
| --- | --- | --- | --- |
| `buyer1@rebook.vn` | Người mua | Phạm Thu Hà | Ví 3–5 triệu, 1 đơn đã hoàn tất, đã đăng ký + cọc phiên đấu giá số 1 |
| `buyer2@rebook.vn` | Người mua | Võ Đức Anh | Ví 3–5 triệu, 1 đơn đang giao (COD), đã đăng ký phiên số 1 |
| `buyer3@rebook.vn` | Người mua | Đặng Ngọc Lan | Ví 3–5 triệu, đã đăng ký phiên số 1 |
| `seller1@rebook.vn` | Người bán | Trần Minh Thư | Shop "Nhà Sách Cũ Sài Gòn" (TP.HCM, **uy tín**: tin tự duyệt), 6 tin đăng, 4 yêu cầu ký gửi ở các bước khác nhau |
| `seller2@rebook.vn` | Người bán | Lê Hoàng Nam | Shop "Tiệm Sách Hà Nội Xưa" (Hà Nội, shop mới: tin chờ admin duyệt), 1 tin chờ duyệt, 1 đơn chờ xác nhận |
| `staff@rebook.vn` | Nhân viên kho | Nguyễn Văn Kho | Lịch hẹn nhận sách mã `APDEMO0007` (ngày mai 10:00), 1 ký gửi chờ sơ duyệt, 5 cuốn trong kho |
| `admin@rebook.vn` | Quản trị | Quản trị ReBook | 1 tin chờ duyệt, phiên đấu giá số 1 "Sách cổ Việt Nam trước 1975" (3 lô, đã công bố) |

Tài khoản mới tự đăng ký cần mã OTP xác thực email. Môi trường test không gửi email thật: mã nằm trong log backend, dòng `[OTP] ... cho <email>: <mã>`. Tester dùng link online thì nhắn Khoa đọc mã giúp.

## Thanh toán thử

App có 3 cách trả tiền; ZaloPay chạy trên môi trường **sandbox** nên tiền và thẻ đều là giả.

| Cách trả | Dùng ở đâu | Kết quả mong đợi |
| --- | --- | --- |
| Tiền mặt khi nhận (COD) | Đặt hàng thường | Đơn vào ngay trạng thái "Chờ xác nhận" |
| Ví ReBook | Đặt hàng, hoá đơn đấu giá | Trừ ví ngay; thiếu số dư thì báo lỗi, không tạo đơn |
| ZaloPay | Đặt hàng, hoá đơn đấu giá, nạp tiền vào ví | Mở trang ZaloPay; trả xong thì app tự báo thành công; hạn 15 phút |

**Thẻ test ZaloPay** (Visa sandbox do ZaloPay công bố, không phải thẻ thật):

| Trường | Giá trị |
| --- | --- |
| Số thẻ | `4111 1111 1111 1111` |
| Tên trên thẻ | `NGUYEN VAN A` |
| Ngày hết hạn | bất kỳ tháng/năm trong tương lai, ví dụ `12/30` (hạn `01/25` ghi trong tài liệu ZaloPay đã qua nên bị từ chối) |
| CVV | `123` |

**Các bước trả bằng ZaloPay:**

1. Chọn **ZaloPay** rồi bấm đặt hàng / xác nhận nạp. Trên web, trang ZaloPay mở ở **tab mới**; tab app chuyển sang màn "Đang chờ thanh toán".
2. Trình duyệt chặn tab mới → bấm nút **Mở trang ZaloPay** trên màn chờ.
3. Trên trang ZaloPay: kiểm tra số tiền và nội dung đúng (ví dụ "ReBook - Nạp tiền vào ví") → chọn **Thẻ quốc tế** → nhập thẻ test → **Thanh toán** → hỏi lưu thẻ thì chọn **Tiếp tục thanh toán**.
4. ZaloPay báo "THANH TOÁN THÀNH CÔNG", rồi đưa về trang kết quả của ReBook (nút **Quay lại ReBook**, tự chuyển sau 3 giây).
5. Tab app tự đổi sang **Thanh toán thành công** trong vài giây, không cần tải lại. Nạp ví thì số dư tăng và có dòng "Nạp tiền qua ZaloPay"; đơn hàng thì chuyển sang "Chờ xác nhận".

Dùng link online thì trang kết quả ở bước 4 có thể không mở được (nó trỏ về máy của Khoa): đóng tab đó và quay lại tab app, kết quả vẫn tự cập nhật. Đây không phải lỗi.

**Trường hợp nên thử thêm:**

- [ ] Bấm **Hủy giao dịch** trên trang ZaloPay → app không báo thành công, không trừ ví; thanh toán báo thất bại hoặc hết hạn sau 15 phút, đơn chưa trả bị huỷ.
- [ ] Đóng tab ZaloPay giữa chừng → màn chờ vẫn có nút **Mở trang ZaloPay** để trả tiếp.
- [ ] Tải lại trang ReBook sau khi đã thành công → ví không bị cộng hai lần.
- [ ] Đơn chờ thanh toán: vào **Đơn mua** → trả lại bằng Ví ReBook thay vì ZaloPay.

## Vai 1 — Khách chưa đăng nhập

Khách xem được sách, shop, lịch và phòng đấu giá; mọi thao tác mua, thả tim, trả giá đều đưa sang đăng nhập rồi quay lại đúng chỗ cũ.

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 1.1 | Mở app (web) | Trang giới thiệu ReBook; có nút Đăng nhập / Đăng ký |
| 1.2 | Vào trang chủ mua sách, kéo các kệ | Băng chuyền, "Đang được săn", sách có bìa, giá |
| 1.3 | Khám phá / tìm kiếm: gõ "Nhân Tâm", lọc theo danh mục, giá, tình trạng; đổi sắp xếp | Kết quả đúng bộ lọc; đổi sắp xếp thì thứ tự đổi |
| 1.4 | Mở chi tiết một cuốn | Bìa, tình trạng, giá, tồn kho, shop (sao), ảnh thật, mô tả |
| 1.5 | Bấm trái tim / Thêm vào giỏ / Mua ngay | Chuyển sang Đăng nhập; đăng nhập xong quay lại đúng cuốn đó |
| 1.6 | Chuyển sang khu Đấu giá (nút búa), mở phiên đang diễn ra | Xem được phòng đấu giá trực tiếp; có dòng "Bạn đang xem. Đăng ký phiên để trả giá."; không có nút trả giá |
| 1.7 | Mở thẳng đường dẫn `/account` hoặc `/home/cart` | Bị chuyển sang Đăng nhập |

**Đăng ký tài khoản mới** (dùng email chưa có, ví dụ `tester01@rebook.vn`):

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 1.8 | Đăng ký: họ tên, email, số điện thoại `09xxxxxxxx`, mật khẩu 8 ký tự trở lên | Sang màn nhập OTP |
| 1.9 | Nhập mã OTP (lấy trong log backend) | Tài khoản kích hoạt, vào được app |
| 1.10 | Nhập sai OTP | Báo "Mã OTP không đúng hoặc đã hết hạn." |
| 1.11 | Đăng ký trùng email đã có (ví dụ `buyer1@rebook.vn`) | Báo email đã được dùng |
| 1.12 | Mật khẩu 6–7 ký tự | Ô mật khẩu báo "Mật khẩu 8–72 ký tự", không gửi được |
| 1.13 | Số điện thoại dạng `+849xxxxxxxx` | Đăng ký được; số lưu lại dạng `09xxxxxxxx` (+84 tự đổi thành 0) |
| 1.14 | Quên mật khẩu: nhập email → OTP → mật khẩu mới | Đăng nhập được bằng mật khẩu mới |
| 1.15 | Đăng nhập sai mật khẩu | Báo sai email hoặc mật khẩu, không lộ email có tồn tại hay không |

## Vai 2 — Người mua (`buyer1`)

Người mua đi trọn vòng đơn hàng: chọn sách → giỏ → thanh toán → nhận hàng → đánh giá hoặc trả hàng. Tiền trả nằm ở sàn (escrow) tới khi đơn hoàn tất mới về ví người bán.

**2A. Sổ địa chỉ và hồ sơ** (Tài khoản → Địa chỉ)

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 2.1 | Thêm địa chỉ: chọn tỉnh → quận/huyện → phường/xã từ danh sách, gõ số nhà + đường | Đổi tỉnh thì quận và phường bị xoá để chọn lại; chỉ ô đường là gõ tay |
| 2.2 | Xem bản đồ trong form địa chỉ | Bản đồ tự định vị theo địa chỉ; ghim cố định giữa khung, kéo bản đồ để chọn điểm; có nhãn Hoàng Sa, Trường Sa |
| 2.3 | Chọn loại Nhà riêng / Văn phòng, bật Mặc định, lưu | Địa chỉ mới đứng đầu, có nhãn mặc định; mở lại vẫn giữ đúng điểm ghim và loại |
| 2.4 | Nhập số điện thoại sai (chữ, thiếu số) | Ô chặn ký tự lạ / báo lỗi, không lưu được |
| 2.5 | Sửa tên, số điện thoại ở Hồ sơ; đổi mật khẩu | Lưu thành công; đăng nhập lại bằng mật khẩu mới được |

**2B. Chọn sách, yêu thích, giỏ hàng**

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 2.6 | Bấm trái tim ở chi tiết sách, rồi vào Tài khoản → Sách yêu thích | Tim tô đỏ ngay; cuốn đó có trong danh sách (mới nhất trước); bấm lại thì bỏ |
| 2.7 | Thêm 2 sách của `seller1` (TP.HCM) và 1 sách của `seller2` (Hà Nội) vào giỏ | Giỏ chia theo 2 shop |
| 2.8 | Tăng số lượng một cuốn chỉ còn 1 | Không tăng quá tồn kho |
| 2.9 | Bỏ chọn 1 món trong giỏ | Tạm tính và phí ship tính lại chỉ theo món còn chọn; món bỏ chọn vẫn nằm trong giỏ |
| 2.10 | Đổi địa chỉ nhận ở bước thanh toán (TP.HCM ↔ Hà Nội) | Phí ship đổi: cùng tỉnh với shop thì rẻ hơn liên tỉnh |

**2C. Đặt hàng và theo dõi đơn**

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 2.11 | Đặt giỏ 2 shop, trả bằng Ví ReBook | Tách thành 2 đơn (mỗi shop một đơn); ví bị trừ đúng tổng; đơn ở "Chờ xác nhận"; món đã đặt biến mất khỏi giỏ |
| 2.12 | Đặt một đơn trả bằng ZaloPay (mục Thanh toán thử) | Thanh toán xong đơn sang "Chờ xác nhận" |
| 2.13 | Đặt một đơn COD | Đơn vào "Chờ xác nhận", không trừ ví |
| 2.14 | Đặt ZaloPay rồi bỏ ngang; vào Đơn mua → trả lại bằng Ví | Đơn chuyển sang "Chờ xác nhận"; không trả tiền hai lần |
| 2.15 | Để một đơn ZaloPay quá 15 phút không trả | Đơn tự huỷ, hàng trả lại kho của shop |
| 2.16 | Huỷ một đơn "Chờ xác nhận"; xin huỷ một đơn "Đang chuẩn bị" | Đơn chờ xác nhận bị huỷ ngay, tiền đã trả hoàn về ví; đơn đang chuẩn bị chỉ gửi yêu cầu, chờ shop đồng ý |
| 2.17 | Mở chi tiết đơn | Có lịch sử trạng thái, địa chỉ, phí ship, phương thức trả, mã vận đơn khi đang giao |

**2D. Nhận hàng, đánh giá, trả hàng** (cần `seller1` giao đơn ở Vai 3 trước)

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 2.18 | Đơn "Đã giao" → Xác nhận đã nhận hàng | Đơn "Hoàn tất"; tiền về ví người bán (trừ phí sàn 5%) |
| 2.19 | Đánh giá shop 1–5 sao + nhận xét | Sao của shop cập nhật; mỗi đơn chỉ đánh giá một lần |
| 2.20 | Đơn "Đã giao" khác → Yêu cầu trả hàng: lý do, mô tả, 1–10 ảnh thật | Ảnh tải lên và hiện lại được; đơn "Yêu cầu trả hàng" kèm **hạn shop trả lời (2 ngày)** |
| 2.21 | Đang yêu cầu trả hàng mà bấm Đã nhận hàng | Yêu cầu trả hàng bị rút lại, đơn hoàn tất |
| 2.22 | Shop từ chối trả hàng | Yêu cầu chuyển sang Admin phân xử (Vai 6) |

**2E. Ví và thông báo**

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 2.23 | Ví ReBook → Nạp tiền 10.000đ qua ZaloPay; thử nạp 5.000đ | Nạp 10.000đ thành công, có dòng "Nạp tiền qua ZaloPay"; 5.000đ bị chặn (tối thiểu 10.000đ) |
| 2.24 | Xem lịch sử giao dịch | Mỗi dòng có loại, số tiền +/−, số dư sau, giờ |
| 2.25 | Mở chuông Thông báo sau mỗi bước trên | Có thông báo đơn mới, shop xác nhận, đang giao…; "Đánh dấu đã đọc" làm mất số đếm |

## Vai 3 — Người bán (`seller1`, `seller2`)

Người bán quản lý tin đăng, xử lý đơn tới khi giao xong, trả lời trả hàng và rút tiền bán sách về ngân hàng. Vào bằng Tài khoản → Kênh người bán.

**3A. Mở shop** (dùng tài khoản mới đăng ký ở Vai 1, hoặc `buyer3`)

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 3.1 | Mở shop: tên, mô tả, địa chỉ lấy hàng, tỉnh, ngân hàng + số tài khoản + chủ tài khoản | Shop tạo xong, có Kênh người bán |
| 3.2 | Đăng tin mới từ shop mới | Tin ở trạng thái **Chờ duyệt**, khách chưa thấy cho tới khi Admin duyệt (Vai 6) |

**3B. Tin đăng** (`seller1` — shop uy tín, tin tự duyệt)

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 3.3 | Thêm tin: thông tin sách, tình trạng, giá, tồn kho, ảnh thật | Dưới 3 ảnh thì báo thiếu ảnh; đủ ảnh thì tin **Đang bán** ngay, ảnh hiện đúng ảnh vừa tải |
| 3.4 | Quét bìa: chụp / chọn ảnh bìa trước, kéo 4 góc | Ảnh bìa được làm phẳng thành hình chữ nhật và dùng làm bìa tin |
| 3.5 | Nhập giá / ISBN / tồn kho sai định dạng | Ô chặn ký tự lạ, báo lỗi rõ, chữ gợi ý mờ biến mất khi gõ |
| 3.6 | Sửa tồn kho về 0 | Tin chuyển **Hết hàng**, không thêm vào giỏ được |
| 3.7 | Ẩn tin rồi hiện lại | Ẩn thì khách không tìm thấy; hiện lại thì thấy |

**3C. Xử lý đơn** (đơn do `buyer1` đặt ở Vai 2)

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 3.8 | Đơn của shop → đơn "Chờ xác nhận" → Xác nhận | Đơn "Đang chuẩn bị"; người mua nhận thông báo |
| 3.9 | Giao hàng: nhập mã vận đơn | Đơn "Đang giao", người mua thấy mã vận đơn |
| 3.10 | Đã giao | Đơn "Đã giao"; người mua xác nhận được (2.18) |
| 3.11 | Một đơn khác → Giao thất bại | Đơn chuyển trạng thái giao thất bại; tiền người mua đã trả được hoàn |
| 3.12 | Đơn "Đang chuẩn bị" người mua xin huỷ (2.16) → Đồng ý hoặc Từ chối | Đồng ý: đơn huỷ, tiền hoàn vào ví người mua, hàng trả lại tồn kho. Từ chối: đơn giữ nguyên, lịch sử ghi lý do |
| 3.13 | `seller2`: đơn chờ xác nhận có sẵn, để quá 24 giờ không xác nhận | Đơn tự huỷ (chỉ test khi có thời gian) |
| 3.14 | Yêu cầu trả hàng (2.20): Đồng ý / Từ chối kèm ghi chú | Đồng ý: đơn trả hàng, hoàn tiền. Từ chối: chuyển Admin phân xử |
| 3.15 | Thống kê kênh người bán | Doanh thu, số đơn chờ xác nhận / đang giao khớp với danh sách đơn |

**3D. Rút tiền** (Ví ReBook → Rút tiền, `seller1` sau khi có đơn hoàn tất)

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 3.16 | Bước 1 chọn ngân hàng (tìm theo tên) → bước 2 số tài khoản + tên chủ TK IN HOA không dấu → bước 3 số tiền + ghi chú | Mỗi bước chặn dữ liệu sai: số TK 6–19 chữ số, số tiền tối thiểu 50.000đ và không quá số dư |
| 3.17 | Xác nhận rút | Màn kết quả; yêu cầu "Đang xử lý" kèm ngân hàng, số TK, ghi chú vừa nhập |
| 3.18 | Xem số dư ngay sau khi rút | Số tiền rút chuyển từ "Có thể dùng" sang "Đang khoá" ngay, đúng như dòng hướng dẫn trên màn rút tiền; yêu cầu rút thứ hai không dùng lại được số tiền đang khoá |
| 3.19 | Rút lần hai | Tài khoản vừa dùng hiện ở mục "Gần đây"; bấm ngôi sao thì nó đứng đầu danh sách |
| 3.20 | Admin duyệt (Vai 6) | Yêu cầu "Đã chuyển", có biên lai và tên người duyệt; tiền đang khoá được trừ hẳn |

## Vai 4 — Đấu giá (người ký gửi + người trả giá)

Sách quý được ký gửi vào kho, kiểm định rồi mới lên lô; người mua đăng ký + đặt cọc trước giờ mở, trả giá trực tiếp, người trả cao nhất khi hết giờ thắng. Vào khu đấu giá bằng nút búa (giao diện tối, tab Khám phá · Đang diễn ra · Sắp diễn ra · Yêu thích · Của tôi).

**Luật cần biết khi kiểm tra kết quả:**

| Luật | Giá trị mặc định |
| --- | --- |
| Hạn mức trả giá | tiền cọc × 10 (phiên số 1: cọc 500.000đ → trả tới 5.000.000đ) |
| Bước giá | dưới 200k: +10k · từ 200k: +50k · từ 1 triệu: +100k · từ 5 triệu: +500k |
| Thời gian mỗi lô | 60 giây (phiên số 1), nghỉ 7 giây giữa hai lô |
| Soft close | có người trả khi còn dưới 15 giây → đồng hồ về lại 15 giây |
| Giá sàn | gõ búa dưới giá sàn → lô không bán |
| Phí | người thắng trả thêm 10% · người ký gửi trả hoa hồng 15% |
| Thanh toán lô thắng | trong 48 giờ; bỏ thanh toán → mất cọc, cấm đấu giá 90 ngày, người trả cao thứ hai được mời mua lại (nếu giá của họ ≥ giá sàn), hạn 24 giờ |

**4A. Ký gửi sách** (`seller1`, Tài khoản → Ký gửi đấu giá)

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 4.1 | Tạo yêu cầu: thông tin sách, ảnh, giá mong muốn 250.000đ | Bị chặn: giá mong muốn tối thiểu 300.000đ |
| 4.2 | Tạo lại với giá ≥ 300.000đ + câu chuyện nguồn gốc | Yêu cầu "Đã gửi", chờ kho sơ duyệt (Vai 5) |
| 4.3 | Sau khi kho duyệt sơ bộ: đặt lịch hẹn mang sách tới kho | Chỉ chọn được giờ 8:00–17:00 trong 7 ngày tới; nhận mã lịch hẹn |
| 4.4 | Yêu cầu đã kiểm định có sẵn (`KGDEMO000005`, chờ người bán) | Thấy đánh giá tình trạng, ước giá, giá khởi điểm, giá sàn đề xuất |
| 4.5 | Chọn Đồng ý / Đề xuất giá sàn khác / Rút lại | Đồng ý: sách thành lô sẵn sàng cho Admin xếp phiên. Rút lại: không lên đấu giá |
| 4.6 | Lô không bán được sau phiên | Chọn: vào phiên sau / chuyển bán giá cố định (tạo tin chờ duyệt) / nhận sách về |

**4B. Đăng ký và trả giá** (`buyer1`, `buyer2`, `buyer3` — mỗi người một cửa sổ, phiên số 1 đã đăng ký sẵn)

Phiên số 1 hẹn mở sau 2 ngày. Muốn chạy ngay, Khoa chạy `powershell -File demo\start-auction.ps1 -Session 1` trên máy chủ. Phiên mẫu chỉ chạy được **một lần**; lần sau phải làm sạch dữ liệu hoặc Admin tạo phiên mới (Vai 6).

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 4.7 | Mở phiên sắp diễn ra, xem danh mục lô | Mỗi lô có bìa, báo cáo kiểm định, ước giá, giá khởi điểm |
| 4.8 | Bấm sao theo dõi một lô và theo dõi cả phiên | Lô / phiên hiện ở tab Yêu thích; bấm lại thì bỏ |
| 4.9 | Tài khoản mới ở Vai 1 (nạp trước ít nhất 500.000đ qua ZaloPay): Đăng ký tham gia + đặt cọc, đồng ý quy định | Trừ cọc vào "Đang khoá"; nhận số bài (paddle). Thiếu ví thì báo lỗi |
| 4.10 | Phiên mở: vào phòng đấu giá | Lô đang mở, giá hiện tại, đồng hồ đếm ngược, người trả giá hiện bằng số bài (không lộ tên) |
| 4.11 | `buyer1` bấm Trả giá | Giá tăng đúng một bước; cửa sổ `buyer2` cập nhật ngay không cần tải lại; `buyer1` nhận thông báo khi bị vượt |
| 4.12 | `buyer2` đặt Trả giá tự động (mức tối đa) rồi `buyer1` trả tiếp | Hệ thống tự trả thay `buyer2` tới mức tối đa |
| 4.13 | Trả giá khi đồng hồ còn dưới 15 giây | Đồng hồ nhảy về 15 giây |
| 4.14 | Hai người bấm cùng một mức cùng lúc | Chỉ một người được; người sau báo "giá đã thay đổi" |
| 4.15 | Trả vượt hạn mức (cọc × 10) | Bị từ chối; thêm cọc thì trả tiếp được |
| 4.16 | Mất mạng vài giây (tắt Wi-Fi) rồi bật lại | Phòng tự nối lại và hiện đúng giá, đúng đồng hồ |
| 4.17 | Hết giờ lô | Lô báo Bán (giá ≥ sàn) hoặc Không bán; sang lô kế; hết phiên xem được Kết quả từng lô |
| 4.18 | Người không thắng xem ví sau phiên | Tiền cọc được hoàn về số dư khả dụng |

**4C. Sau khi thắng**

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 4.19 | Người thắng: Tài khoản đấu giá → Hoá đơn lô thắng | Hoá đơn = giá gõ búa + 10% phí người mua, đã trừ tiền cọc; hạn 48 giờ |
| 4.20 | Chọn giao tận nơi (địa chỉ) hoặc nhận tại kho, trả bằng Ví hoặc ZaloPay | Hoá đơn đã thanh toán, kho xử lý giao (Vai 5); hoá đơn đấu giá không huỷ được |
| 4.21 | Lịch sử trả giá, Đấu giá của tôi | Hiện đủ các lượt trả giá và phiên đã tham gia |
| 4.22 | (Tùy chọn, lâu) Người thắng bỏ thanh toán quá hạn | Người thắng mất cọc và bị cấm; người trả cao thứ hai thấy **Lời mời mua lần hai** (Tài khoản đấu giá) → Nhận mua (mở hoá đơn) hoặc Từ chối. Muốn test nhanh: Admin giảm "Hạn thanh toán lô thắng" ở Cấu hình trước khi chạy phiên |

## Vai 5 — Nhân viên kho (`staff`)

Nhân viên kho nhận sách ký gửi, kiểm định, giữ kho và giao lô đấu giá đã bán. Staff chỉ vào được 4 mục: **Ký gửi, Lịch hẹn, Kho, Đơn đấu giá**.

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 5.1 | Đăng nhập `staff@rebook.vn` | App chuyển sang giao diện quản trị, mở sẵn mục Ký gửi; thanh bên chỉ có 4 mục trên |
| 5.2 | Mở thẳng đường dẫn của Admin (ví dụ `/users`, `/config`) | Bị đưa về Ký gửi, không xem được |
| 5.3 | Ký gửi → yêu cầu `KGDEMO000006` (mới gửi) → Sơ duyệt Đạt | Người gửi (`seller2`) nhận thông báo và đặt lịch hẹn được |
| 5.4 | Sơ duyệt Không đạt (yêu cầu mới ở 4.2) | Bắt buộc nhập lý do; người gửi thấy lý do |
| 5.5 | Lịch hẹn → nhập mã `APDEMO0007` → Nhận sách, gán mã kệ | Tạo biên nhận và mã kho; sách chuyển sang chờ kiểm định |
| 5.6 | Nhập mã lịch hẹn sai | Báo không tìm thấy lịch hẹn |
| 5.7 | Kiểm định cuốn vừa nhận: tick checklist (đủ trang, đúng ấn bản, ẩm mốc, ghi chú, chữ ký), chấm tình trạng, ước giá thấp–cao, giá khởi điểm, giá sàn, ảnh, kết quả Đạt | Người gửi thấy kết quả và quyết định được (4.5) |
| 5.8 | Nhập ước giá thấp lớn hơn ước giá cao, hoặc giá sàn nhỏ hơn giá khởi điểm | Form báo lỗi, không lưu |
| 5.9 | Kho: xem danh sách (5 cuốn mẫu `WHDEMO0001`–`0005`), đổi mã kệ | Mã kệ cập nhật; trạng thái từng cuốn đúng |
| 5.10 | Đơn đấu giá (sau 4.20): Xác nhận → Giao → Đã giao | Người thắng thấy đơn chuyển trạng thái tương ứng; chọn nhận tại kho thì không có bước giao |
| 5.11 | Người thắng yêu cầu trả lô đã nhận → kho Đồng ý / Từ chối | Giống trả hàng thường: từ chối thì sang Admin phân xử |
| 5.12 | Thu nhỏ cửa sổ dưới 900px | Thanh bên thành ngăn kéo; màn vẫn dùng được ở 375px |

## Vai 6 — Quản trị (`admin`)

Admin duyệt nội dung, quản lý người dùng, chạy phiên đấu giá, duyệt rút tiền và phân xử trả hàng; mọi thao tác quan trọng được ghi vào Nhật ký hoạt động.

**6A. Nội dung và người dùng**

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 6.1 | Tổng quan | Số người dùng, ký gửi chờ xử lý, phí sàn thu được… khớp với dữ liệu |
| 6.2 | Tin đăng → tin chờ duyệt của `seller2` → Duyệt | Tin đang bán, người mua tìm thấy; tin chuyển sang danh sách Đã duyệt kèm **tên Admin và thời điểm** |
| 6.3 | Từ chối một tin (3.2) | Bắt buộc nhập lý do; người bán thấy lý do và nhận thông báo |
| 6.4 | Người dùng → tìm `buyer3` → Khoá (kèm lý do) | `buyer3` không đăng nhập được; Mở khoá thì đăng nhập lại được |
| 6.5 | Danh mục: thêm danh mục con, sửa tên, xoá danh mục còn con | Thêm / sửa được; xoá danh mục còn con bị chặn |

**6B. Phiên đấu giá**

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 6.6 | Tạo phiên: tên, mô tả, giờ bắt đầu (vài phút nữa), hạn đăng ký (trước giờ bắt đầu), số người tối thiểu 1, cọc 500.000đ, 30 giây/lô | Phiên nháp được tạo; giờ bắt đầu ở quá khứ thì bị chặn |
| 6.7 | Xếp lô "sẵn sàng" (sau 4.5) vào phiên → Công bố | Người dùng thấy phiên ở Sắp diễn ra và đăng ký được |
| 6.8 | Đến giờ bắt đầu (đủ người đăng ký) | Phiên tự mở; thiếu người thì phiên bị dời |
| 6.9 | Giám sát phiên đang chạy → Tạm dừng → Tiếp tục | Phòng đấu giá của người dùng báo tạm dừng, không trả giá được; tiếp tục thì đồng hồ chạy tiếp |
| 6.10 | Huỷ một lô (kèm lý do) | Lô bị bỏ khỏi phiên, người dùng thấy đã huỷ |

**6C. Tiền, cấu hình, khiếu nại, nhật ký**

| # | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 6.11 | Rút tiền → yêu cầu của `seller1` (3.17) → Duyệt, nhập biên lai: người chuyển, giờ chuyển, số tiền, ảnh chứng từ | Thiếu biên lai, số tiền khác số yêu cầu, hoặc giờ chuyển ở tương lai → bị chặn. Đủ thì "Đã chuyển", hiện người duyệt và thời điểm |
| 6.12 | Cấu hình: đổi phí sàn 5% → 7%, đổi hạn trả lời trả hàng | Chỉ áp dụng cho giao dịch sau đó; giá trị vô lý (âm, chữ) bị chặn. **Nhớ trả lại 5%** |
| 6.13 | Khiếu nại → yêu cầu trả hàng shop đã từ chối (2.22) → Hoàn tiền hoặc Giữ đơn | Hoàn tiền: đơn trả hàng, tiền về người mua. Giữ đơn: đơn hoàn tất. Khiếu nại chuyển sang danh sách Đã phân xử kèm tên Admin và thời điểm |
| 6.14 | Yêu cầu trả hàng shop không trả lời quá 2 ngày | Tự chuyển vào Khiếu nại (chỉ test khi có thời gian, hoặc giảm hạn ở Cấu hình) |
| 6.15 | Nhật ký hoạt động | Có đủ các thao tác vừa làm: duyệt / từ chối tin, khoá / mở khoá, duyệt rút tiền, đổi cấu hình, kèm tên Admin và giờ |

## Báo lỗi

Ghi mỗi lỗi thành một dòng trong sổ dưới đây (thêm dòng khi cần), hoặc bình luận thẳng vào dòng kịch bản bị lỗi. Mỗi lỗi cần đủ để dev làm lại được:

- **Mã kịch bản** (ví dụ 2.11) và **tài khoản** đã dùng
- **Thiết bị**: web (trình duyệt, độ rộng cửa sổ) hay Android
- **Các bước đã làm**, **kết quả mong đợi**, **kết quả thực tế** (chép nguyên câu báo lỗi)
- **Ảnh chụp hoặc video**; lỗi tiền bạc thì ghi cả mã đơn / mã thanh toán (dạng `OD...`, `PM...`)

Mức độ: **Chặn** = không đi tiếp được luồng chính hoặc sai tiền · **Nặng** = sai nghiệp vụ nhưng có cách vòng · **Nhẹ** = sai nhỏ, không ảnh hưởng kết quả · **Giao diện** = lệch hình, chữ, màu, tràn màn hình.

| Mã | Người test | Mô tả ngắn (thực tế khác mong đợi thế nào) | Thiết bị | Mức độ | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| 1.12 (ví dụ) | Tên bạn | Mật khẩu 7 ký tự: app cho bấm Đăng ký, lỗi hiện "..." | Chrome 1440px | Nhẹ | Mới |
|  |  |  |  |  |  |
|  |  |  |  |  |  |

## Câu hỏi thường gặp và điểm đã biết

**Không cần báo lỗi** với các điểm dưới đây: đã biết và có chủ đích, hoặc chưa làm trong đợt này.

| Điểm | Hiện trạng |
| --- | --- |
| Email / SMS OTP | Không gửi thật; mã nằm trong log backend |
| Thanh toán | ZaloPay sandbox, thẻ test; không có tiền thật. VNPay trong SRS đã được thay bằng ZaloPay |
| Vận chuyển | Giả lập bằng nút (Giao hàng, Đã giao, Giao thất bại), chưa nối hãng vận chuyển |
| Thông báo đẩy | Chỉ có thông báo trong app (chuông), chưa có thông báo đẩy về điện thoại |
| Bắt đầu phiên đấu giá ngay | App chưa có nút; phiên tự mở đúng giờ, hoặc Khoa chạy `demo\start-auction.ps1` |
| Đổi vai người dùng, đánh dấu shop uy tín, gỡ cấm đấu giá, từ chối yêu cầu rút tiền | Backend đã có, giao diện Admin chưa có nút |
| Phiên đấu giá mẫu số 1 | Chạy được một lần; mỗi lô lên đấu giá tối đa 2 lần |
| Trang kết quả ZaloPay khi dùng link online | Có thể không mở được; quay lại tab app, kết quả vẫn tự cập nhật |

| Gặp | Xử lý |
| --- | --- |
| App quay mãi / "Lỗi kết nối" | Máy chủ chưa chạy hoặc link đã đổi; xin Khoa link mới |
| Đăng nhập báo sai mật khẩu | Mật khẩu mẫu là `Rebook@123` (chữ R hoa); tài khoản có thể đang bị khoá ở bước 6.4 |
| Trả giá báo "chưa đăng ký" | Tài khoản đang dùng chưa đăng ký + cọc phiên đó |
| Trả giá báo vượt hạn mức | Cọc chưa đủ (hạn mức = cọc × 10); đặt cọc thêm |
| Phiên không tự mở | Chưa đủ số người đăng ký tối thiểu hoặc chưa tới giờ |
| Trang ZaloPay không mở (tab mới bị chặn) | Bấm "Mở trang ZaloPay" trên màn chờ, hoặc cho phép cửa sổ bật lên với trang này |
| Thẻ test báo "Thẻ đã hết hạn" | Nhập ngày hết hạn trong tương lai, ví dụ `12/30` |
| Dữ liệu lộn xộn sau nhiều lần test | Nhờ Khoa làm sạch dữ liệu (mục Chuẩn bị) |
