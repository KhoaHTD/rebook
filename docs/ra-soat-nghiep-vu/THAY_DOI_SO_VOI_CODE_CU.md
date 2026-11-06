# ReBook: đối chiếu với code cũ (đã thay đổi gì)

Gộp ngày 2026-11-06 từ các file cũ. Mỗi phần giữ nguyên nội dung và mã luật (BR-x.y, AM-xx, K-xx). Chú thích trong code và migration cũ có thể còn ghi tên file cũ; bảng dưới cho biết tên cũ nằm ở phần nào.

| Phần | Nội dung | Tên file cũ |
|---|---|---|
| A | Trước / sau khi sửa (tóm tắt cho người đọc nhanh) | `BEFORE_AFTER.md` |
| B | Luồng tiền đấu giá: phân tích và quy tắc | `AUCTION_MONEY_FLOW.md` |
| C | Luật nghiệp vụ bổ sung cho SRS (BR-x.y) | `SRS_BO_SUNG_NGHIEP_VU.md` |
| D | Thiết kế ghi log và sự kiện | `LOGGING_DESIGN.md` |
| E | Nhật ký thay đổi theo phiên (việc đã làm, dòng code cũ bị thay, rủi ro) | `SESSION_LOG_2026-11-05.md` |

---

# Phần A. Trước / sau khi sửa (tóm tắt cho người đọc nhanh)

*(Trước là `BEFORE_AFTER.md`.)*

Cập nhật 2026-11-06. Tóm tắt một lượt cho người mới đọc: phần **cũ** làm gì, **hạn chế** ở đâu, **bây giờ** đã cải thiện gì, và **còn lại** gì. Chi tiết từng mục nằm ở các file nguồn ghi ở cuối.

Phạm vi: chỉ backend (Spring Boot). Frontend chưa đổi gì; việc frontend phải làm kèm nằm ở [DANH_GIA_BA_TESTER.md phần C](DANH_GIA_BA_TESTER.md). **Chưa commit gì.**

### 0. Con số tổng

| | Trước | Bây giờ |
|---|---|---|
| Migration | V1–V8 | thêm V9, V10, V11, V12 (chỉ thêm, không sửa file đã chạy) |
| Test backend | bộ test cũ (đặt hàng, ví, rút tiền, ZaloPay, trả hàng...) | **144 test đạt** (trừ `SeedDataTest`), gồm thêm 7 lớp test về tiền, đấu giá, bảo mật, song song, luồng đầu cuối |
| Nhật ký hoạt động | chỉ bảng `admin_activity_logs` cho thao tác Admin | bảng `audit_events` thống nhất, mọi đường tiền, đơn, đấu giá, xác thực đều ghi |
| Lỗi nghiệp vụ đã liệt kê | | 42 mục (BE-01…BE-42): 16 đã sửa hẳn, 6 sửa một phần (BE-02, 06, 13, 21, 26, 33), còn lại để sau hoặc cần chủ repo quyết |

### 1. Tiền: ví, rút tiền, đối soát

| | Nội dung |
|---|---|
| **Cũ làm gì** | Ví có số dư khả dụng và số dư bị giữ. Nạp qua ZaloPay sandbox. Rút tiền cần Admin duyệt, tối thiểu 50.000đ |
| **Hạn chế** | Nạp xong rút ngay được: ví không phân biệt tiền nạp với tiền bán hàng. Rút không có tối đa. Không có công nợ. Không ai đối soát tổng ví với sổ cái. Hai yêu cầu rút cùng lúc có thể rút vượt số dư |
| **Bây giờ** | Tiền mới nạp bị khoá 24 giờ (cấu hình được; đặt 0 để tắt), tiền bán hàng thì rút được ngay: `GET /wallet/withdrawable`. Hạn mức rút mỗi ngày. Người đang nợ không rút được. Khoá ví khi rút, thử hai yêu cầu cùng lúc cũng không vượt số dư. Job đối soát hằng đêm: số dư mỗi ví phải bằng tổng sổ cái, lệch thì cảnh báo. Số tiền nhập vào phải là số nguyên đồng, tối đa 15 chữ số (`@WholeVnd`) |
| **Còn lại** | Chưa KYC khi rút, chưa OTP khi đổi tài khoản ngân hàng, chưa đối soát tổng với cổng thanh toán, Admin vẫn một cấp duyệt (BE-02, BE-06, BE-28) |

### 2. Đơn hàng bán giá cố định

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

### 3. Phí ship

| | Nội dung |
|---|---|
| **Cũ làm gì** | Bảng cố định: nội tỉnh 20.000đ, liên tỉnh 30.000đ cho gói ≤ 1kg, cộng 5.000đ mỗi 500g vượt (làm tròn lên). Ba giá này nằm trong cấu hình |
| **Hạn chế** | Người thắng nhiều lô trong một phiên bị tính ship riêng từng lô |
| **Bây giờ** | Công thức không đổi. **Gộp kiện**: lô sau chỉ trả phần tăng thêm so với các lô trước. Lúc đầu chỉ chạy khi người thắng đã có địa chỉ mặc định; **sửa ngày 06/11**: chạy cả khi người thắng chọn giao tận nơi sau phiên (đường thường gặp nhất), tính lại cả các hoá đơn chưa thanh toán cùng phiên |
| **Còn lại** | Chưa phân vùng, kích thước, khai giá, hãng thật; so tỉnh bằng tên (BE-37); gộp kiện giả định cùng một nơi nhận |

### 4. Đấu giá: ký gửi, kho, phiên

| Việc | Cũ làm gì | Hạn chế | Bây giờ |
|---|---|---|---|
| **Người thắng bỏ thanh toán** | Mất cọc đã đặt, bị cấm | Cọc chỉ áp vào lô đầu; thắng 5 lô bỏ 4 lô thì không còn gì để thu | Phạt = lớn hơn giữa cọc đang giữ và 10% giá búa, mỗi lô bỏ. Thiếu thì thu từ ví, vẫn thiếu thì ghi **công nợ** (chặn đăng ký, trả giá, rút tiền đến khi trả). Người bị cấm được hoàn cọc các phiên chưa chốt. Từ 2026-11-06: cọc / phạt về sàn 100%, sàn bù chênh cho người bán khi lô bán lại thấp hơn |
| **Mời người trả giá thứ hai** | Mời người cao thứ hai nếu đạt giá sàn | Có thể mời người đang bị cấm hoặc đang nợ, hoặc chính người ký gửi | Chọn người đủ điều kiện kế tiếp (không bị cấm, không nợ, không phải người bán). Từ 2026-11-06: giá mời là giá công bằng (giá người kế tiếp + 1 bước, không vượt giá người về nhì đã trả, không dưới giá sàn) |
| **Huỷ đăng ký** | Không có | Cọc kẹt đến hết phiên | `DELETE /sessions/{id}/register` đến hạn đăng ký, hoàn đủ cọc, huỷ giá tối đa |
| **Lô không bán** | Chờ người bán chọn mãi | Sách nằm kho vô hạn, không tính phí kho | Sau 7 ngày không chọn thì tự chuyển sang trả sách, bắt đầu tính hạn lưu kho miễn phí. Phí kho không đủ ví thì thành nợ, kho vẫn xuất sách được |
| **Lô bị trả hàng** | Quay lại hàng chờ xếp phiên | Sách đã qua tay người mua nhưng dùng báo cáo cũ | Sang trạng thái `INSPECTING`, Staff kiểm định lại (`/staff/lots/inspecting`, `/reinspect`); không đạt thì trả người bán |
| **Chuyển sang bán thường** | Tin được duyệt là lên bán | Sách vẫn nằm trong kho | Chặn duyệt tin khi sách còn trong kho (`BOOK_IN_WAREHOUSE`) |
| **Mã lỗi** | Nhiều lỗi dùng chung `FORBIDDEN` | Frontend dò chuỗi tiếng Việt | Có mã riêng `AUCTION_BANNED`, `NOT_REGISTERED`, `DEBT_OPEN` |
| **Còn lại** | | | Chuyển bán thường do kho giao hộ (đúng SRS 6.6), KYC người ký gửi, ~~sự cố mất/hỏng sách trong kho~~ (đã làm 2026-11-06), chống thông đồng đẩy giá bằng IP/thiết bị, hạn mức cọc theo giá trị lô (BE-21, 23, 24, 25) |

### 5. Đấu giá: phiên trực tiếp nhiều người

Phần lõi (khoá lạc quan khi trả giá, soft close, giá tối đa tự động, bước giá bậc thang, phát tin realtime sau commit) đã tốt từ trước và được giữ nguyên. Lớp test `MultiBidderTest` (12 ca, 5 người trong một phiên) và các ca đua nhau tìm ra 3 lỗi, đã sửa:

| Lỗi tìm được | Hậu quả | Sửa |
|---|---|---|
| Đặt giá tối đa sau giờ chốt (engine chưa kịp chốt, tối đa ~1 giây) vẫn được nhận | Đổi người dẫn đầu ngay sau khi hết giờ | Từ chối `409 LOT_NOT_OPEN` khi phiên đang chạy mà lô hết giờ |
| Giá tay đúng bằng giá tối đa của người đang dẫn thì cướp được vị trí | Trái luật "bằng giá thì người đặt trước giữ" đã áp cho hai giá tối đa | Người đặt trước giữ vị trí ở cùng mức giá, báo người kia bị vượt |
| Giá tối đa đặt lúc phiên tạm dừng không được xét khi tiếp tục | Người đặt có thể không bao giờ được trả giá hộ | `resume` xét ngay và báo người bị vượt |

Và nhóm kiểm lại số tiền: số lẻ (`50000.4`) bị làm tròn khi lưu, số quá lớn làm tràn cột, nay trả 400.

### 6. Tài khoản, bảo mật, nhật ký

| | Nội dung |
|---|---|
| **Cũ làm gì** | Đăng nhập, OTP, JWT, nhật ký thao tác Admin |
| **Hạn chế** | Dò mật khẩu thoải mái; bộ đếm OTP sai bị rollback cùng lỗi nên dò OTP vô hạn; không có dấu vết cho đăng nhập, đổi mật khẩu, 403, tải tệp |
| **Bây giờ** | Chặn đăng nhập sai 10 lần/15 phút (do nhóm làm). Sửa bộ đếm OTP. Thiết kế ghi log thống nhất ([THAY_DOI_SO_VOI_CODE_CU.md phần D](THAY_DOI_SO_VOI_CODE_CU.md)): `audit_events`, `AuditLog`, `EventCode`, `X-Request-Id`. Đã ghi: đăng ký, đăng nhập (đúng, sai, bị chặn), OTP (không lưu mã), đặt lại và đổi mật khẩu, khoá/mở khoá, đổi vai trò, đổi cấu hình, tải tệp (cả bị từ chối), mọi 403, toàn bộ đường tiền và đơn. Email chỉ lưu dạng băm. Việc bị từ chối vẫn có dòng log (giao dịch riêng) |
| **Còn lại** | Dòng log mã OTP cũ ở `AuthService.java:168` (nhóm 1), màn xem Nhật ký, cảnh báo tự động, role DB chỉ-INSERT, khoá đăng nhập theo email có thể bị lợi dụng (BE-42) |

### 7. Kiểm thử

| | Nội dung |
|---|---|
| **Cũ làm gì** | Test tích hợp cho đặt hàng, ví, rút tiền, ZaloPay, trả hàng quá hạn, upload, bảo vệ đầu vào |
| **Hạn chế** | Không test song song; không test cả vòng đời; không có môi trường chạy test trên máy chưa có DB |
| **Bây giờ** | `MoneyRulesTest`, `AuctionMoneyTest`, `ShopSlaAndLockTest`, `OpsGapsTest`, `SecurityAuditTest`, `ConcurrencyTest`, `MultiBidderTest`, `FullJourneyTest` (16 câu chuyện, kiểm bảo toàn tiền), `JourneyEdgeCasesTest` (15 ca). Kế hoạch: [TEST_PLAN_TOAN_DIEN.md phần B](TEST_PLAN_TOAN_DIEN.md). Cách chạy trên máy không có DB: tạo cụm Postgres tạm cổng 5433, đặt `TEST_DB_URL` |
| **Còn lại** | Không kiểm tải thật, WebSocket phòng đông, ZaloPay thật, push; chưa có CI cho backend (BE-40) |

### 8. Việc còn lại (tóm tắt)

| Nhóm | Việc | Ghi chú |
|---|---|---|
| **Nhóm 1 (hoãn theo yêu cầu chủ repo)** | BE-32 profile mặc định `dev`; gỡ mã OTP khỏi log; BE-33 khoảng giá trị cấu hình, cận trên giá và tồn kho | BE-32 là P0 |
| **Làm cùng frontend** | Màn Staff đối chiếu COD (**bắt buộc, không có thì đơn COD không hoàn tất**), màn lô chờ kiểm định lại, hiện địa chỉ gửi trả, hiện hạn và uy tín shop, thông báo đẩy | [DANH_GIA_BA_TESTER.md phần C](DANH_GIA_BA_TESTER.md) |
| **Cần chủ repo / hạ tầng / luật** | Pháp lý giữ tiền hộ và thuế, KYC, Admin hai cấp, CI backend, deploy, nhiều instance | [DANH_GIA_BA_TESTER.md phần D](DANH_GIA_BA_TESTER.md) mục C |
| **Đấu giá dang dở** | ~~Huỷ hoá đơn đã trả vì lỗi sàn~~ (đã làm 2026-11-06, sự cố kho), bán sau phiên cho người chưa đạt sàn, kho giao hộ, hạn mức cọc theo lô | [DANH_GIA_BA_TESTER.md phần D](DANH_GIA_BA_TESTER.md) mục D |

### Nguồn chi tiết

- [DANH_GIA_BA_TESTER.md phần B](DANH_GIA_BA_TESTER.md): 42 lỗi, trạng thái, các đợt cập nhật 1–7
- [THAY_DOI_SO_VOI_CODE_CU.md phần E](THAY_DOI_SO_VOI_CODE_CU.md): nhật ký từng việc đã làm (mục A–J), file đã đổi, rủi ro
- [THAY_DOI_SO_VOI_CODE_CU.md phần B](THAY_DOI_SO_VOI_CODE_CU.md): phân tích luồng tiền đấu giá, 18 tình huống
- [THAY_DOI_SO_VOI_CODE_CU.md phần D](THAY_DOI_SO_VOI_CODE_CU.md): thiết kế ghi log và trạng thái triển khai
- [TEST_PLAN_TOAN_DIEN.md phần B](TEST_PLAN_TOAN_DIEN.md): kế hoạch và kết quả test đầu cuối
- [DANH_GIA_BA_TESTER.md phần D](DANH_GIA_BA_TESTER.md): việc để sau
- [DANH_GIA_BA_TESTER.md phần C](DANH_GIA_BA_TESTER.md): việc frontend phải làm kèm

---

# Phần B. Luồng tiền đấu giá: phân tích và quy tắc

*(Trước là `AUCTION_MONEY_FLOW.md`.)*

Ngày 2026-11-05. Nguồn: SRS mục 6.4 (đăng ký, cọc), 6.5 (phiên), 6.6 (sau phiên), 8.2 (phí), 8.3 (cọc), 8.4 (nguyên tắc kỹ thuật), đối chiếu với code `auction/`, `consignment/`, `wallet/`, `order/`.
Quyết định của chủ sàn: phạt **% giá búa cho mỗi lô bỏ thanh toán**; phần còn lại do BA tự đánh giá theo SRS và thực tế vận hành.
Mọi con số là giá trị mặc định, sửa được trong `system_configs`.

> **Cập nhật 2026-11-06** (chủ sàn chốt, xem [THAY_DOI_SO_VOI_CODE_CU.md phần C](THAY_DOI_SO_VOI_CODE_CU.md) BR-6.1, BR-6.2, BR-6.5, BR-4.2): cọc và tiền phạt của người bỏ thanh toán **về sàn 100%** (`auction.forfeit_seller_percent` = 0); sàn **bù chênh** cho người bán khi lô bán lại thấp hơn; người về nhì được mời mua ở **giá công bằng**; kho làm mất / hỏng sách thì sàn bồi thường theo giai đoạn. Các mục dưới đã sửa theo luật này.

### 1. Mô hình tiền của một người tham gia đấu giá

Tiền đi qua ba "túi" trong sổ cái ví (SRS 8.1): `available` (dùng được), `held` (đang khoá), và ví sàn.

| Giai đoạn | available | held | Ví sàn | Loại giao dịch |
|---|---|---|---|---|
| Đăng ký, cọc D | −D | +D | | `DEPOSIT_HOLD` |
| Cọc thêm | −x | +x | | `DEPOSIT_HOLD` |
| Huỷ đăng ký (mới) / không thắng lô nào / phiên huỷ | +D | −D | | `DEPOSIT_RELEASE` |
| Thắng, thanh toán hoá đơn T (đã trừ cọc áp A) | −(T−A) | −A | + phí người mua + ship | `PAYMENT`, phí người mua + ship ghi `FEE` |
| Tiền người bán, chờ hoàn tất | | + giá búa (ví người bán) | | `SALE_PENDING` |
| Hoàn tất | người bán + (búa − hoa hồng) | − búa | + hoa hồng | `SALE_RELEASE`, `FEE` |
| Bỏ thanh toán | − phạt bù thiếu | − cọc còn giữ | + cọc + phạt (100%) | `DEPOSIT_FORFEIT`, `AUCTION_PENALTY` |
| Lô bị bỏ, bán lại thấp hơn, hoàn tất | người bán + bù chênh | | − bù chênh | `COMPENSATION` |

Ví dụ SRS 8.2: búa 1.000.000, cọc 500.000, ship 30.000. Hoá đơn 1.130.000; người thắng trả thêm 630.000 từ available; người bán nhận 850.000; sàn thu 250.000 (premium 100.000 + hoa hồng 150.000) cộng 30.000 ship chuyển tiếp.

### 2. Đối chiếu SRS với hiện trạng (lệch và rủi ro thực tế)

| ID | SRS nói | Code hiện tại | Hậu quả thực tế | Xử lý |
|---|---|---|---|---|
| AM-01 | 6.6, 8.3: bỏ thanh toán thì mất cọc | Cọc chỉ được trừ vào hoá đơn đầu; chỉ lô bỏ đầu tiên mất cọc, các lô bỏ sau chỉ bị cấm đấu giá | Thắng 5 lô, trả lô 1, bỏ 4 lô: người bán mất cả 4 lô mà người thắng không mất thêm đồng nào; cọc cố định trong khi lô có thể giá trị gấp 10 lần | **Phạt % giá búa cho từng lô bỏ** (mục 3.1) |
| AM-02 | Không nói | Phạt chỉ trích từ cọc; không có khái niệm nợ | Nếu cọc nhỏ hơn mức thiệt hại, hoặc đã dùng hết, không thu được gì | **Nợ phạt** thu từ ví, chặn tham gia và rút tiền đến khi trả (mục 3.2) |
| AM-03 | 6.4: hoàn cọc khi phiên huỷ | Không có cách huỷ đăng ký; cọc kẹt đến hết phiên dù người dùng đổi ý trước hạn | Khoá vốn không cần thiết; người dùng khiếu nại | **Huỷ đăng ký đến hạn đăng ký** (mục 3.3) |
| AM-04 | 6.6: lô không bán, người bán chọn trong 14 ngày | Không có hạn quyết định; người bán im lặng thì sách nằm kho vô hạn, không tính phí lưu kho | Sàn gánh chi phí kho và rủi ro; lô kẹt | **Tự trả sách sau 7 ngày không quyết định** (mục 3.4) |
| AM-05 | 8.2: phí lưu kho trừ người bán | Trừ thẳng vào ví người bán; thiếu số dư thì lỗi, Staff không xuất kho được | Người bán không nhận được sách của chính mình; Staff kẹt | **Phí kho thành nợ**, vẫn trả sách (mục 3.2) |
| AM-06 | 8.2: ship tính theo bảng và khối lượng | Mỗi hoá đơn tính ship đầy đủ cho từng lô | Người thắng 3 lô cùng phiên trả 3 lần phí nền | **Gộp ship**: lô sau chỉ tính phần phụ thu khối lượng (mục 3.5) |
| AM-07 | 6.6: sàn đã kiểm định, nếu sách khác báo cáo thì sàn chịu trách nhiệm | Sách bị trả về kho rồi lô tự quay lại `READY` và có thể lên phiên mà không ai kiểm tra lại | Sách đã qua tay người mua (có thể hỏng) lên phiên sau với báo cáo tình trạng cũ, gây tranh chấp kế tiếp | **Kiểm định lại bắt buộc** (mục 3.6) |
| AM-08 | 6.6: mời người trả giá cao thứ hai | Chọn đúng một người, không kiểm tra người đó còn đủ điều kiện | Mời nhầm người đang bị cấm đấu giá hoặc đang nợ phạt; lời mời vô nghĩa | **Chọn người hợp lệ kế tiếp** (mục 3.7) |
| AM-09 | 8.4: mọi thay đổi tiền ghi sổ cái | Đã đúng; phạt và nợ hiện chưa có loại giao dịch riêng | Khó đối soát phạt | Thêm loại giao dịch `AUCTION_PENALTY`; mọi bước ghi sự kiện `audit_events` |

Không đổi (đã đúng SRS và đủ sâu): hạn mức trả giá, soft close, xử lý đồng thời bid, hoàn cọc người không thắng, hoá đơn = búa + premium + ship − cọc, thanh toán 48 giờ, mời mua lần hai 24 giờ chỉ khi giá ≥ giá sàn, hoa hồng khi hoàn tất, sàn chịu trách nhiệm khi trả hàng.

