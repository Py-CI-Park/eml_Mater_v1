@echo off
title Email Manager - Install Program
chcp 65001 > nul
color 0A

:: 관리자 권한 자동 획득
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo 관리자 권한이 필요합니다. UAC 창에서 "예"를 클릭해주세요.
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
echo                    통합 설치 프로그램
echo  ================================================================
echo.
echo    폐쇄망에서 .eml 파일을 관리하는 웹 애플리케이션
echo    Backend: Flask (Python)
echo    Frontend: React (JavaScript)
echo.
echo  ================================================================
echo.
echo 관리자 권한으로 실행됨
echo 작업 폴더: %CD%
echo.

:: 안전한 로깅 시스템 초기화
set LOG_FILE=install_log.log
set MAX_LOG_SIZE=5000000

:: 기존 로그 파일이 너무 크면 백업 후 새로 시작
if exist %LOG_FILE% (
    for %%A in (%LOG_FILE%) do (
        if %%~zA gtr %MAX_LOG_SIZE% (
            move %LOG_FILE% install_log_backup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%.log >nul 2>&1
        )
    )
)

:: 로그 파일 안전 초기화
echo [%date% %time%] 로그 시스템 초기화 시작 > %LOG_FILE% 2>nul
if not exist %LOG_FILE% (
    echo [ERROR] 로그 파일을 생성할 수 없습니다. 
    echo 가능한 원인:
    echo   1. 관리자 권한 부족
    echo   2. 디스크 공간 부족  
    echo   3. 바이러스 백신 차단
    echo   4. 파일 경로 문제
    echo.
    echo 해결책: 환경정리.bat를 먼저 실행하거나 컴퓨터를 재부팅하세요.
    pause
    exit /b 1
)

echo [%date% %time%] 통합 설치 시작 - 안정성 강화 버전 >> %LOG_FILE%
echo [%date% %time%] 로그 파일 초기화 완료 >> %LOG_FILE%

:: 시스템 환경 사전 검증
call :check_system_health
if %errorLevel% neq 0 (
    echo [ERROR] 시스템 환경에 문제가 있습니다. 환경정리.bat를 먼저 실행하세요.
    pause
    exit /b 1
)

:: 설치 모드 선택
echo 설치 모드를 선택하세요:
echo.
echo    [1] 빠른 설치 ^(권장^) - 자동으로 모든 것을 설치
echo    [2] 고급 설치 - 단계별 확인하며 설치  
echo    [3] 시스템 상태 확인만
echo    [4] 설치 취소
echo.
set /p INSTALL_MODE="선택하세요 (1-4): "

if "%INSTALL_MODE%"=="4" (
    echo 설치가 취소되었습니다.
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
    echo 고급 설치 모드 - 각 단계에서 확인을 요청합니다.
    set /p CONTINUE="계속하시겠습니까? (Y/N): "
    if /i not "!CONTINUE!"=="Y" (
        echo 설치가 취소되었습니다.
        pause
        exit /b
    )
) else (
    echo 빠른 설치 모드 - 자동으로 모든 과정을 진행합니다.
    echo 빠른 설치를 시작합니다...
    timeout /t 2 /nobreak >nul
)

echo [%date% %time%] 설치 모드: %INSTALL_MODE% >> %LOG_FILE%

:: 1단계: 시스템 요구사항 확인
echo.
echo ===============================================
echo 1단계: 시스템 요구사항 확인
echo ===============================================

call :progress_bar "시스템 검사 중" 3

echo Python 설치 확인...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python이 설치되지 않았습니다!
    echo.
    echo Python 설치 필요:
    echo    1. https://www.python.org/downloads/ 방문
    echo    2. 최신 Python 3.x 버전 다운로드
    echo    3. 설치 시 "Add Python to PATH" 반드시 체크!
    echo    4. 설치 완료 후 컴퓨터 재시작
    echo    5. 이 스크립트 다시 실행
    echo.
    echo [%date% %time%] Python 미설치로 중단 >> %LOG_FILE%
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo    [OK] Python %PYTHON_VERSION%

pip --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] pip가 설치되지 않았습니다!
    echo Python을 재설치하거나 pip를 별도로 설치해주세요.
    pause
    exit /b 1
)

