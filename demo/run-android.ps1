# Chay app Android (may ao) noi vao ReBook online qua link Cloudflare.
# Dung tren LAPTOP o truong, trong khi PC nha dang chay start-demo.
#
#   Chay:  demo\run-android.cmd                (nhap dup, script hoi link)
#          demo\run-android.cmd -Link https://xxxx.trycloudflare.com
#          demo\run-android.cmd -Device emulator-5554   (chon thiet bi cu the)
#
# Script se: lay link -> kiem tra link song -> ghi env/android.tunnel.json
#            -> bat may ao neu chua bat -> flutter run.
param(
    [string]$Link,
    [string]$Device
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$fe = Join-Path $repo 'apps\frontend'
$envFile = Join-Path $fe 'env\android.tunnel.json'

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Fail($msg) { Say "LOI: $msg" 'Red'; exit 1 }

# Lay phan https://ten-mien tu chuoi bat ky (bo /api, dau / thua, khoang trang...).
function Get-Origin([string]$s) {
    if (-not $s) { return $null }
    $m = [regex]::Match($s, 'https?://[A-Za-z0-9.-]+(:\d+)?')
    if ($m.Success) { return $m.Value.ToLower() }
    return $null
}

# --- Tim flutter ---
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    foreach ($d in 'D:\flutter\bin', 'C:\flutter\bin', "$env:USERPROFILE\flutter\bin") { if (Test-Path $d) { $env:Path = "$d;$env:Path"; break } }
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Fail 'Khong tim thay flutter. Them thu muc flutter\bin vao PATH roi mo lai cua so.' }

# --- 1. Lay link ---
Say '[1/4] Lay link Cloudflare...' 'Cyan'
$origin = Get-Origin $Link
if (-not $origin) {
    # Goi y: link trong clipboard, hoac demo\LINK.txt (neu dang o PC nha).
    $hint = $null
    try { $hint = Get-Origin ((Get-Clipboard -Raw) -as [string]) } catch { }
    if ($hint -and $hint -notmatch 'trycloudflare\.com') { $hint = $null }
    if (-not $hint) {
        $lf = Join-Path $PSScriptRoot 'LINK.txt'
        if (Test-Path $lf) { $hint = Get-Origin (Get-Content $lf -Raw) }
    }
    if ($hint) {
        Say "      Tim thay link: $hint" 'Yellow'
        $ans = Read-Host '      Nhan Enter de dung link nay, hoac dan link khac'
        $origin = if ($ans.Trim()) { Get-Origin $ans } else { $hint }
    } else {
        $origin = Get-Origin (Read-Host '      Dan link Cloudflare (https://....trycloudflare.com)')
    }
}
if (-not $origin) { Fail 'Link khong hop le. Link phai co dang https://xxxx.trycloudflare.com' }
if ($origin -notmatch '^https://') { Say '      Canh bao: link khong phai https, WebSocket co the khong chay.' 'Yellow' }
Say "      Dung link: $origin" 'Green'

# --- 2. Kiem tra link song ---
Say '[2/4] Kiem tra link tu laptop...' 'Cyan'
$ok = $false
for ($i = 0; $i -lt 3 -and -not $ok; $i++) {
    try { Invoke-WebRequest "$origin/api/categories" -UseBasicParsing -TimeoutSec 10 | Out-Null; $ok = $true }
    catch { Start-Sleep -Seconds 2 }
}
if (-not $ok) {
    Fail "Khong goi duoc $origin/api/categories. PC nha da tat demo, mat mang, hoac link da doi (moi lan bat start-demo la link moi)."
}
Say '      Link OK, backend o nha dang tra loi.' 'Green'

# --- 3. Ghi file env ---
$ws = $origin -replace '^http', 'ws'    # https -> wss, http -> ws
$json = @"
{
  "API_BASE_URL": "$origin/api",
  "WS_BASE_URL": "$ws/ws",
  "USE_MOCK": false,
  "FCM_ENABLED": false,
  "PAYMENT_RETURN_URL": "$origin/payment-return"
}
"@
# Ghi UTF-8 khong BOM de flutter doc duoc.
[IO.File]::WriteAllText($envFile, $json, (New-Object Text.UTF8Encoding $false))
Say "      Da ghi $envFile" 'Gray'

