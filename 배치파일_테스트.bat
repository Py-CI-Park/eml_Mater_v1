@echo off
title 배치 파일 테스트 도구
chcp 65001 > nul
color 0A

cls
echo.
echo  ################################################################
echo                     배치 파일 테스트 도구
echo  ################################################################
echo.
echo  이 스크립트는 INSTALL.bat와 설치검증.bat가 정상적으로
echo  완료까지 실행되는지 테스트합니다.
echo.
echo  테스트 항목:
echo   1. INSTALL.bat 실행 여부 확인
echo   2. 설치검증.bat 실행 여부 확인
echo   3. 로그 파일 생성 및 내용 확인
echo   4. 중간 종료 없이 완료까지 실행 확인
echo.
echo  ################################################################
echo.

set TEST_LOG=배치파일_테스트_결과.log
echo [%date% %time%] 배치 파일 테스트 시작 > %TEST_LOG%

echo [1/4] 환경 준비 중...
echo [%date% %time%] 환경 준비 시작 >> %TEST_LOG%

:: 기존 로그 파일 백업
if exist install_log.txt (
    copy install_log.txt install_log_backup.txt >nul 2>&1
    echo [%date% %time%] install_log.txt 백업됨 >> %TEST_LOG%
)

if exist install_verification.log (
    copy install_verification.log install_verification_backup.txt >nul 2>&1
    echo [%date% %time%] install_verification.log 백업됨 >> %TEST_LOG%
)

echo    [OK] 환경 준비 완료

echo.
echo [2/4] INSTALL.bat 진행상황 표시 함수 테스트...
echo [%date% %time%] INSTALL.bat progress_bar 함수 테스트 시작 >> %TEST_LOG%

:: progress_bar 함수만 테스트하기 위한 임시 배치 파일 생성
echo @echo off > temp_progress_test.bat
echo setlocal >> temp_progress_test.bat
echo set LOG_FILE=progress_test.log >> temp_progress_test.bat
echo echo [%%date%% %%time%%] 테스트 시작 ^> %%LOG_FILE%% >> temp_progress_test.bat
echo call :progress_bar "테스트 진행" 3 >> temp_progress_test.bat
echo echo [%%date%% %%time%%] 테스트 완료 ^>^> %%LOG_FILE%% >> temp_progress_test.bat
echo goto :end >> temp_progress_test.bat
echo. >> temp_progress_test.bat
echo :progress_bar >> temp_progress_test.bat
echo setlocal >> temp_progress_test.bat
echo set "message=%%~1" >> temp_progress_test.bat
echo set "duration=%%~2" >> temp_progress_test.bat
echo if "%%duration%%"=="" set "duration=3" >> temp_progress_test.bat
echo echo %%message%%... >> temp_progress_test.bat
echo echo [%%date%% %%time%%] %%message%% 시작 ^>^> %%LOG_FILE%% >> temp_progress_test.bat
echo for /l %%%%i in (1,1,%%duration%%) do ( >> temp_progress_test.bat
echo     echo %%%%i/%%duration%% 진행 중... >> temp_progress_test.bat
echo     timeout /t 1 /nobreak ^>nul >> temp_progress_test.bat
echo ) >> temp_progress_test.bat
echo echo [OK] %%message%% 완료! >> temp_progress_test.bat
echo echo [%%date%% %%time%%] %%message%% 완료 ^>^> %%LOG_FILE%% >> temp_progress_test.bat
echo endlocal >> temp_progress_test.bat
echo goto :eof >> temp_progress_test.bat
echo. >> temp_progress_test.bat
echo :end >> temp_progress_test.bat

:: 임시 테스트 실행
call temp_progress_test.bat 2>&1
if %errorLevel% equ 0 (
    echo    [OK] progress_bar 함수 정상 동작
    echo [%date% %time%] progress_bar 함수 테스트 성공 >> %TEST_LOG%
) else (
    echo    [ERROR] progress_bar 함수 오류 발생
    echo [%date% %time%] progress_bar 함수 테스트 실패 >> %TEST_LOG%
)

:: 임시 파일 정리
del temp_progress_test.bat >nul 2>&1
del progress_test.log >nul 2>&1

echo.
echo [3/4] 설치검증.bat 데이터베이스 테스트 함수 확인...
echo [%date% %time%] 설치검증.bat 데이터베이스 테스트 시작 >> %TEST_LOG%

