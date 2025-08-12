-- =============================================================================
-- 마이그레이션: ID 타입을 혼합형으로 변경 (UUID + Integer)
-- Users: UUID (auth.users 매칭)
-- Escape Cafes & Themes: SERIAL integers 
-- Friends: user_id(UUID) + connected_user_id(UUID) - 둘 다 auth.users 참조
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. 기존 테이블 백업 및 데이터 임시 보관
-- =============================================================================

-- 기존 데이터 백업
CREATE TEMP TABLE temp_escape_cafes AS SELECT * FROM escape_cafes;
CREATE TEMP TABLE temp_escape_themes AS SELECT * FROM escape_themes;
CREATE TEMP TABLE temp_friends AS SELECT * FROM friends;
CREATE TEMP TABLE temp_diary_entries AS SELECT * FROM diary_entries;
CREATE TEMP TABLE temp_diary_entry_friends AS SELECT * FROM diary_entry_friends;

-- =============================================================================
-- 2. 기존 테이블 삭제 (외래키 제약조건 때문에 순서 중요)
-- =============================================================================

DROP TABLE IF EXISTS diary_entry_friends CASCADE;
DROP TABLE IF EXISTS diary_entries CASCADE;
DROP TABLE IF EXISTS friends CASCADE;  
DROP TABLE IF EXISTS escape_themes CASCADE;
DROP TABLE IF EXISTS escape_cafes CASCADE;

-- =============================================================================
-- 3. escape_cafes 테이블 재생성 (SERIAL ID 사용)
-- =============================================================================

