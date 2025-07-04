import sqlite3
import os
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

DB_FILE = "email_manager.db"

def get_db():
    """데이터베이스 연결 객체 반환"""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row  # dict-like 접근 가능
    return conn

def init_db():
    """데이터베이스 테이블 초기화"""
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        # 태그 테이블
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tags (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                color TEXT DEFAULT '#007bff',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # 이메일 태그 연결 테이블
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS email_tags (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email_path TEXT NOT NULL,
                tag_id INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE,
                UNIQUE(email_path, tag_id)
            )
        ''')
        
        # 검색 인덱스 테이블 (성능 향상용)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS search_index (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email_path TEXT UNIQUE NOT NULL,
                subject TEXT,
                sender TEXT,
                recipient TEXT,
                body_text TEXT,
                date_parsed TIMESTAMP,
                indexed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # 사용자 설정 테이블
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_settings (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # 이메일 읽음 상태 테이블
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS email_status (
                email_path TEXT PRIMARY KEY,
                is_read BOOLEAN DEFAULT FALSE,
                is_starred BOOLEAN DEFAULT FALSE,
                last_viewed TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        logger.info("데이터베이스 초기화 완료")
        
    except Exception as e:
        logger.error(f"데이터베이스 초기화 실패: {e}")
        raise

class TagManager:
    """태그 관리 클래스"""
    
    @staticmethod
    def create_tag(name, color='#007bff'):
        """새 태그 생성"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO tags (name, color) VALUES (?, ?)",
                (name, color)
            )
            tag_id = cursor.lastrowid
            conn.commit()
            conn.close()
            return tag_id
        except sqlite3.IntegrityError:
            raise ValueError(f"태그 '{name}'이 이미 존재합니다.")
        except Exception as e:
            logger.error(f"태그 생성 실패: {e}")
            raise
    
    @staticmethod
    def get_all_tags():
        """모든 태그 조회"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM tags ORDER BY name")
            tags = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return tags
        except Exception as e:
            logger.error(f"태그 조회 실패: {e}")
            return []
    
    @staticmethod
    def delete_tag(tag_id):
        """태그 삭제"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute("DELETE FROM tags WHERE id = ?", (tag_id,))
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"태그 삭제 실패: {e}")
            return False
    
    @staticmethod
    def add_tag_to_email(email_path, tag_id):
        """이메일에 태그 추가"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO email_tags (email_path, tag_id) VALUES (?, ?)",
                (email_path, tag_id)
            )
            conn.commit()
            conn.close()
            return True
        except sqlite3.IntegrityError:
            # 이미 존재하는 태그
            return False
        except Exception as e:
            logger.error(f"이메일 태그 추가 실패: {e}")
            return False
    
    @staticmethod
    def remove_tag_from_email(email_path, tag_id):
        """이메일에서 태그 제거"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute(
                "DELETE FROM email_tags WHERE email_path = ? AND tag_id = ?",
                (email_path, tag_id)
            )
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"이메일 태그 제거 실패: {e}")
            return False
    
    @staticmethod
    def get_email_tags(email_path):
        """특정 이메일의 태그 목록 조회"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT t.* FROM tags t
                JOIN email_tags et ON t.id = et.tag_id
                WHERE et.email_path = ?
            ''', (email_path,))
            tags = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return tags
        except Exception as e:
            logger.error(f"이메일 태그 조회 실패: {e}")
            return []

class EmailStatusManager:
    """이메일 상태 관리 클래스"""
    
    @staticmethod
    def mark_as_read(email_path):
        """이메일을 읽음으로 표시"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO email_status 
                (email_path, is_read, last_viewed) 
                VALUES (?, TRUE, CURRENT_TIMESTAMP)
            ''', (email_path,))
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"읽음 표시 실패: {e}")
            return False
    
    @staticmethod
    def toggle_star(email_path):
        """이메일 별표 토글"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            
            # 현재 상태 확인
            cursor.execute(
                "SELECT is_starred FROM email_status WHERE email_path = ?",
                (email_path,)
            )
            result = cursor.fetchone()
            
            if result:
                new_starred = not result['is_starred']
                cursor.execute(
                    "UPDATE email_status SET is_starred = ? WHERE email_path = ?",
                    (new_starred, email_path)
                )
            else:
                new_starred = True
                cursor.execute(
                    "INSERT INTO email_status (email_path, is_starred) VALUES (?, ?)",
                    (email_path, new_starred)
                )
            
            conn.commit()
            conn.close()
            return new_starred
        except Exception as e:
            logger.error(f"별표 토글 실패: {e}")
            return False
    
    @staticmethod
    def get_email_status(email_path):
        """이메일 상태 조회"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM email_status WHERE email_path = ?",
                (email_path,)
            )
            result = cursor.fetchone()
            conn.close()
            
            if result:
                return dict(result)
            else:
                return {
                    'email_path': email_path,
                    'is_read': False,
                    'is_starred': False,
                    'last_viewed': None
                }
        except Exception as e:
            logger.error(f"이메일 상태 조회 실패: {e}")
            return {
                'email_path': email_path,
                'is_read': False,
                'is_starred': False,
                'last_viewed': None
            }

class SearchIndexManager:
    """검색 인덱스 관리 클래스"""
    
    @staticmethod
    def update_index(email_path, email_data):
        """검색 인덱스 업데이트"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO search_index 
                (email_path, subject, sender, recipient, body_text, date_parsed, indexed_at)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            ''', (
                email_path,
                email_data.get('subject', ''),
                email_data.get('from', ''),
                email_data.get('to', ''),
                email_data.get('body_text', ''),
                email_data.get('date_parsed')
            ))
            
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"검색 인덱스 업데이트 실패: {e}")
            return False
    
    @staticmethod
    def search_emails(query, limit=100):
        """검색 인덱스를 사용한 빠른 검색"""
        try:
            conn = get_db()
            cursor = conn.cursor()
            
            search_query = f"%{query}%"
            cursor.execute('''
                SELECT * FROM search_index 
                WHERE subject LIKE ? OR sender LIKE ? OR recipient LIKE ? OR body_text LIKE ?
                ORDER BY date_parsed DESC
                LIMIT ?
            ''', (search_query, search_query, search_query, search_query, limit))
            
            results = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return results
        except Exception as e:
            logger.error(f"인덱스 검색 실패: {e}")
            return []