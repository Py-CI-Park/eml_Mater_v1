import React, { useState, useEffect } from 'react';
import { Spinner, Button, Card } from 'react-bootstrap';
import { FaDownload, FaPaperclip, FaEnvelope, FaEye } from 'react-icons/fa';
import DOMPurify from 'dompurify';
import parse from 'html-react-parser';
import { emailAPI, handleAPIError } from '../services/api';

const EmailViewer = ({ email, loading }) => {
  const [emailContent, setEmailContent] = useState(null);
  const [contentLoading, setContentLoading] = useState(false);
  const [error, setError] = useState(null);
  const [viewMode, setViewMode] = useState('html'); // 'html' 또는 'text'

  useEffect(() => {
    if (email) {
      loadEmailContent();
    } else {
      setEmailContent(null);
      setError(null);
    }
  }, [email]);

  const loadEmailContent = async () => {
    if (!email) return;
    
    try {
      setContentLoading(true);
      setError(null);
      
      const response = await emailAPI.getEmailContent(
        email.folder_path || 'root', 
        email.filename
      );
      
      setEmailContent(response.data);
      
      // HTML이 있으면 HTML 모드로, 없으면 텍스트 모드로 설정
      if (response.data.body_html) {
        setViewMode('html');
      } else {
        setViewMode('text');
      }
    } catch (error) {
      console.error('이메일 내용 로드 실패:', error);
      setError(handleAPIError(error));
    } finally {
      setContentLoading(false);
    }
  };

  const formatEmailAddress = (address) => {
    if (!address) return 'N/A';
    
    // 긴 주소 목록을 줄여서 표시
    if (address.length > 100) {
      return address.substring(0, 100) + '...';
    }
    
    return address;
  };

  const downloadAttachment = (attachmentName) => {
    if (!email || !attachmentName) return;
    
    const url = emailAPI.getAttachmentUrl(
      email.folder_path || 'root',
      email.filename,
      attachmentName
    );
    
    // 새 창에서 다운로드
    window.open(url, '_blank');
  };

  const renderEmailBody = () => {
    if (!emailContent) return null;

    const hasHtml = emailContent.body_html && emailContent.body_html.trim();
    const hasText = emailContent.body_text && emailContent.body_text.trim();

    if (!hasHtml && !hasText) {
      return (
        <div className="text-muted text-center py-4">
          <FaEnvelope size={32} className="mb-2" />
          <p>이메일 본문이 없습니다.</p>
        </div>
      );
    }

    return (
      <div>
        {/* 보기 모드 토글 버튼 */}
        {hasHtml && hasText && (
          <div className="mb-3">
            <Button
              variant={viewMode === 'html' ? 'primary' : 'outline-primary'}
              size="sm"
              className="me-2"
              onClick={() => setViewMode('html')}
            >
              HTML 보기
            </Button>
            <Button
              variant={viewMode === 'text' ? 'primary' : 'outline-primary'}
              size="sm"
              onClick={() => setViewMode('text')}
            >
              텍스트 보기
            </Button>
          </div>
        )}

        <div className="email-body-content">
          {viewMode === 'html' && hasHtml ? (
            <div>
              {parse(DOMPurify.sanitize(emailContent.body_html, {
                ALLOWED_TAGS: [
                  'div', 'p', 'span', 'br', 'strong', 'b', 'em', 'i', 'u', 
                  'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li',
                  'table', 'tr', 'td', 'th', 'thead', 'tbody', 'tfoot',
                  'a', 'img', 'blockquote', 'pre', 'code'
                ],
                ALLOWED_ATTR: [
                  'style', 'class', 'href', 'src', 'alt', 'title', 'width', 'height'
                ],
                ALLOW_DATA_ATTR: false
              }))}
            </div>
          ) : (
            <pre style={{ 
              whiteSpace: 'pre-wrap', 
              wordBreak: 'break-word',
              fontFamily: 'inherit',
              fontSize: 'inherit',
              margin: 0
            }}>
              {emailContent.body_text || '본문 내용을 표시할 수 없습니다.'}
            </pre>
          )}
        </div>
      </div>
    );
  };

  const renderAttachments = () => {
    if (!emailContent || !emailContent.attachments || emailContent.attachments.length === 0) {
      return null;
    }

    return (
      <div className="email-attachments-section">
        <h6 className="mb-3">
          <FaPaperclip className="me-2" />
          첨부파일 ({emailContent.attachments.length}개)
        </h6>
        {emailContent.attachments.map((attachment, index) => (
          <div key={index} className="attachment-item">
            <div className="attachment-info">
              <FaPaperclip size={16} className="text-muted" />
              <div>
                <div className="attachment-name" title={attachment.filename}>
                  {attachment.filename}
                </div>
                <div className="attachment-size">
                  {attachment.size_formatted} • {attachment.content_type}
                </div>
              </div>
            </div>
            <Button
              variant="outline-primary"
              size="sm"
              onClick={() => downloadAttachment(attachment.filename)}
            >
              <FaDownload size={12} className="me-1" />
              다운로드
            </Button>
          </div>
        ))}
      </div>
    );
  };

  if (!email) {
    return (
      <div className="d-flex align-items-center justify-content-center h-100">
        <div className="text-center text-muted">
          <FaEye size={48} className="mb-3" />
          <p>이메일을 선택하여 내용을 확인하세요.</p>
        </div>
      </div>
    );
  }

  if (contentLoading) {
    return (
      <div className="d-flex align-items-center justify-content-center h-100">
        <div className="text-center">
          <Spinner animation="border" className="mb-3" />
          <p className="text-muted">이메일 내용을 불러오는 중...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <h5>이메일을 불러올 수 없습니다</h5>
        <p>{error.message}</p>
        <Button variant="outline-primary" onClick={loadEmailContent}>
          다시 시도
        </Button>
      </div>
    );
  }

  return (
    <div className="h-100 d-flex flex-column">
      {/* 이메일 헤더 */}
      <div className="email-header">
        <h4 className="email-subject-header" title={emailContent?.subject}>
          {emailContent?.subject || 'No Subject'}
        </h4>
        
        <div className="email-meta-info">
          <div className="email-meta-row">
            <span className="email-meta-label">보낸이:</span>
            <span className="email-meta-value" title={emailContent?.from}>
              {formatEmailAddress(emailContent?.from)}
            </span>
          </div>
          
          {emailContent?.to && (
            <div className="email-meta-row">
              <span className="email-meta-label">받는이:</span>
              <span className="email-meta-value" title={emailContent.to}>
                {formatEmailAddress(emailContent.to)}
              </span>
            </div>
          )}
          
          {emailContent?.cc && (
            <div className="email-meta-row">
              <span className="email-meta-label">참조:</span>
              <span className="email-meta-value" title={emailContent.cc}>
                {formatEmailAddress(emailContent.cc)}
              </span>
            </div>
          )}
          
          <div className="email-meta-row">
            <span className="email-meta-label">날짜:</span>
            <span className="email-meta-value">
              {emailContent?.date || 'Unknown'}
            </span>
          </div>
        </div>
      </div>

      {/* 이메일 본문 */}
      <div className="email-body">
        {renderEmailBody()}
        {renderAttachments()}
      </div>
    </div>
  );
};

export default EmailViewer;