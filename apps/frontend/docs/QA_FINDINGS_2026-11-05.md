# ReBook — kết quả test theo TEST_GUIDE (05/11/2026)

Nguồn kịch bản: `docs/TEST_GUIDE.md` + báo cáo Android của tester trước (PDF `ReBook_TEST_GUIDE_Android_2026-11-04.pdf`, lỗi A01–A08).
Bản test: frontend = `origin/interface` (+ địa chỉ dùng chung, khung xương loading, nút phát lại intro), backend = `origin/main`, DB mẫu, nối backend thật ở cổng 8081.
Cách test: (1) gọi API backend thật theo từng kịch bản (183 kiểm tra, 160 đạt); (2) bấm tay trên máy ảo Android 1080×2400 cho các lỗi của tester trước và một số màn khác.
Không test được: ZaloPay sandbox (cổng không mở form thẻ), thông báo đẩy, kéo-thả bản đồ, bản web, mất mạng giữa phiên (4.16), các việc phải chờ 15 phút – 48 giờ (3.13, 4.22, 6.14), bấm tay màn Admin phần duyệt rút tiền.
Sau test đã tạo lại DB về dữ liệu mẫu.

## Mức Chặn (đi không tiếp được luồng chính) — ĐÃ SỬA cả 3 (cùng ngày)

| # | Lỗi | Cách thấy | Cách đã sửa |
|---|---|---|---|
| 1 | **Admin không duyệt được yêu cầu rút tiền trong app** (6.11) | Frontend gửi giờ chuyển khoản dạng giờ máy, không có múi giờ (`2026-11-05T10:24:01.123`); backend trả 400 "JSON parse error … Instant". Code: `withdrawals_screen.dart:172,213` dùng `DateTime` local, `api_admin_repository.dart:253` truyền thẳng | **Đã sửa**: gửi `transferredAt.toUtc()`; test `api_admin_withdrawal_test.dart` bắt request thật (hỏng khi bỏ `toUtc`). Chưa bấm tay được vì phải chọn ảnh biên lai từ thư viện máy ảo |
| 2 | **Người bán không có nút "Đã giao" / "Giao thất bại"** (A02, 3.10–3.11) | Đơn ODDEMO000002 đang giao: cuối màn trống. Nút chỉ hiện khi `Env.useMock` (`seller_order_detail_screen.dart:247`) nên nối backend thật thì đơn kẹt "Đang giao", kéo theo 2.18–2.22 không test được | **Đã sửa**: đơn đang giao hiện "Giả lập: đã giao thành công" và "Giao thất bại" (hỏi lý do); đã bấm thử trên máy ảo, đơn ODDEMO000002 sang DELIVERED. Backend chỉ chấp nhận hai nút này ở môi trường dev |
| 3 | **Màn "Phiên đấu giá" của Staff tải mãi** (A03, 5.1) | Staff thấy 5 mục menu (thừa "Phiên đấu giá", `admin_module.dart:112-115` có `staff: true`); màn gọi `GET /admin/sessions` → 403 nên hiện khung xương mãi, không có thông báo lỗi. Hướng dẫn test chỉ cho Staff 4 mục | **Đã sửa**: giữ mục menu theo SRS 2 (Staff xem danh sách phiên + giám sát), danh sách của Staff gọi API công khai `/sessions`; đã thấy phiên hiện đúng trên máy ảo. Hướng dẫn test vẫn ghi Staff 4 mục: cần thống nhất lại với tài liệu |

## Mức Nặng (sai nghiệp vụ hoặc người dùng bị báo sai) — ĐÃ SỬA cả 7 (cùng ngày)

