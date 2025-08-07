-- =============================================================================
-- 탈출일지 앱 데이터베이스 테이블 생성 스크립트
-- data_models.md 명세에 따른 완전한 스키마 생성
-- =============================================================================

-- ===================================================================
-- 1. profiles 테이블 (사용자 프로필)
-- auth.users 테이블과 1:1 관계
-- ===================================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (id)
);

-- RLS 정책: 자신의 프로필만 조회/수정 가능
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 기존 정책이 있다면 삭제하고 다시 생성
DROP POLICY IF EXISTS "Users can manage own profile" ON profiles;
CREATE POLICY "Users can manage own profile" ON profiles 
  FOR ALL USING (auth.uid() = id);

-- ===================================================================
-- 2. escape_cafes 테이블 (방탈출 카페)
-- 모든 유저가 공유하는 공통 데이터
-- ===================================================================

CREATE TABLE IF NOT EXISTS escape_cafes (
  id UUID DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  contact TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (id)
);

-- RLS 정책: 모든 인증된 유저가 조회 가능
ALTER TABLE escape_cafes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view cafes" ON escape_cafes;
CREATE POLICY "Anyone can view cafes" ON escape_cafes 
  FOR SELECT TO authenticated USING (true);

-- ===================================================================
-- 3. escape_themes 테이블 (방탈출 테마)
-- 모든 유저가 공유하는 공통 데이터
-- ===================================================================

CREATE TABLE IF NOT EXISTS escape_themes (
  id UUID DEFAULT gen_random_uuid(),
  cafe_id UUID REFERENCES escape_cafes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  difficulty INTEGER CHECK (difficulty >= 1 AND difficulty <= 5),
  time_limit_minutes INTEGER,
  genre TEXT[], -- 배열 타입
  theme_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (id)
);

-- RLS 정책: 모든 인증된 유저가 조회 가능
ALTER TABLE escape_themes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view themes" ON escape_themes;
CREATE POLICY "Anyone can view themes" ON escape_themes 
  FOR SELECT TO authenticated USING (true);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_escape_themes_cafe_id ON escape_themes(cafe_id);

-- ===================================================================
-- 4. friends 테이블 (친구 관리)
-- 연결된 유저 + 비연결 유저 모두 지원
-- ===================================================================

CREATE TABLE IF NOT EXISTS friends (
  id UUID DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  connected_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  nickname TEXT NOT NULL,
  memo TEXT,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (id),
  UNIQUE(user_id, nickname) -- 동일 유저 내에서 닉네임 중복 방지
);

-- RLS 정책: 자신의 친구만 관리 가능
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own friends" ON friends;
CREATE POLICY "Users can manage own friends" ON friends 
  FOR ALL USING (auth.uid() = user_id);

-- ===================================================================
-- 5. diary_entries 테이블 (방탈출 일지)
-- 개별 유저의 방탈출 경험 기록
-- ===================================================================

CREATE TABLE IF NOT EXISTS diary_entries (
  id UUID DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_id UUID REFERENCES escape_themes(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  memo TEXT,
  rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5),
  escaped BOOLEAN,
  hint_used_count INTEGER DEFAULT 0,
  time_taken_minutes INTEGER,
  photos TEXT[], -- 사진 URL 배열
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (id)
);

-- RLS 정책: 자신의 일지만 관리 가능
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own entries" ON diary_entries;
CREATE POLICY "Users can manage own entries" ON diary_entries 
  FOR ALL USING (auth.uid() = user_id);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_diary_entries_user_date ON diary_entries(user_id, date DESC);

-- ===================================================================
-- 6. diary_entry_friends 테이블 (일지-친구 관계)
-- N:M 관계 테이블
-- ===================================================================

CREATE TABLE IF NOT EXISTS diary_entry_friends (
  diary_entry_id UUID REFERENCES diary_entries(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES friends(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (diary_entry_id, friend_id)
);

-- RLS 정책: 자신의 일지에 대한 친구 관계만 관리 가능
ALTER TABLE diary_entry_friends ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own entry friends" ON diary_entry_friends;
CREATE POLICY "Users can manage own entry friends" ON diary_entry_friends 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM diary_entries 
      WHERE id = diary_entry_id AND user_id = auth.uid()
    )
  );

-- ===================================================================
-- 7. updated_at 자동 갱신을 위한 트리거 함수
-- ===================================================================

-- 함수가 이미 존재하는지 확인하고 생성
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================================================================
-- 8. 각 테이블에 updated_at 트리거 적용
-- ===================================================================

-- profiles 테이블
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- friends 테이블  
DROP TRIGGER IF EXISTS update_friends_updated_at ON friends;
CREATE TRIGGER update_friends_updated_at 
  BEFORE UPDATE ON friends 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- diary_entries 테이블
DROP TRIGGER IF EXISTS update_diary_entries_updated_at ON diary_entries;
CREATE TRIGGER update_diary_entries_updated_at 
  BEFORE UPDATE ON diary_entries 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- escape_cafes, escape_themes는 관리자만 수정하므로 선택사항
-- 필요시 주석을 제거하여 활성화
-- DROP TRIGGER IF EXISTS update_escape_cafes_updated_at ON escape_cafes;
-- CREATE TRIGGER update_escape_cafes_updated_at 
--   BEFORE UPDATE ON escape_cafes 
--   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DROP TRIGGER IF EXISTS update_escape_themes_updated_at ON escape_themes;
-- CREATE TRIGGER update_escape_themes_updated_at 
--   BEFORE UPDATE ON escape_themes 
--   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===================================================================
-- 9. 초기 데이터 삽입 (선택사항)
-- ===================================================================

-- 샘플 방탈출 카페 데이터
INSERT INTO escape_cafes (name, address, contact) VALUES
  ('넥스트에디션', '서울시 강남구 테헤란로', '02-1234-5678'),
  ('비밀의 방', '서울시 홍대 와우산로', '02-2345-6789'),
  ('미스터리 하우스', '부산시 해운대구 해운대로', '051-3456-7890')
ON CONFLICT DO NOTHING;

-- 샘플 테마 데이터 
INSERT INTO escape_themes (cafe_id, name, difficulty, time_limit_minutes, genre)
SELECT 
  c.id,
  theme.name,
  theme.difficulty,
  theme.time_limit,
  theme.genre
FROM escape_cafes c
CROSS JOIN (VALUES
  ('스쿨 좀비', 4, 60, ARRAY['공포', '액션']),
  ('시간의 틈', 3, 90, ARRAY['추리', 'SF']),
  ('마법사의 방', 2, 75, ARRAY['판타지', '어드벤처'])
) AS theme(name, difficulty, time_limit, genre)
WHERE c.name = '넥스트에디션'
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 마이그레이션 완료
-- =============================================================================