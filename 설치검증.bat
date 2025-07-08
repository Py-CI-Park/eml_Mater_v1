@echo off
title 이메일 관리자 - 설치 검증
chcp 65001 > nul
color 0A

cls
echo.
echo  ################################################################
echo    ##### #    # ##### ##### #   #    #### #   # ##### ##### # #
echo      #   #    #   #   #     ##  #   #     #   # #     #     # #
echo      #   ######   #   ###   # # #   #     ##### ###   ###   ###
echo      #   #    #   #   #     #  ##   #     #   # #     #     # #
echo      #   #    #   #   ##### #   #    #### #   # ##### ##### # #
echo.
echo    ######  ##### ####  #   # #     ##### ####
echo    #    #  #     #     #   # #       #   #
echo    ####    ###   ####  #   # #       #   ####
echo    #  #    #         # #   # #       #       #
echo    #   #   ##### ####   ###  #####   #   ####
echo  ################################################################
echo                       설치 및 시스템 검증
echo  ################################################################
echo.

set LOG_FILE=install_verification.log
echo [%date% %time%] 설치 검증 시작 > %LOG_FILE%

echo  검증 항목:
echo   1. 시스템 요구사항 (Python, Node.js)
echo   2. 프로젝트 환경 (가상환경, 패키지)
echo   3. 데이터베이스 연결
echo   4. 포트 사용 가능성
echo   5. 설정 파일 유효성
echo   6. 서버 시작 테스트
echo.

pause

:: ========================================
:: 1단계: 시스템 요구사항 확인
:: ========================================
echo.
echo  ################################################################
echo                    1. 시스템 요구사항 확인
echo  ################################################################
echo.

echo [1/6] Python 확인...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] Python이 설치되지 않았습니다!
    echo    해결책: https://www.python.org/downloads/ 에서 Python 설치
    echo [%date% %time%] Python 미설치 >> %LOG_FILE%
    goto :verification_failed
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do (
        echo    [OK] Python %%i 설치됨
        echo [%date% %time%] Python %%i 확인됨 >> %LOG_FILE%
    )
)

echo [1/6] pip 확인...
echo [%date% %time%] pip 확인 시작 >> %LOG_FILE%
pip --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] pip가 설치되지 않았습니다!
    echo [%date% %time%] pip 미설치 >> %LOG_FILE%
    goto :verification_failed
) else (
    echo    [OK] pip 사용 가능
    echo [%date% %time%] pip 사용 가능 확인됨 >> %LOG_FILE%
)

echo [1/6] Node.js 확인...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] Node.js가 설치되지 않았습니다!
    echo    해결책: https://nodejs.org/ 에서 Node.js LTS 버전 설치
    echo [%date% %time%] Node.js 미설치 >> %LOG_FILE%
    goto :verification_failed
) else (
    for /f %%i in ('node --version 2^>^&1') do (
        echo    [OK] Node.js %%i 설치됨
        echo [%date% %time%] Node.js %%i 확인됨 >> %LOG_FILE%
    )
)

echo [1/6] npm 확인...
echo [%date% %time%] npm 확인 시작 >> %LOG_FILE%
npm --version >nul 2>&1
if %errorLevel% neq 0 (
    echo    [ERROR] npm이 설치되지 않았습니다!
    echo [%date% %time%] npm 미설치 >> %LOG_FILE%
    goto :verification_failed
) else (
    for /f "tokens=1" %%i in ('npm --version 2^>^&1') do (
        echo    [OK] npm %%i 사용 가능
        echo [%date% %time%] npm %%i 확인됨 >> %LOG_FILE%
    )
)

:: ========================================
:: 2단계: 프로젝트 환경 확인
:: ========================================
echo.
echo  ################################################################
echo                    2. 프로젝트 환경 확인
echo  ################################################################
echo.

