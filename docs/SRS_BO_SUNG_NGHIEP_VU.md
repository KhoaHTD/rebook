# ReBook: bổ sung nghiệp vụ cho SRS

Ngày 2026-11-06. Tài liệu này **bổ sung** cho SRS (`docs/Đặc-tả-ứng-dụng-mua-bán-đấu-giá-sách-cũ.docx`). SRS không nói thì theo tài liệu này; SRS nói khác thì theo tài liệu này (mục đó ghi rõ "thay SRS").
Con số nào cũng là giá trị mặc định, đổi được trong `system_configs`, trừ khi ghi "cố định".

**Nhãn trạng thái của từng luật**

| Nhãn | Nghĩa |
|---|---|
| **[Chốt]** | Chủ sàn quyết ngày 2026-11-06 |
| **[Đã có]** | Đã quyết trước đó và đã có trong code (xem `AUDIT_BACKEND.md`, `AUCTION_MONEY_FLOW.md`, `SESSION_LOG_2026-11-05.md`) |
| **[Đề xuất]** | BA tự đặt theo thông lệ, chờ chủ sàn duyệt; chưa có trong code |

Cột "Code" của các bảng: ✅ đã làm · ⏳ chưa làm.

---

## 1. Tài khoản và định danh

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-1.1 | Mọi người muốn đăng ký phiên đấu giá phải xác thực **SĐT bằng OTP gửi thật** (SMS). Một SĐT chỉ gắn một tài khoản; SĐT chỉ được tính là "đã dùng" sau khi xác thực, nên không ai chiếm trước được số của người khác | [Chốt] | ⏳ (OTP mới ghi log) |
| BR-1.2 | Phải **định danh CCCD + ảnh chân dung** trước khi: (a) gửi yêu cầu ký gửi; (b) rút tiền lần đầu; (c) đăng ký phiên có ít nhất một lô với giá ước tính cao ≥ `kyc.auction_threshold` = 5.000.000đ | [Chốt] | ⏳ |
| BR-1.3 | Một CCCD chỉ gắn một tài khoản. Lệnh cấm đấu giá, khoá tài khoản và nợ phạt áp theo **người** (CCCD và SĐT), không chỉ theo tài khoản: tạo tài khoản mới bằng cùng CCCD / SĐT thì bị chặn | [Chốt] | ⏳ |
| BR-1.4 | Ảnh CCCD lưu riêng, không công khai, chỉ Admin được xem; mỗi lần xem ghi nhật ký. Trạng thái định danh: `NONE → PENDING → VERIFIED / REJECTED` (Admin duyệt, từ chối phải có lý do) | [Đề xuất] | ⏳ |
| BR-1.5 | Tên chủ tài khoản ngân hàng nhận tiền phải khớp họ tên trên CCCD (so sánh IN HOA, không dấu). Áp từ khi có BR-1.2 | [Đề xuất] | ⏳ (nhóm đã bỏ luật khớp tên vì chưa có CCCD) |
| BR-1.6 | Xoá tài khoản: chỉ khi không còn đơn dở, nợ, số dư ví, lô trong kho hay đăng ký phiên. Khi xoá, dữ liệu cá nhân bị ẩn danh; sổ cái ví, đơn hàng và nhật ký vẫn giữ để đối soát | [Đề xuất] | ⏳ |
| BR-1.7 | Khoá tài khoản thì: ẩn tin, huỷ đơn chưa giao, hoàn cọc ở các phiên chưa chốt | [Đã có] | ✅ |

## 2. Đăng bán giá cố định, ISBN, nội dung

