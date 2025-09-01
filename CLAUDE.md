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
  connectivity_plus: ^6.0.5  # 네트워크 연결 상태 모니터링
```

### 현재 작동하는 기능 (업데이트: 2025-01-02)
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
22. **네트워크 연결 관리** - 오프라인 모드 안내, 실시간 연결 상태 모니터링 ✅
23. **사용자 친화적 에러 처리** - 지능형 에러 인식 및 맞춤 메시지 제공 ✅
24. **Skeleton UI 로딩** - 페이지별 최적화된 로딩 스켈레톤 적용 ✅
25. **완전한 비회원 시스템** - Hive 로컬 저장소 기반 오프라인 일지 작성/조회 ✅
26. **자동 데이터 마이그레이션** - 로그인 시 로컬 데이터 클라우드 이전 안내 ✅
27. **비회원 친구 시스템** - 로컬 저장소 기반 친구 관리 (추가/수정/삭제) ✅
28. **칭호 진행 시스템** - 방탈 횟수 기반 칭호 레벨 및 진행 상황 표시 ✅
29. **팀 통계 분석** - 평균 팀 크기, 솔로/팀 비율, 팀 크기별 분포 ✅

### 최근 구현 완료

#### 🚀 2025-09-02 최신 업데이트 (비회원 친구 시스템 + 게임화 요소)
- **👥 완전한 비회원 친구 시스템**:
  - **로컬 친구 관리**: Hive를 사용한 친구 추가/수정/삭제
  - **FriendService 통합**: 회원/비회원 자동 구분 서비스 계층
  - **일지-친구 연동**: 비회원도 일지에 친구 정보 저장 가능
  - **JSON 직렬화**: DiaryEntry의 friends 필드 완전 지원
- **🎮 게임화 요소 추가**:
  - **칭호 시스템**: 방탈 횟수 기반 5단계 칭호 (방알못→방린이→방청년→고인물→썩은물)
  - **진행 상황 표시**: 현재 칭호 진행률 및 다음 목표까지 남은 횟수
  - **팀 통계 분석**: 평균 팀 크기, 솔로vs팀 비율, 팀 크기별 분포 차트
  - **인터랙티브 카드**: 메인 화면 카드 탭으로 상세 정보 팝업
- **🔧 기술적 개선**:
  - **중복 저장 버그 수정**: main.dart의 addFriend 콜백 로직 정리
  - **UI 즉시 업데이트**: _refreshFriendsList() 복구로 실시간 반영
  - **칭호별 아이콘 통일**: TitleProgressDialog와 메인 화면 동기화

#### 🚀 2025-08-31 이전 업데이트 (비회원 시스템 + 마이그레이션)
- **📱 완전한 비회원 사용자 기능**:
  - **Hive 로컬 저장소**: 비회원도 일지 작성/저장/조회 가능
  - **오프라인 데이터 관리**: 로컬 ID 시스템 (음수 ID로 구분)
  - **상태 기반 UI**: 로그인 여부에 따른 데이터 소스 자동 전환 (DB vs 로컬)
- **🔄 자동 데이터 마이그레이션 시스템**:
  - **LoginDialog 연동**: 친구목록 더보기 등에서 로그인 시 마이그레이션 팝업 자동 표시
  - **main.dart 상태 관리**: AuthService 상태 변화 감지하여 MaterialLocalizations 에러 해결
  - **플래그 기반 처리**: `_shouldShowMigrationDialog` 플래그로 HomeScreen에서 안전한 다이얼로그 표시
  - **사용자 친화적 UI**: "일지 가져오기" 제목으로 개발자 용어 제거
- **🎯 UX 개선**:
  - **페이지 이동 방지**: 로그인 팝업에서 로그인해도 메인 페이지에 그대로 유지
  - **실시간 마이그레이션 안내**: 로그인 즉시 로컬 데이터 존재 시 안내 팝업
  - **진행률 표시**: 마이그레이션 중 로딩 오버레이 + 상세 진행 메시지
- **🏗️ 아키텍처 개선**:
  - **HomeScreen StatefulWidget 전환**: 마이그레이션 다이얼로그 상태 관리
  - **MaterialLocalizations 호환**: main.dart에서 직접 showDialog 호출 방지
  - **디버깅 로그 강화**: 마이그레이션 과정 각 단계별 상세 로그

#### 🚀 2025-08-27 이전 업데이트 (에러 처리 및 로딩 UX 개선)
- **🌐 네트워크 연결 관리 시스템**:
  - **ConnectivityService**: `connectivity_plus` 패키지 활용한 실시간 네트워크 모니터링
  - **OfflineBanner**: 연결 끊김 시 상단 애니메이션 배너 + 재시도 기능
  - **오프라인 기능 안내**: 사용 가능/불가능 기능 목록 제공
  - **주기적 연결 테스트**: 30초마다 Supabase 연결 상태 확인
- **🛠️ 사용자 친화적 에러 메시지 표준화**:
  - **ErrorService**: 50+ 에러 패턴 자동 인식 및 사용자 친화적 메시지 변환
  - **커스텀 예외 클래스**: `FriendNotFoundException`, `ValidationException` 등 세분화
  - **통합 에러 UI**: 일관된 아이콘, 색상, 액션 버튼을 가진 다이얼로그/SnackBar
  - **지능형 에러 분류**: 에러 타입별 맞춤 아이콘 및 해결 방법 제시
- **⚡ 로딩 상태 개선 (Skeleton UI)**:
  - **페이지별 맞춤 스켈레톤**: 8가지 화면 구조에 최적화된 로딩 UI
    - `HomeScreenSkeleton`: 통계 카드 + 일지 리스트 구조
    - `FriendsListSkeleton`: 친구 카드 목록 스켈레톤
    - `DiaryCardSkeleton`: 일지 카드 레이아웃 모방
    - `LoadingOverlay`: 전체 화면 반투명 로딩 오버레이
  - **부드러운 애니메이션**: 0.3~1.0 opacity 페이드 효과 (1.2초 주기)
  - **실제 적용**: 친구 목록, 일지 작성 저장 등에 적용 완료

#### 🚀 2025-08-27 이전 업데이트 (친구 관리 UX 완성 + 테마 변경)
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

### 핵심 로직 (업데이트: 2025-09-02)
- `lib/services/auth_service.dart` - **Google Sign-In 플러그인 인증** (네이티브 + 웹 하이브리드)
  - 모바일: google_sign_in 플러그인 → ID토큰 → Supabase 인증
  - 웹: 기존 Supabase OAuth 유지 
  - 개선된 로그아웃 (단계별 에러 핸들링)
- `lib/services/database_service.dart` - **사용자 코드 시스템** + 친구 연동 + **마이그레이션 로직**
  - **사용자 코드 관리**: `getMyUserCode()`, `findUserByCode()`, `addFriendByCode()`
  - **친구 연동**: `linkFriendWithCode()` - 기존 친구를 실제 사용자와 연결
  - **개인 일지 조회**: `getMyDiaryEntries()` - 단순화된 쿼리
  - **데이터 마이그레이션**: `migrateLocalDataToDatabase()` - 로컬 데이터를 DB로 이전
- `lib/services/local_storage_service.dart` - **Hive 로컬 저장소 관리**
  - **비회원 일지 데이터**: 로컬 일지 저장/조회/수정/삭제
  - **비회원 친구 데이터**: 로컬 친구 저장/조회/수정/삭제
  - **32비트 ID 제한 대응**: Hive 키 범위 내에서 안전한 ID 생성
  - **마이그레이션 지원**: 로컬 데이터 통계 및 DB 이전 준비
- `lib/services/friend_service.dart` - **통합 친구 관리 서비스** (신규)
  - **회원/비회원 자동 구분**: 로그인 상태에 따라 DB vs 로컬 자동 선택
  - **일관된 API**: addFriend, updateFriend, deleteFriend, getFriends
  - **페이징 지원**: getFriendsPaginated (검색 포함)
  - **코드 연동**: addFriendByCode, linkFriendWithCode
- `lib/services/profile_service.dart` - **프로필 이미지 업로드**
  - Supabase Storage 연동 (avatars 버킷)
  - 이미지 업로드/삭제, 프로필 정보 업데이트
- `lib/services/escape_room_service.dart` - **Supabase 데이터 조회** (카페/테마 지연 로딩)
- `lib/services/connectivity_service.dart` - **네트워크 연결 모니터링** + 오프라인 기능 관리
- `lib/services/error_service.dart` - **사용자 친화적 에러 처리** + 커스텀 예외 클래스
- `lib/main.dart` - 앱 진입점 + 전역 상태 관리 + 인증 상태 추적 + **마이그레이션 팝업 트리거**
  - **비회원/회원 데이터 전환**: 로그인 시 로컬 → DB 데이터 자동 전환
  - **AuthService 리스너**: 상태 변화 감지하여 마이그레이션 플래그 설정
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
- `lib/screens/main/home_screen.dart` - **홈 화면** (StatefulWidget) + **마이그레이션 다이얼로그 처리**
  - **연동 친구 프로필 이미지 표시**: 실제 사용자 프로필 이미지 연동
  - **마이그레이션 플래그 감지**: main.dart에서 설정한 플래그 기반 다이얼로그 표시
  - **MaterialLocalizations 호환**: 안전한 showDialog 호출 환경 제공
- `lib/screens/diary/diary_list_infinite_screen.dart` - **인피니트 스크롤** + 검색/필터
- `lib/screens/diary/write_diary_screen.dart` - **일지 작성** + 개선된 테마 검색 UX + 로딩 오버레이
- `lib/widgets/diary_entry_card.dart` - **재사용 일지 카드 컴포넌트**
- `lib/widgets/offline_banner.dart` - **오프라인 상태 알림 배너** + 애니메이션
- `lib/widgets/skeleton_widgets.dart` - **페이지별 맞춤 스켈레톤 UI** (8가지 유형)
- `lib/widgets/migration_guide_dialog.dart` - **마이그레이션 안내 다이얼로그**
  - **사용자 친화적 UI**: "일지 가져오기" 제목으로 개발자 용어 제거
  - **로딩 오버레이**: 마이그레이션 진행 중 상태 표시
  - **결과 피드백**: 성공/실패 개수 및 에러 상세 정보 제공
- `lib/widgets/login_dialog.dart` - **로그인 안내 다이얼로그**
  - **기능 안내**: 로그인 시 사용 가능한 기능들 상세 설명
  - **Google 로그인 연동**: AuthService와 완전 통합
- `lib/widgets/title_progress_dialog.dart` - **칭호 진행 상황 다이얼로그** (신규)
  - **현재 칭호 표시**: 5단계 칭호별 아이콘, 색상, 진행률
  - **다음 목표 안내**: "???" 미스터리 표시 + 남은 횟수
  - **간소한 디자인**: 핵심 정보만 표시하는 깔끔한 UI
- `lib/widgets/team_stats_dialog.dart` - **팀 통계 다이얼로그** (신규)
  - **평균 팀 크기**: 함께 플레이하는 평균 인원 수 계산
  - **솔로/팀 비율**: 혼자 vs 친구와 함께 플레이 비율
  - **팀 크기별 분포**: 1명~N명 각각 몇 번 플레이했는지 막대 차트
  - **최다 표시**: 가장 자주 하는 팀 크기 강조

### 환경변수 및 설정
- `.env` - Supabase 환경변수 (URL, API 키 등)
- `lib/utils/supabase.dart` - 클라이언트 접근 헬퍼
- `.mcp.json` - MCP Supabase 서버 설정 (선택적)

## 🚀 이전 구현 완료 사항

### ✅ 2025-08-29 업데이트 (친구 상세페이지 UX 최적화 + 메모 공개 시스템)

#### 🎯 친구 상세페이지 성능 및 UX 개선
1. **테마 표시 최적화**: 
   - "함께한 테마" → "최근 함께한 테마"로 제목 변경
   - **최대 3개**만 표시하여 성능 개선 + 깔끔한 UI
   - 통계 카드는 "총 테마 수"로 전체 개수 표시
2. **"더 보기" 기능**: 
   - 3개 초과 시 TextButton.icon으로 "더 보기" 표시
   - 클릭 시 **일지 리스트로 해당 친구 필터 적용**하여 이동
   - `DiaryListInfiniteScreen`에 `initialSelectedFriends` 매개변수 추가
   - 필터는 적용되지만 **필터 영역은 접힌 상태**로 깔끔하게 시작

#### 🔒 일지 상세페이지 보안 강화  
1. **본인 클릭 방지**: 함께한 친구 목록에서 본인은 클릭 불가능
2. **시각적 구분**: 
   - 본인: 연한 오렌지 배경 + 테두리 + "나" 배지
   - 다른 친구: 기본 배경 + 화살표 아이콘
3. **성능 최적화**: 
   - `DatabaseService.getDiaryEntriesWithFriend()` 함수로 특정 친구와 함께한 모든 일지 조회
   - 로딩 다이얼로그 + 에러 처리로 사용자 경험 개선

#### 💭 메모 공개 시스템 (구현 후 제거)
1. **Phase 1**: `diary_entries.memo_public` 컬럼 추가 + UI 체크박스 ✅
2. **Phase 2**: 친구 후기 조회 함수 + 성능 최적화 인덱스 ✅  
3. **Phase 3**: 일지 상세페이지 친구 후기 카드 구현 ✅
4. **최종**: 개인정보 보호 우려로 **전체 기능 제거** - 메모 공개 설정만 유지

### ✅ 2025-08-29 이전 업데이트 (연관검색어 + UI 개선)

#### 🔍 연관검색어 시스템 구현
1. **데이터베이스 확장**: `escape_themes` 테이블에 `search_keywords` 컬럼 추가
   - PostgreSQL 인덱스로 검색 성능 최적화
   - 쉼표로 구분된 연관검색어 저장 (예: "아야코,ayako")
2. **검색 로직 개선**: `DatabaseService.searchThemes()` 메서드 업데이트
   - `OR` 쿼리로 테마명 + 연관검색어 동시 검색
   - `ILIKE` 사용으로 대소문자/띄어쓰기 무관 검색
3. **Flutter 모델 업데이트**: `EscapeTheme` 클래스에 `searchKeywords` 필드 추가
   - JSON 직렬화/역직렬화 지원

#### 🎨 UI 컴포넌트 통합 및 개선
1. **공통 입력 필드 시스템**: `lib/widgets/common_input_fields.dart` 생성
   - 5가지 입력 컴포넌트: TextField, TextArea, Dropdown, DateField, AutocompleteField
   - 일관된 56px 높이 (DateField는 64px) + 동적 높이 조정
   - 전체 앱에서 일관된 입력 필드 디자인
2. **스탬프 이미지 UI**: 성공/실패 상태를 시각적 스탬프로 표시
   - `assets/images/stamp_success.png`, `stamp_failed.png` 활용
   - Stack 위젯으로 색상 배경(연한 초록/빨강) + 투명 스탬프 이미지 레이어링
   - `DiaryEntryCard`, `FriendDetailScreen`에서 일관된 스탬프 디자인 적용
3. **메모 입력 위치 조정**: 일지 작성/수정 폼에서 메모를 가장 하단으로 이동
4. **친구 표시 개선**: 
   - 일지 카드의 친구 칩 → 아이콘 + 텍스트 한 줄로 변경
   - 적절한 들여쓰기로 깔끔한 정렬
   - 친구 상세페이지에서 미연동 아이콘을 이름 옆으로 이동

#### 🚧 진행 중인 작업
- **친구 필터 요약 표시**: 친구 화면에서 필터 숨김 시 요약 정보 표시 (일지목록과 동일한 패턴)
  - `_showFilters` 상태 변수 추가됨
  - AppBar에 필터 아이콘 추가됨  
  - `_buildFilterSummary()` 메서드 준비됨
  - 애니메이션 필터 영역 구현 필요

## 🚀 이전 구현 완료 사항 (2025-08-14)

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

### 🎨 현재 완전히 작동하는 기능들 (업데이트: 2025-08-29)
1. **Google Sign-In 네이티브 로그인** - 모바일 최적화된 UX
2. **프로필 이미지 업로드** - 갤러리/카메라 → Supabase Storage
3. **프로필 편집** - 이름 변경, 이미지 교체, 실시간 반영
4. **실시간 설정 화면** - 로그인/로그아웃 상태 즉시 반영
5. **친구 관리** - 추가/수정/삭제 + 연결/비연결 지원
6. **일지 작성/수정** - DB 저장 + 참여자 자동 관리 + 메모 공개 설정
7. **스마트 삭제** - 작성자/참여자별 차별화 처리
8. **본인 제외 통계** - 정확한 친구 수 및 랭킹 표시
9. **참여자 중심 조회** - 내가 관련된 모든 일지 표시
10. **실시간 UI 업데이트** - 모든 변경사항 즉시 반영
11. **크로스 플랫폼 인증** - 웹/모바일 최적화된 로그인 방식
12. **연관검색어 시스템** - 테마 검색 시 한글/영문 별명 검색 지원
13. **공통 UI 컴포넌트 시스템** - 일관된 56px 높이 입력 필드들
14. **스탬프 이미지 UI** - 성공/실패 상태를 스탬프로 표시 (투명 PNG + 색상 배경)
15. **친구 상세페이지 최적화** - 최근 함께한 테마 3개 제한 + "더 보기" 연동
16. **일지 상세페이지 보안** - 함께한 친구 중 본인 클릭 방지 + 시각적 구분
17. **친구별 일지 필터링** - 특정 친구와 함께한 모든 일지 조회 + 필터 연동

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

# TODO (향후 개선 사항)

## 📱 로컬 우선 + 클라우드 백업 아키텍처 전환
- **목표**: 모든 데이터를 로컬에 저장하고, 클라우드는 백업/동기화용으로만 사용
- **장점**: 
  - 즉시 로드 (네트워크 대기 없음)
  - 빠른 CRUD 작업
  - 완벽한 오프라인 지원
  - 향상된 사용자 경험
- **구현 방식**:
  1. Phase 1: 현재 시스템 유지 + 캐싱 강화
     - 회원도 첫 로드 시 로컬 캐시 우선 표시
     - 백그라운드에서 DB 동기화
  2. Phase 2: 완전한 로컬 우선 시스템
     - 동기화 로직 완전 구현
     - 충돌 해결 메커니즘
     - 멀티 디바이스 지원
- **고려사항**:
  - 동기화 큐 구현
  - 충돌 처리 로직
  - 네트워크 에러 복구

# Do Not Section

- 주석을 칠땐, 최상단 import 에는 설명용 주석을 할 필요 없음