### 3. Quy tắc mới

#### 3.1 Phạt bỏ thanh toán (theo quyết định của chủ sàn)
- Áp cho **mỗi** lô thắng bị quá hạn thanh toán (hoá đơn thường, không áp cho lời mời mua lần hai).
- `phạt = giá búa × auction.default_penalty_percent` (mặc định **10%**).
- Nếu người đó còn tiền cọc **đang giữ** (đăng ký còn `APPROVED`): **mất toàn bộ cọc** như SRS, và `phạt = max(phạt, cọc còn giữ)`. Phần phạt vượt cọc thu từ `available` (mục 3.2).
- Nếu cọc đã dùng (`APPLIED`) hoặc đã mất ở lô trước: chỉ thu `phạt = % giá búa` từ `available`.
- Tiền phạt và cọc bị thu **về sàn 100%** (`auction.forfeit_seller_percent` = 0, thay SRS 8.3 chia 50/50): người bán không còn lợi gì khi dùng tài khoản phụ đẩy giá rồi bỏ.
- **Bù chênh cho người bán** (BR-6.2): lô bán lại (mua lần hai hoặc phiên sau) với giá búa thấp hơn giá bị bỏ thì khi đơn mới hoàn tất, sàn trả người bán `(giá bị bỏ − giá mới) × (1 − hoa hồng)`, tối đa bằng số sàn đã thu từ người bỏ cho lô đó (cọc + phạt đã thu). Phạt thu sau lúc hoàn tất thì không bù thêm.
- Luôn cấm đấu giá `auction.ban_days` (90 ngày) như hiện tại. Mỗi lô bỏ làm mốc cấm lùi thêm.

#### 3.2 Nợ phạt và nợ phí kho
- Phần phạt hoặc phí kho **chưa thu đủ** ghi vào bảng `account_debts` (loại `AUCTION_PENALTY` hoặc `STORAGE_FEE`), trạng thái `OPEN`.
- Thu nợ tự động theo thứ tự cũ nhất trước, từ `available`, mỗi khi: tạo nợ, người dùng bấm thu nợ (`POST /me/debts/collect`), người dùng đăng ký phiên hoặc rút tiền (hệ thống thu trước rồi mới kiểm tra), người bán được trả tiền đấu giá.
- Khi còn nợ `OPEN`: **không đăng ký phiên, không trả giá, không rút tiền** (`DEBT_OPEN`, 409/403). Vẫn mua bán thường, nạp tiền, xem.
- Tiền thu được: nợ phạt và nợ phí kho đều vào ví sàn (nợ tạo trước 2026-11-06 vẫn chia theo tỷ lệ ghi trên khoản nợ).
- Admin miễn nợ (`WAIVED`) kèm lý do, ghi nhật ký. Miễn nợ không gỡ lệnh cấm đấu giá.

#### 3.3 Huỷ đăng ký
- Cho huỷ khi phiên còn `PUBLISHED` / `POSTPONED` và chưa tới `registrationDeadline`. Hoàn toàn bộ cọc (`DEPOSIT_RELEASE`), huỷ các giá tối đa tự động đã đặt, không tính vào số người đăng ký.
- Sau hạn đăng ký không huỷ được (phiên `CONFIRMED` đã tính đủ người).
- Đăng ký lại được nếu còn trong hạn; giữ nguyên số bài cũ.

#### 3.4 Lô không bán, tự xử lý
- Lô `UNSOLD` hoặc `CANCELLED` quá `auction.unsold_decision_days` (mặc định **7 ngày**) kể từ lúc đóng mà người bán chưa chọn: hệ thống chuyển sang **trả sách** (`RETURNED`), thông báo, bắt đầu 14 ngày lưu kho miễn phí; sau đó 5.000đ/cuốn/ngày.
- Người bán vẫn nhận lại sách như SRS; không tự động đưa lô vào phiên sau (tránh phát sinh lượt mà người bán không biết).

#### 3.5 Gộp phí giao
- Người thắng nhiều lô trong cùng một phiên, giao tận nơi tới địa chỉ mặc định: phí giao của lô thứ n = `phí(tổng khối lượng n lô đầu) − phí(tổng khối lượng n−1 lô đầu)`. Tổng các hoá đơn bằng đúng phí giao của kiện gộp.
- Nhận tại kho thì không tính. Người mua đổi cách nhận hoặc địa chỉ ở từng hoá đơn thì hoá đơn đó tính lại theo khối lượng riêng của lô.

#### 3.5b Lời mời mua lần hai
- **Giá mời = giá công bằng** (BR-6.5): `max(giá sàn, min(giá cao nhất của người về nhì, giá cao nhất của người kế tiếp + 1 bước))`; không có người kế tiếp thì bằng giá sàn. Ví dụ người bỏ 300.000, người về nhì 250.000, người thứ ba 150.000 → mời 160.000.
- Giữ nguyên: không có cọc để trừ, hạn 24 giờ, giá ≥ giá sàn. **Không phạt** nếu từ chối hoặc để quá hạn (SRS không yêu cầu).

#### 3.6 Kiểm định lại khi lô bị trả hàng
- Đơn đấu giá `RETURNED` / `FAILED_DELIVERY`: hoàn tiền người mua đầy đủ như hiện tại; lô chuyển sang trạng thái mới `INSPECTING` (nằm trong kho, chưa xếp phiên được).
- Staff kiểm định lại (`POST /staff/lots/{id}/reinspect`, bắt buộc có báo cáo): đạt → `READY`; không đạt → `RETURNED` trả người bán, bắt đầu hạn lưu kho (sàn đã chịu trách nhiệm hoàn tiền người mua).

#### 3.7 Chọn người về nhì hợp lệ
- Xét các lượt trả giá cao nhất của từng người (không phải người bỏ thanh toán), từ cao xuống thấp: người đầu tiên có giá ≥ giá sàn, **không bị cấm đấu giá, không còn nợ, không phải người ký gửi** thì được mời. Không có ai thì lô quay lại `READY`.

### 4. Ma trận kịch bản (kết quả mong đợi)

Quy ước: cọc 500.000, premium 10%, hoa hồng 15%, phạt 10%, cọc / phạt về sàn 100%.

| # | Kịch bản | Kết quả tiền | Trạng thái |
|---|---|---|---|
| K1 | Thắng 1 lô 1.000.000, trả đúng hạn | Mục 1 | Đăng ký `APPLIED`; lô `PAID` rồi `COMPLETED` |
| K2 | Không thắng lô nào | Hoàn 500.000 ngay khi đóng phiên | `REFUNDED` |
| K3 | Thắng lô 1.000.000, bỏ | Phạt = max(500.000; 100.000) = 500.000 từ cọc; về sàn 500.000 | `FORFEITED`; cấm 90 ngày; mời người về nhì |
| K4 | Thắng lô 10.000.000, bỏ, ví đủ | Phạt 1.000.000 = cọc 500.000 + 500.000 từ ví; về sàn 1.000.000 | Như K3 |
| K5 | Như K4 nhưng ví chỉ có 100.000 | Thu 600.000; **nợ 400.000** | Nợ `OPEN`; chặn đăng ký, trả giá, rút tiền |
| K6 | Sau K5 nạp tiền rồi thu nợ | Nợ `PAID`, tiền về sàn | Hết chặn (trừ lệnh cấm đấu giá còn hạn) |
| K7 | Thắng 2 lô, trả lô 1 (cọc đã áp), bỏ lô 2 giá 2.000.000 | Phạt 200.000 từ ví (không còn cọc) | Cấm đấu giá; lô 2 mời người về nhì |
| K8 | Thắng 2 lô, bỏ cả hai (1.000.000 và 2.000.000) | Lô đầu: mất cọc 500.000 (≥ 100.000). Lô sau: phạt 200.000 từ ví | Hai lô quay lại hàng chờ hoặc mời người về nhì |
| K9 | Huỷ đăng ký trước hạn | Hoàn 500.000 | `CANCELLED`, không tính vào số người đăng ký |
| K10 | Huỷ đăng ký sau hạn đăng ký | Từ chối `REGISTRATION_CLOSED` | Không đổi |
| K11 | Người về nhì không trả hoặc từ chối | Không phạt | Lô quay lại `READY` |
| K12 | Người về nhì đang bị cấm hoặc có nợ | Bỏ qua, mời người kế tiếp có giá ≥ giá sàn | |
| K13 | Đơn đã thanh toán rồi bị trả hàng | Hoàn đủ tổng hoá đơn (gồm cả phần cọc đã áp); người bán không nhận tiền; sàn trả lại premium + ship | Lô `INSPECTING` |
| K14 | Kiểm định lại: đạt / không đạt | | `READY` / `RETURNED` + hạn lưu kho |
| K15 | Lô không bán, người bán im lặng 7 ngày | | Tự `RETURNED`, đếm 14 ngày miễn phí |
| K19 | Bỏ lô 300.000 (mất cọc 500.000 → sàn), người về nhì mua lần hai ở 160.000 rồi hoàn tất | Người bán 136.000 + bù min(119.000; 500.000) = 255.000 | Có dòng `COMPENSATION` |
| K16 | Người bán nhận sách sau 20 ngày, ví hết tiền | Phí kho 6 ngày × 5.000 = 30.000; thu từ ví nếu có, thiếu thì nợ | Vẫn xuất kho, consignment `RETURNED` |
| K17 | Thắng 2 lô nặng 600g + 700g, cùng địa chỉ | Phí giao hoá đơn 1 = phí(600g); hoá đơn 2 = phí(1.300g) − phí(600g); tổng bằng phí kiện 1.300g | |
| K18 | ZaloPay báo thành công muộn sau khi hoá đơn đã quá hạn và bị huỷ | Tiền hoàn vào ví người mua (luật có sẵn); **phạt vẫn giữ** | Đơn đã `CANCELLED` |
| K18b | Người mua đã mở ZaloPay, tới hạn mà cổng chưa báo (cập nhật 2026-11-06) | Job hỏi lại ZaloPay; đã trả thì ghi nhận hoá đơn; còn chờ thì ân hạn 15 phút sau hạn rồi mới phạt | |
| K20 | Lô đã trả tiền, Staff báo giao thất bại do người mua (`buyerFault`) | Hoàn đủ hoá đơn, rồi phạt 10% giá búa + phí giao chiều đi (thu từ ví, thiếu thì nợ); cấm đấu giá | Lô `INSPECTING`; bù chênh người bán nếu bán lại thấp hơn |

### 5. API, cấu hình, sự kiện log

| Loại | Chi tiết |
|---|---|
| API mới | `DELETE /sessions/{id}/register` (huỷ đăng ký); `GET /me/debts`, `POST /me/debts/collect`; `POST /admin/debts/{id}/waive`; `POST /staff/lots/{id}/reinspect` |
| Giá trị enum mới | `LotStatus.INSPECTING`, `RegistrationStatus.CANCELLED`, loại giao dịch ví `AUCTION_PENALTY` |
| Cấu hình mới | `auction.default_penalty_percent` = 10; `auction.unsold_decision_days` = 7 |
| Mã lỗi mới | `DEBT_OPEN` |
| Sự kiện log | `AUCTION.REGISTRATION.CANCELLED`, `AUCTION.DEFAULT.PENALIZED`, `DEBT.CREATED`, `DEBT.COLLECTED`, `DEBT.WAIVED`, `AUCTION.LOT.AUTO_RETURNED`, `AUCTION.LOT.REINSPECTED`, `WAREHOUSE.STORAGE_FEE.CHARGED` (cộng với `WALLET.TX.POSTED` cho mọi dòng sổ cái) |

### 6. Ngoài phạm vi (ghi nhận để làm sau)
- Người bị cấm đấu giá vẫn đang giữ cọc ở các phiên tương lai: nên tự huỷ các đăng ký đó và hoàn cọc.
- ~~Sàn huỷ hoá đơn đã thanh toán vì lỗi của sàn (mất, hỏng sách trong kho)~~: đã làm 2026-11-06 (sự cố kho, SRS bổ sung BR-4.2).
- Bán sau phiên cho người trả cao nhất khi chưa đạt giá sàn (after-sale negotiation).
- Nâng hạn mức cọc theo giá trị lô, hoặc cọc riêng cho lô giá trị cao.
- Ảnh hưởng thuế, hoá đơn điện tử cho phí người mua và hoa hồng, quy định đấu giá tài sản (Luật Đấu giá tài sản): cần tham vấn pháp lý.

### 7. Giả định cần chủ sàn duyệt
Phạt 10% (và `max` với cọc còn giữ), hạn 7 ngày tự trả sách, chặn rút tiền khi còn nợ, miễn nợ do Admin quyết, gộp ship chỉ khi giao đến địa chỉ mặc định, không phạt người về nhì từ chối.

---

# Phần C. Luật nghiệp vụ bổ sung cho SRS (BR-x.y)

*(Trước là `SRS_BO_SUNG_NGHIEP_VU.md`.)*

Ngày 2026-11-06. Tài liệu này **bổ sung** cho SRS (`docs/Đặc-tả-ứng-dụng-mua-bán-đấu-giá-sách-cũ.docx`). SRS không nói thì theo tài liệu này; SRS nói khác thì theo tài liệu này (mục đó ghi rõ "thay SRS").
Con số nào cũng là giá trị mặc định, đổi được trong `system_configs`, trừ khi ghi "cố định".

**Nhãn trạng thái của từng luật**

| Nhãn | Nghĩa |
|---|---|
| **[Chốt]** | Chủ sàn quyết ngày 2026-11-06 |
| **[Đã có]** | Đã quyết trước đó và đã có trong code (xem `DANH_GIA_BA_TESTER.md phần B`, `THAY_DOI_SO_VOI_CODE_CU.md phần B`, `THAY_DOI_SO_VOI_CODE_CU.md phần E`) |
| **[Đề xuất]** | BA tự đặt theo thông lệ, chờ chủ sàn duyệt; chưa có trong code |

Cột "Code" của các bảng: ✅ đã làm · ⏳ chưa làm.

---

### 1. Tài khoản và định danh

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-1.1 | Mọi người muốn đăng ký phiên đấu giá phải xác thực **SĐT bằng OTP gửi thật** (SMS). Một SĐT chỉ gắn một tài khoản; SĐT chỉ được tính là "đã dùng" sau khi xác thực, nên không ai chiếm trước được số của người khác | [Chốt] | ⏳ (OTP mới ghi log) |
| BR-1.2 | Phải **định danh CCCD + ảnh chân dung** trước khi: (a) gửi yêu cầu ký gửi; (b) rút tiền lần đầu; (c) đăng ký phiên có ít nhất một lô với giá ước tính cao ≥ `kyc.auction_threshold` = 5.000.000đ | [Chốt] | ⏳ |
| BR-1.3 | Một CCCD chỉ gắn một tài khoản. Lệnh cấm đấu giá, khoá tài khoản và nợ phạt áp theo **người** (CCCD và SĐT), không chỉ theo tài khoản: tạo tài khoản mới bằng cùng CCCD / SĐT thì bị chặn | [Chốt] | ⏳ |
| BR-1.4 | Ảnh CCCD lưu riêng, không công khai, chỉ Admin được xem; mỗi lần xem ghi nhật ký. Trạng thái định danh: `NONE → PENDING → VERIFIED / REJECTED` (Admin duyệt, từ chối phải có lý do) | [Đề xuất] | ⏳ |
| BR-1.5 | Tên chủ tài khoản ngân hàng nhận tiền phải khớp họ tên trên CCCD (so sánh IN HOA, không dấu). Áp từ khi có BR-1.2 | [Đề xuất] | ⏳ (nhóm đã bỏ luật khớp tên vì chưa có CCCD) |
| BR-1.6 | Xoá tài khoản: chỉ khi không còn đơn dở, nợ, số dư ví, lô trong kho hay đăng ký phiên. Khi xoá, dữ liệu cá nhân bị ẩn danh; sổ cái ví, đơn hàng và nhật ký vẫn giữ để đối soát | [Đề xuất] | ⏳ |
| BR-1.7 | Khoá tài khoản thì: ẩn tin, huỷ đơn chưa giao, hoàn cọc ở các phiên chưa chốt | [Đã có] | ✅ |

### 2. Đăng bán giá cố định, ISBN, nội dung

#### 2.1 ISBN và thông tin sách

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-2.1 | ISBN **không bắt buộc** (sách trước 1970 và nhiều sách cũ không có ISBN) | [Chốt] | ✅ |
| BR-2.2 | Nếu có nhập: bỏ dấu gạch và khoảng trắng; chỉ nhận 10 ký tự (ký tự cuối được là `X`) hoặc 13 chữ số; **kiểm số kiểm tra** (ISBN-10: tổng có trọng số chia hết cho 11; ISBN-13: trọng số 1-3 chia hết cho 10, đầu số 978 hoặc 979). Sai thì báo `INVALID_ISBN` | [Chốt] | ✅ |
| BR-2.3 | ISBN-10 được đổi sang ISBN-13 (thêm 978 rồi tính lại số kiểm tra) để **lưu và tìm kiếm**; trang chi tiết vẫn hiện số người bán đã nhập. Tìm kiếm theo ISBN chuẩn hoá cả từ khoá (gõ có gạch hay ISBN-10 đều ra) | [Chốt] | ✅ (lưu và hiển thị ISBN-13, không giữ bản gốc người bán nhập) |
| BR-2.4 | Năm xuất bản trước 1970 mà có ISBN thì gắn **cờ cảnh báo** cho người duyệt tin / Staff kiểm định (không chặn, vì có sách in lại) | [Chốt] | ✅ (trường `isbnWarning` trong thông tin sách; frontend chưa hiển thị) |
| BR-2.5 | Sửa một trong các trường **ISBN, NXB, năm xuất bản, lần in, tên, tác giả, tình trạng, mô tả, ảnh** thì tin phải duyệt lại (shop uy tín vẫn được tự duyệt theo luật hiện có) | [Chốt] | ✅ (chưa có trường "lần in", xem BR-2.6) |
| BR-2.6 | Thêm trường tuỳ chọn **Lần in / ấn bản** (ví dụ "In lần 1, 1965"), vì "sai ấn bản" là một lý do trả hàng hợp lệ | [Đề xuất] | ⏳ |
| BR-2.7 | Gợi ý tự điền tên, tác giả, NXB, năm từ ISBN (Open Library / Google Books). Chỉ là gợi ý, người bán vẫn sửa được | [Đề xuất] | ⏳ |

#### 2.2 Chính sách nội dung

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-2.8 | **Cấm** đăng: sách in lậu, sách photocopy hoặc in lại không phép, sách bị cấm lưu hành, và tin không phải sách | [Chốt] | ⏳ |
| BR-2.9 | Người dùng đã đăng nhập được **báo cáo tin** (lý do: in lậu / photocopy / sách cấm / lừa đảo / khác, kèm ảnh tuỳ chọn), mỗi người mỗi tin một lần. Admin xử lý: gỡ tin (ghi lý do) hoặc bỏ qua; ghi nhật ký | [Chốt] | ⏳ |
| BR-2.10 | Shop bị gỡ tin vì vi phạm BR-2.8 lần thứ 3 trong 12 tháng thì **khoá shop**. Bị gỡ lần 1 hoặc 2 thì mất cờ shop uy tín | [Chốt] (3 lần) / [Đề xuất] (mất uy tín) | ⏳ |
| BR-2.11 | Người mua nhận phải sách in lậu / photocopy được trả hàng với lý do mới `COUNTERFEIT`, theo luồng "lỗi của shop" (BR-3.4) | [Chốt] | ⏳ (cần migration cho `CHECK` lý do trả hàng) |
| BR-2.12 | Giá bán ≥ 1.000đ và ≤ 500.000.000đ; tồn kho ≤ 999 | [Đề xuất] | ⏳ (BE-33) |
| BR-2.13 | Checkout gửi kèm giá người mua đã thấy; giá đổi thì trả `PRICE_CHANGED` và hỏi lại | [Đề xuất] | ✅ (`expectedTotal` tuỳ chọn, 2026-11-06) |

### 3. Đơn hàng, giao hàng, trả hàng, khiếu nại

#### 3.1 Luật đã có (tóm tắt để đủ bộ)

| ID | Luật | Nhãn |
|---|---|---|
| BR-3.0a | Thanh toán online 15 phút; shop xác nhận 24 giờ; giao cho vận chuyển trong 3 ngày; shop trả lời yêu cầu huỷ trong 24 giờ (im lặng là đồng ý) | [Đã có] ✅ |
| BR-3.0b | Người mua chưa bấm "Đã nhận" thì sau 7 ngày kể từ lúc giao shipper, hệ thống tự coi là đã giao; sau đó còn 3 ngày khiếu nại | [Đã có] ✅ |
| BR-3.0c | Trả hàng: shop đồng ý → người mua gửi trả (7 ngày) → shop xác nhận đã nhận (7 ngày) → hoàn tiền. Tồn kho không tự cộng lại | [Đã có] ✅ |
| BR-3.0d | COD do hãng vận chuyển thu hộ, sàn đối soát rồi mới trả shop. Hạn mức 3.000.000đ/đơn (500.000đ với người chưa có đơn hoàn tất); chặn COD khi có ≥ 2 đơn giao thất bại trong 90 ngày | [Đã có] ✅ |
| BR-3.0e | Shop có tỷ lệ đơn lỗi ≥ 10% (tối thiểu 5 đơn trong 90 ngày) thì mất cờ uy tín | [Đã có] ✅ |

#### 3.2 Phí ship khi trả hàng và giao thất bại [Chốt]

