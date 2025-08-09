from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
import os
import json
import sqlite3
from datetime import datetime
from threading import Thread, Lock
from email_parser import EmailParser
from models import init_db, get_db, TagManager, EmailStatusManager, SearchIndexManager
from services.indexer import EmailIndexer
from core.path_utils import (
    normalize_and_validate_path,
    is_allowed_eml_filename,
    sanitize_attachment_name,
)
import logging
from io import BytesIO

app = Flask(__name__)

# 강화된 CORS 설정 (와일드카드 금지)
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "http://127.0.0.1:3000"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 설정
EMAIL_ROOT = ""  # 설정에서 지정될 예정
CONFIG_FILE = "config.json"

# 인덱싱 진행률 상태
_index_lock = Lock()
_index_progress = {"total": 0, "processed": 0, "phase": "idle"}

@app.route('/api/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'message': '이메일 관리자 백엔드 서버가 정상 작동 중입니다.'
    })

@app.route('/', methods=['GET'])
def root():
    """루트 경로"""
    return jsonify({
        'message': '이메일 관리자 백엔드 API',
        'version': '1.0.0',
        'endpoints': [
            '/api/health - 서버 상태 확인',
            '/api/config - 설정 관리',
            '/api/folders - 폴더 목록',
            '/api/emails - 이메일 목록',
            '/api/stats - 통계 정보'
        ]
    })

def load_config():
    """설정 파일 로드"""
    global EMAIL_ROOT
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
            config = json.load(f)
            EMAIL_ROOT = config.get('email_root', '')
    else:
        # 기본 설정 파일 생성
        default_config = {
            'email_root': '',
            'port': 5000,
            'host': '127.0.0.1'
        }
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, indent=2, ensure_ascii=False)

@app.route('/api/config', methods=['GET', 'POST'])
def handle_config():
    """설정 관리"""
    if request.method == 'GET':
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                return jsonify(json.load(f))
        return jsonify({'email_root': '', 'port': 5000, 'host': '127.0.0.1'})
    
    elif request.method == 'POST':
        config = request.json
        global EMAIL_ROOT
        EMAIL_ROOT = config.get('email_root', '')
        
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
        
        return jsonify({'success': True, 'message': '설정이 저장되었습니다.'})

