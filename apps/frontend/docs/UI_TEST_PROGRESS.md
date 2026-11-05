# Cột mốc test tay (giao diện) theo TEST_GUIDE

Cập nhật lần cuối: 05/11/2026. File này để phiên làm việc sau đọc lại và đi tiếp mà không phải làm lại.

## Trạng thái repo lúc bắt đầu đợt test tay
- Nhánh `main`, hơn `origin/main` 5 commit, **chưa push** (người dùng chưa cho phép). Commit không được có dòng `Co-Authored-By` hay tên Claude.
  - `9d25426`, `1c04db7`, `1f69605`: backend (chặn dò mật khẩu, 405, ISBN / số tài khoản, lý do từ chối, OTP, đếm đăng ký).
  - `3ea1ff6`: frontend đồng bộ từ `interface` + các sửa lỗi sau test.
  - `48e8087`: màn Mở shop khi backend trả 403 + chữ gợi ý ô giới thiệu.
- Bản backend cũ hơn (đã bỏ theo ý người dùng, gồm COD, trả hàng có bước gửi lại, mặc định không dev, test end-to-end): nhánh `backup/before-rollback-2026-11-05`.
- Hai file audit nghiệp vụ (`AUDIT_BACKEND.md`, `AUDIT_FRONTEND.md`) **gác lại**, làm sau. Kết quả đối chiếu: gần như chưa mục nào xong. Gói 13 mục an toàn đã đề xuất (BE-32, BE-26 còn lại, BE-33, BE-35 + FE-07, BE-05, BE-13, BE-29, BE-40, FE-01, FE-02, FE-11, FE-09) chưa làm.

## Lưu ý khi mở lại máy
- Sau khi máy khởi động lại: mở Docker Desktop, `docker start rebook-db`, chạy backend `PORT=8081 ./mvnw spring-boot:run` trong `apps/backend` (KHÔNG chạy `resetdb.sh`, nó xoá dữ liệu test), bật lại máy ảo Android và cài lại app nếu cần.

## Cách chạy lại môi trường
- Backend chạy cổng **8081** (cổng 8080 bị dịch vụ MiniTool `MTAgentService` chiếm). Database Docker `rebook-db`.
- Công cụ trong `docs/qa-tools/` (chép từ thư mục tạm, cần sửa đường dẫn `S=` / `L=` trong `ui.sh` và `resetdb.sh` cho đúng máy):
  - `resetdb.sh`: dừng backend, tạo lại database, chạy backend (nạp dữ liệu mẫu).
  - `ui.sh`: hàm điều khiển máy ảo qua adb (`login_as email`, `tap "chữ"`, `tapxy x y`, `edit n "giá trị"`, `shot tên`, `ls_ui`).
  - `lib.mjs` + `g1…g6.mjs`: kịch bản API (chạy `node gN.mjs`, g5 là phiên đấu giá trọn vẹn, chạy sau khi tạo lại DB). `android.8081.json.example`: file cấu hình app cho máy ảo (`10.0.2.2:8081`).
- App Android: `flutter build apk --debug --dart-define-from-file=<android.8081.json>` rồi `adb install -r -t`.
- Tài khoản mẫu, mật khẩu `Rebook@123`: `buyer1..3`, `seller1`, `seller2`, `staff`, `admin` (đuôi `@rebook.vn`). `buyer3` chưa có shop.
- Mẹo máy ảo: bàn phím nổi che nút dưới; bấm `Back` một lần để ẩn bàn phím, bấm lần hai sẽ thoát màn. Kéo trang qua vùng bản đồ sẽ kéo bản đồ (dùng vùng ngoài bản đồ để cuộn). `adb input text` không gõ được dấu cách thường.
- Công cụ dump giao diện không thấy chữ của khu đấu giá (nền tối): dùng toạ độ cho khu này.

## Đã test tay trước đó (bằng giao diện, máy ảo)
Đăng nhập sai / đúng, đăng ký (mật khẩu 7 ký tự, +84), giỏ hàng, xác nhận đặt hàng + đổi địa chỉ, danh sách và chi tiết đơn, ví, rút tiền (bước nhập số tài khoản và số tiền), đơn của người bán (xác nhận, giao cho shipper, đã giao), Mở shop (form hiện), đăng ký phiên đấu giá + vào phòng + trả giá, các màn Admin và Staff (mở được, không lỗi), bản web 1440px / 375px.

