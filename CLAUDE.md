# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application for tracking escape room experiences. The app allows users to create diary entries for escape rooms they've visited, including details about the cafe, theme, friends who participated, ratings, and game results.

## Development Commands

### Flutter Commands

- `flutter run` - Run the application in development mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter test` - Run tests
- `flutter analyze` - Run static analysis
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Platform-Specific Commands

- `flutter run -d android` - Run on Android device/emulator
- `flutter run -d ios` - Run on iOS device/simulator
- `flutter run -d web` - Run on web browser
- `flutter run -d macos` - Run on macOS
- `flutter run -d linux` - Run on Linux
- `flutter run -d windows` - Run on Windows

## Architecture

### Core Structure

The app follows a simple Flutter architecture pattern:

- **main.dart**: Entry point with global state management for diary entries
- **models/**: Data models for the application
  - `diary.dart`: DiaryEntry model representing escape room experiences
  - `escape_cafe.dart`: EscapeCafe and EscapeTheme models
  - `user.dart`: User and Friend models
- **screens/**: UI screens for different app functions
  - `diary_list_screen.dart`: Main list view of diary entries
  - `diary_detail_screen.dart`: Detailed view of individual entries
  - `write_diary_screen.dart`: Form for creating new entries
  - `edit_diary_screen.dart`: Form for editing existing entries

### State Management

- Uses StatefulWidget at the app level (MyApp) to manage the global list of diary entries
- Callback functions (onAdd, onUpdate) are passed down to child widgets for state updates
- No external state management library is used

### Data Flow

- DiaryEntry objects are created with mock data structure including cafe, theme, friends, ratings, and game results
- Navigation between screens uses Navigator.push with MaterialPageRoute
- Data is passed between screens through constructor parameters and return values

### Key Models Relationships

- DiaryEntry contains an EscapeTheme
- EscapeTheme belongs to an EscapeCafe
- DiaryEntry can have multiple Friend objects
- Friend objects contain User information

## Supabase Integration (구현 완료 - 2025-08-07)

### 데이터베이스 구조
- **완전한 PostgreSQL 스키마 구축 완료**
- **모든 테이블 생성 및 RLS 정책 적용**
- **자동 타임스탬프 트리거 설정**

#### 테이블 목록 (업데이트: 2025-08-24)
- `profiles` - 사용자 프로필 (auth.users와 연결) + **user_code (6자리 영숫자, UNIQUE)** ✅
- `escape_cafes` - 방탈출 카페 정보 (공통 데이터)
- `escape_themes` - 방탈출 테마 정보 (공통 데이터)  
- `friends` - 친구 관리 (개인 데이터)
- `diary_entries` - 일지 엔트리 (개인 데이터, ID: SERIAL INTEGER) ✅
- `diary_entry_participants` - 일지-참여자 관계 테이블 ✅ 개선

### OAuth 인증 시스템 (업데이트: 2025-08-19)
- **Google Sign-In 플러그인 기반 구현 완료** ✅
- **크로스 플랫폼 호환성** - 웹(OAuth) + 모바일(네이티브) 지원
- **실시간 인증 상태 관리**
- **자동 프로필 생성 및 동기화**

#### 주요 컴포넌트
- `AuthService` - 중앙 인증 관리 클래스
  - **Google Sign-In 플러그인** 사용 (모바일 네이티브 UI)
  - Supabase OAuth 백업 (웹 브라우저)
  - ID 토큰 기반 Supabase 인증 연동
  - 사용자 상태 추적 + 프로필 자동 생성
  - 개선된 로그아웃 처리 (Google + Supabase 세션 정리)
- `SettingsScreen` - **실시간 상태 반영** OAuth UI
  - **StatefulWidget으로 변경** - 로그인 상태 실시간 업데이트
  - 회원/비회원 동적 인터페이스
  - 즉시 피드백 로그인/로그아웃 플로우

### 설정 및 구성
#### 환경변수 및 설정 파일 (업데이트: 2025-08-19)
- `.env` - 환경변수
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY` - Supabase 연결
  - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` - 웹 OAuth용
  - **`GOOGLE_SERVER_CLIENT_ID`** - 모바일 네이티브 로그인용 (신규)
- `lib/utils/supabase.dart` - 클라이언트 접근 유틸리티
- `.mcp.json` - MCP 서버 설정 (선택적)

#### 패키지 의존성
```yaml
dependencies:
  supabase_flutter: ^2.8.0   # Supabase 클라이언트
  google_sign_in: ^6.2.1     # Google OAuth
  hive_flutter: ^1.1.0       # 로컬 저장소
  url_launcher: ^6.3.1       # 외부 링크
  flutter_dotenv: ^5.1.0     # 환경변수 관리
  image_picker: ^1.0.7       # 갤러리/카메라 이미지 선택
  path: ^1.9.0               # 파일 경로 처리 유틸리티
