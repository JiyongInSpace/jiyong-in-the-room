-- =============================================================================
-- 스키마 검증: friends 테이블의 connected_user_id가 올바른 UUID 타입인지 확인
-- =============================================================================

-- 현재 friends 테이블의 스키마 확인
DO $$
DECLARE
    connected_user_id_type text;
    user_id_type text;
BEGIN
    -- connected_user_id 컬럼의 데이터 타입 확인
    SELECT data_type INTO connected_user_id_type
    FROM information_schema.columns 
    WHERE table_name = 'friends' 
    AND column_name = 'connected_user_id'
    AND table_schema = 'public';
    
    -- user_id 컬럼의 데이터 타입 확인  
    SELECT data_type INTO user_id_type
    FROM information_schema.columns 
    WHERE table_name = 'friends' 
    AND column_name = 'user_id'
    AND table_schema = 'public';
    
    -- 결과 출력
    RAISE NOTICE '=== Friends 테이블 스키마 검증 결과 ===';
    RAISE NOTICE 'user_id 타입: %', COALESCE(user_id_type, 'NOT FOUND');
    RAISE NOTICE 'connected_user_id 타입: %', COALESCE(connected_user_id_type, 'NOT FOUND');
    
    -- 검증
    IF user_id_type = 'uuid' AND connected_user_id_type = 'uuid' THEN
        RAISE NOTICE '✅ 올바름: 두 컬럼 모두 UUID 타입입니다.';
    ELSE
        RAISE WARNING '❌ 문제 발견: UUID가 아닌 타입이 감지되었습니다.';
    END IF;
END $$;

-- 외래키 제약조건 확인
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='friends'
  AND tc.table_schema='public'
ORDER BY tc.constraint_name;