@echo off
cd /d "%~dp0"
title LUCY Application - Startup
color 0B

echo ========================================================
echo               STARTING LUCY MICROSERVICES
echo ========================================================
echo.
echo [+] Starting Content Service (Spring Boot) on Port 8081...
start "LUCY Content Service (8081)" cmd /k "cd /d "%~dp0lucy-content-service" && mvnw.cmd spring-boot:run"

echo [+] Starting Auth Service (.NET) on Port 5086...
start "LUCY Auth Service (5086)" cmd /k "cd /d "%~dp0lucy-auth-service" && dotnet run"

echo [+] Starting Realtime Service (NodeJS) on Port 3001...
start "LUCY Realtime Service (3001)" cmd /k "cd /d "%~dp0lucy-realtime-service" && npm run dev"

echo [+] Starting Web Client (Next.js) on Port 3000...
start "LUCY Web Client (3000)" cmd /k "cd /d "%~dp0lucy-web-client" && npm run dev"

echo.
echo ========================================================
echo   Services are starting up in separate windows.
echo   Please wait 10-15 seconds for all services to boot.
echo ========================================================
echo.
echo   [1] Web Client      : http://localhost:3000
echo   [2] Realtime Socket : ws://localhost:3001
echo   [3] Auth API (.NET) : http://localhost:5086
echo   [4] Content API     : http://localhost:8081
echo.
echo   DO NOT CLOSE THIS WINDOW to keep this summary visible.
echo ========================================================
echo.
pause
