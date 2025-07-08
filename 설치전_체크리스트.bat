@echo off
title 이메일 관리자 - 설치 전 체크리스트
chcp 65001 > nul
color 0E

cls
echo.
echo  ################################################################
echo                    설치 전 체크리스트 및 준비사항
echo  ################################################################
echo.
echo  이 스크립트는 안전한 설치를 위한 사전 점검을 수행합니다.
echo.
echo  ################################################################
echo.

set CHECKLIST_LOG=설치전체크_로그.log
echo [%date% %time%] 설치 전 체크리스트 시작 > %CHECKLIST_LOG%

:: 관리자 권한 확인
echo [1/10] 관리자 권한 확인...
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo    [ERROR] 관리자 권한이 없습니다!
    echo    해결책: 이 파일을 마우스 우클릭 → "관리자 권한으로 실행"
    echo [%date% %time%] 관리자 권한 없음 >> %CHECKLIST_LOG%
    goto :checklist_failed
) else (
    echo    [OK] 관리자 권한으로 실행 중
    echo [%date% %time%] 관리자 권한 확인 >> %CHECKLIST_LOG%
)

:: 바이러스 백신 간섭 확인
echo [2/10] 바이러스 백신 프로세스 확인...
tasklist /fi "imagename eq avp.exe" 2>nul | find /i "avp.exe" >nul && set AV_KASPERSKY=1
tasklist /fi "imagename eq avgnt.exe" 2>nul | find /i "avgnt.exe" >nul && set AV_AVIRA=1
tasklist /fi "imagename eq msmpeng.exe" 2>nul | find /i "msmpeng.exe" >nul && set AV_DEFENDER=1

if defined AV_KASPERSKY echo    [INFO] Kaspersky 바이러스 백신 감지됨
if defined AV_AVIRA echo    [INFO] Avira 바이러스 백신 감지됨
if defined AV_DEFENDER echo    [INFO] Windows Defender 감지됨

if defined AV_KASPERSKY set ANTIVIRUS_DETECTED=1
if defined AV_AVIRA set ANTIVIRUS_DETECTED=1
if defined AV_DEFENDER set ANTIVIRUS_DETECTED=1

if defined ANTIVIRUS_DETECTED (
    echo    [WARNING] 바이러스 백신이 설치 과정을 방해할 수 있습니다.
    echo    권장사항: 설치 중 실시간 검사 일시 중지
    echo [%date% %time%] 바이러스 백신 감지됨 >> %CHECKLIST_LOG%
) else (
    echo    [OK] 바이러스 백신 간섭 없음
    echo [%date% %time%] 바이러스 백신 간섭 없음 >> %CHECKLIST_LOG%
)

:: 디스크 공간 확인
echo [3/10] 디스크 공간 확인...
for /f "tokens=3" %%a in ('dir /-c %~dp0 ^| findstr /i "bytes free"') do set FREE_SPACE=%%a
if defined FREE_SPACE (
    if %FREE_SPACE% lss 2147483648 (
        echo    [ERROR] 디스크 공간 부족! 현재: %FREE_SPACE% bytes
        echo    필요: 최소 2GB의 여유 공간
        echo [%date% %time%] 디스크 공간 부족: %FREE_SPACE% >> %CHECKLIST_LOG%
        goto :checklist_failed
    ) else (
        echo    [OK] 충분한 디스크 공간 (%FREE_SPACE% bytes)
        echo [%date% %time%] 디스크 공간 충분: %FREE_SPACE% >> %CHECKLIST_LOG%
    )
) else (
    echo    [WARNING] 디스크 공간을 확인할 수 없습니다
    echo [%date% %time%] 디스크 공간 확인 불가 >> %CHECKLIST_LOG%
)

:: 인터넷 연결 확인
echo [4/10] 인터넷 연결 확인...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% equ 0 (
    echo    [OK] 인터넷 연결 정상
    echo [%date% %time%] 인터넷 연결 정상 >> %CHECKLIST_LOG%
) else (
    echo    [ERROR] 인터넷 연결이 필요합니다!
    echo    패키지 다운로드를 위해 인터넷 연결을 확인하세요.
    echo [%date% %time%] 인터넷 연결 없음 >> %CHECKLIST_LOG%
    goto :checklist_failed
)

:: 포트 사용 확인
echo [5/10] 포트 사용 상태 확인...
netstat -an | findstr ":5000" >nul 2>&1
if %errorLevel% equ 0 (
    echo    [WARNING] 포트 5000이 사용 중입니다!
    echo    해결책: 다른 프로그램을 종료하거나 환경정리.bat 실행
    echo [%date% %time%] 포트 5000 사용 중 >> %CHECKLIST_LOG%
    set PORT_CONFLICT=1
) else (
    echo    [OK] 포트 5000 사용 가능
    echo [%date% %time%] 포트 5000 사용 가능 >> %CHECKLIST_LOG%
)

netstat -an | findstr ":3000" >nul 2>&1
if %errorLevel% equ 0 (
    echo    [WARNING] 포트 3000이 사용 중입니다!
    echo    해결책: 다른 프로그램을 종료하거나 환경정리.bat 실행
    echo [%date% %time%] 포트 3000 사용 중 >> %CHECKLIST_LOG%
    set PORT_CONFLICT=1
) else (
    echo    [OK] 포트 3000 사용 가능
    echo [%date% %time%] 포트 3000 사용 가능 >> %CHECKLIST_LOG%
)

