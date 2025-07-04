import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api';

// Axios 인스턴스 생성
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 요청 인터셉터
api.interceptors.request.use(
  (config) => {
    console.log(`API 요청: ${config.method?.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 응답 인터셉터
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    console.error('API 오류:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

// API 함수들
export const emailAPI = {
  // 설정 관리
  getConfig: () => api.get('/config'),
  saveConfig: (config) => api.post('/config', config),

  // 폴더 관리
  getFolders: () => api.get('/folders'),

  // 이메일 관리
  getEmails: (folderPath) => {
    const encodedPath = encodeURIComponent(folderPath || 'root');
    return api.get(`/emails/${encodedPath}`);
  },

  getEmailContent: (folderPath, filename) => {
    const encodedFolderPath = encodeURIComponent(folderPath || 'root');
    const encodedFilename = encodeURIComponent(filename);
    return api.get(`/email/${encodedFolderPath}/${encodedFilename}`);
  },

  // 검색
  searchEmails: (query, searchIn = ['subject', 'from', 'body']) => 
    api.post('/search', { query, search_in: searchIn }),

  // 첨부파일
  getAttachmentUrl: (folderPath, filename, attachmentName) => {
    const encodedFolderPath = encodeURIComponent(folderPath || 'root');
    const encodedFilename = encodeURIComponent(filename);
    const encodedAttachmentName = encodeURIComponent(attachmentName);
    return `${API_BASE_URL}/attachment/${encodedFolderPath}/${encodedFilename}/${encodedAttachmentName}`;
  },

  // 통계
  getStats: () => api.get('/stats'),
};

// 에러 처리 헬퍼
export const handleAPIError = (error) => {
  if (error.response) {
    // 서버에서 응답한 에러
    const message = error.response.data?.error || error.response.data?.message || '서버 오류가 발생했습니다.';
    return {
      type: 'server',
      message,
      status: error.response.status,
    };
  } else if (error.request) {
    // 네트워크 오류
    return {
      type: 'network',
      message: '서버에 연결할 수 없습니다. 백엔드 서버가 실행 중인지 확인하세요.',
    };
  } else {
    // 기타 오류
    return {
      type: 'unknown',
      message: error.message || '알 수 없는 오류가 발생했습니다.',
    };
  }
};

export default api;