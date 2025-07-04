from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
import os
import json
import sqlite3
from datetime import datetime
from email_parser import EmailParser
from models import init_db, get_db
import logging

app = Flask(__name__)
CORS(app)  # React 앱과의 통신을 위해 CORS 설정

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 설정
EMAIL_ROOT = ""  # 설정에서 지정될 예정
CONFIG_FILE = "config.json"

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
        if folder_path == 'root':
            full_path = EMAIL_ROOT
        else:
            full_path = os.path.join(EMAIL_ROOT, folder_path)
        
        if not os.path.exists(full_path):
            return jsonify({'error': '폴더가 존재하지 않습니다.'}), 404
        
        emails = []
        parser = EmailParser()
        
        for filename in os.listdir(full_path):
            if filename.endswith('.eml'):
                file_path = os.path.join(full_path, filename)
                try:
                    email_info = parser.parse_email_headers(file_path)
                    email_info['filename'] = filename
                    email_info['folder_path'] = folder_path
                    emails.append(email_info)
                except Exception as e:
                    logger.warning(f"이메일 파싱 실패: {filename}, 오류: {e}")
                    continue
        
        # 날짜순 정렬 (최신순)
        emails.sort(key=lambda x: x.get('date_parsed', datetime.min), reverse=True)
        
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
        if folder_path == 'root':
            file_path = os.path.join(EMAIL_ROOT, filename)
        else:
            file_path = os.path.join(EMAIL_ROOT, folder_path, filename)
        
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
    """이메일 검색"""
    if not EMAIL_ROOT:
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    
    try:
        data = request.json
        query = data.get('query', '').lower()
        search_in = data.get('search_in', ['subject', 'from', 'body'])  # 검색 범위
        
        if not query:
            return jsonify({'error': '검색어를 입력해주세요.'}), 400
        
        results = []
        parser = EmailParser()
        
        for root, dirs, files in os.walk(EMAIL_ROOT):
            for filename in files:
                if filename.endswith('.eml'):
                    file_path = os.path.join(root, filename)
                    try:
                        # 기본 헤더 정보 파싱
                        email_info = parser.parse_email_headers(file_path)
                        
                        # 검색 조건 확인
                        match = False
                        if 'subject' in search_in and query in email_info.get('subject', '').lower():
                            match = True
                        elif 'from' in search_in and query in email_info.get('from', '').lower():
                            match = True
                        elif 'body' in search_in:
                            # 본문 검색은 필요시에만 파싱 (성능 고려)
                            full_email = parser.parse_email_full(file_path)
                            if query in full_email.get('body_text', '').lower():
                                match = True
                        
                        if match:
                            email_info['filename'] = filename
                            email_info['folder_path'] = os.path.relpath(root, EMAIL_ROOT)
                            if email_info['folder_path'] == '.':
                                email_info['folder_path'] = 'root'
                            results.append(email_info)
                            
                    except Exception as e:
                        logger.warning(f"검색 중 이메일 파싱 실패: {filename}, 오류: {e}")
                        continue
        
        # 날짜순 정렬
        results.sort(key=lambda x: x.get('date_parsed', datetime.min), reverse=True)
        
        return jsonify({'results': results, 'count': len(results)})
    except Exception as e:
        logger.error(f"검색 오류: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/attachment/<path:folder_path>/<filename>/<attachment_name>', methods=['GET'])
def get_attachment(folder_path, filename, attachment_name):
    """첨부파일 다운로드"""
    if not EMAIL_ROOT:
        return jsonify({'error': '메일 루트 폴더가 설정되지 않았습니다.'}), 400
    
    try:
        if folder_path == 'root':
            file_path = os.path.join(EMAIL_ROOT, filename)
        else:
            file_path = os.path.join(EMAIL_ROOT, folder_path, filename)
        
        if not os.path.exists(file_path):
            return jsonify({'error': '이메일 파일이 존재하지 않습니다.'}), 404
        
        parser = EmailParser()
        attachment_data = parser.get_attachment(file_path, attachment_name)
        
        if not attachment_data:
            return jsonify({'error': '첨부파일을 찾을 수 없습니다.'}), 404
        
        # 임시 파일로 저장 후 전송
        temp_path = f"/tmp/{attachment_name}"
        with open(temp_path, 'wb') as f:
            f.write(attachment_data)
        
        return send_file(temp_path, as_attachment=True, download_name=attachment_name)
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

if __name__ == '__main__':
    # 설정 로드 및 데이터베이스 초기화
    load_config()
    init_db()
    
    app.run(host='127.0.0.1', port=5000, debug=True)