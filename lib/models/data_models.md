# 📋 데이터 모델 통합 명세
*최종 업데이트: 2025-08-29*

## 🎯 앱의 핵심 가치
**"누구와 함께했는지"**에 중점을 둔 설계로, Friend와 DiaryEntry 간의 관계가 가장 중요한 데이터 구조입니다.

## 🔐 인증 시스템
- **OAuth 기반 인증**: Supabase Auth의 `auth.users` 테이블 활용
- **제공자**: Google, Apple, GitHub 등
- **유저 구분**: `auth.users.id` (UUID)를 기준으로 모든 데이터 분리

## 📊 데이터베이스 테이블 목록

### 📋 기본 테이블 (Base Tables)
| 테이블명 | 역할 | 주요 컬럼 | RLS 적용 |
|---------|------|----------|---------|
| `profiles` | 사용자 프로필 확장 | id(UUID), display_name, avatar_url, user_code | ✅ |
| `friends` | 친구 관리 | id(INT), user_id, connected_user_id, nickname | ✅ |
| `escape_cafes` | 방탈출 카페 정보 (공통) | id(INT), name, address, contact | ✅ |
| `escape_themes` | 방탈출 테마 정보 (공통) | id(INT), cafe_id, name, difficulty | ✅ |
| `diary_entries` | 방탈출 일지 | id(INT), user_id, theme_id, date, rating | ✅ |
| `diary_entry_participants` | 일지 참여자 관계 | id(INT), diary_entry_id, user_id, friend_id | ✅ |

### 🔍 뷰 (Views)
| 뷰명 | 역할 | 기반 테이블 | 목적 |
|-----|------|-----------|------|
| `diary_participants_with_details` | 참여자 정보 조회 최적화 | diary_entry_participants + friends | 복잡한 JOIN 로직 캡슐화 |

### 📈 인덱스 및 성능 최적화
- **복합 인덱스**: `diary_entries(user_id, date DESC)` - 사용자별 일지 날짜순 정렬
- **단일 인덱스**: `escape_themes(cafe_id)` - 카페별 테마 조회
- **UNIQUE 제약**: `profiles(user_code)` - 사용자 코드 중복 방지

---

## 📊 모델별 상세 명세

### 1. User / Profiles
**개념**: 앱 사용자 (OAuth 인증 기반)

#### 📋 **테이블 상세 설명**

**`profiles` 테이블**은 Supabase Auth의 `auth.users`와 1:1 연결되는 확장 프로필 테이블입니다.

**주요 특징:**
- **OAuth 연동**: Google, Apple 등의 OAuth 제공자와 연동
- **자동 프로필 생성**: 첫 로그인 시 `AuthService.getCurrentUserProfile()`에서 UPSERT로 자동 생성
- **개인정보 관리**: 표시 이름, 아바타 이미지 등 사용자 커스터마이징 정보 저장
- **RLS 보안**: 본인의 프로필만 조회/수정 가능한 보안 정책 적용

**데이터 플로우:**
1. OAuth 로그인 → `auth.users` 자동 생성 (Supabase Auth)
2. 앱 최초 접근 → `profiles` 테이블에 기본 정보 자동 생성
3. 프로필 편집 → `ProfileEditScreen`에서 표시명, 아바타 수정
4. 실시간 동기화 → 모든 화면에서 즉시 반영

#### Flutter Model (User)
```dart
class User {
  final String id;           // auth.users.id와 동일
  final String name;         // 실명
  final String email;        // 이메일
  final String? avatarUrl;   // 프로필 이미지 URL
  final DateTime joinedAt;   // 가입일시
  
  // Supabase 연동 필드
  final DateTime createdAt;
  final DateTime updatedAt;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) { /* 구현 예정 */ }
  Map<String, dynamic> toJson() { /* 구현 예정 */ }
}
```

#### Supabase Table (profiles)
```sql
CREATE TABLE profiles (
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
CREATE POLICY "Users can manage own profile" ON profiles USING (auth.uid() = id);
```