:: Python 설치 확인
echo [6/10] Python 설치 확인...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] Python이 설치되지 않았습니다!
    echo    해결책: https://www.python.org/downloads/ 방문
    echo [%date% %time%] Python 미설치 >> %CHECKLIST_LOG%
    goto :checklist_failed
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do (
        echo    [OK] Python %%i 설치됨
        echo [%date% %time%] Python %%i 확인됨 >> %CHECKLIST_LOG%
    )
)

:: Node.js 설치 확인
echo [7/10] Node.js 설치 확인...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] Node.js가 설치되지 않았습니다!
    echo    해결책: https://nodejs.org/ 방문
    echo [%date% %time%] Node.js 미설치 >> %CHECKLIST_LOG%
    goto :checklist_failed
) else (
    for /f %%i in ('node --version 2^>^&1') do (
        echo    [OK] Node.js %%i 설치됨
        echo [%date% %time%] Node.js %%i 확인됨 >> %CHECKLIST_LOG%
    )
)

:: 파일 권한 확인
echo [8/10] 파일 시스템 권한 확인...
echo test > test_write.tmp 2>nul
if exist test_write.tmp (
    del test_write.tmp >nul 2>&1
    echo    [OK] 파일 쓰기 권한 정상
    echo [%date% %time%] 파일 쓰기 권한 정상 >> %CHECKLIST_LOG%
) else (
    echo    [ERROR] 파일 쓰기 권한이 없습니다!
    echo    해결책: 관리자 권한으로 실행하거나 폴더 권한 확인
    echo [%date% %time%] 파일 쓰기 권한 없음 >> %CHECKLIST_LOG%
    goto :checklist_failed
)

:: 기존 설치 흔적 확인
echo [9/10] 기존 설치 흔적 확인...
set EXISTING_INSTALL=0
if exist venv (
    echo    [INFO] 기존 Python 가상환경 발견
    set EXISTING_INSTALL=1
)
if exist frontend\node_modules (
    echo    [INFO] 기존 Node.js 모듈 발견
    set EXISTING_INSTALL=1
)
if exist backend\email_manager.db (
    echo    [INFO] 기존 데이터베이스 발견
    set EXISTING_INSTALL=1
)

if %EXISTING_INSTALL% equ 1 (
    echo    [WARNING] 기존 설치 파일들이 있습니다.
    echo    권장사항: 먼저 환경정리.bat 실행
    echo [%date% %time%] 기존 설치 흔적 발견 >> %CHECKLIST_LOG%
) else (
    echo    [OK] 깨끗한 환경
    echo [%date% %time%] 깨끗한 환경 확인 >> %CHECKLIST_LOG%
)

:: 시스템 리소스 확인
echo [10/10] 시스템 리소스 확인...
for /f "skip=1 tokens=4" %%i in ('wmic computersystem get TotalPhysicalMemory') do (
    if not "%%i"=="" (
        set /a TOTAL_RAM=%%i/1024/1024
        goto :ram_check_done
    )
)
:ram_check_done

if defined TOTAL_RAM (
    if %TOTAL_RAM% lss 2048 (
        echo    [WARNING] RAM이 부족할 수 있습니다. 현재: %TOTAL_RAM%MB
        echo    권장: 최소 2GB RAM
        echo [%date% %time%] RAM 부족: %TOTAL_RAM%MB >> %CHECKLIST_LOG%
    ) else (
        echo    [OK] 충분한 RAM (%TOTAL_RAM%MB)
        echo [%date% %time%] RAM 충분: %TOTAL_RAM%MB >> %CHECKLIST_LOG%
    )
) else (
    echo    [INFO] RAM 정보를 확인할 수 없습니다
    echo [%date% %time%] RAM 정보 확인 불가 >> %CHECKLIST_LOG%
)

:: 최종 결과
echo.
echo  ################################################################
echo                        체크리스트 결과
echo  ################################################################
echo.

if defined PORT_CONFLICT (
    echo  [WARNING] 포트 충돌이 감지되었습니다.
    echo  권장사항: 환경정리.bat를 먼저 실행하세요.
    echo.
)

if %EXISTING_INSTALL% equ 1 (
    echo  [WARNING] 기존 설치 파일이 있습니다.
    echo  권장사항: 환경정리.bat를 먼저 실행하세요.
    echo.
)

echo  [SUCCESS] 기본 시스템 요구사항이 충족되었습니다!
echo.
echo  다음 단계:
echo   1. 포트 충돌이나 기존 설치가 있다면 '환경정리.bat' 실행
echo   2. 'INSTALL.bat'를 관리자 권한으로 실행
echo   3. 문제 발생 시 '단계별검증.bat' 활용
echo.
echo  추가 도구:
echo   - 환경정리.bat: 기존 설치 완전 제거
echo   - 단계별검증.bat: 단계별 설치 및 검증
echo   - 설치검증.bat: 설치 후 종합 검증
echo.

echo [%date% %time%] 체크리스트 완료 - 설치 준비됨 >> %CHECKLIST_LOG%
echo 로그 파일: %CHECKLIST_LOG%
echo.
echo 아무 키나 누르면 종료됩니다...
pause >nul
exit /b 0

:checklist_failed
echo.
echo  ################################################################
echo                        체크리스트 실패!
echo  ################################################################
echo.
echo  위의 문제들을 해결한 후 다시 실행하세요.
echo.
echo  일반적인 해결 방법:
echo   1. 관리자 권한으로 실행
echo   2. 인터넷 연결 확인
echo   3. Python/Node.js 설치
echo   4. 바이러스 백신 일시 중지
echo   5. 디스크 공간 확보
echo.

echo [%date% %time%] 체크리스트 실패 >> %CHECKLIST_LOG%
echo 로그 파일: %CHECKLIST_LOG%
echo.
echo 아무 키나 누르면 종료됩니다...
pause >nul
exit /b 1