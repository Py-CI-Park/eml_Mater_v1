import React from 'react';
import { Spinner } from 'react-bootstrap';
import { FaEnvelope, FaPaperclip, FaSearch } from 'react-icons/fa';

const EmailList = ({ 
  emails, 
  selectedEmail, 
  onEmailSelect, 
  loading, 
  isSearchResults = false,
  folderName = ''
}) => {
  const formatDate = (dateString) => {
    if (!dateString || dateString === 'Unknown') return '날짜 없음';
    
    try {
      const date = new Date(dateString);
      const now = new Date();
      const diffTime = Math.abs(now - date);
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      
      if (diffDays === 1) {
        return '오늘';
      } else if (diffDays <= 7) {
        return `${diffDays}일 전`;
      } else if (diffDays <= 30) {
        const weeks = Math.floor(diffDays / 7);
        return `${weeks}주 전`;
      } else {
        return date.toLocaleDateString('ko-KR', {
          year: 'numeric',
          month: 'short',
          day: 'numeric'
        });
      }
    } catch (error) {
      return dateString.substring(0, 10);
    }
  };

  const truncateText = (text, maxLength = 50) => {
    if (!text) return '';
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  const extractEmailName = (fromHeader) => {
    if (!fromHeader) return 'Unknown';
    
    // "Name <email@domain.com>" 형식에서 이름 추출
    const nameMatch = fromHeader.match(/^([^<]+)<.*>$/);
    if (nameMatch) {
      return nameMatch[1].trim().replace(/"/g, '');
    }
    
    // 이메일 주소만 있는 경우
    const emailMatch = fromHeader.match(/[\w\.-]+@[\w\.-]+\.\w+/);
    if (emailMatch) {
      return emailMatch[0].split('@')[0];
    }
    
    return fromHeader;
  };

  if (loading && emails.length === 0) {
    return (
      <div>
        <div className="email-list-header">
          <h6 className="email-list-title">
            {isSearchResults ? (
              <>
                <FaSearch className="me-2" />
                검색 결과
              </>
            ) : (
              <>
                <FaEnvelope className="me-2" />
                {folderName || '이메일'}
              </>
            )}
          </h6>
        </div>
        <div className="loading-container">
          <Spinner animation="border" size="sm" className="me-2" />
          이메일 로딩중...
        </div>
      </div>
    );
  }

  const renderEmailItem = (email, index) => {
    const isSelected = selectedEmail && selectedEmail.filename === email.filename &&
                      selectedEmail.folder_path === email.folder_path;
    
    return (
      <div
        key={`${email.folder_path || 'root'}-${email.filename}-${index}`}
        className={`email-item ${isSelected ? 'selected' : ''}`}
        onClick={() => onEmailSelect(email)}
      >
        <div className="email-subject" title={email.subject}>
          {email.subject || 'No Subject'}
        </div>
        <div className="email-from" title={email.from}>
          {extractEmailName(email.from)}
        </div>
        <div className="email-meta">
          <span className="email-date">
            {formatDate(email.date)}
          </span>
          {email.has_attachments && (
            <span className="email-attachments">
              <FaPaperclip size={12} />
            </span>
          )}
        </div>
      </div>
    );
  };

  return (
    <div>
      <div className="email-list-header">
        <h6 className="email-list-title">
          {isSearchResults ? (
            <>
              <FaSearch className="me-2" />
              검색 결과
            </>
          ) : (
            <>
              <FaEnvelope className="me-2" />
              {folderName || '이메일'}
            </>
          )}
        </h6>
        <span className="email-count">
          {emails.length}개
        </span>
      </div>
      
      <div className="email-list">
        {emails.length === 0 ? (
          <div className="empty-state">
            {isSearchResults ? (
              <>
                <FaSearch className="empty-state-icon" />
                <p>검색 결과가 없습니다</p>
                <small>다른 검색어를 시도해보세요.</small>
              </>
            ) : (
              <>
                <FaEnvelope className="empty-state-icon" />
                <p>이메일이 없습니다</p>
                <small>폴더를 선택하여 이메일을 확인하세요.</small>
              </>
            )}
          </div>
        ) : (
          emails.map(renderEmailItem)
        )}
      </div>
    </div>
  );
};

export default EmailList;