## Tiến độ đợt test tay này (đánh dấu khi xong)
Quy ước: ✅ đạt · ❌ lỗi (ghi lỗi bên dưới) · ⏭ bỏ qua có lý do · ⬜ chưa làm

| Nhóm | Trạng thái | Ghi chú |
|---|---|---|
| Vai 1: khách (1.1–1.15) | ⏳ làm dở | ✅ 1.1 intro, 1.2 trang chủ, 1.3 tìm theo tác giả ("Dale" ra Đắc Nhân Tâm), 1.6 khách xem phiên đấu giá và bấm Đăng ký thì sang màn "Cần đăng nhập". ⬜ chưa làm: 1.3 lọc / sắp xếp bằng giao diện, 1.4 chi tiết sách, 1.5 tim → đăng nhập → quay lại đúng cuốn, 1.8–1.15 đăng ký / OTP / quên mật khẩu bằng giao diện (lấy OTP trong bảng `otp_codes` hoặc phản hồi `devOtp`) |
| Vai 2A–2B: địa chỉ, hồ sơ, yêu thích, giỏ | ⬜ | |
| Vai 2C–2E: đặt hàng, theo dõi, nhận hàng, trả hàng, ví, thông báo | ⬜ | |
| Vai 3: mở shop → đăng tin → xử lý đơn → rút tiền | ⏳ làm dở | ✅ 3.1 Mở shop bằng giao diện (buyer3 → shop "Time Sach QA"). ✅ 3.2–3.4 đăng tin đầu tiên: chọn ảnh bìa từ thư viện + chỉnh 4 góc, thêm 3 ảnh thật, điền form, Lưu → tin "Tat Den" 60.000 ₫ trạng thái **Chờ duyệt** (đúng cho shop mới). ✅ admin duyệt tin "Tat Den" qua API → ACTIVE (6.2 chỉ mới thử bằng API, chưa bằng giao diện Admin; lỡ duyệt luôn tin mẫu id 9 "Rừng Na Uy"). ✅ sau khi duyệt, tin hiện "Đang bán" ở Tin đăng, trang chủ người mua có sách mới, Kênh người bán ghi "Tin đang bán 1". ✅ 3.6 Ẩn tin → Đã ẩn (DB HIDDEN) rồi Hiện lại → Đang bán (DB ACTIVE). ✅ xử lý đơn của shop trên giao diện: đơn mới (buyer1 mua bằng ví) hiện ở "Chờ xác nhận 1" → Xác nhận đặt hàng → Giao cho shipper (có mã vận đơn tự sinh) → Giả lập đã giao; buyer1 xác nhận nhận hàng (API) → COMPLETED, ví shop nhận tiền bán, trừ phí sàn 3.000 ₫. ✅ rút tiền bằng giao diện: chọn VCB, số tài khoản, tên chủ, 100.000 ₫ → "Đã gửi yêu cầu rút tiền / Đang xử lý"; admin duyệt (API, kèm biên lai) → APPROVED, ví khớp. ⬜ chưa làm: hết hàng khi sửa số lượng về 0 (3.7) |
| Vai 4: ký gửi, đăng ký, trả giá, hoá đơn | ⏳ làm dở | ✅ 4.1 danh sách ký gửi của seller1 hiện đủ trạng thái (Đã đặt lịch, Đã kiểm định chờ quyết định, Đã thành lô). ✅ gửi yêu cầu ký gửi bằng giao diện: giá 250.000 ₫ bị chặn ngay "Tối thiểu 300.000 đ" (lỗi nằm đúng ô, khác U-2), câu chuyện < 20 ký tự bị chặn "Nhập từ 20 đến 1000 ký tự"; giá 400.000 ₫ → "Chờ sơ duyệt" và thông báo "ReBook sơ duyệt trong 48 giờ". ⬜ chưa làm bằng giao diện: Staff duyệt, đăng ký phiên + đặt cọc, vào phòng trả giá, hoá đơn lô thắng. Phiên mẫu số 1 mở lúc 07/11/2026 nên chưa chạy trực tiếp được; phần trả giá / soft close / thanh toán lô thắng đã có kết quả API (g5). |
| Vai 5: Staff | ✅ một phần | Staff thấy yêu cầu ký gửi vừa gửi của seller1 ("Sach Co QA", 400.000 ₫) ở "Chờ sơ duyệt". Từ chối: nút Xác nhận bị khoá tới khi chọn lý do; chọn "Ảnh không rõ" → DB REJECTED, review_note đúng. ⬜ chưa làm: Duyệt → lịch hẹn, nhận sách, kiểm định, Kho, Giao lô |
| Vai 6: Admin | ✅ một phần | Menu quản trị đủ mục (Bảng điều khiển, Duyệt tin đăng, Khiếu nại, Người dùng, Danh mục, Phiên đấu giá, Ký gửi, Lịch hẹn, Kho, Giao lô, Cấu hình phí, Nhật ký, Rút tiền). Mở Duyệt tin đăng ("Đã xử lý gần đây" ghi tin Tat Den duyệt bởi Quản trị ReBook), Phiên đấu giá, Rút tiền (trống vì đã duyệt) đều dựng đúng, không lỗi. ⬜ chưa làm bằng giao diện: duyệt tin / rút tiền bằng nút, khiếu nại trả hàng, người dùng, danh mục, cấu hình phí, nhật ký |