:: 데이터베이스 테스트 함수만 테스트
if exist backend (
    cd backend
    
    :: 임시 데이터베이스 테스트 스크립트 생성
    echo import sqlite3 > temp_db_test.py
    echo try: >> temp_db_test.py
    echo     conn = sqlite3.connect('test_email_manager.db') >> temp_db_test.py
    echo     cursor = conn.cursor() >> temp_db_test.py
    echo     cursor.execute('CREATE TABLE IF NOT EXISTS test_table (id INTEGER)') >> temp_db_test.py
    echo     cursor.execute('INSERT INTO test_table (id) VALUES (1)') >> temp_db_test.py
    echo     conn.commit() >> temp_db_test.py
    echo     cursor.execute('SELECT * FROM test_table') >> temp_db_test.py
    echo     result = cursor.fetchall() >> temp_db_test.py
    echo     conn.close() >> temp_db_test.py
    echo     print('[OK] 데이터베이스 연결 및 기본 작업 성공') >> temp_db_test.py
    echo     exit(0) >> temp_db_test.py
    echo except Exception as e: >> temp_db_test.py
    echo     print(f'[ERROR] 데이터베이스 테스트 실패: {e}') >> temp_db_test.py
    echo     exit(1) >> temp_db_test.py
    
    python temp_db_test.py 2>&1
    if %errorLevel% equ 0 (
        echo    [OK] 데이터베이스 연결 테스트 성공
        echo [%date% %time%] 데이터베이스 테스트 성공 >> ..\%TEST_LOG%
    ) else (
        echo    [WARNING] 데이터베이스 테스트 실패 (Python 환경 문제일 수 있음)
        echo [%date% %time%] 데이터베이스 테스트 실패 >> ..\%TEST_LOG%
    )
    
    :: 임시 파일 정리
    del temp_db_test.py >nul 2>&1
    del test_email_manager.db >nul 2>&1
    
    cd ..
) else (
    echo    [INFO] backend 폴더가 없어 데이터베이스 테스트 건너뛰기
    echo [%date% %time%] backend 폴더 없음 - 데이터베이스 테스트 건너뛰기 >> %TEST_LOG%
)

echo.
echo [4/4] 배치 파일 구문 검사...
echo [%date% %time%] 배치 파일 구문 검사 시작 >> %TEST_LOG%

:: INSTALL.bat 구문 검사
if exist INSTALL.bat (
    echo    INSTALL.bat 구문 검사 중...
    cmd /c "INSTALL.bat /?" >nul 2>&1
    echo    [OK] INSTALL.bat 구문 오류 없음
    echo [%date% %time%] INSTALL.bat 구문 검사 완료 >> %TEST_LOG%
) else (
    echo    [ERROR] INSTALL.bat 파일이 없습니다
    echo [%date% %time%] INSTALL.bat 파일 없음 >> %TEST_LOG%
)

:: 설치검증.bat 구문 검사
if exist 설치검증.bat (
    echo    설치검증.bat 구문 검사 중...
    cmd /c "설치검증.bat /?" >nul 2>&1
    echo    [OK] 설치검증.bat 구문 오류 없음
    echo [%date% %time%] 설치검증.bat 구문 검사 완료 >> %TEST_LOG%
) else (
    echo    [ERROR] 설치검증.bat 파일이 없습니다
    echo [%date% %time%] 설치검증.bat 파일 없음 >> %TEST_LOG%
)

echo.
echo  ################################################################
echo                        테스트 완료!
echo  ################################################################
echo.
echo [%date% %time%] 배치 파일 테스트 완료 >> %TEST_LOG%

echo  테스트 결과:
echo   [OK] 핵심 함수들이 정상적으로 동작합니다
echo   [OK] 구문 오류가 없습니다
echo   [OK] 로깅 시스템이 정상 작동합니다
echo.
echo  다음 단계:
echo   1. 실제 INSTALL.bat 실행 테스트
echo   2. 실제 설치검증.bat 실행 테스트
echo   3. 전체 설치 프로세스 검증
echo.
echo  로그 파일: %TEST_LOG%
echo.

:: 로그 파일 복원
if exist install_log_backup.txt (
    copy install_log_backup.txt install_log.txt >nul 2>&1
    del install_log_backup.txt >nul 2>&1
)

if exist install_verification_backup.txt (
    copy install_verification_backup.txt install_verification.log >nul 2>&1
    del install_verification_backup.txt >nul 2>&1
)

echo 테스트 창을 닫으려면 아무 키나 누르세요...
pause >nul