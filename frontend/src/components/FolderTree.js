import React from 'react';
import { Spinner } from 'react-bootstrap';
import { FaFolder, FaFolderOpen, FaInbox } from 'react-icons/fa';

const FolderTree = ({ folders, selectedFolder, onFolderSelect, loading }) => {
  if (loading && folders.length === 0) {
    return (
      <div className="loading-container">
        <Spinner animation="border" size="sm" className="me-2" />
        폴더 로딩중...
      </div>
    );
  }

  if (folders.length === 0) {
    return (
      <div className="empty-state">
        <FaFolder className="empty-state-icon" />
        <p>폴더가 없습니다</p>
        <small>설정된 경로에 .eml 파일이 있는 폴더가 없습니다.</small>
      </div>
    );
  }

  const renderFolder = (folder) => {
    const isSelected = selectedFolder && selectedFolder.path === folder.path;
    const isRoot = folder.path === '' || folder.path === 'root';
    
    return (
      <div
        key={folder.path || 'root'}
        className={`folder-item ${isSelected ? 'active' : ''}`}
        onClick={() => onFolderSelect(folder)}
      >
        <div className="folder-name">
          {isRoot ? (
            <FaInbox size={16} />
          ) : isSelected ? (
            <FaFolderOpen size={16} />
          ) : (
            <FaFolder size={16} />
          )}
          <span title={folder.name}>{folder.name}</span>
        </div>
        <span className="folder-count">{folder.count}</span>
      </div>
    );
  };

  // 폴더를 계층적으로 정렬
  const sortedFolders = [...folders].sort((a, b) => {
    // 루트 폴더를 맨 위로
    if (a.path === '' || a.path === 'root') return -1;
    if (b.path === '' || b.path === 'root') return 1;
    
    // 나머지는 이름순
    return a.name.localeCompare(b.name);
  });

  return (
    <div>
      <div className="sidebar-header">
        <FaFolder className="me-2" />
        메일 폴더
      </div>
      <div className="folder-tree">
        {sortedFolders.map(renderFolder)}
      </div>
    </div>
  );
};

export default FolderTree;