| ID | Tình huống | Ai chịu | Code |
|---|---|---|---|
| BR-3.4 | Trả hàng vì sai mô tả (sai tình trạng, thiếu trang, sai ấn bản, sách lậu) | **Shop** chịu ship cả hai chiều: người mua được hoàn tiền sách + ship chiều đi; ship chiều về (theo bảng phí) trừ vào tiền bán của shop. Đơn đấu giá: **sàn** chịu | ⏳ |
| BR-3.5 | Giao thất bại do người mua (từ chối nhận, sai địa chỉ, không liên lạc được) | Người mua: tiền hoàn **trừ phí ship chiều đi**. Đơn COD không trừ được tiền thì chỉ tính một lần giao thất bại (luật chặn COD ở BR-3.0d) | ✅ (phí đó về shop; đơn đấu giá thì phạt như bỏ thanh toán) |
| BR-3.6 | Giao thất bại do hãng vận chuyển hoặc shop | Hoàn đủ cho người mua; tính lỗi cho shop nếu do shop | ✅ |
| BR-3.7 | Ai gây lỗi giao thất bại do Staff ghi lúc đánh dấu thất bại (`BUYER` / `CARRIER` / `SHOP`); đến khi có webhook của hãng vận chuyển thì lấy từ hãng | [Đề xuất] | ✅ |

#### 3.3 Khiếu nại và hoàn một phần [Chốt]

| ID | Luật | Code |
|---|---|---|
| BR-3.8 | Ngoài "trả hàng hoàn tiền", shop được đề nghị **hoàn một phần 10–50% tiền sách** để người mua giữ sách. Người mua đồng ý thì khiếu nại đóng, phần còn lại về shop khi đơn hoàn tất; từ chối thì luồng trả hàng chạy tiếp | ⏳ |
| BR-3.9 | Khi phân xử, Admin chọn một trong ba: hoàn toàn bộ (kèm trả hàng), hoàn một phần (10–50%, người mua giữ sách), hoặc từ chối | ⏳ |
| BR-3.10 | Shop nộp được **ảnh phản biện** (tối đa 5 ảnh) cùng ghi chú | ⏳ |
| BR-3.11 | Admin phân xử trong **3 ngày** kể từ khi khiếu nại được chuyển lên. Quá hạn thì nhắc Admin và ghi cảnh báo; hệ thống **không tự quyết tiền** | ⏳ |

#### 3.4 Đánh giá [Đề xuất]

| ID | Luật | Code |
|---|---|---|
| BR-3.12 | Đơn hoàn tiền toàn bộ thì không được đánh giá. Người mua sửa đánh giá được một lần trong 7 ngày | ⏳ |
| BR-3.13 | Shop phản hồi mỗi đánh giá một lần. Người dùng báo cáo được đánh giá vi phạm; Admin ẩn đánh giá (điểm trung bình tính lại) | ⏳ (BE-16) |

### 4. Ký gửi và kiểm định

#### 4.1 Phiếu kiểm định có cấu trúc [Chốt]

| ID | Luật | Code |
|---|---|---|
| BR-4.1 | **Checklist cố định**, mục nào cũng phải chọn `Đạt / Lỗi nhẹ / Lỗi nặng`: đủ trang · đúng ấn bản / lần in · bìa · gáy · ruột · ẩm mốc / mối mọt · ghi chú / gạch chân · trang bị rách hoặc thiếu | ⏳ (hiện là JSON tự do) |
| BR-4.2 | **Bộ ảnh chuẩn**, bắt buộc khi Đạt: bìa trước, bìa sau, gáy, trang bản quyền (hoặc trang tên sách nếu không có), và ảnh từng chỗ hư hại. Tối thiểu 4 ảnh, cộng một ảnh cho mỗi mục "Lỗi" | ⏳ (hiện không bắt buộc ảnh) |
| BR-4.3 | **Trường chữ ký / bút tích**: `NONE` · `PRESENT_UNVERIFIED` (có, chưa xác thực) · `PRESENT_VERIFIED` (đã xác thực, phải ghi căn cứ: giấy chứng nhận, nguồn gốc, chuyên gia). Catalogue hiển thị đúng chữ; mô tả của người bán không được ghi "có chữ ký tác giả" nếu Staff chưa chọn `VERIFIED` | ⏳ |
| BR-4.4 | Luật suy ra kết quả: "Lỗi nặng" ở **đủ trang** hoặc **đúng ấn bản** → không được Đạt. Sách in lậu / photocopy → Không đạt, kèm cờ vi phạm (tính như BR-2.10) | [Đề xuất] ⏳ |
| BR-4.5 | **Xác minh thông tin sách**: với tên, tác giả, NXB, năm, lần in, ISBN, Staff đánh dấu `Khớp / Lệch`; lệch thì ghi giá trị đúng. Giá trị đã sửa gửi cho người bán cùng đề xuất giá; người bán chấp nhận đề xuất là chấp nhận thông tin đã sửa. Catalogue hiện thông tin đã xác minh với nhãn "Đã xác minh bởi ReBook" | [Đề xuất]: chủ sàn yêu cầu "đảm bảo sách chuẩn, hạn chế rủi ro" nhưng chưa chọn mục "Staff sửa thông tin"; đây là cách làm cả hai bên cùng đồng ý | ⏳ |
| BR-4.6 | Giá trong phiếu: ước tính thấp > 0, ước tính thấp ≤ ước tính cao, 0 < giá khởi điểm ≤ giá sàn ≤ ước tính thấp. Sai thì báo 400 **ngay lúc lập phiếu** | [Đề xuất] | ✅ (`INVALID_PRICE`) |
| BR-4.7 | Đã có: sơ duyệt 48 giờ, từ chối khi giá mong muốn < 300.000đ, hẹn lịch 7 ngày, 14 ngày nhận lại sách không đạt, tối đa 2 phiên, lô bị trả hàng phải kiểm định lại | [Đã có] | ✅ |

#### 4.2 Bồi thường khi kho làm mất / hỏng sách [Chốt: theo giai đoạn]

| Giai đoạn lúc xảy ra | Người bán nhận | Người mua nhận | Code |
|---|---|---|---|
| Đã nhận tại kho, chưa kiểm định | Giá mong muốn, tối đa `warehouse.compensation_cap_uninspected` = 2.000.000đ | — | ✅ |
| Đã kiểm định, chưa bán (chờ phiên, đang xếp phiên, không bán được) | Mức thấp của giá ước tính | — | ✅ |
| Đã bán, người mua đã thanh toán, chưa giao | Giá búa − hoa hồng (như bán thành công) | Hoàn đủ hoá đơn + **10% giá búa** bồi thường | ✅ |

- Code: ✅ `POST /staff/warehouse/{id}/incidents`, `GET /staff/warehouse-incidents`, `POST /admin/warehouse-incidents/{id}/approve | reject`. Chỗ làm khác thiết kế:
  - Kho chỉ thêm trạng thái `LOST`. Sách hỏng vẫn `IN_STOCK`, chờ người bán đến nhận và được miễn phí lưu kho (`storage_fee_waived`).
  - Lô đang chờ người thắng thanh toán (`SOLD`) chưa duyệt sự cố được (`LOT_AWAITING_PAYMENT`): chờ có kết quả thanh toán. Lô đang đấu (`OPEN`) thì phải huỷ lô trước (`LOT_LIVE`).
  - Ví sàn không đủ tiền thì không duyệt được (`PLATFORM_FUNDS_INSUFFICIENT`); chưa có chức năng nạp vốn cho ví sàn.
  - Giai đoạn tính theo phiếu kiểm định: có phiếu Đạt thì dùng mức thấp giá ước tính, kể cả khi người bán đã rút sách.
  - Sách đã **trượt kiểm định** mà bị mất: Admin phải chọn mức 0–100% (như sách hỏng), vì giá người bán tự khai không đáng tin.
  - Lô đã chuyển sang bán thường mà sách bị mất: tin đang chờ duyệt tự chuyển sang **bị từ chối** kèm lý do.
- BR-4.8 Staff khai báo sự cố (mất / hỏng, mô tả, ảnh); **Admin duyệt** rồi hệ thống mới chi tiền từ ví sàn. Trạng thái kho thêm `LOST` / `DAMAGED`. [Đề xuất về quy trình]
- BR-4.9 Hỏng một phần mà người bán muốn nhận lại sách: Admin chọn mức bồi thường 0–100% của mức trên. [Đề xuất]

### 5. Phiên đấu giá: lịch, cọc, hạn mức, trả giá

#### 5.1 Lịch phiên [Chốt, tính cả nhu cầu demo]

| ID | Luật | Code |
|---|---|---|
| BR-5.1 | Catalogue công bố ít nhất `auction.min_publish_lead_hours` = **72 giờ** trước giờ mở | ✅ |
| BR-5.2 | Hạn đăng ký ít nhất `auction.min_registration_close_hours` = **24 giờ** trước giờ mở (SRS 6.4) | ✅ |
| BR-5.3 | Lúc công bố, **chốt vào phiên**: % phí người mua, bảng bước giá, hệ số hạn mức. Đổi cấu hình sau đó chỉ áp cho phiên công bố sau (hoa hồng người bán đã được chốt theo lô) | ✅ |
| BR-5.4 | Nút "Mở phiên ngay" và hai khoá ở BR-5.1, BR-5.2 bằng 0 **chỉ có ở môi trường demo / dev** (cờ `app.auction.demo-enabled`). Môi trường thật không có nút này | ✅ (`DEMO_ONLY` ngoài demo; seed dev `V13_1` đặt hai khoá bằng 0) |

**Cho buổi demo:** profile `dev` có seed `V13_1` đặt `min_publish_lead_hours = 0`, `min_registration_close_hours = 0` và bật `app.auction.demo-enabled`. Vẫn tạo phiên, công bố và mở ngay được như trước; luật 72 giờ / 24 giờ chỉ chạy ở môi trường thật. Lưu ý: profile mặc định vẫn là `dev` (BE-32), deploy mà quên đặt profile thì nút demo cũng bật.

#### 5.2 Tiền cọc và hạn mức [Chốt: phiên + lô cao giá]

| ID | Luật | Code |
|---|---|---|
| BR-5.0 | Tài khoản nhân viên sàn (Staff / Admin) **không được** đăng ký phiên, trả giá hay đặt giá tối đa (`STAFF_CANNOT_BID`), vì Staff kiểm định lô và biết giá sàn | [Chốt] | ✅ |
| BR-5.5 | Cọc phiên giữ như SRS: một mức cho cả phiên, hạn mức = tổng cọc × 10. Cọc phiên phải > 0 | ✅ (cọc tối thiểu 1.000đ) |
| BR-5.6 | **Lô cao giá** (ước tính cao ≥ `auction.high_value_lot_threshold` = 10.000.000đ): chỉ được trả giá hoặc đặt giá tối đa khi **tổng cọc của người đó trong phiên ≥ cọc phiên + 10% mức thấp ước tính của lô** (`auction.high_value_deposit_percent` = 10). Thiếu thì báo `LOT_DEPOSIT_REQUIRED` kèm số tiền cần cọc thêm; người dùng cọc thêm bằng chức năng có sẵn (hạn mức tăng theo) | ✅ |
| BR-5.7 | Catalogue đánh dấu "Lô cao giá, cần cọc X đ" để người mua biết trước khi vào phòng | ⏳ |
| BR-5.8 | Đăng ký phiên có lô cao giá ≥ 5.000.000đ thì cần CCCD (BR-1.2) | ⏳ |
| BR-5.9 | Đã có: huỷ đăng ký trước hạn đăng ký thì hoàn cọc; không thắng lô nào thì hoàn cọc ngay khi phiên đóng; còn nợ thì không đăng ký / trả giá / rút tiền được | [Đã có] ✅ |

#### 5.3 Trả giá [Đề xuất]

| ID | Luật | Code |
|---|---|---|
| BR-5.10 | Lượt trả giá vượt mức tối thiểu hơn 10 bước giá phải gửi kèm `confirmed = true` (giao diện hỏi lại "Bạn chắc chắn trả X đ?"). Không có thì trả `CONFIRM_LARGE_BID` | ⏳ |
| BR-5.11 | **Không rút lượt trả giá** sau khi server đã nhận. Chỉ huỷ lô (Staff, khi có sự cố hệ thống) mới vô hiệu các lượt trả giá; huỷ lô phải có lý do và ghi nhật ký | ⏳ (lý do đã bắt buộc; chưa ghi nhật ký) |
| BR-5.12 | Phiên tạm dừng quá 60 phút thì Admin phải chọn: tiếp tục, hoặc kết thúc phiên (lô đang mở bị huỷ; các lô chưa chạy về chờ xếp phiên và không tính lượt) | ⏳ |
| BR-5.13 | Ghi IP và mã thiết bị cho mỗi lượt đăng ký và trả giá (chỉ Admin xem, giữ 12 tháng) | ⏳ (BE-25) |

### 6. Sau phiên

#### 6.1 Bỏ thanh toán: tiền phạt về đâu [Chốt: về sàn hết, thay SRS 8.3]

| ID | Luật | Code |
|---|---|---|
| BR-6.1 | Cọc bị thu và tiền phạt (10% giá búa, nợ nếu thiếu) **vào ví sàn 100%**. Bỏ tỷ lệ chia 50% cho người bán | ✅ |
| BR-6.2 | **Bù cho người bán**: nếu lô sau đó bán được (qua mua lần hai, bán sau phiên hoặc phiên sau) với giá búa thấp hơn giá bị bỏ, sàn bù cho người bán **phần chênh sau hoa hồng**, tối đa bằng số tiền sàn đã thu thực tế từ người bỏ cho lô đó (cọc + phạt đã thu). Tiền bù trả lúc đơn mới hoàn tất. Lô không bán được hoặc người bán nhận lại sách thì không bù | ✅ (phạt thu được sau lúc hoàn tất thì không bù thêm) |
| BR-6.3 | Người thắng bỏ thanh toán mà dùng chung CCCD / SĐT / tài khoản ngân hàng / thiết bị với người ký gửi lô đó: khoá cả hai tài khoản chờ Admin điều tra; người ký gửi không được bù BR-6.2 | [Đề xuất] ⏳ |
| BR-6.4 | Cấm đấu giá **luỹ tiến**: lần 1 cấm 90 ngày; lần 2 trong 12 tháng cấm 365 ngày; lần 3 cấm vĩnh viễn (Admin vẫn gỡ được, có ghi nhật ký) | [Đề xuất] ✅ (`auction.ban_days_repeat` = 365) |

#### 6.2 Mời mua lần hai: giá công bằng [Chốt, thay SRS 6.6]

- BR-6.5 Giá mời = **giá mà người về nhì lẽ ra phải trả nếu không có người bỏ**:
  `giá mời = max(giá sàn, min(giá cao nhất của người về nhì, giá cao nhất của người thứ ba + 1 bước giá))`.
  Không có người thứ ba thì `giá mời = max(giá sàn, giá khởi điểm)`.
  "Giá cao nhất của mỗi người" là lượt trả giá cao nhất người đó đã có ở lô (tay hoặc tự động); chỉ xét người còn hợp lệ (không bị cấm, không nợ, không phải người ký gửi; luật chọn người hợp lệ đã có).
- BR-6.6 Ví dụ: A (người bỏ) 5.000.000, B 4.800.000, C 2.000.000, bước 100.000, giá sàn 1.500.000 → B được mời ở **2.100.000** (SRS cũ là 4.800.000). Kẻ đẩy giá không còn kiếm được gì từ người mua thật.
- BR-6.7 Giữ nguyên: hạn 24 giờ, không cọc, không phạt nếu từ chối; giá người về nhì dưới giá sàn thì không mời. [Đã có] ✅
- Code: ✅ (`AuctionSettlement.fairSecondChancePrice`).

#### 6.3 Bán sau phiên khi chưa đạt giá sàn [Chốt]

| ID | Luật | Code |
|---|---|---|
| BR-6.8 | Lô đóng với kết quả "Không đạt giá" (`RESERVE_NOT_MET`): người bán có **24 giờ** (`auction.after_sale_seller_hours`) để đồng ý bán cho người trả cao nhất **ở đúng giá cuối** | ⏳ |
| BR-6.9 | Người bán đồng ý thì người mua nhận lời mời, có **24 giờ** (`auction.after_sale_buyer_hours`) để nhận hoặc từ chối. Không cọc, **không phạt** nếu từ chối. Phí người mua và hoa hồng như bán thường | ⏳ |
| BR-6.10 | Người trả cao nhất không còn hợp lệ (bị cấm, có nợ) thì không mời. Người bán im lặng hoặc người mua từ chối thì lô theo luồng "không bán được" đã có (người bán chọn trong 7 ngày, im lặng thì tự trả sách) | ⏳ |
| BR-6.11 | Bảng kết quả công khai vẫn ghi "Không đạt giá" và không lộ giá sàn; nếu bán sau phiên thành công thì không công bố lại | [Đề xuất] ⏳ |

#### 6.4 Đã có, giữ nguyên

Hoá đơn = giá búa + phí người mua + ship − cọc; hạn thanh toán 48 giờ; phạt 10% giá búa cho mỗi lô bỏ (mất cọc nếu cọc lớn hơn, thiếu thì ghi nợ); gộp phí ship khi thắng nhiều lô; lô không bán mà người bán im lặng 7 ngày thì tự trả sách; phí lưu kho thành nợ; lô bị trả hàng phải kiểm định lại. [Đã có] ✅

### 7. Tiền và ví (bổ sung)

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-7.1 | Đã có: khoá tiền nạp chưa dùng 24 giờ; hạn mức rút 20.000.000đ/ngày; rút tối thiểu 50.000đ; Admin duyệt rút phải nhập biên lai; đối soát ví với sổ cái mỗi đêm | [Đã có] | ✅ |
| BR-7.2 | Thêm tài khoản ngân hàng mới để rút: phải nhập OTP; tài khoản mới dùng được sau 24 giờ | [Đề xuất] | ⏳ (BE-02) |
| BR-7.3 | Rút tiền không mất phí (sàn chịu phí chuyển khoản) | [Đề xuất] | ✅ (đúng như hiện tại) |
| BR-7.4 | Khoản rút ≥ 50.000.000đ phải có Admin thứ hai xác nhận | [Đề xuất] | ⏳ (BE-28) |
| BR-7.5 | Sàn chi tiền bồi thường (BR-4.2) và tiền bù (BR-6.2) từ ví sàn, mỗi khoản một loại giao dịch riêng (`COMPENSATION`) để đối soát | [Đề xuất] | ✅ (loại giao dịch `COMPENSATION`) |

### 8. Thông báo bắt buộc

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-8.1 | Các mốc có hạn phải gửi **ngoài app** (push, và email dự phòng), không chỉ lưu thông báo trong app: thắng lô (hạn 48 giờ, nhắc lại lúc còn 24 giờ và 2 giờ), mời mua lần hai, mời bán / mua sau phiên, phát sinh nợ, khiếu nại sắp hết hạn trả lời, phiên dời / huỷ | [Đề xuất] | ⏳ (BE-36: chưa có push / email) |
| BR-8.2 | Chưa gửi được thông báo ngoài app thì **không được phạt** người thắng bỏ thanh toán. Đến khi có BR-8.1, hạn thanh toán vẫn 48 giờ nhưng phạt chỉ áp khi hệ thống đã gửi được ít nhất một thông báo ngoài app | [Đề xuất] | ⏳ |

### 9. Pháp lý (chưa xác minh, cần người am hiểu luật)

Ghi vào phần "rủi ro / hạn chế" của báo cáo đồ án, không làm trong code:
- Đấu giá tài sản chuyên nghiệp chịu điều chỉnh của Luật Đấu giá tài sản (SRS mục 5.3 đã nhắc). Một sàn tự đấu giá hàng ký gửi có thể cần mô hình pháp lý riêng.
- Thu và lưu CCCD, IP, thiết bị là dữ liệu cá nhân: cần đối chiếu Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân (đồng ý, mục đích, thời hạn lưu).
- Sàn thương mại điện tử giữ tiền hộ, thuế của người bán cá nhân, hoá đơn điện tử cho phí sàn: cần tham vấn (BE-31).

### 10. Cấu hình mới đề xuất

| Khoá | Mặc định (thật) | Demo | Mục |
|---|---|---|---|
| `kyc.auction_threshold` | 5000000 | 5000000 | BR-1.2 |
| `auction.min_publish_lead_hours` | 72 | 0 | BR-5.1 |
| `auction.min_registration_close_hours` | 24 | 0 | BR-5.2 |
| `auction.high_value_lot_threshold` | 10000000 | 10000000 | BR-5.6 |
| `auction.high_value_deposit_percent` | 10 | 10 | BR-5.6 |
| `auction.large_bid_confirm_steps` | 10 | 10 | BR-5.10 |
| `auction.max_pause_minutes` | 60 | 60 | BR-5.12 |
| `auction.after_sale_seller_hours` | 24 | 24 | BR-6.8 |
| `auction.after_sale_buyer_hours` | 24 | 24 | BR-6.9 |
| `auction.forfeit_seller_percent` | **0** (trước là 50) | 0 | BR-6.1 |
| `warehouse.compensation_cap_uninspected` | 2000000 | 2000000 | BR-4.2 |
| `warehouse.compensation_buyer_percent` | 10 | 10 | BR-4.2 |
| `order.partial_refund_min_percent` / `_max_percent` | 10 / 50 | 10 / 50 | BR-3.8 |
| `order.dispute_sla_days` | 3 | 3 | BR-3.11 |
| `listing.violation_lock_count` | 3 | 3 | BR-2.10 |

Cờ môi trường (không nằm trong `system_configs`): `app.auction.demo-enabled` (BR-5.4).

