# Luồng tiền đấu giá: phân tích BA và quy tắc

Ngày 2026-11-05. Nguồn: SRS mục 6.4 (đăng ký, cọc), 6.5 (phiên), 6.6 (sau phiên), 8.2 (phí), 8.3 (cọc), 8.4 (nguyên tắc kỹ thuật), đối chiếu với code `auction/`, `consignment/`, `wallet/`, `order/`.
Quyết định của chủ sàn: phạt **% giá búa cho mỗi lô bỏ thanh toán**; phần còn lại do BA tự đánh giá theo SRS và thực tế vận hành.
Mọi con số là giá trị mặc định, sửa được trong `system_configs`.

> **Cập nhật 2026-11-06** (chủ sàn chốt, xem [SRS_BO_SUNG_NGHIEP_VU.md](SRS_BO_SUNG_NGHIEP_VU.md) BR-6.1, BR-6.2, BR-6.5, BR-4.2): cọc và tiền phạt của người bỏ thanh toán **về sàn 100%** (`auction.forfeit_seller_percent` = 0); sàn **bù chênh** cho người bán khi lô bán lại thấp hơn; người về nhì được mời mua ở **giá công bằng**; kho làm mất / hỏng sách thì sàn bồi thường theo giai đoạn. Các mục dưới đã sửa theo luật này.

## 1. Mô hình tiền của một người tham gia đấu giá

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

## 2. Đối chiếu SRS với hiện trạng (lệch và rủi ro thực tế)

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

## 3. Quy tắc mới

### 3.1 Phạt bỏ thanh toán (theo quyết định của chủ sàn)
- Áp cho **mỗi** lô thắng bị quá hạn thanh toán (hoá đơn thường, không áp cho lời mời mua lần hai).
- `phạt = giá búa × auction.default_penalty_percent` (mặc định **10%**).
- Nếu người đó còn tiền cọc **đang giữ** (đăng ký còn `APPROVED`): **mất toàn bộ cọc** như SRS, và `phạt = max(phạt, cọc còn giữ)`. Phần phạt vượt cọc thu từ `available` (mục 3.2).
- Nếu cọc đã dùng (`APPLIED`) hoặc đã mất ở lô trước: chỉ thu `phạt = % giá búa` từ `available`.
- Tiền phạt và cọc bị thu **về sàn 100%** (`auction.forfeit_seller_percent` = 0, thay SRS 8.3 chia 50/50): người bán không còn lợi gì khi dùng tài khoản phụ đẩy giá rồi bỏ.
- **Bù chênh cho người bán** (BR-6.2): lô bán lại (mua lần hai hoặc phiên sau) với giá búa thấp hơn giá bị bỏ thì khi đơn mới hoàn tất, sàn trả người bán `(giá bị bỏ − giá mới) × (1 − hoa hồng)`, tối đa bằng số sàn đã thu từ người bỏ cho lô đó (cọc + phạt đã thu). Phạt thu sau lúc hoàn tất thì không bù thêm.
- Luôn cấm đấu giá `auction.ban_days` (90 ngày) như hiện tại. Mỗi lô bỏ làm mốc cấm lùi thêm.

### 3.2 Nợ phạt và nợ phí kho
- Phần phạt hoặc phí kho **chưa thu đủ** ghi vào bảng `account_debts` (loại `AUCTION_PENALTY` hoặc `STORAGE_FEE`), trạng thái `OPEN`.
- Thu nợ tự động theo thứ tự cũ nhất trước, từ `available`, mỗi khi: tạo nợ, người dùng bấm thu nợ (`POST /me/debts/collect`), người dùng đăng ký phiên hoặc rút tiền (hệ thống thu trước rồi mới kiểm tra), người bán được trả tiền đấu giá.
- Khi còn nợ `OPEN`: **không đăng ký phiên, không trả giá, không rút tiền** (`DEBT_OPEN`, 409/403). Vẫn mua bán thường, nạp tiền, xem.
- Tiền thu được: nợ phạt và nợ phí kho đều vào ví sàn (nợ tạo trước 2026-11-06 vẫn chia theo tỷ lệ ghi trên khoản nợ).
- Admin miễn nợ (`WAIVED`) kèm lý do, ghi nhật ký. Miễn nợ không gỡ lệnh cấm đấu giá.

### 3.3 Huỷ đăng ký
- Cho huỷ khi phiên còn `PUBLISHED` / `POSTPONED` và chưa tới `registrationDeadline`. Hoàn toàn bộ cọc (`DEPOSIT_RELEASE`), huỷ các giá tối đa tự động đã đặt, không tính vào số người đăng ký.
- Sau hạn đăng ký không huỷ được (phiên `CONFIRMED` đã tính đủ người).
- Đăng ký lại được nếu còn trong hạn; giữ nguyên số bài cũ.