```

### 현재 작동하는 기능 (업데이트: 2025-08-27)
1. **Google Sign-In 네이티브 로그인** - 모바일 최적화된 UX ✅
2. **실시간 인증 상태 관리** - 설정화면 즉시 업데이트 ✅  
3. **프로필 이미지 업로드** - 갤러리/카메라 → Supabase Storage ✅
4. **프로필 편집** - 이름 변경, 이미지 교체, 실시간 반영 ✅
5. **개선된 로그아웃** - Google/Supabase 세션 완전 정리 ✅
6. **데이터베이스 연결** - RLS 보안 정책 적용
7. **방탈출 테마 DB 연동** - 지연 로딩 방식 구현
8. **카페/테마 자동완성** - Supabase 실시간 데이터
9. **JSON 직렬화** - 모든 모델 클래스 완성
10. **일지 작성/조회** - 완전한 CRUD 구현 ✅
11. **참여자 시스템** - 작성자 + 친구들 자동 관리 ✅
12. **친구 정보 실시간 반영** - 친구 정보 변경 시 모든 일지에 반영 ✅
13. **UI 친구 표시** - 메인화면, 일지리스트에서 참여자 표시 ✅
14. **본인 제외 통계** - 친구 수/랭킹에서 자기 자신 제외 ✅
15. **사용자 코드 시스템** - 6자리 코드 기반 친구 연동 ✅
16. **인피니트 스크롤** - 일지 목록/친구 목록 20개 단위 페이징 ✅
17. **검색 및 필터링** - 테마/카페명 검색, 친구 다중 선택 필터 ✅
18. **개인 일지 시스템** - 참여자 기반에서 개인 일지로 단순화 ✅
19. **테마 검색 UX 완성** - 실시간 옵션 표시, 선택 상태 완벽 동작 ✅
20. **친구 관리 UX 완성** - 길게 누르기 컨텍스트 메뉴, 통합 친구 추가 ✅
21. **지도 느낌 테마** - 노랑+연황토 색상 테마 적용 ✅

### 최근 구현 완료

#### 🚀 2025-08-27 최신 업데이트 (친구 관리 UX 완성 + 테마 변경)
- **🎨 지도 테마 적용**:
  - **컬러 팔레트**: 연보라색 → 지도 느낌의 노랑+연황토 색상으로 완전 변경
  - **메인 컬러**: 밝은 노랑 (`#F4D03F`) + 오렌지-노랑 (`#F39C12`)
  - **배경 시스템**: 연한 베이지 (`#FDF2E9`) 배경 + 크림색 서페이스
  - **AppBar 테마**: 노랑색 배경에 갈색 텍스트로 지도 느낌 강화
- **👥 친구 관리 UX 완성**:
  - **인피니트 스크롤**: 친구 목록 20개 단위 페이징 + 실시간 검색 (500ms 디바운싱)
  - **길게 누르기 메뉴**: 드롭다운 버튼 → 컨텍스트 메뉴로 UX 개선
  - **전체 카드 터치**: `HitTestBehavior.opaque`로 카드 전체 영역 터치 가능
  - **통합 친구 추가**: 두 개 팝업 → 하나의 다이얼로그로 단순화
  - **인라인 에러 표시**: SnackBar z-index 문제 → 입력 필드 하단 에러 텍스트로 개선
