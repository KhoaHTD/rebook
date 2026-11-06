# Cập nhật giao diện theo backend nghiệp vụ mới (nhánh `ui-sync-business-rules`)

Cập nhật 06/11/2026. Nhánh làm việc `ui-sync-business-rules` = `main` + `origin/improve_bussinessrule` (backend nghiệp vụ mới của Phitruong) + phần frontend dưới đây. **Chưa push, chưa merge vào `main`.**

Việc làm bám bảng "Việc frontend phải làm" trong `docs/AUDIT_FRONTEND.md` của nhánh backend.

## Đã làm (code, `dart analyze`, `arch_check`, 178 test đạt; chưa test tay trên máy ảo)

| Mục | Nội dung | Ở đâu |
|---|---|---|
| Client API | Sinh lại từ `apps/backend/openapi.yaml` mới | `lib/api/generated` |
| Mã lỗi mới | `TOPUP_LOCKED`, `WITHDRAW_DAILY_LIMIT`, `COD_NOT_ALLOWED`, `DEBT_OPEN`, `STAFF_CANNOT_BID`, `INVALID_ISBN`, `INVALID_PRICE`, `BOOK_IN_WAREHOUSE`, `TOO_MANY_REQUESTS` có chuỗi tiếng Việt / Anh; lỗi nghiệp vụ 400 / 403 / 409 / 429 khác hiện câu của backend thay vì "Máy chủ gặp lỗi"; bỏ đoạn dò chuỗi câu chữ ở `FORBIDDEN` (FE-07) | `core/error/app_exception.dart`, `shared/widgets/error_view.dart` |
| Ví | Hiện tiền mới nạp đang khoá và giờ mở khoá; màn Rút tiền chỉ cho rút phần "rút được ngay" (`GET /wallet/withdrawable`) | `Wallet.locked / unlockAt / withdrawable`, `wallet_screen.dart`, `withdraw_screens.dart` |
| Nợ | Khung "Khoản nợ chưa thanh toán" trong ví: nợ phạt bỏ thanh toán, phí kho, nút thu nợ từ ví | `wallet/presentation/widgets/debt_panel.dart` |
| Đơn (người mua) | Nút "Đã nhận hàng" ngay khi đơn đang giao; trả hàng nhiều bước: thấy nơi gửi và hạn gửi, nút "Gửi hàng trả" nhập mã vận đơn; thấy trạng thái đã gửi | `order_detail_screen.dart` |
| Đơn (shop) | Thấy "chờ người mua gửi hàng trả" / mã vận đơn hàng trả; nút "Đã nhận lại sách, hoàn tiền" | `seller_order_detail_screen.dart` |
| Đấu giá | Nút "Huỷ đăng ký" (trước hạn đăng ký, hoàn đủ cọc), trạng thái `CANCELLED` | `session_screen.dart`, `auction_providers.dart` |
| Staff | Màn "Đối chiếu vận chuyển": đơn đang giao, nút "Đã giao thành công" / "Giao thất bại" (đơn COD chỉ đi tiếp khi có kết quả này) | `features/staff/.../carrier_screen.dart` |
| Admin | Màn "Đối soát COD": đơn COD đã giao chờ sàn nhận tiền, nút "Đã nhận tiền COD" | `features/admin/.../cod_screen.dart` |
| Dữ liệu giả | Trả hàng nhiều bước chạy được ở chế độ mock; COD / nợ không có ở mock | `shared/data/fake/` |

## Đã làm thêm ngày 06/11/2026 (tối)

| Phần | Nội dung |
|---|---|
| Người mua | Trả hàng chọn "Sách không đúng mô tả" (cần ảnh) hoặc "Chưa nhận được hàng" (không cần ảnh) |
| Shop | Yêu cầu huỷ của người mua: "Đồng ý hủy" hoặc "Từ chối hủy" (đơn đi tiếp) |
| Admin | "Mở ngay" và "Hủy phiên" ở danh sách phiên; menu mỗi người dùng: đổi vai trò, gỡ cấm đấu giá (hiện khi đang bị cấm) |
| Staff | Màn "Sự cố & kiểm lại": kiểm định lại lô bị trả về kho (đạt / không đạt), khai báo sự cố kho từ màn Kho; Admin duyệt (nhập % bồi thường) hoặc từ chối trong cùng màn |
| Staff | Màn Giao lô đấu giá: nút giao thất bại (chọn bên có lỗi), đồng ý / từ chối trả hàng, đã nhận lại sách |
| Tài khoản | Cài đặt: đổi mật khẩu; đăng xuất báo backend huỷ refresh token; đặt giá tự động có nút hủy |

## Chưa làm

