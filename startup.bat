@echo off
title Project LUCY - Startup Services Gateway
color 0B
echo ============================================================
echo    STARTING PROJECT LUCY BACKEND SERVICES GATEWAY
echo ============================================================
echo.

rem ------------------------------------------------------------
rem SET LOCAL ENVIRONMENT FOR JAVA 17 & .NET 8
rem ------------------------------------------------------------
echo [Environment] Configuring JDK 17 and .NET 8 paths...

rem Point JAVA_HOME locally to the newly installed Temurin JDK 17
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"

rem ------------------------------------------------------------
rem PRE-FLIGHT CHECKS
rem ------------------------------------------------------------
echo [Pre-flight] Checking required tools...

rem Check Node.js
where node >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Node.js is NOT installed. Please install from https://nodejs.org/
    pause
    exit /b 1
)
echo    Node.js is installed.

rem Check npm
where npm >nul 2>nul
if errorlevel 1 (
    echo [ERROR] npm is NOT installed.
    pause
    exit /b 1
)
echo    npm is installed.

rem Check Java 17
java -version 2>&1 | findstr "17." >nul
if errorlevel 1 (
    echo [WARN] Java 17 is not active in this session. Spring Boot may fail.
) else (
    echo    Java 17 is configured and active.
)

rem Check .NET SDK (optional for Auth service)
set DOTNET_AVAILABLE=1
where dotnet >nul 2>nul
if errorlevel 1 (
    echo [WARN] .NET SDK is NOT installed. Auth service will not start.
    set DOTNET_AVAILABLE=0
) else (
    echo    .NET SDK is installed.
)

echo.
echo ============================================================
echo    PORT MAPPING
echo ------------------------------------------------------------
echo    .NET Auth Service:       http://localhost:5086
echo    Java Spring Boot:        http://localhost:8081
echo    Node.js Realtime:        http://localhost:3001
echo ============================================================
echo.

rem ------------------------------------------------------------
rem 1. Check Node.js dependencies
rem ------------------------------------------------------------
echo [Step 0] Checking Node.js dependencies...
if not exist "lucy-realtime-service\node_modules" (
    echo    node_modules not found. Running npm install...
    cd lucy-realtime-service
    call npm install
    cd ..
    echo    npm install complete.
) else (
    echo    node_modules found. Skipping install.
)
echo.

rem ------------------------------------------------------------
rem 2. Start .NET Auth Service (Port 5086)
rem ------------------------------------------------------------
if "%DOTNET_AVAILABLE%"=="1" (
    echo [Step 1] Starting .NET Auth and Financial Service...
    start "LUCY .NET Auth Service Port 5086" cmd /k "cd lucy-auth-service && dotnet run --launch-profile http"
    timeout /t 3 >nul
) else (
    echo [Step 1] SKIPPED - .NET SDK not available.
)
echo.

rem ------------------------------------------------------------
rem 3. Start Java Spring Boot Service (Port 8081)
rem ------------------------------------------------------------
echo [Step 2] Starting Java Spring Boot Content Service...
start "LUCY Spring Boot Service Port 8081" cmd /k "set \"JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot\" && set \"PATH=%%JAVA_HOME%%\bin;%%PATH%%\" && cd lucy-content-service && mvnw.cmd spring-boot:run"
timeout /t 3 >nul
echo.

rem ------------------------------------------------------------
rem 4. Start Node.js Realtime Service (Port 3001)
rem ------------------------------------------------------------
echo [Step 3] Starting Node.js Realtime Service...
start "LUCY Node.js Realtime Service Port 3001" cmd /k "cd lucy-realtime-service && npm run dev"
echo.

rem ------------------------------------------------------------
rem 5. Finish
rem ------------------------------------------------------------
echo ============================================================
echo    ALL SERVICES LAUNCHED!
echo ------------------------------------------------------------
echo    .NET Auth:       http://localhost:5086
echo    Java Spring:     http://localhost:8081
echo    Swagger UI:      http://localhost:8081/swagger-ui/index.html
echo    Node.js Health:  http://localhost:3001/api/health
echo ============================================================
echo.

echo Waiting 8 seconds for services to warm up...
timeout /t 8 >nul

echo Opening Swagger API and Realtime Healthcheck in browser...
start http://localhost:8081/swagger-ui/index.html
start http://localhost:3001/api/health

echo.
echo Done. Press any key to close this launcher window.
pause >nul