- **⚙️ 일지 작성 UX 개선**:
  - **기본값 설정**: 탈출 결과 기본값을 "성공"으로 변경
  - **날짜 선택 UI**: "날짜 선택" 버튼 → 달력 아이콘이 있는 세련된 카드 형태
  - **버튼 스타일**: "자세히" 버튼을 OutlinedButton → TextButton으로 변경하여 깔끔함 증대

#### 🚀 2025-08-25 최신 업데이트 (테마 검색 UX 개선)
- **🔍 테마 검색 옵션 리스트 표시 개선**:
  - **실시간 옵션 표시**: 검색 완료 시 드롭다운이 즉시 표시되도록 수정
  - **UI 갱신 보장**: `List.from()` + 텍스트 컨트롤러 미세 조정으로 강제 UI 업데이트
  - **검색 결과 반영**: "ea" 검색 시 19개 결과가 바로 표시되도록 개선
- **🎯 테마 선택 완료 상태 수정**:
  - **선택 상태 유지**: 테마 검색 후 선택 시 `selectedTheme` 상태가 올바르게 유지
  - **카페 자동 선택**: 테마 선택 시 해당 카페 자동 설정 + 체크 아이콘 표시
  - **스마트 테마 로딩**: `_loadThemesForCafeWithoutClearingSelection()` 메서드로 선택된 테마를 초기화하지 않고 카페 테마 목록만 업데이트
  - **저장 기능 정상화**: "모든 항목을 선택해주세요" 에러 해결

#### 🚀 2025-08-24 주요 업데이트 (사용자 코드 시스템)
- **🔢 6자리 사용자 코드**: 각 사용자에게 고유한 영숫자 코드 자동 생성
  - **PostgreSQL 함수**: `generate_unique_user_code()` - 중복 방지 코드 생성
  - **자동 할당**: 신규 사용자 가입 시 트리거로 자동 코드 생성
  - **인덱스 최적화**: `user_code` 컬럼에 인덱스 추가로 빠른 검색
- **👥 친구 연동 시스템**: 
  - **코드 기반 친구 추가**: 6자리 코드로 실제 사용자와 연결
  - **기존 친구 연동**: 직접 입력한 친구를 나중에 코드로 연결 가능
  - **중복 방지**: 자기 자신 추가, 기존 친구 중복 추가 방지
- **🎨 UI/UX 개선**:
  - **프로필 이미지 표시**: 연동된 친구는 실제 프로필 이미지 표시
  - **연동 상태 구분**: 미연동 친구만 `link_off` 아이콘 표시
  - **친구 추가 플로우**: 코드 입력 vs 직접 입력 선택지 제공
  - **코드 관리**: 프로필 편집 페이지에서 내 코드 확인 및 복사
- **⚡ 사용자 친화적 에러 처리**: 
  - **명확한 메시지**: "코드가 올바르지 않아요" 등 이해하기 쉬운 안내
  - **자동 팝업 닫기**: 에러 발생 시 다이얼로그 자동 종료

#### 🚀 2025-08-24 주요 업데이트 (UI 컴포넌트 및 UX 개선)
- **📱 인피니트 스크롤**: 일지 목록 10개 단위 페이징으로 성능 최적화
- **🔍 검색 및 필터 시스템**: 
  - **실시간 검색**: 테마명/카페명 500ms 딜레이 검색
  - **친구 다중 필터**: 칩 형태 다중 선택, 교집합 필터링
  - **토글 필터 영역**: 애니메이션 적용된 필터 표시/숨김
- **🧩 재사용 컴포넌트**: `DiaryEntryCard` 위젯으로 코드 중복 제거
- **📊 개인 일지 시스템**: 복잡한 참여자 기반 → 단순한 개인 일지 조회로 변경
  - **성능 개선**: `WHERE user_id = currentUserId` 단순 쿼리
  - **participants 테이블 유지**: 친구 정보 저장용으로 활용

#### 🚀 2025-08-19 주요 업데이트 (프로필 이미지 업로드 시스템)
- **📷 Supabase Storage 연동**: avatars 버킷 + RLS 보안 정책
  - **5MB 이미지 제한**: JPEG, PNG, WebP 지원
  - **사용자별 폴더**: `/avatars/{user_id}/profile_image.jpg` 구조
  - **자동 덮어쓰기**: 기존 이미지 자동 교체
