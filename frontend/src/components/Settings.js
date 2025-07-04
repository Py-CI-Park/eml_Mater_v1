import React, { useState, useEffect } from 'react';
import { Form, Button, Alert, Card, Row, Col } from 'react-bootstrap';
import { FaCog, FaFolder, FaSave, FaCheck } from 'react-icons/fa';
import { emailAPI, handleAPIError } from '../services/api';

const Settings = ({ config, onConfigSave }) => {
  const [formData, setFormData] = useState({
    email_root: '',
    port: 5000,
    host: '127.0.0.1'
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [stats, setStats] = useState(null);

  useEffect(() => {
    if (config) {
      setFormData({
        email_root: config.email_root || '',
        port: config.port || 5000,
        host: config.host || '127.0.0.1'
      });
    }
  }, [config]);

  useEffect(() => {
    if (formData.email_root) {
      loadStats();
    }
  }, [formData.email_root]);

  const loadStats = async () => {
    try {
      const response = await emailAPI.getStats();
      setStats(response.data);
    } catch (error) {
      console.error('통계 로드 실패:', error);
      setStats(null);
    }
  };

  const handleInputChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
    setError(null);
    setSuccess(false);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.email_root.trim()) {
      setError({ message: '이메일 폴더 경로를 입력해주세요.' });
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      const response = await emailAPI.saveConfig(formData);
      
      if (response.data.success) {
        setSuccess(true);
        onConfigSave(formData);
        
        // 성공 메시지 3초 후 자동 숨김
        setTimeout(() => setSuccess(false), 3000);
      }
    } catch (error) {
      console.error('설정 저장 실패:', error);
      setError(handleAPIError(error));
    } finally {
      setLoading(false);
    }
  };

  const renderStats = () => {
    if (!stats) return null;

    return (
      <Card className="card-custom">
        <Card.Header>
          <h5 className="mb-0">
            <FaFolder className="me-2" />
            통계 정보
          </h5>
        </Card.Header>
        <Card.Body>
          <Row>
            <Col md={6}>
              <div className="text-center">
                <h3 className="text-primary">{stats.total_emails.toLocaleString()}</h3>
                <p className="text-muted mb-0">총 이메일 수</p>
              </div>
            </Col>
            <Col md={6}>
              <div className="text-center">
                <h3 className="text-success">{stats.total_folders.toLocaleString()}</h3>
                <p className="text-muted mb-0">총 폴더 수</p>
              </div>
            </Col>
          </Row>
        </Card.Body>
      </Card>
    );
  };

  return (
    <div className="settings-container">
      <div className="settings-section">
        <h2 className="settings-title">
          <FaCog className="me-2" />
          설정
        </h2>

        {error && (
          <Alert variant="danger" className="mb-4">
            <strong>오류:</strong> {error.message}
          </Alert>
        )}

        {success && (
          <Alert variant="success" className="mb-4">
            <FaCheck className="me-2" />
            설정이 성공적으로 저장되었습니다!
          </Alert>
        )}

        <Form onSubmit={handleSubmit}>
          <Card className="card-custom mb-4">
            <Card.Header>
              <h5 className="mb-0">이메일 폴더 설정</h5>
            </Card.Header>
            <Card.Body>
              <Form.Group className="mb-3">
                <Form.Label className="fw-bold">
                  <FaFolder className="me-2" />
                  이메일 루트 폴더 경로 *
                </Form.Label>
                <Form.Control
                  type="text"
                  value={formData.email_root}
                  onChange={(e) => handleInputChange('email_root', e.target.value)}
                  placeholder="예: /home/user/emails 또는 C:\Emails"
                  required
                />
                <Form.Text className="text-muted">
                  .eml 파일들이 저장된 폴더의 경로를 입력하세요. 하위 폴더들도 자동으로 검색됩니다.
                </Form.Text>
              </Form.Group>

              <Row>
                <Col md={6}>
                  <Form.Group className="mb-3">
                    <Form.Label className="fw-bold">서버 포트</Form.Label>
                    <Form.Control
                      type="number"
                      value={formData.port}
                      onChange={(e) => handleInputChange('port', parseInt(e.target.value))}
                      min="1000"
                      max="65535"
                    />
                    <Form.Text className="text-muted">
                      백엔드 서버가 실행될 포트 번호
                    </Form.Text>
                  </Form.Group>
                </Col>
                <Col md={6}>
                  <Form.Group className="mb-3">
                    <Form.Label className="fw-bold">서버 호스트</Form.Label>
                    <Form.Control
                      type="text"
                      value={formData.host}
                      onChange={(e) => handleInputChange('host', e.target.value)}
                      placeholder="127.0.0.1"
                    />
                    <Form.Text className="text-muted">
                      보안을 위해 localhost(127.0.0.1) 권장
                    </Form.Text>
                  </Form.Group>
                </Col>
              </Row>
            </Card.Body>
          </Card>

          <div className="d-flex justify-content-end">
            <Button
              type="submit"
              variant="primary"
              className="btn-custom"
              disabled={loading}
            >
              {loading ? (
                <>로딩중...</>
              ) : (
                <>
                  <FaSave className="me-2" />
                  설정 저장
                </>
              )}
            </Button>
          </div>
        </Form>
      </div>

      {formData.email_root && (
        <div className="mt-4">
          {renderStats()}
        </div>
      )}

      <Card className="card-custom mt-4">
        <Card.Header>
          <h5 className="mb-0">사용 방법</h5>
        </Card.Header>
        <Card.Body>
          <ol>
            <li className="mb-2">
              <strong>이메일 폴더 설정:</strong> .eml 파일들이 저장된 폴더의 경로를 입력하세요.
            </li>
            <li className="mb-2">
              <strong>폴더 탐색:</strong> 왼쪽 사이드바에서 폴더를 선택하여 이메일 목록을 확인하세요.
            </li>
            <li className="mb-2">
              <strong>이메일 보기:</strong> 이메일을 클릭하면 오른쪽에서 내용을 확인할 수 있습니다.
            </li>
            <li className="mb-2">
              <strong>검색:</strong> 상단 검색바를 사용하여 제목, 보낸이, 본문에서 검색할 수 있습니다.
            </li>
            <li>
              <strong>첨부파일:</strong> 첨부파일이 있는 이메일은 다운로드 링크가 제공됩니다.
            </li>
          </ol>
        </Card.Body>
      </Card>
    </div>
  );
};

export default Settings;