echo [2/6] Python 가상환경 확인...
echo [%date% %time%] Python 가상환경 확인 시작 >> %LOG_FILE%
if exist venv (
    echo    [OK] Python 가상환경 존재
    echo [%date% %time%] venv 폴더 확인됨 >> %LOG_FILE%
    if exist venv\Scripts\activate.bat (
        echo    [OK] 가상환경 활성화 스크립트 존재
        echo [%date% %time%] activate.bat 스크립트 확인됨 >> %LOG_FILE%
    ) else (
        echo    [ERROR] 가상환경 활성화 스크립트 없음
        echo [%date% %time%] activate.bat 스크립트 누락 >> %LOG_FILE%
        goto :verification_failed
    )
) else (
    echo    [ERROR] Python 가상환경이 없습니다!
    echo    해결책: INSTALL.bat를 다시 실행하세요
    echo [%date% %time%] venv 폴더 누락 >> %LOG_FILE%
    goto :verification_failed
)

echo [2/6] Python 패키지 확인...
echo [%date% %time%] Python 패키지 확인 시작 >> %LOG_FILE%
call venv\Scripts\activate.bat
echo [%date% %time%] 가상환경 활성화됨 >> %LOG_FILE%

:: 임시 Python 스크립트로 패키지 확인
echo import sys > temp_package_test.py
echo try: >> temp_package_test.py
echo     import flask, flask_cors, dateutil, chardet >> temp_package_test.py
echo     print('[OK] 모든 필수 Python 패키지 설치됨') >> temp_package_test.py
echo     print(f'Flask 버전: {flask.__version__}') >> temp_package_test.py
echo     exit(0) >> temp_package_test.py
echo except ImportError as e: >> temp_package_test.py
echo     print(f'[ERROR] 패키지 누락: {e}') >> temp_package_test.py
echo     exit(1) >> temp_package_test.py

python temp_package_test.py >> %LOG_FILE% 2>&1
set PACKAGE_TEST_RESULT=%errorLevel%
del temp_package_test.py >nul 2>&1

if %PACKAGE_TEST_RESULT% neq 0 (
    echo    [ERROR] 필수 Python 패키지가 누락되었습니다!
    echo    해결책: backend 폴더에서 'pip install -r requirements.txt' 실행
    echo [%date% %time%] Python 패키지 확인 실패 >> %LOG_FILE%
    goto :verification_failed
) else (
    echo    [OK] 모든 필수 Python 패키지 설치됨
    echo [%date% %time%] Python 패키지 확인 성공 >> %LOG_FILE%
)

echo [2/6] Node.js 모듈 확인...
echo [%date% %time%] Node.js 모듈 확인 시작 >> %LOG_FILE%
if exist frontend\node_modules (
    echo    [OK] Node.js 모듈 설치됨
    echo [%date% %time%] frontend\node_modules 폴더 확인됨 >> %LOG_FILE%
    if exist frontend\package.json (
        echo    [OK] package.json 존재
        echo [%date% %time%] frontend\package.json 확인됨 >> %LOG_FILE%
    ) else (
        echo    [ERROR] package.json이 없습니다!
        echo [%date% %time%] frontend\package.json 누락 >> %LOG_FILE%
        goto :verification_failed
    )
) else (
    echo    [ERROR] Node.js 모듈이 설치되지 않았습니다!
    echo    해결책: frontend 폴더에서 'npm install --legacy-peer-deps' 실행
    echo [%date% %time%] frontend\node_modules 폴더 누락 >> %LOG_FILE%
    goto :verification_failed
)

:: ========================================
:: 3단계: 데이터베이스 연결 확인
:: ========================================
echo.
echo  ################################################################
echo                    3. 데이터베이스 연결 확인
echo  ################################################################
echo.

echo [3/6] SQLite 데이터베이스 확인...
cd backend
if exist email_manager.db (
    echo    [OK] SQLite 데이터베이스 파일 존재
) else (
    echo    [INFO] 데이터베이스 파일이 없습니다. 첫 실행 시 자동 생성됩니다.
)

echo [3/6] 데이터베이스 연결 테스트...
echo [%date% %time%] 데이터베이스 테스트 시작 >> %LOG_FILE%

