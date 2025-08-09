# API 명세서 (제안)

Base URL: `http://127.0.0.1:<port>/api`

## 공통
- 응답: `{ success?: boolean, message?: string, error?: string } + payload`
- 에러 코드: 400 입력오류, 404 없음, 409 충돌, 500 내부오류

## 헬스체크
- GET `/health` → `{ status, timestamp }`

## 설정
- GET `/config` → `{ email_root, port, host }`
- POST `/config` body: `{ email_root, port, host }`

## 폴더/이메일
- GET `/folders` → `{ folders: [{ path, name, count }] }`
- GET `/emails/{folder_path|root}` → `{ emails: [{ subject, from, date, has_attachments, filename, folder_path }] }`
- GET `/email/{folder_path|root}/{filename}` → `전체 메일 데이터`
- GET `/attachment/{folder_path|root}/{filename}/{attachment_name}` → 파일 다운로드

## 검색
- POST `/search` body: `{ query: string, search_in: ['subject'|'from'|'body'][] }`
  - 성능형 옵션: `{ limit?: number }` 추가

## 태그/상태 (신규)
- GET `/tags` → 전체 태그
- POST `/tags` body: `{ name, color? }`
- DELETE `/tags/{id}`
- POST `/email-tags` body: `{ email_path, tag_id }`
- DELETE `/email-tags` body: `{ email_path, tag_id }`
- GET `/email-status?email_path=...`
- POST `/email-status/read` body: `{ email_path }`
- POST `/email-status/star` body: `{ email_path }` → 토글 결과 반환

## 인덱싱/통계 (신규)
- GET `/stats` → `{ total_emails, total_folders }`
- POST `/index/rebuild` → 전체 재인덱싱 트리거
- GET `/index/progress` → `{ total, processed, phase }`

## 보안/제약
- 모든 파일 경로는 서버 측에서 루트 기반 정규화 후 검증
- 첨부 다운로드 시 파일명 화이트리스트/사이즈 상한


