# ReBook backend: trước đây, hạn chế, và bây giờ

Cập nhật 2026-11-06. Tóm tắt một lượt cho người mới đọc: phần **cũ** làm gì, **hạn chế** ở đâu, **bây giờ** đã cải thiện gì, và **còn lại** gì. Chi tiết từng mục nằm ở các file nguồn ghi ở cuối.

Phạm vi: chỉ backend (Spring Boot). Frontend chưa đổi gì; việc frontend phải làm kèm nằm ở [AUDIT_FRONTEND.md](AUDIT_FRONTEND.md). **Chưa commit gì.**

## 0. Con số tổng

| | Trước | Bây giờ |
|---|---|---|
| Migration | V1–V8 | thêm V9, V10, V11, V12 (chỉ thêm, không sửa file đã chạy) |
| Test backend | bộ test cũ (đặt hàng, ví, rút tiền, ZaloPay, trả hàng...) | **144 test đạt** (trừ `SeedDataTest`), gồm thêm 7 lớp test về tiền, đấu giá, bảo mật, song song, luồng đầu cuối |
| Nhật ký hoạt động | chỉ bảng `admin_activity_logs` cho thao tác Admin | bảng `audit_events` thống nhất, mọi đường tiền, đơn, đấu giá, xác thực đều ghi |
| Lỗi nghiệp vụ đã liệt kê | | 42 mục (BE-01…BE-42): 16 đã sửa hẳn, 6 sửa một phần (BE-02, 06, 13, 21, 26, 33), còn lại để sau hoặc cần chủ repo quyết |

## 1. Tiền: ví, rút tiền, đối soát

| | Nội dung |
|---|---|
| **Cũ làm gì** | Ví có số dư khả dụng và số dư bị giữ. Nạp qua ZaloPay sandbox. Rút tiền cần Admin duyệt, tối thiểu 50.000đ |
| **Hạn chế** | Nạp xong rút ngay được: ví không phân biệt tiền nạp với tiền bán hàng. Rút không có tối đa. Không có công nợ. Không ai đối soát tổng ví với sổ cái. Hai yêu cầu rút cùng lúc có thể rút vượt số dư |
| **Bây giờ** | Tiền mới nạp bị khoá 24 giờ (cấu hình được; đặt 0 để tắt), tiền bán hàng thì rút được ngay: `GET /wallet/withdrawable`. Hạn mức rút mỗi ngày. Người đang nợ không rút được. Khoá ví khi rút, thử hai yêu cầu cùng lúc cũng không vượt số dư. Job đối soát hằng đêm: số dư mỗi ví phải bằng tổng sổ cái, lệch thì cảnh báo. Số tiền nhập vào phải là số nguyên đồng, tối đa 15 chữ số (`@WholeVnd`) |
| **Còn lại** | Chưa KYC khi rút, chưa OTP khi đổi tài khoản ngân hàng, chưa đối soát tổng với cổng thanh toán, Admin vẫn một cấp duyệt (BE-02, BE-06, BE-28) |

## 2. Đơn hàng bán giá cố định

