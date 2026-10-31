# Bat dau NGAY mot phien dau gia (admin bam "start"). Dung khi demo, thay vi cho den gio bat dau.
#   demo\start-auction.ps1 -Session 1
# Chu y: moi nguoi phai dang ky + dat coc TRUOC khi bat dau (phien da bat dau thi khong dang ky duoc nua).
param(
    [Parameter(Mandatory = $true)][int]$Session,
    [string]$Api = 'http://localhost:8080',
    [string]$Email = 'admin@rebook.vn',
    [string]$Password = 'Rebook@123'
)
$ErrorActionPreference = 'Stop'
$login = Invoke-RestMethod "$Api/auth/login" -Method Post -ContentType 'application/json' `
    -Body (@{ email = $Email; password = $Password } | ConvertTo-Json)
$h = @{ Authorization = "Bearer $($login.accessToken)" }
try {
    $s = Invoke-RestMethod "$Api/admin/sessions/$Session/start" -Method Post -Headers $h
    Write-Host "Da bat dau phien $Session -> $($s.status)" -ForegroundColor Green
} catch {
    $msg = $_.ErrorDetails.Message
    Write-Host "Khong bat dau duoc phien $Session : $msg" -ForegroundColor Red
    Write-Host 'Thuong gap: phien chua cong bo (PUBLISHED), chua du nguoi dang ky, hoac da bat dau / ket thuc roi.'
    exit 1
}
