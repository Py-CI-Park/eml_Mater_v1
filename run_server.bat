@echo off
chcp 65001 > nul
cd /d %~dp0

echo.
echo ===============================================
echo        📧 이메일 관리자 서버 시작
echo ===============================================
echo.

:: 가상환경 활성화 확인
if not exist venv (
    echo ❌ 가상환경이 없습니다.
    echo install.bat를 먼저 실행해주세요.
    pause
    exit /b 1
)

:: 가상환경 활성화
call venv\Scripts\activate.bat

:: 백엔드 서버 시작
echo 🚀 백엔드 서버 시작 중... (Flask)
start "Email Manager - Backend" cmd /k "cd backend && python app.py"

:: 잠시 대기
timeout /t 3 /nobreak > nul

:: 프론트엔드 서버 시작
echo 🚀 프론트엔드 서버 시작 중... (React)
start "Email Manager - Frontend" cmd /k "cd frontend && npm start"

echo.
echo ✅ 서버가 시작되었습니다!
echo.
echo 📍 접속 정보:
echo   - 프론트엔드: http://localhost:3000
echo   - 백엔드: http://localhost:5000
echo.
echo 💡 사용 방법:
echo   1. 브라우저에서 http://localhost:3000 접속
echo   2. 설정 페이지에서 이메일 폴더 경로 설정
echo   3. 이메일 관리 시작!
echo.
echo 🛑 서버 종료: 각 서버 창에서 Ctrl+C
echo.

pause