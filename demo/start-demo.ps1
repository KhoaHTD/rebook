# Bat ReBook ra Internet bang MOT link duy nhat (web + API + WebSocket chung mot cong).
#
#   Backend (cong 8080) phai dang chay san.  Chay:  demo\start-demo.cmd   (nhap dup)
#   Them -Rebuild de build lai web.  Nhan phim bat ky (hoac dong cua so) de tat.
#
# Luong:  trinh duyet --https--> Cloudflare --> cloudflared --> demo_server (cong 8000)
#                                                                 |-- /      file web (build/web)
#                                                                 |-- /api   -> backend :8080
#                                                                 \-- /ws    -> backend :8080 (WebSocket)
param(
    [switch]$Rebuild,
    [int]$Port = 8000,
    [string]$Backend = 'http://localhost:8080'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$fe = Join-Path $repo 'apps\frontend'
$stamp = Join-Path $fe 'build\web\.built-for-tunnel'
$logDir = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Force $logDir | Out-Null

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Fail($msg) { Say "LOI: $msg" 'Red'; Read-Host 'Nhan Enter de dong'; exit 1 }

# --- Tim cong cu ---
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    foreach ($d in 'D:\flutter\bin', 'C:\flutter\bin') { if (Test-Path $d) { $env:Path = "$d;$env:Path"; break } }
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Fail 'Khong tim thay flutter (can D:\flutter\bin trong PATH).' }

$cf = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
if (-not $cf) { $cf = @('D:\Tools\cloudflared\cloudflared.exe', "$env:ProgramFiles\cloudflared\cloudflared.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1 }
if (-not $cf) { Fail 'Khong tim thay cloudflared.exe (tai ve D:\Tools\cloudflared\ - xem docs\DEMO_ONLINE.md).' }

# --- 1. Backend ---
Say '[1/4] Kiem tra backend...' 'Cyan'
try { Invoke-WebRequest "$Backend/categories" -UseBasicParsing -TimeoutSec 5 | Out-Null }
catch { Fail "Backend chua chay o $Backend. Mo IntelliJ, chay ReBookApplication, doi 'Started ReBookApplication' roi chay lai." }
Say '      Backend OK.' 'Green'

# --- 2. Build web (chi khi can) ---
Say '[2/4] Kiem tra ban build web...' 'Cyan'
if ($Rebuild -or -not (Test-Path $stamp)) {
    Say '      Dang build web (khoang 1-2 phut)...' 'Yellow'
    Push-Location $fe
    try {
        flutter pub get | Out-Null
        flutter build web --dart-define-from-file=env/tunnel.json
        if ($LASTEXITCODE -ne 0) { Fail 'Build web that bai.' }
        Set-Content $stamp (Get-Date -Format o)
    } finally { Pop-Location }
}
Say '      Web san sang.' 'Green'

# --- 3. Proxy + tunnel ---
$procs = @()
function Stop-All {
    foreach ($p in $script:procs) { if ($p -and -not $p.HasExited) { & taskkill /PID $p.Id /T /F | Out-Null } }
}

# Chan may ngu trong luc script chay (chi co hieu luc khi script con song).
Add-Type -Namespace Win -Name Power -MemberDefinition '[System.Runtime.InteropServices.DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
[void][Win.Power]::SetThreadExecutionState([uint32]2147483649)

try {
    Say "[3/4] Bat may chu demo (cong $Port)..." 'Cyan'
    & (Join-Path $PSScriptRoot 'stop-demo.ps1') -Port $Port | Out-Null   # don tien trinh cu con sot
    $busy = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($busy) { Fail "Cong $Port dang bi chiem (PID $($busy[0].OwningProcess)). Tat chuong trinh do hoac dung -Port 8001." }
    $proxy = Start-Process cmd.exe -ArgumentList '/c', "dart run tool/demo_server.dart --port $Port --backend $Backend > `"$logDir\proxy.log`" 2>&1" `
        -WorkingDirectory $fe -WindowStyle Hidden -PassThru
    $procs += $proxy
    $ok = $false
    for ($i = 0; $i -lt 120; $i++) {
        Start-Sleep -Milliseconds 750
        try { if ((Invoke-WebRequest "http://127.0.0.1:$Port/__health" -UseBasicParsing -TimeoutSec 2).Content -eq 'ok') { $ok = $true; break } } catch { }
    }
    if (-not $ok) { Fail "May chu demo khong len. Xem $logDir\proxy.log" }
    Say '      May chu demo OK.' 'Green'

    Say '[4/4] Mo tunnel Cloudflare...' 'Cyan'
    $tlog = Join-Path $logDir 'tunnel.log'
    Remove-Item $tlog -ErrorAction SilentlyContinue
    $tunnel = Start-Process $cf -ArgumentList 'tunnel', '--url', "http://127.0.0.1:$Port", '--no-autoupdate', '--logfile', $tlog `
        -WindowStyle Hidden -PassThru
    $procs += $tunnel
    $url = $null
    for ($i = 0; $i -lt 60 -and -not $url; $i++) {
        Start-Sleep -Seconds 1
        if ($tunnel.HasExited) { Fail "cloudflared bi thoat. Xem $tlog" }
        if (Test-Path $tlog) {
            $m = Select-String -Path $tlog -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($m) { $url = $m.Matches[0].Value }
        }
    }
    if (-not $url) { Fail "Khong lay duoc link tunnel. Xem $tlog" }

    # Link moi tao can vai giay de DNS lan ra; thu tu den khi truy cap duoc.
    $live = $false
    for ($i = 0; $i -lt 30 -and -not $live; $i++) {
        try { if ((Invoke-WebRequest "$url/__health" -UseBasicParsing -TimeoutSec 5).Content -eq 'ok') { $live = $true } } catch { Start-Sleep -Seconds 2 }
    }
    Set-Content (Join-Path $PSScriptRoot 'LINK.txt') $url
    try { Set-Clipboard $url } catch { }

    Write-Host ''
    Say '==============================================================' 'Green'
    Say '  ReBook dang online. Gui link nay cho ban be:' 'Green'
    Write-Host ''
    Say "      $url" 'Yellow'
    Write-Host ''
    if ($live) { Say '  (Da kiem tra: link truy cap duoc tu Internet. Link da duoc copy.)' 'Green' }
    else { Say '  (Chua kiem tra duoc tu ngoai - doi 1 phut roi thu mo link.)' 'Yellow' }
    Say '  Tai khoan: buyer1@rebook.vn / Rebook@123' 'Gray'
    Say '  GIU CUA SO NAY MO. Nhan phim bat ky de tat ca he thong.' 'Gray'
    Say '==============================================================' 'Green'

    # --- Giu song, canh chung ---
    $warned = $false
    while ($true) {
        try { if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); break } } catch { }
        if ($proxy.HasExited) { Say 'May chu demo da dung! Xem logs\proxy.log' 'Red'; break }
        if ($tunnel.HasExited) { Say 'Tunnel da dung! Chay lai script de lay link moi.' 'Red'; break }
        try { Invoke-WebRequest "$Backend/categories" -UseBasicParsing -TimeoutSec 5 | Out-Null; $warned = $false }
        catch { if (-not $warned) { Say "$(Get-Date -Format HH:mm:ss) CANH BAO: backend khong tra loi." 'Red'; $warned = $true } }
        Start-Sleep -Seconds 5
    }
} finally {
    Stop-All
    [void][Win.Power]::SetThreadExecutionState([uint32]2147483648)
    Say 'Da tat may chu demo va tunnel.' 'Gray'
}
