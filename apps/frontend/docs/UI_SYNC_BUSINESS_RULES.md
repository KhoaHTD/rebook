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

## Test tay (cần Docker, backend nhánh này, máy ảo)

Chưa chạy. Điều kiện: bật Docker Desktop, tạo lại database `rebook_dev` (migration V9–V14 khác bản cũ), chạy backend ở nhánh này, cài lại app lên máy ảo bằng `android.8081.json`.