| # | Lỗi | Cách thấy | Cách đã sửa |
|---|---|---|---|
| 4 | **Đăng nhập sai mật khẩu báo "Phiên đăng nhập đã hết hạn"** (A04, 1.15) | Backend trả đúng `INVALID_CREDENTIALS` / "Email hoặc mật khẩu không đúng" (401); app gặp 401 là báo hết hạn (`error_mapper` tại `status == 401`) | **Đã sửa**: Màn đăng nhập giờ hiện "Email hoặc mật khẩu không đúng." (401 mang mã `INVALID_CREDENTIALS` không còn bị coi là hết phiên). Đã thử trên máy ảo |
| 5 | **Đăng ký: mật khẩu 6–7 ký tự lọt qua form** (1.12) | Form ghi "Ít nhất 6 ký tự" (`input_rules.dart:137`), backend yêu cầu 8–72 → 400, app báo chung "Máy chủ gặp lỗi. Vui lòng thử lại sau." | **Đã sửa**: Mật khẩu mới (đăng ký, đặt lại) dùng luật 8–72 ký tự, báo "Nhập từ 8 đến 72 ký tự" ngay ở ô; lỗi `VALIDATION_ERROR` của backend hiện theo từng ô. Đã thử trên máy ảo |
| 6 | **Đăng ký: số `+84…` không được đổi thành `0…`** (1.13) | Form cho nhập `+84901234999`, chỉ bỏ khoảng trắng (`input_rules.dart:127`); backend từ chối "Số điện thoại không hợp lệ" → cũng báo "Máy chủ gặp lỗi" | **Đã sửa**: Số `+84…` đổi thành `0…` trước khi gửi; đăng ký bằng `+84901234xxx` sang được bước nhập OTP. Đã thử trên máy ảo |
| 7 | **Số tiền rút tối thiểu lệch: app 10.000đ, backend 50.000đ** (A05, 3.16) | `wallet_providers.dart:38` `minAmount = 10000`; nhập 20.000đ → backend 400 "Rút tối thiểu 50.000đ" → app báo "Dữ liệu không hợp lệ" | **Đã sửa**: Rút tối thiểu 50.000đ (nạp vẫn 10.000đ); ô nhập ghi "Tối thiểu 50.000 đ", 20.000đ không bấm Tiếp được. Đã thử trên máy ảo |
| 8 | **Xoá danh mục còn con báo sai nguyên nhân** (A08, 6.5) | Backend trả 409 `HAS_CHILDREN` "Hãy xoá danh mục con trước"; app chỉ hiện "Dữ liệu vừa thay đổi. Hãy tải lại và thử lại" | **Đã sửa**: Lỗi 409 hiện đúng câu của backend: "Hãy xoá danh mục con trước". Đã thử trên máy ảo |
| 9 | **Ảnh sản phẩm trong đơn là ảnh ngẫu nhiên, không phải bìa sách** | Đơn của shop, chi tiết đơn: "Tắt Đèn" hiện ảnh ruộng lúa, "Sapiens" hiện ảnh núi (ảnh `picsum`) | **Đã sửa**: Đơn hàng (danh sách, chi tiết) dùng bìa đóng gói sẵn theo tên sách. Đã thử trên máy ảo |
| 10 | **Phí ship khác nhau giữa Giỏ hàng và Xác nhận đặt hàng** (A07, 2.9–2.11) | Giỏ: "Phí vận chuyển 0 đ", tổng 160.000đ; bước xác nhận: ship 30.000đ, tổng 190.000đ (đã chụp trên máy ảo) | **Đã sửa**: Giỏ hàng ghi "Tính khi thanh toán" ở từng shop và tổng, thay cho "0 đ". Đã thử trên máy ảo |

## Mức Nhẹ (backend) — ĐÃ SỬA #11–#14 và #16 (cùng ngày, commit riêng ở apps/backend)