echo Node.js 설치 확인...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Node.js가 설치되지 않았습니다!
    echo.
    echo Node.js 설치 필요:
    echo    1. https://nodejs.org/ 방문
    echo    2. LTS 버전 다운로드 및 설치
    echo    3. 설치 완료 후 이 스크립트 다시 실행
    echo.
    pause
    exit /b 1
)

for /f %%i in ('node --version 2^>^&1') do set NODE_VERSION=%%i
echo    [OK] Node.js %NODE_VERSION%

for /f "tokens=1" %%i in ('npm --version 2^>^&1') do set NPM_VERSION=%%i
echo    [OK] npm %NPM_VERSION%

echo [OK] 모든 시스템 요구사항이 충족되었습니다!

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="다음 단계로 진행하시겠습니까? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: 2단계: 환경 정리
echo.
echo ===============================================
echo 2단계: 환경 정리 및 준비
echo ===============================================

call :progress_bar "환경 정리 중" 3

if exist backend\config.json (
    echo 기존 설정 파일 백업...
    copy backend\config.json backend\config.json.backup >nul 2>&1
)

echo 기존 환경 정리...
if exist venv rmdir /s /q venv >nul 2>&1
if exist frontend\node_modules rmdir /s /q frontend\node_modules >nul 2>&1
if exist frontend\package-lock.json del frontend\package-lock.json >nul 2>&1

echo [OK] 환경 정리 완료

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="다음 단계로 진행하시겠습니까? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: 3단계: Python 환경 설정
echo.
echo ===============================================
echo 3단계: Python 환경 설정
echo ===============================================

call :progress_bar "Python 가상환경 생성" 5

echo Python 가상환경 생성...
python -m venv venv
if %errorLevel% neq 0 (
    echo [ERROR] Python 가상환경 생성 실패
    pause
    exit /b 1
)

call venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul 2>&1

call :progress_bar "Python 패키지 설치" 10

echo Python 의존성 설치...
echo [%date% %time%] Python 의존성 설치 시작 >> %LOG_FILE%
cd backend

:: 안전한 로깅을 위한 서브 로그 파일 사용
set BACKEND_LOG=python_install.log
echo [%date% %time%] Python 패키지 설치 로그 시작 > %BACKEND_LOG%

echo [INFO] 첫 번째 시도: requirements.txt 설치
echo [%date% %time%] requirements.txt 설치 시도 >> ..\%LOG_FILE%
echo [%date% %time%] requirements.txt 설치 시도 >> %BACKEND_LOG%

:: pip 설치를 더 안전하게 실행
pip install -r requirements.txt >> %BACKEND_LOG% 2>&1
set PIP_RESULT=%errorLevel%

:: 서브 로그를 메인 로그에 안전하게 복사
call :safe_log_copy %BACKEND_LOG% ..\%LOG_FILE%

if %PIP_RESULT% neq 0 (
    echo [WARNING] requirements.txt 설치 실패, 개별 패키지 설치 시도...
    echo [%date% %time%] requirements.txt 실패, 개별 설치 시작 >> ..\%LOG_FILE%
    
    echo [INFO] Flask 설치...
    pip install Flask==2.3.3 >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] Flask-CORS 설치...
    pip install Flask-CORS==4.0.0 >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] python-dateutil 설치...
    pip install python-dateutil >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] chardet 설치...
    pip install chardet >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] 최종 검증 중...
    echo [%date% %time%] Python 패키지 검증 시작 >> ..\%LOG_FILE%
    python -c "import flask, flask_cors, dateutil, chardet; print('[OK] 모든 필수 패키지 설치 완료')" >> ..\%LOG_FILE% 2>&1
    if %errorLevel% neq 0 (
        echo [ERROR] Python 의존성 설치 최종 실패
        echo [%date% %time%] Python 패키지 검증 실패 >> ..\%LOG_FILE%
        echo 인터넷 연결을 확인하고 다시 시도해주세요.
        cd ..
        echo 오류 로그를 확인하려면 아무 키나 누르세요...
        pause
        exit /b 1
    ) else (
        echo [OK] 개별 패키지 설치 및 검증 완료
        echo [%date% %time%] 개별 패키지 설치 성공 >> ..\%LOG_FILE%
    )
) else (
    echo [OK] requirements.txt 설치 성공
    echo [%date% %time%] requirements.txt 설치 성공 >> ..\%LOG_FILE%
)
cd ..