### 2.1 ISBN và thông tin sách

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-2.1 | ISBN **không bắt buộc** (sách trước 1970 và nhiều sách cũ không có ISBN) | [Chốt] | ✅ |
| BR-2.2 | Nếu có nhập: bỏ dấu gạch và khoảng trắng; chỉ nhận 10 ký tự (ký tự cuối được là `X`) hoặc 13 chữ số; **kiểm số kiểm tra** (ISBN-10: tổng có trọng số chia hết cho 11; ISBN-13: trọng số 1-3 chia hết cho 10, đầu số 978 hoặc 979). Sai thì báo `INVALID_ISBN` | [Chốt] | ✅ |
| BR-2.3 | ISBN-10 được đổi sang ISBN-13 (thêm 978 rồi tính lại số kiểm tra) để **lưu và tìm kiếm**; trang chi tiết vẫn hiện số người bán đã nhập. Tìm kiếm theo ISBN chuẩn hoá cả từ khoá (gõ có gạch hay ISBN-10 đều ra) | [Chốt] | ✅ (lưu và hiển thị ISBN-13, không giữ bản gốc người bán nhập) |
| BR-2.4 | Năm xuất bản trước 1970 mà có ISBN thì gắn **cờ cảnh báo** cho người duyệt tin / Staff kiểm định (không chặn, vì có sách in lại) | [Chốt] | ✅ (trường `isbnWarning` trong thông tin sách; frontend chưa hiển thị) |
| BR-2.5 | Sửa một trong các trường **ISBN, NXB, năm xuất bản, lần in, tên, tác giả, tình trạng, mô tả, ảnh** thì tin phải duyệt lại (shop uy tín vẫn được tự duyệt theo luật hiện có) | [Chốt] | ✅ (chưa có trường "lần in", xem BR-2.6) |
| BR-2.6 | Thêm trường tuỳ chọn **Lần in / ấn bản** (ví dụ "In lần 1, 1965"), vì "sai ấn bản" là một lý do trả hàng hợp lệ | [Đề xuất] | ⏳ |
| BR-2.7 | Gợi ý tự điền tên, tác giả, NXB, năm từ ISBN (Open Library / Google Books). Chỉ là gợi ý, người bán vẫn sửa được | [Đề xuất] | ⏳ |

### 2.2 Chính sách nội dung

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-2.8 | **Cấm** đăng: sách in lậu, sách photocopy hoặc in lại không phép, sách bị cấm lưu hành, và tin không phải sách | [Chốt] | ⏳ |
| BR-2.9 | Người dùng đã đăng nhập được **báo cáo tin** (lý do: in lậu / photocopy / sách cấm / lừa đảo / khác, kèm ảnh tuỳ chọn), mỗi người mỗi tin một lần. Admin xử lý: gỡ tin (ghi lý do) hoặc bỏ qua; ghi nhật ký | [Chốt] | ⏳ |
| BR-2.10 | Shop bị gỡ tin vì vi phạm BR-2.8 lần thứ 3 trong 12 tháng thì **khoá shop**. Bị gỡ lần 1 hoặc 2 thì mất cờ shop uy tín | [Chốt] (3 lần) / [Đề xuất] (mất uy tín) | ⏳ |
| BR-2.11 | Người mua nhận phải sách in lậu / photocopy được trả hàng với lý do mới `COUNTERFEIT`, theo luồng "lỗi của shop" (BR-3.4) | [Chốt] | ⏳ (cần migration cho `CHECK` lý do trả hàng) |
| BR-2.12 | Giá bán ≥ 1.000đ và ≤ 500.000.000đ; tồn kho ≤ 999 | [Đề xuất] | ⏳ (BE-33) |
| BR-2.13 | Checkout gửi kèm giá người mua đã thấy; giá đổi thì trả `PRICE_CHANGED` và hỏi lại | [Đề xuất] | ⏳ (BE-12) |

## 3. Đơn hàng, giao hàng, trả hàng, khiếu nại

### 3.1 Luật đã có (tóm tắt để đủ bộ)

