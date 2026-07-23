@echo off
cd /d "%~dp0"
title LUCY Application - Startup
color 0B

echo ========================================================
echo            STARTING LUCY CONSOLIDATED SYSTEM
echo ========================================================
echo.
echo [+] Setting environment variables...
set NEXT_PUBLIC_AGORA_APP_ID=ef8ac89bf2ac4e29ba2bc768bdeeca7c
set AGORA_APP_ID=ef8ac89bf2ac4e29ba2bc768bdeeca7c
set AGORA_APP_CERTIFICATE=9e9888e288ea4b689265b53fd1d59a32

echo [+] Starting LUCY Backend (Auth + Wallet + Realtime + Webhook + Content) on Port 3001...
start "LUCY Backend (3001)" cmd /k "cd /d "%~dp0lucy-realtime-service" && npm run dev"

echo [+] Starting LUCY Web Client (Next.js) on Port 3000...
start "LUCY Web Client (3000)" cmd /k "cd /d "%~dp0lucy-web-client" && npm run dev"

echo [+] Starting Ngrok Tunnel for FULL Web (Port 3000)...
start "LUCY Ngrok Tunnel" cmd /k "cd /d "%~dp0" && .\ngrok.exe http 3000"

echo.
echo ========================================================
echo   Services are booting up!
echo ========================================================
echo.
echo   [1] Local Web Client      : http://localhost:3000
echo   [2] Local Realtime ^& APIs : http://localhost:3001
echo   [3] FULL NGROK PUBLIC URL  : Check Ngrok window!
echo                                (e.g. https://xxx.ngrok-free.app)
echo.
echo   * Webhook SePay URL: https://^<NGROK_URL^>/api/wallet/sepay-webhook
echo   * Share Room / Call: Copy link from browser or click "Moi Ban Be"!
echo.
echo   DO NOT CLOSE THIS WINDOW to keep this summary visible.
echo ========================================================
echo.
pause
