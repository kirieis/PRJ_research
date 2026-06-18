@echo off
cd /d "%~dp0"
title LUCY Application - Khoi dong
color 0A

echo ========================================================
echo               KHOI DONG HE THONG LUCY
echo ========================================================
echo.
echo Thu muc hien tai: %cd%
echo.

echo [+] Dang khoi dong Content Service (Spring Boot)...
start "LUCY Content Service" cmd /k "cd /d "%~dp0lucy-content-service" && mvnw.cmd spring-boot:run"

echo [+] Dang khoi dong Realtime Service (NodeJS)...
start "LUCY Realtime Service" cmd /k "cd /d "%~dp0lucy-realtime-service" && npm run dev"

echo [+] Dang khoi dong Web Client (Next.js)...
start "LUCY Web Client" cmd /k "cd /d "%~dp0lucy-web-client" && npm run dev"

echo.
echo ========================================================
echo  Dang doi Spring Boot khoi dong va ket noi Database...
echo  Co the mat 30-60 giay, vui long doi...
echo ========================================================
echo.

set count=0

:WAIT_LOOP
set /a count=%count%+1
if %count% GTR 60 goto FAILED

echo   Thu lan %count%/60 - Dang cho backend...

powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8081/api/v1/languages' -UseBasicParsing -TimeoutSec 3; exit 0 } catch { exit 1 }" >nul 2>nul

if %ERRORLEVEL% EQU 0 goto SUCCESS

ping -n 3 127.0.0.1 >nul 2>nul
goto WAIT_LOOP

:SUCCESS
color 0A
echo.
echo ========================================================
echo.
echo   [OK] KET NOI DATABASE THANH CONG!
echo.
echo   API: http://127.0.0.1:8081 -- HOAT DONG
echo   DB:  LucyDB (SQL Server)   -- DA KET NOI
echo.
echo ========================================================
echo.
echo [+] Dang mo trinh duyet...
start http://localhost:3000
echo.
echo   LUCY da khoi dong thanh cong!
echo   KHONG DONG CUA SO NAY!
echo.
pause
goto END

:FAILED
color 0C
echo.
echo ========================================================
echo   [X] LOI: Khong the ket noi Database sau 120 giay!
echo   Vui long kiem tra SQL Server va thu lai.
echo ========================================================
echo.
pause
goto END

:END