---

### 2. Friend
**개념**: 함께 방탈출을 한 친구 (연결된 유저 + 비연결 유저 모두 지원)

#### 📋 **테이블 상세 설명**

**`friends` 테이블**은 앱의 핵심 소셜 기능을 담당하는 테이블로, 사용자가 방탈출을 함께한 친구들을 관리합니다.

**주요 특징:**
- **하이브리드 친구 시스템**: 앱 사용자인 친구 + 앱을 사용하지 않는 친구 모두 지원
- **개인별 관리**: 각 사용자마다 독립적인 친구 목록 (동일인을 다른 별명으로 관리 가능)
- **실시간 정보 반영**: 연결된 친구가 프로필 변경 시 자동으로 모든 일지에 반영
- **INTEGER ID**: UUID에서 INTEGER로 변경하여 더 간결하고 효율적인 식별자 사용

**친구 유형:**
1. **연결된 친구** (`connected_user_id` 존재)
   - 앱을 사용하는 실제 사용자와 연결
   - 실명, 이메일, 프로필 사진 등 실시간 정보 표시
   - 친구가 표시명 변경 시 모든 일지에 자동 반영

2. **비연결 친구** (`connected_user_id` null)
   - 앱을 사용하지 않는 친구
   - 사용자가 입력한 별명만 표시
   - 수동으로 정보 관리

**데이터 플로우:**
1. 친구 추가 → `FriendsScreen`에서 별명 입력 (연결 여부는 추후 구현)
2. 일지 작성 시 → 친구 선택하여 `diary_entry_participants`에 자동 등록
3. 친구 정보 변경 → 모든 관련 일지에 실시간 반영
4. 통계 표시 → 메인 화면에서 "가장 많이 함께한 친구" 랭킹 표시

#### Flutter Model
```dart
class Friend {
  final int id;                       // 친구 고유 ID (SERIAL INTEGER)
  final String userId;                // 소유자 ID (UUID)
  final String? connectedUserId;      // 연결된 유저 ID (옵션, UUID)
  final User? connectedUser;          // 연결된 유저 정보 (옵션)
  final String nickname;              // 내가 부르는 이름 (필수)
  final String? memo;                 // 친구 메모
  final DateTime addedAt;             // 친구 추가일
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Friend({
    required this.id,
    required this.userId,
    this.connectedUserId,
    this.connectedUser,
    required this.nickname,
    this.memo,
    required this.addedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Helper methods
  bool get isConnected => connectedUserId != null && connectedUser != null;
  String get displayName => nickname;
  String? get displayEmail => connectedUser?.email;
  String? get realName => connectedUser?.name;
  
  factory Friend.fromJson(Map<String, dynamic> json) { /* 구현 예정 */ }
  Map<String, dynamic> toJson() { /* 구현 예정 */ }
}
```

#### Supabase Table (friends)
```sql
CREATE TABLE friends (
  id SERIAL PRIMARY KEY,                                       -- INTEGER로 변경
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,   -- UUID 유지
  connected_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- UUID 유지
  nickname TEXT NOT NULL,
  memo TEXT,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, nickname) -- 동일 유저 내에서 닉네임 중복 방지
);

-- RLS 정책: 자신의 친구만 관리 가능
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own friends" ON friends USING (auth.uid() = user_id);
```

---

### 3. EscapeCafe
**개념**: 방탈출 카페 (모든 유저가 공유하는 공통 데이터)

#### 📋 **테이블 상세 설명**

**`escape_cafes` 테이블**은 전국의 방탈출 카페 정보를 저장하는 공통 데이터베이스입니다.

**주요 특징:**
- **공유 데이터**: 모든 사용자가 동일한 카페 정보 공유 (중복 방지)
- **계층적 구조**: 카페 → 테마의 2단계 계층 구조
- **지연 로딩**: 카페 선택 시에만 해당 카페의 테마 목록 로드로 성능 최적화
- **읽기 전용**: 일반 사용자는 조회만 가능 (관리자만 수정 권한)

