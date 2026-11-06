# Kế hoạch test luồng đầu cuối (backend)

Cập nhật 2026-11-06. Căn cứ: SRS mục 4 (bán giá cố định), 6 (đấu giá), 7 (luồng trạng thái), 8 (ví, phí, cọc) và các quy tắc đã làm thêm ở `AUDIT_BACKEND.md`, `AUCTION_MONEY_FLOW.md`.

Cách chạy: test tích hợp thật (Spring + PostgreSQL), gọi qua HTTP như app gọi (`MockMvc`), mỗi người dùng đóng đúng vai (USER, STAFF, ADMIN). Chỉ những chỗ không thể chờ thật (đồng hồ lô, hạn thanh toán) mới chỉnh giờ bằng SQL rồi gọi đúng hàm mà job gọi.

Hai lớp test, thư mục `src/test/java/com/rebook/journey/`:

- `FullJourneyTest`: các "câu chuyện" dài, mỗi câu chuyện đi hết một vòng và kiểm **bảo toàn tiền** (tổng ví người tham gia + ví sàn đổi đúng bằng số tiền nạp vào).
- `JourneyEdgeCasesTest`: nhiều ca ngắn: dữ liệu sai, sai quyền, sai trạng thái, đua nhau.

## A. Câu chuyện (FullJourneyTest)

| Mã | Câu chuyện | Kiểm gì |
|---|---|---|
| S1 | Nạp ví qua cổng (giả lập) → shop mới đăng tin → Admin duyệt → người mua bỏ giỏ, thanh toán ví → shop xác nhận, giao, đã giao → người mua xác nhận nhận → đánh giá | Tin shop mới chờ duyệt, người mua chưa thấy; tồn kho giảm; tiền: người mua trừ đúng tổng, người bán nhận giá trừ phí, ví sàn nhận phí; đánh giá một lần |
| S2 | Giao rồi trả hàng, shop đồng ý, người mua gửi trả, shop nhận lại | Hoàn đủ tiền cho người mua, người bán không nhận gì, ví sàn không giữ phí |
| S3 | Trả hàng bị shop từ chối → Admin phân xử (hai nhánh) | Nhánh giữ đơn: người bán nhận tiền; nhánh hoàn: người mua nhận lại tiền |
| S4 | Huỷ đơn: trước khi xác nhận (huỷ tự do), sau khi xác nhận (yêu cầu huỷ, shop đồng ý) | Hoàn tiền ví, trả lại tồn kho |
| S5 | COD: đặt → shop xác nhận, giao → Staff đối chiếu hãng vận chuyển → người mua xác nhận → Admin xác nhận đã nhận tiền thu hộ | Người bán chỉ được trả sau khi sàn nhận tiền COD |
| S6 | Ký gửi → sơ duyệt → hẹn lịch → nhận sách → kiểm định → người bán đồng ý → Admin lập phiên, xếp lô, công bố → đăng ký + cọc → mở phiên → nhiều người trả giá (tay + giá tối đa) → chốt lô → hết phiên → hoá đơn → thanh toán → Staff xuất kho, giao → người mua xác nhận → trả người bán | Cọc khoá/hoàn đúng; người thua nhận lại cọc; hoá đơn = giá búa + phí người mua + phí giao − cọc; người bán nhận giá búa − hoa hồng; bảo toàn tiền |
| S7 | Người thắng không thanh toán đúng hạn | Mất cọc/ bị phạt, bị cấm; người trả giá cao thứ hai được mời nếu đạt giá sàn; người đó thanh toán; người bán vẫn được trả |
| S8 | Phiên thiếu người: dời lịch một lần rồi huỷ | Hoàn cọc toàn bộ; lô quay về chờ xếp phiên |

## B. Ca ngắn (JourneyEdgeCasesTest)

| Nhóm | Ca |
|---|---|
| Số tiền | Nạp 9.999 / 10.000,5 / 10^16: 400. Trả giá 50.000,4: 400; `50000.0`: nhận. Giá tối đa, cọc thêm, giá tin, giá mong muốn ký gửi: số lẻ 400 |
| Ví | Mô phỏng thanh toán của người khác: 403; mô phỏng hai lần: 409; rút dưới tối thiểu: 400; rút quá số dư: 4xx và ví không đổi; tiền vừa nạp chưa rút ngay được |
| Tin đăng | Dưới 3 ảnh, giá < 1.000, tồn kho âm: 400; từ chối không lý do: 400; người mua gọi API Admin: 403; không đăng nhập: 401; tin chờ duyệt không hiện trong danh sách công khai; sửa tin của shop khác: 403/404 |
| Giỏ & đặt hàng | Giỏ trống; số lượng vượt tồn; mua tin của chính mình; ví không đủ; tin đã ẩn; hai shop trong một giỏ ra hai đơn; hai người tranh cuốn cuối (đã có ở `ConcurrencyTest`) |
| Quyền đơn | Người lạ xem / huỷ đơn: 403/404; shop khác xác nhận: 403/404; sai thứ tự (giao trước khi xác nhận, nhận hàng trước khi giao, đánh giá khi chưa hoàn tất): 409 |
| Trả hàng | Thiếu ảnh / mô tả: 400; đơn chưa giao: 409; trả lần hai: 409; quá hạn khiếu nại: 409 |
| Ký gửi | Giá mong muốn dưới mức tối thiểu; email chưa xác thực; hẹn ngoài 8h–17h; hẹn quá hạn; xem ký gửi người khác; kiểm định khi chưa nhận sách; giá kiểm định sai (sàn > ước tính thấp, khởi điểm > sàn); không tích điều khoản; giá sàn đề nghị vượt / thấp hơn khởi điểm; kiểm định không đạt rồi không xếp được phiên |
| Phiên | Xếp lô chưa sẵn sàng / trùng lô; công bố khi chưa có lô, khi hạn đăng ký ở quá khứ; sửa phiên đã công bố; đăng ký khi chưa xác thực SĐT, chưa đồng ý quy chế, ví không đủ cọc, đăng ký hai lần, sau hạn; mở phiên khi chưa đủ người. Từ 2026-11-06: công bố thiếu 72 giờ / hạn đăng ký sát giờ mở, cọc 0, Staff / Admin đăng ký hoặc trả giá, mở phiên ngay ngoài demo (`BusinessRulesBatchTest`, `StartNowDemoGateTest`, `MultiBidderTest`) |
| Bảo mật | Mọi endpoint ví / đơn / đấu giá cần đăng nhập; vai USER không vào được `/staff`, `/admin` |

## C. Điều kiện hoàn thành

- Tất cả ca đạt hoặc được ghi rõ là lỗi tìm thấy kèm cách sửa.
- Mỗi câu chuyện S1–S8 kết thúc bằng kiểm bảo toàn tiền.
- Chạy cả bộ test cũ vẫn đạt (không phá `MoneyRulesTest`, `AuctionMoneyTest`, `MultiBidderTest`).

## D. Chưa nằm trong phạm vi

Giao diện Flutter, cổng ZaloPay thật, thông báo đẩy, tải lớn nhiều trăm người, WebSocket phòng đông.

## E. Kết quả chạy (2026-11-06)

`FullJourneyTest` 16 ca và `JourneyEdgeCasesTest` 15 ca đạt; toàn bộ bộ test backend **144/144 đạt**. Tìm được và sửa 2 lỗi nhờ các ca này: số tiền lẻ / quá lớn được nhận (giờ trả 400), và mất "gộp kiện" phí giao khi người thắng chọn giao tận nơi sau phiên. Chi tiết: [SESSION_LOG_2026-11-05.md](SESSION_LOG_2026-11-05.md) mục J.
