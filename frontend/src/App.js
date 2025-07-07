import React, { useState, useEffect } from 'react';
import { Container, Navbar, Nav, Alert, Spinner } from 'react-bootstrap';
import { FaEnvelope, FaCog, FaSearch, FaHome } from 'react-icons/fa';
import FolderTree from './components/FolderTree';
import EmailList from './components/EmailList';
import EmailViewer from './components/EmailViewer';
import SearchBar from './components/SearchBar';
import Settings from './components/Settings';
import { emailAPI, handleAPIError } from './services/api';

function App() {
  // 상태 관리
  const [currentView, setCurrentView] = useState('home'); // 'home', 'search', 'settings'
  const [folders, setFolders] = useState([]);
  const [selectedFolder, setSelectedFolder] = useState(null);
  const [emails, setEmails] = useState([]);
  const [selectedEmail, setSelectedEmail] = useState(null);
  const [searchResults, setSearchResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [config, setConfig] = useState(null);

  // 초기 설정 로드
  useEffect(() => {
    loadConfig();
  }, []);

  // 설정 로드 후 폴더 목록 로드
  useEffect(() => {
    if (config && config.email_root && currentView === 'home') {
      loadFolders();
    }
  }, [config, currentView]);

  const loadConfig = async () => {
    try {
      setLoading(true);
      const response = await emailAPI.getConfig();
      setConfig(response.data);
    } catch (error) {
      console.error('설정 로드 실패:', error);
      setError(handleAPIError(error));
    } finally {
      setLoading(false);
    }
  };

  const loadFolders = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await emailAPI.getFolders();
      setFolders(response.data.folders || []);
    } catch (error) {
      console.error('폴더 목록 로드 실패:', error);
      setError(handleAPIError(error));
    } finally {
      setLoading(false);
    }
  };

  const loadEmails = async (folderPath) => {
    try {
      setLoading(true);
      setError(null);
      const response = await emailAPI.getEmails(folderPath);
      setEmails(response.data.emails || []);
      setSelectedEmail(null); // 새 폴더 선택시 이메일 선택 해제
    } catch (error) {
      console.error('이메일 목록 로드 실패:', error);
      setError(handleAPIError(error));
      setEmails([]);
    } finally {
      setLoading(false);
    }
  };

  const handleFolderSelect = (folder) => {
    setSelectedFolder(folder);
    loadEmails(folder.path);
    setCurrentView('home');
  };

  const handleEmailSelect = (email) => {
    setSelectedEmail(email);
  };

  const handleSearch = async (query, searchIn) => {
    try {
      setLoading(true);
      setError(null);
      const response = await emailAPI.searchEmails(query, searchIn);
      setSearchResults(response.data.results || []);
      setCurrentView('search');
      setSelectedEmail(null);
    } catch (error) {
      console.error('검색 실패:', error);
      setError(handleAPIError(error));
      setSearchResults([]);
    } finally {
      setLoading(false);
    }
  };

  const handleConfigSave = (newConfig) => {
    setConfig(newConfig);
    // 설정 변경 후 홈으로 이동
    setCurrentView('home');
    // 폴더 목록 새로고침
    if (newConfig.email_root) {
      loadFolders();
    }
  };

  const renderMainContent = () => {
    // 설정이 없거나 이메일 루트가 설정되지 않은 경우
    if (!config || !config.email_root) {
      return (
        <div className="d-flex flex-column h-100">
          <div className="flex-grow-1 d-flex align-items-center justify-content-center">
            <div className="text-center">
              <FaCog size={64} className="text-muted mb-3" />
              <h4 className="text-muted">설정이 필요합니다</h4>
              <p className="text-muted">먼저 이메일 폴더 경로를 설정해주세요.</p>
              <button 
                className="btn btn-primary btn-custom"
                onClick={() => setCurrentView('settings')}
              >
                설정하기
              </button>
            </div>
          </div>
        </div>
      );
    }

    if (currentView === 'settings') {
      return (
        <Settings 
          config={config}
          onConfigSave={handleConfigSave}
        />
      );
    }

    return (
      <div className="d-flex h-100">
        {/* 폴더 트리 사이드바 */}
        <div className="sidebar">
          <FolderTree
            folders={folders}
            selectedFolder={selectedFolder}
            onFolderSelect={handleFolderSelect}
            loading={loading}
          />
        </div>

        {/* 이메일 목록 */}
        <div className="email-list-container">
          <EmailList
            emails={currentView === 'search' ? searchResults : emails}
            selectedEmail={selectedEmail}
            onEmailSelect={handleEmailSelect}
            loading={loading}
            isSearchResults={currentView === 'search'}
            folderName={selectedFolder?.name || ''}
          />
        </div>

        {/* 이메일 뷰어 */}
        <div className="email-viewer">
          <EmailViewer
            email={selectedEmail}
            loading={loading}
          />
        </div>
      </div>
    );
  };

  return (
    <div className="app-container">
      {/* 상단 네비게이션 */}
      <div className="w-100">
        <Navbar className="navbar-custom" expand="lg">
          <Container fluid>
            <Navbar.Brand>
              <FaEnvelope className="me-2" />
              이메일 관리자
            </Navbar.Brand>
            
            <Nav className="me-auto">
              <Nav.Link 
                active={currentView === 'home'}
                onClick={() => setCurrentView('home')}
              >
                <FaHome className="me-1" /> 홈
              </Nav.Link>
              <Nav.Link 
                active={currentView === 'settings'}
                onClick={() => setCurrentView('settings')}
              >
                <FaCog className="me-1" /> 설정
              </Nav.Link>
            </Nav>

            {/* 검색바 */}
            {config && config.email_root && (
              <div className="d-flex">
                <SearchBar onSearch={handleSearch} />
              </div>
            )}
          </Container>
        </Navbar>

        {/* 에러 메시지 */}
        {error && (
          <Alert variant="danger" className="mb-0 rounded-0" dismissible onClose={() => setError(null)}>
            <strong>오류:</strong> {error.message}
            {error.type === 'network' && (
              <div className="mt-2">
                <small>
                  백엔드 서버가 실행 중인지 확인하세요. (python backend/app.py)
                </small>
              </div>
            )}
          </Alert>
        )}

        {/* 메인 컨텐츠 */}
        <div className="main-content">
          {renderMainContent()}
        </div>

        {/* 전역 로딩 */}
        {loading && (
          <div className="position-fixed top-50 start-50 translate-middle" 
               style={{ zIndex: 9999 }}>
            <div className="bg-white p-3 rounded shadow">
              <Spinner animation="border" size="sm" className="me-2" />
              로딩중...
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;