echo [OK] Python 환경 설정 완료!

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="다음 단계로 진행하시겠습니까? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: 4단계: Node.js 환경 설정
echo.
echo ===============================================
echo 4단계: Node.js 환경 설정
echo ===============================================

cd frontend
call :progress_bar "Node.js 패키지 설치" 15

echo React 및 Node.js 의존성 설치...
echo React 18 호환성 문제 해결을 위해 --legacy-peer-deps 옵션 사용
echo [%date% %time%] Node.js 패키지 설치 시작 >> ..\%LOG_FILE%

echo [INFO] npm install 첫 번째 시도...
npm install --legacy-peer-deps --no-audit >> ..\%LOG_FILE% 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] 첫 번째 설치 시도 실패, 다른 방법으로 재시도...
    echo [%date% %time%] npm install 첫 번째 시도 실패 >> ..\%LOG_FILE%
    
    echo [INFO] npm cache 정리 중...
    npm cache clean --force >> ..\%LOG_FILE% 2>&1
    
    echo [INFO] npm install 두 번째 시도 (--force 옵션)...
    npm install --force --no-audit >> ..\%LOG_FILE% 2>&1
    if %errorLevel% neq 0 (
        echo [ERROR] Node.js 의존성 설치 최종 실패
        echo [%date% %time%] npm install 최종 실패 >> ..\%LOG_FILE%
        echo 인터넷 연결을 확인하고 다시 시도해주세요.
        cd ..
        echo 오류 로그를 확인하려면 아무 키나 누르세요...
        pause
        exit /b 1
    ) else (
        echo [OK] 두 번째 시도로 설치 성공
        echo [%date% %time%] npm install 두 번째 시도 성공 >> ..\%LOG_FILE%
    )
) else (
    echo [OK] 첫 번째 시도로 설치 성공
    echo [%date% %time%] npm install 첫 번째 시도 성공 >> ..\%LOG_FILE%
)

echo [OK] Node.js 환경 설정 완료!
echo [%date% %time%] Node.js 환경 설정 완료 >> ..\%LOG_FILE%
cd ..

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="다음 단계로 진행하시겠습니까? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: 5단계: 설정 파일 및 실행 환경 구성
echo.
echo ===============================================
echo 5단계: 설정 파일 및 실행 환경 구성
echo ===============================================

call :progress_bar "설정 파일 구성" 3

cd backend
if exist config.json.backup (
    copy config.json.backup config.json >nul 2>&1
    del config.json.backup >nul 2>&1
    echo [OK] 기존 설정 복원됨
) else (
    (
        echo {
        echo   "email_root": "",
        echo   "port": 5000,
        echo   "host": "127.0.0.1"
        echo }
    ) > config.json
    echo [OK] 기본 설정 파일 생성됨
)
cd ..

:: 실행 스크립트들 생성
echo 실행 스크립트 생성...

