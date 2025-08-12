# 🔄 데이터베이스 스키마 마이그레이션 가이드

## 📋 변경사항 요약

이 마이그레이션은 데이터베이스 스키마를 혼합 ID 타입 구조로 변경합니다:

### 🎯 변경 대상
- ✅ **escape_cafes.id**: `UUID` → `SERIAL INTEGER` (1, 2, 3, ...)
- ✅ **escape_themes.id**: `UUID` → `SERIAL INTEGER` (1, 2, 3, ...)
- ✅ **escape_themes.cafe_id**: `UUID` → `INTEGER` (escape_cafes 참조)
- ✅ **diary_entries.theme_id**: `UUID` → `INTEGER` (escape_themes 참조)

### 🔒 유지되는 구조
- ✅ **profiles.id**: `UUID` (auth.users.id와 매칭)
- ✅ **friends.user_id**: `UUID` (auth.users.id 참조)
- ✅ **friends.connected_user_id**: `UUID` (auth.users.id 참조)
- ✅ **diary_entries.id**: `UUID`
- ✅ **diary_entries.user_id**: `UUID`

---

## 🚀 마이그레이션 실행 방법

### 방법 1: Supabase Dashboard (추천)

1. **Supabase Dashboard 접속**
   ```
   https://supabase.com/dashboard/project/zvhymzlclfzkoysnhfgf/sql
   ```

2. **마이그레이션 SQL 복사**
   - `supabase/migrations/03_update_id_types_to_mixed.sql` 파일 전체 내용을 복사

3. **SQL Editor에서 실행**
   - Dashboard의 SQL Editor에 붙여넣기
   - "RUN" 버튼 클릭하여 실행

### 방법 2: Supabase CLI (로컬)

```bash
# 1. Supabase CLI 설치 (이미 설치됨)
npx supabase --version

# 2. 환경변수 설정
export SUPABASE_ACCESS_TOKEN=sbp_3e23423af215a3a7e5d64e9775e259fd9f6879e9

# 3. 프로젝트 링크 (데이터베이스 비밀번호 필요)
npx supabase link --project-ref zvhymzlclfzkoysnhfgf

# 4. 마이그레이션 실행
npx supabase db push
```

### 방법 3: 직접 PostgreSQL 연결

```bash
# 환경변수에서 연결 정보 사용
psql "postgresql://postgres:[YOUR_PASSWORD]@aws-0-ap-northeast-2.pooler.supabase.com:5432/postgres" \
  -f supabase/migrations/03_update_id_types_to_mixed.sql
```

---

## ⚠️ 주의사항

### 🔥 마이그레이션 전 백업 필수
- 마이그레이션은 **기존 테이블을 삭제하고 재생성**합니다
- **반드시 데이터를 백업**한 후 실행하세요
- 테스트 환경에서 먼저 실행해보는 것을 권장합니다

### 📊 데이터 변환 과정
1. **기존 데이터 임시 백업** → TEMP 테이블에 저장
2. **테이블 삭제** → 외래키 순서를 고려하여 삭제
3. **새 구조로 재생성** → SERIAL ID 사용
4. **데이터 마이그레이션** → UUID → INTEGER 매핑
5. **관계 복원** → 새 ID로 외래키 재설정

### 🔄 ID 매핑 방식
- **escape_cafes**: UUID → 1, 2, 3, ... (생성 순서대로)
- **escape_themes**: UUID → 1, 2, 3, ... (생성 순서대로)
- **기존 관계 유지**: diary_entries와 테마 간 관계는 자동으로 새 ID에 매핑

---

## 🧪 마이그레이션 검증

### 실행 후 확인사항

```sql
-- 1. 테이블 구조 확인
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('escape_cafes', 'escape_themes', 'diary_entries', 'friends')
ORDER BY table_name, ordinal_position;

-- 2. 데이터 개수 확인
SELECT 'escape_cafes' as table_name, COUNT(*) as count FROM escape_cafes
UNION ALL
SELECT 'escape_themes', COUNT(*) FROM escape_themes
UNION ALL
SELECT 'diary_entries', COUNT(*) FROM diary_entries
UNION ALL
SELECT 'friends', COUNT(*) FROM friends;

-- 3. 외래키 관계 확인
SELECT 
  de.id as diary_id,
  de.theme_id as theme_id_int,
  et.name as theme_name,
  ec.name as cafe_name
FROM diary_entries de
JOIN escape_themes et ON de.theme_id = et.id
JOIN escape_cafes ec ON et.cafe_id = ec.id
LIMIT 5;
```

---

## 🔧 Flutter 코드 업데이트 필요사항

마이그레이션 후 다음 Flutter 모델들을 업데이트해야 합니다:

```dart
// EscapeCafe 모델
class EscapeCafe {
  final int id;              // String → int 변경
  // ... 나머지 필드
}

// EscapeTheme 모델
class EscapeTheme {
  final int id;              // String → int 변경
  final int cafeId;          // String → int 변경
  // ... 나머지 필드
}

// DiaryEntry 모델
class DiaryEntry {
  final String id;           // UUID 유지
  final String userId;       // UUID 유지
  final int themeId;         // String → int 변경
  // ... 나머지 필드
}
```

---

## 💾 롤백 방법

문제 발생 시 이전 마이그레이션으로 롤백:

```sql
-- 02_create_all_tables.sql을 다시 실행하여 UUID 구조로 복원
-- 단, 데이터는 별도로 백업에서 복원해야 함
```

---

## 📞 지원

마이그레이션 중 문제 발생 시:
1. **에러 로그 확인**: SQL 실행 결과에서 구체적인 오류 메시지 확인
2. **데이터 백업 확인**: 마이그레이션 전 백업이 정상적으로 생성되었는지 확인  
3. **테이블 상태 확인**: 어느 단계에서 실패했는지 파악

**⚡ 마이그레이션은 트랜잭션으로 처리되므로, 실패 시 모든 변경사항이 자동으로 롤백됩니다.**