**데이터 소스:**
- 방탈출 카페 공식 정보
- 사용자 제보 (추후 구현 예정)
- 크롤링 데이터 (추후 구현 예정)

**성능 최적화:**
- 카페 목록은 앱 시작 시 전체 로드
- 테마 목록은 카페 선택 시 지연 로딩
- 자동완성 기능으로 빠른 검색 지원

**데이터 플로우:**
1. 앱 시작 → `EscapeRoomService.getAllCafes()` 전체 카페 목록 로드
2. 일지 작성 → 자동완성으로 카페 검색 및 선택
3. 카페 선택 → `EscapeRoomService.getThemesByCafe(cafeId)` 해당 카페 테마 로드
4. 테마 자동완성 → 선택된 카페의 테마 목록에서 검색

#### Flutter Model
```dart
class EscapeCafe {
  final int id;              // 카페 고유 ID (SERIAL/INTEGER)
  final String name;         // 카페명
  final String? address;     // 주소
  final String? contact;     // 연락처
  final String? logoUrl;     // 로고 이미지 URL
  final DateTime createdAt;
  final DateTime updatedAt;
  
  EscapeCafe({
    required this.id,
    required this.name,
    this.address,
    this.contact,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory EscapeCafe.fromJson(Map<String, dynamic> json) { /* 구현 예정 */ }
  Map<String, dynamic> toJson() { /* 구현 예정 */ }
}
```

#### Supabase Table (escape_cafes)
```sql
CREATE TABLE escape_cafes (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  contact TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책: 모든 인증된 유저가 조회 가능
ALTER TABLE escape_cafes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view cafes" ON escape_cafes FOR SELECT TO authenticated USING (true);
```

---

### 4. EscapeTheme
**개념**: 방탈출 테마 (모든 유저가 공유하는 공통 데이터)

#### 📋 **테이블 상세 설명**

**`escape_themes` 테이블**은 각 방탈출 카페에서 운영하는 테마들의 상세 정보를 저장합니다.

**주요 특징:**
- **카페별 분류**: `cafe_id`를 통해 각 카페의 테마들을 그룹화
- **풍부한 메타데이터**: 난이도, 제한시간, 장르 등 테마 선택에 필요한 정보 제공
- **유연한 데이터 구조**: 일부 필드는 nullable로 설정하여 데이터 부족 시에도 등록 가능
- **지연 로딩 최적화**: 카페 선택 후에만 로드되어 초기 로딩 속도 향상

**데이터 특성:**
- **난이도**: 1~5단계 (null 허용, 정보 없는 테마 대응)
- **장르**: 배열 형태로 다중 장르 지원 (예: ["추리", "공포", "어드벤처"])
- **제한시간**: Duration 타입으로 정확한 시간 관리
- **테마 이미지**: 썸네일 URL 저장으로 시각적 정보 제공

**성능 최적화:**
- 카페 선택 시에만 해당 테마들 로드
- 자동완성에서 빠른 검색을 위한 인덱싱
- EscapeCafe와 조인하여 카페 정보와 함께 제공

**데이터 플로우:**
1. 카페 선택 → `EscapeRoomService.getThemesByCafe(cafeId)` 호출
2. 테마 목록 로드 → 자동완성 필드에 표시
3. 테마 검색 → 이름으로 필터링하여 실시간 검색
4. 테마 선택 → 일지 작성 시 `DiaryEntry.themeId`에 저장

