@echo off
title ReBook online (build lai web)
echo === ReBook online: build lai web roi mo link, mat khoang 1-2 phut, vui long doi... ===
echo.
rem Giong start-demo.cmd nhung luon build lai web (dung khi code frontend vua thay doi / vua pull ve).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-demo.ps1" -Rebuild %*
echo.
echo === Da dung (ma thoat: %errorlevel%). Neu co loi o tren, chup man hinh gui lai. ===
pause
