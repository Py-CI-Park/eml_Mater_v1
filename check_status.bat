@echo off
chcp 65001 > nul

echo.
echo ===============================================
echo       🔍 이메일 관리자 상태 확인
echo ===============================================
echo.

:: Python 설치 확인
echo 🐍 Python 상태:
python --version >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do echo   ✅ Python %%i 설치됨
) else (
    echo   ❌ Python 미설치
)

:: Node.js 설치 확인
echo.
echo 🟢 Node.js 상태:
node --version >nul 2>&1
if %errorLevel% equ 0 (
    for /f %%i in ('node --version 2^>^&1') do echo   ✅ Node.js %%i 설치됨
    for /f "tokens=1" %%i in ('npm --version 2^>^&1') do echo   ✅ npm %%i 설치됨
) else (
    echo   ❌ Node.js 미설치
)

:: 가상환경 확인
echo.
echo 🔧 가상환경 상태:
if exist venv (
    echo   ✅ Python 가상환경 존재
    call venv\Scripts\activate.bat
    pip list | findstr Flask >nul 2>&1
    if %errorLevel% equ 0 (
        echo   ✅ Flask 설치됨
    ) else (
        echo   ❌ Flask 미설치
    )
) else (
    echo   ❌ Python 가상환경 없음
)

:: 프론트엔드 의존성 확인
echo.
echo ⚛️ 프론트엔드 상태:
if exist frontend\node_modules (
    echo   ✅ Node.js 모듈 설치됨
    if exist frontend\package.json (
        echo   ✅ package.json 존재
    )
) else (
    echo   ❌ Node.js 모듈 미설치
)

:: 설정 파일 확인
echo.
echo ⚙️ 설정 파일 상태:
if exist backend\config.json (
    echo   ✅ config.json 존재
) else (
    echo   ❌ config.json 없음
)

:: 서버 실행 상태 확인
echo.
echo 🌐 서버 실행 상태:
netstat -an | findstr :5000 >nul 2>&1
if %errorLevel% equ 0 (
    echo   ✅ 백엔드 서버 실행 중 (포트 5000)
) else (
    echo   ⚪ 백엔드 서버 중지
)

netstat -an | findstr :3000 >nul 2>&1
if %errorLevel% equ 0 (
    echo   ✅ 프론트엔드 서버 실행 중 (포트 3000)
) else (
    echo   ⚪ 프론트엔드 서버 중지
)

echo.
echo ===============================================
echo          상태 확인 완료
echo ===============================================
echo.

pause