-- 기존 diary_entry_friends 테이블을 diary_entry_participants로 변경하고
-- friend_id를 user_id로 변경

-- 1. 새로운 테이블 생성
CREATE TABLE diary_entry_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_entry_id INTEGER NOT NULL REFERENCES diary_entries(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 중복 방지를 위한 unique constraint
  UNIQUE(diary_entry_id, user_id)
);

-- 2. 기존 데이터를 새 테이블로 이동
INSERT INTO diary_entry_participants (diary_entry_id, user_id, added_at)
SELECT diary_entry_id, friend_id, NOW()
FROM diary_entry_friends;

-- 3. RLS 정책 설정
ALTER TABLE diary_entry_participants ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신이 참여한 일지의 참여자 정보만 볼 수 있음
CREATE POLICY "Users can view participants of their own entries" ON diary_entry_participants
FOR SELECT USING (
  diary_entry_id IN (
    SELECT id FROM diary_entries WHERE user_id = auth.uid()
  ) OR user_id = auth.uid()
);

-- 일지 작성자만 참여자를 추가할 수 있음
CREATE POLICY "Authors can manage participants" ON diary_entry_participants
FOR ALL USING (
  diary_entry_id IN (
    SELECT id FROM diary_entries WHERE user_id = auth.uid()
  )
);

-- 4. 기존 테이블 삭제
DROP TABLE diary_entry_friends;

-- 5. 인덱스 생성 (성능 최적화)
CREATE INDEX idx_diary_entry_participants_diary_entry_id ON diary_entry_participants(diary_entry_id);
CREATE INDEX idx_diary_entry_participants_user_id ON diary_entry_participants(user_id);