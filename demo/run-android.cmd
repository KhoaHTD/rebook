@echo off
title ReBook Android (qua link Cloudflare)
echo === ReBook Android: chay app tren may ao, noi vao link Cloudflare ===
echo.
rem Them "-Link https://xxxx.trycloudflare.com" de khoi phai dan link.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-android.ps1" %*
echo.
echo === Da dung (ma thoat: %errorlevel%). Neu co loi o tren, chup man hinh gui lai. ===
pause