| # | Lỗi | Kết quả |
|---|---|---|
| 11 | Đăng nhập sai nhiều lần không bị chặn (12 lần liên tiếp vẫn 401) | **Đã sửa**: 10 lần sai trong 15 phút thì trả 429 `TOO_MANY_REQUESTS`, đăng nhập đúng cũng bị chặn tới hết thời gian, email khác không ảnh hưởng; bộ đếm nằm trong bộ nhớ nên mất khi khởi động lại backend |
| 12 | Gọi sai phương thức (vd `GET /lots/2/bids`, `PATCH /cart`) trả **500** thay vì 405 | **Đã sửa**: trả 405 `METHOD_NOT_ALLOWED` |
| 13 | Backend không kiểm tra ISBN, số tài khoản ngân hàng (chấp nhận `abc`, `12ab`) | **Đã sửa**: ISBN rỗng hoặc 10 / 13 ký tự, số tài khoản 6–19 chữ số, sai thì 400 kèm `fieldErrors`. Cập nhật `openapi.yaml` (hai dòng `pattern`) |
| 14 | Sơ duyệt ký gửi "Không đạt" không bắt buộc lý do (`reviewNote` rỗng vẫn nhận) | **Đã sửa**: sơ duyệt Không đạt thiếu lý do (kể cả toàn khoảng trắng) trả 400 `REASON_REQUIRED` |
| 15 | Rút tiền cho phép tên chủ tài khoản khác họ tên trong hồ sơ | **Không sửa theo ý bạn**: quy tắc khớp họ tên đã bỏ có chủ ý ở đợt rollback |
| 16 | Nhật ký hoạt động chỉ thấy LOCK / UNLOCK / UPDATE_CONFIG trong lượt test; duyệt tin / từ chối tin chưa kiểm lại sau khi tạo lại DB | **Không phải lỗi**: duyệt / từ chối tin đã ghi `APPROVE_LISTING` / `REJECT_LISTING`; lần trước chỉ thiếu vì tạo lại DB trước khi kiểm. Đã kiểm lại trên backend thật |

## Mức Giao diện / nội dung — ĐÃ SỬA #17–#20 (cùng ngày)

| # | Lỗi | Cách thấy / cách đã sửa |
|---|---|---|
| 17 | **Ô "Mã vận đơn" hiện chữ gợi ý sai**: "Tình trạng, ghi chú, điểm đáng chú ý…" (A06) | **Đã sửa**: ô mã vận đơn gợi ý `VN123456789`, ô mã kệ của Staff dùng luật riêng (nhận cả `A3-12` và `A-02-01` của kho). Đã thử trên máy ảo |
| 18 | Lịch sử đơn ghi nguyên enum: "Đã thanh toán (WALLET)" | **Đã sửa**: lịch sử đơn ghi "Đã thanh toán (Ví ReBook)". Đã thử trên máy ảo |
| 19 | Thanh điều hướng nổi che chữ "Đăng xuất" ở màn Tài khoản | **Đã sửa**: màn Tài khoản chừa chỗ cuối, cuộn lên thì "Đăng xuất" nằm trên thanh điều hướng. Đã thử trên máy ảo |
| 20 | Khung xương mặc định luôn 5 dòng nên màn Ví nhảy bố cục khi tải xong | **Đã sửa**: màn Ví có khung xương đúng dạng (thẻ số dư + 3 dòng giao dịch). Đã thử trên máy ảo |

## Không tái hiện được / không phải lỗi

| Mã | Kết quả |
|---|---|
| A01 (không mở được form đăng ký) | **Không tái hiện**: khách → Chi tiết → tim → "Đăng ký" mở đúng form. Code còn `location.endsWith('/register')` ở `routes.dart:92` nên nên dọn, nhưng form mở bình thường |
| 2.18b (tiền người bán) | Đúng thiết kế: người bán nhận giá sách + ship, trừ 5% phí trên giá sách (325.000 − 15.000 = 310.000) |
| 4.21 (lịch sử trả giá) | API `/lots/{id}` không trả danh sách lượt trả; lịch sử nằm ở `recentBids` của trạng thái phiên. Chưa kiểm màn |
| ZaloPay (A điểm cần kiểm chứng thêm) | Backend tạo được link thanh toán thật (`qcgateway.zalopay.vn`) nhưng chưa test được trang thanh toán |

## Đã đạt (qua API trên backend thật)

