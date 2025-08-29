-- 일지의 메모 공개 여부를 관리하는 컬럼 추가
-- 2025-08-29: 친구들과의 메모 공유 기능 추가

-- diary_entries 테이블에 memo_public 컬럼 추가
ALTER TABLE diary_entries 
ADD COLUMN memo_public BOOLEAN DEFAULT false;

-- 코멘트 추가
COMMENT ON COLUMN diary_entries.memo_public IS '메모 공개 여부 (true: 친구들에게 공개, false: 비공개)';

-- 성능 최적화를 위한 인덱스 추가
-- 같은 테마+날짜에서 공개된 메모만 빠르게 조회하기 위함
CREATE INDEX idx_diary_theme_date_public 
ON diary_entries (theme_id, date, memo_public) 
WHERE memo_public = true;

-- 코멘트 추가
COMMENT ON INDEX idx_diary_theme_date_public IS '친구 메모 조회 최적화를 위한 복합 인덱스';

-- 마이그레이션 완료 로그
DO $$ 
BEGIN 
    RAISE NOTICE '✅ memo_public 컬럼과 인덱스가 성공적으로 추가되었습니다.';
END $$;