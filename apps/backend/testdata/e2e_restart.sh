#!/usr/bin/env bash
# =====================================================================
# Hell case: backend khởi động lại khi phiên đấu giá đang chạy (docs/ra-soat-nghiep-vu/TEST_PLAN_TOAN_DIEN.md phần A, T-AUC-18).
# Dùng phiên 9003 trong testdata/e2e_personas.sql (mỗi lô 60 giây). Cách chạy:
#   psql ... -f testdata/e2e_personas.sql
#   bash testdata/e2e_restart.sh part1      # đăng ký, mở phiên, trả giá
#   (tắt backend, bật lại, chờ "Started ReBookApplication" — làm trong vòng ~40 giây)
#   bash testdata/e2e_restart.sh part2      # kiểm phiên chạy tiếp từ trạng thái trong DB
# =====================================================================
set -u
API=${API:-http://localhost:8080}
PSQL=${PSQL:-psql -h localhost -U rebook -d rebook_dev -tA}
PASS=0; FAIL=0
sql() { $PSQL -c "$1" 2>/dev/null | head -1; }
check() { if [ "$3" = "$4" ]; then PASS=$((PASS + 1)); echo "  PASS $1 $2"; else FAIL=$((FAIL + 1)); echo "  FAIL $1 $2 (được '$3', mong '$4')"; fi; }
req() {
  local auth=() body=()
  [ -n "$1" ] && auth=(-H "Authorization: Bearer $1")
  [ $# -ge 4 ] && body=(-H 'Content-Type: application/json' -d "$4")
  curl -s -o /tmp/e2e_body -w '%{http_code}' -X "$2" ${auth[@]+"${auth[@]}"} ${body[@]+"${body[@]}"} "$API$3"
}
login() { req '' POST /auth/login '{"email":"'"$1"'","password":"Rebook@123"}' >/dev/null; jq -r .accessToken /tmp/e2e_body; }
wait_for() { local i; for ((i = 0; i < $1; i += 2)); do [ "$(sql "$2")" = "t" ] && return 0; sleep 2; done; return 1; }

RICH=$(login e2e.buyer.rich@rebook.vn); A=$(login e2e.bidder.a@rebook.vn); ADMIN=$(login admin@rebook.vn)
case "${1:-}" in
  part1)
    req "$RICH" POST /sessions/9003/register '{"agreeRules":true}' >/dev/null
    req "$A" POST /sessions/9003/register '{"agreeRules":true}' >/dev/null
    check RST-01 "Admin mở phiên" "$(req "$ADMIN" POST /admin/sessions/9003/start)" 200
    wait_for 15 "select status = 'OPEN' from lots where id = 9106" && check RST-02 "Lô mở" ok ok || check RST-02 "Lô mở" no ok
    check RST-03 "RICH trả giá trước khi tắt backend" "$(req "$RICH" POST /lots/9106/bids '{"amount":150000}')" 200
    echo "ends_at trước khi tắt: $(sql "select ends_at from lots where id = 9106")"
    echo ">>> Tắt và bật lại backend NGAY, rồi chạy: bash testdata/e2e_restart.sh part2"
    ;;
  part2)
    check RST-04 "Sau khi bật lại: phiên vẫn LIVE, lô vẫn OPEN, giữ giá và người dẫn" \
      "$(sql "select s.status || ' ' || l.status || ' ' || l.current_price || ' ' || l.current_winner_id from auction_sessions s join lots l on l.session_id = s.id where s.id = 9003")" \
      "LIVE OPEN 150000 9001"
    check RST-05 "Trả giá tiếp được sau khi bật lại" "$(req "$A" POST /lots/9106/bids '{"amount":200000}')" 200
    wait_for 90 "select status = 'ENDED' from auction_sessions where id = 9003" && check RST-06 "Phiên chạy tới cuối" ok ok || check RST-06 "Phiên chạy tới cuối" no ok
    check RST-07 "Lô bán cho người trả sau khi bật lại; người thua được hoàn cọc" \
      "$(sql "select status || ' ' || winner_id from lots where id = 9106") $(sql "select held_balance from wallets where user_id = 9001")" "SOLD 9008 0"
    ;;
  *) echo "Dùng: $0 part1 | part2"; exit 2 ;;
esac
echo "Tổng: $PASS PASS, $FAIL FAIL"
[ $FAIL -eq 0 ]