| ID | Luật | Nhãn |
|---|---|---|
| BR-3.0a | Thanh toán online 15 phút; shop xác nhận 24 giờ; giao cho vận chuyển trong 3 ngày; shop trả lời yêu cầu huỷ trong 24 giờ (im lặng là đồng ý) | [Đã có] ✅ |
| BR-3.0b | Người mua chưa bấm "Đã nhận" thì sau 7 ngày kể từ lúc giao shipper, hệ thống tự coi là đã giao; sau đó còn 3 ngày khiếu nại | [Đã có] ✅ |
| BR-3.0c | Trả hàng: shop đồng ý → người mua gửi trả (7 ngày) → shop xác nhận đã nhận (7 ngày) → hoàn tiền. Tồn kho không tự cộng lại | [Đã có] ✅ |
| BR-3.0d | COD do hãng vận chuyển thu hộ, sàn đối soát rồi mới trả shop. Hạn mức 3.000.000đ/đơn (500.000đ với người chưa có đơn hoàn tất); chặn COD khi có ≥ 2 đơn giao thất bại trong 90 ngày | [Đã có] ✅ |
| BR-3.0e | Shop có tỷ lệ đơn lỗi ≥ 10% (tối thiểu 5 đơn trong 90 ngày) thì mất cờ uy tín | [Đã có] ✅ |

### 3.2 Phí ship khi trả hàng và giao thất bại [Chốt]

| ID | Tình huống | Ai chịu | Code |
|---|---|---|---|
| BR-3.4 | Trả hàng vì sai mô tả (sai tình trạng, thiếu trang, sai ấn bản, sách lậu) | **Shop** chịu ship cả hai chiều: người mua được hoàn tiền sách + ship chiều đi; ship chiều về (theo bảng phí) trừ vào tiền bán của shop. Đơn đấu giá: **sàn** chịu | ⏳ |
| BR-3.5 | Giao thất bại do người mua (từ chối nhận, sai địa chỉ, không liên lạc được) | Người mua: tiền hoàn **trừ phí ship chiều đi**. Đơn COD không trừ được tiền thì chỉ tính một lần giao thất bại (luật chặn COD ở BR-3.0d) | ⏳ |
| BR-3.6 | Giao thất bại do hãng vận chuyển hoặc shop | Hoàn đủ cho người mua; tính lỗi cho shop nếu do shop | ⏳ |
| BR-3.7 | Ai gây lỗi giao thất bại do Staff ghi lúc đánh dấu thất bại (`BUYER` / `CARRIER` / `SHOP`); đến khi có webhook của hãng vận chuyển thì lấy từ hãng | [Đề xuất] | ⏳ |

### 3.3 Khiếu nại và hoàn một phần [Chốt]

| ID | Luật | Code |
|---|---|---|
| BR-3.8 | Ngoài "trả hàng hoàn tiền", shop được đề nghị **hoàn một phần 10–50% tiền sách** để người mua giữ sách. Người mua đồng ý thì khiếu nại đóng, phần còn lại về shop khi đơn hoàn tất; từ chối thì luồng trả hàng chạy tiếp | ⏳ |
| BR-3.9 | Khi phân xử, Admin chọn một trong ba: hoàn toàn bộ (kèm trả hàng), hoàn một phần (10–50%, người mua giữ sách), hoặc từ chối | ⏳ |
| BR-3.10 | Shop nộp được **ảnh phản biện** (tối đa 5 ảnh) cùng ghi chú | ⏳ |
| BR-3.11 | Admin phân xử trong **3 ngày** kể từ khi khiếu nại được chuyển lên. Quá hạn thì nhắc Admin và ghi cảnh báo; hệ thống **không tự quyết tiền** | ⏳ |

### 3.4 Đánh giá [Đề xuất]

| ID | Luật | Code |
|---|---|---|
| BR-3.12 | Đơn hoàn tiền toàn bộ thì không được đánh giá. Người mua sửa đánh giá được một lần trong 7 ngày | ⏳ |
| BR-3.13 | Shop phản hồi mỗi đánh giá một lần. Người dùng báo cáo được đánh giá vi phạm; Admin ẩn đánh giá (điểm trung bình tính lại) | ⏳ (BE-16) |

## 4. Ký gửi và kiểm định

### 4.1 Phiếu kiểm định có cấu trúc [Chốt]

