<#
  Reset dữ liệu DEMO của ReBook bằng MỘT lệnh (Windows PowerShell):
      cd apps/backend
      ./scripts/reset-demo.ps1                      # xoá DB, tạo lại, chạy backend, nạp dữ liệu demo
      ./scripts/reset-demo.ps1 -Port 8081 -Db rebook_books
      ./scripts/reset-demo.ps1 -NoStart             # chỉ làm lại DB, không chạy backend

  Việc script làm:
    1. Bật container PostgreSQL (mặc định `rebook-db`) nếu đang tắt.
    2. Tắt backend đang chiếm cổng, ngắt kết nối cũ, xoá và tạo lại database.
    3. Chạy backend ở profile dev: Flyway tạo bảng và nạp dữ liệu mẫu + dữ liệu demo (db/seed). Mọi mốc thời gian
       của dữ liệu demo tính theo lúc này, nên phiên đấu giá "sắp mở" sẽ tự LIVE sau vài phút.
    4. Đợi tới khi API sẵn sàng rồi in tài khoản demo.
  Chạy ngay trước khi gặp thầy; máy nào chạy cũng ra cùng một bộ dữ liệu.
#>
param(
    [string]$Container = 'rebook-db',
    [string]$Db = 'rebook_dev',
    [string]$DbUser = 'rebook',
    [int]$Port = 8080,
    [switch]$NoStart
)
$ErrorActionPreference = 'Stop'
$backend = Split-Path -Parent $PSScriptRoot
Set-Location $backend

function Psql([string]$sql) {
    docker exec $Container psql -U $DbUser -d postgres -v ON_ERROR_STOP=1 -q -c $sql | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "psql lỗi: $sql" }
}

Write-Host '1/4 Bật PostgreSQL...' -ForegroundColor Cyan
if (-not (docker ps --format '{{.Names}}' | Select-String -SimpleMatch $Container)) { docker start $Container | Out-Null; Start-Sleep -Seconds 4 }

Write-Host "2/4 Tắt backend cổng $Port và làm lại database $Db..." -ForegroundColor Cyan
$conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($conn) { Stop-Process -Id $conn.OwningProcess -Force; Start-Sleep -Seconds 2 }
Psql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$Db' AND pid <> pg_backend_pid()"
Psql "DROP DATABASE IF EXISTS $Db"
Psql "CREATE DATABASE $Db OWNER $DbUser ENCODING 'UTF8' TEMPLATE template0"
if ($NoStart) { Write-Host "Đã tạo lại database $Db. Chạy backend (profile dev) để nạp dữ liệu." -ForegroundColor Green; return }

Write-Host '3/4 Chạy backend (Flyway nạp dữ liệu demo)...' -ForegroundColor Cyan
if (Test-Path '.env.local') {
    Get-Content '.env.local' | Where-Object { $_ -match '^\s*[A-Za-z_][A-Za-z0-9_]*=' } | ForEach-Object {
        $k, $v = $_ -split '=', 2
        [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim().Trim('"'), 'Process')
    }
}
$env:SPRING_PROFILES_ACTIVE = 'dev'
$env:REBOOK_DEMO = ',classpath:db/demo'
$env:PORT = "$Port"
$env:DB_URL = "jdbc:postgresql://localhost:5432/$Db"
New-Item -ItemType Directory -Force target | Out-Null
$log = Join-Path $backend 'target/reset-demo.log'
Start-Process -FilePath (Join-Path $backend 'mvnw.cmd') -ArgumentList 'spring-boot:run' -WorkingDirectory $backend `
    -RedirectStandardOutput $log -RedirectStandardError (Join-Path $backend 'target/reset-demo.err.log') -WindowStyle Hidden | Out-Null

Write-Host "4/4 Đợi API sẵn sàng (log: $log)..." -ForegroundColor Cyan
$ok = $false
for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep -Seconds 4
    try { if ((Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/v3/api-docs.yaml" -TimeoutSec 3).StatusCode -eq 200) { $ok = $true; break } } catch { }
}
if (-not $ok) { throw "Backend chưa lên sau 6 phút, xem $log" }

Write-Host ''
Write-Host "Xong. API: http://localhost:$Port (profile dev). Mật khẩu mọi tài khoản: Rebook@123" -ForegroundColor Green
Write-Host '  admin@rebook.vn   staff@rebook.vn'
Write-Host '  seller1@rebook.vn (shop uy tín)  seller2@rebook.vn  seller3@rebook.vn (Đà Nẵng)  seller4@rebook.vn (shop mới, tiền bán còn bị giữ)'
Write-Host '  buyer1..buyer7@rebook.vn   locked@rebook.vn (bị khoá)   banned@rebook.vn (bị cấm đấu giá, có nợ phạt)'
Write-Host 'Phiên đấu giá #3 tự mở sau ~4 phút (buyer1..5 đã đăng ký + cọc). Reset lúc nào thì mốc thời gian dời theo lúc đó.'