### 11. Thứ tự làm đề xuất

1. **Nhỏ, ít rủi ro (backend thuần):** BR-4.6 và BR-5.5 (chặn giá ≤ 0), BR-2.2–2.5 (ISBN), BR-5.3 (chốt phí lúc công bố), BR-5.4 (cờ demo), BR-6.1 (đổi `forfeit_seller_percent` về 0), BR-6.5 (giá mời công bằng).
2. **Cần frontend đổi theo:** phiếu kiểm định có cấu trúc (BR-4.1–4.5), lô cao giá (BR-5.6–5.7), bán sau phiên (BR-6.8–6.10), hoàn một phần (BR-3.8–3.10), báo cáo tin (BR-2.9), xác nhận trả giá lớn (BR-5.10).
3. **Cần dịch vụ ngoài:** OTP SMS (BR-1.1), push / email (BR-8.1), CCCD (BR-1.2–1.5).
4. **Bồi thường kho và tiền bù người bán** (BR-4.2, BR-6.2): làm sau khi có trạng thái kho `LOST` / `DAMAGED`.

Mỗi mục làm xong thì đổi ⏳ thành ✅ ở bảng tương ứng, và đánh dấu endpoint / field mới trong `apps/frontend/openapi/openapi.yaml` theo quy ước ở `CLAUDE.md`.

---

# Phần D. Thiết kế ghi log và sự kiện

*(Trước là `LOGGING_DESIGN.md`.)*

Ngày 2026-11-05. Mục tiêu: **mọi việc có ý nghĩa nghiệp vụ hoặc bảo mật đều để lại dấu vết, theo một khuôn duy nhất**, truy ngược được "ai, làm gì, lên cái gì, kết quả ra sao, lúc nào, từ đâu".
Đây là tài liệu thiết kế, chưa có code. Liên quan: [DANH_GIA_BA_TESTER.md phần B](DANH_GIA_BA_TESTER.md) (mục 9 bên dưới ghi log nào giúp phát hiện lỗi nào).

### 1. Hiện trạng (đọc từ code)

| Có | Thiếu / sai |
|---|---|
| `admin_activity_logs` (10 chỗ gọi `activityLog.record`): duyệt / từ chối tin, duyệt / từ chối rút tiền, khoá / mở khoá, đổi vai trò, gỡ cấm đấu giá, shop uy tín, đổi cấu hình | Chỉ ghi thao tác **Admin**. Không có đăng nhập, OTP, đổi mật khẩu, mở shop, đổi tài khoản ngân hàng, ký gửi, kiểm định, tạo phiên, tạo đơn... |
| Các bảng lịch sử riêng: `wallet_transactions` (sổ cái), `order_status_history`, `bids`, `payments.raw_callback` | Mỗi bảng một khuôn, không có cột chung (request id, IP, vai trò người làm). Ký gửi, lô, phiên, đăng ký đấu giá **không có lịch sử trạng thái** |
| 23 dòng `log.info/warn/error/debug` ở 10 file | Văn bản tự do tiếng Việt, không mã sự kiện, không `requestId`, không `userId`; lỗi lặp (vừa log vừa ném); **`AuthService.java:168` ghi OTP nguyên văn và email ra log** |
| Lệnh bị từ chối (403, 429, sai OTP) | Không được ghi. Bài học: bộ đếm OTP sai từng bị mất vì ghi chung giao dịch với lỗi rồi bị rollback |

### 2. Nguyên tắc

1. **Một cửa**: mọi sự kiện nghiệp vụ đi qua một lớp `AuditLog.record(...)` với **mã sự kiện** lấy từ một danh mục cố định (mục 5). Không ghi log nghiệp vụ bằng `log.info("...")` tự do.
2. **Cùng giao dịch với việc nghiệp vụ**: việc thành công thì log commit cùng, việc lỗi thì log rollback cùng (không có log "ma").
3. **Việc bị từ chối cũng phải ghi**, trong giao dịch riêng (`REQUIRES_NEW`), vì giao dịch chính sẽ rollback.
4. **Chỉ thêm, không sửa, không xoá** (giống sổ cái ví). Sai thì ghi sự kiện đính chính.
5. **Không ghi bí mật**: mục 6.
6. **Tiền** luôn là số nguyên VNĐ (chuỗi), kèm trước / sau khi có thay đổi.
7. **Mọi dòng log truy ngược được về một yêu cầu**: có `requestId`, trả cùng id trong header `X-Request-Id` và trong `ErrorResponse` để người dùng báo lỗi chỉ cần đọc mã.

### 3. Ba lớp log

| Lớp | Là gì | Lưu ở đâu | Ai đọc | Giữ bao lâu (đề xuất) |
|---|---|---|---|---|
| **A. Kiểm toán nghiệp vụ** | Sự kiện đã xảy ra với dữ liệu nghiệp vụ (đơn, tiền, tin, phiên, ký gửi, tài khoản) | Bảng `audit_events` (mới) | Admin (màn Nhật ký), đối soát, giải quyết khiếu nại | 5 năm với sự kiện tiền; 2 năm còn lại (**chủ sàn và pháp lý chốt**) |
| **B. Bảo mật** | Đăng nhập, OTP, khoá, đổi quyền, đổi ngân hàng, bị chặn (429 / 403) | Cùng bảng `audit_events`, `category = SECURITY` | Admin, người trực | 2 năm |
| **C. Kỹ thuật** | Lỗi hệ thống, job, hiệu năng, kết nối cổng thanh toán | File / stdout, **JSON một dòng**, đẩy lên công cụ thu log | Dev, vận hành | 30 ngày |

Các sổ chuyên biệt **giữ nguyên** (`wallet_transactions`, `order_status_history`, `bids`): đó là dữ liệu nghiệp vụ, không phải log. Mỗi dòng sổ đều có một sự kiện lớp A trỏ tới (`details.ledgerId`), và thêm cột `request_id` vào `wallet_transactions` để nối hai bên.
`admin_activity_logs` được **gộp vào `audit_events`** (migration chép dữ liệu cũ). API `GET /admin/activity-logs` giữ nguyên hình dạng trả về để màn Nhật ký không đổi.

### 4. Khuôn dữ liệu chung

Bảng `audit_events` và dòng JSON của lớp C dùng **cùng tên trường**:

| Trường | Kiểu | Ví dụ | Ghi chú |
|---|---|---|---|
| `occurredAt` | UTC, ISO-8601 | `2026-11-05T09:31:02.114Z` | Luôn UTC, hiển thị mới đổi múi giờ |
| `eventCode` | chuỗi | `ORDER.STATUS.CHANGED` | `MODULE.ĐỐI_TƯỢNG.HÀNH_ĐỘNG`, chữ hoa, tiếng Anh |
| `category` | enum | `BUSINESS` / `SECURITY` / `FINANCE` / `SYSTEM` | Dùng để lọc và đặt thời gian giữ |
| `result` | enum | `SUCCESS` / `DENIED` / `FAILED` | `DENIED` = bị luật chặn; `FAILED` = lỗi hệ thống |
| `reasonCode` | chuỗi | `BAD_CREDENTIALS`, `PRICE_CHANGED` | Dùng đúng `ErrorResponse.code` của API |
| `actorType` | enum | `USER` / `STAFF` / `ADMIN` / `SYSTEM` / `GATEWAY` | `SYSTEM` = job tự động, `GATEWAY` = callback ZaloPay |
| `actorId`, `actorRole` | số, enum | `42`, `USER` | `null` khi chưa đăng nhập; vai trò **lấy lúc thao tác** |
| `targetType`, `targetId` | chuỗi | `ORDER`, `1187` | Đối tượng chính bị tác động |
| `refCode` | chuỗi | `OD2611051234` | Mã nghiệp vụ người dùng nhìn thấy (đơn, thanh toán, ký gửi), để tìm bằng mã |
| `requestId` | UUID | `9f0c…` | Một yêu cầu HTTP / một lần chạy job / một sự kiện WS |
| `channel` | enum | `API` / `JOB` / `WS` / `CALLBACK` | |
| `ip`, `userAgent` | chuỗi | `203.0.113.7` | Chỉ với `channel = API / WS`; User-Agent cắt 120 ký tự |
| `summary` | chuỗi ≤ 500 | "Duyệt tin 'Số Đỏ' của shop X" | Tiếng Việt, **chỉ để hiển thị cho người**; không phân tích máy từ trường này |
| `details` | JSON | `{"from":"PREPARING","to":"SHIPPING"}` | Dữ liệu có cấu trúc: trước / sau, số tiền, tham số. Khoá tên camelCase |

Ví dụ một dòng lớp C (JSON) và một dòng lớp A cho cùng sự kiện:
```json
{"ts":"2026-11-05T09:31:02.114Z","level":"INFO","eventCode":"ORDER.DELIVERY.MARKED","result":"SUCCESS","actorType":"USER","actorId":42,"actorRole":"USER","targetType":"ORDER","targetId":1187,"refCode":"OD2611051234","requestId":"9f0c…","channel":"API","details":{"simulated":true,"shipToDeliverSec":2}}
```
Cột `details.simulated = true` và `shipToDeliverSec` (khoảng cách giữa "giao cho shipper" và "giao thành công") là thứ cho phép phát hiện lỗi BE-04.

### 5. Danh mục sự kiện

Cột "Ghi" : **A** = `audit_events`, **C** = chỉ log kỹ thuật, **L** = đã có sổ riêng, vẫn thêm một dòng A trỏ tới. Cột "Bắt buộc có trong `details`" là tối thiểu.
Mọi sự kiện đều có đủ trường chung ở mục 4; bảng chỉ ghi phần riêng.

#### 5.1 Xác thực và tài khoản (SECURITY)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `AUTH.REGISTER.SUCCESS` | Đăng ký xong | A | `emailDomain` (không ghi email đầy đủ ở lớp C) |
| `AUTH.LOGIN.SUCCESS` | Đăng nhập đúng | A | `method` |
| `AUTH.LOGIN.FAILED` | Sai mật khẩu / email không tồn tại / tài khoản khoá | A | `reasonCode`, `failuresInWindow`. **Không phân biệt "email không tồn tại" và "sai mật khẩu" ở `reasonCode`** (giống phản hồi cho người dùng) |
| `AUTH.LOGIN.THROTTLED` | Bị 429 do sai quá nhiều | A | `key` (email băm), `retryAfterSec` |
| `AUTH.TOKEN.REFRESHED` / `AUTH.TOKEN.REFRESH_FAILED` | Đổi refresh token | A | `reasonCode` khi lỗi |
| `AUTH.LOGOUT` | Đăng xuất | A | |
| `AUTH.OTP.SENT` | Gửi OTP | A | `purpose`, `channel`, `recipientMasked` — **không ghi mã** |
| `AUTH.OTP.VERIFIED` / `AUTH.OTP.FAILED` / `AUTH.OTP.LOCKED` | Nhập OTP | A | `purpose`, `attempt` |
| `AUTH.PASSWORD.RESET_REQUESTED` / `AUTH.PASSWORD.RESET` / `AUTH.PASSWORD.CHANGED` | Quên / đổi mật khẩu | A | `revokedTokens` |
| `USER.PROFILE.UPDATED` | Đổi họ tên, SĐT, ảnh | A | `changedFields`; đổi SĐT thì ghi `phoneVerifiedReset=true` |
| `USER.ADDRESS.ADDED` / `.UPDATED` / `.DELETED` | Sổ địa chỉ | A | `addressId`, `province` |
| `USER.SHOP.OPENED` / `USER.SHOP.UPDATED` | Mở / sửa shop | A | `bankChanged` (đổi ngân hàng là sự kiện nhạy cảm) |
| `USER.LOCKED` / `USER.UNLOCKED` / `USER.ROLE.CHANGED` / `USER.AUCTION_BAN.SET` / `USER.AUCTION_BAN.LIFTED` / `SHOP.TRUSTED.CHANGED` | Admin tác động tài khoản, hoặc hệ thống cấm đấu giá | A | `reason`, `before`, `after`, `until` |
| `ACCESS.DENIED` | 401 / 403 trên đường dẫn nhạy cảm (`/admin`, `/staff`, ví, rút tiền) | A | `path`, `method`, `requiredRole` |

#### 5.2 Tin đăng và danh mục (BUSINESS)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `LISTING.CREATED` / `LISTING.UPDATED` | Đăng, sửa tin | A | `priceBefore`, `priceAfter`, `stockBefore`, `stockAfter`, `changedFields` (cần cho BE-12) |
| `LISTING.HIDDEN` / `LISTING.SHOWN` | Ẩn / hiện | A | |
| `LISTING.REVIEW.SUBMITTED` / `.APPROVED` / `.REJECTED` | Chờ duyệt, Admin duyệt / từ chối | A | `reason`, `autoApproved` |
| `STOCK.RESERVED` / `STOCK.RESTORED` | Giữ hàng khi đặt, hoàn khi huỷ / trả | A | `listingId`, `qty`, `orderCode`, `stockAfter` |
| `CATEGORY.CREATED` / `.UPDATED` / `.DELETED` | Quản lý danh mục | A | `before`, `after` |

#### 5.3 Đơn hàng (BUSINESS)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `ORDER.CHECKOUT.CREATED` | Tạo một lần đặt (nhiều đơn) | A | `orderCodes`, `total`, `paymentMethod`, `idempotencyKey` |
| `ORDER.STATUS.CHANGED` | **Mọi** lần đổi trạng thái (đi qua `OrderService.transition`) | L + A | `from`, `to`, `note`; `actorType = SYSTEM` khi do job |
| `ORDER.SHIPPED` | Giao cho vận chuyển | A | `trackingCode`, `trackingProvided` (true nếu người dùng tự nhập) |
| `ORDER.DELIVERY.MARKED` | Bấm giao thành công / thất bại | A | `outcome`, `simulated`, `shipToDeliverSec` |
| `ORDER.CANCEL.REQUESTED` / `.ANSWERED` | Yêu cầu huỷ khi đã chuẩn bị, shop trả lời | A | `reason`, `approved` |
| `ORDER.RETURN.REQUESTED` / `.ANSWERED` / `.ESCALATED` / `.RESOLVED` | Vòng đời trả hàng | A | `reason`, `imageCount`, `approved`, `refundAmount`, `resolvedBy` |
| `ORDER.REVIEW.CREATED` | Đánh giá | A | `rating` |

#### 5.4 Thanh toán, ví, rút tiền (FINANCE)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `PAYMENT.CREATED` | Tạo thanh toán | A | `paymentCode`, `purpose`, `method`, `amount`, `expiresAt` |
| `PAYMENT.CALLBACK.RECEIVED` | Cổng gọi về hoặc người dùng quay về | A | `source` (`CALLBACK` / `RETURN` / `POLL`), `signatureValid`, `amount`, `gatewayRef`. **Không ghi `data`/`mac` thô** (chỉ lưu `payments.raw_callback`) |
| `PAYMENT.SUCCEEDED` / `PAYMENT.FAILED` / `PAYMENT.EXPIRED` | Kết quả cuối | A | `paymentCode`, `amount`, `gatewayTxnId` |
| `PAYMENT.SIMULATED` | Gọi `/payments/{code}/simulate` | A (**category SECURITY**) | `paymentCode`, `purpose`, `amount` (cần cho BE-32) |
| `PAYMENT.LATE_REFUND` | Tiền về muộn, hoàn vào ví | A | `orderCode`, `amount`, `reason` |
| `WALLET.TX.POSTED` | Mỗi dòng sổ cái ví | L + A | `ledgerId`, `type`, `availableChange`, `heldChange`, `availableAfter`, `heldAfter`, `refType`, `refId` |
| `WITHDRAW.REQUESTED` | Tạo yêu cầu rút | A | `amount`, `bankName`, `accountMasked`, `balanceSource` (nạp / bán hàng, cần cho BE-02) |
| `WITHDRAW.APPROVED` / `WITHDRAW.REJECTED` | Admin duyệt / từ chối | A | `amount`, `transferTime`, `proofImageUrl`, `note` |
| `BANKACCOUNT.ADDED` / `.CHANGED` | Thêm / đổi tài khoản nhận tiền | A (SECURITY) | `bankName`, `accountMasked`, `minutesSinceLastLogin` |
| `RECONCILE.RUN` | Job đối soát đêm (BE-06) | A | `walletTotal`, `expectedTotal`, `diff` |

#### 5.5 Đấu giá (BUSINESS / FINANCE)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `SESSION.CREATED` / `.UPDATED` / `.PUBLISHED` / `.CONFIRMED` / `.POSTPONED` / `.STARTED` / `.PAUSED` / `.RESUMED` / `.ENDED` / `.CANCELLED` | Mọi bước vòng đời phiên | A | `from`, `to`, `registered`, `minParticipants`, `reason` |
| `LOT.ASSIGNED` / `.OPENED` / `.CLOSED` / `.CANCELLED` / `.RESET` | Vòng đời lô | A | `sessionId`, `lotNumber`, `result`, `hammerPrice`, `bidCount`; **không ghi `reservePrice` ở lớp C** |
| `REGISTRATION.CREATED` / `.DEPOSIT_ADDED` / `.REFUNDED` / `.APPLIED` / `.FORFEITED` | Đăng ký và cọc | A + L | `paddle`, `deposit`, `bidLimit`, `reason` |
| `BID.PLACED` | Trả giá thành công | A | `lotId`, `amount`, `isAuto`, `previousLeaderId`, `endsAtBefore`, `endsAtAfter`, `softCloseExtended` |
| `BID.REJECTED` | Trả giá bị chặn | A | `lotId`, `amount`, `reasonCode` (`PRICE_CHANGED`, `ALREADY_LEADING`, `BID_LIMIT_EXCEEDED`, `LOT_NOT_OPEN`...) — dùng khi người dùng khiếu nại "bấm mà không ăn" |
| `PROXY.SET` / `PROXY.CANCELLED` | Giá tối đa tự động | A | `lotId`, `maxAmount` |
| `INVOICE.CREATED` / `INVOICE.OVERDUE` | Hoá đơn lô thắng; quá hạn | A | `orderCode`, `hammer`, `buyerPremium`, `shipping`, `depositApplied`, `dueAt` |
| `SECONDCHANCE.OFFERED` / `.DECLINED` / `.EXPIRED` | Mời mua lần hai | A | `runnerUpAmount`, `reserveMet` |

#### 5.6 Ký gửi và kho (BUSINESS)
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `CONSIGN.CREATED` / `.REVIEWED` / `.APPOINTMENT_BOOKED` / `.EXPIRED` / `.WITHDRAWN` | Giai đoạn A | A | `expectedPrice`, `approved`, `reviewNote`, `appointmentAt` |
| `CONSIGN.RECEIVED` | Staff nhận sách | A | `receivedBy`, `shelfCode`, `photoCount` |
| `CONSIGN.INSPECTED` | Kiểm định | A | `result`, `estimateLow/High`, `proposedStart`, `proposedReserve`, `conditionGrade` |
| `CONSIGN.SELLER_DECIDED` | Người bán chấp nhận / thương lượng / rút | A | `decision`, `counterReserve`, `agreedTerms` |
| `CONSIGN.UNSOLD_DECIDED` | Quyết định với lô không bán | A | `action`, `newReserve`, `listingPrice` |
| `WAREHOUSE.SHELF.CHANGED` / `.CHECKED_OUT` / `.RETURNED_TO_SELLER` | Kho | A | `from`, `to`, `reason`, `storageFee` |
| `WAREHOUSE.INCIDENT` | Mất / hỏng sách (cho BE-24 khi làm) | A | `severity`, `description` |

#### 5.7 Cấu hình, tệp, hệ thống
| Mã | Khi nào | Ghi | Bắt buộc có trong `details` |
|---|---|---|---|
| `CONFIG.UPDATED` | Admin đổi cấu hình | A | `key`, `before`, `after` (cần cho BE-05: biết đổi phí lúc nào) |
| `FILE.UPLOADED` / `FILE.REJECTED` | Tải ảnh | A | `size`, `contentType`, `purpose`, `reasonCode` |
| `JOB.RUN` | Mỗi lần chạy job **có xử lý ≥ 1 mục**, hoặc có lỗi | C | `job`, `durationMs`, `processed`, `failed`. Không log các lần chạy rỗng |
| `JOB.ITEM.FAILED` | Một mục của job lỗi | C (ERROR) | `job`, `itemId`, `exception` |
| `REQUEST.ERROR` | Lỗi 5xx | C (ERROR) | `status`, `path`, `exception`; ghi **một lần duy nhất ở `GlobalExceptionHandler`** |
| `NOTIFICATION.SENT` / `NOTIFICATION.FAILED` | Gửi thông báo (app, FCM, email, SMS khi có) | C | `type`, `channel`, `recipientId` |

### 6. Cái gì không bao giờ được ghi

| Không ghi | Thay bằng |
|---|---|
| Mật khẩu, hash mật khẩu, JWT, refresh token | Không ghi gì; chỉ `AUTH.*` với `tokenId` nếu cần |
| **Mã OTP** (hiện đang ghi ở `AuthService.java:168`) | `AUTH.OTP.SENT` với người nhận đã che. Môi trường dev vẫn cần xem mã: đọc bằng cờ `expose-in-response`, không qua log |
| Số tài khoản ngân hàng đầy đủ | `accountMasked` = 4 số cuối |
| Email, SĐT, họ tên ở lớp C | `userId`. Lớp A cho phép `summary` có tên hiển thị (dữ liệu nội bộ, quyền xem hạn chế) |
| Khoá ZaloPay, `mac`, `data` thô của callback | `signatureValid`, `amount`, `gatewayRef`. Dữ liệu thô chỉ nằm ở `payments.raw_callback` |
| Giá sàn (`reservePrice`) của lô | Chỉ ở lớp A và chỉ Admin xem; không ra response, không ra log kỹ thuật |
| Nội dung ảnh, mô tả dài | Chỉ URL / kích thước |