| ID | Luật | Code |
|---|---|---|
| BR-4.1 | **Checklist cố định**, mục nào cũng phải chọn `Đạt / Lỗi nhẹ / Lỗi nặng`: đủ trang · đúng ấn bản / lần in · bìa · gáy · ruột · ẩm mốc / mối mọt · ghi chú / gạch chân · trang bị rách hoặc thiếu | ⏳ (hiện là JSON tự do) |
| BR-4.2 | **Bộ ảnh chuẩn**, bắt buộc khi Đạt: bìa trước, bìa sau, gáy, trang bản quyền (hoặc trang tên sách nếu không có), và ảnh từng chỗ hư hại. Tối thiểu 4 ảnh, cộng một ảnh cho mỗi mục "Lỗi" | ⏳ (hiện không bắt buộc ảnh) |
| BR-4.3 | **Trường chữ ký / bút tích**: `NONE` · `PRESENT_UNVERIFIED` (có, chưa xác thực) · `PRESENT_VERIFIED` (đã xác thực, phải ghi căn cứ: giấy chứng nhận, nguồn gốc, chuyên gia). Catalogue hiển thị đúng chữ; mô tả của người bán không được ghi "có chữ ký tác giả" nếu Staff chưa chọn `VERIFIED` | ⏳ |
| BR-4.4 | Luật suy ra kết quả: "Lỗi nặng" ở **đủ trang** hoặc **đúng ấn bản** → không được Đạt. Sách in lậu / photocopy → Không đạt, kèm cờ vi phạm (tính như BR-2.10) | [Đề xuất] ⏳ |
| BR-4.5 | **Xác minh thông tin sách**: với tên, tác giả, NXB, năm, lần in, ISBN, Staff đánh dấu `Khớp / Lệch`; lệch thì ghi giá trị đúng. Giá trị đã sửa gửi cho người bán cùng đề xuất giá; người bán chấp nhận đề xuất là chấp nhận thông tin đã sửa. Catalogue hiện thông tin đã xác minh với nhãn "Đã xác minh bởi ReBook" | [Đề xuất]: chủ sàn yêu cầu "đảm bảo sách chuẩn, hạn chế rủi ro" nhưng chưa chọn mục "Staff sửa thông tin"; đây là cách làm cả hai bên cùng đồng ý | ⏳ |
| BR-4.6 | Giá trong phiếu: ước tính thấp > 0, ước tính thấp ≤ ước tính cao, 0 < giá khởi điểm ≤ giá sàn ≤ ước tính thấp. Sai thì báo 400 **ngay lúc lập phiếu** | [Đề xuất] | ✅ (`INVALID_PRICE`) |
| BR-4.7 | Đã có: sơ duyệt 48 giờ, từ chối khi giá mong muốn < 300.000đ, hẹn lịch 7 ngày, 14 ngày nhận lại sách không đạt, tối đa 2 phiên, lô bị trả hàng phải kiểm định lại | [Đã có] | ✅ |

### 4.2 Bồi thường khi kho làm mất / hỏng sách [Chốt: theo giai đoạn]

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

## 5. Phiên đấu giá: lịch, cọc, hạn mức, trả giá

### 5.1 Lịch phiên [Chốt, tính cả nhu cầu demo]

| ID | Luật | Code |
|---|---|---|
| BR-5.1 | Catalogue công bố ít nhất `auction.min_publish_lead_hours` = **72 giờ** trước giờ mở | ✅ |
| BR-5.2 | Hạn đăng ký ít nhất `auction.min_registration_close_hours` = **24 giờ** trước giờ mở (SRS 6.4) | ✅ |
| BR-5.3 | Lúc công bố, **chốt vào phiên**: % phí người mua, bảng bước giá, hệ số hạn mức. Đổi cấu hình sau đó chỉ áp cho phiên công bố sau (hoa hồng người bán đã được chốt theo lô) | ✅ |
| BR-5.4 | Nút "Mở phiên ngay" và hai khoá ở BR-5.1, BR-5.2 bằng 0 **chỉ có ở môi trường demo / dev** (cờ `app.auction.demo-enabled`). Môi trường thật không có nút này | ✅ (`DEMO_ONLY` ngoài demo; seed dev `V13_1` đặt hai khoá bằng 0) |