# --- 4. Tim / bat may ao ---
Say '[3/4] Tim may ao Android...' 'Cyan'
function Get-AndroidDevices {
    $ErrorActionPreference = 'Continue'   # flutter in canh bao ra stderr; dung lam dung script
    $out = (flutter devices --machine 2>$null) -join "`n"
    $start = $out.IndexOf('[')
    if ($start -lt 0) { return @() }
    try { $list = $out.Substring($start) | ConvertFrom-Json } catch { return @() }
    # Uu tien may ao, sau do toi dien thoai that cam cap.
    @($list | Where-Object { $_.targetPlatform -like 'android*' } | Sort-Object { -not $_.emulator })
}

# Tim Android SDK (de flutter thay adb/emulator ngay ca khi chua dat ANDROID_HOME).
$sdk = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, "$env:LOCALAPPDATA\Android\Sdk", 'C:\Android\Sdk', 'D:\Android\Sdk') |
    Where-Object { $_ -and (Test-Path (Join-Path $_ 'platform-tools\adb.exe')) } | Select-Object -First 1
if ($sdk -and -not $env:ANDROID_HOME) { $env:ANDROID_HOME = $sdk }
$emuExe = if ($sdk) { Join-Path $sdk 'emulator\emulator.exe' } else { $null }
if ($emuExe -and -not (Test-Path $emuExe)) { $emuExe = $null }

# Danh sach ten may ao (AVD): hoi emulator.exe, neu khong duoc thi doc thu muc .android\avd.
function Get-AvdNames {
    $ErrorActionPreference = 'Continue'
    $names = @()
    if ($emuExe) { $names = @(& $emuExe -list-avds 2>$null | Where-Object { $_ -match '^[\w.-]+$' }) }
    if ($names.Count -eq 0) {
        $avdHome = if ($env:ANDROID_AVD_HOME) { $env:ANDROID_AVD_HOME }
                   elseif ($env:ANDROID_USER_HOME) { Join-Path $env:ANDROID_USER_HOME 'avd' }
                   else { Join-Path $env:USERPROFILE '.android\avd' }
        if (Test-Path $avdHome) { $names = @(Get-ChildItem $avdHome -Filter *.ini | ForEach-Object { $_.BaseName }) }
    }
    $names
}

if (-not $Device) {
    $devs = Get-AndroidDevices
    if ($devs.Count -eq 0) {
        $avds = @(Get-AvdNames)
        if ($avds.Count -eq 0) {
            Say '      Khong tim thay may ao nao.' 'Red'
            if ($sdk) { Say "      Android SDK: $sdk" 'Gray' } else { Say '      Khong tim thay Android SDK (adb.exe).' 'Gray' }
            Say '      Cach sua: mo Android Studio > Device Manager > Create Virtual Device, tao xong bam nut Play.' 'Yellow'
            Say '      Hoac bat san may ao bang Android Studio roi chay lai script nay.' 'Yellow'
            Fail 'Khong co may ao nao.'
        }
        $avd = $avds[0]
        if (-not $emuExe) {
            Say "      Co may ao '$avd' nhung khong tim thay emulator.exe (Android SDK)." 'Red'
            Fail 'Hay bat may ao bang Android Studio (Device Manager > nut Play) roi chay lai script.'
        }
        Say "      Chua co may ao dang chay. Dang bat '$avd' (khoang 30-90 giay)..." 'Yellow'
        Start-Process $emuExe -ArgumentList '-avd', $avd | Out-Null
        for ($i = 0; $i -lt 40 -and $devs.Count -eq 0; $i++) {
            Start-Sleep -Seconds 5
            $devs = Get-AndroidDevices
        }
        if ($devs.Count -eq 0) {
            if (-not $sdk) { Fail 'May ao da bat nhung flutter khong thay. Chay: flutter config --android-sdk <duong dan Android SDK>, roi chay lai.' }
            Fail 'May ao bat qua lau. Doi no hien man hinh chinh roi chay lai script.'
        }
    }
    $Device = $devs[0].id
    Say "      Dung thiet bi: $($devs[0].name) ($Device)" 'Green'
}

# --- 5. Chay app ---
Say '[4/4] flutter run (lan dau build mat vai phut)...' 'Cyan'
Say '      Trong luc chay: r = hot reload, R = hot restart, q = thoat.' 'Gray'
Write-Host ''
Push-Location $fe
try {
    flutter run -d $Device --dart-define-from-file=env/android.tunnel.json
} finally { Pop-Location }
