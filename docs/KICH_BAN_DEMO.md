# Kịch bản demo cho thầy (khoảng 15 phút, làm theo là chạy)

File này chỉ có **việc cần bấm và chữ cần gõ**. Giải thích nghiệp vụ nằm ở [DEMO.md](DEMO.md).
Mọi dữ liệu dưới đây là dữ liệu sau `reset-demo` (xem phần 0). Mật khẩu mọi tài khoản: `Rebook@123`.

## 0. Chuẩn bị trước giờ demo (làm xong trước 20 phút)

Làm đúng thứ tự, mỗi bước xong mới sang bước sau.

1. Bật Docker Desktop. Mở terminal ở `apps/backend`, chạy (mất khoảng 3 phút, dữ liệu về đúng trạng thái đầu):
   ```powershell
   ./scripts/reset-demo.ps1 -Port 8081 -Db rebook_books
   node scripts/smoke.mjs http://localhost:8081      # phải ra "lỗi 0"
   ```
2. Bật máy ảo Android (rebook_pixel) **bằng lệnh có DNS**, nếu không ảnh bìa sẽ không hiện:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd rebook_pixel -dns-server 1.1.1.1,8.8.8.8
   ```
   Cài bản app mới nhất lên máy ảo (file env `10.0.2.2:8081`, xem `apps/frontend/README.md`), mở app một lần cho chắc.
3. Chạy web (trong `apps/frontend`):
   ```powershell
   flutter run -d chrome --web-port 5199 --dart-define-from-file=env/local.8081.json
   ```
4. **Đăng nhập thử từng vai một lần rồi đăng xuất** (kiểm tra mạng và dữ liệu): `admin@`, `staff@`, `seller1@`, `buyer1@`, `buyer6@`.
5. Chuẩn bị tệp và ảnh:
   - Trong thư viện ảnh của máy ảo phải có ít nhất 4 ảnh bìa sách (hiện có: Tắt đèn, Clean Code, Tâm lý học, Dế Mèn). Chưa có thì kéo ảnh từ máy tính thả vào cửa sổ máy ảo.
   - Trên Windows tạo sẵn một ảnh **biên lai chuyển khoản** (chụp màn hình bất kỳ, PNG, dưới 5MB) tên `bien-lai.png`, để ở Desktop.
6. Bố trí màn hình (một lần):
   - **Cửa sổ A:** máy ảo Android, đăng nhập `buyer1@rebook.vn` (người mua).
   - **Cửa sổ B:** Chrome thường, `http://localhost:5199`, đăng nhập `admin@rebook.vn`.
   - **Cửa sổ C:** Chrome **ẩn danh**, cùng địa chỉ, đăng nhập `buyer6@rebook.vn` (đối thủ trả giá). Để im, chỉ dùng ở cảnh 5.
   - Staff dùng chung cửa sổ B: đăng xuất admin, đăng nhập `staff@rebook.vn` khi tới cảnh 4 rồi đổi lại.

> **Chưa bấm tay đủ, hãy chạy thử một lần trước giờ demo:** phiếu kiểm định của Staff (cảnh 4a, bước 3) và hộp "Đã chuyển khoản" của Admin (cảnh 4b, bước 6). Luồng chạy đúng ở mức API, nhưng tôi chưa thao tác hai form này bằng giao diện.
>
> **Đừng làm trước giờ demo:** thanh toán ZaloPay và đăng nhập Google. Hai việc đó phụ thuộc mạng và tài khoản ngoài, nên chỉ nhắc miệng, không bấm.

## 1. Mở đầu (1 phút), nói rồi mới bấm

Giới thiệu: chợ sách cũ có hai cách mua, giá cố định và đấu giá; tiền đi qua ví của sàn (escrow); ba vai: người dùng, nhân viên kho, quản trị.
Mở app trên máy ảo ở trang chủ để thầy thấy ảnh bìa, băng chuyền, kệ sách.