**Cho buổi demo:** profile `dev` có seed `V13_1` đặt `min_publish_lead_hours = 0`, `min_registration_close_hours = 0` và bật `app.auction.demo-enabled`. Vẫn tạo phiên, công bố và mở ngay được như trước; luật 72 giờ / 24 giờ chỉ chạy ở môi trường thật. Lưu ý: profile mặc định vẫn là `dev` (BE-32), deploy mà quên đặt profile thì nút demo cũng bật.

### 5.2 Tiền cọc và hạn mức [Chốt: phiên + lô cao giá]

| ID | Luật | Code |
|---|---|---|
| BR-5.0 | Tài khoản nhân viên sàn (Staff / Admin) **không được** đăng ký phiên, trả giá hay đặt giá tối đa (`STAFF_CANNOT_BID`), vì Staff kiểm định lô và biết giá sàn | [Chốt] | ✅ |
| BR-5.5 | Cọc phiên giữ như SRS: một mức cho cả phiên, hạn mức = tổng cọc × 10. Cọc phiên phải > 0 | ✅ (cọc tối thiểu 1.000đ) |
| BR-5.6 | **Lô cao giá** (ước tính cao ≥ `auction.high_value_lot_threshold` = 10.000.000đ): chỉ được trả giá hoặc đặt giá tối đa khi **tổng cọc của người đó trong phiên ≥ cọc phiên + 10% mức thấp ước tính của lô** (`auction.high_value_deposit_percent` = 10). Thiếu thì báo `LOT_DEPOSIT_REQUIRED` kèm số tiền cần cọc thêm; người dùng cọc thêm bằng chức năng có sẵn (hạn mức tăng theo) | ⏳ |
| BR-5.7 | Catalogue đánh dấu "Lô cao giá, cần cọc X đ" để người mua biết trước khi vào phòng | ⏳ |
| BR-5.8 | Đăng ký phiên có lô cao giá ≥ 5.000.000đ thì cần CCCD (BR-1.2) | ⏳ |
| BR-5.9 | Đã có: huỷ đăng ký trước hạn đăng ký thì hoàn cọc; không thắng lô nào thì hoàn cọc ngay khi phiên đóng; còn nợ thì không đăng ký / trả giá / rút tiền được | [Đã có] ✅ |

### 5.3 Trả giá [Đề xuất]

| ID | Luật | Code |
|---|---|---|
| BR-5.10 | Lượt trả giá vượt mức tối thiểu hơn 10 bước giá phải gửi kèm `confirmed = true` (giao diện hỏi lại "Bạn chắc chắn trả X đ?"). Không có thì trả `CONFIRM_LARGE_BID` | ⏳ |
| BR-5.11 | **Không rút lượt trả giá** sau khi server đã nhận. Chỉ huỷ lô (Staff, khi có sự cố hệ thống) mới vô hiệu các lượt trả giá; huỷ lô phải có lý do và ghi nhật ký | ⏳ (lý do đã bắt buộc; chưa ghi nhật ký) |
| BR-5.12 | Phiên tạm dừng quá 60 phút thì Admin phải chọn: tiếp tục, hoặc kết thúc phiên (lô đang mở bị huỷ; các lô chưa chạy về chờ xếp phiên và không tính lượt) | ⏳ |
| BR-5.13 | Ghi IP và mã thiết bị cho mỗi lượt đăng ký và trả giá (chỉ Admin xem, giữ 12 tháng) | ⏳ (BE-25) |

## 6. Sau phiên

### 6.1 Bỏ thanh toán: tiền phạt về đâu [Chốt: về sàn hết, thay SRS 8.3]

