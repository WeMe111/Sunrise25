-- =====================================================
-- Supabase 테이블 수정 및 문제 해결 스크립트
-- =====================================================

-- 1. notices 테이블에 category 컬럼 추가 (존재하지 않는 경우)
ALTER TABLE public.notices
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT '일반';

-- notices 테이블에 files 컬럼 추가 (파일 업로드용)
ALTER TABLE public.notices
ADD COLUMN IF NOT EXISTS file_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS file_names TEXT[] DEFAULT ARRAY[]::TEXT[];

-- 2. notices 테이블의 RLS 정책 확인 및 재설정
-- 기존 정책 삭제
DROP POLICY IF EXISTS "Anyone can read notices" ON public.notices;
DROP POLICY IF EXISTS "Authenticated users can insert notices" ON public.notices;
DROP POLICY IF EXISTS "Users can update own notices" ON public.notices;
DROP POLICY IF EXISTS "Users can delete own notices" ON public.notices;

-- RLS 활성화
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

-- 새로운 정책 생성
-- 누구나 읽기 가능
CREATE POLICY "Anyone can read notices"
  ON public.notices FOR SELECT
  USING (true);

-- 인증된 사용자는 삽입 가능
CREATE POLICY "Authenticated users can insert notices"
  ON public.notices FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 자신의 글은 수정 가능
CREATE POLICY "Users can update own notices"
  ON public.notices FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

-- 자신의 글은 삭제 가능
CREATE POLICY "Users can delete own notices"
  ON public.notices FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- =====================================================
-- 3. gallery 테이블 RLS 정책 확인 및 재설정
-- =====================================================

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

-- =====================================================
-- 4. press_releases 테이블 RLS 정책 확인 및 재설정
-- =====================================================

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
-- 5. 테스트 데이터 확인
-- =====================================================

-- notices 테이블 구조 확인
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'notices' AND table_schema = 'public';

-- 현재 RLS 정책 확인
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('notices', 'gallery', 'press_releases');
