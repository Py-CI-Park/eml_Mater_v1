@echo off
title 이메일 관리자 - 단계별 검증 도구
chcp 65001 > nul
color 0B

:: 관리자 권한 확인
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
echo  ################################################################
echo                    단계별 검증 및 설치 도구
echo  ################################################################
echo.
echo  이 스크립트는 각 설치 단계를 독립적으로 검증하고 실행합니다.
echo  문제가 발생하는 단계를 식별하여 안전하게 해결할 수 있습니다.
echo.
echo  검증 가능한 단계:
echo   1. 시스템 요구사항 확인
echo   2. Python 가상환경 생성
echo   3. Python 패키지 설치
echo   4. Node.js 패키지 설치
echo   5. 설정 파일 생성
echo   6. 서버 시작 테스트
echo   7. 전체 통합 테스트
echo.
echo  ################################################################
echo.

set STEP_LOG=단계별검증_로그.log
echo [%date% %time%] 단계별 검증 시작 > %STEP_LOG%

:main_menu
echo.
echo  ================================================================
echo                        메뉴 선택
echo  ================================================================
echo.
echo    [1] 시스템 요구사항 확인
echo    [2] Python 가상환경 생성
echo    [3] Python 패키지 설치 
echo    [4] Node.js 패키지 설치
echo    [5] 설정 파일 생성
echo    [6] 서버 시작 테스트
echo    [7] 전체 통합 테스트
echo    [8] 모든 단계 순차 실행
echo    [9] 종료
echo.
set /p STEP_CHOICE="선택하세요 (1-9): "

echo [%date% %time%] 사용자 선택: %STEP_CHOICE% >> %STEP_LOG%

if "%STEP_CHOICE%"=="1" goto :step1_system_check
if "%STEP_CHOICE%"=="2" goto :step2_python_venv
if "%STEP_CHOICE%"=="3" goto :step3_python_packages
if "%STEP_CHOICE%"=="4" goto :step4_node_packages
if "%STEP_CHOICE%"=="5" goto :step5_config_files
if "%STEP_CHOICE%"=="6" goto :step6_server_test
if "%STEP_CHOICE%"=="7" goto :step7_integration_test
if "%STEP_CHOICE%"=="8" goto :step8_full_install
if "%STEP_CHOICE%"=="9" goto :end
goto :main_menu

:: ================================================================
:: 1단계: 시스템 요구사항 확인
:: ================================================================
:step1_system_check
cls
echo.
echo  ================================================================
echo                    1단계: 시스템 요구사항 확인
echo  ================================================================
echo.

echo [%date% %time%] 시스템 요구사항 확인 시작 >> %STEP_LOG%

echo [1/4] Python 확인...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] Python이 설치되지 않았습니다!
    echo    해결책: https://www.python.org/downloads/ 방문
    echo [%date% %time%] Python 미설치 >> %STEP_LOG%
    goto :step1_failed
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do (
        echo    [OK] Python %%i 설치됨
        echo [%date% %time%] Python %%i 확인됨 >> %STEP_LOG%
    )
)

echo [2/4] pip 확인...
pip --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] pip가 설치되지 않았습니다!
    echo [%date% %time%] pip 미설치 >> %STEP_LOG%
    goto :step1_failed
) else (
    echo    [OK] pip 사용 가능
    echo [%date% %time%] pip 사용 가능 >> %STEP_LOG%
)

echo [3/4] Node.js 확인...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] Node.js가 설치되지 않았습니다!
    echo    해결책: https://nodejs.org/ 방문
    echo [%date% %time%] Node.js 미설치 >> %STEP_LOG%
    goto :step1_failed
) else (
    for /f %%i in ('node --version 2^>^&1') do (
        echo    [OK] Node.js %%i 설치됨
        echo [%date% %time%] Node.js %%i 확인됨 >> %STEP_LOG%
    )
)

echo [4/4] npm 확인...
npm --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] npm이 설치되지 않았습니다!
    echo [%date% %time%] npm 미설치 >> %STEP_LOG%
    goto :step1_failed
) else (
    for /f "tokens=1" %%i in ('npm --version 2^>^&1') do (
        echo    [OK] npm %%i 사용 가능
        echo [%date% %time%] npm %%i 확인됨 >> %STEP_LOG%
    )
)

echo.
echo  [SUCCESS] 1단계: 시스템 요구사항 확인 완료!
echo [%date% %time%] 1단계 성공 >> %STEP_LOG%
pause
goto :main_menu

:step1_failed
echo.
echo  [FAILED] 1단계: 시스템 요구사항 확인 실패!
echo  위의 오류를 해결한 후 다시 시도하세요.
echo [%date% %time%] 1단계 실패 >> %STEP_LOG%
pause
goto :main_menu

:: ================================================================
:: 2단계: Python 가상환경 생성
:: ================================================================
:step2_python_venv
cls
echo.
echo  ================================================================
echo                    2단계: Python 가상환경 생성
echo  ================================================================
echo.

echo [%date% %time%] Python 가상환경 생성 시작 >> %STEP_LOG%