| ID | Luật | Code |
|---|---|---|
| BR-6.1 | Cọc bị thu và tiền phạt (10% giá búa, nợ nếu thiếu) **vào ví sàn 100%**. Bỏ tỷ lệ chia 50% cho người bán | ✅ |
| BR-6.2 | **Bù cho người bán**: nếu lô sau đó bán được (qua mua lần hai, bán sau phiên hoặc phiên sau) với giá búa thấp hơn giá bị bỏ, sàn bù cho người bán **phần chênh sau hoa hồng**, tối đa bằng số tiền sàn đã thu thực tế từ người bỏ cho lô đó (cọc + phạt đã thu). Tiền bù trả lúc đơn mới hoàn tất. Lô không bán được hoặc người bán nhận lại sách thì không bù | ✅ (phạt thu được sau lúc hoàn tất thì không bù thêm) |
| BR-6.3 | Người thắng bỏ thanh toán mà dùng chung CCCD / SĐT / tài khoản ngân hàng / thiết bị với người ký gửi lô đó: khoá cả hai tài khoản chờ Admin điều tra; người ký gửi không được bù BR-6.2 | [Đề xuất] ⏳ |
| BR-6.4 | Cấm đấu giá **luỹ tiến**: lần 1 cấm 90 ngày; lần 2 trong 12 tháng cấm 365 ngày; lần 3 cấm vĩnh viễn (Admin vẫn gỡ được, có ghi nhật ký) | [Đề xuất] ⏳ (hiện luôn 90 ngày) |

### 6.2 Mời mua lần hai: giá công bằng [Chốt, thay SRS 6.6]

- BR-6.5 Giá mời = **giá mà người về nhì lẽ ra phải trả nếu không có người bỏ**:
  `giá mời = max(giá sàn, min(giá cao nhất của người về nhì, giá cao nhất của người thứ ba + 1 bước giá))`.
  Không có người thứ ba thì `giá mời = max(giá sàn, giá khởi điểm)`.
  "Giá cao nhất của mỗi người" là lượt trả giá cao nhất người đó đã có ở lô (tay hoặc tự động); chỉ xét người còn hợp lệ (không bị cấm, không nợ, không phải người ký gửi; luật chọn người hợp lệ đã có).
- BR-6.6 Ví dụ: A (người bỏ) 5.000.000, B 4.800.000, C 2.000.000, bước 100.000, giá sàn 1.500.000 → B được mời ở **2.100.000** (SRS cũ là 4.800.000). Kẻ đẩy giá không còn kiếm được gì từ người mua thật.
- BR-6.7 Giữ nguyên: hạn 24 giờ, không cọc, không phạt nếu từ chối; giá người về nhì dưới giá sàn thì không mời. [Đã có] ✅
- Code: ✅ (`AuctionSettlement.fairSecondChancePrice`).

### 6.3 Bán sau phiên khi chưa đạt giá sàn [Chốt]

| ID | Luật | Code |
|---|---|---|
| BR-6.8 | Lô đóng với kết quả "Không đạt giá" (`RESERVE_NOT_MET`): người bán có **24 giờ** (`auction.after_sale_seller_hours`) để đồng ý bán cho người trả cao nhất **ở đúng giá cuối** | ⏳ |
| BR-6.9 | Người bán đồng ý thì người mua nhận lời mời, có **24 giờ** (`auction.after_sale_buyer_hours`) để nhận hoặc từ chối. Không cọc, **không phạt** nếu từ chối. Phí người mua và hoa hồng như bán thường | ⏳ |
| BR-6.10 | Người trả cao nhất không còn hợp lệ (bị cấm, có nợ) thì không mời. Người bán im lặng hoặc người mua từ chối thì lô theo luồng "không bán được" đã có (người bán chọn trong 7 ngày, im lặng thì tự trả sách) | ⏳ |
| BR-6.11 | Bảng kết quả công khai vẫn ghi "Không đạt giá" và không lộ giá sàn; nếu bán sau phiên thành công thì không công bố lại | [Đề xuất] ⏳ |

### 6.4 Đã có, giữ nguyên

Hoá đơn = giá búa + phí người mua + ship − cọc; hạn thanh toán 48 giờ; phạt 10% giá búa cho mỗi lô bỏ (mất cọc nếu cọc lớn hơn, thiếu thì ghi nợ); gộp phí ship khi thắng nhiều lô; lô không bán mà người bán im lặng 7 ngày thì tự trả sách; phí lưu kho thành nợ; lô bị trả hàng phải kiểm định lại. [Đã có] ✅

