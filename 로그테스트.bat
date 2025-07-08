@echo off
chcp 65001 > nul
color 0A

echo ========================================
echo          로그 파일 생성 테스트
echo ========================================
echo.

set TEST_LOG=test_log.log

echo 테스트 1: 기본 로그 파일 생성
echo [%date% %time%] 테스트 로그 시작 > %TEST_LOG% 2>nul

if exist %TEST_LOG% (
    echo [OK] 로그 파일 생성 성공
    echo [%date% %time%] 로그 생성 테스트 성공 >> %TEST_LOG%
) else (
    echo [ERROR] 로그 파일 생성 실패
    echo 가능한 원인:
    echo   - 관리자 권한 부족
    echo   - 디스크 공간 부족
    echo   - 바이러스 백신 차단
    goto :test_failed
)

echo.
echo 테스트 2: 한글 경로 테스트
echo 작업 폴더: %CD%
echo [%date% %time%] 한글 폴더 테스트: %CD% >> %TEST_LOG%

echo.
echo 테스트 3: 시스템 정보
echo Windows 버전:
ver
echo [%date% %time%] Windows 버전 확인 >> %TEST_LOG%

echo.
echo ========================================
echo           테스트 결과: 성공
echo ========================================
echo.
echo 로그 파일이 정상적으로 생성되었습니다.
echo 파일 위치: %TEST_LOG%
echo.
echo 이제 INSTALL_SAFE.bat를 실행해 보세요.
echo.
goto :cleanup

:test_failed
echo.
echo ========================================
echo           테스트 결과: 실패
echo ========================================
echo.
echo 로그 파일 생성에 실패했습니다.
echo 다음을 확인하세요:
echo   1. 관리자 권한으로 실행
echo   2. 바이러스 백신 일시 중지
echo   3. 디스크 공간 확인
echo   4. 환경정리.bat 실행
echo.

:cleanup
if exist %TEST_LOG% (
    echo 테스트 로그 파일 내용:
    echo ----------------------------------------
    type %TEST_LOG%
    echo ----------------------------------------
)

echo.
echo 아무 키나 누르면 종료됩니다...
pause >nul

if exist %TEST_LOG% del %TEST_LOG% >nul 2>&1