### 7. Mức log kỹ thuật (lớp C)

| Mức | Dùng cho |
|---|---|
| `ERROR` | Lỗi hệ thống cần người xử lý: 5xx, job lỗi, cổng thanh toán không phản hồi, ví không khớp sổ cái |
| `WARN` | Bất thường nhưng đã tự xử lý: thanh toán về muộn, proxy bid dừng sau 50 vòng, callback sai chữ ký, bị 429 liên tục |
| `INFO` | Ranh giới nghiệp vụ lớn và tóm tắt job (mỗi sự kiện một dòng, không lặp) |
| `DEBUG` | Chi tiết chẩn đoán; chỉ bật ở dev. Production mặc định `INFO` |

Quy tắc: **một lỗi chỉ log một lần**, ở nơi bắt cuối cùng; không `log.error` rồi `throw` ở tầng dưới.

### 8. Cảnh báo (rút từ log)

| Điều kiện | Dựa vào | Ý nghĩa |
|---|---|---|
| ≥ 20 `AUTH.LOGIN.FAILED` / phút từ một IP hoặc ≥ 10 / 15 phút một email | lớp B | Dò mật khẩu / khoá tài khoản người khác (BE-42) |
| ≥ 1 `PAYMENT.SIMULATED` ở môi trường production | lớp B | Cấu hình dev lọt ra production (BE-32), **cảnh báo tức thì** |
| `ORDER.DELIVERY.MARKED` với `simulated = true` ở production | lớp A | Người bán tự đánh dấu giao (BE-04) |
| `WITHDRAW.REQUESTED` có `balanceSource = TOPUP` và nạp cách < 24h | lớp A | Nạp rồi rút (BE-02) |
| `BANKACCOUNT.ADDED` rồi `WITHDRAW.REQUESTED` trong 10 phút | lớp A | Chiếm tài khoản rồi rút |
| `RECONCILE.RUN` có `diff ≠ 0` | lớp A | Ví lệch sổ (BE-06, BE-01) |
| `PAYMENT.CALLBACK.RECEIVED` với `signatureValid = false` | lớp A | Giả mạo callback |
| `JOB.RUN` có `failed > 0` hoặc `AuctionEngine` tick > 1 giây | lớp C | Phiên đấu giá có nguy cơ treo |
| `ORDER.STATUS.CHANGED` ở `PREPARING` quá hạn bàn giao | lớp A | Đơn ngâm (BE-07) |

### 9. Mỗi lỗi trong báo cáo audit cần log gì
| Lỗi | Sự kiện cần có |
|---|---|
| BE-01 COD | `ORDER.STATUS.CHANGED → COMPLETED` với `paymentMethod = COD` và `WALLET.TX.POSTED` tương ứng, để đối soát COD |
| BE-02 nạp rồi rút | `WITHDRAW.REQUESTED.balanceSource`, `BANKACCOUNT.ADDED` |
| BE-03 trả hàng | `ORDER.RETURN.*` có `refundAmount`, `STOCK.RESTORED` |
| BE-04 / FE-12 | `ORDER.DELIVERY.MARKED.simulated`, `shipToDeliverSec` |
| BE-05 phí đổi giữa chừng | `CONFIG.UPDATED` + lưu `feeRate` vào `details` của `ORDER.STATUS.CHANGED → COMPLETED` |
| BE-12 đổi giá | `LISTING.UPDATED.priceBefore/After`, `ORDER.CHECKOUT.CREATED` có giá người mua thấy |
| BE-17 cọc | `REGISTRATION.APPLIED / FORFEITED`, `INVOICE.OVERDUE` |
| BE-25 thông đồng đẩy giá | `BID.PLACED` có `ip`, `userAgent` |
| BE-26, BE-42 | `AUTH.LOGIN.*`, `AUTH.OTP.*` |
| BE-32 | `PAYMENT.SIMULATED` |
| BE-35 | `ACCESS.DENIED` có `reasonCode` riêng |

### 10. Lộ trình làm

Làm theo thứ tự này, mỗi bước chạy độc lập được:

| Bước | Việc | Phụ thuộc | Ghi chú |
|---|---|---|---|
| 1 | Bộ lọc gán `requestId` (đọc / sinh `X-Request-Id`), đưa vào `MDC` cùng `userId`, `role`, `ip`; thêm `requestId` vào `ErrorResponse`; cấu hình log JSON (Logback) | — | Nhỏ, có tác dụng ngay |
| 2 | **Gỡ OTP khỏi log** (`AuthService.java:168`), che email / tài khoản ngân hàng trong mọi `log.*` còn lại | — | Làm ngay, là lỗi bảo mật |
| 3 | Migration `V9`: bảng `audit_events` (cột như mục 4, chỉ INSERT: tạo role DB không có UPDATE / DELETE), chép dữ liệu `admin_activity_logs`; lớp `AuditLog` + enum `EventCode`; `record` (cùng giao dịch) và `recordDenied` (`REQUIRES_NEW`) | 1 | Giữ `GET /admin/activity-logs` trả cùng hình dạng |
| 4 | Gắn vào `OrderService.transition`, `WalletService.move`, `PaymentService`, `AuthService` (bảo mật), `BidService` | 3 | Chỗ tập trung nên ít chỗ phải sửa: `transition` và `move` là hai cửa duy nhất |
| 5 | Gắn nốt: ký gửi, kho, phiên, lô, đăng ký, tin, cấu hình, tệp | 3 | |
| 6 | Job `RECONCILE.RUN` và các cảnh báo mục 8 | 4, 5 | Cần công cụ thu log; nếu chưa có thì cảnh báo bằng truy vấn định kỳ trên `audit_events` |
| 7 | Màn Nhật ký của Admin: lọc theo `category`, `eventCode`, `refCode`, `requestId` | 3 | Phần frontend (khi cần) |

Kiểm thử cho mỗi bước: (a) một test duyệt qua mọi `EventCode` đảm bảo có trong danh mục tài liệu này; (b) test "việc bị từ chối vẫn có dòng log" (đăng nhập sai, trả giá thấp); (c) test "log không chứa bí mật" (chạy luồng OTP, chụp output, khẳng định không có mã).

### 11. Câu hỏi cần chủ sàn chốt
1. **Thời gian giữ** từng lớp (mục 3 mới là đề xuất; sự kiện tiền thường do luật kế toán quy định).
2. Có cho **người dùng xem lịch sử hoạt động của chính mình** (đăng nhập, đổi mật khẩu, rút tiền) không? Đề xuất: có, đủ cho phát hiện chiếm tài khoản; cần thêm một API đọc `audit_events` theo `actorId`.
3. Có **gộp** `admin_activity_logs` vào `audit_events` (đề xuất) hay giữ hai bảng?
4. Công cụ thu log lớp C: dùng gì (file xoay vòng, ELK, dịch vụ đám mây)? Quyết định ảnh hưởng bước 6.
5. Có ghi **IP** người dùng không? Cần cho BE-25 nhưng là dữ liệu cá nhân, cần thông báo trong chính sách bảo mật.

### 12. Trạng thái triển khai (cập nhật 2026-11-05)

Đã làm (bước 1, 3 và một phần bước 4 của mục 10):
- Migration `V9__money_rules.sql` tạo bảng `audit_events` (chưa tạo role DB không có UPDATE / DELETE).
- `audit/AuditLog` (`record` cùng giao dịch, `recordDenied` giao dịch riêng), `audit/EventCode` (danh mục mã đã gắn), `audit/AuditEvent`, `audit/RequestIdFilter` (gán `X-Request-Id`, IP vào MDC).
- Mã sự kiện đã gắn vào code: `WALLET.TX.POSTED` (mọi dòng sổ cái, trong `WalletService.move`), `WITHDRAW.REQUESTED`, `WITHDRAW.BLOCKED`, `ORDER.CHECKOUT.CREATED`, `ORDER.STATUS.CHANGED` (mọi lần đổi trạng thái đơn), `ORDER.DELIVERY.MARKED / CONFIRMED / AUTO`, `ORDER.RETURN.APPROVED / SHIPPED / RECEIVED / EXPIRED / ESCALATED`, `COD.BLOCKED / REMITTED / PAID_OUT / REFUND_PENDING / REFUNDED`, `RECONCILE.RUN / MISMATCH`.

Chưa làm: bước 2 (**gỡ OTP khỏi log**, `AuthService.java:168`), bước 5 (ký gửi, kho, phiên, lô, đăng ký, tin, cấu hình, tệp, xác thực), bước 6 (cảnh báo), bước 7 (màn Nhật ký), cấu hình log JSON, gộp `admin_activity_logs` vào `audit_events`, và `requestId` trong `ErrorResponse`. `admin_activity_logs` vẫn hoạt động song song, chưa đụng tới.

Bổ sung (luồng tiền đấu giá): `AUCTION.REGISTRATION.CANCELLED`, `AUCTION.DEFAULT.PENALIZED` (phạt bỏ thanh toán: giá búa, % phạt, phần thu từ cọc, phần thu từ ví hoặc ghi nợ), `AUCTION.LOT.AUTO_RETURNED`, `AUCTION.LOT.REINSPECTED`, `DEBT.CREATED`, `DEBT.COLLECTED`, `DEBT.WAIVED`, `WAREHOUSE.STORAGE_FEE.CHARGED`.

Bổ sung (đợt 2026-11-06): `ORDER.AUTO_CANCELLED` (quá hạn giao, shop không trả lời yêu cầu huỷ, hệ thống huỷ khi khoá tài khoản; có `reason`), `SHOP.TRUST.REVOKED`, `ACCOUNT.LOCK.CLEANUP` (số tin ẩn, đơn huỷ, đăng ký đấu giá hoàn cọc).

Bổ sung (đợt vá 2026-11-06): `AUTH.REGISTER.SUCCESS`, `AUTH.LOGIN.SUCCESS` / `AUTH.LOGIN.FAILED` / `AUTH.LOGIN.THROTTLED` (đăng nhập sai ghi băm email, không lưu email), `AUTH.OTP.SENT` / `AUTH.OTP.FAILED` / `AUTH.OTP.VERIFIED` (không ghi mã), `AUTH.PASSWORD.RESET_REQUESTED` / `AUTH.PASSWORD.RESET` / `AUTH.PASSWORD.CHANGED`, `USER.LOCKED` / `USER.UNLOCKED`, `USER.ROLE.CHANGED`, `SHOP.TRUST.CHANGED`, `CONFIG.UPDATED`, `FILE.UPLOADED` / `FILE.REJECTED`, `ACCESS.DENIED` (401/403 kèm `path`, `method`), `ORDER.DELIVERY.MARKED` dùng lại cho Staff đối chiếu hãng vận chuyển (đơn COD; chi tiết kết quả giao / thất bại nằm trong `details`). Nhắc việc trước hạn chỉ gửi thông báo, chưa có mã audit riêng. `AuditLog` có thêm `recordBy` / `recordDeniedBy` cho chỗ chưa có người đăng nhập trong ngữ cảnh. Còn nợ: gỡ OTP khỏi log (`AuthService.java:168`, nhóm 1), màn Nhật ký, cảnh báo tự động, role DB chỉ-INSERT.

---

# Phần E. Nhật ký thay đổi theo phiên (việc đã làm, dòng code cũ bị thay, rủi ro)

*(Trước là `SESSION_LOG_2026-11-05.md`.)*

File này ghi lại **mọi việc đã làm trong phiên**, theo thứ tự thời gian, để người khác đối chiếu. Cập nhật liên tục; mục mới thêm vào cuối.
Quy ước chủ repo đặt ra giữa phiên: **không sửa phần code không liên quan, không xoá code** (chỉ thêm, hoặc sửa đúng dòng thuộc yêu cầu).
Trạng thái git: **chưa commit gì**, chưa push.

### A. Việc đã làm trước khi có quy ước trên

| # | Việc | Công cụ / lệnh | Kết quả | File thay đổi |
|---|---|---|---|---|
| 1 | Đọc SRS (`docs/Đặc-tả-ứng-dụng-…docx`): giải nén `word/document.xml` ra văn bản | PowerShell, ghi vào thư mục scratchpad ngoài repo | Đọc xong 562 dòng | Không (file tạm ngoài repo) |
| 2 | Đọc code backend: wallet, payment, order, checkout, settlement, job, auction, consignment, listing, auth, user, admin, security, file, WebSocket, cấu hình, migration | Read / Grep / Bash (chỉ đọc) | Rà soát nghiệp vụ | Không |
| 3 | Đọc frontend: `CLAUDE.md`, `DECISIONS.md`, `BACKEND_HANDOFF.md`, `core/` (realtime, auth, error, notifications, settings), `env/*.json`, workflow CI | Read / Bash (chỉ đọc) | Rà soát frontend | Không |
| 4 | Viết báo cáo rà soát gộp, rồi tách | Write | `BUSINESS_RULE_AUDIT.md` tạo ra, sau đó **xoá chính file này** (do tôi tạo, chưa từng commit) khi tách | Xem dòng 5 |
| 5 | Kiểm lại từng lỗi với code, sửa các mục viết sai / nói quá, tách theo BE / FE | Write | Tạo `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần B` (41 mục), `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần C` (11 mục) | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần B`, `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần C` (mới) |
| 6 | Xem 14 commit mới sau lần rà soát (`git log`, `git diff 29d495d..HEAD`), chạy thử test backend | Bash | Chạy `./mvnw -Dtest=InputGuardsTest test` **3 lần, đều không chạy được**: (1) `JAVA_HOME` trỏ JDK 8, (2) sai đường dẫn JDK 21, (3) JDK 21 đúng nhưng Postgres báo sai mật khẩu user `rebook` (`FATAL: password authentication failed`). Không sửa cấu hình DB | Sinh thư mục `apps/backend/target/` (đã được `.gitignore`) |
| 7 | Cập nhật hai file audit theo code mới: BE-26, BE-33 sửa một phần; thêm BE-42, FE-12; ghi chú BE-02, BE-04; thêm mục "Việc test còn nợ" | Python (sửa text trong file của tôi) | Cập nhật xong | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần B`, `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần C` |
| 8 | Hook Stop báo 44 lỗi `dart analyze` do file sinh tự động chưa được tạo lại sau pull. Chạy `flutter gen-l10n` và `dart run build_runner build --delete-conflicting-outputs` trong `apps/frontend` | Bash nền | Sinh 339 file; `dart analyze --fatal-infos` sạch, `arch_check` OK | Chỉ file sinh (`*.g.dart`, l10n), đều nằm trong `.gitignore`, không hiện trong `git status` |
| 9 | Tắt tiến trình Dart theo yêu cầu: `dart` (PID 23264) và `dart_mcp_server` (PID 3444) | PowerShell `Stop-Process` | Kiểm lại còn 0 tiến trình | Không |
| 10 | Thiết kế ghi log thống nhất (BA): 3 lớp, khuôn trường chung, ~100 mã sự kiện, danh sách không được ghi, cảnh báo, lộ trình 7 bước | Write | Chưa có code | `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần D` (mới) |
| 11 | Hỏi chủ repo 4 quyết định về luật tiền (COD, rút tiền, trả hàng, xác nhận giao hàng) | AskUserQuestion | Xem mục B | Không |

### B. Quyết định của chủ repo cho luồng tiền

| Vấn đề | Quyết định | Cách hiểu và áp dụng |
|---|---|---|
| COD | "Áp dụng cách chuyên nghiệp nhất các sàn dùng và xử lý các trường hợp liên quan" | Mô hình sàn TMĐT: **hãng vận chuyển thu hộ, sàn đối soát với hãng, rồi mới trả tiền shop sau khi trừ phí**. Tiền COD chỉ vào ví shop sau khi (đơn hoàn tất) **và** (sàn xác nhận đã nhận tiền đối soát). Trả hàng COD chỉ hoàn ví người mua khi sàn đã nhận tiền đối soát. Thêm hạn mức COD và chặn người bom hàng |
| Nạp ví rồi rút | Khoá 7 ngày "hay nhưng chưa ổn vì vừa nạp muốn rút ngay thì phải chờ tận 7 ngày" | Rút ngắn: khoá tiền nạp **24 giờ** (cấu hình được, đặt 0 để tắt), thêm gắn nguồn tiền (bán hàng / tiền nạp) vào yêu cầu rút để Admin thấy, và hạn mức rút từ tiền nạp mỗi ngày |
| Trả hàng | Hoàn khi shop nhận lại sách | Thêm bước người mua gửi trả (mã vận đơn) và shop / kho xác nhận đã nhận; tồn kho không tự cộng lại |
| Giao hàng khi chưa có hãng vận chuyển thật | "Cách 1 nhưng thêm trường hợp nếu khách không nhấn xác nhận thì sao" | Người mua xác nhận đã nhận khi đơn đang giao; nếu không bấm, sau **7 ngày** kể từ lúc giao shipper hệ thống tự coi là đã giao rồi mới chạy hạn khiếu nại 3 ngày. Hai nút giả lập của shop chỉ bật ở profile dev |

### C. Việc đã làm sau quy ước "không sửa code không liên quan, không xoá code"

