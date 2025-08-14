# 📋 데이터 모델 통합 명세

## 🎯 앱의 핵심 가치
**"누구와 함께했는지"**에 중점을 둔 설계로, Friend와 DiaryEntry 간의 관계가 가장 중요한 데이터 구조입니다.

## 🔐 인증 시스템
- **OAuth 기반 인증**: Supabase Auth의 `auth.users` 테이블 활용
- **제공자**: Google, Apple, GitHub 등
- **유저 구분**: `auth.users.id` (UUID)를 기준으로 모든 데이터 분리

---

## 📊 모델별 상세 명세

### 1. User / Profiles
**개념**: 앱 사용자 (OAuth 인증 기반)

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

#### Flutter Model
```dart
class Friend {
  final String id;                    // 친구 고유 ID
  final String userId;                // 소유자 ID
  final String? connectedUserId;      // 연결된 유저 ID (옵션)
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
CREATE POLICY "Users can manage own friends" ON friends USING (auth.uid() = user_id);
```

---

### 3. EscapeCafe
**개념**: 방탈출 카페 (모든 유저가 공유하는 공통 데이터)

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
```sql
CREATE TABLE diary_entry_participants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  diary_entry_id INTEGER REFERENCES diary_entries(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,        -- 연결된 사용자 (nullable)
  friend_id UUID REFERENCES friends(id) ON DELETE CASCADE,       -- 친구 정보 (nullable)
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