## 7. Tiền và ví (bổ sung)

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-7.1 | Đã có: khoá tiền nạp chưa dùng 24 giờ; hạn mức rút 20.000.000đ/ngày; rút tối thiểu 50.000đ; Admin duyệt rút phải nhập biên lai; đối soát ví với sổ cái mỗi đêm | [Đã có] | ✅ |
| BR-7.2 | Thêm tài khoản ngân hàng mới để rút: phải nhập OTP; tài khoản mới dùng được sau 24 giờ | [Đề xuất] | ⏳ (BE-02) |
| BR-7.3 | Rút tiền không mất phí (sàn chịu phí chuyển khoản) | [Đề xuất] | ✅ (đúng như hiện tại) |
| BR-7.4 | Khoản rút ≥ 50.000.000đ phải có Admin thứ hai xác nhận | [Đề xuất] | ⏳ (BE-28) |
| BR-7.5 | Sàn chi tiền bồi thường (BR-4.2) và tiền bù (BR-6.2) từ ví sàn, mỗi khoản một loại giao dịch riêng (`COMPENSATION`) để đối soát | [Đề xuất] | ✅ (loại giao dịch `COMPENSATION`) |

## 8. Thông báo bắt buộc

| ID | Luật | Nhãn | Code |
|---|---|---|---|
| BR-8.1 | Các mốc có hạn phải gửi **ngoài app** (push, và email dự phòng), không chỉ lưu thông báo trong app: thắng lô (hạn 48 giờ, nhắc lại lúc còn 24 giờ và 2 giờ), mời mua lần hai, mời bán / mua sau phiên, phát sinh nợ, khiếu nại sắp hết hạn trả lời, phiên dời / huỷ | [Đề xuất] | ⏳ (BE-36: chưa có push / email) |
| BR-8.2 | Chưa gửi được thông báo ngoài app thì **không được phạt** người thắng bỏ thanh toán. Đến khi có BR-8.1, hạn thanh toán vẫn 48 giờ nhưng phạt chỉ áp khi hệ thống đã gửi được ít nhất một thông báo ngoài app | [Đề xuất] | ⏳ |

## 9. Pháp lý (chưa xác minh, cần người am hiểu luật)

Ghi vào phần "rủi ro / hạn chế" của báo cáo đồ án, không làm trong code:
- Đấu giá tài sản chuyên nghiệp chịu điều chỉnh của Luật Đấu giá tài sản (SRS mục 5.3 đã nhắc). Một sàn tự đấu giá hàng ký gửi có thể cần mô hình pháp lý riêng.
- Thu và lưu CCCD, IP, thiết bị là dữ liệu cá nhân: cần đối chiếu Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân (đồng ý, mục đích, thời hạn lưu).
- Sàn thương mại điện tử giữ tiền hộ, thuế của người bán cá nhân, hoá đơn điện tử cho phí sàn: cần tham vấn (BE-31).

## 10. Cấu hình mới đề xuất

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

## 11. Thứ tự làm đề xuất

1. **Nhỏ, ít rủi ro (backend thuần):** BR-4.6 và BR-5.5 (chặn giá ≤ 0), BR-2.2–2.5 (ISBN), BR-5.3 (chốt phí lúc công bố), BR-5.4 (cờ demo), BR-6.1 (đổi `forfeit_seller_percent` về 0), BR-6.5 (giá mời công bằng).
2. **Cần frontend đổi theo:** phiếu kiểm định có cấu trúc (BR-4.1–4.5), lô cao giá (BR-5.6–5.7), bán sau phiên (BR-6.8–6.10), hoàn một phần (BR-3.8–3.10), báo cáo tin (BR-2.9), xác nhận trả giá lớn (BR-5.10).
3. **Cần dịch vụ ngoài:** OTP SMS (BR-1.1), push / email (BR-8.1), CCCD (BR-1.2–1.5).
4. **Bồi thường kho và tiền bù người bán** (BR-4.2, BR-6.2): làm sau khi có trạng thái kho `LOST` / `DAMAGED`.

Mỗi mục làm xong thì đổi ⏳ thành ✅ ở bảng tương ứng, và đánh dấu endpoint / field mới trong `apps/frontend/openapi/openapi.yaml` theo quy ước ở `CLAUDE.md`.