CREATE TABLE escape_cafes (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  contact TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책 설정
ALTER TABLE escape_cafes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view cafes" ON escape_cafes 
  FOR SELECT TO authenticated USING (true);

-- =============================================================================
-- 4. escape_themes 테이블 재생성 (SERIAL ID, INTEGER cafe_id)
-- =============================================================================

CREATE TABLE escape_themes (
  id SERIAL PRIMARY KEY,
  cafe_id INTEGER REFERENCES escape_cafes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  difficulty INTEGER CHECK (difficulty >= 1 AND difficulty <= 5),
  time_limit_minutes INTEGER,
  genre TEXT[], -- 배열 타입
  theme_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책 및 인덱스 설정
ALTER TABLE escape_themes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view themes" ON escape_themes 
  FOR SELECT TO authenticated USING (true);
CREATE INDEX idx_escape_themes_cafe_id ON escape_themes(cafe_id);

-- =============================================================================
-- 5. friends 테이블 재생성 (user_id와 connected_user_id 모두 UUID)
-- =============================================================================

CREATE TABLE friends (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  connected_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  nickname TEXT NOT NULL,
  memo TEXT,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, nickname) -- 동일 유저 내에서 닉네임 중복 방지
);

-- RLS 정책 설정
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own friends" ON friends 
  FOR ALL USING (auth.uid() = user_id);

-- =============================================================================
-- 6. diary_entries 테이블 재생성 (theme_id는 INTEGER)
-- =============================================================================

CREATE TABLE diary_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_id INTEGER REFERENCES escape_themes(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  memo TEXT,
  rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5),
  escaped BOOLEAN,
  hint_used_count INTEGER DEFAULT 0,
  time_taken_minutes INTEGER,
  photos TEXT[], -- 사진 URL 배열
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책 및 인덱스 설정
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own entries" ON diary_entries 
  FOR ALL USING (auth.uid() = user_id);
CREATE INDEX idx_diary_entries_user_date ON diary_entries(user_id, date DESC);

-- =============================================================================
-- 7. diary_entry_friends 테이블 재생성
-- =============================================================================

CREATE TABLE diary_entry_friends (
  diary_entry_id UUID REFERENCES diary_entries(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES friends(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  PRIMARY KEY (diary_entry_id, friend_id)
);

-- RLS 정책 설정
ALTER TABLE diary_entry_friends ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own entry friends" ON diary_entry_friends 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM diary_entries 
      WHERE id = diary_entry_id AND user_id = auth.uid()
    )
  );

-- =============================================================================
-- 8. 데이터 마이그레이션 (UUID to INTEGER 매핑)
-- =============================================================================

-- 8.1 escape_cafes 데이터 삽입 (UUID → SERIAL ID 매핑 테이블 생성)
CREATE TEMP TABLE uuid_to_cafe_id_mapping (
  old_uuid UUID,
  new_id INTEGER
);

-- 기존 카페 데이터를 새 테이블에 삽입하고 매핑 생성
INSERT INTO escape_cafes (name, address, contact, logo_url, created_at, updated_at)
SELECT name, address, contact, logo_url, created_at, updated_at 
FROM temp_escape_cafes
ORDER BY created_at; -- 생성 순서 유지

-- 매핑 테이블 생성 (ROW_NUMBER로 순서 보장)
INSERT INTO uuid_to_cafe_id_mapping (old_uuid, new_id)
SELECT 
  t.id as old_uuid,
  ROW_NUMBER() OVER (ORDER BY t.created_at) as new_id
FROM temp_escape_cafes t
ORDER BY t.created_at;

-- 8.2 escape_themes 데이터 삽입 (UUID → SERIAL ID 매핑)
CREATE TEMP TABLE uuid_to_theme_id_mapping (
  old_uuid UUID,
  new_id INTEGER
);

INSERT INTO escape_themes (cafe_id, name, difficulty, time_limit_minutes, genre, theme_image_url, created_at, updated_at)
SELECT 
  m.new_id as cafe_id,
  t.name, 
  t.difficulty, 
  t.time_limit_minutes, 
  t.genre, 
  t.theme_image_url, 
  t.created_at, 
  t.updated_at
FROM temp_escape_themes t
JOIN uuid_to_cafe_id_mapping m ON t.cafe_id = m.old_uuid
ORDER BY t.created_at;

-- 테마 매핑 테이블 생성
INSERT INTO uuid_to_theme_id_mapping (old_uuid, new_id)
SELECT 
  t.id as old_uuid,
  ROW_NUMBER() OVER (ORDER BY t.created_at) as new_id
FROM temp_escape_themes t
ORDER BY t.created_at;

-- 8.3 friends 테이블 데이터 마이그레이션
-- connected_user_id는 UUID 유지하므로 기존 데이터 그대로 유지
INSERT INTO friends (id, user_id, connected_user_id, nickname, memo, added_at, created_at, updated_at)
SELECT 
  id,
  user_id,
  connected_user_id,
  nickname,
  memo,
  added_at,
  created_at,
  updated_at
FROM temp_friends;

-- 8.4 diary_entries 데이터 마이그레이션
INSERT INTO diary_entries (id, user_id, theme_id, date, memo, rating, escaped, hint_used_count, time_taken_minutes, photos, created_at, updated_at)
SELECT 
  de.id,
  de.user_id,
  tm.new_id as theme_id,
  de.date,
  de.memo,
  de.rating,
  de.escaped,
  de.hint_used_count,
  de.time_taken_minutes,
  de.photos,
  de.created_at,
  de.updated_at
FROM temp_diary_entries de
JOIN uuid_to_theme_id_mapping tm ON de.theme_id = tm.old_uuid;

-- 8.5 diary_entry_friends 관계 데이터 마이그레이션
INSERT INTO diary_entry_friends (diary_entry_id, friend_id, created_at)
SELECT 
  def.diary_entry_id,
  def.friend_id,
  def.created_at
FROM temp_diary_entry_friends def
WHERE EXISTS (
  SELECT 1 FROM diary_entries de WHERE de.id = def.diary_entry_id
) AND EXISTS (
  SELECT 1 FROM friends f WHERE f.id = def.friend_id
);

-- =============================================================================
-- 9. updated_at 트리거 재설정
-- =============================================================================

-- 기존 트리거 삭제 후 재생성
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_friends_updated_at ON friends;
DROP TRIGGER IF EXISTS update_diary_entries_updated_at ON diary_entries;
DROP TRIGGER IF EXISTS update_escape_cafes_updated_at ON escape_cafes;
DROP TRIGGER IF EXISTS update_escape_themes_updated_at ON escape_themes;

-- 트리거 재생성
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friends_updated_at 
  BEFORE UPDATE ON friends 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_diary_entries_updated_at 
  BEFORE UPDATE ON diary_entries 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_escape_cafes_updated_at 
  BEFORE UPDATE ON escape_cafes 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_escape_themes_updated_at 
  BEFORE UPDATE ON escape_themes 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 10. 샘플 데이터 재삽입 (기존 데이터가 없는 경우에만)
-- =============================================================================

-- 카페가 비어있는 경우에만 샘플 데이터 추가
INSERT INTO escape_cafes (name, address, contact) 
SELECT * FROM (VALUES
  ('넥스트에디션', '서울시 강남구 테헤란로', '02-1234-5678'),
  ('비밀의 방', '서울시 홍대 와우산로', '02-2345-6789'),
  ('미스터리 하우스', '부산시 해운대구 해운대로', '051-3456-7890')
) AS v(name, address, contact)
WHERE NOT EXISTS (SELECT 1 FROM escape_cafes WHERE name = v.name);

-- 테마 데이터 (넥스트에디션 카페에만 추가)
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
  AND NOT EXISTS (
    SELECT 1 FROM escape_themes et 
    WHERE et.cafe_id = c.id AND et.name = theme.name
  );

-- 임시 매핑 테이블 정리
DROP TABLE uuid_to_cafe_id_mapping;
DROP TABLE uuid_to_theme_id_mapping;

COMMIT;

-- =============================================================================
-- 마이그레이션 완료 - 새 스키마 요약
-- =============================================================================

-- 🔍 변경사항 요약:
-- ✅ escape_cafes.id: UUID → SERIAL (integer)
-- ✅ escape_themes.id: UUID → SERIAL (integer) 
-- ✅ escape_themes.cafe_id: UUID → INTEGER (escape_cafes 참조)
-- ✅ friends.connected_user_id: UUID 유지 (auth.users 직접 참조 유지)
-- ✅ diary_entries.theme_id: UUID → INTEGER (escape_themes 참조)
-- ✅ profiles 테이블: UUID 유지 (auth.users.id와 매칭)
-- ✅ friends.user_id: UUID 유지 (auth.users.id 참조)

-- ⚠️ 주의사항:
-- escape_cafes와 escape_themes가 UUID에서 SERIAL INTEGER로 변경됨
-- 기존 UUID 데이터는 생성 순서에 따라 1, 2, 3... 순서로 새 ID 할당
-- friends 테이블의 connected_user_id는 UUID 유지하여 auth.users 직접 참조 가능