## 2. Người mua mua sách giá cố định (3 phút, cửa sổ A, `buyer1`)

| # | Bấm | Gõ / chọn |
|---|---|---|
| 1 | Ô tìm kiếm → tìm sách | `Steinbeck` |
| 2 | Mở **The Grapes of Wrath** (288.000 đ), đọc nhanh mô tả, ảnh thật | |
| 3 | **Thêm vào giỏ** (bìa sách bay vào giỏ) | |
| 4 | Thanh tab → **Giỏ hàng** → bấm `+` một lần (số lượng 02) | |
| 5 | **Tiến hành thanh toán** | địa chỉ: chọn **Phạm Thu Hà · 45 Trần Quốc Thảo**; phương thức: **Ví ReBook** (số dư khoảng 7.001.000) |
| 6 | Xác nhận đặt hàng | |
| 7 | Tài khoản → **Đơn mua** → tab **Chờ xử lý**, mở đơn vừa đặt | |

Nói: giỏ tự tách đơn theo shop, phí ship tính theo tỉnh và khối lượng, đơn chưa thanh toán tự huỷ sau 15 phút.

## 3. Người bán đăng sách và xử lý đơn (3 phút)

**Đổi tài khoản trên máy ảo sang `seller1@rebook.vn`** (Tài khoản → Đăng xuất → đăng nhập lại).

**3a. Đăng sách mới** (Tài khoản → Kênh người bán → **Đăng sách**):

| Ô | Gõ / chọn |
|---|---|
| Ảnh bìa đại diện | **Chọn ảnh bìa** → ảnh "Tắt đèn" → kéo 4 chấm về 4 góc → **Dùng ảnh này** |
| Ảnh thật (cần ≥ 3) | dấu `+` → chọn 3 ảnh bất kỳ → **Add** |
| Tên sách | `Dế Mèn Phiêu Lưu Ký` |
| Tác giả | `Tô Hoài` |
| Thể loại → Thể loại con | **Văn học** → **Tiểu thuyết Việt Nam** |
| Tình trạng | **Tốt** |
| Nhà xuất bản / Năm | `NXB Kim Đồng` / `1941` |
| Ngôn ngữ / Số trang / Khối lượng (g) | `Tiếng Việt` / `160` / `300` |
| Giá bán / Số lượng | `55000` / `3` |

Bấm **Lưu**. Shop uy tín nên tin lên ngay ("Đang bán"). Trong danh sách bấm **Thêm** → **Ẩn tin** → **Hiện lại** để thầy thấy quản lý tin.

**3b. Xử lý đơn:** Kênh người bán → **Chờ xác nhận** → mở đơn mới nhất → **Xác nhận đơn** → **Giao cho shipper**, mã vận đơn gõ `GHN123456789` (phải 8 đến 20 ký tự).

> Mẹo gõ tiếng Việt trên máy ảo: copy chữ trên Windows rồi giữ ô nhập trên máy ảo → **Paste** (clipboard dùng chung). Gõ không dấu vẫn chạy nhưng tên sẽ hiển thị không dấu.

## 4. Nhân viên kho và quản trị (4 phút, cửa sổ B)

**4a. Staff** (`staff@rebook.vn`):

| # | Màn | Thao tác | Gõ / chọn |
|---|---|---|---|
| 1 | **Yêu cầu ký gửi** (Chờ sơ duyệt) | **Duyệt** yêu cầu "Truyện Kiều (bản Kiều Oánh Mậu)" của seller1 | |
| 2 | **Lịch hẹn & nhận sách** | nhận sách tại kho | mã lịch hẹn `HEN-DEMO-2`, mã kệ `A3-12`, thêm một ảnh biên nhận |
| 3 | **Yêu cầu ký gửi** → tab **Đã nhận sách** → "Tắt Đèn (bản 1939)" | điền phiếu kiểm định (tên ô có thể hơi khác chữ dưới đây) | tình trạng **Khá**; ước giá thấp `900000`, cao `1500000`; giá khởi điểm `800000`; **giá sàn `850000`** (giá sàn phải không vượt mức ước giá thấp, gõ cao hơn sẽ bị từ chối: dùng làm ca lỗi); kết luận **Đạt** |
| 4 | **Đối chiếu vận chuyển** | đơn đang giao → **Đã giao thành công** | |