- Admin: nút miễn nợ (`POST /admin/debts/{id}/waive`): backend chưa có API liệt kê nợ của người dùng cho Admin nên chưa có chỗ để bấm; nhãn tiếng Việt cho các cấu hình mới trong màn Cấu hình phí; đánh dấu shop uy tín (`PUT /admin/shops/{id}/trusted`, thiếu dữ liệu shop trong danh sách người dùng).
- Không làm vì trùng chức năng đã có: `POST /consignments/{id}/withdraw` (đã rút ký gửi bằng quyết định WITHDRAW), `DELETE /cart` (xoá từng món), `GET /admin/platform-wallet` (Dashboard đã có phí sàn thu được), `PUT /seller/listings/{id}/stock` (sửa tồn kho qua form sửa tin).
- Người bán: hiển thị hạn giao hàng, uy tín shop, hạn quyết định lô không bán.
- Ẩn nút giả lập giao hàng ở bản production (FE-12): chỉ chạy được khi backend bật chế độ giả lập (profile dev).
- Cảnh báo ở hoá đơn lô thắng: quá 48 giờ bị phạt 10% giá búa và cấm đấu giá.

## Test tay trên máy ảo Android (06/11/2026, backend nhánh này, database riêng `rebook_ui`, cổng 8081)

| Luồng | Kết quả |
|---|---|
| Ví người mua: hiện tiền mới nạp đang khoá và giờ mở khoá | Đạt |
| Màn Rút tiền: "Rút được ngay", ghi chú tiền khoá, nút chọn nhanh chỉ tới mức rút được, chữ giải thích đã sửa | Đạt |
| Đơn đang giao: người mua thấy nút "Đã nhận hàng" | Đạt |
| Trả hàng nhiều bước: người mua yêu cầu → shop đồng ý (giao diện) → người mua thấy nơi gửi, hạn gửi, nhập mã vận đơn (giao diện) → shop bấm "Đã nhận lại sách, hoàn tiền" (giao diện) → đơn "Đã trả hàng", người mua được hoàn 70.000 ₫ | Đạt |
| COD: shop giao → Staff đánh dấu "Đã giao thành công" ở màn Đối chiếu vận chuyển (giao diện) → người mua nhận → Admin bấm "Đã nhận tiền COD" (giao diện) → tiền về ví shop | Đạt |
| Huỷ đăng ký đấu giá trước hạn: hoàn đủ cọc, nút quay lại "Đăng ký tham gia", có thông báo | Đạt sau khi sửa lỗi (bên dưới) |
| Khoản nợ trong ví: hiện khung nợ, "Thu nợ từ ví" thu đủ 250.000 ₫, khung biến mất | Đạt (nợ chèn thẳng vào database test) |
| Admin "Mở ngay" ở danh sách phiên: phiên đổi sang đang diễn ra, hiện "Giám sát" | Đạt |
| Trả hàng "Chưa nhận được hàng": form ẩn phần ảnh, gửi được không cần ảnh | Đạt |
| Shop từ chối yêu cầu huỷ của người mua: đơn trở lại "Đang chuẩn bị" bình thường | Đạt |
| Admin đổi vai trò người dùng bằng menu, đổi lại được | Đạt |
| Staff báo sự cố kho (hỏng sách) → Admin duyệt 50%: backend từ chối vì ví sàn không đủ, app hiện đúng thông báo của backend | Đạt |
| Đổi mật khẩu với mật khẩu hiện tại sai: hiện "Mật khẩu hiện tại không đúng" | Đạt |
| Admin: nút "Mở ngay" ở danh sách phiên đấu giá, phiên chuyển sang đang diễn ra, hiện nút "Giám sát" | Đạt |
| Trả hàng "Chưa nhận được hàng": form ẩn phần ảnh, gửi được không cần ảnh, đơn sang "Yêu cầu trả hàng" | Đạt |

Lỗi tìm thấy khi test và đã sửa:
- Huỷ đăng ký xong màn hình vẫn hiện "Đã đăng ký": provider hành động bị huỷ giữa lúc gọi API (log: "Cannot use the Ref … after it has been disposed"). Sửa: màn phiên theo dõi `auctionActionsProvider`.
- Lịch sử đơn hiện mã thô `WRONG_CONDITION`: nay dịch sang "sai tình trạng sách", "thiếu trang", "sai ấn bản", "không đúng mô tả".

Còn thấy nhưng chưa sửa: dòng sổ cái của khoản thu nợ vẫn mang nhãn chung "Thanh toán".

Cách chạy lại: bật Docker Desktop, `docker start rebook-db`, tạo database mới (`CREATE DATABASE rebook_ui OWNER rebook ENCODING 'UTF8' TEMPLATE template0`), chạy backend ở `apps/backend` với `DB_URL=jdbc:postgresql://localhost:5432/rebook_ui PORT=8081 ./mvnw spring-boot:run` (nếu báo trùng migration V9 thì xoá file cũ `target/classes/db/migration/V9__unaccent_search.sql`), build app bằng file env trỏ `10.0.2.2:8081`.

Chưa test tay trên máy ảo (đã có test tự động và analyze sạch): Hủy phiên, kiểm định lại lô, nút giao thất bại / trả hàng ở màn Giao lô đấu giá của Staff, gỡ cấm đấu giá, hủy đặt giá tự động.
