# 📦 Supabase 설정 가이드

## 🎯 목적
Flutter 앱에서 파일 업로드 및 데이터베이스 기능을 사용하기 위한 Supabase 설정

---

## 📋 설정 순서

### 1️⃣ Supabase Dashboard 접속
1. https://supabase.com 접속 및 로그인
2. 프로젝트 선택

### 2️⃣ SQL Editor 실행
1. 왼쪽 사이드바에서 **"SQL Editor"** 클릭
2. **"New query"** 버튼 클릭

### 3️⃣ SQL 스크립트 실행
1. `supabase_complete_setup.sql` 파일 열기
2. **전체 내용 복사** (Ctrl+A → Ctrl+C)
3. SQL Editor에 **붙여넣기** (Ctrl+V)
4. **"Run"** 버튼 클릭 (또는 Ctrl+Enter)

### 4️⃣ 실행 결과 확인
스크립트 실행 후 다음 결과들이 표시되어야 합니다:

#### ✅ notices 테이블 구조
```
column_name      | data_type | column_default
-----------------+-----------+----------------
id              | uuid      | gen_random_uuid()
title           | text      |
content         | text      |
author          | text      |
author_id       | uuid      |
category        | text      | '일반'
views           | integer   | 0
is_new          | boolean   | true
file_urls       | text[]    | ARRAY[]::text[]
file_names      | text[]    | ARRAY[]::text[]
created_at      | timestamp | now()
updated_at      | timestamp | now()
```

#### ✅ Storage 버킷
```
id           | name         | public | file_size_limit | allowed_mime_types
-------------+--------------+--------+-----------------+--------------------
notice-files | notice-files | true   | 52428800        | NULL
```

#### ✅ Storage 정책 (4개)
- Anyone can view files (SELECT)
- Authenticated users can upload files (INSERT)
- Authenticated users can update files (UPDATE)
- Users can delete own files (DELETE)

#### ✅ RLS 정책 (각 테이블당 4개)
**notices 테이블:**
- Anyone can read notices (SELECT)
- Authenticated users can insert notices (INSERT)
- Users can update own notices (UPDATE)
- Users can delete own notices (DELETE)

**gallery 테이블:** (동일 구조)

**press_releases 테이블:** (동일 구조)

---

## 🔍 문제 해결

### ❌ 에러: "relation does not exist"
**원인:** 테이블이 아직 생성되지 않음
**해결:** 먼저 테이블 생성 SQL을 실행해야 함

### ❌ 에러: "mime type not supported"
**원인:** allowed_mime_types가 제한되어 있음
**해결:** SQL 스크립트에서 `allowed_mime_types = NULL`로 설정됨 (모든 파일 허용)

### ❌ 에러: "permission denied"
**원인:** RLS 정책이 없거나 잘못 설정됨
**해결:** SQL 스크립트가 모든 RLS 정책을 자동으로 설정함

### ❌ 파일 업로드가 안됨
**체크리스트:**
1. [ ] notice-files 버킷이 생성되었는지 확인
2. [ ] public = true인지 확인
3. [ ] Storage 정책 4개가 모두 있는지 확인
4. [ ] 사용자가 로그인되어 있는지 확인

---

## 🧪 테스트 방법

### 1. Storage 버킷 확인
```sql
SELECT * FROM storage.buckets WHERE id = 'notice-files';
```

### 2. Storage 정책 확인
```sql
SELECT policyname FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';
```

### 3. 테이블 RLS 정책 확인
```sql
SELECT tablename, policyname FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;
```

---

## ✅ 설정 완료 후

설정이 완료되면 Flutter 앱에서:

1. ✅ 관리자 로그인
2. ✅ 공지사항 작성
3. ✅ 파일 첨부 (최대 5개, 최대 50MB)
4. ✅ 저장

→ 파일이 Supabase Storage에 업로드되고 공지사항에 첨부됩니다!

---

## 📞 추가 도움말

- Supabase 공식 문서: https://supabase.com/docs
- Storage 가이드: https://supabase.com/docs/guides/storage
- RLS 가이드: https://supabase.com/docs/guides/auth/row-level-security

---

## 🎉 완료!

SQL 스크립트를 실행하면 모든 설정이 자동으로 완료됩니다.
에러 없이 실행되면 바로 사용 가능합니다! 🚀