| Việc | Cũ làm gì | Hạn chế | Bây giờ |
|---|---|---|---|
| **COD** | Hoàn tất đơn là cộng thẳng tiền cho shop | Sàn chưa nhận đồng nào mà shop đã rút được; hoàn trả COD cũng "đẻ" tiền | Mô hình hãng vận chuyển thu hộ: Staff đối chiếu hãng (`/staff/orders/in-transit`, `carrier-delivered`, `carrier-failed`), Admin xác nhận đã nhận tiền (`/admin/cod/{id}/remit`), shop chỉ được trả sau đó. Hoàn trả COD chờ sàn nhận tiền. Hạn mức giá trị COD, chặn người từng bom hàng. Đơn COD không tự "đã giao" theo thời gian |
| **Xác nhận giao hàng** | Shop tự bấm "đã giao", sau 3 ngày tự hoàn tất | Shop giao khống rồi lấy tiền | Nút giả lập hãng vận chuyển chỉ bật ở môi trường dev. Người mua xác nhận nhận hàng; không bấm thì sau 7 ngày tự coi là đã giao (đơn trả bằng ví) rồi mới tới thời hạn khiếu nại |
| **Trả hàng** | Shop đồng ý là hoàn tiền và cộng lại tồn kho ngay | Người mua giữ cả sách lẫn tiền; tin bán một cuốn chưa về tay | Theo bước: shop đồng ý → người mua gửi trả (mã vận đơn) → shop/kho xác nhận đã nhận → mới hoàn tiền. Có hạn gửi trả, hạn xử lý, leo thang cho Admin. Không tự cộng tồn kho (shop kiểm sách rồi tự chỉnh). Người mua biết gửi về đâu (`returnToName`, `returnToAddress`; hàng ký gửi trả về kho sàn) |
| **Phí sàn** | Đọc cấu hình lúc hoàn tất | Admin đổi 15% → 25% thì đơn cũ bị tính theo 25% | Chụp tỷ lệ phí lúc đặt (`fee_percent`); hoa hồng đấu giá chụp lúc người bán chấp nhận hợp đồng (`commission_percent`) |
| **Đặt hàng song song** | Hai request cùng giỏ có thể tạo hai bộ đơn | Trừ tiền hai lần, hai đơn | Khoá ví khi đặt hàng, chỉ một đơn được tạo |
| **Shop ngâm đơn** | Đơn đã xác nhận không có hạn | Tiền người mua kẹt vô hạn | Quá 3 ngày chưa giao cho vận chuyển: tự huỷ, hoàn tiền, tính lỗi shop. Yêu cầu huỷ của người mua: shop im lặng 24 giờ thì tự đồng ý |
| **Uy tín shop** | `trusted` chỉ Admin bật tay | Shop xấu vẫn được tự duyệt tin mãi | Tỷ lệ đơn lỗi ≥ 10% với tối thiểu 5 đơn trong 90 ngày thì tự gỡ uy tín (Admin gắn lại được) |
| **Khoá tài khoản** | Chỉ đổi trạng thái | Tin vẫn bán, đơn dở và cọc kẹt | Ẩn tin, huỷ và hoàn tiền đơn chưa giao, huỷ đơn chưa thanh toán, hoàn cọc phiên chưa chốt |
| **Nhắc việc** | Không có | Shop/người mua lỡ hạn mới biết | Nhắc trước hạn 24 giờ: giao cho vận chuyển, trả lời yêu cầu huỷ, thanh toán, chọn hướng xử lý lô không bán (mỗi việc nhắc một lần) |
| **Còn lại** | | | Người mua bom hàng ngoài COD, phân xử hoàn một phần, review farming, chống đổi giá giữa lúc xem và đặt (BE-10, 11, 12, 14, 16) |

## 3. Phí ship

| | Nội dung |
|---|---|
| **Cũ làm gì** | Bảng cố định: nội tỉnh 20.000đ, liên tỉnh 30.000đ cho gói ≤ 1kg, cộng 5.000đ mỗi 500g vượt (làm tròn lên). Ba giá này nằm trong cấu hình |
| **Hạn chế** | Người thắng nhiều lô trong một phiên bị tính ship riêng từng lô |
| **Bây giờ** | Công thức không đổi. **Gộp kiện**: lô sau chỉ trả phần tăng thêm so với các lô trước. Lúc đầu chỉ chạy khi người thắng đã có địa chỉ mặc định; **sửa ngày 06/11**: chạy cả khi người thắng chọn giao tận nơi sau phiên (đường thường gặp nhất), tính lại cả các hoá đơn chưa thanh toán cùng phiên |
| **Còn lại** | Chưa phân vùng, kích thước, khai giá, hãng thật; so tỉnh bằng tên (BE-37); gộp kiện giả định cùng một nơi nhận |

## 4. Đấu giá: ký gửi, kho, phiên

