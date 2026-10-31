@echo off
title ReBook online
echo === ReBook online: dang khoi dong, vui long doi... ===
echo.
rem Them tham so "-Rebuild" de build lai web.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-demo.ps1" %*
echo.
echo === Da dung (ma thoat: %errorlevel%). Neu co loi o tren, chup man hinh gui lai. ===
pause
