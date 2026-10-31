# Tat het tien trinh demo con sot lai (may chu demo cong 8000 + cloudflared).
# Dung khi lo dong cua so start-demo bang tay, hoac muon chac chan da tat link.
param([int]$Port = 8000)

$n = 0
Get-Process cloudflared -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.Id -Force; $n++ }

$listen = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
foreach ($c in $listen) {
    $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    # Chi tat neu la dart (may chu demo cua minh), tranh tat nham chuong trinh khac.
    if ($p -and $p.ProcessName -like 'dart*') { & taskkill /PID $p.Id /T /F | Out-Null; $n++ }
    elseif ($p) { Write-Host "Cong $Port dang do '$($p.ProcessName)' (PID $($p.Id)) chiem, khong phai may chu demo - khong tat." -ForegroundColor Yellow }
}
Remove-Item (Join-Path $PSScriptRoot 'LINK.txt') -ErrorAction SilentlyContinue
Write-Host "Da tat $n tien trinh. Link cu khong con dung duoc." -ForegroundColor Green