:: 메인 실행 스크립트
(
    echo @echo off
    echo title 이메일 관리자
    echo chcp 65001 ^> nul
    echo color 0A
    echo cd /d %%~dp0
    echo cls
    echo.
    echo  ######  ##   ## ##    ## 
    echo  ##   ## ##   ## ###   ## 
    echo  ##   ## ##   ## ## #  ## 
    echo  ######  ##   ## ##  # ## 
    echo  ##  ##  ##   ## ##   ### 
    echo  ##   ## ##   ## ##    ## 
    echo  ##   ##  #####  ##    ##
    echo.
    echo  ===============================================
    echo            이메일 관리자 시작
    echo  ===============================================
    echo.
    echo [1/4] Python 가상환경 활성화 중...
    echo call venv\Scripts\activate.bat
    echo.
    echo [2/4] 백엔드 서버 시작 중...
    echo start "Backend Server" cmd /k "cd backend && python app.py"
    echo echo 백엔드 서버 시작됨 (포트 5000^)
    echo.
    echo [3/4] 프론트엔드 서버 시작을 위해 잠시 대기...
    echo timeout /t 5 /nobreak ^> nul
    echo.
    echo [4/4] 프론트엔드 서버 시작 중...
    echo start "Frontend Server" cmd /k "cd frontend && npm start"
    echo echo 프론트엔드 서버 시작됨 (포트 3000^)
    echo.
    echo ===============================================
    echo echo [OK] 모든 서버가 시작되었습니다!
    echo echo.
    echo echo 접속 정보:
    echo echo   - 프론트엔드: http://localhost:3000
    echo echo   - 백엔드 API: http://localhost:5000
    echo echo.
    echo echo 브라우저가 10초 후 자동으로 열립니다...
    echo timeout /t 10 /nobreak ^> nul
    echo.
    echo echo 브라우저 열기 중...
    echo start http://localhost:3000
    echo.
    echo echo [OK] 브라우저가 열렸습니다!
    echo echo 이 창을 닫으려면 아무 키나 누르세요...
    echo pause ^> nul
) > "이메일관리자_실행.bat"

:: 종료 스크립트
(
    echo @echo off
    echo chcp 65001 ^> nul
    echo color 0A
    echo title 서버 종료
    echo cls
    echo.
    echo   ####  ######  ####  ######  
    echo  ##       ##   ##   ## ##   ## 
    echo  ##       ##   ##   ## ##   ## 
    echo   ####     ##   ##   ## ######  
    echo      ##    ##   ##   ## ##      
    echo      ##    ##   ##   ## ##      
    echo   ####     ##    ####  ##      
    echo.
    echo  ===============================================
    echo               서버 종료
    echo  ===============================================
    echo.
    echo 서버 종료 중...
    echo for /f "tokens=5" %%%%a in ^('netstat -aon ^^^| findstr :5000'^) do taskkill /PID %%%%a /F ^>nul 2^>^&1
    echo for /f "tokens=5" %%%%a in ^('netstat -aon ^^^| findstr :3000'^) do taskkill /PID %%%%a /F ^>nul 2^>^&1
    echo taskkill /IM node.exe /F ^>nul 2^>^&1
    echo taskkill /IM python.exe /F ^>nul 2^>^&1
    echo echo [OK] 서버가 종료되었습니다.
    echo pause
) > "이메일관리자_종료.bat"

:: 상태 확인 스크립트
(
    echo @echo off
    echo chcp 65001 ^> nul
    echo color 0A
    echo title 상태 확인
    echo cls
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
    echo           시스템 상태 확인
    echo  ===============================================
    echo.
    echo python --version 2^>nul ^&^& echo [OK] Python 설치됨 ^|^| echo [ERROR] Python 미설치
    echo node --version 2^>nul ^&^& echo [OK] Node.js 설치됨 ^|^| echo [ERROR] Node.js 미설치
    echo if exist venv echo [OK] 가상환경 존재
    echo if exist frontend\node_modules echo [OK] Node 모듈 설치됨
    echo if exist backend\config.json echo [OK] 설정파일 존재
    echo netstat -an ^^^| findstr :5000 ^>nul ^&^& echo [OK] 백엔드 실행중 ^|^| echo [INFO] 백엔드 중지
    echo netstat -an ^^^| findstr :3000 ^>nul ^&^& echo [OK] 프론트엔드 실행중 ^|^| echo [INFO] 프론트엔드 중지
    echo pause
) > "이메일관리자_상태확인.bat"

:: 테스트 폴더 생성
if not exist "테스트용_이메일_폴더" (
    mkdir "테스트용_이메일_폴더"
    echo 이메일 관리자 테스트용 폴더 > "테스트용_이메일_폴더\사용방법.txt"
    echo. >> "테스트용_이메일_폴더\사용방법.txt"
    echo 1. 이 폴더에 .eml 파일들을 복사하세요 >> "테스트용_이메일_폴더\사용방법.txt"
    echo 2. 프로그램 설정에서 이 폴더 경로를 입력하세요 >> "테스트용_이메일_폴더\사용방법.txt"
    echo 3. 경로 예시: %~dp0테스트용_이메일_폴더 >> "테스트용_이메일_폴더\사용방법.txt"
)