- **Khách / đăng ký:** tìm kiếm, lọc, sắp xếp; chặn khách ở giỏ / ví / đơn / trả giá; đăng ký trùng email; OTP sai / đúng; quên mật khẩu; mật khẩu cũ hết dùng.
- **Người mua:** địa chỉ + loại + ghim, yêu thích, giỏ 2 shop, ship đổi theo địa chỉ, đặt bằng ví / COD / ZaloPay, trả lại bằng ví, huỷ đơn có hoàn tiền, xin huỷ đơn đang chuẩn bị (đồng ý / từ chối), giao thất bại có hoàn tiền, trả hàng (1–10 ảnh), rút yêu cầu, shop đồng ý / từ chối, Admin phân xử, đánh giá một lần, nạp tối thiểu 10.000đ.
- **Người bán:** đăng tin cần 3 ảnh, tin shop mới chờ duyệt, tồn kho 0 thành hết hàng, ẩn / hiện tin, duyệt / từ chối tin (bắt buộc lý do), rút tiền (chặn dưới 50.000đ, quá số dư; số tiền chuyển sang "Đang khoá"), biên lai Admin (thiếu / sai số tiền / giờ tương lai bị chặn).
- **Đấu giá (chạy trọn một phiên, 3 lô):** Staff / Admin không đăng ký được; thiếu SĐT / ví bị chặn; trả giá, người dẫn hiện bằng số bài; hai người trả cùng lúc chỉ một thành công; vượt hạn mức bị chặn; proxy bid; gia hạn khi còn dưới 15 giây; lô không ai trả → Không bán; hoàn cọc người không thắng; hoá đơn = giá búa + 10% − cọc; không huỷ được; trả bằng ví; Staff giao đơn đấu giá.
- **Staff / Admin:** Staff bị chặn mọi API admin; ký gửi tối thiểu 300.000đ; lịch hẹn chỉ 8:00–17:00 trong 7 ngày; mã lịch hẹn sai báo 404; nhận sách, kiểm định (chặn ước giá ngược, giá sàn < khởi điểm); khoá / mở khoá người dùng; danh mục thêm / sửa / chặn xoá; cấu hình chặn giá trị vô lý; tạo phiên (chặn giờ quá khứ), xếp lô, công bố.

## Gợi ý thứ tự sửa

1. Mục 1, 2, 3 (chặn): mỗi cái vài dòng, đều nằm ở frontend.
2. Mục 4, 5, 6, 8: cùng một gốc, app không hiển thị lỗi thật của backend; sửa chung ở chỗ map lỗi + form đăng ký.
3. Mục 7, 9, 10, 17: sửa nhỏ, dễ thấy khi demo.
4. Backend (mục 11–14): làm sau, ít thấy khi demo.


## Lỗi phát sinh khi sửa nhóm Nặng

- **Lỗi đăng nhập dính sang màn đăng ký** (đã sửa): sau khi đăng nhập sai, mở màn đăng ký vẫn thấy câu "Email hoặc mật khẩu không đúng". Trước đây lỗi chung chung nên không thấy. Nay mỗi màn đăng nhập / đăng ký / quên mật khẩu xoá lỗi cũ khi mở.

---

# Vòng 2 — chạy lại toàn bộ TEST_GUIDE sau khi sửa (05/11/2026)

Cách làm: tạo lại DB, chạy lại 7 nhóm kịch bản API trên backend thật (Vai 1–6, gồm một phiên đấu giá trọn vẹn 3 lô), rồi bấm tay trên máy ảo Android (khách, người mua, người bán, đấu giá, Staff, Admin) và mở bản web ở 1440px và 375px.
Kết quả API: toàn bộ đạt, trừ **một lỗi thật** (V2-1). Bấm tay thêm được **5 điểm** (V2-2 đến V2-6).