#### Flutter Model
```dart
class EscapeTheme {
  final int id;                   // 테마 고유 ID (SERIAL/INTEGER)
  final int cafeId;               // 소속 카페 ID (INTEGER)
  final EscapeCafe? cafe;         // 소속 카페 (조인 시에만)
  final String name;              // 테마명
  final int? difficulty;          // 난이도 (1~5) - NULLABLE: DB에서 null 값 허용
  final Duration? timeLimit;      // 제한시간
  final List<String>? genre;      // 장르 (추리, 공포, SF 등)
  final String? themeImageUrl;    // 테마 이미지 URL
  final DateTime createdAt;
  final DateTime updatedAt;
  
  EscapeTheme({
    required this.id,
    required this.cafeId,
    this.cafe,
    required this.name,
    this.difficulty,              // NULLABLE로 변경 (2025-08-13)
    this.timeLimit,
    this.genre,
    this.themeImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory EscapeTheme.fromJson(Map<String, dynamic> json) { /* 구현 완료 */ }
  Map<String, dynamic> toJson() { /* 구현 완료 */ }
}
```

#### Supabase Table (escape_themes)
```sql
CREATE TABLE escape_themes (
  id SERIAL PRIMARY KEY,
  cafe_id INTEGER REFERENCES escape_cafes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  difficulty INTEGER CHECK (difficulty IS NULL OR (difficulty >= 1 AND difficulty <= 5)), -- NULLABLE (2025-08-13)
  time_limit_minutes INTEGER,
  genre TEXT[], -- 배열 타입
  theme_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책: 모든 인증된 유저가 조회 가능
ALTER TABLE escape_themes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view themes" ON escape_themes FOR SELECT TO authenticated USING (true);

-- 인덱스
CREATE INDEX idx_escape_themes_cafe_id ON escape_themes(cafe_id);
```

---

### 5. DiaryEntry
**개념**: 방탈출 일지 엔트리 (개별 유저 데이터)

#### 📋 **테이블 상세 설명**

**`diary_entries` 테이블**은 사용자가 방탈출 카페에서 진행한 각각의 경험을 기록하는 핵심 테이블입니다.

**주요 특징:**
- **개인별 데이터**: RLS 정책으로 본인이 작성/참여한 일지만 접근 가능
- **풍부한 메타데이터**: 만족도, 탈출 여부, 소요시간, 힌트 사용 등 상세 기록
- **참여자 시스템**: 별도 `diary_entry_participants` 테이블과 연동하여 다중 참여자 지원
- **INTEGER ID**: UUID에서 SERIAL INTEGER로 변경하여 성능 최적화

**게임 결과 데이터:**
- **rating**: 0.5~5.0 별점 (0.5 단위, null 가능)
- **escaped**: 탈출 성공/실패 여부 (null = 기록 없음)
- **hintUsedCount**: 사용한 힌트 횟수 (기본값 0)
- **timeTaken**: 게임 소요시간 (Duration, 분 단위 저장)
- **photos**: 인증샷/추억 사진 URL 배열

**참여자 관리:**
- **작성자 자동 포함**: 일지 작성 시 본인도 자동으로 참여자에 추가
- **친구 다중 선택**: `diary_entry_participants`를 통해 여러 친구와의 경험 기록
- **실시간 정보**: 친구 정보 변경 시 모든 관련 일지에 자동 반영

**데이터 플로우:**
1. 일지 작성 → `WriteDiaryScreen`에서 카페/테마 선택 및 상세 정보 입력
2. 참여자 추가 → 본인 + 선택된 친구들 자동으로 `diary_entry_participants`에 등록
3. 일지 조회 → `getMyDiaryEntries()`로 본인이 참여한 모든 일지 반환
4. 통계 생성 → 메인 화면에서 총 방탈출 횟수, 친구 랭킹 등 표시

