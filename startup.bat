@echo off
title LUCY Application - Khởi động
echo ========================================================
echo               KHOI DONG HE THONG LUCY
echo ========================================================
echo.

echo [+] Dang khoi dong Content Service (Spring Boot)...
start "LUCY Content Service" cmd /k "cd lucy-content-service && mvnw.cmd spring-boot:run"

echo [+] Dang khoi dong Realtime Service (NodeJS)...
start "LUCY Realtime Service" cmd /k "cd lucy-realtime-service && npm run dev"

echo [+] Dang khoi dong Web Client (Next.js)...
start "LUCY Web Client" cmd /k "cd lucy-web-client && npm run dev"

echo.
echo [+] Dang doi cac dich vu san sang khoi chay...
timeout /t 5

echo [+] Dang mo ung dung tren trinh duyet...
start http://localhost:3000

echo.
echo ========================================================
echo   LUCY da duoc khoi dong thanh cong!
echo   Giu cac cua so dong lenh mo de duy tri ket noi.
echo ========================================================
exit