**4b. Admin** (`admin@rebook.vn`, đăng xuất staff rồi đăng nhập):

| # | Màn | Thao tác |
|---|---|---|
| 1 | **Bảng điều khiển** | chỉ KPI và biểu đồ, bấm 7 / 30 / 90 ngày |
| 2 | **Báo cáo** | bấm **Xuất PDF** và **Xuất CSV** (mở file PDF cho thầy xem chữ tiếng Việt) |
| 3 | **Duyệt tin đăng** | **Duyệt** một tin, **Từ chối** một tin (gõ lý do `Ảnh mờ, chưa rõ bìa`) |
| 4 | **Đối soát COD** | **Đã nhận tiền COD** một đơn, xác nhận |
| 5 | **Khiếu nại trả hàng** | **Hoàn tiền người mua**, ghi chú `Bìa và ruột khác ảnh` |
| 6 | **Rút tiền** | chọn yêu cầu **Lê Hoàng Nam 800.000 đ** → **Đã chuyển khoản**: người chuyển `ReBook Corp`, giờ chuyển để mặc định (giờ hiện tại), số tiền `800000` (phải đúng số tiền rút), ảnh biên lai chọn `bien-lai.png` |

## 5. Đấu giá trực tiếp (4 phút), phần ăn điểm nhất