#### Flutter Model
```dart
class DiaryEntry {
  final int id;                       // 엔트리 고유 ID (SERIAL INTEGER) - ✅ 2025-08-14 변경
  final String userId;                // 작성자 ID (UUID)
  final int themeId;                  // 진행한 테마 ID (INTEGER)
  final EscapeTheme? theme;           // 테마 정보 (조인 시에만)
  final DateTime date;                // 진행 날짜
  final List<Friend>? friends;        // 참여자 정보 (별도 테이블에서 조회) - ✅ 2025-08-14
  final String? memo;                 // 메모/후기
  final double? rating;               // 별점 (0.0~5.0) - nullable (기본값 없음)
  final bool? escaped;                // 탈출 성공 여부
  final int? hintUsedCount;           // 사용한 힌트 횟수
  final Duration? timeTaken;          // 소요 시간
  final List<String>? photos;         // 사진 URL 목록
  final DateTime createdAt;
  final DateTime updatedAt;
  
  DiaryEntry({
    required this.id,
    required this.userId,
    required this.themeId,
    this.theme,
    required this.date,
    this.friends,
    this.memo,
    this.rating,
    this.escaped,
    this.hintUsedCount,
    this.timeTaken,
    this.photos,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Helper getter
  EscapeCafe? get cafe => theme?.cafe;
  
  factory DiaryEntry.fromJson(Map<String, dynamic> json) { /* ✅ 구현 완료 */ }
  Map<String, dynamic> toJson() { /* ✅ 구현 완료 */ }
}
```

#### Supabase Table (diary_entries)
```sql
CREATE TABLE diary_entries (
  id SERIAL PRIMARY KEY,  -- ✅ 2025-08-14: UUID에서 SERIAL INTEGER로 변경
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

-- RLS 정책: 자신의 일지만 관리 가능
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own entries" ON diary_entries USING (auth.uid() = user_id);

-- 인덱스
CREATE INDEX idx_diary_entries_user_date ON diary_entries(user_id, date DESC);
```

#### 관계 테이블 (diary_entry_participants) - ✅ 2025-08-14 구조 개선

#### 📋 **테이블 상세 설명**

**`diary_entry_participants` 테이블**은 방탈출 일지의 참여자 정보를 관리하는 관계 테이블입니다. 앱의 핵심 소셜 기능을 담당합니다.

**주요 특징:**
- **다대다 관계**: DiaryEntry와 참여자(User/Friend) 간의 다대다 관계 해결
- **하이브리드 참여자**: 앱 사용자(`user_id`) + 비사용자(`friend_id`) 모두 지원
- **작성자 자동 포함**: 일지 작성 시 본인도 자동으로 참여자로 등록
- **INTEGER ID**: 더 효율적인 식별자로 성능 최적화

**참여자 유형별 데이터 구조:**
```sql
-- 작성자 (본인)
INSERT INTO diary_entry_participants (diary_entry_id, user_id, friend_id)
VALUES (123, 'author-uuid', NULL);

-- 연결된 친구 (앱 사용자)
INSERT INTO diary_entry_participants (diary_entry_id, user_id, friend_id)
VALUES (123, 'friend-user-uuid', 456);

-- 비연결 친구 (앱 미사용자)
INSERT INTO diary_entry_participants (diary_entry_id, user_id, friend_id)
VALUES (123, NULL, 789);
```

**데이터 무결성:**
- **체크 제약조건**: `user_id` 또는 `friend_id` 중 하나는 반드시 존재
- **중복 방지**: 동일 일지에 같은 참여자 중복 등록 방지
- **CASCADE 삭제**: 일지 삭제 시 관련 참여자 정보 자동 정리

**성능 최적화:**
- **복합 인덱스**: `diary_entry_id` + `user_id` 조합으로 빠른 조회
- **RLS 보안**: 본인이 참여한 일지의 참여자 정보만 접근 가능
- **조인 최적화**: 뷰(`diary_participants_with_details`)를 통한 복잡한 조인 단순화

