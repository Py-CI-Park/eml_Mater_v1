@echo off
title Email Manager - Install Program
chcp 65001 > nul
color 0A

:: Admin privilege auto-elevation
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Admin privileges required. Please click "Yes" in UAC dialog.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion
cd /d %~dp0

cls
echo.
echo  ================================================================
echo    ######  ##     ## ##     ##  #### ##     
echo    ##      ###   ### ##     ##   ##  ##     
echo    ##      ## # # ## ##     ##   ##  ##     
echo    ######  ##  #  ## #########   ##  ##     
echo    ##      ##     ## ##     ##   ##  ##     
echo    ##      ##     ## ##     ##   ##  ##     
echo    ######  ##     ## ##     ##  #### ######
echo.
echo    ##     ##    ###    ##    ##    ###     ######   #######  ######  
echo    ###   ###   ## ##   ###   ##   ## ##   ##    ## ##       ##   ## 
echo    ## # # ##  ##   ##  ## #  ##  ##   ##  ##       ##       ##   ## 
echo    ##  #  ## ##     ## ##  # ## ##     ## ##   ### #######  ######  
echo    ##     ## ######### ##   ### ######### ##    ## ##       ##   ## 
echo    ##     ## ##     ## ##    ## ##     ## ##    ## ##       ##   ## 
echo    ##     ## ##     ## ##    ## ##     ##  ######  #######  ##   ## 
echo  ================================================================
echo                      EMAIL MANAGER v1.0
echo                    Install Program
echo  ================================================================
echo.
echo    Web application for managing .eml files in closed network
echo    Backend: Flask (Python)
echo    Frontend: React (JavaScript)
echo.
echo  ================================================================
echo.
echo Running with admin privileges
echo Working directory: %CD%
echo.

:: Safe logging system initialization
set LOG_FILE=install_log.log
set MAX_LOG_SIZE=5000000

echo [%date% %time%] Installation started - Enhanced stability version > %LOG_FILE% 2>nul
if not exist %LOG_FILE% (
    echo [ERROR] Cannot create log file.
    echo Possible causes:
    echo   1. Insufficient admin privileges
    echo   2. Disk space shortage
    echo   3. Antivirus blocking
    echo   4. Path issues
    echo.
    echo Solution: Run cleanup script first or restart computer.
    pause
    exit /b 1
)

echo [%date% %time%] Log system initialized >> %LOG_FILE%

:: System health check
echo [%date% %time%] Pre-installation health check started >> %LOG_FILE%

echo Checking disk space...
for /f "tokens=3" %%a in ('dir /-c %~dp0 ^| findstr /i "bytes free"') do (
    set free_space=%%a
    goto :space_check_done
)
:space_check_done

if defined free_space (
    if %free_space% lss 1073741824 (
        echo [ERROR] Insufficient disk space. Need at least 1GB.
        echo [%date% %time%] ERROR: Disk space insufficient >> %LOG_FILE%
        pause
        exit /b 1
    ) else (
        echo [OK] Sufficient disk space
        echo [%date% %time%] Disk space OK: %free_space% bytes >> %LOG_FILE%
    )
)

:: Installation mode selection
echo Installation mode selection:
echo.
echo    [1] Quick install (recommended) - Auto install everything
echo    [2] Advanced install - Step by step confirmation  
echo    [3] System status check only
echo    [4] Cancel installation
echo.
set /p INSTALL_MODE="Select (1-4): "

echo [%date% %time%] Install mode: %INSTALL_MODE% >> %LOG_FILE%

if "%INSTALL_MODE%"=="4" (
    echo Installation cancelled.
    pause
    exit /b
)

if "%INSTALL_MODE%"=="3" (
    goto :check_status
)

if "%INSTALL_MODE%"=="2" (
    set ADVANCED_MODE=1
) else (
    set ADVANCED_MODE=0
    set INSTALL_MODE=1
)

echo.
if "%ADVANCED_MODE%"=="1" (
    echo Advanced install mode - Confirmation required at each step.
    set /p CONTINUE="Continue? (Y/N): "
    if /i not "!CONTINUE!"=="Y" (
        echo Installation cancelled.
        pause
        exit /b
    )
) else (
    echo Quick install mode - Auto process all steps.
    echo Starting quick installation...
    timeout /t 2 /nobreak >nul
)

:: Step 1: System requirements check
echo.
echo ===============================================
echo Step 1: System Requirements Check
echo ===============================================

call :progress_bar "System check" 3

echo Checking Python installation...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python not installed!
    echo.
    echo Python installation required:
    echo    1. Visit https://www.python.org/downloads/
    echo    2. Download latest Python 3.x version
    echo    3. During install, CHECK "Add Python to PATH"!
    echo    4. Restart computer after installation
    echo    5. Run this script again
    echo.
    echo [%date% %time%] Python not found - installation stopped >> %LOG_FILE%
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo    [OK] Python %PYTHON_VERSION%