Dùng **phiên "Trinh thám Mỹ & Kỳ ảo" (phiên #4)**: đang mở đăng ký, mới có 2 người, cần tối thiểu 3. Nhờ vậy không phụ thuộc giờ.

| # | Cửa sổ | Thao tác | Gõ / chọn |
|---|---|---|---|
| 1 | A (máy ảo, **đăng nhập lại `buyer1@rebook.vn`**) | nút búa ở góc trên → **Sàn đấu giá** → mở phiên Trinh thám Mỹ & Kỳ ảo → **Đăng ký tham gia** | chọn **Cọc 400.000 đ**, tick **Quy chế phiên**, **Khóa cọc và đăng ký** → hiện "Bài #003" |
| 2 | B (Admin web) | **Phiên đấu giá** → phiên Trinh thám Mỹ & Kỳ ảo → **Mở ngay** → xác nhận | |
| 3 | A | phiên đã LIVE → **Vào phòng trả giá** → **Trả 400.000 đ** | |
| 4 | C (ẩn danh `buyer6`) | **Sàn đấu giá** → vào phòng → **Trả 450.000 đ** (đối thủ nâng giá, máy ảo thấy giá nhảy ngay) | |
| 5 | A | trả tiếp, mỗi lần nút tự điền mức tối thiểu kế tiếp | |
| 6 | A | **Trả giá tự động**, nhập `1000000` (hệ thống tự đáp giá thay mình tới mức đó) | |
| 7 | A | chờ hết giờ lô 1 → báo thắng | |

Nói: bước giá tăng theo mốc (10k / 50k / 100k / 500k), hạn mức trả giá = cọc × 10, trả giá phút chót thì đồng hồ kéo dài (soft close), tên người trả giá ẩn thành số bài `#003`.

**Thanh toán lô thắng.** Hóa đơn của lô vừa thắng chỉ xuất hiện khi **cả phiên kết thúc** (4 lô, mỗi lô khoảng 2 phút, tức khoảng 8 phút), nên đừng chờ. Dùng hóa đơn có sẵn để cho thầy xem bước này:

| # | Cửa sổ | Thao tác |
|---|---|---|
| 8 | C (ẩn danh `buyer6`) | Thông báo hoặc **Kết quả** → **Lô thắng cần thanh toán** → hóa đơn `RBA261106006` (đã trừ tiền cọc) → **Thanh toán hóa đơn** → **Giao tận nơi**, chọn địa chỉ mặc định, **Ví ReBook** → **Thanh toán** |

Nếu cuối buổi phiên #4 đã kết thúc và còn thời gian, mở lại máy ảo để thầy thấy thông báo "Bạn đã thắng đấu giá" và hóa đơn mới của `buyer1`.

## 6. Kết (30 giây)

Nhắc: dữ liệu thật trong PostgreSQL, realtime bằng WebSocket, API sinh client tự động từ OpenAPI, 207 test tự động, backend 224 test. Còn giả lập: ZaloPay sandbox, vận chuyển, email OTP.

## Phụ lục A. Ca lỗi để trình diễn kiểm soát đầu vào (chọn 2 đến 3 ca, đừng làm hết)

| Màn | Gõ | Kết quả |
|---|---|---|
| Đăng nhập | mật khẩu sai `abc12345` | "Email hoặc mật khẩu không đúng" (không còn báo nhầm hết phiên) |
| Đăng ký | mật khẩu `123456` (6 ký tự) | bị chặn, cần 8 đến 72 ký tự |
| Đăng sách | bỏ trống tên, hoặc chỉ 2 ảnh | báo lỗi từng ô, "Cần ít nhất 3 ảnh" |
| Đăng sách | giá `500` | từ chối (tối thiểu 1.000 đ) |
| Ký gửi | giá mong muốn `100000` | từ chối (tối thiểu 300.000 đ) |
| Kiểm định (Staff) | giá sàn `1000000` khi ước giá thấp `900000` | "Giá sàn không vượt mức thấp của giá ước tính" |
| Rút tiền | `10000` | từ chối (tối thiểu 50.000 đ) |
| Giao hàng (Seller) | mã vận đơn `123` | bị chặn, cần 8 đến 20 ký tự |
| Phòng đấu giá | trả giá thấp hơn mức tối thiểu | "Giá đã thay đổi, mức tối thiểu hiện tại là …" |
| Phòng đấu giá | đăng nhập `buyer7@rebook.vn` rồi trả giá | bị chặn: còn nợ phạt chưa thanh toán |
| Đăng nhập | `locked@rebook.vn` hoặc `banned@rebook.vn` | tài khoản bị khoá / bị cấm đấu giá |

## Phụ lục B. Nếu có sự cố giữa chừng

| Sự cố | Cách xử lý nhanh |
|---|---|
| Ảnh bìa không hiện trên máy ảo | máy ảo chưa bật bằng `-dns-server`: tắt, bật lại bằng lệnh ở phần 0, bước 2 |
| App quay mãi / lỗi mạng | backend chưa chạy: mở `http://localhost:8081/categories` phải ra JSON; chưa thì chạy lại `reset-demo` |
| Chọn ảnh không thấy ảnh nào | thư viện ảnh máy ảo trống: kéo ảnh vào cửa sổ máy ảo |
| Phiên #4 không "Mở ngay" được | chưa đủ 3 người: kiểm tra `buyer1` đã hiện "Bài #003" |
| Lô đấu giá đã đóng trước khi trả giá | sang lô kế tiếp, mỗi lô khoảng 2 phút |
| Web chậm lần đầu mở mỗi màn | bản debug nạp từng phần: mở trước các màn sẽ dùng khi chuẩn bị |
| Làm hỏng dữ liệu | chạy lại `reset-demo` (3 phút); phiên đấu giá #3 tự mở sau khoảng 4 phút và kéo dài khoảng 10 phút, dùng được như phương án thay thế |

## Phụ lục C. Thứ tự rút gọn nếu chỉ có 8 phút

Cảnh 2 (mua sách) → cảnh 3a (đăng sách) → cảnh 5 (đấu giá, bỏ bước thanh toán) → cảnh 4b mục 1, 2 (dashboard, xuất PDF).
