-- =====================================================
-- Supabase 완전 설정 스크립트
-- 이 파일을 Supabase SQL Editor에 복사해서 실행하세요
-- =====================================================

-- =====================================================
-- PART 1: 테이블 스키마 설정
-- =====================================================

-- 1. notices 테이블에 필요한 컬럼 추가
ALTER TABLE public.notices
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT '일반';

ALTER TABLE public.notices
ADD COLUMN IF NOT EXISTS file_urls TEXT[] DEFAULT ARRAY[]::TEXT[];

ALTER TABLE public.notices
ADD COLUMN IF NOT EXISTS file_names TEXT[] DEFAULT ARRAY[]::TEXT[];

-- 2. gallery 테이블 확인 (이미 존재하는지 확인)
-- 없으면 생성하지 않고 넘어감

-- 3. press_releases 테이블 확인
-- 없으면 생성하지 않고 넘어감

-- =====================================================
-- PART 2: Storage 버킷 생성 및 설정
-- =====================================================

-- Storage 버킷 생성 (notice-files)
-- 이미 존재하면 설정만 업데이트
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'notice-files',
  'notice-files',
  true,                    -- 공개 버킷
  52428800,               -- 50MB 제한
  NULL                    -- 모든 파일 타입 허용
)
ON CONFLICT (id)
DO UPDATE SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = NULL;

-- =====================================================
-- PART 3: Storage 정책 설정
-- =====================================================

-- 기존 정책 삭제 (충돌 방지)
DROP POLICY IF EXISTS "Anyone can view files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update files" ON storage.objects;

-- 정책 1: 누구나 파일 읽기 가능 (SELECT)
CREATE POLICY "Anyone can view files"
ON storage.objects FOR SELECT
USING (bucket_id = 'notice-files');

-- 정책 2: 인증된 사용자만 파일 업로드 가능 (INSERT)
CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'notice-files');

-- 정책 3: 인증된 사용자만 파일 업데이트 가능 (UPDATE)
CREATE POLICY "Authenticated users can update files"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'notice-files')
WITH CHECK (bucket_id = 'notice-files');

-- 정책 4: 인증된 사용자가 파일 삭제 가능 (DELETE)
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'notice-files');

-- =====================================================
-- PART 4: 테이블 RLS(Row Level Security) 정책 설정
-- =====================================================

-- ---------- notices 테이블 RLS ----------
-- 기존 정책 삭제
DROP POLICY IF EXISTS "Anyone can read notices" ON public.notices;
DROP POLICY IF EXISTS "Authenticated users can insert notices" ON public.notices;
DROP POLICY IF EXISTS "Users can update own notices" ON public.notices;
DROP POLICY IF EXISTS "Users can delete own notices" ON public.notices;

-- RLS 활성화
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

-- 정책 생성
CREATE POLICY "Anyone can read notices"
  ON public.notices FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert notices"
  ON public.notices FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own notices"
  ON public.notices FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own notices"
  ON public.notices FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- ---------- gallery 테이블 RLS ----------
DROP POLICY IF EXISTS "Anyone can read gallery" ON public.gallery;
DROP POLICY IF EXISTS "Authenticated users can insert gallery" ON public.gallery;
DROP POLICY IF EXISTS "Users can update own gallery" ON public.gallery;
DROP POLICY IF EXISTS "Users can delete own gallery" ON public.gallery;

ALTER TABLE public.gallery ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read gallery"
  ON public.gallery FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert gallery"
  ON public.gallery FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own gallery"
  ON public.gallery FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own gallery"
  ON public.gallery FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- ---------- press_releases 테이블 RLS ----------
DROP POLICY IF EXISTS "Anyone can read press releases" ON public.press_releases;
DROP POLICY IF EXISTS "Authenticated users can insert press releases" ON public.press_releases;
DROP POLICY IF EXISTS "Users can update own press releases" ON public.press_releases;
DROP POLICY IF EXISTS "Users can delete own press releases" ON public.press_releases;

ALTER TABLE public.press_releases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read press releases"
  ON public.press_releases FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert press releases"
  ON public.press_releases FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own press releases"
  ON public.press_releases FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own press releases"
  ON public.press_releases FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- =====================================================
-- PART 5: 설정 확인
-- =====================================================

-- notices 테이블 구조 확인
SELECT
  'notices 테이블 구조' as info,
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'notices'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Storage 버킷 확인
SELECT
  'Storage 버킷' as info,
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
WHERE id = 'notice-files';

-- Storage 정책 확인
SELECT
  'Storage 정책' as info,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects';

-- 테이블 RLS 정책 확인
SELECT
  'RLS 정책' as info,
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename IN ('notices', 'gallery', 'press_releases')
  AND schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 완료!
-- =====================================================
-- 위 결과를 확인하여 모든 설정이 올바른지 확인하세요.
--
-- 예상 결과:
-- 1. notices 테이블에 category, file_urls, file_names 컬럼 존재
-- 2. notice-files 버킷이 public=true, allowed_mime_types=NULL
-- 3. Storage 정책 4개 (SELECT, INSERT, UPDATE, DELETE)
-- 4. 각 테이블마다 RLS 정책 4개씩 존재
-- =====================================================