*(Mục này được cập nhật khi làm; mỗi dòng ghi file đã sửa và lý do.)*

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 12 | Tạo file log phiên này | `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần E` (mới) | |
| 13 | Migration luồng tiền: 9 cấu hình mới; loại giao dịch ví `COD_RECEIPT`, `COD_PAYOUT`; cột mới ở `orders`, `lots`, `return_requests`, `withdraw_requests`; bảng `audit_events`. Phát hiện cột `resolved_at` đã có từ V5 nên bỏ dòng thêm trùng | `apps/backend/src/main/resources/db/migration/V9__money_rules.sql` (mới) | Chỉ thêm; backfill `orders.shipped_at` từ `order_status_history` là lệnh `UPDATE` duy nhất trên dữ liệu cũ |
| 14 | Khung ghi sự kiện: `AuditLog` (cùng giao dịch / giao dịch riêng), `EventCode`, `AuditEvent`, `AuditEventRepository`, `RequestIdFilter` | `apps/backend/src/main/java/com/rebook/audit/` (5 file mới) | `admin_activity_logs` và `ActivityLogService` giữ nguyên, chạy song song |
| 15 | **COD** theo mô hình đối soát hãng vận chuyển: `CodService`, `CodController` (`GET /admin/cod/pending`, `POST /admin/cod/{orderId}/remit`); `OrderSettlement` chỉ trả shop khi đã đối soát, hoàn ví người mua khi đã đối soát; hạn mức COD và chặn bom hàng ở `CheckoutService` | `order/CodService.java`, `order/CodController.java` (mới); sửa `order/OrderSettlement.java`, `order/CheckoutService.java`, `order/OrderRepository.java`, `order/Order.java` | |
| 16 | **Rút tiền**: khoá tiền mới nạp 24h (trừ phần đã tiêu), hạn mức rút/ngày, ghi `topup_locked`; `GET /wallet/withdrawable`; khoá ví khi rút | sửa `wallet/WalletService.java`, `WalletController.java`, `WalletDtos.java`, `WithdrawRequest.java`, `WithdrawRequestRepository.java`, `WalletTransactionRepository.java`, `WalletTxType.java` | |
| 17 | **Trả hàng theo bước** (`AWAITING_GOODS`, `EXPIRED`), người mua gửi hàng trả, shop/kho xác nhận nhận lại, job quá hạn; tồn kho không tự cộng lại khi trả hàng | sửa `order/OrderService.java`, `OrderDtos.java`, `OrderController.java`, `OrderManagementController.java`, `OrderJobs.java`, `ReturnRequest.java`, `ReturnRequestRepository.java` | |
| 18 | **Giao hàng**: hai endpoint giả lập của shop chỉ chạy khi `app.shipping.simulate-enabled=true`; người mua xác nhận khi đang giao; job tự coi là đã giao sau 7 ngày; ghi `shippedAt` | sửa `order/OrderManagementController.java`, `OrderService.java`, `OrderJobs.java`, `OrderRepository.java`, `application.yml` (chỉ profile dev), `src/test/resources/application-test.yml` | Production không bật cờ này |
| 19 | **Chụp tỷ lệ phí**: phí đơn thường lúc đặt (`orders.fee_percent`), hoa hồng đấu giá lúc chấp nhận hợp đồng (`lots.commission_percent`) | sửa `order/CheckoutService.java`, `consignment/ConsignmentService.java`, `auction/AuctionSettlement.java`, `auction/Lot.java` | Đơn / lô cũ (cột null) vẫn dùng cấu hình hiện tại |
| 20 | **Đối soát ví** hằng đêm (ví so với sổ cái, đơn COD quá 7 ngày chưa đối soát) | `wallet/WalletReconciliationJob.java` (mới) | |
| 21 | Gắn ghi sự kiện vào các điểm tiền: mọi dòng sổ cái ví (`WalletService.move`), mọi lần đổi trạng thái đơn (`OrderService.transition`), COD, rút tiền, trả hàng, giao hàng, đặt hàng | các file ở dòng 15–20 | Mã sự kiện đã gắn: xem `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần D` mục 12 |
| 22 | Test mới: `MoneyRulesTest` (14 test: COD, rút tiền, giao hàng, trả hàng, chụp phí, sổ cái / đối soát), `ShippingSimulationGateTest` (1 test) | `apps/backend/src/test/java/com/rebook/order/` (2 file mới) | Đã chạy, đạt (xem mục D) |
| 23 | Cập nhật tài liệu: trạng thái BE-01…06, BE-13; mục "Cập nhật 2: luồng tiền"; mục "Việc frontend phải làm sau thay đổi luồng tiền"; mục 12 trạng thái triển khai log | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần B`, `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần C`, `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần D` | |

#### Những dòng code cũ đã bị thay thế (không có dòng nào bị xoá không thay)

Chỉ những dòng thuộc đúng hành vi được yêu cầu đổi. Danh sách đầy đủ để người review đối chiếu:

| File | Dòng cũ | Thay bằng |
|---|---|---|
| `OrderSettlement` | nhánh `else` COD cộng `gross` vào ví shop từ không có gì; tính phí bằng cấu hình hiện tại | nhánh `else if` chỉ trả shop khi đã đối soát; phí lấy từ `feePercentOf(o)` (đã chụp) |
| `OrderSettlement` | nhánh COD trả hàng cộng ví người mua từ không có gì; `restoreStock` chạy cho cả trả hàng | hoàn ví khi đã đối soát, chưa thì đánh dấu chờ; `restoreStock` bỏ qua trường hợp `RETURNED` |
| `OrderService` | `respondReturn` (đồng ý): đặt `APPROVED` rồi chuyển `RETURNED` ngay | gọi `approveReturn` (chờ gửi hàng) |
| `OrderService` | `resolveDispute` (hoàn tiền): chuyển `RETURNED` ngay | đã gửi hàng → `completeReturn` (logic cũ chuyển vào đây); chưa gửi → `approveReturn` |
| `OrderService` | `confirmReceived`: bộ lọc chỉ `PENDING`/`DISPUTED`; không xử lý đơn đang giao | thêm `AWAITING_GOODS`; thêm nhánh `SHIPPING` |
| `OrderService`, `OrderDtos` | `ReturnResponse.of(r, respondBy, resolvedByName)` và 13 trường | thêm tham số `shipBy` và 4 trường cuối |
| `CheckoutService` | `case COD -> null;` | `case COD -> { ensureCodAllowed(...); yield null; }` |
| `AuctionSettlement` | hoa hồng luôn lấy từ cấu hình | lấy từ lô nếu đã chụp |
| `ReturnRequest`, `WalletTxType`, `WalletService.move` | dòng khai báo enum / dòng `return` | thêm giá trị / lưu rồi ghi sự kiện rồi trả về |

### D. Rủi ro và việc chưa làm

- **Test backend đã chạy: 64 test đạt, 0 lỗi** (50 test cũ + 14 `MoneyRulesTest` + 1 `ShippingSimulationGateTest`, trừ `SeedDataTest`). Không chạy được `SeedDataTest` vì test cũ này gắn cứng `localhost:5432`, trong khi DB dùng để chạy nằm ở cổng 5433. Thay vào đó đã khởi động backend profile `dev` (có dữ liệu mẫu) trên cổng 8081: Flyway áp 11 migration đến `v9` thành công, `GET /wallet/withdrawable` và `X-Request-Id` hoạt động. Hai lỗi duy nhất trong lần chạy đầu là của chính test mới (đếm cả sự kiện bị từ chối); đã sửa test, không phải sửa code nghiệp vụ.
- Việc dựng môi trường chạy test (không thay đổi gì trong repo): (1) tạo cụm PostgreSQL tạm bằng `initdb` của Postgres 18 đã cài, nghe `127.0.0.1:5433`, dữ liệu trong thư mục scratchpad của phiên, user `rebook`/`rebook`, DB `rebook_dev`, **không đụng** Postgres chính trên cổng 5432; (2) lỗi môi trường riêng của máy này `Unable to establish loopback connection` khi JDK tạo `HttpClient` (Windows từ chối socket nội bộ trong thư mục tạm mặc định) khắc phục bằng cờ JVM `-Djdk.net.unixdomain.tmpdir=C:\rbtmp` (thư mục `C:\rbtmp` do tôi tạo); (3) JDK 21 của máy nằm ở `~/.jdks/graalvm-jdk-21.0.7` vì `JAVA_HOME` mặc định trỏ JDK 8. Sau khi xong đã tắt backend và cụm Postgres tạm.
- Lệnh chạy lại sau này (Git Bash): `cd apps/backend && export JAVA_HOME="$(cygpath -w ~/.jdks/graalvm-jdk-21.0.7)" TEST_DB_URL="jdbc:postgresql://localhost:5433/rebook_dev?currentSchema=rebook_test" && ./mvnw -DargLine="-Djdk.net.unixdomain.tmpdir=C:\\rbtmp" test` (cần bật lại cụm Postgres 5433 bằng `pg_ctl`, hoặc dùng DB riêng của bạn).
- `apps/backend/openapi.yaml` **đã xuất lại** từ `/v3/api-docs.yaml` của bản chạy thật: 219 dòng thêm, 0 dòng xoá (6 endpoint mới, `ReturnStatus` thêm `AWAITING_GOODS` / `EXPIRED`, 4 schema mới, 4 trường mới ở `ReturnResponse`). Frontend vẫn chưa đổi gì và chưa chạy `/sync-api`.
- Đây là thay đổi hành vi nghiệp vụ lớn (COD, trả hàng, rút tiền, giao hàng) chưa qua review của người khác.
- Giá trị mặc định do tôi chọn, chủ sàn nên duyệt: COD tối đa 3.000.000đ (500.000đ cho người chưa có đơn hoàn tất), chặn COD sau 2 đơn thất bại trong 90 ngày, khoá tiền nạp 24 giờ, hạn mức rút 20.000.000đ/ngày, tự coi là đã giao sau 7 ngày, hạn gửi hàng trả 7 ngày, hạn shop xác nhận hàng trả 7 ngày. Tất cả sửa được trong `system_configs`.
- Chưa làm: gỡ OTP khỏi log (`AuthService.java:168`), cấu hình log JSON, KYC / OTP khi đổi tài khoản ngân hàng, đối soát tổng với ZaloPay, BE-17 (cọc đấu giá), BE-22, và các mục khác trong `DANH_GIA_BA_TESTER.md phần B`.
- Dùng hook `Stop` của frontend: chỉ chạy lệnh Dart khi hook yêu cầu; theo yêu cầu chủ repo, phần frontend không chạy nữa.

### E. Việc làm sau khi có DB để chạy test

| # | Việc | File / công cụ | Kết quả |
|---|---|---|---|
| 24 | Tìm Postgres trên máy: Postgres 18 đang chạy ở 5432 (của chủ máy, không có mật khẩu quản trị), Docker Desktop tắt. Dựng cụm Postgres tạm bằng `initdb` / `pg_ctl` ở cổng 5433, tạo role và DB theo `scripts/create-database.sql` | thư mục scratchpad của phiên | Chạy được; đã tắt sau khi xong |
| 25 | Chẩn đoán lỗi `Unable to establish loopback connection`: tái hiện bằng chương trình Java nhỏ (`Selector.open()`), thử `preferIPv4Stack`, đổi JDK, đổi `java.io.tmpdir` đều không được; cờ `jdk.net.unixdomain.tmpdir` khắc phục | file thử trong scratchpad, thư mục `C:\rbtmp` | Khắc phục |
| 26 | Chạy toàn bộ test: lần 1 lỗi môi trường; lần 2 có 63/65 (1 lỗi test mới đếm sai sự kiện, 1 lỗi `SeedDataTest` gắn cứng cổng 5432); sửa hàm đếm trong test | `apps/backend/src/test/java/com/rebook/order/MoneyRulesTest.java` (hàm `auditCount` chỉ đếm `result = 'SUCCESS'`) | Lần 3: 64/64 đạt (bỏ `SeedDataTest`) |
| 27 | Khởi động backend profile `dev` trên DB mới để kiểm migration trên dữ liệu mẫu và gọi thử API | `./mvnw spring-boot:run` (cổng 8081) | Flyway lên `v9`; API chạy; đã tắt |
| 28 | Xuất lại spec API | `apps/backend/openapi.yaml` (ghi đè bằng bản xuất từ `/v3/api-docs.yaml`) | Chỉ thêm 219 dòng |
| 29 | Cập nhật trạng thái trong tài liệu: bỏ "chưa chạy test" | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần B`, `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần C` | |

### F. Nâng cấp luồng tiền đấu giá