| Việc | Cũ làm gì | Hạn chế | Bây giờ |
|---|---|---|---|
| **Người thắng bỏ thanh toán** | Mất cọc đã đặt, bị cấm | Cọc chỉ áp vào lô đầu; thắng 5 lô bỏ 4 lô thì không còn gì để thu | Phạt = lớn hơn giữa cọc đang giữ và 10% giá búa, mỗi lô bỏ. Thiếu thì thu từ ví, vẫn thiếu thì ghi **công nợ** (chặn đăng ký, trả giá, rút tiền đến khi trả). Người bị cấm được hoàn cọc các phiên chưa chốt |
| **Mời người trả giá thứ hai** | Mời người cao thứ hai nếu đạt giá sàn | Có thể mời người đang bị cấm hoặc đang nợ, hoặc chính người ký gửi | Chọn người đủ điều kiện kế tiếp (không bị cấm, không nợ, không phải người bán) |
| **Huỷ đăng ký** | Không có | Cọc kẹt đến hết phiên | `DELETE /sessions/{id}/register` đến hạn đăng ký, hoàn đủ cọc, huỷ giá tối đa |
| **Lô không bán** | Chờ người bán chọn mãi | Sách nằm kho vô hạn, không tính phí kho | Sau 7 ngày không chọn thì tự chuyển sang trả sách, bắt đầu tính hạn lưu kho miễn phí. Phí kho không đủ ví thì thành nợ, kho vẫn xuất sách được |
| **Lô bị trả hàng** | Quay lại hàng chờ xếp phiên | Sách đã qua tay người mua nhưng dùng báo cáo cũ | Sang trạng thái `INSPECTING`, Staff kiểm định lại (`/staff/lots/inspecting`, `/reinspect`); không đạt thì trả người bán |
| **Chuyển sang bán thường** | Tin được duyệt là lên bán | Sách vẫn nằm trong kho | Chặn duyệt tin khi sách còn trong kho (`BOOK_IN_WAREHOUSE`) |
| **Mã lỗi** | Nhiều lỗi dùng chung `FORBIDDEN` | Frontend dò chuỗi tiếng Việt | Có mã riêng `AUCTION_BANNED`, `NOT_REGISTERED`, `DEBT_OPEN` |
| **Còn lại** | | | Chuyển bán thường do kho giao hộ (đúng SRS 6.6), KYC người ký gửi, sự cố mất/hỏng sách trong kho, chống thông đồng đẩy giá bằng IP/thiết bị, hạn mức cọc theo giá trị lô (BE-21, 23, 24, 25) |

## 5. Đấu giá: phiên trực tiếp nhiều người

Phần lõi (khoá lạc quan khi trả giá, soft close, giá tối đa tự động, bước giá bậc thang, phát tin realtime sau commit) đã tốt từ trước và được giữ nguyên. Lớp test `MultiBidderTest` (12 ca, 5 người trong một phiên) và các ca đua nhau tìm ra 3 lỗi, đã sửa:

| Lỗi tìm được | Hậu quả | Sửa |
|---|---|---|
| Đặt giá tối đa sau giờ chốt (engine chưa kịp chốt, tối đa ~1 giây) vẫn được nhận | Đổi người dẫn đầu ngay sau khi hết giờ | Từ chối `409 LOT_NOT_OPEN` khi phiên đang chạy mà lô hết giờ |
| Giá tay đúng bằng giá tối đa của người đang dẫn thì cướp được vị trí | Trái luật "bằng giá thì người đặt trước giữ" đã áp cho hai giá tối đa | Người đặt trước giữ vị trí ở cùng mức giá, báo người kia bị vượt |
| Giá tối đa đặt lúc phiên tạm dừng không được xét khi tiếp tục | Người đặt có thể không bao giờ được trả giá hộ | `resume` xét ngay và báo người bị vượt |

Và nhóm kiểm lại số tiền: số lẻ (`50000.4`) bị làm tròn khi lưu, số quá lớn làm tràn cột, nay trả 400.

## 6. Tài khoản, bảo mật, nhật ký