echo [OK] 설정 파일 및 실행 환경 구성 완료!

if "%ADVANCED_MODE%"=="1" (
    set /p CONTINUE="다음 단계로 진행하시겠습니까? (Y/N): "
    if /i not "!CONTINUE!"=="Y" goto :eof
)

:: 6단계: 바탕화면 바로가기 생성
echo.
echo ===============================================
echo 6단계: 바탕화면 바로가기 생성
echo ===============================================

call :progress_bar "바로가기 생성" 3

set DESKTOP=%USERPROFILE%\Desktop
set SHORTCUT_PATH=%DESKTOP%\이메일 관리자.lnk
set TARGET_PATH=%~dp0이메일관리자_실행.bat

powershell -Command "& { try { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%TARGET_PATH%'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.IconLocation = 'imageres.dll,14'; $Shortcut.Description = 'EML 파일 관리 도구'; $Shortcut.Save(); Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' } }" > temp_result.txt

for /f %%i in (temp_result.txt) do set SHORTCUT_RESULT=%%i
del temp_result.txt >nul 2>&1

if "%SHORTCUT_RESULT%"=="SUCCESS" (
    echo [OK] 바탕화면 바로가기 생성 완료
) else (
    echo [WARNING] 바탕화면 바로가기 생성 실패 (무시 가능)
)

:: 설치 완료
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
echo                        설치 완료!
echo  ================================================================
echo.
echo  설치된 구성 요소:
echo     [OK] Python %PYTHON_VERSION% 가상환경
echo     [OK] Node.js %NODE_VERSION% + React 18
echo     [OK] Flask 백엔드 서버
echo     [OK] 모든 실행 스크립트
echo     [OK] 바탕화면 바로가기
echo     [OK] 테스트 환경
echo.
echo  실행 방법:
echo     방법 1: 바탕화면 "이메일 관리자" 더블클릭
echo     방법 2: "이메일관리자_실행.bat" 더블클릭
echo.
echo  관리 도구:
echo     - 이메일관리자_실행.bat      : 프로그램 시작
echo     - 이메일관리자_종료.bat      : 서버 종료
echo     - 이메일관리자_상태확인.bat  : 상태 확인
echo.
echo  접속 주소: http://localhost:3000
echo  테스트 폴더: "테스트용_이메일_폴더"
echo.

echo [%date% %time%] 설치 성공적으로 완료 >> %LOG_FILE%

echo.
echo  ================================================================
echo                        설치 성공!
echo  ================================================================
echo.
echo  다음 단계:
echo     1. 바탕화면의 "이메일 관리자" 바로가기를 더블클릭
echo     2. 또는 "이메일관리자_실행.bat" 파일을 실행
echo     3. 브라우저에서 http://localhost:3000 접속
echo     4. 설정에서 이메일 폴더 경로를 지정하세요
echo.
echo  ================================================================
echo.

set /p AUTORUN="지금 바로 실행하시겠습니까? (Y/N): "
if /i "%AUTORUN%"=="Y" (
    echo.
    echo 이메일 관리자를 시작합니다...
    echo 잠시 후 브라우저가 자동으로 열립니다.
    echo.
    timeout /t 3 /nobreak >nul
    start "" "이메일관리자_실행.bat"
    echo.
    echo [OK] 프로그램이 시작되었습니다!
    echo 브라우저에서 http://localhost:3000을 확인하세요.
    echo.
) else (
    echo.
    echo 설치가 완료되었습니다!
    echo 나중에 바탕화면 바로가기를 사용하여 실행하세요.
    echo.
)

echo 설치 창을 닫으려면 아무 키나 누르세요...
pause >nul

:: 시스템 상태 확인 함수
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
echo           시스템 상태 확인
echo  ===============================================
echo.
echo Python 상태:
python --version >nul 2>&1 && (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do echo    [OK] Python %%i 설치됨
) || echo    [ERROR] Python 미설치

echo.
echo Node.js 상태:
node --version >nul 2>&1 && (
    for /f %%i in ('node --version 2^>^&1') do echo    [OK] Node.js %%i 설치됨
) || echo    [ERROR] Node.js 미설치

