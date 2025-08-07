import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jiyong_in_the_room/screens/home_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';

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
  
  void updateDiary(DiaryEntry oldEntry, DiaryEntry newEntry) {
    setState(() {
      final index = diaryList.indexOf(oldEntry);
      if (index != -1) {
        diaryList[index] = newEntry;
      }
    });
  }

  void addFriend(Friend friend) {
    setState(() {
      friendsList.add(friend);
    });
  }

  void removeFriend(Friend friend) {
    setState(() {
      friendsList.remove(friend);
    });
  }

  void updateFriend(Friend oldFriend, Friend newFriend) {
    setState(() {
      final index = friendsList.indexOf(oldFriend);
      if (index != -1) {
        friendsList[index] = newFriend;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenToAuthChanges();
  }

  void _checkAuthState() {
    setState(() {
      isLoggedIn = AuthService.isLoggedIn;
    });
    if (isLoggedIn) {
      _loadUserProfile();
    }
  }

  void _listenToAuthChanges() {
    AuthService.authStateChanges.listen((data) {
      setState(() {
        isLoggedIn = data.session != null;
      });
      if (isLoggedIn) {
        _loadUserProfile();
      } else {
        userProfile = null;
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthService.getCurrentUserProfile();
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      print('프로필 로드 실패: $e');
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
        onAddFriend: addFriend,
        onRemoveFriend: removeFriend,
        onUpdateFriend: updateFriend,
        isLoggedIn: isLoggedIn,
        userProfile: userProfile,
      ),
    );
  }
}
