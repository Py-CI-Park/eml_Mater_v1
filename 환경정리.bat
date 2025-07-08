@echo off
title 이메일 관리자 - 환경 정리
chcp 65001 > nul
color 0C

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
echo                      환경 정리 및 복구 도구
echo  ################################################################
echo.
echo  이 스크립트는 손상된 설치 환경을 완전히 정리합니다.
echo.
echo  정리 항목:
echo   1. 손상된 로그 파일들
echo   2. 기존 Python 가상환경
echo   3. Node.js 모듈들
echo   4. 실행 중인 프로세스들
echo   5. 임시 파일들
echo.
echo  ################################################################
echo.

set CLEAN_LOG=환경정리_로그.log
echo [%date% %time%] 환경 정리 시작 > %CLEAN_LOG%

echo [1/7] 실행 중인 프로세스 확인 및 종료...
echo [%date% %time%] 프로세스 정리 시작 >> %CLEAN_LOG%

:: 포트 사용 프로세스 종료
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 2^>nul') do (
    if "%%a" neq "" (
        echo    포트 5000 프로세스 %%a 종료 중...
        taskkill /PID %%a /F >nul 2>&1
        echo [%date% %time%] 포트 5000 프로세스 %%a 종료됨 >> %CLEAN_LOG%
    )
)

for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000 2^>nul') do (
    if "%%a" neq "" (
        echo    포트 3000 프로세스 %%a 종료 중...
        taskkill /PID %%a /F >nul 2>&1
        echo [%date% %time%] 포트 3000 프로세스 %%a 종료됨 >> %CLEAN_LOG%
    )
)

:: Python 및 Node.js 프로세스 종료 (신중하게)
echo    Python/Node.js 프로세스 정리 중...
taskkill /IM python.exe /F >nul 2>&1
taskkill /IM node.exe /F >nul 2>&1
echo [%date% %time%] Python/Node.js 프로세스 정리 완료 >> %CLEAN_LOG%

echo [2/7] 손상된 로그 파일 정리...
echo [%date% %time%] 로그 파일 정리 시작 >> %CLEAN_LOG%

:: 메인 로그 파일 백업 후 삭제
if exist install_log.txt (
    if exist install_log_corrupted_backup.txt del install_log_corrupted_backup.txt >nul 2>&1
    move install_log.txt install_log_corrupted_backup.txt >nul 2>&1
    echo    [OK] 손상된 install_log.txt 백업됨
    echo [%date% %time%] install_log.txt 백업 완료 >> %CLEAN_LOG%
)

if exist install_log.log (
    if exist install_log_backup.log del install_log_backup.log >nul 2>&1
    move install_log.log install_log_backup.log >nul 2>&1
    echo    [OK] 기존 install_log.log 백업됨
    echo [%date% %time%] install_log.log 백업 완료 >> %CLEAN_LOG%
)

:: 서브 디렉토리 로그 파일들도 정리
if exist backend\install_log.txt (
    del backend\install_log.txt >nul 2>&1
    echo    [OK] backend\install_log.txt 삭제됨
)

if exist frontend\install_log.txt (
    del frontend\install_log.txt >nul 2>&1
    echo    [OK] frontend\install_log.txt 삭제됨
)

echo [3/7] 기존 Python 가상환경 제거...
echo [%date% %time%] 가상환경 정리 시작 >> %CLEAN_LOG%

if exist venv (
    echo    기존 venv 폴더 제거 중... (시간이 걸릴 수 있습니다)
    rmdir /s /q venv >nul 2>&1
    if exist venv (
        echo    [WARNING] venv 폴더 완전 제거 실패 - 재부팅 후 수동 삭제 필요
        echo [%date% %time%] venv 폴더 제거 실패 >> %CLEAN_LOG%
    ) else (
        echo    [OK] venv 폴더 제거 완료
        echo [%date% %time%] venv 폴더 제거 성공 >> %CLEAN_LOG%
    )
) else (
    echo    [OK] venv 폴더 없음
    echo [%date% %time%] venv 폴더 없음 확인 >> %CLEAN_LOG%
)

echo [4/7] Node.js 모듈 제거...
echo [%date% %time%] Node.js 모듈 정리 시작 >> %CLEAN_LOG%

