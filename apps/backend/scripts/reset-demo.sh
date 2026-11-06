#!/usr/bin/env bash
# Reset dữ liệu DEMO của ReBook bằng một lệnh (macOS / Linux / Git Bash):
#   cd apps/backend && ./scripts/reset-demo.sh            (tuỳ chọn: PORT=8081 DB=rebook_books ./scripts/reset-demo.sh)
# Xoá và tạo lại database, chạy backend profile dev để Flyway nạp dữ liệu mẫu + dữ liệu demo (db/seed).
# Bản Windows PowerShell: scripts/reset-demo.ps1.
set -euo pipefail
cd "$(dirname "$0")/.."

CONTAINER="${CONTAINER:-rebook-db}"
DB="${DB:-rebook_dev}"
DB_USER="${DB_USER:-rebook}"
PORT="${PORT:-8080}"

psql_admin() { docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 -q -c "$1" >/dev/null; }

echo "1/4 Bật PostgreSQL..."
docker ps --format '{{.Names}}' | grep -qx "$CONTAINER" || { docker start "$CONTAINER" >/dev/null; sleep 4; }

echo "2/4 Làm lại database $DB..."
if command -v lsof >/dev/null 2>&1; then
  pid="$(lsof -ti tcp:"$PORT" -sTCP:LISTEN || true)"; [ -n "$pid" ] && kill -9 $pid && sleep 2
fi
psql_admin "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB' AND pid <> pg_backend_pid()"
psql_admin "DROP DATABASE IF EXISTS $DB"
psql_admin "CREATE DATABASE $DB OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0"
[ "${NO_START:-}" = "1" ] && { echo "Đã tạo lại $DB. Chạy backend (profile dev) để nạp dữ liệu."; exit 0; }

echo "3/4 Chạy backend (Flyway nạp dữ liệu demo)..."
[ -f .env.local ] && { set -a; . ./.env.local; set +a; }
mkdir -p target
REBOOK_DEMO=",classpath:db/demo" SPRING_PROFILES_ACTIVE=dev PORT="$PORT" DB_URL="jdbc:postgresql://localhost:5432/$DB" \
  nohup ./mvnw spring-boot:run > target/reset-demo.log 2>&1 &

echo "4/4 Đợi API sẵn sàng (log: target/reset-demo.log)..."
for _ in $(seq 1 90); do
  sleep 4
  [ "$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT/v3/api-docs.yaml" || true)" = "200" ] && { ok=1; break; }
done
[ "${ok:-}" = "1" ] || { echo "Backend chưa lên, xem target/reset-demo.log"; exit 1; }

echo
echo "Xong. API: http://localhost:$PORT (profile dev). Mật khẩu mọi tài khoản: Rebook@123"
echo "  admin@rebook.vn  staff@rebook.vn  seller1..4@rebook.vn  buyer1..7@rebook.vn  locked@  banned@"
echo "Phiên đấu giá #3 tự mở sau ~4 phút. Mốc thời gian dữ liệu demo tính theo lúc reset."