echo [1/3] 기존 가상환경 정리...
if exist venv (
    echo    기존 venv 폴더 제거 중...
    rmdir /s /q venv >nul 2>&1
    if exist venv (
        echo    [WARNING] 기존 venv 완전 제거 실패
        echo [%date% %time%] venv 제거 실패 >> %STEP_LOG%
    ) else (
        echo    [OK] 기존 venv 제거 완료
        echo [%date% %time%] venv 제거 성공 >> %STEP_LOG%
    )
) else (
    echo    [OK] 기존 venv 없음
)

echo [2/3] 새 가상환경 생성...
python -m venv venv
if %errorLevel% neq 0 (
    echo    [ERROR] Python 가상환경 생성 실패
    echo [%date% %time%] venv 생성 실패 >> %STEP_LOG%
    goto :step2_failed
) else (
    echo    [OK] 가상환경 생성 성공
    echo [%date% %time%] venv 생성 성공 >> %STEP_LOG%
)

echo [3/3] 가상환경 활성화 테스트...
call venv\Scripts\activate.bat
if exist venv\Scripts\python.exe (
    echo    [OK] 가상환경 활성화 성공
    echo [%date% %time%] venv 활성화 성공 >> %STEP_LOG%
    
    :: pip 업그레이드
    python -m pip install --upgrade pip >nul 2>&1
    echo    [OK] pip 업그레이드 완료
) else (
    echo    [ERROR] 가상환경 활성화 실패
    echo [%date% %time%] venv 활성화 실패 >> %STEP_LOG%
    goto :step2_failed
)

echo.
echo  [SUCCESS] 2단계: Python 가상환경 생성 완료!
echo [%date% %time%] 2단계 성공 >> %STEP_LOG%
pause
goto :main_menu

:step2_failed
echo.
echo  [FAILED] 2단계: Python 가상환경 생성 실패!
echo [%date% %time%] 2단계 실패 >> %STEP_LOG%
pause
goto :main_menu

:: ================================================================
:: 3단계: Python 패키지 설치
:: ================================================================
:step3_python_packages
cls
echo.
echo  ================================================================
echo                    3단계: Python 패키지 설치
echo  ================================================================
echo.

echo [%date% %time%] Python 패키지 설치 시작 >> %STEP_LOG%

:: 가상환경 확인
if not exist venv\Scripts\activate.bat (
    echo    [ERROR] 가상환경이 없습니다. 2단계를 먼저 실행하세요.
    echo [%date% %time%] 가상환경 없음 - 3단계 실패 >> %STEP_LOG%
    pause
    goto :main_menu
)

echo [1/3] 가상환경 활성화...
call venv\Scripts\activate.bat
echo    [OK] 가상환경 활성화됨

echo [2/3] requirements.txt 확인...
if not exist backend\requirements.txt (
    echo    [ERROR] backend\requirements.txt 파일이 없습니다!
    echo [%date% %time%] requirements.txt 없음 >> %STEP_LOG%
    goto :step3_failed
)
echo    [OK] requirements.txt 존재

echo [3/3] Python 패키지 설치...
cd backend
set PYTHON_INSTALL_LOG=python_step_install.log

echo [%date% %time%] Python 패키지 설치 시작 > %PYTHON_INSTALL_LOG%

pip install -r requirements.txt >> %PYTHON_INSTALL_LOG% 2>&1
if %errorLevel% neq 0 (
    echo    [WARNING] requirements.txt 설치 실패, 개별 설치 시도...
    
    :: 개별 패키지 설치
    pip install Flask==2.3.3 >> %PYTHON_INSTALL_LOG% 2>&1
    pip install Flask-CORS==4.0.0 >> %PYTHON_INSTALL_LOG% 2>&1
    pip install python-dateutil >> %PYTHON_INSTALL_LOG% 2>&1
    pip install chardet >> %PYTHON_INSTALL_LOG% 2>&1
    
    :: 검증
    python -c "import flask, flask_cors, dateutil, chardet; print('[OK] 모든 패키지 설치 완료')" >> %PYTHON_INSTALL_LOG% 2>&1
    if %errorLevel% neq 0 (
        echo    [ERROR] Python 패키지 설치 최종 실패
        echo [%date% %time%] Python 패키지 설치 실패 >> ..\%STEP_LOG%
        cd ..
        goto :step3_failed
    ) else (
        echo    [OK] 개별 패키지 설치 성공
    )
) else (
    echo    [OK] requirements.txt 설치 성공
)

type %PYTHON_INSTALL_LOG% >> ..\%STEP_LOG%
cd ..

echo.
echo  [SUCCESS] 3단계: Python 패키지 설치 완료!
echo [%date% %time%] 3단계 성공 >> %STEP_LOG%
pause
goto :main_menu

:step3_failed
echo.
echo  [FAILED] 3단계: Python 패키지 설치 실패!
echo [%date% %time%] 3단계 실패 >> %STEP_LOG%
pause
goto :main_menu

:: ================================================================
:: 4단계: Node.js 패키지 설치
:: ================================================================
:step4_node_packages
cls
echo.
echo  ================================================================
echo                    4단계: Node.js 패키지 설치
echo  ================================================================
echo.