## Lỗi tìm thấy trong đợt này
- **U-1 (Nhẹ, giao diện, chưa sửa):** khách bấm "Đăng ký tham gia" ở trang phiên đấu giá thì sang màn cổng đăng nhập có tiêu đề **"Nội dung này"** (chuỗi `gateFeatureGeneric` dùng làm tiêu đề) và **không có nút quay lại**. Gợi ý: tiêu đề "Đăng ký tham gia đấu giá" hoặc "Cần đăng nhập", thêm nút quay lại.

- **U-2 (Nhẹ, giao diện, chưa sửa):** form Đăng sách. Ô `Khối lượng` (và `Số trang`, `NXB`…) hiện chữ mờ gợi ý trông như đã điền, nhưng `Khối lượng` bắt buộc: bấm Lưu thì nút **không làm gì nhìn thấy được**, lỗi đỏ nằm ở ô đang cuộn ra khỏi màn (ô Tên sách trống cũng vậy). Gợi ý: sau khi Lưu thất bại, cuộn tới ô lỗi đầu tiên hoặc hiện thông báo; ghi rõ ô bắt buộc.
- **U-4 (Nhẹ, chữ hướng dẫn sai, chưa sửa):** màn Rút tiền ghi "Tiền chỉ bị trừ khỏi ví khi Admin duyệt và chuyển khoản" (cả màn kết quả), nhưng thực tế ngay khi gửi yêu cầu số dư khả dụng giảm 100.000 ₫ và chuyển sang "Đang khoá" (2.587.000 → 2.487.000, khoá 500.000 → 600.000); khi admin duyệt thì khoản khoá mới biến mất. Sửa chữ cho đúng: "Tiền được giữ lại ngay, trừ hẳn khi Admin duyệt; bị từ chối thì hoàn lại".
- **U-3 (không phải lỗi app, thao tác máy ảo):** bấm `Back` khi bàn phím không hiện sẽ thoát / làm mất form đang điền; dùng chạm vào vùng trống để ẩn bàn phím.

## Ghi chú khi test
- Công cụ dump giao diện (`uiautomator`) đôi lúc trả cây cũ sau khi chuyển màn, nhất là khi vừa chuyển giữa khu mua sách và khu đấu giá: tin ảnh chụp màn hình (`shot`) hơn tin `ls_ui`, và bấm theo toạ độ khi nghi ngờ. Đây cũng là dấu hiệu cho điểm V2-7 (trình đọc màn hình) chưa kết luận.
- Thanh điều hướng dưới: bấm nút tròn trái dưới (152, 2200) để mở, rồi bấm tab theo toạ độ x: Mua sách 152, Khám phá 346, Giỏ hàng 540, Thông báo 734, Tài khoản 928 (y = 2200). `tap "Khám phá"` sẽ trúng tiêu đề trang chứ không phải tab.
- Việc nên làm tiếp theo thứ tự: Vai 2 (địa chỉ lưu bằng giao diện, đặt hàng ví / COD, huỷ, nhận hàng, đánh giá, trả hàng) → Vai 3 (Mở shop đến lúc đăng tin đầu tiên, vì lỗi "Mở shop" từng lọt qua) → Vai 4 → Vai 5 → Vai 6.
