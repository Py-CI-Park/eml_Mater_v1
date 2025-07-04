import email
from email import policy
from email.parser import BytesParser
from email.header import decode_header
from datetime import datetime
import base64
import quopri
import re
import html
import logging

logger = logging.getLogger(__name__)

class EmailParser:
    def __init__(self):
        self.parser = BytesParser(policy=policy.default)
    
    def decode_mime_header(self, header_value):
        """MIME 헤더 디코딩"""
        if not header_value:
            return ""
        
        try:
            decoded_parts = decode_header(header_value)
            decoded_string = ""
            
            for part, encoding in decoded_parts:
                if isinstance(part, bytes):
                    if encoding:
                        try:
                            decoded_string += part.decode(encoding)
                        except (UnicodeDecodeError, LookupError):
                            # 디코딩 실패시 UTF-8로 시도
                            try:
                                decoded_string += part.decode('utf-8', errors='replace')
                            except:
                                decoded_string += str(part)
                    else:
                        try:
                            decoded_string += part.decode('utf-8', errors='replace')
                        except:
                            decoded_string += str(part)
                else:
                    decoded_string += str(part)
            
            return decoded_string.strip()
        except Exception as e:
            logger.warning(f"헤더 디코딩 실패: {e}")
            return str(header_value)
    
    def parse_date(self, date_string):
        """이메일 날짜 파싱"""
        if not date_string:
            return None, "Unknown"
        
        try:
            # 다양한 날짜 형식 시도
            date_formats = [
                "%a, %d %b %Y %H:%M:%S %z",
                "%a, %d %b %Y %H:%M:%S %Z",
                "%d %b %Y %H:%M:%S %z",
                "%d %b %Y %H:%M:%S %Z",
                "%a, %d %b %Y %H:%M:%S",
                "%d %b %Y %H:%M:%S",
                "%Y-%m-%d %H:%M:%S",
                "%Y/%m/%d %H:%M:%S"
            ]
            
            # 시간대 정보 정리
            cleaned_date = re.sub(r'\s*\([^)]*\)', '', str(date_string).strip())
            
            for fmt in date_formats:
                try:
                    parsed_date = datetime.strptime(cleaned_date, fmt)
                    return parsed_date, parsed_date.strftime("%Y-%m-%d %H:%M:%S")
                except ValueError:
                    continue
            
            # email.utils.parsedate_to_datetime 시도
            try:
                from email.utils import parsedate_to_datetime
                parsed_date = parsedate_to_datetime(cleaned_date)
                return parsed_date, parsed_date.strftime("%Y-%m-%d %H:%M:%S")
            except:
                pass
            
            return None, str(date_string)
        except Exception as e:
            logger.warning(f"날짜 파싱 실패: {date_string}, 오류: {e}")
            return None, str(date_string)
    
    def parse_email_headers(self, file_path):
        """이메일 헤더 정보만 파싱 (빠른 조회용)"""
        try:
            with open(file_path, 'rb') as f:
                msg = self.parser.parse(f)
            
            # 기본 헤더 정보 추출
            subject = self.decode_mime_header(msg.get('subject', 'No Subject'))
            from_header = self.decode_mime_header(msg.get('from', 'Unknown'))
            to_header = self.decode_mime_header(msg.get('to', ''))
            cc_header = self.decode_mime_header(msg.get('cc', ''))
            date_header = msg.get('date', '')
            
            # 날짜 파싱
            date_parsed, date_formatted = self.parse_date(date_header)
            
            # 발신자 이메일 주소 추출
            from_email = self.extract_email_address(from_header)
            
            return {
                'subject': subject,
                'from': from_header,
                'from_email': from_email,
                'to': to_header,
                'cc': cc_header,
                'date': date_formatted,
                'date_parsed': date_parsed,
                'message_id': msg.get('message-id', ''),
                'has_attachments': self.has_attachments(msg)
            }
        except Exception as e:
            logger.error(f"헤더 파싱 실패: {file_path}, 오류: {e}")
            raise
    
    def parse_email_full(self, file_path):
        """이메일 전체 내용 파싱"""
        try:
            with open(file_path, 'rb') as f:
                msg = self.parser.parse(f)
            
            # 헤더 정보
            headers = self.parse_email_headers(file_path)
            
            # 본문 추출
            body_text, body_html = self.extract_body(msg)
            
            # 첨부파일 목록
            attachments = self.extract_attachments_list(msg)
            
            return {
                **headers,
                'body_text': body_text,
                'body_html': body_html,
                'attachments': attachments,
                'headers_raw': dict(msg.items())
            }
        except Exception as e:
            logger.error(f"전체 파싱 실패: {file_path}, 오류: {e}")
            raise
    
    def extract_email_address(self, header_value):
        """헤더에서 이메일 주소만 추출"""
        if not header_value:
            return ""
        
        # 정규식으로 이메일 주소 추출
        email_pattern = r'[\w\.-]+@[\w\.-]+\.\w+'
        matches = re.findall(email_pattern, header_value)
        return matches[0] if matches else ""
    
    def has_attachments(self, msg):
        """첨부파일 존재 여부 확인"""
        try:
            for part in msg.walk():
                if part.get_content_disposition() == 'attachment':
                    return True
                # 인라인 파일도 첨부파일로 간주
                if part.get_content_disposition() == 'inline' and part.get_filename():
                    return True
            return False
        except:
            return False
    
    def extract_body(self, msg):
        """이메일 본문 추출"""
        body_text = ""
        body_html = ""
        
        try:
            # 멀티파트 메시지 처리
            if msg.is_multipart():
                for part in msg.walk():
                    content_type = part.get_content_type()
                    content_disposition = part.get_content_disposition()
                    
                    # 첨부파일은 건너뛰기
                    if content_disposition == 'attachment':
                        continue
                    
                    if content_type == 'text/plain' and not body_text:
                        body_text = self.decode_body_content(part)
                    elif content_type == 'text/html' and not body_html:
                        body_html = self.decode_body_content(part)
            else:
                # 단일 파트 메시지
                content_type = msg.get_content_type()
                if content_type == 'text/plain':
                    body_text = self.decode_body_content(msg)
                elif content_type == 'text/html':
                    body_html = self.decode_body_content(msg)
            
            # HTML이 있으면 텍스트 버전도 생성
            if body_html and not body_text:
                body_text = self.html_to_text(body_html)
            
        except Exception as e:
            logger.warning(f"본문 추출 실패: {e}")
        
        return body_text, body_html
    
    def decode_body_content(self, part):
        """본문 내용 디코딩"""
        try:
            content = part.get_content()
            if isinstance(content, bytes):
                # 인코딩 감지 및 디코딩
                charset = part.get_content_charset()
                if charset:
                    try:
                        return content.decode(charset, errors='replace')
                    except (UnicodeDecodeError, LookupError):
                        pass
                
                # UTF-8로 시도
                try:
                    return content.decode('utf-8', errors='replace')
                except:
                    return content.decode('latin-1', errors='replace')
            return str(content)
        except Exception as e:
            logger.warning(f"본문 디코딩 실패: {e}")
            return ""
    
    def html_to_text(self, html_content):
        """HTML을 텍스트로 변환 (간단한 변환)"""
        try:
            # HTML 태그 제거
            text = re.sub(r'<[^>]+>', '', html_content)
            # HTML 엔티티 디코딩
            text = html.unescape(text)
            # 여러 공백을 하나로
            text = re.sub(r'\s+', ' ', text)
            return text.strip()
        except:
            return html_content
    
    def extract_attachments_list(self, msg):
        """첨부파일 목록 추출"""
        attachments = []
        
        try:
            for part in msg.walk():
                content_disposition = part.get_content_disposition()
                filename = part.get_filename()
                
                if content_disposition == 'attachment' or (content_disposition == 'inline' and filename):
                    if filename:
                        decoded_filename = self.decode_mime_header(filename)
                        content_type = part.get_content_type()
                        content_size = len(part.get_payload(decode=True) or b'')
                        
                        attachments.append({
                            'filename': decoded_filename,
                            'content_type': content_type,
                            'size': content_size,
                            'size_formatted': self.format_size(content_size)
                        })
        except Exception as e:
            logger.warning(f"첨부파일 목록 추출 실패: {e}")
        
        return attachments
    
    def get_attachment(self, file_path, attachment_name):
        """특정 첨부파일 데이터 추출"""
        try:
            with open(file_path, 'rb') as f:
                msg = self.parser.parse(f)
            
            for part in msg.walk():
                filename = part.get_filename()
                if filename and self.decode_mime_header(filename) == attachment_name:
                    return part.get_payload(decode=True)
            
            return None
        except Exception as e:
            logger.error(f"첨부파일 추출 실패: {file_path}, {attachment_name}, 오류: {e}")
            return None
    
    def format_size(self, size_bytes):
        """파일 크기를 읽기 쉬운 형태로 변환"""
        if size_bytes == 0:
            return "0 B"
        
        size_names = ["B", "KB", "MB", "GB"]
        i = 0
        while size_bytes >= 1024 and i < len(size_names) - 1:
            size_bytes /= 1024.0
            i += 1
        
        return f"{size_bytes:.1f} {size_names[i]}"