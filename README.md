# 🏃‍♂️ 방탈출 일지 (Escape Room Diary)

> **"누구와 함께했는지"**에 중점을 둔 방탈출 기록 앱

## 📝 프로젝트 컨셉

다른 방탈출 기록 어플은 평점, 후기에 중점을 뒀다면, 이 앱은 **누구와 했는지**에 중점을 둡니다.  
친구와 함께한 추억을 기록하고, 통계를 확인할 수 있는 소셜 방탈출 일지 앱입니다.

## 🚀 주요 기능

### ✅ 구현 완료된 기능들

#### 📱 핵심 기능
- **일지 관리 (CRUD)**
  - 일지 작성/수정/삭제
  - 카페/테마 자동완성 검색
  - 탈출 성공/실패 기록
  - 별점 및 메모 작성
  - 함께한 친구 기록
  - 메모 공개/비공개 설정

#### 👥 친구 시스템
- **친구 관리**
  - 6자리 사용자 코드로 친구 추가
  - 친구 정보 수정/삭제
  - 실제 사용자와 연동/해제
  - 친구별 참여 통계
  - 친구 상세 페이지

#### 🔐 인증 & 프로필
- **Google Sign-In 네이티브 로그인**
  - 모바일 최적화 UX (브라우저 없이 로그인)
  - 실시간 인증 상태 관리
  - 자동 프로필 생성
- **프로필 관리**
  - 프로필 이미지 업로드 (갤러리/카메라)
  - 표시 이름 변경
  - 6자리 친구 코드 확인/복사

#### 🎨 UI/UX
- **지도 테마 디자인**
  - 노랑+연황토 색상 팔레트
  - 스탬프 이미지 (성공/실패)
  - Material 3 디자인 시스템
- **인피니트 스크롤**
  - 일지 목록 페이징
  - 친구 목록 페이징
  - 실시간 검색 (500ms 디바운싱)
- **Skeleton UI 로딩**
  - 8가지 페이지별 최적화 스켈레톤
  - 부드러운 페이드 애니메이션
- **오프라인 지원**
  - 네트워크 상태 실시간 모니터링
  - 오프라인 배너 표시
  - 자동 재연결

#### 📊 통계 & 필터
- **홈 화면 통계**
  - 총 진행한 테마 수
  - 함께한 친구 수
  - 최근 진행한 테마
  - 가장 많이 함께한 친구 랭킹
- **검색 & 필터링**
  - 테마명/카페명 검색
  - 친구 다중 선택 필터
  - 연관검색어 지원

#### 🔧 기타
- **공통 위젯 시스템**
  - 일관된 입력 필드 (56px 높이)
  - 재사용 가능한 카드 컴포넌트
  - 바텀시트 관리 시스템
- **에러 처리**
  - 50+ 에러 패턴 자동 인식
  - 사용자 친화적 메시지 변환
  - 맞춤 해결 방법 제시

## 🛠 기술 스택

### Frontend
- **Flutter 3.7.2+** - 크로스 플랫폼 앱 개발
- **Material 3 Design** - 최신 디자인 시스템
- **지도 테마 색상** - 노랑+연황토 커스텀 팔레트

### Backend & Database
- **Supabase**
  - PostgreSQL 데이터베이스
  - OAuth 인증 (Google)
  - Storage (프로필 이미지)
  - RLS (Row Level Security) 보안
- **로컬 저장소**
  - Hive Flutter (오프라인 캐싱)

### 주요 패키지
```yaml
dependencies:
  supabase_flutter: ^2.8.0      # 백엔드 서비스
  google_sign_in: ^6.2.1        # Google OAuth
  hive_flutter: ^1.1.0          # 로컬 저장소
  image_picker: ^1.0.7          # 이미지 선택
  connectivity_plus: ^6.0.5     # 네트워크 모니터링
  flutter_dotenv: ^5.1.0        # 환경변수 관리
  url_launcher: ^6.3.1          # 외부 링크
```

## 📊 데이터베이스 구조

### 주요 테이블
- `profiles` - 사용자 프로필 (user_code 포함)
- `friends` - 친구 관리 (연동/비연동 지원)
- `escape_cafes` - 방탈출 카페 정보
- `escape_themes` - 방탈출 테마 정보 (연관검색어 포함)
- `diary_entries` - 일지 엔트리
- `diary_entry_participants` - 일지 참여자

### 특징
- **INTEGER ID 사용** - 성능 최적화
- **RLS 보안 정책** - 사용자별 데이터 격리
- **자동 타임스탬프** - created_at/updated_at 트리거
- **복합 인덱스** - 빠른 쿼리 성능

## 🎯 개발 로드맵

### 🔥 다음 개발 예정
- [ ] 사진 첨부 기능 (테마 사진, 인증샷)
- [ ] 테마별 통계 (성공률, 평균 시간 등)
- [ ] 카페별 테마 목록 보기
- [ ] 데이터 백업/내보내기

### 💡 추후 계획
- [ ] 친구와 기록 공유
- [ ] 월별/연도별 활동 그래프
- [ ] 추천 테마 목록
- [ ] 다크모드 지원
- [ ] iOS 지원 개선

## 🔧 개발 환경 설정

### 1. 환경변수 설정 (.env)
```bash
# .env.example을 복사하여 .env 파일 생성
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_SERVER_CLIENT_ID=your_server_client_id
```

### 2. Google OAuth 설정
- Firebase Console에서 프로젝트 생성
- `google-services.json` 다운로드 → `android/app/` 폴더에 추가
- 패키지명: `com.jiyong.escape_diary`

### 3. 의존성 설치
```bash
flutter pub get
```

### 4. 앱 실행
```bash
flutter run
```

## 📱 스크린샷

### 메인 화면
- 통계 카드 (테마 수, 친구 수)
- 최근 진행한 테마 목록
- 친구 랭킹

### 일지 작성
- 카페/테마 자동완성
- 친구 선택
- 탈출 결과 기록

### 친구 관리
- 6자리 코드로 추가
- 친구별 통계 확인
- 연동/해제 기능

## 🤝 기여 방법

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 있습니다.

## 👨‍💻 개발자

**개발**: Claude Code + 지용  
**최종 업데이트**: 2025-08-30

---

### 🏆 최근 마일스톤

#### 2025-08-30
- 일지/친구 관리 바텀시트 공통 위젯화
- 친구 정보 수정 시 실시간 반영

#### 2025-08-29
- 친구 상세페이지 성능 최적화
- 일지 상세페이지 보안 강화

#### 2025-08-27
- 네트워크 연결 관리 시스템 구축
- Skeleton UI 로딩 상태 개선
- 사용자 친화적 에러 처리

#### 2025-08-25
- 테마 검색 UX 완성
- 친구 관리 통합 UI

#### 2025-08-24
- 6자리 사용자 코드 시스템
- 친구 연동 기능

#### 2025-08-21
- 비회원 접근 제어
- 본인 제외 통계

#### 2025-08-19
- Google Sign-In 네이티브 구현
- 프로필 이미지 업로드

#### 2025-08-14
- 참여자 시스템 개선
- 스마트 삭제 기능

#### 2025-08-13
- 지연 로딩 구현
- Supabase 완전 연동