@echo off
chcp 65001 > nul

:: 관리자 권한 자동 요청 (프로세스 종료에 필요할 수 있음)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 프로세스 종료를 위해 관리자 권한이 필요합니다...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ===============================================
echo        🛑 이메일 관리자 서버 종료
echo ===============================================
echo.

:: 포트 사용 중인 프로세스 종료
echo 🔍 실행 중인 서버 프로세스 확인 중...

:: Flask 서버 종료 (포트 5000)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000') do (
    set PID=%%a
    if defined PID (
        echo 백엔드 서버 프로세스 종료 중... (PID: !PID!)
        taskkill /PID !PID! /F >nul 2>&1
    )
)

:: React 서버 종료 (포트 3000)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000') do (
    set PID=%%a
    if defined PID (
        echo 프론트엔드 서버 프로세스 종료 중... (PID: !PID!)
        taskkill /PID !PID! /F >nul 2>&1
    )
)

:: Node.js 프로세스 종료
taskkill /IM node.exe /F >nul 2>&1
taskkill /IM python.exe /F >nul 2>&1

echo.
echo ✅ 모든 서버가 종료되었습니다.
echo.

pause