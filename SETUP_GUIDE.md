# 📧 이메일 관리자 설치 및 실행 가이드

## 🔍 분석 결과

### 발견된 문제점
1. **Python pip 미설치**: 시스템에 pip가 설치되어 있지 않음
2. **Node.js 의존성 충돌**: `react-split-pane`이 React 18과 호환되지 않음
3. **파이썬 가상환경 미사용**: 의존성 충돌 방지를 위해 가상환경 필요

### 시스템 요구사항 확인
- ✅ Python 3.10.12 (요구사항: 3.7+)
- ✅ Node.js v20.19.3 (요구사항: 14+)
- ✅ npm 10.8.2 (요구사항: 6+)

## 🚀 완전한 설치 및 실행 가이드

### 1단계: Python 환경 설정

#### 1-1. pip 설치 (Ubuntu/Debian)
```bash
# pip 설치
sudo apt update
sudo apt install python3-pip python3-venv

# 설치 확인
pip3 --version
```

#### 1-2. 파이썬 가상환경 생성
```bash
# 프로젝트 폴더로 이동
cd /mnt/c/Programming/eml_Mater_v1

# 가상환경 생성
python3 -m venv venv

# 가상환경 활성화
source venv/bin/activate

# 가상환경 활성화 확인 (프롬프트 앞에 (venv)가 나타남)
which python
```

#### 1-3. Python 의존성 설치
```bash
# 가상환경이 활성화된 상태에서
cd backend
pip install -r requirements.txt
```

### 2단계: Node.js 환경 설정

#### 2-1. React 의존성 충돌 해결
```bash
# 프로젝트 루트로 이동
cd /mnt/c/Programming/eml_Mater_v1/frontend

# 기존 node_modules 제거 (있다면)
rm -rf node_modules package-lock.json

# 호환성 문제 해결을 위한 설치
npm install --legacy-peer-deps
```

#### 2-2. 대안 방법 (권장)
`react-split-pane` 대신 호환되는 라이브러리 사용:
```bash
# 문제가 있는 패키지 제거
npm uninstall react-split-pane

# 호환되는 대안 설치
npm install react-split-pane-v2
# 또는
npm install @allotment/allotment
```

### 3단계: 설정 파일 준비

#### 3-1. 백엔드 설정 파일 생성
```bash
# backend 폴더에 config.json 생성
cd backend
cat > config.json << 'EOF'
{
  "email_root": "",
  "port": 5000,
  "host": "127.0.0.1"
}
EOF
```

#### 3-2. 테스트용 .eml 파일 폴더 생성 (선택사항)
```bash
# 테스트용 이메일 폴더 생성
mkdir -p /tmp/test_emails
echo "테스트용 이메일 파일들을 이 폴더에 넣어주세요" > /tmp/test_emails/README.txt
```

### 4단계: 프로그램 실행

#### 4-1. 자동 실행 (권장)
```bash
# 프로젝트 루트에서
python3 run.py
```

#### 4-2. 수동 실행
```bash
# 터미널 1 - 백엔드 실행
cd backend
source ../venv/bin/activate
python3 app.py

# 터미널 2 - 프론트엔드 실행
cd frontend
npm start
```

#### 4-3. 브라우저에서 접속
- 프론트엔드: http://localhost:3000
- 백엔드 API: http://localhost:5000

## 🔧 문제 해결

### Python 관련 문제

#### pip 명령어를 찾을 수 없는 경우
```bash
# Ubuntu/Debian
sudo apt install python3-pip

# CentOS/RHEL
sudo yum install python3-pip
# 또는
sudo dnf install python3-pip

# macOS
brew install python3
```

#### 가상환경 활성화 문제
```bash
# 가상환경이 제대로 활성화되지 않은 경우
deactivate  # 기존 환경 비활성화
source venv/bin/activate  # 다시 활성화

# Windows 사용자의 경우
# venv\Scripts\activate
```

### Node.js 관련 문제

#### npm 의존성 충돌 해결
```bash
# 모든 의존성 재설치
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps

# 또는 강제 설치
npm install --force
```

#### 포트 충돌 문제
```bash
# 다른 포트 사용
# 프론트엔드
PORT=3001 npm start

# 백엔드 (app.py 수정 필요)
# app.run(host='127.0.0.1', port=5001, debug=True)
```

### 권한 문제

#### 파일 접근 권한 문제
```bash
# 프로젝트 폴더 권한 확인
ls -la /mnt/c/Programming/eml_Mater_v1

# 필요시 권한 변경
sudo chown -R $USER:$USER /mnt/c/Programming/eml_Mater_v1
```

## 📝 사용 방법

### 1. 초기 설정
1. 브라우저에서 http://localhost:3000 접속
2. 상단 네비게이션에서 "설정" 클릭
3. "이메일 루트 폴더 경로"에 .eml 파일들이 있는 폴더 경로 입력
4. "설정 저장" 클릭

### 2. 이메일 관리
1. 왼쪽 폴더 트리에서 폴더 선택
2. 중간 패널에서 이메일 목록 확인
3. 오른쪽 패널에서 이메일 내용 확인
4. 상단 검색바로 이메일 검색

## 🐛 알려진 문제

### React Split Pane 호환성 문제
- **문제**: `react-split-pane@0.1.92`가 React 18과 호환되지 않음
- **해결책**: 
  ```bash
  npm install react-split-pane-v2 --legacy-peer-deps
  ```
- **코드 수정**: `src/components/` 파일들에서 import 경로 수정 필요

### 임시 파일 경로 문제
- **문제**: 첨부파일 다운로드 시 `/tmp/` 경로 사용 (Windows 호환성 문제)
- **해결책**: `backend/app.py`의 223행 수정:
  ```python
  import tempfile
  temp_path = os.path.join(tempfile.gettempdir(), attachment_name)
  ```

## 📊 개발 환경 설정

### 코드 편집 권장사항
```bash
# 코드 포맷팅 (선택사항)
pip install black flake8  # Python
npm install --save-dev prettier eslint  # JavaScript
```

### 디버깅 모드
```bash
# 백엔드 디버그 모드
export FLASK_ENV=development
export FLASK_DEBUG=1
python3 app.py

# 프론트엔드 개발 모드
npm start  # 기본적으로 개발 모드
```

이 가이드를 따라하면 프로그램이 정상적으로 실행될 것입니다. 문제가 발생하면 해당 섹션의 문제 해결 방법을 참고하세요.