- **🎨 프로필 편집 화면**: 갤러리/카메라 이미지 선택
  - **실시간 프리뷰**: 선택한 이미지 즉시 미리보기
  - **표시 이름 변경**: 2-20자 제한, 폼 검증
  - **Android 권한**: 카메라, 갤러리 접근 권한 추가
- **⚡ 실시간 반영**: 프로필 변경 시 홈화면/설정화면 즉시 업데이트
  - **설정 화면 연동**: 프로필 탭하면 편집 화면 이동
  - **ProfileService**: 이미지 업로드 + 프로필 업데이트 중앙 관리

#### 🚀 2025-08-19 주요 업데이트 (Google Sign-In 네이티브 구현)
- **🔐 Google Sign-In 플러그인 전환**: Supabase OAuth → google_sign_in 플러그인
  - **모바일 네이티브 UI**: 브라우저 리다이렉트 없는 매끄러운 로그인
  - **크로스 플랫폼**: 웹은 기존 OAuth 유지, 모바일은 네이티브 사용
  - **ID 토큰 연동**: Google 인증 → Supabase `signInWithIdToken` 변환
- **⚡ 실시간 설정 화면**: `StatelessWidget` → `StatefulWidget`
  - **즉시 UI 업데이트**: 로그인 완료 시 버튼이 실시간으로 변경
  - **인증 스트림 리스닝**: AuthService 상태 변화 자동 감지
- **🔧 개선된 로그아웃**: Google Sign-In + Supabase 세션 완전 정리
  - **에러 핸들링**: disconnect 실패 시에도 로그아웃 진행
  - **선택적 처리**: 각 단계별 독립적 에러 처리
- **📊 본인 제외 통계 시스템**: 홈화면 친구 통계에서 자기 자신 제외
  - **정확한 친구 수**: "N명의 친구들과" 메시지에서 본인 제외
  - **랭킹 정화**: "가장 많이 함께한 친구" 목록에서 본인 제거
  - **동적 필터링**: userProfile 기반 실시간 본인 식별

#### 🚀 2025-08-14 주요 업데이트 (참여자 시스템 대폭 개선)
- **🔄 데이터베이스 구조 개선**: 
  - `diary_entries.id`: UUID → SERIAL INTEGER (성능 최적화)
  - `diary_entry_friends` → `diary_entry_participants` (의미 명확화)
  - nullable `user_id` + `friend_id` 추가 (모든 친구 유형 지원)
- **👥 참여자 자동 관리**: 일지 작성 시 본인 + 선택된 친구들 자동 포함
- **🔗 실시간 정보 반영**: 친구 정보 변경 시 모든 기존 일지에 자동 반영
- **🎨 UI 개선**: 메인화면 "최근 진행한 테마"에도 친구 정보 표시
- **✅ 완전한 통합**: 모든 화면에서 일관된 친구 표시 방식

#### 🚀 2025-08-21 UX 개선 업데이트
- **🔒 비회원 접근 제어 시스템**: 메인화면 "더보기" 버튼 로그인 요구 메시지
  - **최근 진행한 테마 더보기**: 비회원 클릭 시 "일지 목록을 보려면 로그인이 필요합니다" 표시
  - **가장 많이 함께한 친구들 더보기**: 기존 구현 유지 "친구 기능을 사용하려면 로그인이 필요합니다"
  - **일관된 UX**: 모든 로그인 요구 메시지에 orange SnackBar 사용

#### 📋 2025-08-13 구현 완료
- **🔄 지연 로딩**: 카페 선택 시에만 테마 로드 (성능 최적화)
- **🎯 자동 포커스**: 테마 로딩 완료 시 자동으로 옵션박스 표시
- **🛠️ Nullable 안전성**: difficulty 등 DB 필드 nullable 처리
- **⚡ 실시간 데이터**: 하드코딩 제거, 완전 DB 기반
- **🔧 프로필 자동 생성**: 로그인 시 profiles 테이블 자동 생성/업데이트