Yêu cầu của chủ repo: tự đọc lại SRS, tự đánh giá chỗ cần cải thiện và làm lại như BA chuyên nghiệp, đủ sâu cho nhiều tình huống thực tế. Quyết định duy nhất do chủ repo chọn: **phạt % giá búa cho mỗi lô bỏ thanh toán**. Phần còn lại do tôi đề xuất (xem `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần B` mục 7 để duyệt).

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 30 | Đọc lại SRS mục 6.4–6.6, 8.2–8.4 và code `auction/`, `consignment/`, `wallet/`; viết bản phân tích BA: mô hình tiền, 9 điểm lệch SRS, 7 quy tắc mới, 18 kịch bản, API / cấu hình / sự kiện, giả định cần duyệt | `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần B` (mới) | |
| 31 | Migration V10: 2 cấu hình, loại giao dịch `AUCTION_PENALTY`, trạng thái `LotStatus.INSPECTING` và `RegistrationStatus.CANCELLED`, bảng `account_debts` | `apps/backend/src/main/resources/db/migration/V10__auction_money_rules.sql` (mới) | Chỉ thêm |
| 32 | **Nợ phạt / nợ phí kho**: thực thể, kho lưu trữ, `DebtService` (tạo nợ, thu từ ví, miễn nợ), `DebtController` (`GET /me/debts`, `POST /me/debts/collect`, `POST /admin/debts/{id}/waive`) | `wallet/AccountDebt.java`, `AccountDebtRepository.java`, `DebtService.java`, `DebtController.java` (mới); sửa `WalletService.java` (chặn rút khi còn nợ), `WalletController.java` (thu nợ trước khi rút), `WalletTxType.java` | |
| 33 | **Phạt bỏ thanh toán**: phạt = % giá búa mỗi lô; còn cọc thì mất cọc và phạt không thấp hơn cọc; phần vượt cọc thu từ ví, thiếu thì ghi nợ; chia người bán / sàn 50/50; chọn người về nhì hợp lệ (không bị cấm, không nợ, không phải người ký gửi) | sửa `auction/AuctionSettlement.java` | Dòng cũ thay: lời gọi `forfeitAndBan`, lấy người về nhì, nội dung thông báo |
| 34 | **Huỷ đăng ký** đến hạn đăng ký, hoàn cọc, huỷ giá tối đa tự động, đăng ký lại dùng số bài cũ; chặn đăng ký và trả giá khi còn nợ | sửa `auction/AuctionService.java`, `AuctionController.java`, `BidService.java`, `AuctionRegistration.java`, `ProxyBidRepository.java` | |
| 35 | **Lô không bán** quá 7 ngày không quyết định thì tự trả sách; **phí kho** thành nợ, vẫn xuất kho | `auction/AuctionMaintenanceJob.java` (mới); sửa `consignment/ConsignmentService.java`, `auction/LotRepository.java` | Dòng cũ thay: hai dòng trừ ví phí kho |
| 36 | **Gộp phí giao** nhiều lô cùng phiên | sửa `auction/AuctionSettlement.java` | Hàm `createInvoice` cũ giữ nguyên, thêm bản có tham số khối lượng đã gộp |
| 37 | **Kiểm định lại** khi lô bị trả về kho: `INSPECTING`, `POST /staff/lots/{id}/reinspect` | sửa `auction/LotStatus.java`, `consignment/ConsignmentService.java`, `ConsignmentController.java`, `ConsignmentDtos.java` | Dòng cũ thay: lô bị trả không còn tự về `READY` |
| 38 | Mã sự kiện log mới và cấu hình mới | `audit/EventCode.java`, `system/SystemConfigService.java` | |
| 39 | Test: `AuctionMoneyTest` (11 test) | `apps/backend/src/test/java/com/rebook/auction/AuctionMoneyTest.java` (mới) | Lần đầu 10/11; 1 test lỗi do cách test gọi ngoài giao dịch (sản phẩm gọi trong giao dịch), đã sửa test |
| 40 | Chạy lại toàn bộ test với Postgres tạm: **75/75 đạt** (trừ `SeedDataTest`); khởi động backend `dev` thấy Flyway lên `v10`, API mới trả đúng; xuất lại `openapi.yaml`; tắt backend và Postgres tạm | `apps/backend/openapi.yaml` | Diff 409 dòng thêm; 25 dòng "xoá" là schema `LotBrief` dời chỗ |
| 41 | Cập nhật tài liệu: trạng thái BE-15, 17, 18, 19, 20, 22; mục "Cập nhật 3"; việc frontend sau thay đổi; sự kiện log | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần B`, `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần C`, `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần D` | |

#### Dòng code cũ bị thay trong phần đấu giá
`AuctionSettlement`: lời gọi `forfeitAndBan(lot, buyer)`, đoạn lấy người về nhì, `lot.resetToReady()` ở nhánh trả hàng, nội dung thông báo mất cọc, `createInvoice` ba dòng phí giao (giờ tính theo kiện). `ConsignmentService`: hai dòng `walletService.debit/credit` phí kho. `AuctionService.register`: kiểm tra `ALREADY_REGISTERED` (nay cho đăng ký lại khi `CANCELLED`). `LotStatus`, `AuctionRegistration.Status`, `WalletTxType`: thêm giá trị. Không xoá hàm hay file nào.

#### Rủi ro
- Chưa qua review của người khác; chủ sàn nên duyệt các giá trị: phạt 10%, hạn tự trả sách 7 ngày, chặn rút tiền khi còn nợ.
- `LotStatus.INSPECTING`, `RegistrationStatus.CANCELLED` là giá trị enum mới trong API. Client frontend không lỗi khi gặp (enum lạ rơi vào `$unknown`, mapper về `pending`) nhưng hiển thị sai trạng thái cho tới khi đồng bộ.
- Smoke test trên DB tạm: lệnh `DELETE /sessions/1/register` thật sự huỷ đăng ký mẫu của `buyer1` trong DB tạm (DB tạm không còn giá trị).
- Thư mục rỗng `D:\rbtmp` do tôi tạo nhầm ở lượt trước vẫn cần chủ máy xoá tay.

### G. Đợt thuần backend (2026-11-06)

Yêu cầu của chủ repo: nhóm 1 (BE-32, gỡ OTP khỏi log, BE-33) để sau; việc cần làm cùng frontend thì ghi lại để sau; bây giờ chỉ sửa phần thuần backend. Danh sách việc để sau: `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần D` (mới).

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 42 | Ghi backlog: nhóm 1, việc cần làm cùng frontend, việc cần chủ repo / hạ tầng / luật, đấu giá còn dang dở | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần D` (mới) | |
| 43 | Migration V11: 5 cấu hình mới, cột `ship_due_at`, `cancel_requested_at`, `seller_fault` ở `orders` | `db/migration/V11__order_sla_and_shop_reputation.sql` (mới) | Đơn đang `PREPARING` lúc migrate được tính hạn từ lúc đó, không phạt oan |
| 44 | **BE-07** hạn giao cho vận chuyển 3 ngày: job tự huỷ, hoàn tiền người mua, tính lỗi shop (bỏ qua đơn đang có yêu cầu huỷ chờ shop trả lời) | sửa `order/OrderService.java`, `OrderJobs.java`, `OrderRepository.java`, `Order.java` | |
| 45 | **BE-08** shop im lặng 24 giờ trước yêu cầu huỷ: tự đồng ý huỷ (không tính lỗi shop) | như dòng 44 | |
| 46 | **BE-09** điểm uy tín shop: `ShopReputation` gỡ uy tín khi tỷ lệ đơn lỗi ≥ 10% với tối thiểu 5 đơn trong 90 ngày; tính lỗi khi shop huỷ, không xác nhận đúng hạn, không giao đúng hạn | `order/ShopReputation.java` (mới); sửa `OrderService.java` | Chỉ gỡ uy tín, Admin gắn lại được |
| 47 | **BE-27** khoá tài khoản: ẩn tin đang bán, huỷ và hoàn tiền đơn shop chưa giao cho vận chuyển, huỷ đơn chưa thanh toán của người mua, hoàn cọc phiên chưa chốt; đơn đã giao, hoá đơn lô thắng và yêu cầu rút tiền giữ nguyên | `admin/AccountLockService.java` (mới); sửa `admin/AdminService.java`, `catalog/ListingRepository.java`, `order/OrderService.java` (`cancelBySystem`), `OrderRepository.java` | |
| 48 | Người bị cấm đấu giá vì bỏ thanh toán: hoàn cọc các phiên chưa chốt (trước đó cọc kẹt) | sửa `auction/AuctionSettlement.java` (`releaseFutureRegistrations`), `AuctionRegistrationRepository.java` | |
| 49 | **BE-35** mã lỗi riêng `AUCTION_BANNED`, `NOT_REGISTERED` (vẫn HTTP 403) | sửa `common/ApiException.java`, `auction/BidService.java`, `auction/AuctionService.java` | Frontend đã có hằng số trùng mã nên tương thích |
| 50 | **BE-21 một phần**: không duyệt tin của cuốn sách còn nằm trong kho (`BOOK_IN_WAREHOUSE`) | sửa `catalog/ListingService.java`, `consignment/ConsignmentRepository.java` | |
| 51 | Mã sự kiện log và hằng số cấu hình mới | `audit/EventCode.java`, `system/SystemConfigService.java` | |
| 52 | Test: `ShopSlaAndLockTest` (7 test), `ConcurrencyTest` (4 test: 2 lần đặt cùng giỏ, 2 người tranh cuốn cuối, 2 yêu cầu rút cùng lúc, 2 lượt trả giá cùng mức) | `apps/backend/src/test/java/com/rebook/order/` (2 file mới) | Lần đầu chạy đạt hết |
| 53 | Chạy toàn bộ test với Postgres tạm: **86/86 đạt** (trừ `SeedDataTest`); khởi động backend `dev` thấy Flyway lên `v11`; spec API không đổi nên không ghi đè `openapi.yaml`; tắt backend và Postgres tạm | | |
| 54 | Cập nhật tài liệu: trạng thái BE-07, 08, 09, 21, 27, 35, 41; mục "Cập nhật 4"; việc frontend; sự kiện log | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần B`, `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần C`, `docs/ra-soat-nghiep-vu/THAY_DOI_SO_VOI_CODE_CU.md phần D` | |

#### Dòng code cũ bị thay trong đợt này
`OrderService`: thêm dòng vào `confirm`, `buyerCancel`, `sellerCancel`, `autoCancelUnconfirmed` (không xoá dòng nào). `BidService` / `AuctionService`: hai câu `ApiException.forbidden("...")` thành bản có mã. `AdminService.lock`: thêm một dòng gọi dọn việc dở. `ListingService.approve`: thêm đoạn kiểm tra đầu hàm. Không xoá hàm hay file nào.

#### Rủi ro
- Thay đổi hành vi vận hành đơn của shop (tự huỷ khi trễ giao) chưa qua review; các hạn 3 ngày / 24 giờ / ngưỡng 10% do tôi chọn, đổi được trong `system_configs`.
- `ConcurrencyTest` kiểm trên Postgres tạm, một máy; chưa thay thế được kiểm thử tải thật.
- Thư mục rỗng `D:\rbtmp` vẫn cần chủ máy xoá tay.

### H. Đợt vá sau đánh giá lại (2026-11-06)

Sau khi đánh giá lại toàn bộ việc đã làm, tôi vá các lỗ hổng tìm thấy. Chủ repo yêu cầu "vá đi"; vẫn giữ quy ước không sửa code không liên quan, không xoá code.

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 55 | Migration V12: cấu hình `notify.reminder_hours` (24) và `shipping.warehouse_address`; cột cờ nhắc `ship_reminder_sent`, `cancel_reminder_sent`, `payment_reminder_sent` ở `orders`, `decision_reminder_sent` ở `lots`; index cho đơn COD đang giao | `db/migration/V12__reminders_and_ops.sql` (mới) | Chỉ thêm |
| 56 | **COD chạy được ngoài đời thật**: đơn COD không còn tự giao sau N ngày (không có chứng cứ giao). Staff đối chiếu hãng vận chuyển: danh sách đơn đang giao, bấm "đã giao" hoặc "giao thất bại" | `order/OrderService.java` (`carrierConfirm`, `inTransit`), `OrderManagementController.java`, `OrderRepository.java` (`findShippedBefore` loại COD, `findNormalInTransit`), `OrderDtos.java` (`InTransitOrder`) | Endpoint mới: `GET /staff/orders/in-transit`, `POST /staff/orders/{id}/carrier-delivered`, `POST /staff/orders/{id}/carrier-failed` |
| 57 | Trả hàng: người mua biết gửi về đâu. Trả về địa chỉ shop (tin thường) hoặc địa chỉ kho sàn (hàng ký gửi / đấu giá) | `OrderService.returnDestination`, `OrderDtos.ReturnResponse` (`returnToName`, `returnToAddress`) | Địa chỉ kho đọc từ cấu hình `shipping.warehouse_address` |
| 58 | Staff thấy danh sách lô bị trả về kho đang chờ kiểm định lại | `consignment/ConsignmentService.inspectingLots`, `ConsignmentController` | Endpoint mới: `GET /staff/lots/inspecting` |
| 59 | Nhắc việc trước hạn (24 giờ): shop giao cho vận chuyển, shop trả lời yêu cầu huỷ, người mua thanh toán, người bán chọn hướng xử lý lô không bán. Mỗi việc nhắc đúng một lần (cờ ở mục 55) | `order/OrderJobs.java`, `OrderService.send*Reminder`, `auction/AuctionMaintenanceJob.java`, `ConsignmentService.sendDecisionReminder`, `OrderRepository`, `LotRepository` | |
| 60 | Đối soát đêm cảnh báo thêm đơn COD đang giao quá 7 ngày chưa có kết quả | `wallet/WalletReconciliationJob.java` | Chỉ log + ghi vào sự kiện `RECONCILE.RUN`, không đổi dữ liệu |
| 61 | Phủ nhật ký bảo mật: đăng ký, đăng nhập (đúng / sai / bị chặn), OTP (gửi / sai / đúng), đặt lại và đổi mật khẩu, khoá / mở khoá, đổi vai trò, gắn / gỡ uy tín shop, đổi cấu hình, tải tệp lên (cả bị từ chối), 403 trên mọi đường dẫn. Email không bao giờ nằm trong log (chỉ băm); mã OTP không nằm trong log | `audit/AuditLog.java` (`recordBy`, `recordDeniedBy`), `audit/EventCode.java`, `auth/AuthService.java`, `user/UserService.java`, `admin/AdminService.java`, `file/FileController.java`, `security/SecurityConfig.java` | Dòng log OTP cũ ở `AuthService.java:168` **vẫn còn** (nhóm 1, hoãn theo yêu cầu) |
| 62 | Test mới: `OpsGapsTest` (9), `SecurityAuditTest` (6); sửa `MoneyRulesTest` cho khớp luật mới (tự giao chỉ áp cho đơn ví, đơn COD vẫn `SHIPPING`) | `apps/backend/src/test/java/com/rebook/` | `SecurityAuditTest` lần đầu sai 3 chỗ kỳ vọng mã HTTP (đăng ký trả 201, xác thực OTP và đổi mật khẩu trả 204), đã sửa test, không sửa code |
| 63 | Chạy toàn bộ test với Postgres tạm: **101/101 đạt** (trừ `SeedDataTest`). Khởi động backend `dev` trên DB tạm: Flyway lên `v12`, `/staff/orders/in-transit` và `/staff/lots/inspecting` trả 200; xuất lại `apps/backend/openapi.yaml` từ `/v3/api-docs.yaml`: **chỉ thêm** (0 dòng cũ bị đổi / xoá) | `apps/backend/openapi.yaml` | 4 endpoint mới + schema `InTransitOrder`, `InspectingLot`, hai trường mới trong `ReturnResponse` |

#### Dòng code cũ bị thay trong đợt này
`OrderRepository.findShippedBefore`: thêm điều kiện loại đơn COD (đổi hành vi có chủ đích). `OrderJobs.autoDeliver` dùng lại truy vấn đó nên tự hưởng. Các dòng gọi `audit.record` thêm vào `AuthService`, `UserService`, `AdminService`, `FileController`, `SecurityConfig`. Không xoá hàm hay file nào.

#### Rủi ro
- Đơn COD không còn tự hoàn tất nếu Staff không đối chiếu: tiền người bán kẹt đến khi có người bấm. Đã có cảnh báo 7 ngày ở đối soát đêm, chưa có màn Staff ở frontend.
- Nhắc việc dựa vào cờ trong DB: nếu thông báo gửi lỗi sau khi bật cờ thì không nhắc lại (chấp nhận, cùng giao dịch nên thông thường cờ và thông báo cùng thành công hoặc cùng huỷ).
- Cổng ZaloPay thật, push FCM, tải thật chưa kiểm được.
- `D:
btmp` rỗng vẫn cần chủ máy xoá tay (`C:
btmp` là thư mục test cần).

### I. Kiểm tra lại đấu giá nhiều người trong một phiên (2026-11-06)

Yêu cầu của chủ repo: kiểm tra lại luồng đấu giá khi có nhiều người cùng trả giá trong một phiên. Viết `MultiBidderTest` (11 test, 5 người dùng đã đăng ký cùng một phiên): lượt tay luân phiên, từ chối người chưa đăng ký / bị cấm / đã huỷ đăng ký / chính người ký gửi, hạn mức, giá tối đa tự động đấu nhau, giá tối đa trả lời lượt tay, đồng hồ kéo dài khi trả giá phút chót, lượt trả sau giờ chốt, 20 lượt tay song song, 5 giá tối đa đặt song song, và cả phiên hai lô từ chốt lô, lập hoá đơn đến hoàn cọc người thua.

| # | Phát hiện | Cách xử lý | File |
|---|---|---|---|
| 64 | **Lỗi:** đặt giá tối đa (`PUT /lots/{id}/proxy-bid`) sau khi lô đã hết giờ nhưng engine chưa kịp chốt (tối đa ~1 giây) vẫn được nhận và đổi người dẫn đầu | Từ chối `409 LOT_NOT_OPEN` khi lô đang mở mà hết giờ | `auction/BidService.setProxy` |
| 65 | **Lỗi luật:** người trả giá tay đúng bằng giá tối đa của người đang dẫn lại cướp được vị trí dẫn (hai giá tối đa bằng nhau thì người đặt trước giữ, nhưng giá tay thì không) | Giá tay bằng giá tối đa đã đặt trước: người đặt trước giữ vị trí dẫn ở cùng mức giá, ghi một lượt tự động và báo người kia bị vượt | `auction/BidService.resolveProxies`, `takeLeadAtSamePrice` (mới) |

Không có phát hiện ở: tranh giá song song (không trùng, không vượt, `bid_count` khớp số dòng, mỗi lượt cao hơn lượt trước, người dẫn là người trả lượt cuối), nhiều giá tối đa đặt cùng lúc (người đặt cao nhất luôn dẫn), hoàn cọc người thua và giữ cọc người thắng, lô không đạt giá sàn.

**Kết quả:** `MultiBidderTest` 11/11, lặp lại 3 lần cùng `ConcurrencyTest` không lần nào lỗi; chạy toàn bộ **112/112 đạt** (trừ `SeedDataTest`). Spec API không đổi (không đụng chữ ký endpoint).

#### Dòng code cũ bị thay trong đợt này
Không xoá dòng nào; `BidService` chỉ thêm một kiểm tra trong `setProxy` và một khối ở đầu mỗi vòng xét proxy.

#### Chưa kiểm
Tải thật nhiều trăm người, WebSocket phát tin cho phòng đông, mất mạng giữa phiên. Test chạy một máy, một cụm Postgres.

#### I.2 Rà soát tiếp (tạm dừng / tiếp tục phiên)

| # | Phát hiện | Cách xử lý | File |
|---|---|---|---|
| 66 | **Lỗi do chính tôi gây ở mục 64:** kiểm "hết giờ" trong `setProxy` chặn nhầm lúc phiên đang tạm dừng (`ends_at` cũ chưa được đặt lại) | Chỉ kiểm khi phiên đang `LIVE` | `auction/BidService.setProxy` |
| 67 | **Lỗi có sẵn:** giá tối đa đặt trong lúc tạm dừng không được xét khi tiếp tục phiên, người đặt có thể không bao giờ được trả giá hộ trước khi lô chốt | `AuctionRunner.resume` chạy `resolveProxies` và báo người bị vượt; `afterPriceChange` thành package-private | `auction/AuctionRunner.java`, `BidService.java` |

Test mới `maxBidPlacedWhilePausedIsAppliedWhenTheSessionResumes`. **Toàn bộ 113/113 đạt** (trừ `SeedDataTest`).

Chưa sửa (ghi để sau): `BidRequest.amount` / `ProxyBidRequest.maxAmount` không ép số nguyên (`50000.4` được nhận rồi làm tròn khi lưu); chưa thêm `@Digits` vì chưa biết frontend gửi `50000` hay `50000.0`, ép sai thì chặn nhầm mọi lượt trả giá.

### J. Ép số nguyên cho tiền và kiểm thử luồng đầu cuối (2026-11-06)

Yêu cầu của chủ repo: sửa lỗi số lẻ ở tiền trả giá; sau đó đọc lại SRS và thiết kế, lên kế hoạch test luồng từ nạp tiền, đăng sách, mua bán, duyệt, tổ chức đấu giá, giao hàng, trả hàng, rồi chạy test nhiều trường hợp. Kế hoạch: [TEST_PLAN_TOAN_DIEN.md phần B](TEST_PLAN_TOAN_DIEN.md).

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 68 | Xem frontend: gửi số tiền bằng `int` của Dart (`api_auction_repository.dart`), JSON ra `50000`, không phải `50000.0` | đọc `apps/frontend/lib/features/auction/data/` | Ép số nguyên không làm hỏng frontend |
| 69 | **Lỗi:** số lẻ (`50000.4`) được nhận rồi làm tròn khi lưu; số quá lớn (10^16) làm tràn cột NUMERIC(15,0) | `common/WholeVnd.java` (mới): nhận `50000` và `50000.0`, từ chối `50000.4`, tối đa 15 chữ số. Gắn vào: trả giá, giá tối đa, cọc thêm, tiền cọc của phiên, nạp ví, rút ví, giá tin, giá mong muốn ký gửi, giá sàn đề nghị / giá sàn mới / giá bán cố định của lô không bán, 4 giá của phiếu kiểm định | `auction/AuctionDtos.java`, `wallet/WalletDtos.java`, `catalog/CatalogDtos.java`, `consignment/ConsignmentDtos.java` |
| 70 | **Lỗi:** người thắng chọn giao tận nơi sau phiên (đường thường gặp nhất) thì mỗi hoá đơn bị tính phí giao như một kiện riêng; "gộp kiện" chỉ chạy khi người mua đã có địa chỉ mặc định từ trước | Sau mỗi lần đổi cách nhận, tính lại phí giao của các hoá đơn chưa thanh toán cùng phiên theo thứ tự lập (lô sau chỉ trả phần tăng thêm) | `auction/AuctionSettlement.reconsolidateShipping`, `order/OrderRepository.findAuctionOrdersInSession` |
| 71 | Lập kế hoạch test | `docs/ra-soat-nghiep-vu/TEST_PLAN_TOAN_DIEN.md phần B` (mới) | |
| 72 | Test mới: `FullJourneyTest` 16 ca (S1–S14: nạp ví → đăng tin → duyệt → mua → giao → nhận → đánh giá; trả hàng; phân xử; huỷ; COD; ký gửi → phiên → nhiều người trả giá → hoá đơn → nhận hàng → trả người bán; không thanh toán; thiếu người; không bán được → chuyển bán thường; không đạt giá sàn → hạ giá sàn → bán; huỷ lô khi đang chạy; một người thắng hai lô; rút tiền; hai lượt trả cùng hoá đơn), `JourneyEdgeCasesTest` 15 ca (số tiền, ví, tin đăng, giỏ, quyền, trả hàng, ký gửi, kiểm định, xếp phiên, đăng ký, trả giá, bảo mật). Các câu chuyện kiểm bảo toàn tiền | `apps/backend/src/test/java/com/rebook/journey/` (3 file mới) | |

**Kết quả:** toàn bộ **144/144 đạt**, chạy hai lần liên tiếp (trừ `SeedDataTest`).

#### Điều đã hiểu sai lúc viết test (không phải lỗi code)
- Người bán nhận cả phí ship (shop tự giao), sàn chỉ thu phí trên tiền sách: `OrderSettlement` đã ghi rõ.
- Tên trạng thái tin: `PENDING_REVIEW`, `OUT_OF_STOCK`. Đánh giá trả 201.
- Đo bảo toàn tiền bằng toàn bộ ví sàn bị lệch vì job định kỳ của ứng dụng xử lý đơn do test khác để lại. Đã đổi sang chỉ tính giao dịch ví sàn gắn với đơn / đăng ký của người tham gia (`JourneySupport.platformShare`).

#### Dòng code cũ bị thay trong đợt này
Không xoá dòng nào. Chỉ thêm annotation `@WholeVnd` vào tham số record có sẵn và một lời gọi `reconsolidateShipping(o)` cuối `updateDelivery`.

#### Chưa kiểm
Giao diện Flutter, ZaloPay thật, thông báo đẩy, tải lớn, WebSocket phòng đông, và đường ZaloPay trả tiền đơn thường (có `ZaloPayTest` riêng). Hoá đơn đấu giá có nhiều tỉnh nhận khác nhau tính theo từng tỉnh (ghi `shortcut` trong code).

### K. Chặn nhân viên sàn đấu giá (2026-11-06)

Phát hiện khi đối chiếu bản đánh giá của nhóm (`DANH_GIA_NGHIEP_VU_improve_bussinessrule.md`, mục 6.6): nhóm thấy Staff đăng ký phiên bị báo "Số dư ví không đủ", nhưng nguyên nhân thật là đăng ký / trả giá không kiểm vai trò. Staff, Admin có tiền và đã xác thực SĐT thì đấu giá được, dù Staff là người kiểm định lô và biết giá sàn. Chủ repo duyệt: chặn ngay.

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 73 | Tài khoản `STAFF` / `ADMIN` không đăng ký phiên, không trả giá tay, không đặt giá tối đa (403 `STAFF_CANNOT_BID`), kể cả khi đã có đăng ký từ trước; cọc thêm cần đăng ký hợp lệ nên bị chặn theo | `user/User.java` (`isPlatformOperator`), `auction/AuctionService.register`, `auction/BidService.requireBidder`; test `MultiBidderTest.platformStaffCannotRegisterOrBid` | Chặn trước khi khoá cọc nên hết luôn câu báo sai "Số dư ví không đủ" |

**Kết quả:** 145/145 đạt (trừ `SeedDataTest`). Spec API không đổi (chỉ thêm mã lỗi).

#### Dòng code cũ bị thay trong đợt này
Không thay dòng nào; chỉ thêm một khối `if` ở mỗi chỗ kiểm.

### L. Luật nghiệp vụ nhóm 1 và nhóm 4 của SRS bổ sung (2026-11-06)

Trước đó trong phiên: rà soát nghiệp vụ backend, hỏi chủ repo 12 quyết định, viết [THAY_DOI_SO_VOI_CODE_CU.md phần C](THAY_DOI_SO_VOI_CODE_CU.md) (mã BR-x.y). Chủ repo yêu cầu làm nhóm 1 và nhóm 4 của mục 11 trước. Chi tiết luật và chỗ code làm khác thiết kế ghi ngay trong tài liệu đó (cột ✅).

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 74 | **Lỗi:** phiếu kiểm định nhận giá 0 / âm, đến lúc người bán chấp nhận mới vỡ ràng buộc DB và yêu cầu ký gửi kẹt ở `AWAITING_SELLER` (Staff không lập lại phiếu được). Nay chặn ngay lúc lập (`INVALID_PRICE`). Cọc phiên tối thiểu 1.000đ (trước cho 0 → hạn mức 0, không ai trả giá được) | `consignment/ConsignmentService.validatePricing`, `auction/AuctionDtos.SessionRequest` | BR-4.6, BR-5.5 |
| 75 | ISBN: bỏ gạch / khoảng trắng, kiểm số kiểm tra (`INVALID_ISBN`), ISBN-10 đổi sang ISBN-13 để lưu; tìm kiếm nhận ISBN-10 hoặc có gạch; đổi ISBN / NXB / năm xuất bản thì tin duyệt lại; cờ `isbnWarning` khi có ISBN mà năm < 1970. ISBN đã lưu mà người bán giữ nguyên thì không kiểm lại (7/8 ISBN dữ liệu mẫu sai số kiểm tra) | `common/Isbn.java` (mới), `catalog/BookService.java`, `catalog/CatalogDtos.java`, `catalog/ListingService.buildSpec`; migration chuẩn hoá ISBN cũ | BR-2.2–2.5 |
| 76 | Công bố phiên: phải trước giờ mở ≥ 72 giờ, hạn đăng ký trước giờ mở ≥ 24 giờ; chốt % phí người mua, bảng bước giá, hệ số hạn mức vào phiên. Bước giá, phí người mua (hoá đơn), hạn mức (đăng ký, cọc thêm) đọc từ phiên; phiên cũ chưa chốt thì đọc cấu hình | `auction/AuctionAdminService.publish`, `auction/AuctionSession.java`, `auction/AuctionViews.increment`, `auction/AuctionService`, `auction/AuctionSettlement.buyerPremiumPercent`, `system/SystemConfigService.bidIncrement` | BR-5.1–5.3 |
| 77 | "Mở phiên ngay" chỉ khi `app.auction.demo-enabled=true` (bật ở profile `dev` và test), ngoài đó 403 `DEMO_ONLY`. Seed dev đặt hai mốc lịch về 0 để demo như cũ | `config/AppProperties.java`, `auction/AuctionRunner.startNow`, `application.yml`, `application-test.yml`, `db/seed/V13_1__demo_auction_schedule.sql` (mới); test `StartNowDemoGateTest` | BR-5.4 |
| 78 | Cọc / phạt của người bỏ thanh toán về sàn 100% (`auction.forfeit_seller_percent` = 0). Ghi lên lô giá búa bị bỏ và phần cọc sàn giữ | migration V13, `auction/AuctionSettlement.forfeitAndBan`, `auction/Lot.java` | BR-6.1 |
| 79 | Mời mua lần hai ở giá công bằng: `max(giá sàn, min(giá cao nhất người về nhì, giá cao nhất người kế tiếp + 1 bước))`; không có người kế tiếp thì bằng giá sàn | `auction/AuctionSettlement.fairSecondChancePrice` | BR-6.5 |
| 80 | Bù chênh cho người bán khi lô bị bỏ rồi bán lại thấp hơn: phần chênh sau hoa hồng, trần = cọc sàn giữ + phạt sàn đã thu của lô, trả lúc đơn mới hoàn tất | `auction/AuctionSettlement.compensateSellerForDefault`, `wallet/AccountDebtRepository.platformPenaltyCollectedForLot`, `wallet/DebtService`, `wallet/WalletService.platformAvailable` | BR-6.2. `shortcut` trong code: phạt thu sau lúc hoàn tất không bù thêm |
| 81 | Sự cố kho: Staff khai báo mất / hỏng (`POST /staff/warehouse/{id}/incidents`, danh sách `GET /staff/warehouse-incidents`), Admin duyệt / từ chối (`/admin/warehouse-incidents/{id}/approve`, `/reject`). Bồi thường theo giai đoạn (chưa kiểm định: giá mong muốn, trần 2.000.000đ; đã kiểm định: mức thấp giá ước tính; đã bán đã trả tiền: người bán giá búa − hoa hồng, người mua hoàn đủ + 10% giá búa). Mất → lô / ký gửi / kho `LOST`; hỏng → Admin chọn 0–100%, trả sách miễn phí lưu kho | `consignment/WarehouseIncident*.java` (3 file mới), `consignment/ConsignmentController.java`, `consignment/ConsignmentDtos.java`, `consignment/ConsignmentStatus.java`, `consignment/WarehouseItem.java`, `consignment/ConsignmentService.returnToSeller`, `auction/LotStatus.java`, `wallet/WalletTxType.java` (`COMPENSATION`), `audit/EventCode.java` (4 mã mới) | BR-4.2, BR-4.8, BR-4.9 |
| 82 | Migration: cấu hình mới, cột chốt điều khoản của phiên, cột theo dõi tiền bỏ thanh toán của lô, trạng thái `LOST`, cột miễn phí lưu kho, loại giao dịch `COMPENSATION`, bảng `warehouse_incidents`, chuẩn hoá ISBN cũ | `db/migration/V13__business_rules_batch1.sql` (mới) | Khởi động thử profile `dev` trên DB trống: 16 migration chạy tốt, giá trị demo đúng |
| 83 | Test mới: `IsbnTest` (2), `BusinessRulesBatchTest` (7: giá ≤ 0, lịch + chốt điều khoản, duyệt lại tin, 4 ca sự cố kho), 3 ca trong `AuctionMoneyTest` (giá mời công bằng + bù chênh, không có người thứ ba, điều khoản chốt thắng cấu hình), `StartNowDemoGateTest` (1) | `apps/backend/src/test/java/com/rebook/` | |
| 84 | `apps/backend/openapi.yaml` xuất lại từ `/v3/api-docs.yaml`: thêm 4 endpoint sự cố kho, schema sự cố, `isbnWarning`; đổi mẫu ISBN và cọc tối thiểu | `apps/backend/openapi.yaml` | Frontend chưa chạy `/sync-api` |
| 85 | Ghi tài liệu | `THAY_DOI_SO_VOI_CODE_CU.md phần C` (đổi ⏳ → ✅, ghi chỗ làm khác), `DANH_GIA_BA_TESTER.md phần B` (cập nhật 8, 9), `DANH_GIA_BA_TESTER.md phần D` (màn sự cố kho, mã lỗi mới), `apps/frontend/docs/DECISIONS_V2.md` (trỏ tới SRS bổ sung; xem #86), file này | |
| 86 | Theo quy ước mới của chủ repo (file md tạo từ 2026-11-05 thì sửa thẳng, file có từ trước thì viết bản V2): sửa luật cũ "cọc chia 50/50", "mời mua với giá đã trả" trong `THAY_DOI_SO_VOI_CODE_CU.md phần B` (thêm kịch bản K19), `THAY_DOI_SO_VOI_CODE_CU.md phần A`, `TEST_PLAN_TOAN_DIEN.md phần B`, `DANH_GIA_BA_TESTER.md phần D`; viết `TEST_PLAN_TOAN_DIEN.md phần C` (kịch bản demo theo luật mới, thêm câu hỏi thầy có thể hỏi và cách xử lý lỗi `DEMO_ONLY`, lịch 72 giờ) và `apps/frontend/docs/DECISIONS_V2.md`; gỡ mục đã chèn vào `DECISIONS.md` gốc (khôi phục đúng bản trong git) | `docs/`, `apps/frontend/docs/` | `DEMO.md`, `DECISIONS.md`, `TEST_GUIDE.md`, `DEMO_ONLINE.md` giữ nguyên. Chuỗi `offersHint` trong `app_vi.arb` (không phải md) chưa sửa |

**Kết quả:** toàn bộ **158/158 đạt** (145 cũ + 13 mới, trừ `SeedDataTest`). Chạy trên cụm PostgreSQL tạm cổng 5433 trong thư mục scratchpad, không đụng Postgres chính cổng 5432; đã tắt và xoá sau khi chạy.

#### Dòng code cũ bị thay trong đợt này
- `catalog/CatalogDtos.java`: mẫu kiểm ISBN `^$|^(\d{9}[\dXx]|\d{13})$` thay bằng mẫu cho phép gạch / khoảng trắng (số kiểm tra kiểm ở `BookService`).
- `catalog/BookService.java`: `apply(book, req)` thêm tham số ISBN đã chuẩn hoá; `book.setIsbn(req.isbn())` thành `book.setIsbn(isbn)`; điều kiện "nội dung đổi" thêm ISBN / NXB / năm.
- `catalog/ListingService.java`: điều kiện tìm theo ISBN thêm một vế so khớp ISBN-13.
- `auction/AuctionDtos.java`: cọc `@DecimalMin("0")` thành `@DecimalMin("1000")`.
- `auction/AuctionViews.java`: `increment(price)` thành `increment(lot, price)`; hai chỗ gọi trong `AuctionViews` và hai chỗ trong `BidService` đổi theo.
- `auction/AuctionService.java`: hai dòng tính hạn mức đọc hệ số từ phiên thay vì cấu hình.
- `auction/AuctionSettlement.java`: dòng tính phí người mua đọc % từ phiên; mời mua lần hai dùng giá công bằng thay cho `second.getAmount()`.
- `system/SystemConfigService.java`: thân `bidIncrement(price)` chuyển sang hàm tĩnh `bidIncrement(tiers, price)` (hành vi cũ giữ nguyên).
- `config/AppProperties.java`: record `Auction` thêm `demoEnabled`.
- `auction/LotStatus.java`, `consignment/ConsignmentStatus.java`: các dòng bước chuyển được mở rộng (thêm `LOST`, `PAID → RETURNED`, `RECEIVED → WITHDRAWN`); `consignment/WarehouseItem.java` thêm `LOST`.
- `consignment/ConsignmentService.returnToSeller`: dòng tính phí lưu kho bỏ qua khi sách được miễn phí.
- Test: `AuctionMoneyTest` sửa 4 cụm khẳng định chia cọc 50/50 sang 100% về sàn; `InputGuardsTest.bookIsbnMustBeTenOrThirteenCharactersWhenGiven` **bị thay** bằng `bookIsbnIsCheckedAndStoredAsIsbn13` (luật cũ không còn đúng).

#### Rủi ro
- Đổi hành vi tiền: người bán không còn nhận 50% cọc bị thu; thay vào đó được bù chênh khi bán lại thấp hơn. Ví sàn không đủ thì không duyệt được bồi thường kho, và chưa có cách nạp vốn cho ví sàn.
- Profile mặc định vẫn là `dev` (BE-32): deploy quên đặt profile thì nút mở phiên ngay và hai mốc lịch bằng 0 cũng có hiệu lực.
- Bản sửa tìm kiếm không dấu của nhóm (đang là `V9__unaccent_search.sql`, chưa push) phải đổi số thành **V14**.

#### Chưa kiểm
Giao diện Flutter (chưa có màn sự cố kho, chưa hiện `isbnWarning`, chưa có nhãn cho mã lỗi mới), chưa chạy `/sync-api`, chưa thử các luật mới trên app thật.

### M. Việc trước buổi demo (2026-11-06)

Chủ repo yêu cầu làm nhóm việc trước demo: vá hai lỗ nhỏ của sự cố kho, sửa câu chữ luật cũ trong app, chạy test backend (không chạy test frontend), chạy thử luồng demo, commit.

| # | Việc | File | Ghi chú |
|---|---|---|---|
| 87 | Sự cố kho: sách đã trượt kiểm định mà bị mất thì Admin phải chọn mức 0–100% (`SELLER_PERCENT_REQUIRED`), không tự trả theo giá người bán tự khai; lô đã chuyển bán thường mà sách bị mất thì tin chờ duyệt chuyển `REJECTED` kèm lý do, tồn kho 0 | `consignment/WarehouseIncidentService.approve`; 2 test mới trong `BusinessRulesBatchTest` | |
| 88 | Câu `offersHint` (vi, en) còn ghi "mời mua với giá đã trả" → giá công bằng; `flutter gen-l10n` | `apps/frontend/lib/app/l10n/arb/app_vi.arb`, `app_en.arb` | Chưa chạy `dart analyze` / `flutter test` theo yêu cầu chủ repo |
| 89 | Chạy thử luồng đấu giá của `TEST_PLAN_TOAN_DIEN.md phần C` qua API trên DB mới (profile `dev`, dữ liệu mẫu): ký gửi ISBN có gạch → lưu ISBN-13; kiểm định giá 0 bị chặn; tạo phiên cọc 0 bị chặn; công bố phiên mở sau 5 phút được; buyer1, buyer2 đăng ký được, staff / admin bị `STAFF_CANNOT_BID`; mở phiên ngay; trả giá 1.000.000 → 1.100.000 đúng bước giá; tự đẩy giá mình bị `ALREADY_LEADING` | script tạm trong `C:
btmp` (đã xoá) | Dữ liệu mẫu không có lô sẵn sàng: muốn demo đấu giá phải ký gửi và kiểm định trước (như `DEMO.md` mục 3.6) |

**Kết quả:** test backend **160/160 đạt** (158 + 2 mới, trừ `SeedDataTest`).

#### Dòng code cũ bị thay trong đợt này
- `WarehouseIncidentService.approve`: dòng `int percent = lost ? 100 : requirePercent(req);` thêm điều kiện sách chưa trượt kiểm định; câu báo lỗi `SELLER_PERCENT_REQUIRED` thêm "hoặc sách đã trượt kiểm định".
- `app_vi.arb`, `app_en.arb`: đổi nội dung chuỗi `offersHint` (giữ nguyên key).

### N. Đánh giá BA / tester, sửa luật nghiệp vụ, test đầu cuối (2026-11-06, chiều)

Nhánh `improve_bussinessrule` (tạo local từ `origin/improve_bussinessrule`, commit gốc `f365cfd`). Chủ repo yêu cầu chỉ làm backend, không chạy frontend. **Trạng thái git: chưa commit, chưa push.**

#### N.1 Môi trường

| # | Việc | Ghi chú |
|---|---|---|
| 90 | Cài PostgreSQL 16 bằng Homebrew (chủ repo đồng ý), chạy bằng `pg_ctl` (không tự bật khi đăng nhập máy), tạo user / DB bằng `scripts/create-database.sql` | `localhost:5432`, `rebook` / `rebook`, DB `rebook_dev` |
| 91 | JDK: máy không có `java` trong PATH, dùng `JAVA_HOME=/opt/homebrew/opt/openjdk@21` | Không đặt thì `./mvnw` treo, không báo lỗi |
| 92 | Seed dev báo `gen_salt does not exist`: test chạy trước đã cài `pgcrypto` vào schema test. Chuyển về `public` (`ALTER EXTENSION pgcrypto SET SCHEMA public`) | Test vẫn đạt sau khi chuyển. Cách xử lý ghi ở `TEST_PLAN_TOAN_DIEN.md phần A` mục 1.1 |
| 93 | Hook Claude của frontend (`claude_hook.dart stop`) báo 360 lỗi analyze ở mỗi lượt vì worktree chưa chạy `build_runner`. Không tự tắt được (bị chặn sửa cấu hình Claude) | Chủ repo tự tạo `.claude/settings.local.json` với `{"disableAllHooks": true}` nếu muốn tắt |

#### N.2 Đánh giá và tài liệu mới

| # | Việc | File |
|---|---|---|
| 94 | Đánh giá luồng Tiền, Mua bán, Đấu giá với vai tester / BA: 5 lỗi mới (2 P0, 3 P1) | (trả lời trong chat; đưa vào `DANH_GIA_BA_TESTER.md phần B` cập nhật 10) |
| 95 | Đánh giá toàn hệ thống: 37 mục xếp P0 → P3, 8 mục mới, bộ kịch bản test | `docs/ra-soat-nghiep-vu/DANH_GIA_BA_TESTER.md phần A` (mới) |
| 96 | Kế hoạch test toàn diện: 3 tầng, 7 bất biến, ma trận ca (happy, biên, sai, gian lận, đồng thời, hell) | `docs/ra-soat-nghiep-vu/TEST_PLAN_TOAN_DIEN.md phần A phần A` (mới); `TEST_PLAN_TOAN_DIEN.md phần B` thêm mục F trỏ tới |

#### N.3 Lỗi sửa (theo thứ tự làm)

| # | ID | Lỗi | Sửa | File chính |
|---|---|---|---|---|
| 97 | BE-43 (P0) | Giá tối đa ≥ giá sàn mà lô vẫn "Không đạt giá" | Hết người tranh thì trả hộ người dẫn lên đúng giá sàn | `auction/BidService.liftLeaderToReserve` |
| 98 | BE-44 (P0) | Đơn trả trước tự coi là đã giao, người mua không nhận được sách mà không đòi được tiền | Lý do trả hàng `NOT_RECEIVED`: không cần ảnh, đồng ý là hoàn tiền ngay; chỉ đơn thường | `order/OrderService.requestReturn`, `approveReturn`, `ReturnRequest`, `OrderDtos`; migration `V14` |
| 99 | BE-45 (P1) | Thắng đấu giá, trả tiền rồi từ chối nhận thì không bị gì | Staff báo giao thất bại kèm `fault=BUYER`: phạt như bỏ thanh toán + thu phí giao chiều đi | `auction/AuctionSettlement.deliveryFailed`, `OrderManagementController` |
| 100 | BE-46 (P1) | Trả ZaloPay sát hạn, cổng báo chậm vẫn bị phạt | Hỏi lại ZaloPay trước khi phạt, ân hạn 15 phút | `auction/AuctionSettlement.awaitingGateway`, `wallet/PaymentService.refresh` |
| 101 | BE-47 (P1) | Thu nợ song song trừ ví hai lần | Khoá ví trước rồi mới đọc nợ | `wallet/DebtService.collect` |
| 102 | Mục 10 | Khoá tài khoản giữa lúc đấu giá: người bị khoá vẫn bị phạt | Khoá thì huỷ hoá đơn đấu giá chưa trả không phạt, hoàn cọc, mời người kế tiếp; huỷ giá tối đa; rút lô của người bán khỏi phiên chưa chạy; người bị khoá không được mời mua lần hai | `admin/AccountLockService`, `auction/AuctionSettlement.cancelForLockedBuyer`, `withdrawSellerLots` |
| 103 | Mục 11 | Ký gửi treo mãi ở bước chờ người bán quyết | Quá `consignment.seller_decision_days` (7) thì coi như rút | `consignment/ConsignmentService.expireSellerDecision`, `ConsignmentJobs` |
| 104 | Mục 12 | Sách không ai nhận lại nằm kho mãi, không phát sinh phí | Nhắc trước 7 ngày; quá `warehouse.abandon_days` (60) thì thu phí kho (thiếu thì nợ) và thanh lý; tin chờ duyệt của cuốn đó bị từ chối | `ConsignmentService.warnAbandon`, `abandon`, `checkOut` |
| 105 | Mục 13 | Hoá đơn đấu giá đã trả mà kho quên xử lý | Báo Staff / Admin một lần khi quá hạn (cùng hạn với shop) | `order/OrderService.alertWarehouseSla`, `OrderJobs` |
| 106 | Mục 25 | Lịch hẹn ký gửi nhận giờ trong quá khứ | `APPOINTMENT_IN_PAST` | `ConsignmentService.bookAppointment` |
| 107 | Mục 27 | Cấu hình đặt 0 phá luật | Mức tối thiểu cho 18 khoá số nguyên (thời hạn, số lượt, hệ số) | `system/SystemConfigService.MIN_VALUES` |
| 108 | Mục 7 | Giá đổi đúng lúc người mua bấm đặt | `expectedTotal` tuỳ chọn, lệch thì `PRICE_CHANGED` | `order/CheckoutService` |
| 109 | Mục 8 | Giao thất bại không phân biệt lỗi ai | `fault` `BUYER` / `CARRIER` / `SHOP`: lỗi người mua thì hoàn trừ phí giao (phí về shop); lỗi shop thì tính lỗi shop; chặn COD chỉ đếm lỗi người mua | `order/OrderSettlement`, `OrderService.carrierConfirm`, `OrderRepository.countCodFailuresSince` |
| 110 | Mục 15 | Lô giá trị lớn chỉ cần cọc chung của phiên | Lô ước tính ≥ 10 triệu cần tổng cọc ≥ cọc phiên + 10% mức thấp ước tính (`LOT_DEPOSIT_REQUIRED`) | `auction/BidService.requireLotDeposit` |
| 111 | Mục 17 | Ai cũng khoá được đăng nhập của người khác (BE-42) | Đếm sai theo email + IP (10), IP (30), email trên mọi IP (100) | `auth/AuthService.login`, `AuthController` |
| 112 | Mục 23 | Cấm đấu giá luôn 90 ngày | Luỹ tiến 90 ngày → 365 ngày → vĩnh viễn; bỏ nhiều lô cùng phiên tính một lần | `AuctionSettlement.applyStrike`, `user/User` |
| 113 | BE-48 | Backend tắt lâu hơn thời gian còn lại của lô: bật lại thì lô chốt ngay | Nhịp đầu tiên sau khi khởi động kéo dài lô đang mở cho đủ thời gian soft close | `auction/AuctionRunner.recoverAfterRestart`, `AuctionEngine` |

Migration mới: `V14__return_reason_not_received.sql`, `V15__consignment_deadlines_and_warehouse_sla.sql`, `V16__delivery_fault_high_value_lots_progressive_ban.sql`. `apps/backend/openapi.yaml` **sửa tay** (chưa xuất lại từ `/v3/api-docs.yaml`): `ReturnReason.NOT_RECEIVED`, `images` tuỳ chọn, `DeliveryFailedRequest` + `DeliveryFault`, `CheckoutRequest.expectedTotal`.

#### N.4 Test

| # | Việc | File | Kết quả |
|---|---|---|---|
| 114 | Test tích hợp mới: `NotReceivedReturnTest`, `BaReviewGapsTest`, `BaReviewBatch2Test`, các ca mới trong `MultiBidderTest` (giá sàn, khởi động lại), `AuctionMoneyTest` (ZaloPay chậm, từ chối nhận), `ConcurrencyTest` (thu nợ song song) | `apps/backend/src/test/java/com/rebook/` | `./mvnw test` **185/185 đạt** |
| 115 | Bộ dữ liệu mẫu cho test: 14 nhân vật (ví rỗng, hay bom COD, còn nợ, bị cấm, bị khoá...), tin bán, ký gửi ở từng bước, 3 phiên đấu giá. Nạp lại được nhiều lần (dọn cả dữ liệu script tạo qua API) | `apps/backend/testdata/e2e_personas.sql` (mới) | |
| 116 | Script test đầu cuối qua HTTP thật, 133 ca: mua bán (ví, ZaloPay, COD đi hết luồng, huỷ, trả hàng, không nhận được hàng, giao thất bại), ví (khoá tiền nạp, rút có biên lai, trả nợ), ký gửi từ đầu qua API đến khi công bố phiên, đấu giá đi hết luồng đến khi người bán nhận tiền, bỏ thanh toán và mời mua lần hai, phiên thiếu người, bảo toàn tổng tiền | `apps/backend/testdata/e2e_flows.sh` (mới) | **133/133 đạt** |
| 117 | Script khởi động lại backend giữa phiên (hai phần, tắt / bật bằng tay) | `apps/backend/testdata/e2e_restart.sh` (mới) | **7/7 đạt**, tắt ~25 giây và tắt 75 giây |

Các lần chạy script hỏng đều do chính script: bash 3.2 của macOS (mảng rỗng với `set -u`, tách nhầm JSON có dấu phẩy); mong `200` cho API trả `201`; sai thứ tự ca; cho trả giá dưới giá sàn rồi mong có hoá đơn. Không có lỗi hệ thống nào lộ ra khi chạy; lỗi BE-48 tìm được khi đọc code.

#### Dòng code cũ bị thay trong đợt này
- `auction/AuctionSettlement.handleOverdue`: thân hàm tách sang `cancelUnpaid(o, penalize, reason)`; `forfeitAndBan` thêm tham số `why`; dòng đặt `auctionBannedUntil = now + ban_days` thay bằng `applyStrike(user)`; `eligibleRunnerUp` thêm điều kiện tài khoản `ACTIVE`; câu thông báo phạt đổi theo lý do.
- `auction/AuctionSettlement.onOrderStatusChanged` (giao thất bại) giữ nguyên; `deliveryFailed` là hàm mới.
- `order/OrderDtos.ReturnCreateRequest.images`: bỏ `@NotNull @Size(min = 1)`, kiểm ở service (lý do `NOT_RECEIVED` không cần ảnh).
- `order/OrderManagementController`: body `staff/.../delivery-failed` và `staff/.../carrier-failed` đổi từ `CancelRequest` sang `DeliveryFailedRequest` (vẫn có `reason`, thêm `fault`).
- `order/OrderService.markDeliveryFailed`, `carrierConfirm`: thêm tham số `fault`.
- `order/OrderSettlement`: nhánh giao thất bại thêm trường hợp lỗi người mua trước nhánh hoàn đủ.
- `order/OrderRepository.countCodFailuresSince`: thêm điều kiện lỗi người mua (hoặc chưa ghi lỗi).
- `consignment/ConsignmentService.returnToSeller`: phần tính phí kho tách sang `checkOut` (hành vi giữ nguyên).
- `consignment/ConsignmentJobs`: vòng lặp có sẵn đổi sang hàm `each(...)` dùng chung.
- `wallet/DebtService.collect`: đảo thứ tự khoá ví và đọc nợ; bỏ `return` sớm khi không có nợ.
- `system/SystemConfigService.validate`: dòng kiểm số nguyên `≥ 0` (riêng hệ số hạn mức `≥ 1`) thay bằng bảng `MIN_VALUES`.
- `auth/AuthService.login(req)` thành `login(req, clientIp)`; một khoá đếm thành ba.
- Test: `MultiBidderTest` sửa kỳ vọng 4 ca theo luật giá sàn mới; `AuctionMoneyTest` đổi `buyerFault` thành `fault`.

#### Rủi ro
- Đổi hành vi tiền: lô có giá tối đa ≥ giá sàn giờ bán ở giá sàn (người xem đoán được giá sàn); giao thất bại do người mua thì người mua mất phí giao; lô cao giá cần cọc thêm; bỏ thanh toán lần 3 bị cấm vĩnh viễn.
- Ngưỡng lô cao giá đọc cấu hình hiện tại, chưa chốt vào phiên lúc công bố.
- Ân hạn ZaloPay 15 phút và báo trước thanh lý 7 ngày là hằng số trong code.
- Khoá đăng nhập theo IP: chạy sau proxy phải bật `server.forward-headers-strategy`, không thì mọi người chung một IP.
- Migration tìm kiếm không dấu chưa push của nhóm phải đổi số thành **V17**.
- `openapi.yaml` của backend sửa tay; nên xuất lại từ `/v3/api-docs.yaml` rồi đối chiếu.

#### Còn lại / cần cải thiện (xếp theo mức nặng, chi tiết ở `DANH_GIA_BA_TESTER.md phần A`)
1. **Trước khi nhận tiền thật (P0):** profile mặc định đang là `dev` (cần chủ repo quyết vì ảnh hưởng máy dev); thông báo ngoài app (push / email) trước khi phạt theo hạn; OTP SMS thật và CCCD; giữ tiền bán của shop mới N ngày và xử lý chargeback; kiểm mã vận đơn với hãng thật; tách quyền xem ảnh biên lai.
2. **Cần chủ sàn quyết:** shop chịu ship chiều về khi sai mô tả (ví sàn ứng trước hay trừ thẳng shop); ngày nghỉ và công suất kho; điều khoản thanh lý sách trong hợp đồng ký gửi; các con số tự chọn (60 ngày thanh lý, 15 phút ân hạn, 10 triệu lô cao giá).
3. **Frontend cần làm theo:** lý do "Không nhận được hàng", ô "ai gây lỗi" khi báo giao thất bại, gửi `expectedTotal`, hiện `LOT_DEPOSIT_REQUIRED` và `PRICE_CHANGED`; chạy `/sync-api`.
4. **Cần frontend làm cùng:** hoàn một phần khi khiếu nại, xác nhận trả giá lớn, bán sau phiên, hai Admin duyệt rút lớn, OTP khi thêm tài khoản ngân hàng.
5. **Thuần backend còn lại:** nhắc người bán trước hạn quyết định ký gửi; ghi IP / thiết bị chống đẩy giá; tách vai trò kiểm định / định giá; phiếu kiểm định có cấu trúc; sách lậu và báo cáo tin; chốt ngưỡng lô cao giá vào phiên.
6. **Test còn thiếu:** tiêm lỗi vào job (một bản ghi lỗi không chặn bản ghi khác); test thủ công trên app (danh sách ở `TEST_PLAN_TOAN_DIEN.md phần A` mục 5); ZaloPay thật, tải lớn, nhiều instance.
