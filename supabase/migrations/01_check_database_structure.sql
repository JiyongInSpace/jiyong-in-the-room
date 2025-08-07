-- 데이터베이스 구조 확인을 위한 SQL 스크립트
-- 이 스크립트는 실제 마이그레이션이 아니라 현재 상태 확인용입니다.

-- =============================================
-- 1. 테이블 존재 여부 확인
-- =============================================

SELECT 
  'Tables Check' as check_type,
  table_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = t.table_name
    ) THEN 'EXISTS ✅'
    ELSE 'MISSING ❌'
  END as status
FROM (
  VALUES 
    ('profiles'),
    ('escape_cafes'),
    ('escape_themes'),
    ('friends'), 
    ('diary_entries'),
    ('diary_entry_friends')
) AS t(table_name);

-- =============================================
-- 2. 테이블별 컬럼 구조 확인
-- =============================================

-- 2.1 profiles 테이블 구조
SELECT 
  'Profiles Columns' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2.2 escape_cafes 테이블 구조  
SELECT 
  'Escape Cafes Columns' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'escape_cafes'
ORDER BY ordinal_position;

-- 2.3 escape_themes 테이블 구조
SELECT 
  'Escape Themes Columns' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'escape_themes'
ORDER BY ordinal_position;

-- 2.4 friends 테이블 구조
SELECT 
  'Friends Columns' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'friends'
ORDER BY ordinal_position;

-- 2.5 diary_entries 테이블 구조
SELECT 
  'Diary Entries Columns' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'diary_entries'
ORDER BY ordinal_position;

-- 2.6 diary_entry_friends 테이블 구조
SELECT 
  'Diary Entry Friends Columns' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'diary_entry_friends'
ORDER BY ordinal_position;

-- =============================================
-- 3. 기본 키 및 외래 키 제약 조건 확인
-- =============================================

-- 3.1 기본 키 확인
SELECT 
  'Primary Keys' as check_type,
  tc.table_name,
  string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) as primary_key_columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('profiles', 'escape_cafes', 'escape_themes', 'friends', 'diary_entries', 'diary_entry_friends')
GROUP BY tc.table_name
ORDER BY tc.table_name;

-- 3.2 외래 키 제약 조건 확인
SELECT 
  'Foreign Keys' as check_type,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.update_rule,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
  AND tc.table_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('profiles', 'escape_cafes', 'escape_themes', 'friends', 'diary_entries', 'diary_entry_friends')
ORDER BY tc.table_name, kcu.column_name;

-- =============================================
-- 4. 인덱스 확인
-- =============================================

SELECT 
  'Indexes' as check_type,
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'escape_cafes', 'escape_themes', 'friends', 'diary_entries', 'diary_entry_friends')
ORDER BY tablename, indexname;

-- =============================================
-- 5. RLS (Row Level Security) 상태 확인
-- =============================================

SELECT 
  'RLS Status' as check_type,
  schemaname,
  tablename,
  rowsecurity,
  CASE WHEN rowsecurity THEN 'ENABLED ✅' ELSE 'DISABLED ❌' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'escape_cafes', 'escape_themes', 'friends', 'diary_entries', 'diary_entry_friends')
ORDER BY tablename;

-- =============================================
-- 6. RLS 정책 확인
-- =============================================

SELECT 
  'RLS Policies' as check_type,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'escape_cafes', 'escape_themes', 'friends', 'diary_entries', 'diary_entry_friends')
ORDER BY tablename, policyname;

-- =============================================
-- 7. 트리거 확인
-- =============================================

SELECT 
  'Triggers' as check_type,
  trigger_schema,
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('profiles', 'escape_cafes', 'escape_themes', 'friends', 'diary_entries', 'diary_entry_friends')
ORDER BY event_object_table, trigger_name;

-- =============================================
-- 8. 사용자 정의 함수 확인 (트리거 함수 포함)
-- =============================================

SELECT 
  'Functions' as check_type,
  routine_name,
  routine_type,
  data_type as return_type,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%update_updated_at%'
ORDER BY routine_name;