:: 임시 Python 스크립트 생성
echo import sqlite3 > temp_db_test.py
echo try: >> temp_db_test.py
echo     conn = sqlite3.connect('email_manager.db') >> temp_db_test.py
echo     cursor = conn.cursor() >> temp_db_test.py
echo     cursor.execute('SELECT name FROM sqlite_master WHERE type=\"table\"') >> temp_db_test.py
echo     tables = cursor.fetchall() >> temp_db_test.py
echo     conn.close() >> temp_db_test.py
echo     print('[OK] 데이터베이스 연결 성공') >> temp_db_test.py
echo     if len(tables) ^> 0: >> temp_db_test.py
echo         print(f'[OK] {len(tables)}개 테이블 존재') >> temp_db_test.py
echo     else: >> temp_db_test.py
echo         print('[INFO] 테이블이 없음 - 첫 실행 시 자동 생성') >> temp_db_test.py
echo     exit(0) >> temp_db_test.py
echo except Exception as e: >> temp_db_test.py
echo     print(f'[ERROR] 데이터베이스 연결 실패: {e}') >> temp_db_test.py
echo     exit(1) >> temp_db_test.py

python temp_db_test.py >> %LOG_FILE% 2>&1
set DB_TEST_RESULT=%errorLevel%
del temp_db_test.py >nul 2>&1

if %DB_TEST_RESULT% neq 0 (
    echo    [ERROR] 데이터베이스 연결 테스트 실패!
    echo [%date% %time%] 데이터베이스 테스트 실패 >> %LOG_FILE%
    goto :verification_failed
) else (
    echo    [OK] 데이터베이스 연결 성공
    echo [%date% %time%] 데이터베이스 테스트 성공 >> %LOG_FILE%
)
cd ..

echo [3/6] 설정 파일 확인...
echo [%date% %time%] 설정 파일 확인 시작 >> %LOG_FILE%
if exist backend\config.json (
    echo    [OK] 설정 파일 존재
    echo [%date% %time%] backend\config.json 파일 발견 >> %LOG_FILE%
    
    :: 임시 Python 스크립트로 설정 파일 검증
    echo import json > temp_config_test.py
    echo try: >> temp_config_test.py
    echo     with open('backend/config.json', 'r', encoding='utf-8') as f: >> temp_config_test.py
    echo         config = json.load(f) >> temp_config_test.py
    echo     print('[OK] 설정 파일 유효함') >> temp_config_test.py
    echo     if 'email_root' in config: >> temp_config_test.py
    echo         print(f'[INFO] 이메일 루트: {config.get(\\\"email_root\\\", \\\"미설정\\\")}') >> temp_config_test.py
    echo     if 'port' in config: >> temp_config_test.py
    echo         print(f'[INFO] 백엔드 포트: {config.get(\\\"port\\\", 5000)}') >> temp_config_test.py
    echo     exit(0) >> temp_config_test.py
    echo except Exception as e: >> temp_config_test.py
    echo     print(f'[ERROR] 설정 파일 오류: {e}') >> temp_config_test.py
    echo     exit(1) >> temp_config_test.py
    
    python temp_config_test.py >> %LOG_FILE% 2>&1
    set CONFIG_TEST_RESULT=%errorLevel%
    del temp_config_test.py >nul 2>&1
    
    if %CONFIG_TEST_RESULT% neq 0 (
        echo    [ERROR] 설정 파일이 손상되었습니다!
        echo [%date% %time%] 설정 파일 검증 실패 >> %LOG_FILE%
        goto :verification_failed
    ) else (
        echo    [OK] 설정 파일 검증 완료
        echo [%date% %time%] 설정 파일 검증 성공 >> %LOG_FILE%
    )
) else (
    echo    [INFO] 설정 파일이 없습니다. 첫 실행 시 자동 생성됩니다.
    echo [%date% %time%] 설정 파일 없음 - 자동 생성 예정 >> %LOG_FILE%
)

:: ========================================
:: 4단계: 포트 사용 가능성 확인
:: ========================================
echo.
echo  ################################################################
echo                    4. 포트 사용 가능성 확인
echo  ################################################################
echo.