echo.
echo 프로젝트 환경:
if exist venv (echo    [OK] Python 가상환경 존재) else echo    [ERROR] 가상환경 없음
if exist frontend\node_modules (echo    [OK] Node.js 모듈 설치됨) else echo    [ERROR] Node 모듈 미설치
if exist backend\config.json (echo    [OK] 설정 파일 존재) else echo    [ERROR] 설정 파일 없음

echo.
echo 서버 상태:
netstat -an | findstr :5000 >nul 2>&1 && echo    [OK] 백엔드 실행 중 || echo    [INFO] 백엔드 중지
netstat -an | findstr :3000 >nul 2>&1 && echo    [OK] 프론트엔드 실행 중 || echo    [INFO] 프론트엔드 중지

echo.
echo ===============================================
pause
exit /b

:: 안전한 진행 상황 표시 함수
:progress_bar
setlocal
set "message=%~1"
set "duration=%~2"

:: 매개변수 검증
if "%message%"=="" (
    echo [ERROR] progress_bar: 메시지가 없습니다
    endlocal
    exit /b 1
)

:: 지속시간 검증 및 제한
if "%duration%"=="" set "duration=3"
if %duration% gtr 30 set "duration=30"
if %duration% lss 1 set "duration=1"

echo %message%...
call :safe_log "[%date% %time%] %message% 시작"

:: 안전한 진행률 표시 (무한루프 방지)
set /a progress_counter=0
for /l %%i in (1,1,%duration%) do (
    set /a progress_counter+=1
    if !progress_counter! gtr %duration% goto :progress_complete
    
    echo %%i/%duration% 진행 중...
    timeout /t 1 /nobreak >nul 2>&1
    
    :: 예상치 못한 중단 상황 처리
    if errorlevel 1 (
        call :safe_log "[WARNING] timeout 명령 오류 발생, 진행 계속"
    )
)

:progress_complete
echo [OK] %message% 완료!
call :safe_log "[%date% %time%] %message% 완료"
endlocal
goto :eof

:: 안전한 로그 기록 함수
:safe_log
setlocal
set "log_message=%~1"
if "%log_message%"=="" goto :eof

:: 로그 파일 존재 확인
if not exist "%LOG_FILE%" (
    echo %log_message% > "%LOG_FILE%" 2>nul
) else (
    echo %log_message% >> "%LOG_FILE%" 2>nul
)

:: 로그 기록 실패 시에도 진행 (silent fail)
endlocal
goto :eof

:: 안전한 로그 복사 함수
:safe_log_copy
setlocal
set "source_log=%~1"
set "target_log=%~2"

if not exist "%source_log%" goto :safe_log_copy_end
if "%target_log%"=="" goto :safe_log_copy_end

:: 소스 파일 크기 확인 (2MB 이상이면 건너뛰기)
for %%A in ("%source_log%") do (
    if %%~zA gtr 2000000 (
        echo [WARNING] %source_log% 파일이 너무 큽니다. 로그 복사를 건너뜁니다.
        goto :safe_log_copy_end
    )
)

:: 안전한 파일 복사
type "%source_log%" >> "%target_log%" 2>nul

:safe_log_copy_end
endlocal
goto :eof

:: 시스템 상태 검증 함수
:check_system_health
setlocal
call :safe_log "[%date% %time%] 시스템 상태 검증 시작"

:: 디스크 공간 확인 (최소 1GB)
for /f "tokens=3" %%a in ('dir /-c %~dp0 ^| findstr /i "bytes free"') do (
    set free_space=%%a
)

if defined free_space (
    if %free_space% lss 1073741824 (
        echo [ERROR] 디스크 공간이 부족합니다. 최소 1GB 필요
        call :safe_log "[ERROR] 디스크 공간 부족: %free_space% bytes"
        endlocal
        exit /b 1
    )
)

:: 기존 프로세스 확인
netstat -an | findstr ":5000\|:3000" >nul 2>&1
if %errorLevel% equ 0 (
    echo [WARNING] 포트 5000 또는 3000이 사용 중입니다.
    call :safe_log "[WARNING] 포트 충돌 감지"
)

call :safe_log "[%date% %time%] 시스템 상태 검증 완료"
endlocal
exit /b 0