if exist frontend\node_modules (
    echo    기존 node_modules 폴더 제거 중... (시간이 걸릴 수 있습니다)
    cd frontend
    rmdir /s /q node_modules >nul 2>&1
    if exist node_modules (
        echo    [WARNING] node_modules 폴더 완전 제거 실패
        echo [%date% %time%] node_modules 폴더 제거 실패 >> ..\%CLEAN_LOG%
    ) else (
        echo    [OK] node_modules 폴더 제거 완료
        echo [%date% %time%] node_modules 폴더 제거 성공 >> ..\%CLEAN_LOG%
    )
    cd ..
) else (
    echo    [OK] node_modules 폴더 없음
    echo [%date% %time%] node_modules 폴더 없음 확인 >> %CLEAN_LOG%
)

if exist frontend\package-lock.json (
    del frontend\package-lock.json >nul 2>&1
    echo    [OK] package-lock.json 삭제됨
    echo [%date% %time%] package-lock.json 삭제 완료 >> %CLEAN_LOG%
)

echo [5/7] 기존 데이터베이스 백업...
echo [%date% %time%] 데이터베이스 백업 시작 >> %CLEAN_LOG%

if exist backend\email_manager.db (
    copy backend\email_manager.db backend\email_manager_backup_%date:~0,4%%date:~5,2%%date:~8,2%.db >nul 2>&1
    echo    [OK] 데이터베이스 백업 완료
    echo [%date% %time%] 데이터베이스 백업 성공 >> %CLEAN_LOG%
) else (
    echo    [OK] 데이터베이스 파일 없음
    echo [%date% %time%] 데이터베이스 파일 없음 확인 >> %CLEAN_LOG%
)

echo [6/7] 임시 파일 정리...
echo [%date% %time%] 임시 파일 정리 시작 >> %CLEAN_LOG%

:: 임시 테스트 파일들 삭제
del temp_*.py >nul 2>&1
del temp_*.bat >nul 2>&1
del temp_*.txt >nul 2>&1
del server_test.log >nul 2>&1

echo    [OK] 임시 파일 정리 완료
echo [%date% %time%] 임시 파일 정리 완료 >> %CLEAN_LOG%

echo [7/7] 기존 실행 스크립트 백업...
echo [%date% %time%] 실행 스크립트 백업 시작 >> %CLEAN_LOG%

:: 기존 실행 스크립트가 있다면 백업
if exist "이메일관리자_실행.bat" (
    copy "이메일관리자_실행.bat" "이메일관리자_실행_백업.bat" >nul 2>&1
    echo    [OK] 실행 스크립트 백업됨
    echo [%date% %time%] 실행 스크립트 백업 완료 >> %CLEAN_LOG%
)

:: 시스템 상태 최종 확인
echo.
echo  ################################################################
echo                        정리 완료!
echo  ################################################################
echo.

echo [%date% %time%] 환경 정리 성공적으로 완료 >> %CLEAN_LOG%

echo  정리 결과:
echo   [OK] 손상된 로그 파일 백업/삭제
echo   [OK] 실행 중인 프로세스 종료
echo   [OK] 기존 가상환경 제거
echo   [OK] Node.js 모듈 제거
echo   [OK] 데이터베이스 백업
echo   [OK] 임시 파일 정리
echo.
echo  다음 단계:
echo   1. 컴퓨터 재부팅 (권장)
echo   2. INSTALL.bat 관리자 권한으로 실행
echo.
echo  백업 파일들:
if exist install_log_corrupted_backup.txt echo   - install_log_corrupted_backup.txt (손상된 로그)
if exist backend\email_manager_backup_*.db echo   - email_manager_backup_*.db (데이터베이스)
if exist "이메일관리자_실행_백업.bat" echo   - 이메일관리자_실행_백업.bat (실행 스크립트)
echo.
echo  로그 파일: %CLEAN_LOG%
echo.

echo [%date% %time%] 사용자에게 완료 안내 표시 >> %CLEAN_LOG%

echo 재부팅을 권장합니다. 지금 재부팅하시겠습니까? (Y/N)
set /p REBOOT_CHOICE="선택: "

if /i "%REBOOT_CHOICE%"=="Y" (
    echo 5초 후 재부팅됩니다...
    timeout /t 5 /nobreak
    shutdown /r /t 0
) else (
    echo.
    echo 환경 정리가 완료되었습니다.
    echo 창을 닫으려면 아무 키나 누르세요...
    pause >nul
)