| | Nội dung |
|---|---|
| **Cũ làm gì** | Đăng nhập, OTP, JWT, nhật ký thao tác Admin |
| **Hạn chế** | Dò mật khẩu thoải mái; bộ đếm OTP sai bị rollback cùng lỗi nên dò OTP vô hạn; không có dấu vết cho đăng nhập, đổi mật khẩu, 403, tải tệp |
| **Bây giờ** | Chặn đăng nhập sai 10 lần/15 phút (do nhóm làm). Sửa bộ đếm OTP. Thiết kế ghi log thống nhất ([LOGGING_DESIGN.md](LOGGING_DESIGN.md)): `audit_events`, `AuditLog`, `EventCode`, `X-Request-Id`. Đã ghi: đăng ký, đăng nhập (đúng, sai, bị chặn), OTP (không lưu mã), đặt lại và đổi mật khẩu, khoá/mở khoá, đổi vai trò, đổi cấu hình, tải tệp (cả bị từ chối), mọi 403, toàn bộ đường tiền và đơn. Email chỉ lưu dạng băm. Việc bị từ chối vẫn có dòng log (giao dịch riêng) |
| **Còn lại** | Dòng log mã OTP cũ ở `AuthService.java:168` (nhóm 1), màn xem Nhật ký, cảnh báo tự động, role DB chỉ-INSERT, khoá đăng nhập theo email có thể bị lợi dụng (BE-42) |

## 7. Kiểm thử

| | Nội dung |
|---|---|
| **Cũ làm gì** | Test tích hợp cho đặt hàng, ví, rút tiền, ZaloPay, trả hàng quá hạn, upload, bảo vệ đầu vào |
| **Hạn chế** | Không test song song; không test cả vòng đời; không có môi trường chạy test trên máy chưa có DB |
| **Bây giờ** | `MoneyRulesTest`, `AuctionMoneyTest`, `ShopSlaAndLockTest`, `OpsGapsTest`, `SecurityAuditTest`, `ConcurrencyTest`, `MultiBidderTest`, `FullJourneyTest` (16 câu chuyện, kiểm bảo toàn tiền), `JourneyEdgeCasesTest` (15 ca). Kế hoạch: [E2E_TEST_PLAN.md](E2E_TEST_PLAN.md). Cách chạy trên máy không có DB: tạo cụm Postgres tạm cổng 5433, đặt `TEST_DB_URL` |
| **Còn lại** | Không kiểm tải thật, WebSocket phòng đông, ZaloPay thật, push; chưa có CI cho backend (BE-40) |

## 8. Việc còn lại (tóm tắt)

| Nhóm | Việc | Ghi chú |
|---|---|---|
| **Nhóm 1 (hoãn theo yêu cầu chủ repo)** | BE-32 profile mặc định `dev`; gỡ mã OTP khỏi log; BE-33 khoảng giá trị cấu hình, cận trên giá và tồn kho | BE-32 là P0 |
| **Làm cùng frontend** | Màn Staff đối chiếu COD (**bắt buộc, không có thì đơn COD không hoàn tất**), màn lô chờ kiểm định lại, hiện địa chỉ gửi trả, hiện hạn và uy tín shop, thông báo đẩy | [AUDIT_FRONTEND.md](AUDIT_FRONTEND.md) |
| **Cần chủ repo / hạ tầng / luật** | Pháp lý giữ tiền hộ và thuế, KYC, Admin hai cấp, CI backend, deploy, nhiều instance | [BACKLOG_LATER.md](BACKLOG_LATER.md) mục C |
| **Đấu giá dang dở** | Huỷ hoá đơn đã trả vì lỗi sàn, bán sau phiên cho người chưa đạt sàn, kho giao hộ, hạn mức cọc theo lô | [BACKLOG_LATER.md](BACKLOG_LATER.md) mục D |

## Nguồn chi tiết

- [AUDIT_BACKEND.md](AUDIT_BACKEND.md): 42 lỗi, trạng thái, các đợt cập nhật 1–7
- [SESSION_LOG_2026-11-05.md](SESSION_LOG_2026-11-05.md): nhật ký từng việc đã làm (mục A–J), file đã đổi, rủi ro
- [AUCTION_MONEY_FLOW.md](AUCTION_MONEY_FLOW.md): phân tích luồng tiền đấu giá, 18 tình huống
- [LOGGING_DESIGN.md](LOGGING_DESIGN.md): thiết kế ghi log và trạng thái triển khai
- [E2E_TEST_PLAN.md](E2E_TEST_PLAN.md): kế hoạch và kết quả test đầu cuối
- [BACKLOG_LATER.md](BACKLOG_LATER.md): việc để sau
- [AUDIT_FRONTEND.md](AUDIT_FRONTEND.md): việc frontend phải làm kèm
