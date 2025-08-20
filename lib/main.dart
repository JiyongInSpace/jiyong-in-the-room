import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jiyong_in_the_room/screens/home_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  
  await Hive.initFlutter();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
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
  
  void addDiary(DiaryEntry entry) {
    setState(() {
      diaryList.add(entry);
    });
  }
  
  // DB에서 일지 목록 로드
  Future<void> _loadDiaryEntries() async {
    try {
      if (AuthService.isLoggedIn) {
        final entries = await DatabaseService.getMyDiaryEntries();
        setState(() {
          diaryList.clear();
          diaryList.addAll(entries);
        });
        if (kDebugMode) {
          print('📋 일지 목록 로드됨: ${entries.length}개');
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
  }

  void deleteDiary(DiaryEntry entry) {
    setState(() {
      diaryList.remove(entry);
    });
  }

  Future<void> addFriend(Friend friend) async {
    try {
      if (AuthService.isLoggedIn) {
        final savedFriend = await DatabaseService.addFriend(friend);
        setState(() {
          friendsList.add(savedFriend);
        });
        if (kDebugMode) {
          print('✅ 친구 "${friend.nickname}" DB에 저장됨');
        }
      } else {
        // 로그인하지 않은 경우 로컬에만 저장
        setState(() {
          friendsList.add(friend);
        });
        if (kDebugMode) {
          print('📱 친구 "${friend.nickname}" 로컬에만 저장됨 (로그인 필요)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 추가 실패: $e');
      }
      // 실패 시에도 로컬에 추가 (오프라인 기능)
      setState(() {
        friendsList.add(friend);
      });
    }
  }

  Future<void> removeFriend(Friend friend) async {
    try {
      if (AuthService.isLoggedIn) {
        await DatabaseService.deleteFriend(friend);
        if (kDebugMode) {
          print('✅ 친구 "${friend.nickname}" DB에서 삭제됨');
        }
      }
      setState(() {
        friendsList.remove(friend);
      });
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
      if (AuthService.isLoggedIn) {
        final updatedFriend = await DatabaseService.updateFriend(
          oldFriend,
          newNickname: newFriend.nickname,
          newMemo: newFriend.memo,
        );
        setState(() {
          final index = friendsList.indexOf(oldFriend);
          if (index != -1) {
            friendsList[index] = updatedFriend;
          }
        });
        if (kDebugMode) {
          print('✅ 친구 "${oldFriend.nickname}" 정보 DB에서 수정됨');
        }
      } else {
        setState(() {
          final index = friendsList.indexOf(oldFriend);
          if (index != -1) {
            friendsList[index] = newFriend;
          }
        });
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
    _checkAuthState();
    _listenToAuthChanges();
    _handleInitialLink();
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
      if (kDebugMode) {
        print('🔐 Auth state changed: ${data.session != null ? "로그인됨" : "로그아웃됨"}');
        if (data.session != null) {
          print('👤 User: ${data.session!.user.email}');
          print('🔑 Provider: ${data.session!.user.appMetadata['provider'] ?? 'unknown'}');
        }
      }
      setState(() {
        isLoggedIn = data.session != null;
      });
      if (isLoggedIn) {
        _loadUserProfile();
        _loadUserData();
      } else {
        userProfile = null;
        _clearUserData();
      }
    });
  }

  // 로그인 시 사용자 데이터 로드
  Future<void> _loadUserData() async {
    try {
      // 친구 목록 로드
      final friends = await DatabaseService.getMyFriends();
      setState(() {
        friendsList.clear();
        friendsList.addAll(friends);
      });
      if (kDebugMode) {
        print('📋 친구 목록 로드됨: ${friends.length}명');
      }
      
      // 일지 목록 로드
      await _loadDiaryEntries();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 사용자 데이터 로드 실패: $e');
      }
    }
  }

  // 로그아웃 시 로컬 데이터 정리
  void _clearUserData() {
    setState(() {
      friendsList.clear();
      diaryList.clear();
    });
    if (kDebugMode) {
      print('🧹 로컬 데이터 정리 완료');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthService.getCurrentUserProfile();
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      // TODO: 로깅 프레임워크로 교체
      // print('프로필 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '탈출일지',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: HomeScreen(
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
        onDataRefresh: _loadUserData, // 프로필 변경 시 데이터 새로고침
      ),
    );
  }
}