echo [4/6] 포트 5000 (백엔드) 확인...
echo [%date% %time%] 포트 5000 확인 시작 >> %LOG_FILE%
netstat -an | findstr :5000 >nul 2>&1
if %errorLevel% equ 0 (
    echo    [WARNING] 포트 5000이 이미 사용 중입니다!
    echo    해결책: 다른 프로그램을 종료하거나 '이메일관리자_종료.bat' 실행
    echo [%date% %time%] 포트 5000 사용 중 감지 >> %LOG_FILE%
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000') do (
        if "%%a" neq "" (
            echo    프로세스 ID: %%a
            echo [%date% %time%] 포트 5000 사용 프로세스 ID: %%a >> %LOG_FILE%
        )
    )
) else (
    echo    [OK] 포트 5000 사용 가능
    echo [%date% %time%] 포트 5000 사용 가능 확인 >> %LOG_FILE%
)

echo [4/6] 포트 3000 (프론트엔드) 확인...
echo [%date% %time%] 포트 3000 확인 시작 >> %LOG_FILE%
netstat -an | findstr :3000 >nul 2>&1
if %errorLevel% equ 0 (
    echo    [WARNING] 포트 3000이 이미 사용 중입니다!
    echo    해결책: 다른 프로그램을 종료하거나 '이메일관리자_종료.bat' 실행
    echo [%date% %time%] 포트 3000 사용 중 감지 >> %LOG_FILE%
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000') do (
        if "%%a" neq "" (
            echo    프로세스 ID: %%a
            echo [%date% %time%] 포트 3000 사용 프로세스 ID: %%a >> %LOG_FILE%
        )
    )
) else (
    echo    [OK] 포트 3000 사용 가능
    echo [%date% %time%] 포트 3000 사용 가능 확인 >> %LOG_FILE%
)

:: ========================================
:: 5단계: 실행 스크립트 확인
:: ========================================
echo.
echo  ################################################################
echo                    5. 실행 스크립트 확인
echo  ################################################################
echo.

echo [5/6] 실행 스크립트 존재 확인...
echo [%date% %time%] 실행 스크립트 확인 시작 >> %LOG_FILE%

if exist "이메일관리자_실행.bat" (
    echo    [OK] 이메일관리자_실행.bat 존재
    echo [%date% %time%] 이메일관리자_실행.bat 확인됨 >> %LOG_FILE%
) else (
    echo    [ERROR] 실행 스크립트가 없습니다!
    echo    해결책: INSTALL.bat를 다시 실행하세요
    echo [%date% %time%] 이메일관리자_실행.bat 누락 - 검증 실패 >> %LOG_FILE%
    goto :verification_failed
)

if exist "이메일관리자_종료.bat" (
    echo    [OK] 이메일관리자_종료.bat 존재
    echo [%date% %time%] 이메일관리자_종료.bat 확인됨 >> %LOG_FILE%
) else (
    echo    [WARNING] 종료 스크립트가 없습니다
    echo [%date% %time%] 이메일관리자_종료.bat 누락 (경고) >> %LOG_FILE%
)

if exist "이메일관리자_상태확인.bat" (
    echo    [OK] 이메일관리자_상태확인.bat 존재
    echo [%date% %time%] 이메일관리자_상태확인.bat 확인됨 >> %LOG_FILE%
) else (
    echo    [WARNING] 상태확인 스크립트가 없습니다
    echo [%date% %time%] 이메일관리자_상태확인.bat 누락 (경고) >> %LOG_FILE%
)

:: ========================================
:: 6단계: 빠른 서버 시작 테스트
:: ========================================
echo.
echo  ################################################################
echo                    6. 빠른 서버 시작 테스트
echo  ################################################################
echo.

echo [6/6] 서버 시작 테스트를 수행하시겠습니까?
echo       (Y: 테스트 실행, N: 건너뛰기)
set /p SERVER_TEST="선택 (Y/N): "

echo [%date% %time%] 서버 테스트 선택: %SERVER_TEST% >> %LOG_FILE%