## Development Notes

### Language and Framework

- Flutter SDK version: ^3.7.2
- Uses Material 3 design system
- Korean language used for UI strings ("탈출일지" means "Escape Diary")

### Testing

- Test files are located in the `test/` directory
- Uses flutter_test framework
- Run tests with `flutter test`

### Code Style

- Uses flutter_lints for code analysis
- Analysis rules defined in analysis_options.yaml
- Follows standard Flutter/Dart conventions
- 모델이 추가되는 경우, data_models.md 에 추가할 것. 해당 파일은 Flutter 모델 + Supabase 테이블을 관리

## 중요 프로젝트 파일들

### 스키마 및 설계
- `lib/models/data_models.md` - **완전한 데이터베이스 스키마 명세** (SQL 포함)
- `lib/models/diary.dart` - DiaryEntry 모델 (JSON 직렬화 + copyWith 구현 완료)
- `lib/models/escape_cafe.dart` - EscapeCafe, EscapeTheme 모델 
- `lib/models/user.dart` - User, Friend 모델

### 핵심 로직 (업데이트: 2025-08-24)
- `lib/services/auth_service.dart` - **Google Sign-In 플러그인 인증** (네이티브 + 웹 하이브리드)
  - 모바일: google_sign_in 플러그인 → ID토큰 → Supabase 인증
  - 웹: 기존 Supabase OAuth 유지 
  - 개선된 로그아웃 (단계별 에러 핸들링)
- `lib/services/database_service.dart` - **사용자 코드 시스템** + 친구 연동 로직
  - **사용자 코드 관리**: `getMyUserCode()`, `findUserByCode()`, `addFriendByCode()`
  - **친구 연동**: `linkFriendWithCode()` - 기존 친구를 실제 사용자와 연결
  - **개인 일지 조회**: `getMyDiaryEntries()` - 단순화된 쿼리
- `lib/services/profile_service.dart` - **프로필 이미지 업로드**
  - Supabase Storage 연동 (avatars 버킷)
  - 이미지 업로드/삭제, 프로필 정보 업데이트
- `lib/services/escape_room_service.dart` - **Supabase 데이터 조회** (카페/테마 지연 로딩)
- `lib/main.dart` - 앱 진입점 + 전역 상태 관리 + 인증 상태 추적
- `lib/screens/auth/settings_screen.dart` - **단순화된 설정 페이지**
  - 친구 코드/로그아웃 기능 → 프로필 편집으로 이동
- `lib/screens/auth/profile_edit_screen.dart` - **프로필 편집** + 친구 코드 관리 + 로그아웃
  - 갤러리/카메라 이미지 선택, 표시 이름 변경
  - **친구 코드 카드**: 6자리 코드 표시 및 복사 기능
  - **로그아웃 버튼**: 오른쪽 정렬, 빨간색 작은 글씨
- `lib/screens/friends/friends_screen.dart` - **친구 관리** + 코드 기반 연동
  - **코드 기반 친구 추가**: 선택지 제공 (코드 vs 직접입력)
  - **기존 친구 연동**: 팝업 메뉴에 "코드 등록" 옵션
  - **연동 상태 UI**: 프로필 이미지 vs 미연동 아이콘
- `lib/screens/main/home_screen.dart` - **홈 화면** (연동 친구 프로필 이미지 표시)
- `lib/screens/diary/diary_list_infinite_screen.dart` - **인피니트 스크롤** + 검색/필터
- `lib/screens/diary/write_diary_screen.dart` - **일지 작성** + 개선된 테마 검색 UX
- `lib/widgets/diary_entry_card.dart` - **재사용 일지 카드 컴포넌트**

### 환경변수 및 설정
- `.env` - Supabase 환경변수 (URL, API 키 등)
- `lib/utils/supabase.dart` - 클라이언트 접근 헬퍼
- `.mcp.json` - MCP Supabase 서버 설정 (선택적)

## 🚀 최신 구현 완료 사항 (2025-08-14)

### ⚡ 참여자 중심 일지 시스템 완성

