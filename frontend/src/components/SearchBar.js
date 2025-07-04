import React, { useState } from 'react';
import { Form, Button, Dropdown } from 'react-bootstrap';
import { FaSearch, FaFilter } from 'react-icons/fa';

const SearchBar = ({ onSearch }) => {
  const [query, setQuery] = useState('');
  const [searchIn, setSearchIn] = useState(['subject', 'from', 'body']);
  const [isAdvancedOpen, setIsAdvancedOpen] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (query.trim()) {
      onSearch(query.trim(), searchIn);
    }
  };

  const handleSearchInChange = (field) => {
    setSearchIn(prev => {
      if (prev.includes(field)) {
        // 최소 하나는 선택되어야 함
        if (prev.length > 1) {
          return prev.filter(item => item !== field);
        }
        return prev;
      } else {
        return [...prev, field];
      }
    });
  };

  const searchOptions = [
    { key: 'subject', label: '제목' },
    { key: 'from', label: '보낸이' },
    { key: 'body', label: '본문' }
  ];

  return (
    <div className="search-container d-flex align-items-center">
      <Form onSubmit={handleSubmit} className="d-flex align-items-center">
        <div className="position-relative">
          <Form.Control
            type="text"
            placeholder="이메일 검색..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="search-input pe-5"
            style={{ minWidth: '250px' }}
          />
          <Button
            type="submit"
            variant="link"
            className="position-absolute top-0 end-0 h-100 px-3 border-0"
            style={{ zIndex: 10 }}
          >
            <FaSearch />
          </Button>
        </div>

        <Dropdown className="ms-2">
          <Dropdown.Toggle
            variant="outline-secondary"
            size="sm"
            className="d-flex align-items-center"
          >
            <FaFilter className="me-1" />
            검색 옵션
          </Dropdown.Toggle>

          <Dropdown.Menu>
            <div className="px-3 py-2">
              <div className="fw-bold mb-2">검색 범위:</div>
              {searchOptions.map(option => (
                <Form.Check
                  key={option.key}
                  type="checkbox"
                  id={`search-${option.key}`}
                  label={option.label}
                  checked={searchIn.includes(option.key)}
                  onChange={() => handleSearchInChange(option.key)}
                  className="mb-1"
                />
              ))}
              <div className="mt-2 text-muted small">
                검색할 항목을 최소 하나 이상 선택하세요.
              </div>
            </div>
          </Dropdown.Menu>
        </Dropdown>
      </Form>
    </div>
  );
};

export default SearchBar;