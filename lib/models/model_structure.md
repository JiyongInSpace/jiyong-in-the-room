# 📋 모델 구조 명세

## 현재 모델 구조

### 1. EscapeCafe (방탈출 카페)
```dart
class EscapeCafe {
  final String id;           // 카페 고유 ID
  final String name;         // 카페명
  final String? address;     // 주소 (선택사항)
  final String? contact;     // 연락처 (선택사항)  
  final String? logoUrl;     // 로고 이미지 URL (선택사항)
}
```

### 2. EscapeTheme (방탈출 테마)
```dart
class EscapeTheme {
  final String id;                // 테마 고유 ID
  final String name;              // 테마명
  final EscapeCafe cafe;          // 소속 카페
  final int difficulty;           // 난이도 (1~5)
  final Duration? timeLimit;      // 제한시간 (선택사항)
  final List<String>? genre;      // 장르 (추리, 공포, SF 등)
  final String? themeImageUrl;    // 테마 이미지 URL (선택사항)
}
```

### 3. User (유저)
```dart
class User {
  final String id;           // 유저 고유 ID
  final String name;         // 실명
  final String email;        // 이메일
  final String? avatarUrl;   // 프로필 이미지 URL (선택사항)
  final DateTime joinedAt;   // 가입일시
}
```

### 4. Friend (친구)
```dart
class Friend {
  final String? connected;   // 연결된 유저 ID (없으면 연결되지 않은 상태)
  final User? user;          // 연결된 경우에만 실제 유저 정보
  final DateTime addedAt;    // 친구 추가일시
  final String nickname;     // 내가 부르는 이름 (필수)
  final String? memo;        // 친구에 대한 메모 (선택사항)
  
  // Helper methods:
  bool get isConnected       // 연결된 친구인지 확인
  String get displayName     // 표시할 이름 (별명 우선)
  String? get displayEmail   // 표시할 이메일 (연결된 경우만)
  String? get displayAvatarUrl  // 표시할 아바타 URL (연결된 경우만)
  String? get realName       // 실제 이름 (연결된 경우만)
}
```

### 5. DiaryEntry (일지 엔트리)
```dart
class DiaryEntry {
  final int id;                    // 엔트리 고유 ID (현재 int, Supabase 연동시 String으로 변경 예정)
  final EscapeTheme theme;         // 진행한 테마
  final DateTime date;             // 진행 날짜
  final List<Friend>? friends;     // 함께한 친구들 (선택사항)
  final String? memo;              // 메모/후기 (선택사항)
  final double? rating;            // 별점 (선택사항)
  final bool? escaped;             // 탈출 성공 여부 (선택사항)
  final int? hintUsedCount;        // 사용한 힌트 횟수 (선택사항)
  final Duration? timeTaken;       // 소요 시간 (선택사항)
  
  // Helper getter:
  EscapeCafe get cafe              // theme.cafe에 접근하는 편의 메서드
}
```

## 🔄 Supabase 연동을 위한 수정 예정 사항

### 필요한 변경사항
1. **ID 타입 통일**: `DiaryEntry.id`를 `String`으로 변경 (UUID 사용)
2. **타임스탬프 추가**: 모든 모델에 `createdAt`, `updatedAt` 필드 추가
3. **직렬화 지원**: 모든 모델에 `toJson()`, `fromJson()` 메서드 추가
4. **관계형 데이터**: 객체 참조를 ID 참조로 변경하는 필드 추가

### 예상 Supabase 테이블 구조
- `escape_cafes` 테이블
- `escape_themes` 테이블 (cafe_id 외래키)
- `users` 테이블
- `friends` 테이블 (user_id 외래키)
- `diary_entries` 테이블 (theme_id 외래키)
- `diary_entry_friends` 테이블 (다대다 관계)

## 🎯 앱의 핵심 가치
**"누구와 함께했는지"**에 중점을 둔 설계로, Friend와 DiaryEntry 간의 관계가 가장 중요한 데이터 구조입니다.