| # | Mức | Lỗi | Cách thấy | Gợi ý sửa |
|---|---|---|---|---|
| V2-1 ✅ | **Nặng** (bảo mật) | **Mã OTP dò được vô hạn lần** (1.10b) | Nhập sai OTP 8 lần liên tiếp rồi nhập đúng vẫn được chấp nhận. Backend có giới hạn 5 lần nhưng số lần sai bị hoàn lại cùng giao dịch báo lỗi nên không bao giờ được lưu. Mã 6 số nên dò hết trong vài phút | **Đã sửa** (commit backend riêng): số lần sai lưu trong giao dịch riêng, sai 5 lần thì mã đúng cũng bị từ chối, xin mã mới thì dùng lại được. Có test `InputGuardsTest` và đã thử trên backend thật |
| V2-2 ✅ | **Nặng** | **Trang phiên đấu giá không tự cập nhật khi Admin mở phiên** | Đang mở trang phiên thì Admin bấm mở phiên: trang vẫn ghi "Đang nhận đăng ký", không có nút vào phòng, chờ hơn 20 giây không đổi. Thoát ra vào lại mới thấy "LIVE". Người mua có thể bỏ lỡ phiên | **Đã sửa**: danh sách phiên và trang phiên tự tải lại mỗi 15 giây, giữ nội dung cũ trong lúc tải (không nháy khung xương). Có test `session_refresh_test.dart`; đã thử trên máy ảo: Admin mở phiên, trang tự đổi sang "Đang diễn ra" kèm nút "Vào phòng đấu giá" sau chưa tới 25 giây |
| V2-3 ✅ | Giao diện | **Phòng đấu giá ghi "0 người xem"** | Header phòng đấu giá, backend không gửi số người xem | **Đã sửa**: không hiện "N người xem" khi N = 0 (phòng đấu giá, thẻ phiên, màn giám sát và tổng quan của Admin). Đã thử trên máy ảo |
| V2-4 ✅ | Giao diện | **Form địa chỉ mới ghi "Đã ghim vị trí" khi chưa chọn gì** | Mở "Thêm địa chỉ mới": ghim đã nằm giữa biển cạnh nhãn Hoàng Sa. Chưa kiểm xem lưu có ghi toạ độ giả này không | **Không phải lỗi**: "Đã ghim vị trí" chỉ hiện sau khi người dùng chạm hoặc kéo bản đồ; lúc test tôi vô tình kéo bản đồ khi cuộn trang. Form trống ghi gợi ý bình thường |
| V2-5 ✅ | Nhẹ | **Số người đăng ký của phiên đã kết thúc bị đếm lại** | Phiên có 2–3 người tham gia, sau khi kết thúc và hoàn cọc danh sách ghi "0 người" hoặc "1 người đã đăng ký" (cả `/sessions` lẫn Staff) | **Đã sửa** (commit backend riêng): vẫn đếm đăng ký đã hoàn cọc, phiên kết thúc không còn ghi "0 người". Có test backend |
| V2-6 ✅ | Nhẹ | **Nhật ký hoạt động hiện khoá cấu hình thô** | "Đặt `fee.fixed_price_percent` = 7" | **Đã sửa**: nhật ký ghi "Đặt Phí bán giá cố định (%) = 5" thay cho khoá thô. Đã thử trên máy ảo |
| V2-7 ✅ | Cần kiểm | **Khu đấu giá có thể không đọc được bằng trình đọc màn hình** | Công cụ dump giao diện Android khi đang ở khu đấu giá (nền tối) chỉ thấy nội dung khu mua sách, không thấy chữ của khu đấu giá. Chưa kiểm bằng TalkBack | **Chưa kết luận**: cần mở TalkBack thật; công cụ dump chỉ có thể do cây truy cập chuyển giữa hai khu chưa kịp làm mới |

Không tái hiện được trong vòng này: A01.
Chưa test được: lưu form địa chỉ, quét bìa và tải ảnh (phải chọn ảnh từ thư viện máy ảo), thanh toán ZaloPay, thông báo đẩy, mất mạng giữa phiên, các việc phải chờ 15 phút đến 48 giờ.
Bản web: dựng được ở 1440px và 375px, tải được dữ liệu từ backend, không thấy tràn; lần đầu tải mất khoảng 10–20 giây trang trắng (đã ghi trong TEST_GUIDE).

## Lần chạy lại cuối (sau khi sửa xong V2-1 … V2-6)

- **API, backend thật, DB sạch:** 7 nhóm kịch bản (Vai 1–6 + một phiên đấu giá trọn vẹn 3 lô): 182 kiểm tra đạt, 2 không đạt đều do lỗi của script test, không phải lỗi app: 2.5a thiếu token trong script (đã đạt khi chạy ở nhóm Người mua) và 2.10 so tổng phí ship thay vì từng shop (phí từng shop khác nhau đúng: 30.000 / 25.000 ở TP.HCM, 20.000 / 35.000 ở Hà Nội).
- **Tự động:** backend 50 test, frontend 173 test, `dart analyze --fatal-infos` và `arch_check` đều qua.
- **Máy ảo:** thử lại đăng nhập sai (báo đúng "Email hoặc mật khẩu không đúng."), giỏ hàng, danh sách đơn mua (bìa sách đúng, đủ trạng thái đã trả hàng / đã huỷ / giao thất bại / hoàn tất).
- **Vẫn chưa test được:** ZaloPay, tải ảnh từ thư viện máy ảo, lưu form địa chỉ trên máy ảo, thông báo đẩy, TalkBack (V2-7).
