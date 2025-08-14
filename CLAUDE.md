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

#### 테이블 목록 (업데이트: 2025-08-14)
- `profiles` - 사용자 프로필 (auth.users와 연결)
- `escape_cafes` - 방탈출 카페 정보 (공통 데이터)
- `escape_themes` - 방탈출 테마 정보 (공통 데이터)  
- `friends` - 친구 관리 (개인 데이터)
- `diary_entries` - 일지 엔트리 (개인 데이터, ID: SERIAL INTEGER) ✅
- `diary_entry_participants` - 일지-참여자 관계 테이블 ✅ 개선

### OAuth 인증 시스템
- **Google OAuth 2.0 구현 완료**
- **실시간 인증 상태 관리**
- **자동 프로필 생성 및 동기화**

#### 주요 컴포넌트
- `AuthService` - 중앙 인증 관리 클래스
  - Google 로그인/로그아웃
  - 사용자 상태 추적
  - 프로필 자동 생성
- `SettingsScreen` - OAuth 연동 UI
  - 회원/비회원 동적 인터페이스
  - 로그인/로그아웃 플로우

### 설정 및 구성
#### 환경변수 및 설정 파일
- `.env` - 환경변수 (SUPABASE_URL, SUPABASE_ANON_KEY 등)
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
```

### 현재 작동하는 기능 (업데이트: 2025-08-14)
1. **OAuth 로그인/로그아웃** - 완전 구현
2. **사용자 프로필 관리** - 자동 생성/동기화 (UPSERT 방식)
3. **설정 페이지** - 인증 상태별 동적 UI
4. **데이터베이스 연결** - RLS 보안 정책 적용
5. **실시간 상태 관리** - 인증 변경 감지
6. **방탈출 테마 DB 연동** - 지연 로딩 방식 구현
7. **카페/테마 자동완성** - Supabase 실시간 데이터
8. **JSON 직렬화** - 모든 모델 클래스 완성
9. **일지 작성/조회** - 완전한 CRUD 구현 ✅
10. **참여자 시스템** - 작성자 + 친구들 자동 관리 ✅
11. **친구 정보 실시간 반영** - 친구 정보 변경 시 모든 일지에 반영 ✅
12. **UI 친구 표시** - 메인화면, 일지리스트에서 참여자 표시 ✅

### 최근 구현 완료

#### 🚀 2025-08-14 주요 업데이트 (참여자 시스템 대폭 개선)
- **🔄 데이터베이스 구조 개선**: 
  - `diary_entries.id`: UUID → SERIAL INTEGER (성능 최적화)
  - `diary_entry_friends` → `diary_entry_participants` (의미 명확화)
  - nullable `user_id` + `friend_id` 추가 (모든 친구 유형 지원)
- **👥 참여자 자동 관리**: 일지 작성 시 본인 + 선택된 친구들 자동 포함
- **🔗 실시간 정보 반영**: 친구 정보 변경 시 모든 기존 일지에 자동 반영
- **🎨 UI 개선**: 메인화면 "최근 진행한 테마"에도 친구 정보 표시
- **✅ 완전한 통합**: 모든 화면에서 일관된 친구 표시 방식

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

### 핵심 로직
- `lib/services/auth_service.dart` - **OAuth 인증 중앙 관리** (Google + 프로필 자동 생성)
- `lib/services/database_service.dart` - **완전한 CRUD 시스템** (일지, 친구, 참여자 관리)
- `lib/services/escape_room_service.dart` - **Supabase 데이터 조회** (카페/테마 지연 로딩)
- `lib/main.dart` - 앱 진입점 + 전역 상태 관리 + 인증 상태 추적
- `lib/screens/settings_screen.dart` - 설정 페이지 (OAuth UI 포함)
- `lib/screens/write_diary_screen.dart` - **DB 기반 일지 작성** (지연 로딩)
- `lib/screens/edit_diary_screen.dart` - **스마트 삭제 시스템** (작성자/참여자별 분기)
- `lib/screens/home_screen.dart` - **개선된 통계 표시** (친구 중복 제거)

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

### 🎨 현재 완전히 작동하는 기능들
1. **OAuth 로그인/로그아웃** - Google 연동 완성
2. **친구 관리** - 추가/수정/삭제 + 연결/비연결 지원
3. **일지 작성/수정** - DB 저장 + 참여자 자동 관리
4. **스마트 삭제** - 작성자/참여자별 차별화 처리
5. **통계 표시** - 중복 제거된 정확한 친구 랭킹
6. **참여자 중심 조회** - 내가 관련된 모든 일지 표시
7. **실시간 UI 업데이트** - 모든 변경사항 즉시 반영

### 🔧 주요 기술적 성취
- **관계형 데이터 모델링**: nullable 제약조건으로 유연한 참여자 시스템 구현
- **상태 관리 최적화**: 콜백 체인을 통한 효율적인 상태 전파
- **사용자 중심 UX**: 역할 기반 동적 인터페이스 구현
- **데이터 정합성**: 자동 작성자 포함 + 중복 제거 로직

# Do Not Section

- 주석을 칠땐, 최상단 import 에는 설명용 주석을 할 필요 없음
