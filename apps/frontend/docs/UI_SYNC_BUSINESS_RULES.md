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

## Chưa làm

- Staff: màn lô chờ kiểm định lại (`POST /staff/lots/{id}/reinspect`), sự cố kho mất / hỏng (Staff khai báo, Admin duyệt), xác nhận kho đã nhận sách trả của đơn đấu giá.
- Admin: nút miễn nợ (`POST /admin/debts/{id}/waive`); nhãn tiếng Việt cho các cấu hình mới trong màn Cấu hình phí.
- Người bán: hiển thị hạn giao hàng, uy tín shop, hạn quyết định lô không bán.
- Ẩn nút giả lập giao hàng ở bản production (FE-12): chỉ chạy được khi backend bật chế độ giả lập (profile dev).
- Cảnh báo ở hoá đơn lô thắng: quá 48 giờ bị phạt 10% giá búa và cấm đấu giá.

## Test tay trên máy ảo Android (06/11/2026, backend nhánh này, database riêng , cổng 8081)

| Luồng | Kết quả |
|---|---|
| Ví người mua: hiện tiền mới nạp đang khoá và giờ mở khoá | Đạt |
| Màn Rút tiền: "Rút được ngay", ghi chú tiền khoá, nút chọn nhanh chỉ tới mức rút được, chữ giải thích đã sửa | Đạt |
| Đơn đang giao: người mua thấy nút "Đã nhận hàng" | Đạt |
| Trả hàng nhiều bước: người mua yêu cầu → shop đồng ý (giao diện) → người mua thấy nơi gửi, hạn gửi, nhập mã vận đơn (giao diện) → shop bấm "Đã nhận lại sách, hoàn tiền" (giao diện) → đơn "Đã trả hàng", người mua được hoàn 70.000 ₫ | Đạt |
| COD: shop giao → Staff đánh dấu "Đã giao thành công" ở màn Đối chiếu vận chuyển (giao diện) → người mua nhận → Admin bấm "Đã nhận tiền COD" (giao diện) → tiền về ví shop | Đạt |
| Huỷ đăng ký đấu giá trước hạn: hoàn đủ cọc, nút quay lại "Đăng ký tham gia", có thông báo | Đạt sau khi sửa lỗi (bên dưới) |
| Khoản nợ trong ví: hiện khung nợ, "Thu nợ từ ví" thu đủ 250.000 ₫, khung biến mất | Đạt (nợ chèn thẳng vào database test) |

Lỗi tìm thấy khi test và đã sửa:
- Huỷ đăng ký xong màn hình vẫn hiện "Đã đăng ký": provider hành động bị huỷ giữa lúc gọi API (log: "Cannot use the Ref … after it has been disposed"). Sửa: màn phiên theo dõi .
- Lịch sử đơn hiện mã thô : nay dịch sang "sai tình trạng sách", "thiếu trang", "sai ấn bản", "không đúng mô tả".

Còn thấy nhưng chưa sửa: dòng sổ cái của khoản thu nợ vẫn mang nhãn chung "Thanh toán".

Cách chạy lại: bật Docker Desktop, , tạo database mới (), chạy backend ở  với  (nếu báo trùng migration V9 thì xoá  cũ), build app bằng file env .
