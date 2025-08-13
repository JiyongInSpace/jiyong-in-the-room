# 🏃‍♂️ 방탈출 일지 (Escape Room Diary)

> **"누구와 함께했는지"**에 중점을 둔 방탈출 기록 앱

## 📝 프로젝트 컨셉

다른 방탈출 기록 어플은 평점, 후기에 중점을 뒀다면, 이 앱은 **누구와 했는지**에 중점을 둡니다.  
(평점 기능은 후순위)

## 🔐 회원/비회원 전략

### 비회원도 핵심 기능 사용 가능
- **로컬 저장**: 앱 삭제 시 데이터 소실
- **사용 가능**: 일지 작성/수정/삭제, 개인 통계, 검색/필터링
- **제한 기능**: 친구 관련 모든 기능

### 회원 가입 시 추가 혜택
- **클라우드 저장**: 앱 삭제해도 데이터 보존 (Supabase)
- **친구 기능**: 친구 추가, 일지에 친구 추가, 친구 통계
- **데이터 동기화**: 로컬 데이터를 클라우드로 자동 마이그레이션

## 🎯 기능 개발 로드맵

### 🔥 높은 우선순위 [상]
- [ ] 사진 첨부 기능 (테마 사진, 인증샷)
- [x] oAuth 회원가입/로그인 (구글) ✅

### 🌟 중간 우선순위 [중]
- [ ] 검색 기능 (테마명, 카페명으로 검색)
- [ ] 필터링 (성공/실패, 별점별, 카페별, 날짜별)
- [ ] 정렬 옵션 (최신순, 별점순, 카페별)
- [ ] 친구와 기록 공유
- [ ] 리뷰/메모 개선 (태그 기능)
- [ ] 데이터 백업/복원 기능

### 💡 낮은 우선순위 [하]
- [ ] 탈출 성공률 표시 (전체 대비 성공한 테마 비율)
- [ ] 평균 별점 표시
- [ ] 가장 좋아하는 카페/테마 순위
- [ ] 월별/연도별 활동 그래프
- [ ] JSON/CSV 내보내기
- [ ] 다크모드 지원
- [ ] 네비게이션 바 (홈, 기록, 친구, 설정)
- [ ] 스와이프 제스처로 기록 삭제/수정
- [ ] 추천 테마 목록

## 🛠 개발 환경

### Flutter 스니펫
- `stfull` : StatefulWidget 생성

## 📊 데이터베이스

### 로컬 저장소 (비회원/회원 공통)
- **Hive**: 일지, 카페/테마 정보 (NoSQL, 빠른 성능)
- **SharedPreferences**: 유저 설정, 앱 상태

### 클라우드 저장소 (회원 전용)
- **Supabase**: OAuth 인증 + PostgreSQL
- **마이그레이션**: 로컬 → 클라우드 자동 동기화

## 🎮 데이터 흐름

1. **비회원**: 로컬(Hive)에서만 데이터 관리
2. **회원가입**: OAuth 로그인 + 로컬 데이터 클라우드 업로드
3. **회원**: 로컬 + 클라우드 동기화, 친구 기능 활성화

## 🚀 최근 구현 완료

### ✅ 완료된 기능들 (2025-08-07)
- **설정 페이지** - 계정 관리 및 앱 정보
- **Google OAuth 로그인** - 실시간 인증 상태 관리
- **Supabase 데이터베이스** - 완전한 스키마 구축
- **회원/비회원 UI** - 동적 인터페이스
- **프로필 자동 생성** - 로그인 시 자동 프로필 생성

### ⚡ 최신 업데이트 (2025-08-13)
- **지연 로딩 구현** - 카페 선택 시 테마를 동적으로 로드
- **EscapeRoomService** - Supabase 데이터 조회 전용 서비스 클래스
- **자동 프로필 생성** - OAuth 로그인 시 UPSERT로 중복 처리
- **nullable 안전성** - EscapeTheme difficulty 필드 nullable 처리
- **RawAutocomplete UX 개선** - 자동 포커스 및 옵션 표시 최적화
- **데이터베이스 연동** - 하드코딩 제거, 실제 DB 쿼리로 변경

### 🔧 기술 스택
- **Frontend**: Flutter 3.7.2+, Material 3 Design
- **Backend**: Supabase (PostgreSQL + Auth)
- **로컬 저장**: Hive + SharedPreferences  
- **인증**: Google OAuth 2.0
- **폰트**: Pretendard
- **아이콘**: flutter_launcher_icons

### 📱 현재 테스트 가능한 기능
1. **OAuth 로그인/로그아웃** - Google 계정으로 로그인
2. **설정 페이지** - 회원 상태에 따른 동적 UI
3. **프로필 관리** - 사용자 정보 자동 동기화
4. **일지 작성** - 카페/테마 동적 로딩, RawAutocomplete UI
5. **친구 관리** - 로그인 시 CRUD 작업, 오프라인 지원
6. **외부 링크** - 앱 가이드, 개인정보처리방침
7. **문의하기** - 이메일 정보 제공

## 🔧 개발 환경 설정

### Supabase 설정 (.env 방식)
1. `.env.example` 파일을 복사하여 `.env` 파일 생성
2. `.env` 파일에 실제 Supabase 프로젝트 정보 입력:
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_ACCESS_TOKEN=your_access_token_here  # MCP용
SUPABASE_PROJECT_REF=your_project_ref_here    # MCP용
```

3. **MCP 설정 (선택적)**:
   - `.mcp.example.json`을 복사해서 `.mcp.json` 생성
   - 프로젝트 정보 입력

### Google OAuth 설정 (Android)
1. `android/app/google-services.json.example`을 복사하여 `google-services.json` 생성
2. Firebase Console에서 다운로드한 실제 파일로 교체
3. 패키지 명: `com.jiyong.escape_diary`

### 보안 주의사항
- `.env`, `.mcp.json`, `google-services.json` 파일은 `.gitignore`에 포함되어 있습니다
- 절대 실제 키 값이 포함된 파일을 커밋하지 마세요
- Next.js와 같은 방식의 환경변수 관리

---

**개발자**: Claude Code + 지용  
**최종 업데이트**: 2025-08-13