**데이터 플로우:**
1. 일지 작성 → 작성자 본인 자동 추가
2. 친구 선택 → 선택된 친구들 배치 추가
3. 참여자 조회 → `getDiaryParticipants()`로 Friend 객체 목록 반환
4. 실시간 반영 → 친구 정보 변경 시 모든 일지에 자동 업데이트
```sql
CREATE TABLE diary_entry_participants (
  id SERIAL PRIMARY KEY,                                         -- INTEGER로 변경
  diary_entry_id INTEGER REFERENCES diary_entries(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,        -- 연결된 사용자 (nullable)
  friend_id INTEGER REFERENCES friends(id) ON DELETE CASCADE,    -- 친구 정보 (nullable) - INTEGER로 변경
  added_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 제약조건: user_id 또는 friend_id 중 하나는 반드시 존재
  CONSTRAINT check_user_or_friend_exists CHECK (user_id IS NOT NULL OR friend_id IS NOT NULL),
  
  -- 중복 방지
  UNIQUE(diary_entry_id, COALESCE(user_id, '00000000-0000-0000-0000-000000000000'), 
         COALESCE(friend_id, '00000000-0000-0000-0000-000000000000'))
);

-- RLS 정책: 자신이 참여한 일지의 참여자 정보만 조회/관리 가능
ALTER TABLE diary_entry_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view participants of their entries" ON diary_entry_participants
FOR SELECT USING (
  diary_entry_id IN (
    SELECT id FROM diary_entries WHERE user_id = auth.uid()
  ) OR user_id = auth.uid()
);

CREATE POLICY "Authors can manage participants" ON diary_entry_participants
FOR ALL USING (
  diary_entry_id IN (
    SELECT id FROM diary_entries WHERE user_id = auth.uid()
  )
);

-- 성능 최적화 인덱스
CREATE INDEX idx_diary_entry_participants_diary_entry_id ON diary_entry_participants(diary_entry_id);
CREATE INDEX idx_diary_entry_participants_user_id ON diary_entry_participants(user_id);
```

---

## 🔧 공통 설정

### 자동 updated_at 갱신 트리거
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_friends_updated_at BEFORE UPDATE ON friends FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_diary_entries_updated_at BEFORE UPDATE ON diary_entries FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
-- escape_cafes, escape_themes는 관리자만 수정하므로 선택사항
```

### 주요 쿼리 예시
```sql
-- 유저의 모든 일지 조회 (테마, 카페 정보 포함)
SELECT 
  de.*,
  et.name as theme_name,
  et.difficulty,
  ec.name as cafe_name,
  ec.address as cafe_address
FROM diary_entries de
JOIN escape_themes et ON de.theme_id = et.id
JOIN escape_cafes ec ON et.cafe_id = ec.id
WHERE de.user_id = auth.uid()
ORDER BY de.date DESC;

-- 특정 일지의 친구들 조회
SELECT f.nickname, f.memo, u.display_name, u.avatar_url
FROM diary_entry_friends def
JOIN friends f ON def.friend_id = f.id
LEFT JOIN profiles u ON f.connected_user_id = u.id
WHERE def.diary_entry_id = $1;
```

---

## 🚀 최근 구현 완료

### ⚡ 2025-08-29 데이터베이스 최적화 (뷰 구조 개선)

#### 🔄 `diary_participants_with_details` 뷰 최적화
**문제점**: 기존 뷰에서 중복 컬럼과 비효율적인 구조
- `friend_id`와 `friend_table_id` 중복
- `user_id`와 `actual_user_id` 중복  
- `display_name` 미리 계산으로 정규화 위반

**해결책**: 뷰 단순화 + Flutter에서 실시간 JOIN
```sql
-- 최적화된 뷰 (2025-08-29)
CREATE VIEW diary_participants_with_details AS
SELECT 
    dep.diary_entry_id,
    dep.user_id,          -- 직접 참여자 (작성자 등)
    dep.friend_id,        -- 친구 테이블 참조
    
    -- 연결 상태만 계산 (나머지는 Flutter에서 실시간 JOIN)
    CASE 
        WHEN dep.user_id IS NOT NULL THEN true
        WHEN dep.friend_id IS NOT NULL AND f.connected_user_id IS NOT NULL THEN true
        ELSE false
    END AS is_connected