#### 🔄 데이터베이스 아키텍처 개선
1. **Nullable 참여자 시스템**: `diary_entry_participants.user_id` nullable로 변경하여 연결/비연결 친구 모두 지원
2. **자동 작성자 참여**: 일지 작성 시 본인도 자동으로 참여자에 포함
3. **참여자 기준 조회**: `getMyDiaryEntries()`가 "내가 참여한 모든 일지" 조회로 변경 (작성 + 참여)
4. **완전한 JSON 직렬화**: DiaryEntry 모델에 `fromJson/toJson/copyWith` 메서드 구현

#### 🗑️ 스마트 삭제 시스템
- **작성자 삭제**: 일지 완전 삭제 (모든 참여자에게서 사라짐)
- **참여자 나가기**: 자신만 참여자 목록에서 제거 (일지는 유지됨)
- **동적 UI**: 사용자 역할에 따라 "삭제"/"나가기" 버튼과 메시지 자동 변경
- **확인 다이얼로그**: 역할별 맞춤 경고 메시지 표시

#### 📊 홈 화면 UX 개선
1. **친구 통계 중복 제거**: 같은 사람이 여러 번 나오던 문제 해결
2. **사회적 메시지 강화**: "총 N개 테마를 M명의 친구들과 진행" 메시지 추가
3. **실시간 친구 표시**: 메인 화면 "최근 진행한 테마"에도 친구 정보 표시

#### 🔐 UX 보안 개선
- **로그인 체크**: 일지 작성, 친구 추가 시 사전 로그인 확인
- **즉시 피드백**: 비회원이 기능 접근 시 즉시 안내 메시지 표시

#### 🎯 데이터 동기화 완성
- **실시간 반영**: 일지 작성 후 친구 정보가 즉시 목록에 표시
- **참여자 정보 자동 로드**: DB 저장 시 완전한 DiaryEntry 객체 반환
- **상태 전파**: 삭제/수정 결과가 모든 관련 화면에 자동 반영

### 🎨 현재 완전히 작동하는 기능들 (업데이트: 2025-08-19)
1. **Google Sign-In 네이티브 로그인** - 모바일 최적화된 UX
2. **프로필 이미지 업로드** - 갤러리/카메라 → Supabase Storage
3. **프로필 편집** - 이름 변경, 이미지 교체, 실시간 반영
4. **실시간 설정 화면** - 로그인/로그아웃 상태 즉시 반영
5. **친구 관리** - 추가/수정/삭제 + 연결/비연결 지원
6. **일지 작성/수정** - DB 저장 + 참여자 자동 관리
7. **스마트 삭제** - 작성자/참여자별 차별화 처리
8. **본인 제외 통계** - 정확한 친구 수 및 랭킹 표시
9. **참여자 중심 조회** - 내가 관련된 모든 일지 표시
10. **실시간 UI 업데이트** - 모든 변경사항 즉시 반영
11. **크로스 플랫폼 인증** - 웹/모바일 최적화된 로그인 방식

### 🔧 주요 기술적 성취 (업데이트: 2025-08-21)
- **Supabase Storage 통합**: RLS 기반 안전한 이미지 업로드 시스템
- **멀티미디어 처리**: image_picker + 압축 최적화 (512px, 80% 품질)
- **하이브리드 인증 아키텍처**: 플랫폼별 최적화된 Google 로그인 구현
- **실시간 상태 동기화**: Stream 기반 UI 자동 업데이트 시스템
- **관계형 데이터 모델링**: nullable 제약조건으로 유연한 참여자 시스템 구현
- **상태 관리 최적화**: 콜백 체인을 통한 효율적인 상태 전파
- **사용자 중심 UX**: 역할 기반 동적 인터페이스 구현
- **데이터 정합성**: 자동 작성자 포함 + 중복 제거 + 본인 제외 로직
- **에러 처리 강화**: 단계별 독립적 에러 핸들링으로 견고한 로그아웃
- **비회원 접근 제어**: 메인화면 더보기 버튼 로그인 요구 메시지 시스템

# Do Not Section

- 주석을 칠땐, 최상단 import 에는 설명용 주석을 할 필요 없음
