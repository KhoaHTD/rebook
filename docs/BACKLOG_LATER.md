# Việc để sau (backlog)

Ngày 2026-11-06. Danh sách những việc **chưa làm**, tách theo lý do. Mã `BE-xx` / `FE-xx` nằm ở [AUDIT_BACKEND.md](AUDIT_BACKEND.md) và [AUDIT_FRONTEND.md](AUDIT_FRONTEND.md).
Đã làm xong thì xoá khỏi đây hoặc ghi vào `SESSION_LOG_*.md`.

## A. Nhóm 1: hoãn theo yêu cầu chủ repo (làm sau, nhỏ nhưng quan trọng)

| Việc | Mã | Ghi chú |
|---|---|---|
| Đổi profile mặc định khỏi `dev`; thiếu `JWT_SECRET` thì không khởi động; `simulate-enabled` chỉ bật bằng biến môi trường tường minh | BE-32 | **P0**: quên đặt biến khi deploy thì OTP lộ và ai cũng tự nạp tiền miễn phí qua endpoint giả lập thanh toán |
| Gỡ mã OTP và email khỏi log (`AuthService.java:168`) | `LOGGING_DESIGN` bước 2 | Lỗi bảo mật |
| Khoảng min/max cho từng khoá cấu hình; cận trên giá, tồn kho; pattern tên chủ tài khoản và số tài khoản của shop | BE-33 | Nay có thêm 18 khoá cấu hình mới nên Admin đặt nhầm (vd hạn 0) dễ hơn |

## B. Phải làm cùng frontend (hoặc frontend đổi trước)

| Việc | Mã | Vì sao cần frontend |
|---|---|---|
| Đồng bộ client: `/sync-api`, enum mới (`INSPECTING`, `CANCELLED` của đăng ký, `AWAITING_GOODS`, `EXPIRED`), mã lỗi mới (`DEBT_OPEN`, `COD_NOT_ALLOWED`, `TOPUP_LOCKED`, `WITHDRAW_DAILY_LIMIT`, `AUCTION_BANNED`, `NOT_REGISTERED`, `BOOK_IN_WAREHOUSE`), ẩn nút giả lập giao hàng ở production, sửa `env/prod.json` | `AUDIT_FRONTEND.md` | Điều kiện để dùng được những gì backend đã đổi |
| Checkout gửi kèm giá người mua đã thấy; backend trả `PRICE_CHANGED` khi lệch; hộp thoại xác nhận lại | BE-12 | Hợp đồng API đổi |
| Ảnh biên lai chuyển khoản không công khai (cần token khi xem) | BE-34 | Ảnh đang tải bằng URL công khai, không kèm header |
| Thông báo ngoài app: endpoint đăng ký thiết bị, gửi FCM, email, SMS; frontend gọi `init()` và gửi token | BE-36, FE-03 | Cần frontend gửi token; nay phạt 48 giờ nên càng quan trọng |
| Xin lại OTP có đếm ngược, giới hạn tần suất gửi OTP; gửi OTP thật qua email / SMS | BE-26 (phần còn lại) | Giao diện đếm ngược và báo khoá tạm; cần dịch vụ gửi |
| OTP hoặc thời gian chờ khi thêm tài khoản ngân hàng mới | BE-02 (phần còn lại) | Thêm bước nhập OTP ở luồng rút tiền |
| Hoàn một phần khi phân xử khiếu nại; shop nộp ảnh bằng chứng phản biện | BE-11 | Màn khiếu nại và đơn shop đổi |
| KYC người ký gửi và người thắng giá trị cao | BE-23 | Màn tải giấy tờ |
| Sự cố kho: mất, hỏng sách, khai báo giá trị, bồi thường | BE-24 | API và màn Staff mới |
| Xác nhận hai người cho rút lớn và đổi quyền | BE-28 | Màn Admin |
| Dashboard tách doanh thu thực (phí thu được) khỏi GMV (thêm trường, không đổi trường cũ) | BE-29 | Màn tổng quan hiển thị trường mới |
| Báo cáo review, shop phản hồi review, phát hiện review ảo | BE-16 | Màn đánh giá |
| Xoá / ẩn danh tài khoản, xuất dữ liệu cá nhân | BE-30 | Màn tài khoản |
| Phạt luỹ tiến cho người tái phạm; hiển thị mức phạt cho người dùng | (chưa mã) | Cần chủ sàn chốt mức; giao diện cảnh báo |
| Cấu hình mới hiện nhãn tiếng Việt ở màn Cấu hình phí | `AUDIT_FRONTEND.md` | `_configLabels` |
| Màn sự cố kho: Staff khai báo mất / hỏng sách (ảnh, mô tả), Admin duyệt (chọn % khi hỏng) hoặc từ chối; hiện giai đoạn và số tiền bồi thường | BR-4.2, BR-4.8 | API đã có (`/staff/warehouse/{id}/incidents`, `/staff/warehouse-incidents`, `/admin/warehouse-incidents/{id}/approve | reject`), chưa có màn hình |
| Mã lỗi mới: `INVALID_ISBN`, `INVALID_PRICE`, `DEMO_ONLY`, `STAFF_CANNOT_BID`, `INCIDENT_PENDING`, `INCIDENT_DECIDED`, `LOT_LIVE`, `LOT_AWAITING_PAYMENT`, `PLATFORM_FUNDS_INSUFFICIENT`, `SELLER_PERCENT_REQUIRED`; trạng thái `LOST` (lô, ký gửi, kho); loại giao dịch `COMPENSATION`; cờ `isbnWarning` ở màn duyệt tin | SRS bổ sung nhóm 1, 4 | Cần `/sync-api` và nhãn tiếng Việt |