if /i "%SERVER_TEST%"=="Y" (
    echo.
    echo 백엔드 서버 시작 테스트 중...
    echo (10초 후 자동 종료됩니다)
    echo [%date% %time%] 백엔드 서버 시작 테스트 시작 >> %LOG_FILE%
    
    cd backend
    echo [%date% %time%] 가상환경 활성화 시도 >> ..\%LOG_FILE%
    
    :: 백엔드 서버를 백그라운드에서 시작
    start /min cmd /c "call ..\venv\Scripts\activate.bat && python app.py > server_test.log 2>&1"
    echo [%date% %time%] 백엔드 서버 프로세스 시작됨 >> ..\%LOG_FILE%
    
    :: 서버 시작 대기
    echo 서버 시작 대기 중... (5초)
    timeout /t 5 /nobreak >nul
    
    :: 서버 응답 테스트
    echo 서버 응답 테스트...
    echo [%date% %time%] 서버 응답 테스트 시작 >> ..\%LOG_FILE%
    
    :: curl이 없는 경우를 위한 대체 방법
    curl -s http://localhost:5000/api/config >nul 2>&1
    if %errorLevel% equ 0 (
        echo    [OK] 백엔드 서버 정상 응답
        echo [%date% %time%] 백엔드 서버 응답 성공 >> ..\%LOG_FILE%
    ) else (
        echo    [WARNING] 백엔드 서버 응답 없음
        echo    서버 로그 확인 중...
        if exist server_test.log (
            echo [%date% %time%] 서버 테스트 로그 내용: >> ..\%LOG_FILE%
            type server_test.log >> ..\%LOG_FILE% 2>&1
        )
        echo [%date% %time%] 백엔드 서버 응답 실패 또는 지연 >> ..\%LOG_FILE%
    )
    
    :: 테스트 서버 정리
    echo 테스트 서버 종료...
    echo [%date% %time%] 테스트 서버 종료 시작 >> ..\%LOG_FILE%
    
    :: 포트 5000을 사용하는 프로세스 강제 종료
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 2^>nul') do (
        if "%%a" neq "" (
            taskkill /PID %%a /F >nul 2>&1
            echo [%date% %time%] 프로세스 ID %%a 종료됨 >> ..\%LOG_FILE%
        )
    )
    
    :: 임시 로그 파일 정리
    if exist server_test.log del server_test.log >nul 2>&1
    
    echo [%date% %time%] 서버 테스트 정리 완료 >> ..\%LOG_FILE%
    cd ..
) else (
    echo    [SKIP] 서버 테스트 건너뛰기
    echo [%date% %time%] 서버 테스트 건너뛰기 >> %LOG_FILE%
)

:: ========================================
:: 검증 완료
:: ========================================
echo.
echo  ################################################################
echo                        검증 완료!
echo  ################################################################
echo.

echo [%date% %time%] 설치 검증 성공적으로 완료 >> %LOG_FILE%
echo [%date% %time%] 모든 구성 요소 정상 확인됨 >> %LOG_FILE%

echo  검증 결과:
echo   [OK] 시스템이 정상적으로 설정되었습니다!
echo.
echo  다음 단계:
echo   1. '이메일관리자_실행.bat' 실행
echo   2. 브라우저에서 http://localhost:3000 접속
echo   3. 설정에서 이메일 폴더 경로 지정
echo.
echo  문제 해결:
echo   - 로그 파일: %LOG_FILE%
echo   - 상태 확인: '이메일관리자_상태확인.bat'
echo   - 재설치: 'INSTALL.bat'
echo.

echo [%date% %time%] 사용자에게 완료 안내 표시 >> %LOG_FILE%

goto :end

:verification_failed
echo.
echo  ################################################################
echo                        검증 실패!
echo  ################################################################
echo.
echo [%date% %time%] 설치 검증 실패 - 구성 요소 문제 발견 >> %LOG_FILE%
echo [%date% %time%] 상세 오류 정보는 로그 파일 참조: %LOG_FILE% >> %LOG_FILE%
echo  일부 구성 요소에 문제가 있습니다.
echo  위의 오류 메시지를 확인하고 해결 후 다시 시도하세요.
echo.
echo  추천 해결책:
echo   1. INSTALL.bat를 관리자 권한으로 다시 실행
echo   2. 인터넷 연결 상태 확인
echo   3. 바이러스 백신 소프트웨어 확인
echo   4. 로그 파일 확인: %LOG_FILE%
echo.

echo [%date% %time%] 사용자에게 실패 안내 및 해결책 표시 >> %LOG_FILE%

:end
echo 창을 닫으려면 아무 키나 누르세요...
pause >nul