### 3.4 Lô không bán, tự xử lý
- Lô `UNSOLD` hoặc `CANCELLED` quá `auction.unsold_decision_days` (mặc định **7 ngày**) kể từ lúc đóng mà người bán chưa chọn: hệ thống chuyển sang **trả sách** (`RETURNED`), thông báo, bắt đầu 14 ngày lưu kho miễn phí; sau đó 5.000đ/cuốn/ngày.
- Người bán vẫn nhận lại sách như SRS; không tự động đưa lô vào phiên sau (tránh phát sinh lượt mà người bán không biết).

### 3.5 Gộp phí giao
- Người thắng nhiều lô trong cùng một phiên, giao tận nơi tới địa chỉ mặc định: phí giao của lô thứ n = `phí(tổng khối lượng n lô đầu) − phí(tổng khối lượng n−1 lô đầu)`. Tổng các hoá đơn bằng đúng phí giao của kiện gộp.
- Nhận tại kho thì không tính. Người mua đổi cách nhận hoặc địa chỉ ở từng hoá đơn thì hoá đơn đó tính lại theo khối lượng riêng của lô.

### 3.5b Lời mời mua lần hai
- **Giá mời = giá công bằng** (BR-6.5): `max(giá sàn, min(giá cao nhất của người về nhì, giá cao nhất của người kế tiếp + 1 bước))`; không có người kế tiếp thì bằng giá sàn. Ví dụ người bỏ 300.000, người về nhì 250.000, người thứ ba 150.000 → mời 160.000.
- Giữ nguyên: không có cọc để trừ, hạn 24 giờ, giá ≥ giá sàn. **Không phạt** nếu từ chối hoặc để quá hạn (SRS không yêu cầu).

### 3.6 Kiểm định lại khi lô bị trả hàng
- Đơn đấu giá `RETURNED` / `FAILED_DELIVERY`: hoàn tiền người mua đầy đủ như hiện tại; lô chuyển sang trạng thái mới `INSPECTING` (nằm trong kho, chưa xếp phiên được).
- Staff kiểm định lại (`POST /staff/lots/{id}/reinspect`, bắt buộc có báo cáo): đạt → `READY`; không đạt → `RETURNED` trả người bán, bắt đầu hạn lưu kho (sàn đã chịu trách nhiệm hoàn tiền người mua).

### 3.7 Chọn người về nhì hợp lệ
- Xét các lượt trả giá cao nhất của từng người (không phải người bỏ thanh toán), từ cao xuống thấp: người đầu tiên có giá ≥ giá sàn, **không bị cấm đấu giá, không còn nợ, không phải người ký gửi** thì được mời. Không có ai thì lô quay lại `READY`.

## 4. Ma trận kịch bản (kết quả mong đợi)

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

## 5. API, cấu hình, sự kiện log

| Loại | Chi tiết |
|---|---|
| API mới | `DELETE /sessions/{id}/register` (huỷ đăng ký); `GET /me/debts`, `POST /me/debts/collect`; `POST /admin/debts/{id}/waive`; `POST /staff/lots/{id}/reinspect` |
| Giá trị enum mới | `LotStatus.INSPECTING`, `RegistrationStatus.CANCELLED`, loại giao dịch ví `AUCTION_PENALTY` |
| Cấu hình mới | `auction.default_penalty_percent` = 10; `auction.unsold_decision_days` = 7 |
| Mã lỗi mới | `DEBT_OPEN` |
| Sự kiện log | `AUCTION.REGISTRATION.CANCELLED`, `AUCTION.DEFAULT.PENALIZED`, `DEBT.CREATED`, `DEBT.COLLECTED`, `DEBT.WAIVED`, `AUCTION.LOT.AUTO_RETURNED`, `AUCTION.LOT.REINSPECTED`, `WAREHOUSE.STORAGE_FEE.CHARGED` (cộng với `WALLET.TX.POSTED` cho mọi dòng sổ cái) |

## 6. Ngoài phạm vi (ghi nhận để làm sau)
- Người bị cấm đấu giá vẫn đang giữ cọc ở các phiên tương lai: nên tự huỷ các đăng ký đó và hoàn cọc.
- ~~Sàn huỷ hoá đơn đã thanh toán vì lỗi của sàn (mất, hỏng sách trong kho)~~: đã làm 2026-11-06 (sự cố kho, SRS bổ sung BR-4.2).
- Bán sau phiên cho người trả cao nhất khi chưa đạt giá sàn (after-sale negotiation).
- Nâng hạn mức cọc theo giá trị lô, hoặc cọc riêng cho lô giá trị cao.
- Ảnh hưởng thuế, hoá đơn điện tử cho phí người mua và hoa hồng, quy định đấu giá tài sản (Luật Đấu giá tài sản): cần tham vấn pháp lý.

## 7. Giả định cần chủ sàn duyệt
Phạt 10% (và `max` với cọc còn giữ), hạn 7 ngày tự trả sách, chặn rút tiền khi còn nợ, miễn nợ do Admin quyết, gộp ship chỉ khi giao đến địa chỉ mặc định, không phạt người về nhì từ chối.
