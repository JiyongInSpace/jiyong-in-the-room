import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jiyong_in_the_room/screens/misc/contact_screen.dart';
import 'package:jiyong_in_the_room/screens/auth/profile_edit_screen.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:jiyong_in_the_room/services/diary_data_service.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? userProfile;

  const SettingsScreen({
    super.key, 
    required this.isLoggedIn,
    this.userProfile,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _currentIsLoggedIn = false;
  Map<String, dynamic>? _currentUserProfile;
  StreamSubscription? _authSubscription;
  bool _profileChanged = false; // 프로필 변경 여부 추적

  @override
  void initState() {
    super.initState();
    _currentIsLoggedIn = widget.isLoggedIn;
    _currentUserProfile = widget.userProfile;
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenToAuthChanges() {
    _authSubscription = AuthService.authStateChanges.listen((data) async {
      final newIsLoggedIn = data.session != null;
      Map<String, dynamic>? newUserProfile;
      
      if (newIsLoggedIn) {
        newUserProfile = await AuthService.getCurrentUserProfile();
      }
      
      if (mounted) {
        setState(() {
          _currentIsLoggedIn = newIsLoggedIn;
          _currentUserProfile = newUserProfile;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 수동으로 pop 제어
      onPopInvoked: (bool didPop) async {
        // 뒤로가기 버튼이나 제스처 시 호출
        Navigator.of(context).pop(_profileChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_profileChanged);
            },
          ),
        ),
        body: ListView(
          children: [
            _buildAccountSection(context), 
            _buildDataSection(context),
            _buildInfoSection(context)
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '👤 계정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        if (!_currentIsLoggedIn) ...[
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Google로 로그인'),
            subtitle: const Text('클라우드 저장 및 친구 기능 사용'),
            onTap: () => _signInWithGoogle(context),
          ),
        ] else ...[
          ListTile(
            leading: _currentUserProfile?['avatar_url'] != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(_currentUserProfile!['avatar_url']),
                  )
                : const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
            title: Text(_currentUserProfile?['display_name'] ?? '사용자'),
            subtitle: Text(_currentUserProfile?['email'] ?? ''),
            onTap: () => _editProfile(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () => _signOut(context),
          ),
        ],
        const Divider(),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '🗂️ 데이터 관리',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep),
          title: const Text('로컬 일지 데이터 정리'),
          subtitle: const Text('기기에 저장된 임시 일지 데이터 삭제'),
          onTap: () => _clearLocalData(context),
        ),
        if (_currentIsLoggedIn) ...[
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('로컬 데이터 다시 동기화'),
            subtitle: const Text('비회원 시 저장한 일지를 클라우드로 이전'),
            onTap: () => _retryMigration(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('마이그레이션 상태 확인'),
            subtitle: const Text('로컬 데이터와 동기화 상태 확인'),
            onTap: () => _checkMigrationStatus(context),
          ),
        ],
        const Divider(),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'ℹ️ 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('앱 사용 가이드'),
          onTap: () async {
            // TODO: 노션 링크로 연결
            const url =
                'https://www.notion.so/24747766bdcc808590bff52a289077fe?source=copy_link';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다')));
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('문의하기'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('개인정보처리방침'),
          onTap: () async {
            // TODO: 노션 링크로 연결
            const url =
                'https://www.notion.so/24747766bdcc80b4aa06c0200b58aa26?source=copy_link';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다')));
              }
            }
          },
        ),
      ],
    );
  }

  // Google 로그인 처리
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await AuthService.signInWithGoogle();
      
      if (kDebugMode) {
        print('🚀 OAuth 시작 결과: $success');
      }
      
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인 완료!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 프로필 편집 화면으로 이동
  Future<void> _editProfile(BuildContext context) async {
    if (_currentUserProfile == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          userProfile: _currentUserProfile!,
        ),
      ),
    );
    
    // 프로필이 업데이트되면 새로고침
    if (result == true) {
      final newProfile = await AuthService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUserProfile = newProfile;
          _profileChanged = true; // 프로필 변경됨으로 표시
        });
      }
    }
  }

  // 로그아웃 처리
  Future<void> _signOut(BuildContext context) async {
    try {
      // 확인 다이얼로그
      final bool? shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      );

      if (shouldSignOut == true) {
        await AuthService.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그아웃되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
          // 설정 화면 닫기
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 로컬 데이터 정리
  Future<void> _clearLocalData(BuildContext context) async {
    try {
      // 현재 로컬 데이터 개수 확인
      final localCount = await LocalStorageService.getDiaryCount();
      
      if (localCount == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('정리할 로컬 데이터가 없습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 확인 다이얼로그
      final bool? shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로컬 데이터 정리'),
          content: Text('기기에 저장된 $localCount개의 임시 일지 데이터를 삭제하시겠습니까?\n\n⚠️ 이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (shouldClear == true) {
        // 로딩 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await LocalStorageService.clearAllDiaries();
        
        if (context.mounted) {
          // 로딩 다이얼로그 닫기
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$localCount개의 로컬 일지 데이터가 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // 로딩 다이얼로그가 열려있다면 닫기
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 정리 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 마이그레이션 다시 시도
  Future<void> _retryMigration(BuildContext context) async {
    try {
      // 현재 로컬 데이터 개수 확인
      final localCount = await LocalStorageService.getDiaryCount();
      
      if (localCount == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('동기화할 로컬 데이터가 없습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 확인 다이얼로그
      final bool? shouldMigrate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로컬 데이터 동기화'),
          content: Text('기기에 저장된 $localCount개의 일지를 클라우드로 이전하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('동기화'),
            ),
          ],
        ),
      );

      if (shouldMigrate == true) {
        // 로딩 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // 마이그레이션 상태 재설정
        await DiaryDataService.resetMigrationStatus();
        
        // 마이그레이션 실행
        final migratedCount = await DiaryDataService.migrateLocalDataToDatabase();
        
        if (context.mounted) {
          // 로딩 다이얼로그 닫기
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$migratedCount개의 일지가 클라우드로 이전되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // 로딩 다이얼로그가 열려있다면 닫기
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 마이그레이션 상태 확인
  Future<void> _checkMigrationStatus(BuildContext context) async {
    try {
      final localCount = await DiaryDataService.getLocalDiaryCount();
      final migrationCompleted = await LocalStorageService.isMigrationCompleted();
      final migrationNeeded = await DiaryDataService.isMigrationNeeded();
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('마이그레이션 상태'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 로컬 일지 개수: $localCount개'),
                const SizedBox(height: 8),
                Text('✅ 마이그레이션 완료: ${migrationCompleted ? "예" : "아니오"}'),
                const SizedBox(height: 8),
                Text('🔄 마이그레이션 필요: ${migrationNeeded ? "예" : "아니오"}'),
                const SizedBox(height: 16),
                if (localCount > 0 && !migrationCompleted)
                  const Text(
                    '⚠️ 동기화가 필요한 로컬 데이터가 있습니다.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (localCount == 0)
                  const Text(
                    '✅ 동기화할 로컬 데이터가 없습니다.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Text(
                    '✅ 모든 데이터가 동기화되었습니다.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태 확인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