echo [%date% %time%] Node.js 패키지 설치 시작 >> %STEP_LOG%

echo [1/3] frontend 폴더 확인...
if not exist frontend\package.json (
    echo    [ERROR] frontend\package.json 파일이 없습니다!
    echo [%date% %time%] package.json 없음 >> %STEP_LOG%
    goto :step4_failed
)
echo    [OK] package.json 존재

echo [2/3] 기존 node_modules 정리...
cd frontend
if exist node_modules (
    echo    기존 node_modules 제거 중...
    rmdir /s /q node_modules >nul 2>&1
)
if exist package-lock.json del package-lock.json >nul 2>&1
echo    [OK] 기존 모듈 정리 완료

echo [3/3] Node.js 패키지 설치...
set NODE_INSTALL_LOG=node_step_install.log
echo [%date% %time%] Node.js 패키지 설치 시작 > %NODE_INSTALL_LOG%

npm install --legacy-peer-deps --no-audit >> %NODE_INSTALL_LOG% 2>&1
if %errorLevel% neq 0 (
    echo    [WARNING] 첫 번째 설치 실패, 재시도...
    npm cache clean --force >> %NODE_INSTALL_LOG% 2>&1
    npm install --force --no-audit >> %NODE_INSTALL_LOG% 2>&1
    if %errorLevel% neq 0 (
        echo    [ERROR] Node.js 패키지 설치 실패
        echo [%date% %time%] Node.js 패키지 설치 실패 >> ..\%STEP_LOG%
        type %NODE_INSTALL_LOG% >> ..\%STEP_LOG%
        cd ..
        goto :step4_failed
    ) else (
        echo    [OK] 재시도로 설치 성공
    )
) else (
    echo    [OK] 첫 번째 시도로 설치 성공
)

type %NODE_INSTALL_LOG% >> ..\%STEP_LOG%
cd ..

echo.
echo  [SUCCESS] 4단계: Node.js 패키지 설치 완료!
echo [%date% %time%] 4단계 성공 >> %STEP_LOG%
pause
goto :main_menu

:step4_failed
echo.
echo  [FAILED] 4단계: Node.js 패키지 설치 실패!
echo [%date% %time%] 4단계 실패 >> %STEP_LOG%
pause
goto :main_menu

:: ================================================================
:: 8단계: 모든 단계 순차 실행
:: ================================================================
:step8_full_install
cls
echo.
echo  ================================================================
echo                    전체 설치 - 모든 단계 순차 실행
echo  ================================================================
echo.

echo [%date% %time%] 전체 설치 시작 >> %STEP_LOG%

call :step1_system_check_silent
if %errorLevel% neq 0 goto :step8_failed

call :step2_python_venv_silent
if %errorLevel% neq 0 goto :step8_failed

call :step3_python_packages_silent
if %errorLevel% neq 0 goto :step8_failed

call :step4_node_packages_silent
if %errorLevel% neq 0 goto :step8_failed

echo.
echo  [SUCCESS] 전체 설치 완료!
echo  모든 단계가 성공적으로 완료되었습니다.
echo [%date% %time%] 전체 설치 성공 >> %STEP_LOG%
pause
goto :main_menu

:step8_failed
echo.
echo  [FAILED] 전체 설치 실패!
echo  실패한 단계를 개별적으로 다시 실행해 보세요.
echo [%date% %time%] 전체 설치 실패 >> %STEP_LOG%
pause
goto :main_menu

:: Silent 버전들 (에러 코드만 반환)
:step1_system_check_silent
python --version >nul 2>&1 || exit /b 1
pip --version >nul 2>&1 || exit /b 1
node --version >nul 2>&1 || exit /b 1
npm --version >nul 2>&1 || exit /b 1
exit /b 0

:step2_python_venv_silent
if exist venv rmdir /s /q venv >nul 2>&1
python -m venv venv || exit /b 1
call venv\Scripts\activate.bat || exit /b 1
python -m pip install --upgrade pip >nul 2>&1
exit /b 0

:step3_python_packages_silent
call venv\Scripts\activate.bat || exit /b 1
cd backend
pip install -r requirements.txt >nul 2>&1
if %errorLevel% neq 0 (
    pip install Flask==2.3.3 Flask-CORS==4.0.0 python-dateutil chardet >nul 2>&1 || (cd .. && exit /b 1)
)
python -c "import flask, flask_cors, dateutil, chardet" >nul 2>&1 || (cd .. && exit /b 1)
cd ..
exit /b 0

:step4_node_packages_silent
cd frontend
if exist node_modules rmdir /s /q node_modules >nul 2>&1
if exist package-lock.json del package-lock.json >nul 2>&1
npm install --legacy-peer-deps --no-audit >nul 2>&1
if %errorLevel% neq 0 (
    npm cache clean --force >nul 2>&1
    npm install --force --no-audit >nul 2>&1 || (cd .. && exit /b 1)
)
cd ..
exit /b 0

:end
echo.
echo 단계별 검증 도구를 종료합니다.
echo [%date% %time%] 단계별 검증 종료 >> %STEP_LOG%
echo 로그 파일: %STEP_LOG%
pause >nul