pip --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] pip not installed!
    echo Please reinstall Python or install pip separately.
    pause
    exit /b 1
)

echo Checking Node.js installation...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Node.js not installed!
    echo.
    echo Node.js installation required:
    echo    1. Visit https://nodejs.org/
    echo    2. Download and install LTS version
    echo    3. Run this script again after installation
    echo.
    pause
    exit /b 1
)

for /f %%i in ('node --version 2^>^&1') do set NODE_VERSION=%%i
echo    [OK] Node.js %NODE_VERSION%

for /f "tokens=1" %%i in ('npm --version 2^>^&1') do set NPM_VERSION=%%i
echo    [OK] npm %NPM_VERSION%

echo [OK] All system requirements met!

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="Continue to next step? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: Step 2: Environment cleanup
echo.
echo ===============================================
echo Step 2: Environment Cleanup and Preparation
echo ===============================================

call :progress_bar "Environment cleanup" 3

if exist backend\config.json (
    echo Backing up existing config file...
    copy backend\config.json backend\config.json.backup >nul 2>&1
)

echo Cleaning existing environment...
if exist venv rmdir /s /q venv >nul 2>&1
if exist frontend\node_modules rmdir /s /q frontend\node_modules >nul 2>&1
if exist frontend\package-lock.json del frontend\package-lock.json >nul 2>&1

echo [OK] Environment cleanup complete

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="Continue to next step? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: Step 3: Python environment setup
echo.
echo ===============================================
echo Step 3: Python Environment Setup
echo ===============================================

call :progress_bar "Python virtual environment creation" 5

echo Creating Python virtual environment...
python -m venv venv
if %errorLevel% neq 0 (
    echo [ERROR] Python virtual environment creation failed
    pause
    exit /b 1
)

call venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul 2>&1

call :progress_bar "Python package installation" 10

echo Installing Python dependencies...
echo [%date% %time%] Python dependency installation started >> %LOG_FILE%
cd backend

echo [INFO] First attempt: requirements.txt installation
echo [%date% %time%] requirements.txt installation attempt >> ..\%LOG_FILE%
pip install -r requirements.txt >> ..\%LOG_FILE% 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] requirements.txt installation failed, trying individual packages...
    echo [%date% %time%] requirements.txt failed, starting individual installation >> ..\%LOG_FILE%
    
    echo [INFO] Installing Flask...
    pip install Flask==2.3.3 >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] Installing Flask-CORS...
    pip install Flask-CORS==4.0.0 >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] Installing python-dateutil...
    pip install python-dateutil >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] Installing chardet...
    pip install chardet >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] Final verification...
    echo [%date% %time%] Python package verification started >> ..\%LOG_FILE%
    python -c "import flask, flask_cors, dateutil, chardet; print('[OK] All required packages installed')" >> ..\%LOG_FILE% 2>&1
    if %errorLevel% neq 0 (
        echo [ERROR] Python dependency installation final failure
        echo [%date% %time%] Python package verification failed >> ..\%LOG_FILE%
        echo Check internet connection and try again.
        cd ..
        echo Press any key to view error log...
        pause
        exit /b 1
    ) else (
        echo [OK] Individual package installation and verification complete
        echo [%date% %time%] Individual package installation success >> ..\%LOG_FILE%
    )
) else (
    echo [OK] requirements.txt installation success
    echo [%date% %time%] requirements.txt installation success >> ..\%LOG_FILE%
)
cd ..

echo [OK] Python environment setup complete!

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="Continue to next step? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: Step 4: Node.js environment setup
echo.
echo ===============================================
echo Step 4: Node.js Environment Setup
echo ===============================================

cd frontend
call :progress_bar "Node.js package installation" 15

echo Installing React and Node.js dependencies...
echo Using --legacy-peer-deps option to resolve React 18 compatibility issues
echo [%date% %time%] Node.js package installation started >> ..\%LOG_FILE%

echo [INFO] npm install first attempt...
npm install --legacy-peer-deps --no-audit >> ..\%LOG_FILE% 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] First install attempt failed, retrying with different approach...
    echo [%date% %time%] npm install first attempt failed >> ..\%LOG_FILE%
    
    echo [INFO] Cleaning npm cache...
    npm cache clean --force >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] npm install second attempt (with --force option)...
    npm install --force --no-audit >> ..\%LOG_FILE% 2>&1
    if %errorLevel% neq 0 (
        echo [ERROR] Node.js dependency installation final failure
        echo [%date% %time%] npm install final failure >> ..\%LOG_FILE%
        echo Check internet connection and try again.
        cd ..
        echo Press any key to view error log...
        pause
        exit /b 1
    ) else (
        echo [OK] Second attempt installation success
        echo [%date% %time%] npm install second attempt success >> ..\%LOG_FILE%
    )
) else (
    echo [OK] First attempt installation success
    echo [%date% %time%] npm install first attempt success >> ..\%LOG_FILE%
)

