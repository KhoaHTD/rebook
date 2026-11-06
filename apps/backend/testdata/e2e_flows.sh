#!/usr/bin/env bash
# =====================================================================
# Test đầu cuối qua HTTP thật (docs/ra-soat-nghiep-vu/TEST_PLAN_TOAN_DIEN.md phần A, phần C).
# Cần: backend đang chạy profile dev ở $API (mặc định http://localhost:8080) với ZALOPAY_APP_ID rỗng (dùng cổng giả lập),
#      đã nạp testdata/e2e_personas.sql, có psql, curl, jq.
#   bash apps/backend/testdata/e2e_flows.sh
# Mỗi ca in PASS / FAIL kèm mã ca; cuối cùng in tổng. Mã thoát 1 nếu có ca FAIL.
# Ca phụ thuộc job nền (chạy mỗi 60 giây hoặc 5 phút) được chờ có giới hạn thời gian.
# =====================================================================
set -u
API=${API:-http://localhost:8080}
PSQL=${PSQL:-psql -h localhost -U rebook -d rebook_dev -tA}
PASS=0; FAIL=0; FAILED=()

sql() { $PSQL -c "$1" 2>/dev/null | head -1; }
ok()  { PASS=$((PASS + 1)); printf '  \033[32mPASS\033[0m %-8s %s\n' "$1" "$2"; }
bad() { FAIL=$((FAIL + 1)); FAILED+=("$1"); printf '  \033[31mFAIL\033[0m %-8s %s  (%s)\n' "$1" "$2" "$3"; }
# check MÃ "mô tả" thực_tế mong_đợi
check() { if [ "$3" = "$4" ]; then ok "$1" "$2"; else bad "$1" "$2" "được '$3', mong '$4'"; fi; }

# req TOKEN METHOD PATH [BODY] → in "HTTP_CODE BODY"
req() {
  local auth=() body=()
  [ -n "$1" ] && auth=(-H "Authorization: Bearer $1")
  [ $# -ge 4 ] && body=(-H 'Content-Type: application/json' -d "$4")
  # ${a[@]+"${a[@]}"}: mảng rỗng không lỗi với set -u trên bash 3.2 (macOS)
  curl -s -o /tmp/e2e_body -w '%{http_code}' -X "$2" ${auth[@]+"${auth[@]}"} ${body[@]+"${body[@]}"} "$API$3"
  printf ' '; cat /tmp/e2e_body
}
code() { echo "${1%% *}"; }
body() { echo "${1#* }"; }
login() { body "$(req '' POST /auth/login '{"email":"'"$1"'","password":"Rebook@123"}')" | jq -r .accessToken; }
avail() { sql "select available_balance from wallets where user_id = $1"; }
held()  { sql "select held_balance from wallets where user_id = $1"; }
total_money() { sql "select sum(available_balance + held_balance) from wallets"; }
wait_for() { # wait_for GIÂY "SQL trả 't' khi xong"
  local i; for ((i = 0; i < $1; i += 3)); do [ "$(sql "$2")" = "t" ] && return 0; sleep 3; done; return 1
}

echo "== Đăng nhập các vai"
ADMIN=$(login admin@rebook.vn); STAFF=$(login e2e.staff@rebook.vn)
RICH=$(login e2e.buyer.rich@rebook.vn); POOR=$(login e2e.buyer.poor@rebook.vn); NEWB=$(login e2e.buyer.new@rebook.vn)
BOMB=$(login e2e.buyer.bomber@rebook.vn); DEBT=$(login e2e.buyer.debt@rebook.vn); BANNED=$(login e2e.buyer.banned@rebook.vn)
A=$(login e2e.bidder.a@rebook.vn); B=$(login e2e.bidder.b@rebook.vn); C=$(login e2e.bidder.c@rebook.vn)
SHOP=$(login e2e.shop.new@rebook.vn); CONS=$(login e2e.consignor@rebook.vn); UNVER=$(login e2e.unverified@rebook.vn)
[ -n "$ADMIN" ] && [ "$ADMIN" != "null" ] && [ -n "$RICH" ] && [ "$RICH" != "null" ] && ok AUTH-01 "Đăng nhập đúng mật khẩu" || bad AUTH-01 "Đăng nhập" "không lấy được token"
check AUTH-02 "Tài khoản bị khoá không đăng nhập được" "$(code "$(req '' POST /auth/login '{"email":"e2e.buyer.locked@rebook.vn","password":"Rebook@123"}')")" 403
check AUTH-03 "Sai mật khẩu bị từ chối" "$(code "$(req '' POST /auth/login '{"email":"e2e.buyer.rich@rebook.vn","password":"sai-mat-khau"}')")" 401
check AUTH-04 "Gọi API cần đăng nhập mà không có token" "$(code "$(req '' GET /wallet)")" 401
check AUTH-05 "Người mua gọi API Admin" "$(code "$(req "$RICH" GET /admin/configs)")" 403
req "$ADMIN" POST /admin/users/9013/lock '{"reason":"Test E2E khoá khi đang đăng nhập"}' >/dev/null
check AUTH-06 "Bị khoá khi đang đăng nhập: token cũ hết tác dụng ngay" "$(code "$(req "$UNVER" GET /me)")" 401
req "$ADMIN" POST /admin/users/9013/unlock >/dev/null

MONEY_BEFORE=$(total_money)
MONEY_IN=0   # tiền vào hệ thống: nạp qua cổng, trả đơn qua cổng, COD hãng chuyển về
MONEY_OUT=0  # tiền ra khỏi hệ thống: rút tiền đã duyệt
RICH_ADDR=$(sql "select id from addresses where user_id = 9001")

echo "== Mua bán giá cố định"
# ORD-01 happy case: ví, shop xác nhận, giao, người mua nhận
req "$RICH" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
PREV=$(body "$(req "$RICH" POST /orders/checkout/preview '{"addressId":'"$RICH_ADDR"',"listingIds":[9002]}')")
SEEN=$(echo "$PREV" | jq -r .total)
RICH0=$(avail 9001); SHOP0=$(avail 9011)
R=$(req "$RICH" POST /orders/checkout '{"addressId":'"$RICH_ADDR"',"paymentMethod":"WALLET","listingIds":[9002],"expectedTotal":'"$SEEN"'}')
check ORD-01a "Đặt hàng trả ví với giá đã thấy" "$(code "$R")" 201
O1=$(body "$R" | jq -r '.orders[0].id')
check ORD-01b "Người mua bị trừ đúng tổng" "$(avail 9001)" "$((RICH0 - SEEN))"
check ORD-01c "Shop xác nhận đơn" "$(code "$(req "$SHOP" POST /seller/orders/$O1/confirm)")" 200
check ORD-01d "Shop giao cho vận chuyển" "$(code "$(req "$SHOP" POST /seller/orders/$O1/ship '{"trackingCode":"GHN123456"}')")" 200
check ORD-01e "Người mua xác nhận đã nhận" "$(code "$(req "$RICH" POST /orders/$O1/confirm-received)")" 200
FEE=$(sql "select round(subtotal * fee_percent / 100) from orders where id = $O1")
check ORD-01f "Shop nhận tiền trừ phí sàn" "$(avail 9011)" "$((SHOP0 + SEEN - FEE))"
check ORD-01g "Đánh giá shop một lần" "$(code "$(req "$RICH" POST /orders/$O1/review '{"rating":5,"comment":"Sách đúng mô tả"}')")" 201
check ORD-01h "Đánh giá lần hai bị chặn" "$(code "$(req "$RICH" POST /orders/$O1/review '{"rating":1,"comment":"x"}')")" 409

# ORD-02 hell case: shop đổi giá đúng lúc người mua bấm đặt
req "$RICH" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
SEEN=$(body "$(req "$RICH" POST /orders/checkout/preview '{"addressId":'"$RICH_ADDR"',"listingIds":[9002]}')" | jq -r .total)
sql "update listings set price = 450000 where id = 9002" >/dev/null
R=$(req "$RICH" POST /orders/checkout '{"addressId":'"$RICH_ADDR"',"paymentMethod":"WALLET","listingIds":[9002],"expectedTotal":'"$SEEN"'}')
check ORD-02 "Giá đổi sau khi xem trước: PRICE_CHANGED" "$(code "$R") $(body "$R" | jq -r .code)" "409 PRICE_CHANGED"
sql "update listings set price = 45000 where id = 9002" >/dev/null

# ORD-03 hell case: hai người tranh cuốn cuối cùng
A_ADDR=$(sql "select id from addresses where user_id = 9008")
req "$RICH" POST /cart '{"listingId":9001,"quantity":1}' >/dev/null
req "$A" POST /cart '{"listingId":9001,"quantity":1}' >/dev/null
( req "$RICH" POST /orders/checkout '{"addressId":'"$RICH_ADDR"',"paymentMethod":"WALLET","listingIds":[9001]}' | cut -c1-3 > /tmp/e2e_race1 ) &
( req "$A" POST /orders/checkout '{"addressId":'"$A_ADDR"',"paymentMethod":"WALLET","listingIds":[9001]}' | cut -c1-3 > /tmp/e2e_race2 ) &
wait
RACE=$(sort /tmp/e2e_race1 /tmp/e2e_race2 | tr '\n' ' ')
check ORD-03 "Hai người tranh cuốn cuối: đúng một người mua được" "$RACE" "201 409 "
check ORD-03b "Tồn kho không âm" "$(sql "select stock from listings where id = 9001")" 0

# ORD-04..08 negative
POOR_ADDR=$(sql "select id from addresses where user_id = 9002")
req "$POOR" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
R=$(req "$POOR" POST /orders/checkout '{"addressId":'"$POOR_ADDR"',"paymentMethod":"WALLET"}')
check ORD-04 "Ví không đủ tiền" "$(code "$R") $(body "$R" | jq -r .code)" "400 INSUFFICIENT_BALANCE"
check ORD-04b "Đặt hỏng thì tồn kho giữ nguyên" "$(sql "select stock from listings where id = 9002")" 4
BOMB_ADDR=$(sql "select id from addresses where user_id = 9004")
req "$BOMB" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
R=$(req "$BOMB" POST /orders/checkout '{"addressId":'"$BOMB_ADDR"',"paymentMethod":"COD"}')
check ORD-05 "Người từng bom 2 đơn COD bị chặn COD" "$(code "$R") $(body "$R" | jq -r .code)" "409 COD_NOT_ALLOWED"
NEW_ADDR=$(sql "select id from addresses where user_id = 9003")
req "$NEWB" POST /cart '{"listingId":9005,"quantity":1}' >/dev/null
R=$(req "$NEWB" POST /orders/checkout '{"addressId":'"$NEW_ADDR"',"paymentMethod":"COD"}')
check ORD-06 "Người mua mới đặt COD vượt hạn mức" "$(code "$R") $(body "$R" | jq -r .code)" "409 COD_NOT_ALLOWED"
check ORD-07 "Bỏ tin đang ẩn vào giỏ" "$(code "$(req "$RICH" POST /cart '{"listingId":9003,"quantity":1}')" | cut -c1)" 4
check ORD-08 "Mua tin của chính shop mình" "$(code "$(req "$SHOP" POST /cart '{"listingId":9002,"quantity":1}')" | cut -c1)" 4

# ORD-09 hell case: shop giao rồi không ai giao thật, đơn tự coi là đã giao, người mua không nhận được sách
req "$RICH" DELETE /cart >/dev/null
req "$RICH" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
R=$(req "$RICH" POST /orders/checkout '{"addressId":'"$RICH_ADDR"',"paymentMethod":"WALLET","listingIds":[9002]}')
O9=$(body "$R" | jq -r '.orders[0].id'); T9=$(body "$R" | jq -r '.orders[0].total')
req "$SHOP" POST /seller/orders/$O9/confirm >/dev/null
req "$SHOP" POST /seller/orders/$O9/ship '{}' >/dev/null
sql "update orders set shipped_at = now() - interval '8 day' where id = $O9" >/dev/null
if wait_for 90 "select status = 'DELIVERED' from orders where id = $O9"; then ok ORD-09a "Job tự coi là đã giao sau 7 ngày"; else bad ORD-09a "Job tự coi là đã giao" "quá 90 giây"; fi
RICH0=$(avail 9001)
check ORD-09b "Khiếu nại không nhận được hàng, không cần ảnh" "$(code "$(req "$RICH" POST /orders/$O9/return '{"reason":"NOT_RECEIVED","description":"Chưa từng nhận được sách"}')")" 200
req "$SHOP" POST /seller/orders/$O9/return-decision '{"approve":false,"note":"Đã giao rồi"}' >/dev/null
check ORD-09c "Admin phân xử hoàn tiền" "$(code "$(req "$ADMIN" POST /admin/disputes/$O9/resolve '{"approve":true,"note":"Mã vận đơn không có thật"}')")" 200
check ORD-09d "Đơn chuyển RETURNED, hoàn đủ tiền" "$(sql "select status from orders where id = $O9") $(avail 9001)" "RETURNED $((RICH0 + T9))"

# ORD-10 giao thất bại do người mua (đối chiếu hãng vận chuyển)
B_ADDR=$(sql "select id from addresses where user_id = 9009")
req "$B" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
R=$(req "$B" POST /orders/checkout '{"addressId":'"$B_ADDR"',"paymentMethod":"WALLET","listingIds":[9002]}')
O10=$(body "$R" | jq -r '.orders[0].id')
SUB10=$(sql "select subtotal from orders where id = $O10"); SHIP10=$(sql "select shipping_fee from orders where id = $O10")
req "$SHOP" POST /seller/orders/$O10/confirm >/dev/null; req "$SHOP" POST /seller/orders/$O10/ship '{"trackingCode":"GHTK999"}' >/dev/null
B0=$(avail 9009); SHOP0=$(avail 9011)
check ORD-10a "Staff báo giao thất bại do người mua" "$(code "$(req "$STAFF" POST /staff/orders/$O10/carrier-failed '{"reason":"Người nhận từ chối","fault":"BUYER"}')")" 200
check ORD-10b "Người mua được hoàn tiền sách, mất phí giao" "$(avail 9009)" "$((B0 + SUB10))"
check ORD-10c "Shop nhận lại phí giao đã trả hãng" "$(avail 9011)" "$((SHOP0 + SHIP10))"

# ORD-11 người mua huỷ trước khi shop xác nhận
req "$RICH" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
STOCK0=$(sql "select stock from listings where id = 9002"); RICH0=$(avail 9001)
R=$(req "$RICH" POST /orders/checkout '{"addressId":'"$RICH_ADDR"',"paymentMethod":"WALLET","listingIds":[9002]}')
O11=$(body "$R" | jq -r '.orders[0].id')
check ORD-11a "Người mua huỷ đơn chưa xác nhận" "$(code "$(req "$RICH" POST /orders/$O11/cancel '{"reason":"Đặt nhầm"}')")" 200
check ORD-11b "Hoàn đủ tiền, trả lại tồn kho" "$(avail 9001) $(sql "select stock from listings where id = 9002")" "$RICH0 $STOCK0"

# ORD-12 trả hàng sai mô tả theo từng bước
req "$RICH" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
R=$(req "$RICH" POST /orders/checkout '{"addressId":'"$RICH_ADDR"',"paymentMethod":"WALLET","listingIds":[9002]}')
O12=$(body "$R" | jq -r '.orders[0].id'); T12=$(body "$R" | jq -r '.orders[0].total')
req "$SHOP" POST /seller/orders/$O12/confirm >/dev/null; req "$SHOP" POST /seller/orders/$O12/ship '{"trackingCode":"GHN777"}' >/dev/null
check ORD-12a "Staff đối chiếu hãng: giao thành công" "$(code "$(req "$STAFF" POST /staff/orders/$O12/carrier-delivered)")" 200
check ORD-12b "Trả hàng thiếu ảnh bị chặn" "$(code "$(req "$RICH" POST /orders/$O12/return '{"reason":"WRONG_CONDITION","description":"Rách bìa"}')")" 400
check ORD-12c "Yêu cầu trả hàng có ảnh" "$(code "$(req "$RICH" POST /orders/$O12/return '{"reason":"WRONG_CONDITION","description":"Rách bìa, khác mô tả","images":["/files/e2e-rach.png"]}')")" 200
check ORD-12d "Shop đồng ý trả hàng" "$(code "$(req "$SHOP" POST /seller/orders/$O12/return-decision '{"approve":true,"note":"Gửi về giúp shop"}')")" 200
check ORD-12e "Người mua gửi hàng trả kèm mã vận đơn" "$(code "$(req "$RICH" POST /orders/$O12/return/shipment '{"trackingCode":"GHN-TRA-1"}')")" 200
RICH0=$(avail 9001)
check ORD-12f "Shop xác nhận đã nhận lại sách" "$(code "$(req "$SHOP" POST /seller/orders/$O12/return-received)")" 200
check ORD-12g "Đơn RETURNED, người mua được hoàn đủ" "$(sql "select status from orders where id = $O12") $(avail 9001)" "RETURNED $((RICH0 + T12))"

# ORD-13 trả bằng ZaloPay (cổng giả lập): tiền vào hệ thống từ cổng
A_ADDR=$(sql "select id from addresses where user_id = 9008")
req "$A" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
R=$(req "$A" POST /orders/checkout '{"addressId":'"$A_ADDR"',"paymentMethod":"ZALOPAY","listingIds":[9002]}')
O13=$(body "$R" | jq -r '.orders[0].id'); PAY13=$(body "$R" | jq -r '.payment.code'); T13=$(body "$R" | jq -r '.orders[0].total')
check ORD-13a "Đặt hàng ZaloPay: đơn chờ thanh toán" "$(code "$R") $(sql "select status from orders where id = $O13")" "201 PENDING_PAYMENT"
check ORD-13b "Cổng báo thành công: đơn chờ shop xác nhận" "$(code "$(req "$A" POST /payments/$PAY13/simulate)") $(sql "select status from orders where id = $O13")" "200 PENDING_CONFIRM"
MONEY_IN=$((MONEY_IN + T13))

# ORD-14 COD đi hết luồng: hãng thu hộ, sàn nhận tiền rồi mới trả shop
req "$NEWB" DELETE /cart >/dev/null
req "$NEWB" POST /cart '{"listingId":9002,"quantity":1}' >/dev/null
R=$(req "$NEWB" POST /orders/checkout '{"addressId":'"$NEW_ADDR"',"paymentMethod":"COD","listingIds":[9002]}')
O14=$(body "$R" | jq -r '.orders[0].id'); T14=$(body "$R" | jq -r '.orders[0].total')
check ORD-14a "Người mua mới đặt COD nhỏ" "$(code "$R")" 201
req "$SHOP" POST /seller/orders/$O14/confirm >/dev/null; req "$SHOP" POST /seller/orders/$O14/ship '{"trackingCode":"GHN-COD-1"}' >/dev/null
req "$STAFF" POST /staff/orders/$O14/carrier-delivered >/dev/null
SHOP0=$(avail 9011)
check ORD-14b "Người mua xác nhận nhận hàng COD" "$(code "$(req "$NEWB" POST /orders/$O14/confirm-received)")" 200
check ORD-14c "Chưa đối soát thì shop chưa nhận tiền" "$(avail 9011)" "$SHOP0"
check ORD-14d "Admin nhập sai số tiền thu hộ bị chặn" "$(code "$(req "$ADMIN" POST /admin/cod/$O14/remit '{"amount":1000}')")" 400
check ORD-14e "Admin xác nhận đã nhận tiền thu hộ" "$(code "$(req "$ADMIN" POST /admin/cod/$O14/remit '{"amount":'"$T14"',"reference":"GHN-DS-1"}')")" 200
FEE14=$(sql "select round(subtotal * fee_percent / 100) from orders where id = $O14")
check ORD-14f "Shop nhận tiền COD trừ phí sàn" "$(avail 9011)" "$((SHOP0 + T14 - FEE14))"
check ORD-14g "Xác nhận nhận tiền thu hộ lần hai bị chặn" "$(code "$(req "$ADMIN" POST /admin/cod/$O14/remit '{"amount":'"$T14"'}')")" 409
MONEY_IN=$((MONEY_IN + T14))

echo "== Ví"
R=$(req "$DEBT" POST /wallet/withdrawals '{"amount":50000,"bankName":"VCB","accountNumber":"0011223344","accountHolder":"E2E NO"}')
check WAL-01 "Còn nợ thì không rút được" "$(code "$R") $(body "$R" | jq -r .code)" "409 DEBT_OPEN"
P=$(body "$(req "$C" POST /wallet/top-up '{"amount":100000}')" | jq -r .code)
check WAL-02 "Nạp ví qua cổng giả lập" "$(code "$(req "$C" POST /payments/$P/simulate)")" 200
check WAL-02b "Giả lập lần hai bị chặn (không cộng trùng)" "$(code "$(req "$C" POST /payments/$P/simulate)")" 409
C_AV=$(avail 9010)
R=$(req "$C" POST /wallet/withdrawals '{"amount":'"$C_AV"',"bankName":"VCB","accountNumber":"0011223344","accountHolder":"E2E C"}')
check WAL-03 "Rút cả tiền vừa nạp bị khoá 24 giờ" "$(code "$R") $(body "$R" | jq -r .code)" "409 TOPUP_LOCKED"
check WAL-04 "Rút dưới mức tối thiểu" "$(code "$(req "$C" POST /wallet/withdrawals '{"amount":10000,"bankName":"VCB","accountNumber":"0011223344","accountHolder":"E2E C"}')")" 400
check WAL-05 "Rút số lẻ / số tài khoản sai" "$(code "$(req "$C" POST /wallet/withdrawals '{"amount":50000.5,"bankName":"VCB","accountNumber":"12","accountHolder":"E2E C"}')")" 400
MONEY_IN=$((MONEY_IN + 100000))
# WAL-06 rút tiền đầy đủ: khoá tiền, Admin duyệt phải có biên lai
R=$(req "$A" POST /wallet/withdrawals '{"amount":100000,"bankName":"VCB","accountNumber":"0011223344","accountHolder":"E2E A"}')
W6=$(body "$R" | jq -r .id); A_HELD=$(held 9008)
check WAL-06a "Yêu cầu rút: tiền bị khoá chờ duyệt" "$(code "$R")" 201
check WAL-06b "Duyệt thiếu biên lai bị chặn" "$(code "$(req "$ADMIN" POST /admin/withdrawals/$W6 '{"approve":true}')")" 400
NOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
check WAL-06c "Admin duyệt kèm biên lai chuyển khoản" "$(code "$(req "$ADMIN" POST /admin/withdrawals/$W6 '{"approve":true,"senderName":"Kế toán ReBook","transferTime":"'"$NOW"'","transferAmount":100000,"proofImageUrl":"/files/e2e-bienlai.png"}')")" 200
check WAL-06d "Tiền khoá được trừ khỏi ví" "$(held 9008)" "$((A_HELD - 100000))"
check WAL-06e "Duyệt lần hai bị chặn" "$(code "$(req "$ADMIN" POST /admin/withdrawals/$W6 '{"approve":false}')")" 409
MONEY_OUT=$((MONEY_OUT + 100000))
# Kiểm "còn nợ thì không đăng ký phiên" trước khi WAL-07 trả nợ
check AUC-02 "Người còn nợ không đăng ký được" "$(body "$(req "$DEBT" POST /sessions/9001/register '{"agreeRules":true}')" | jq -r .code)" DEBT_OPEN
# WAL-07 trả nợ: nạp tiền rồi thu nợ thì hết bị chặn
P=$(body "$(req "$DEBT" POST /wallet/top-up '{"amount":300000}')" | jq -r .code)
req "$DEBT" POST /payments/$P/simulate >/dev/null
MONEY_IN=$((MONEY_IN + 300000))
check WAL-07a "Thu nợ từ tiền vừa nạp" "$(body "$(req "$DEBT" POST /me/debts/collect '{}')" | jq -r .stillOwed)" 0
check WAL-07b "Hết nợ: khoản nợ PAID, còn 100.000 trong ví" "$(sql "select status from account_debts where user_id = 9005") $(avail 9005)" "PAID 100000"

echo "== Cấu hình"
check CFG-01 "Đặt thời hạn thanh toán 0 phút bị chặn" "$(code "$(req "$ADMIN" PUT /admin/configs/order.payment_timeout_minutes '{"value":"0"}')")" 400

echo "== Ký gửi"
check CON-01 "Hẹn lịch trong quá khứ" "$(code "$(req "$CONS" POST /consignments/9106/appointment '{"appointmentAt":"2020-01-01T03:00:00Z"}')")" 400
TOMORROW10=$(date -u -v+1d '+%Y-%m-%dT03:00:00Z' 2>/dev/null || date -u -d tomorrow '+%Y-%m-%dT03:00:00Z')
check CON-02 "Hẹn lịch ngày mai 10:00 giờ VN" "$(code "$(req "$CONS" POST /consignments/9106/appointment '{"appointmentAt":"'"$TOMORROW10"'"}')")" 200
check CON-03 "Người khác xem ký gửi không phải của mình" "$(code "$(req "$RICH" GET /consignments/9106)")" 404
# CON-06 ký gửi từ đầu qua API đến khi lô lên phiên đã công bố
IMGS='["/files/e2e-k1.png","/files/e2e-k2.png","/files/e2e-k3.png"]'
check CON-06a "Giá mong muốn dưới mức tối thiểu bị từ chối" "$(body "$(req "$CONS" POST /consignments '{"book":{"title":"E2E Sách rẻ","author":"X","categoryId":9001,"conditionGrade":"GOOD","weightGram":300,"imageUrls":'"$IMGS"'},"expectedPrice":100000}')" | jq -r .code)" PRICE_TOO_LOW
R=$(req "$CONS" POST /consignments '{"book":{"title":"E2E Ký gửi qua API","author":"Nguyễn Tuân","categoryId":9001,"conditionGrade":"GOOD","publishYear":1960,"weightGram":350,"imageUrls":'"$IMGS"'},"expectedPrice":500000,"provenance":"Tủ sách gia đình"}')
K=$(body "$R" | jq -r .id)
check CON-06b "Gửi yêu cầu ký gửi" "$(code "$R")" 201
check CON-06c "Sơ duyệt không đạt mà không có lý do bị chặn" "$(code "$(req "$STAFF" POST /staff/consignments/$K/review '{"approve":false}')")" 400
check CON-06d "Staff sơ duyệt đạt" "$(code "$(req "$STAFF" POST /staff/consignments/$K/review '{"approve":true}')")" 200
check CON-06e "Người bán hẹn lịch mang sách tới" "$(code "$(req "$CONS" POST /consignments/$K/appointment '{"appointmentAt":"'"$TOMORROW10"'"}')")" 200
check CON-06f "Kho nhận sách" "$(code "$(req "$STAFF" POST /staff/consignments/$K/check-in '{"shelfCode":"E2E-B1","photoUrls":["/files/e2e-nhan.png"]}')")" 200
check CON-06g "Kiểm định với giá sàn vượt ước tính thấp bị chặn" "$(code "$(req "$STAFF" POST /staff/consignments/$K/inspection '{"result":"PASS","conditionGrade":"GOOD","conditionReport":"Đủ trang","estimateLow":400000,"estimateHigh":600000,"proposedStart":150000,"proposedReserve":500000}')")" 400
check CON-06h "Kiểm định đạt kèm đề xuất giá" "$(code "$(req "$STAFF" POST /staff/consignments/$K/inspection '{"result":"PASS","conditionGrade":"GOOD","conditionReport":"Đủ trang, bìa sờn","estimateLow":400000,"estimateHigh":600000,"proposedStart":150000,"proposedReserve":300000}')")" 200
check CON-06i "Không tích điều khoản hợp đồng bị chặn" "$(code "$(req "$CONS" POST /consignments/$K/decision '{"decision":"ACCEPT","agreeTerms":false}')")" 400
check CON-06j "Người bán đồng ý, sách thành lô chờ xếp phiên" "$(code "$(req "$CONS" POST /consignments/$K/decision '{"decision":"ACCEPT","agreeTerms":true}')")" 200
LOTK=$(sql "select id from lots where consignment_id = $K")
START2=$(date -u -v+2H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '+2 hour' '+%Y-%m-%dT%H:%M:%SZ')
DEAD1=$(date -u -v+1H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '+1 hour' '+%Y-%m-%dT%H:%M:%SZ')
R=$(req "$ADMIN" POST /admin/sessions '{"title":"E2E Phiên tạo qua API","startAt":"'"$START2"'","registrationDeadline":"'"$DEAD1"'","minParticipants":2,"depositAmount":100000}')
SK=$(body "$R" | jq -r .id)
check CON-06k "Admin tạo phiên" "$(code "$R")" 201
check CON-06l "Công bố phiên chưa có lô bị chặn" "$(code "$(req "$ADMIN" POST /admin/sessions/$SK/publish)")" 400
check CON-06m "Xếp lô vào phiên" "$(code "$(req "$ADMIN" PUT /admin/sessions/$SK/lots '{"lotIds":['"$LOTK"']}')")" 200
check CON-06n "Công bố phiên" "$(code "$(req "$ADMIN" POST /admin/sessions/$SK/publish)") $(sql "select status from auction_sessions where id = $SK")" "200 PUBLISHED"

echo "== Đấu giá"
check AUC-01 "Người bị cấm đấu giá không đăng ký được" "$(body "$(req "$BANNED" POST /sessions/9001/register '{"agreeRules":true}')" | jq -r .code)" AUCTION_BANNED
check AUC-03 "Nhân viên sàn không được đăng ký" "$(body "$(req "$STAFF" POST /sessions/9001/register '{"agreeRules":true}')" | jq -r .code)" STAFF_CANNOT_BID
check AUC-04 "Chưa xác thực SĐT không đăng ký được" "$(code "$(req "$NEWB" POST /sessions/9001/register '{"agreeRules":true}')")" 403
check AUC-05 "Không đồng ý quy chế" "$(code "$(req "$A" POST /sessions/9001/register '{"agreeRules":false}')")" 400
for T in "$A" "$B" "$C" "$RICH"; do req "$T" POST /sessions/9001/register '{"agreeRules":true}' >/dev/null; done
check AUC-06 "Ba người đăng ký, mỗi người bị khoá 200.000 cọc" "$(held 9008) $(held 9010)" "200000 200000"
check AUC-07 "Đăng ký hai lần bị chặn" "$(code "$(req "$A" POST /sessions/9001/register '{"agreeRules":true}')")" 409
check AUC-08 "Đặt giá tối đa trước khi lô mở (absentee)" "$(code "$(req "$A" PUT /lots/9101/proxy-bid '{"maxAmount":350000}')")" 200
check AUC-09 "Admin mở phiên ngay (demo)" "$(code "$(req "$ADMIN" POST /admin/sessions/9001/start)")" 200
if wait_for 15 "select status = 'OPEN' from lots where id = 9101"; then ok AUC-10 "Lô 1 mở"; else bad AUC-10 "Lô 1 mở" "không mở"; fi
check AUC-11 "Giá tối đa trên giá sàn: trả hộ lên đúng giá sàn 200.000" "$(sql "select current_price || ' ' || current_winner_id from lots where id = 9101")" "200000 9008"
R=$(req "$B" POST /lots/9101/bids '{"amount":100000}')
check AUC-12 "Trả giá thấp hơn mức tối thiểu" "$(code "$R") $(body "$R" | jq -r .code)" "409 PRICE_CHANGED"
req "$B" POST /lots/9101/bids '{"amount":300000}' >/dev/null
check AUC-13 "Giá tối đa tự trả lời lượt tay, không vượt giá tối đa" "$(sql "select current_winner_id from lots where id = 9101")" 9008
check AUC-14 "Người đang dẫn không tự đẩy giá" "$(body "$(req "$A" POST /lots/9101/bids '{"amount":400000}')" | jq -r .code)" ALREADY_LEADING
if wait_for 60 "select status = 'OPEN' from lots where id = 9102"; then ok AUC-15 "Lô 1 chốt, lô 2 (cao giá) mở"; else bad AUC-15 "Lô 2 mở" "quá 60 giây"; fi
check AUC-16 "Lô 1 bán cho A" "$(sql "select status || ' ' || winner_id from lots where id = 9101")" "SOLD 9008"
R=$(req "$B" POST /lots/9102/bids '{"amount":5000000}')
check AUC-17 "Lô cao giá: chưa cọc thêm thì không trả giá được" "$(code "$R") $(body "$R" | jq -r .code)" "409 LOT_DEPOSIT_REQUIRED"
req "$B" POST /sessions/9001/deposit '{"amount":1500000}' >/dev/null
# Trả bằng giá sàn 8.000.000 (trả 5.000.000 thì lô chốt "Không đạt giá", không có hoá đơn)
check AUC-18 "Cọc thêm 1.500.000 rồi trả giá được" "$(code "$(req "$B" POST /lots/9102/bids '{"amount":8000000}')")" 200
check AUC-18b "B dẫn lô cao giá" "$(sql "select current_winner_id from lots where id = 9102")" 9009
if wait_for 60 "select status = 'OPEN' from lots where id = 9103"; then ok AUC-19 "Lô 3 mở"; else bad AUC-19 "Lô 3 mở" "quá 60 giây"; fi
req "$C" POST /lots/9103/bids '{"amount":60000}' >/dev/null
if wait_for 60 "select status = 'OPEN' from lots where id = 9104"; then ok AUC-19b "Lô 4 mở"; else bad AUC-19b "Lô 4 mở" "quá 60 giây"; fi
req "$A" POST /lots/9104/bids '{"amount":150000}' >/dev/null
req "$C" POST /lots/9104/bids '{"amount":200000}' >/dev/null
if wait_for 90 "select status = 'ENDED' from auction_sessions where id = 9001"; then ok AUC-20 "Phiên kết thúc"; else bad AUC-20 "Phiên kết thúc" "quá 90 giây"; fi
check AUC-21 "Lô 3 trả dưới giá sàn: không đạt giá, không lộ giá sàn" "$(sql "select status || ' ' || close_result from lots where id = 9103")" "UNSOLD RESERVE_NOT_MET"
check AUC-22 "Người không thắng lô nào (RICH) được hoàn cọc ngay" "$(held 9001)" 0
INV_A=$(sql "select id from orders where lot_id = 9101 and buyer_id = 9008 and status = 'PENDING_PAYMENT'")
INV_B=$(sql "select id from orders where lot_id = 9102 and buyer_id = 9009 and status = 'PENDING_PAYMENT'")
[ -n "$INV_A" ] && [ -n "$INV_B" ] && ok AUC-23 "Người thắng có hoá đơn 48 giờ" || bad AUC-23 "Hoá đơn người thắng" "thiếu hoá đơn A=$INV_A B=$INV_B"
DUE_A=$(sql "select total - deposit_applied from orders where id = $INV_A")
A0=$(avail 9008)
check AUC-24 "A trả hoá đơn bằng ví (đã trừ cọc)" "$(code "$(req "$A" POST /orders/$INV_A/pay '{"method":"WALLET"}')")" 200
check AUC-24b "A bị trừ đúng phần còn lại" "$(avail 9008)" "$((A0 - DUE_A))"
check AUC-25 "Admin khoá B khi hoá đơn chưa trả" "$(code "$(req "$ADMIN" POST /admin/users/9009/lock '{"reason":"Test E2E khoá giữa phiên"}')")" 200
check AUC-25b "Hoá đơn của B huỷ, không phạt, cọc được hoàn" \
  "$(sql "select status from orders where id = $INV_B") $(held 9009) $(sql "select coalesce(auction_banned_until::text, 'none') from users where id = 9009")" "CANCELLED 0 none"
req "$ADMIN" POST /admin/users/9009/unlock >/dev/null

# AUC-26 nửa sau luồng: kho xác nhận, giao, người mua nhận, người bán nhận giá búa trừ hoa hồng
check AUC-26a "Kho xác nhận hoá đơn đã trả" "$(code "$(req "$STAFF" POST /staff/orders/$INV_A/confirm)")" 200
check AUC-26b "Người bán không được xử lý đơn đấu giá" "$(code "$(req "$SHOP" POST /seller/orders/$INV_A/ship '{}')")" 403
check AUC-26c "Kho giao cho vận chuyển" "$(code "$(req "$STAFF" POST /staff/orders/$INV_A/ship '{"trackingCode":"GHN-LOT-1"}')")" 200
check AUC-26d "Kho đánh dấu giao thành công" "$(code "$(req "$STAFF" POST /staff/orders/$INV_A/delivered)")" 200
CONS0=$(avail 9012); HAMMER=$(sql "select hammer_price from lots where id = 9101")
check AUC-26e "Người thắng xác nhận đã nhận" "$(code "$(req "$A" POST /orders/$INV_A/confirm-received)")" 200
check AUC-26f "Người ký gửi nhận giá búa trừ 15% hoa hồng" "$(avail 9012)" "$((CONS0 + HAMMER - HAMMER * 15 / 100))"
check AUC-26g "Lô hoàn tất" "$(sql "select status from lots where id = 9101")" COMPLETED

# AUC-27 người thắng lô 4 (C) bỏ thanh toán: mất cọc, bị cấm, người về nhì (A) được mời ở giá công bằng
INV_C=$(sql "select id from orders where lot_id = 9104 and buyer_id = 9010 and status = 'PENDING_PAYMENT'")
check AUC-27a "C thắng lô 4, có hoá đơn" "$([ -n "$INV_C" ] && echo yes)" yes
PLAT0=$(sql "select available_balance from wallets where user_id is null")
sql "update orders set payment_due_at = now() - interval '1 minute' where id = $INV_C" >/dev/null
if wait_for 90 "select status = 'CANCELLED' from orders where id = $INV_C"; then ok AUC-27b "Job huỷ hoá đơn quá hạn"; else bad AUC-27b "Huỷ hoá đơn quá hạn" "quá 90 giây"; fi
check AUC-27c "C mất cọc 200.000 về sàn, bị cấm 90 ngày"   "$(held 9010) $(sql "select available_balance from wallets where user_id is null") $(sql "select extract(day from auction_banned_until - now())::int >= 89 from users where id = 9010")" "0 $((PLAT0 + 200000)) t"
SC=$(sql "select id from orders where lot_id = 9104 and buyer_id = 9008 and second_chance and status = 'PENDING_PAYMENT'")
check AUC-27d "A được mời mua lần hai ở giá công bằng 150.000 (không phải 150.000 tay của A vì không có người thứ ba: bằng giá sàn)"   "$(sql "select subtotal from orders where id = ${SC:-0}")" 150000
check AUC-27e "A nhận lời mời và trả bằng ví" "$(code "$(req "$A" POST /orders/$SC/pay '{"method":"WALLET"}')")" 200
check AUC-27f "C bị cấm thì không đăng ký phiên khác được" "$(body "$(req "$C" POST /sessions/9002/register '{"agreeRules":true}')" | jq -r .code)" AUCTION_BANNED

# AUC-28 lô không đạt giá: người ký gửi chọn nhận lại sách, kho trả sách
check AUC-28a "Người ký gửi chọn nhận lại lô không bán" "$(code "$(req "$CONS" POST /consignments/9103/unsold-decision '{"action":"RETURN"}')")" 200
WH3=$(sql "select id from warehouse_items where consignment_id = 9103")
check AUC-28b "Kho trả sách trong hạn miễn phí: không thu phí" "$(code "$(req "$STAFF" POST /staff/warehouse/$WH3/return)") $(sql "select coalesce(storage_fee, 0) from warehouse_items where id = $WH3")" "200 0"
check AUC-28c "Ký gửi kết thúc ở trạng thái đã trả sách" "$(sql "select status from consignments where id = 9103")" RETURNED

# AUC-29 phiên thiếu người: huỷ đăng ký trước hạn, dời lịch một lần, rồi huỷ phiên
req "$RICH" POST /sessions/9002/register '{"agreeRules":true}' >/dev/null
RICH_HELD=$(held 9001)
check AUC-29a "Huỷ đăng ký trước hạn: hoàn cọc" "$(code "$(req "$RICH" DELETE /sessions/9002/register)") $(held 9001)" "200 $((RICH_HELD - 100000))"
check AUC-29b "Người vừa trả hết nợ đăng ký được" "$(code "$(req "$DEBT" POST /sessions/9002/register '{"agreeRules":true}')")" 201
sql "update auction_sessions set registration_deadline = now() - interval '1 second' where id = 9002" >/dev/null
if wait_for 20 "select postpone_count = 1 and status = 'PUBLISHED' from auction_sessions where id = 9002"; then ok AUC-29c "Thiếu người lần 1: dời lịch, mở lại đăng ký"; else bad AUC-29c "Dời lịch" "không dời"; fi
sql "update auction_sessions set registration_deadline = now() - interval '1 second' where id = 9002" >/dev/null
if wait_for 20 "select status = 'CANCELLED' from auction_sessions where id = 9002"; then ok AUC-29d "Thiếu người lần 2: huỷ phiên"; else bad AUC-29d "Huỷ phiên" "không huỷ"; fi
check AUC-29e "Huỷ phiên: hoàn cọc, lô về hàng chờ, không tính lượt" "$(held 9005) $(sql "select status || ' ' || rounds from lots where id = 9105")" "0 READY 0"

echo "== Job ký gửi (chạy 5 phút một lần, lần đầu sau 20 giây)"
if wait_for 330 "select status = 'WITHDRAWN' from consignments where id = 9104"; then ok CON-04 "Không quyết sau 7 ngày: coi như rút"; else bad CON-04 "Hết hạn người bán quyết" "job chưa chạy"; fi
check CON-05 "Sách vô chủ 70 ngày: đã nhắc trước khi thanh lý" "$(sql "select abandon_warned_at is not null from warehouse_items where consignment_id = 9105")" t

echo "== Bảo toàn tiền"
MONEY_AFTER=$(total_money)
check MON-01 "Tổng tiền mọi ví = trước + tiền vào ($MONEY_IN) − tiền rút đã duyệt ($MONEY_OUT)" "$MONEY_AFTER" "$((MONEY_BEFORE + MONEY_IN - MONEY_OUT))"
check MON-02 "Không ví nào âm" "$(sql "select count(*) from wallets where available_balance < 0 or held_balance < 0")" 0

echo
echo "Tổng: $PASS PASS, $FAIL FAIL"
[ $FAIL -eq 0 ] || { printf 'Ca lỗi: %s\n' "${FAILED[*]}"; exit 1; }
