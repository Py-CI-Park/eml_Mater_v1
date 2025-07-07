#!/usr/bin/env python3
"""
이메일 관리자 통합 실행 스크립트
백엔드(Flask)와 프론트엔드(React) 서버를 함께 실행합니다.
"""

import os
import sys
import subprocess
import threading
import time
import signal
from pathlib import Path

def print_banner():
    """시작 배너 출력"""
    print("=" * 60)
    print("           📧 이메일 관리자 (Email Manager)")
    print("=" * 60)
    print("폐쇄망에서 .eml 파일을 관리하는 웹 애플리케이션")
    print("백엔드: Flask (Python)")
    print("프론트엔드: React (JavaScript)")
    print("=" * 60)

def check_requirements():
    """필수 요구사항 확인"""
    print("🔍 시스템 요구사항 확인 중...")
    
    # Python 버전 확인
    if sys.version_info < (3, 7):
        print("❌ Python 3.7 이상이 필요합니다.")
        return False
    
    # Node.js 확인
    try:
        result = subprocess.run(['node', '--version'], 
                              capture_output=True, text=True, check=True)
        node_version = result.stdout.strip()
        print(f"✅ Node.js {node_version}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Node.js가 설치되지 않았습니다.")
        print("   https://nodejs.org에서 다운로드하여 설치하세요.")
        return False
    
    # npm 확인
    try:
        result = subprocess.run(['npm', '--version'], 
                              capture_output=True, text=True, check=True)
        npm_version = result.stdout.strip()
        print(f"✅ npm {npm_version}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ npm이 설치되지 않았습니다.")
        return False
    
    print(f"✅ Python {sys.version.split()[0]}")
    return True

def install_dependencies():
    """의존성 설치"""
    print("\n📦 의존성 설치 중...")
    
    # Python 의존성 설치
    print("  Python 패키지 설치 중...")
    try:
        subprocess.run([
            sys.executable, '-m', 'pip', 'install', '-r', 'backend/requirements.txt'
        ], check=True, cwd=os.getcwd())
        print("  ✅ Python 패키지 설치 완료")
    except subprocess.CalledProcessError:
        print("  ❌ Python 패키지 설치 실패")
        return False
    
    # Node.js 의존성 설치
    print("  Node.js 패키지 설치 중...")
    frontend_path = Path('frontend')
    if not frontend_path.exists():
        print("  ❌ frontend 폴더가 없습니다.")
        return False
    
    try:
        subprocess.run(['npm', 'install'], 
                      check=True, cwd=frontend_path)
        print("  ✅ Node.js 패키지 설치 완료")
    except subprocess.CalledProcessError:
        print("  ❌ Node.js 패키지 설치 실패")
        return False
    
    return True

def run_backend():
    """백엔드 서버 실행"""
    print("🚀 백엔드 서버 시작 중... (Flask)")
    
    backend_path = Path('backend')
    if not backend_path.exists():
        print("❌ backend 폴더가 없습니다.")
        return
    
    try:
        # 백엔드 실행
        env = os.environ.copy()
        env['PYTHONPATH'] = str(backend_path)
        
        subprocess.run([
            sys.executable, 'app.py'
        ], cwd=backend_path, env=env)
    except KeyboardInterrupt:
        print("\n🛑 백엔드 서버 종료")
    except Exception as e:
        print(f"❌ 백엔드 서버 오류: {e}")

def run_frontend():
    """프론트엔드 서버 실행"""
    print("🚀 프론트엔드 서버 시작 중... (React)")
    
    frontend_path = Path('frontend')
    if not frontend_path.exists():
        print("❌ frontend 폴더가 없습니다.")
        return
    
    # 잠시 대기 (백엔드 서버 시작 시간)
    time.sleep(3)
    
    try:
        subprocess.run(['npm', 'start'], cwd=frontend_path)
    except KeyboardInterrupt:
        print("\n🛑 프론트엔드 서버 종료")
    except Exception as e:
        print(f"❌ 프론트엔드 서버 오류: {e}")

def main():
    """메인 실행 함수"""
    print_banner()
    
    # 요구사항 확인
    if not check_requirements():
        print("\n❌ 시스템 요구사항을 만족하지 않습니다.")
        sys.exit(1)
    
    # 의존성 설치
    if not install_dependencies():
        print("\n❌ 의존성 설치에 실패했습니다.")
        sys.exit(1)
    
    print("\n🎉 모든 준비가 완료되었습니다!")
    print("\n📍 서버 정보:")
    print("  - 백엔드: http://localhost:5000")
    print("  - 프론트엔드: http://localhost:3000")
    print("\n💡 사용법:")
    print("  1. 브라우저에서 http://localhost:3000에 접속")
    print("  2. 설정 페이지에서 이메일 폴더 경로 설정")
    print("  3. 이메일 관리 시작!")
    print("\n⏸️  종료하려면 Ctrl+C를 눌러주세요.")
    print("=" * 60)
    
    try:
        # 백엔드와 프론트엔드를 별도 스레드에서 실행
        backend_thread = threading.Thread(target=run_backend, daemon=True)
        frontend_thread = threading.Thread(target=run_frontend, daemon=True)
        
        backend_thread.start()
        frontend_thread.start()
        
        # 메인 스레드에서 대기
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n\n🛑 애플리케이션 종료 중...")
        print("📧 이메일 관리자를 사용해주셔서 감사합니다!")
        sys.exit(0)

if __name__ == '__main__':
    main()