@app.route('/api/folders', methods=['GET'])
def get_folders():
    """폴더 목록 조회"""
    if not EMAIL_ROOT or not os.path.exists(EMAIL_ROOT):
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았거나 존재하지 않습니다.'}), 400
    
    try:
        folders = []
        for root, dirs, files in os.walk(EMAIL_ROOT):
            # .eml 파일이 있는 폴더만 포함
            eml_files = [f for f in files if f.endswith('.eml')]
            if eml_files:
                rel_path = os.path.relpath(root, EMAIL_ROOT)
                if rel_path == '.':
                    rel_path = ''
                folders.append({
                    'path': rel_path,
                    'name': os.path.basename(root) if rel_path else 'Root',
                    'count': len(eml_files)
                })
        
        return jsonify({'folders': folders})
    except Exception as e:
        logger.error(f"폴더 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/emails/<path:folder_path>', methods=['GET'])
def get_emails(folder_path):
    """특정 폴더의 이메일 목록 조회"""
    if not EMAIL_ROOT:
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    
    try:
        full_path = normalize_and_validate_path(EMAIL_ROOT, folder_path)
        
        if not os.path.exists(full_path):
            return jsonify({'error': '폴더가 존재하지 않습니다.'}), 404
        
        emails = []
        parser = EmailParser()
        
        for filename in os.listdir(full_path):
            if not is_allowed_eml_filename(filename):
                continue
            file_path = os.path.join(full_path, filename)
            try:
                email_info = parser.parse_email_headers(file_path)
                email_info['filename'] = filename
                # folder_path could be '' for root
                rel_folder = os.path.relpath(full_path, EMAIL_ROOT)
                email_info['folder_path'] = '' if rel_folder == '.' else rel_folder
                emails.append(email_info)
            except Exception as e:
                logger.warning(f"이메일 파싱 실패: {filename}, 오류: {e}")
                continue
        
        # 날짜순 정렬 (최신순). None 대비 후 정렬
        emails.sort(key=lambda x: (x.get('date_parsed') or datetime.min), reverse=True)

        # JSON 직렬화 호환을 위해 datetime 제거
        for item in emails:
            if 'date_parsed' in item:
                item.pop('date_parsed', None)
        
        return jsonify({'emails': emails})
    except Exception as e:
        logger.error(f"이메일 목록 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/email/<path:folder_path>/<filename>', methods=['GET'])
def get_email_content(folder_path, filename):
    """특정 이메일 내용 조회"""
    if not EMAIL_ROOT:
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    
    try:
        full_folder = normalize_and_validate_path(EMAIL_ROOT, folder_path)
        if not is_allowed_eml_filename(filename):
            return jsonify({'error': '허용되지 않는 파일명입니다.'}), 400
        file_path = os.path.join(full_folder, filename)
        
        if not os.path.exists(file_path):
            return jsonify({'error': '이메일 파일이 존재하지 않습니다.'}), 404
        
        parser = EmailParser()
        email_data = parser.parse_email_full(file_path)
        
        return jsonify(email_data)
    except Exception as e:
        logger.error(f"이메일 내용 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/search', methods=['POST'])
def search_emails():
    """FTS5 기반 이메일 검색 (페이징/정렬/total 포함)"""
    if not EMAIL_ROOT:
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    try:
        data = request.json or {}
        query = (data.get('query') or '').strip()
        limit = max(1, int(data.get('limit') or 50))
        offset = max(0, int(data.get('offset') or 0))
        order = (data.get('order') or 'date_desc')
        if not query:
            return jsonify({'error': '검색어를 입력해주세요.'}), 400

        total = SearchIndexManager.count(query)
        results = SearchIndexManager.search_emails(query, limit=limit, offset=offset, order=order)
        return jsonify({'results': results, 'total': total, 'limit': limit, 'offset': offset, 'order': order})
    except Exception as e:
        logger.error(f"검색 오류: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/attachment/<path:folder_path>/<filename>/<attachment_name>', methods=['GET'])
def get_attachment(folder_path, filename, attachment_name):
    """첨부파일 다운로드"""
    if not EMAIL_ROOT:
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    
    try:
        full_folder = normalize_and_validate_path(EMAIL_ROOT, folder_path)
        if not is_allowed_eml_filename(filename):
            return jsonify({'error': '허용되지 않는 파일명입니다.'}), 400
        file_path = os.path.join(full_folder, filename)
        
        if not os.path.exists(file_path):
            return jsonify({'error': '이메일 파일이 존재하지 않습니다.'}), 404
        
        parser = EmailParser()
        # 첨부 존재 여부 확인
        full_email = parser.parse_email_full(file_path)
        names = {att.get('filename') for att in full_email.get('attachments', [])}
        if attachment_name not in names:
            return jsonify({'error': '첨부파일을 찾을 수 없습니다.'}), 404
        attachment_data = parser.get_attachment(file_path, attachment_name)
        if not attachment_data:
            return jsonify({'error': '첨부파일을 찾을 수 없습니다.'}), 404
        
        # 메모리 버퍼로 직접 전송 (플랫폼 독립)
        return send_file(
            BytesIO(attachment_data),
            as_attachment=True,
            download_name=sanitize_attachment_name(attachment_name),
            mimetype='application/octet-stream'
        )
    except Exception as e:
        logger.error(f"첨부파일 다운로드 오류: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """통계 정보 조회"""
    if not EMAIL_ROOT or not os.path.exists(EMAIL_ROOT):
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    
    try:
        total_emails = 0
        total_folders = 0
        
        for root, dirs, files in os.walk(EMAIL_ROOT):
            eml_files = [f for f in files if f.endswith('.eml')]
            if eml_files:
                total_folders += 1
                total_emails += len(eml_files)
        
        return jsonify({
            'total_emails': total_emails,
            'total_folders': total_folders
        })
    except Exception as e:
        logger.error(f"통계 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500


# 태그/상태 API
@app.route('/api/tags', methods=['GET', 'POST'])
def tags_handler():
    try:
        if request.method == 'GET':
            return jsonify({'tags': TagManager.get_all_tags()})
        data = request.json or {}
        name = (data.get('name') or '').strip()
        color = data.get('color') or '#007bff'
        if not name:
            return jsonify({'error': '태그 이름이 필요합니다.'}), 400
        tag_id = TagManager.create_tag(name, color)
        return jsonify({'id': tag_id, 'name': name, 'color': color})
    except ValueError as ve:
        return jsonify({'error': str(ve)}), 409
    except Exception as e:
        logger.error(f"태그 처리 오류: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/tags/<int:tag_id>', methods=['DELETE'])
def delete_tag(tag_id: int):
    try:
        ok = TagManager.delete_tag(tag_id)
        if not ok:
            return jsonify({'error': '삭제 실패'}), 500
        return jsonify({'success': True})
    except Exception as e:
        logger.error(f"태그 삭제 오류: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/email-tags', methods=['POST', 'DELETE'])
def email_tags_handler():
    try:
        data = request.json or {}
        email_path = data.get('email_path')
        tag_id = data.get('tag_id')
        if not email_path or not tag_id:
            return jsonify({'error': 'email_path와 tag_id가 필요합니다.'}), 400

        # 검증: 경로가 루트 안에 존재하는지 확인
        try:
            abs_path = normalize_and_validate_path(EMAIL_ROOT, email_path)
            if not os.path.exists(abs_path):
                return jsonify({'error': '이메일 파일이 존재하지 않습니다.'}), 404
        except ValueError:
            return jsonify({'error': '유효하지 않은 경로입니다.'}), 400

        if request.method == 'POST':
            ok = TagManager.add_tag_to_email(email_path, int(tag_id))
            return jsonify({'success': bool(ok)})
        else:
            ok = TagManager.remove_tag_from_email(email_path, int(tag_id))
            return jsonify({'success': bool(ok)})
    except Exception as e:
        logger.error(f"이메일 태그 처리 오류: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/email-status', methods=['GET'])
def get_email_status():
    try:
        email_path = request.args.get('email_path')
        if not email_path:
            return jsonify({'error': 'email_path가 필요합니다.'}), 400
        # 경로 검증
        try:
            abs_path = normalize_and_validate_path(EMAIL_ROOT, email_path)
            if not os.path.exists(abs_path):
                return jsonify({'error': '이메일 파일이 존재하지 않습니다.'}), 404
        except ValueError:
            return jsonify({'error': '유효하지 않은 경로입니다.'}), 400
        return jsonify(EmailStatusManager.get_email_status(email_path))
    except Exception as e:
        logger.error(f"이메일 상태 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/email-status/read', methods=['POST'])
def mark_email_read():
    try:
        email_path = (request.json or {}).get('email_path')
        if not email_path:
            return jsonify({'error': 'email_path가 필요합니다.'}), 400
        try:
            abs_path = normalize_and_validate_path(EMAIL_ROOT, email_path)
            if not os.path.exists(abs_path):
                return jsonify({'error': '이메일 파일이 존재하지 않습니다.'}), 404
        except ValueError:
            return jsonify({'error': '유효하지 않은 경로입니다.'}), 400
        ok = EmailStatusManager.mark_as_read(email_path)
        return jsonify({'success': bool(ok)})
    except Exception as e:
        logger.error(f"읽음 표시 오류: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/email-status/star', methods=['POST'])
def toggle_email_star():
    try:
        email_path = (request.json or {}).get('email_path')
        if not email_path:
            return jsonify({'error': 'email_path가 필요합니다.'}), 400
        try:
            abs_path = normalize_and_validate_path(EMAIL_ROOT, email_path)
            if not os.path.exists(abs_path):
                return jsonify({'error': '이메일 파일이 존재하지 않습니다.'}), 404
        except ValueError:
            return jsonify({'error': '유효하지 않은 경로입니다.'}), 400
        new_state = EmailStatusManager.toggle_star(email_path)
        return jsonify({'is_starred': bool(new_state)})
    except Exception as e:
        logger.error(f"별표 토글 오류: {e}")
        return jsonify({'error': str(e)}), 500


# 인덱싱 API
def _run_rebuild(email_root: str):
    global _index_progress
    with _index_lock:
        _index_progress = {"total": 0, "processed": 0, "phase": "initializing"}
    try:
        indexer = EmailIndexer(email_root)
        indexer.initialize_schema()
        with _index_lock:
            _index_progress["phase"] = "scanning"
        stats = indexer.full_scan_and_index()
        indexer.ensure_indexes()
        with _index_lock:
            _index_progress.update({**stats, "phase": "completed"})
    except Exception:
        with _index_lock:
            _index_progress["phase"] = "error"


@app.route('/api/index/rebuild', methods=['POST'])
def index_rebuild():
    if not EMAIL_ROOT or not os.path.exists(EMAIL_ROOT):
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    # 백그라운드 작업 시작
    t = Thread(target=_run_rebuild, args=(EMAIL_ROOT,), daemon=True)
    t.start()
    return jsonify({'started': True})


@app.route('/api/index/incremental', methods=['POST'])
def index_incremental():
    if not EMAIL_ROOT or not os.path.exists(EMAIL_ROOT):
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    try:
        indexer = EmailIndexer(EMAIL_ROOT)
        indexer.initialize_schema()
        stats = indexer.incremental_index()
        indexer.ensure_indexes()
        return jsonify({'success': True, **stats})
    except Exception as e:
        logger.error(f"증분 인덱싱 오류: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/index/progress', methods=['GET'])
def index_progress():
    with _index_lock:
        return jsonify(_index_progress.copy())

def initialize_app():
    """애플리케이션 초기화"""
    try:
        # 설정 로드
        logger.info("설정 파일 로드 중...")
        load_config()
        logger.info(f"이메일 루트 경로: {EMAIL_ROOT or '미설정'}")
        
        # 데이터베이스 초기화
        logger.info("데이터베이스 초기화 중...")
        init_db()
        logger.info("데이터베이스 초기화 완료")

        # 인덱스 스키마 준비
        try:
            if EMAIL_ROOT:
                EmailIndexer(EMAIL_ROOT).initialize_schema()
        except Exception as e:
            logger.warning(f"인덱스 스키마 준비 경고: {e}")
        
        # 기본 설정 확인
        if not EMAIL_ROOT:
            logger.warning("이메일 루트 폴더가 설정되지 않았습니다. 웹 인터페이스에서 설정해주세요.")
        
        return True
    except Exception as e:
        logger.error(f"애플리케이션 초기화 실패: {e}")
        return False

if __name__ == '__main__':
    print("=" * 60)
    print("📧 이메일 관리자 백엔드 서버 시작")
    print("=" * 60)
    
    # 애플리케이션 초기화
    if not initialize_app():
        print("❌ 서버 초기화 실패!")
        input("아무 키나 눌러 종료...")
        exit(1)
    
    print("✅ 서버 초기화 완료")
    # 설정된 호스트/포트 적용
    try:
        with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
            _cfg = json.load(f)
        _host = _cfg.get('host', '127.0.0.1')
        _port = int(_cfg.get('port', 5000))
    except Exception:
        _host, _port = '127.0.0.1', 5000

    print(f"🌐 서버 주소: http://{_host}:{_port}")
    print(f"📊 프론트엔드: http://localhost:3000")
    print("🔧 설정: /api/config")
    print("=" * 60)
    
    try:
        app.run(host=_host, port=_port, debug=False)
    except KeyboardInterrupt:
        print("\n⏹️  서버 종료 중...")
    except Exception as e:
        print(f"❌ 서버 오류: {e}")
        input("아무 키나 눌러 종료...")
    finally:
        print("👋 서버가 종료되었습니다.")