FROM diary_entry_participants dep
LEFT JOIN friends f ON (dep.friend_id = f.id);
```

#### 🎯 Flutter 코드 개선
**변경사항**: 뷰에서 기본 정보만 가져오고, 실제 사용자/친구 정보는 별도 쿼리
- **직접 참여자**: `profiles` 테이블에서 `display_name`, `email`, `avatar_url` 조회
- **친구 참여자**: `friends` 테이블에서 `nickname`, `connected_user_id` 조회 후 필요시 `profiles` 추가 조회
- **실시간 반영**: `display_name` 변경 시 자동으로 모든 일지에 반영

#### ✅ 최적화 효과
1. **데이터 정규화 준수**: 중복 데이터 저장 없음
2. **실시간 정보 반영**: 프로필 변경 시 즉시 모든 곳에 반영
3. **성능 향상**: 불필요한 컬럼 제거로 뷰 크기 감소
4. **유지보수성**: 각 테이블의 책임이 명확함

### ⚡ 2025-08-14 주요 업데이트 (참여자 시스템 개선)

#### 🔄 데이터베이스 구조 변경
1. **`diary_entries.id`**: UUID → SERIAL INTEGER 변경 (성능 최적화)
2. **`diary_entry_friends` → `diary_entry_participants`**: 테이블명 변경
3. **nullable `user_id`**: 연결되지 않은 친구도 참여자로 추가 가능
4. **`friend_id` 컬럼 추가**: `friends` 테이블 직접 참조로 친구 정보 실시간 반영
5. **작성자 자동 추가**: 일지 작성 시 본인도 자동으로 참여자에 포함

#### 🎯 참여자 관리 시스템 개선
```sql
-- 새로운 participants 테이블 구조
diary_entry_participants:
- 작성자(본인): user_id = "author-uuid", friend_id = null
- 연결된 친구: user_id = "friend-user-uuid", friend_id = "friend-record-uuid"  
- 연결되지 않은 친구: user_id = null, friend_id = "friend-record-uuid"
```

#### 🎨 UI/UX 개선
1. **메인 화면 개선**: "최근 진행한 테마"에 친구 정보 표시 추가
2. **친구 정보 실시간 표시**: 일지 리스트와 메인 화면에서 참여자 정보 표시
3. **일관된 친구 표시**: 모든 화면에서 동일한 Chip 스타일로 친구 표시

### ⚡ 2025-08-13 주요 업데이트 사항
1. **지연 로딩 패턴** - `EscapeRoomService` 클래스로 DB 쿼리 분리
2. **EscapeTheme.difficulty** - nullable 처리로 DB null 값 대응
3. **자동 프로필 생성** - OAuth 로그인 시 UPSERT로 중복 처리
4. **RawAutocomplete UX 개선** - 자동 포커스 및 옵션 표시 최적화
5. **JSON 직렬화** - Flutter 모델의 `fromJson/toJson` 구현 완료

### 🔄 서비스 계층 구조
```dart
// 서비스 클래스들
- AuthService           // OAuth 인증 관리
- EscapeRoomService     // 카페/테마 DB 쿼리 (지연 로딩)
- DatabaseService       // 친구/일지 CRUD 작업 + 참여자 관리 ✅
```

### 🎯 데이터 흐름 (업데이트)

1. **OAuth 로그인** → `auth.users` 자동 생성
2. **프로필 자동 생성** → `AuthService.getCurrentUserProfile()` UPSERT
3. **카페 목록 로드** → `EscapeRoomService.getAllCafes()` 
4. **테마 지연 로딩** → 카페 선택 시 `EscapeRoomService.getThemesByCafe(cafeId)`
5. **친구 관리** → `DatabaseService` CRUD + 실시간 정보 반영 ✅
6. **일지 작성** → `diary_entries` + `diary_entry_participants` 관계 생성 ✅
7. **참여자 자동 추가** → 작성자 본인 + 선택된 친구들 자동 포함 ✅
8. **친구 정보 표시** → 메인화면 및 일지 리스트에서 실시간 표시 ✅