## C. Cần quyết định của chủ sàn, quyền hạ tầng, hoặc người am hiểu luật

| Việc | Mã | Ghi chú |
|---|---|---|
| Workflow CI / deploy cho backend (`.github/workflows/backend-ci.yml`, cần Postgres service) | BE-40 | `.github/` thuộc nhóm file hạ tầng cần chủ repo duyệt (xem `CLAUDE.md`) |
| Chạy nhiều instance: Redis cho kênh WebSocket, khoá job | BE-39 | Chưa cần khi còn một node |
| Địa giới hành chính mới (34 tỉnh) và bảng phí giao theo vùng | BE-37 | Cần xác minh quy định hiện hành; frontend cũng đổi nguồn địa chỉ |
| Mô hình giữ tiền hộ, thuế người bán cá nhân, hoá đơn điện tử, kiểm duyệt sách | BE-31 | Cần tham vấn pháp lý |
| Vé WebSocket ngắn hạn thay JWT trên URL | BE-38 | Đổi giao thức nối của frontend |
| Duyệt các giá trị mặc định đã đề xuất (COD, khoá 24 giờ, phạt 10%, hạn 7 ngày, hạn giao 3 ngày, gỡ uy tín 10%) | `SESSION_LOG` mục D, `AUCTION_MONEY_FLOW.md` mục 7 | Đổi được trong `system_configs` |
| `SeedDataTest` gắn cứng cổng 5432 nên không chạy trên DB ở cổng khác | | Sửa test để đọc URL từ `TEST_DB_URL` |
| Test thật với ZaloPay, FCM, các mốc chờ 15 phút đến 48 giờ, TalkBack | `AUDIT_FRONTEND.md` | Cần môi trường và thiết bị thật |

## D. Đấu giá còn dang dở (thuần backend nhưng lớn hoặc cần bàn thiết kế)

| Việc | Ghi chú |
|---|---|
| ~~Sàn huỷ hoá đơn đã thanh toán vì lỗi của sàn (mất, hỏng sách trong kho), hoàn tiền kèm bồi thường~~ | Đã làm 2026-11-06 (sự cố kho, SRS bổ sung BR-4.2). Còn: chưa có cách nạp vốn ví sàn (hai lỗ nhỏ khác đã vá, SESSION_LOG #87) |
| Bán sau phiên cho người trả giá cao nhất khi chưa đạt giá sàn | Cần luật mới và đồng ý của người bán |
| Chuyển lô không bán sang bán thường do sàn giao hộ (đúng SRS 6.6) | BE-21: nay chỉ chặn duyệt tin khi sách còn trong kho |
| Chống thông đồng đẩy giá: ghi IP / thiết bị lượt trả giá, cảnh báo tài khoản liên quan | BE-25; cần chốt chính sách thu thập IP |
| Hạn mức cọc theo giá trị lô | Đổi công thức hạn mức |
| Người ký gửi bị khoá còn lô đang xếp phiên | `AccountLockService` chưa xử lý lô của người ký gửi |

## E. Đã làm ở đợt thuần backend 2026-11-06 (để tham chiếu)

BE-07 hạn giao hàng cho vận chuyển, BE-08 hạn trả lời yêu cầu huỷ, BE-09 điểm uy tín shop và tự gỡ uy tín, BE-27 dọn việc dở khi khoá tài khoản, hoàn cọc phiên chưa chốt khi bị cấm đấu giá, BE-35 mã lỗi riêng `AUCTION_BANNED` / `NOT_REGISTERED`, BE-21 chặn duyệt tin khi sách còn trong kho, BE-41 test chạy song song. Chi tiết ở `SESSION_LOG_2026-11-05.md` mục G.

## F. Đã làm ở đợt vá 2026-11-06 (để tham chiếu)

COD vận hành thật (Staff đối chiếu, đơn COD không tự giao), địa chỉ nhận hàng trả, danh sách lô chờ kiểm định lại, nhắc việc trước hạn, phủ nhật ký bảo mật, cảnh báo COD đang giao quá lâu. Việc frontend đi kèm: [AUDIT_FRONTEND.md](AUDIT_FRONTEND.md) mục "Việc frontend sau đợt vá 2026-11-06".

Còn để sau (thêm sau đợt vá): gỡ dòng log OTP (`AuthService.java:168`) vẫn thuộc nhóm 1; ngưỡng 7 ngày của cảnh báo COD đang cứng trong `WalletReconciliationJob` (chưa đọc từ cấu hình).

## G. Thêm sau rà soát đấu giá nhiều người (2026-11-06)

- ~~Số tiền trả giá / giá tối đa chưa ép số nguyên~~: đã làm (SESSION_LOG mục J, `@WholeVnd`).
- Chưa kiểm tải thật (vài trăm người cùng phòng, WebSocket phát tin cho phòng đông, mất mạng giữa phiên).
