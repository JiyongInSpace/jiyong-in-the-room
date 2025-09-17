import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jiyong_in_the_room/constants/app_colors.dart';
import 'package:jiyong_in_the_room/screens/main/home_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/connectivity_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:jiyong_in_the_room/services/friend_service.dart';
import 'package:jiyong_in_the_room/services/unified_storage_service.dart';
import 'package:jiyong_in_the_room/services/sync_queue_service.dart';
import 'package:jiyong_in_the_room/widgets/offline_banner.dart';
import 'package:jiyong_in_the_room/widgets/onboarding_dialog.dart';
import 'package:jiyong_in_the_room/services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  
  await Hive.initFlutter();
  
  // 로컬 저장소 초기화
  await LocalStorageService.initialize();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  // ConnectivityService 초기화
  await ConnectivityService().initialize();
  
  // SyncQueueService 초기화
  await SyncQueueService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<DiaryEntry> diaryList = [];
  final List<Friend> friendsList = [];
  bool isLoggedIn = false;
  Map<String, dynamic>? userProfile;
  bool _isInitialLoading = true; // 초기 로딩 상태
  bool _shouldShowMigrationDialog = false; // 마이그레이션 다이얼로그 표시 플래그
  bool _hasShownOnboarding = false; // 온보딩 표시 여부
  
  void addDiary(DiaryEntry entry) {
    setState(() {
      // 새 일지를 날짜 기준 올바른 위치에 삽입 (최신순 유지)
      int insertIndex = 0;
      for (int i = 0; i < diaryList.length; i++) {
        if (diaryList[i].date.isBefore(entry.date)) {
          insertIndex = i;
          break;
        }
        insertIndex = i + 1;
      }
      diaryList.insert(insertIndex, entry);
    });
    
    // 데이터 다시 로드 (회원: DB 참여자 정보 업데이트, 비회원: 로컬 데이터 동기화)
    _loadDiaryEntries();
  }
  
  // 일지 목록 로드 (통합 스토리지 서비스 사용)
  Future<void> _loadDiaryEntries() async {
    try {
      // UnifiedStorageService를 사용하여 로컬 우선 로드
      final entries = await UnifiedStorageService.getDiaries();
      if (mounted) {
        setState(() {
          diaryList.clear();
          diaryList.addAll(entries);
        });
        if (kDebugMode) {
          print('⚡ 통합 스토리지에서 일지 로드됨: ${entries.length}개 (캐시 적용)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 일지 목록 로드 실패: $e');
      }
    }
  }
  
  void updateDiary(DiaryEntry oldEntry, DiaryEntry newEntry) {
    setState(() {
      final index = diaryList.indexOf(oldEntry);
      if (index != -1) {
        diaryList[index] = newEntry;
      }
    });
    
    // 일지 수정 후 전체 데이터 다시 로드하여 참여자 정보 업데이트
    _loadDiaryEntries();
  }

  void deleteDiary(DiaryEntry entry) {
    setState(() {
      diaryList.remove(entry);
    });
    
    // 일지 삭제 후 전체 데이터 다시 로드하여 참여자 정보 업데이트
    _loadDiaryEntries();
  }

  void addFriend(Friend friend) {
    // 친구는 이미 저장된 상태로 전달됨 - UI 상태만 업데이트
    setState(() {
      friendsList.add(friend);
    });
    
    if (kDebugMode) {
      print('✅ 친구 "${friend.nickname}" UI에 추가됨');
    }
  }

  Future<void> removeFriend(Friend friend) async {
    try {
      // 통합 친구 서비스 사용
      await FriendService.deleteFriend(friend);
      
      setState(() {
        friendsList.remove(friend);
      });
      
      // 친구 삭제 후 일지 데이터도 새로고침
      await _loadDiaryEntries();
      
      if (kDebugMode) {
        print('✅ 친구 "${friend.nickname}" 삭제됨');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 삭제 실패: $e');
      }
      // 실패해도 로컬에서는 제거
      setState(() {
        friendsList.remove(friend);
      });
    }
  }

  Future<void> updateFriend(Friend oldFriend, Friend newFriend) async {
    try {
      // 통합 친구 서비스 사용
      final updatedFriend = await FriendService.updateFriend(
        oldFriend,
        nickname: newFriend.nickname,
        memo: newFriend.memo,
      );
      
      setState(() {
        final index = friendsList.indexOf(oldFriend);
        if (index != -1) {
          friendsList[index] = updatedFriend;
        }
      });
      
      // 친구 정보 변경 후 일지 데이터도 새로고침 (친구 정보 실시간 반영)
      await _loadDiaryEntries();
      
      if (kDebugMode) {
        print('✅ 친구 "${oldFriend.nickname}" → "${newFriend.nickname}" 수정됨');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 정보 수정 실패: $e');
      }
      // 실패해도 로컬에서는 수정
      setState(() {
        final index = friendsList.indexOf(oldFriend);
        if (index != -1) {
          friendsList[index] = newFriend;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // 앱 초기화 메서드
  Future<void> _initializeApp() async {
    try {
      _checkAuthState();
      _listenToAuthChanges();
      _handleInitialLink();
      
      // 데이터 로드 (로그인 여부와 상관없이)
      await _loadDiaryEntries();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 앱 초기화 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false; // 로딩 완료
        });
        
        // 로딩 완료 후 온보딩 체크 (MaterialApp이 빌드된 후)
        _checkAndScheduleOnboarding();
      }
    }
  }

  void _handleInitialLink() async {
    // 웹에서 URL 파라미터 확인
    if (kIsWeb) {
      final uri = Uri.base;
      if (kDebugMode) {
        print('🌐 Current URL: $uri');
        print('🔍 Query parameters: ${uri.queryParameters}');
      }
      
      if (uri.queryParameters.containsKey('code')) {
        if (kDebugMode) {
          print('🔑 OAuth code received: ${uri.queryParameters['code']}');
        }
        
        // URL을 정리하여 깔끔하게 만들기
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (kIsWeb) {
            // URL에서 쿼리 파라미터 제거
            final cleanUrl = '${uri.origin}${uri.path}';
            if (kDebugMode) {
              print('🧹 Cleaning URL to: $cleanUrl');
            }
            // 브라우저 히스토리 교체 (새로고침 없이)
            // window.history.replaceState(null, '', cleanUrl);
          }
        });
      }
    }
  }

  void _checkAuthState() {
    final currentUser = AuthService.currentUser;
    setState(() {
      isLoggedIn = AuthService.isLoggedIn;
    });
    
    if (kDebugMode) {
      print('🔍 Initial auth check - isLoggedIn: $isLoggedIn');
      if (currentUser != null) {
        print('👤 Current user: ${currentUser.email}');
      }
    }
    
    if (isLoggedIn) {
      _loadUserProfile();
    }
  }

  void _listenToAuthChanges() {
    AuthService.authStateChanges.listen((data) {
      final session = data.session;
      if (kDebugMode) {
        print('🔐 Auth state changed: ${session != null ? "로그인됨" : "로그아웃됨"}');
        if (session != null) {
          print('👤 User: ${session.user.email}');
          print('🔑 Provider: ${session.user.appMetadata['provider'] ?? 'unknown'}');
        }
      }
      if (mounted) {
        setState(() {
          isLoggedIn = session != null;
        });
        if (isLoggedIn) {
          // 로그인 시 비회원 데이터 정리하고 DB 데이터 로드
          if (kDebugMode) {
            print('🔄 로그인 감지: 비회원 데이터 정리 중...');
            print('  - 기존 일지: ${diaryList.length}개');
            print('  - 기존 친구: ${friendsList.length}명');
          }
          
          setState(() {
            diaryList.clear(); // 기존 로컬 데이터 정리
            friendsList.clear(); // 기존 로컬 친구 정리
          });
          
          if (kDebugMode) {
            print('✅ 비회원 데이터 정리 완료. DB 데이터 로드 시작...');
          }
          
          _loadUserProfile();
          _loadUserData();
        } else {
          setState(() {
            userProfile = null;
          });
          // 로그아웃 시 DB 데이터는 지우고 로컬 데이터 로드
          _clearUserData();
          _loadDiaryEntries(); // 로컬 데이터 로드
        }
      }
    });
  }

  // 로그인 시 사용자 데이터 로드 (통합 스토리지 서비스 사용)
  Future<void> _loadUserData() async {
    try {
      // UnifiedStorageService를 사용하여 로컬 우선 로드
      final friends = await UnifiedStorageService.getFriends();
      if (mounted) {
        setState(() {
          friendsList.clear();
          friendsList.addAll(friends);
        });
        if (kDebugMode) {
          print('⚡ 통합 스토리지에서 친구 로드됨: ${friends.length}명 (캐시 적용)');
        }
      }
      
      // 일지 목록 로드 (회원/비회원 상관없이)
      await _loadDiaryEntries();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 사용자 데이터 로드 실패: $e');
      }
    }
  }

  // 로그아웃 시 DB 데이터만 정리 (로컬 데이터는 유지)
  void _clearUserData() {
    if (mounted) {
      setState(() {
        friendsList.clear();
        // diaryList는 clear하지 않고 로컬 데이터로 교체될 예정
      });
      if (kDebugMode) {
        print('🧹 DB 데이터 정리 완료');
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          userProfile = profile;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 프로필 로드 실패: $e');
      }
      // 프로필 로드 실패 시 null로 설정
      if (mounted) {
        setState(() {
          userProfile = null;
        });
      }
    }
  }
  
  // 전체 데이터 새로고침 (일지 작성 후 호출)
  Future<void> _refreshAllData() async {
    if (kDebugMode) {
      print('🔄 전체 데이터 새로고침 시작');
    }
    
    await Future.wait([
      _loadUserProfile(), // 프로필 로드
      _loadUserData(),    // 일지 + 친구 데이터 로드
    ]);
    
    if (kDebugMode) {
      print('✅ 전체 데이터 새로고침 완료');
    }
  }
  
  // 온보딩 체크 및 스케줄링
  void _checkAndScheduleOnboarding() {
    if (!mounted || _isInitialLoading) return;
    
    // 초기 로딩이 완료되고 MaterialApp이 빌드된 후 온보딩 확인
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // MaterialApp이 완전히 빌드될 때까지 잠시 대기
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      try {
        final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
        if (kDebugMode) {
          print('📋 온보딩 확인: hasSeenOnboarding=$hasSeenOnboarding, _hasShownOnboarding=$_hasShownOnboarding');
        }
        
        // 아직 온보딩을 보지 않았고, 이번 세션에서도 보여주지 않았다면
        if (!hasSeenOnboarding && !_hasShownOnboarding && mounted) {
          setState(() {
            _hasShownOnboarding = true;
          });
          
          // context가 MaterialApp 내부에 있는지 확인
          final BuildContext? materialContext = context;
          if (materialContext != null && mounted) {
            await showDialog(
              context: materialContext,
              barrierDismissible: false,
              builder: (dialogContext) => const OnboardingDialog(),
            );
            
            // 온보딩 완료 표시
            await OnboardingService.markOnboardingAsSeen();
            if (kDebugMode) {
              print('✅ 온보딩 완료 처리됨');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ 온보딩 처리 실패: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 초기 로딩 중이라면 로딩 화면 표시
    if (_isInitialLoading) {
      return MaterialApp(
        title: '탈출일지',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.secondary,
            secondary: AppColors.tertiary,
            surface: AppColors.surface,
            background: AppColors.backgroundLight,
          ),
          useMaterial3: true,
          fontFamily: 'Pretendard',
          scaffoldBackgroundColor: AppColors.backgroundLight,
        ),
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 또는 앱 아이콘
                  Icon(
                    Icons.lock_clock,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                  SizedBox(height: 24),
                  // 앱 제목
                  Text(
                    '탈출일지',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 32),
                  // 로딩 인디케이터
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '데이터를 불러오고 있어요...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: '탈출일지',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, // 지도 느낌의 밝은 노랑
          primary: AppColors.secondary, // 따뜻한 오렌지-노랑
          secondary: AppColors.tertiary, // 연황토색
          surface: AppColors.surface, // 매우 연한 크림색
          background: AppColors.backgroundLight, // 연한 베이지
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.appBarText,
          elevation: 2,
        ),
      ),
      // 한국어 로케일 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어 (기본)
      ],
      locale: const Locale('ko', 'KR'), // 기본 로케일을 한국어로 설정,
      home: OfflineBanner(
        child: HomeScreen(
          diaryList: diaryList,
          friends: friendsList,
          onAdd: addDiary,
          onUpdate: updateDiary,
          onDelete: deleteDiary,
          onAddFriend: addFriend,
          onRemoveFriend: removeFriend,
          onUpdateFriend: updateFriend,
          isLoggedIn: isLoggedIn,
          userProfile: userProfile,
          onDataRefresh: _refreshAllData, // 전체 데이터 새로고침
        ),
      ),
    );
  }
}
