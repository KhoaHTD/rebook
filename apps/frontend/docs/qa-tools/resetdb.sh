#!/usr/bin/env bash
# Dừng backend, tạo lại database dev, chạy backend (nạp dữ liệu mẫu), chờ sẵn sàng.
B=/d/Study/FPTUniversity/Semester8/PRM393/rebook/apps/backend
L="C:/Users/Lenovo/AppData/Local/Temp/claude/5ea0f9c3a2726979/309d5caa-794f-4c71-bdb8-aa18b8d6db57/scratchpad/backend.log"
P=$(powershell -NoProfile -Command "(Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue).OwningProcess")
[ -n "$P" ] && powershell -NoProfile -Command "Stop-Process -Id $P -Confirm:\$false"
sleep 2
docker exec rebook-db psql -U rebook -d postgres -c "DROP DATABASE IF EXISTS rebook_dev WITH (FORCE)" -c "CREATE DATABASE rebook_dev OWNER rebook ENCODING 'UTF8' TEMPLATE template0" | tail -1
cd "$B" || exit 1
: > "$L"
(nohup ./mvnw -q spring-boot:run > "$L" 2>&1 &)
for i in $(seq 1 60); do grep -qE "Started ReBookApplication|APPLICATION FAILED|Application run failed" "$L" && break; sleep 2; done
grep -cE "Started ReBookApplication" "$L"
curl -s -m 3 http://localhost:8081/actuator/health; echo