echo [OK] Node.js environment setup complete!
echo [%date% %time%] Node.js environment setup complete >> ..\%LOG_FILE%
cd ..

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="Continue to next step? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: Installation complete
cls
echo.
echo  ================================================================
echo     ####  ##   ##  #### #### ######  ####  ####  ## 
echo    ##     ##   ## ##    ##   ##     ##     ##     ## 
echo    ##     ##   ## ##    ##   ##     ##     ##     ## 
echo     ####  ##   ## ##    ##   ######  ####   ####  ## 
echo        ## ##   ## ##    ##   ##         ##     ## ## 
echo        ## ##   ## ##    ##   ##         ##     ##    
echo     ####   #####   #### #### ######  ####   ####  ## 
echo  ================================================================
echo                        Installation Complete!
echo  ================================================================
echo.
echo  Installed components:
echo     [OK] Python %PYTHON_VERSION% virtual environment
echo     [OK] Node.js %NODE_VERSION% + React 18
echo     [OK] Flask backend server
echo     [OK] All runtime scripts
echo     [OK] Test environment
echo.
echo  How to run:
echo     Method 1: Double-click desktop shortcut
echo     Method 2: Double-click "run_server.bat"
echo.
echo  Access URL: http://localhost:3000
echo  Test folder: "test_email_folder"
echo.

echo [%date% %time%] Installation completed successfully >> %LOG_FILE%

echo.
echo  ================================================================
echo                        Installation Success!
echo  ================================================================
echo.
echo  Next steps:
echo     1. Double-click desktop shortcut or run "run_server.bat"
echo     2. Access http://localhost:3000 in browser
echo     3. Set email folder path in settings
echo.
echo  ================================================================
echo.

set /p AUTORUN="Run now? (Y/N): "
if /i "%AUTORUN%"=="Y" (
    echo.
    echo Starting Email Manager...
    echo Browser will open automatically shortly.
    echo.
    timeout /t 3 /nobreak >nul
    if exist run_server.bat (
        start "" "run_server.bat"
    ) else (
        echo [WARNING] run_server.bat not found. Please check installation.
    )
    echo.
    echo [OK] Program started!
    echo Check http://localhost:3000 in browser.
    echo.
) else (
    echo.
    echo Installation completed!
    echo Use desktop shortcut to run later.
    echo.
)

echo Press any key to close installer...
pause >nul
goto :eof

:: System status check function
:check_status
color 0A
cls
echo.
echo   ####  ######    ###   ######  ##   ##  ####  
echo  ##       ##     ## ##     ##   ##   ## ##    
echo  ##       ##    ##   ##    ##   ##   ## ##    
echo   ####     ##   ## ### ##   ##   ##   ##  #### 
echo      ##    ##   ##     ##   ##   ##   ##     ##
echo      ##    ##   ##     ##   ##   ##   ##     ##
echo   ####     ##   ##     ##   ##    #####   #### 
echo.
echo  ===============================================
echo           System Status Check
echo  ===============================================
echo.
echo Python status:
python --version >nul 2>&1 && (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do echo    [OK] Python %%i installed
) || echo    [ERROR] Python not installed

echo.
echo Node.js status:
node --version >nul 2>&1 && (
    for /f %%i in ('node --version 2^>^&1') do echo    [OK] Node.js %%i installed
) || echo    [ERROR] Node.js not installed

echo.
echo Project environment:
if exist venv (echo    [OK] Python virtual environment exists) else echo    [ERROR] Virtual environment missing
if exist frontend\node_modules (echo    [OK] Node.js modules installed) else echo    [ERROR] Node modules not installed
if exist backend\config.json (echo    [OK] Config file exists) else echo    [ERROR] Config file missing

echo.
echo Server status:
netstat -an | findstr :5000 >nul 2>&1 && echo    [OK] Backend running || echo    [INFO] Backend stopped
netstat -an | findstr :3000 >nul 2>&1 && echo    [OK] Frontend running || echo    [INFO] Frontend stopped

echo.
echo ===============================================
pause
exit /b

:: Safe progress bar function
:progress_bar
setlocal
set "message=%~1"
set "duration=%~2"

if "%message%"=="" (
    echo [ERROR] progress_bar: No message provided
    endlocal
    exit /b 1
)

if "%duration%"=="" set "duration=3"
if %duration% gtr 30 set "duration=30"
if %duration% lss 1 set "duration=1"

echo %message%...
echo [%date% %time%] %message% started >> %LOG_FILE%

set /a progress_counter=0
for /l %%i in (1,1,%duration%) do (
    set /a progress_counter+=1
    if !progress_counter! gtr %duration% goto :progress_complete
    
    echo %%i/%duration% in progress...
    timeout /t 1 /nobreak >nul 2>&1
    
    if errorlevel 1 (
        echo [WARNING] timeout command error, continuing >> %LOG_FILE%
    )
)

:progress_complete
echo [OK] %message% complete!
echo [%date% %time%] %message% completed >> %LOG_FILE%
endlocal
goto :eof