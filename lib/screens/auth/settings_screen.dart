import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jiyong_in_the_room/screens/misc/contact_screen.dart';
import 'package:jiyong_in_the_room/screens/auth/profile_edit_screen.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/widgets/migration_guide_dialog.dart';
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
      final wasLoggedOut = !_currentIsLoggedIn;
      Map<String, dynamic>? newUserProfile;
      
      if (newIsLoggedIn) {
        newUserProfile = await AuthService.getCurrentUserProfile();
        
        // 로그아웃 상태에서 로그인 상태로 변경되었을 때만 마이그레이션 팝업 확인
        if (wasLoggedOut && mounted) {
          _checkAndShowMigrationDialog();
        }
      }
      
      if (mounted) {
        setState(() {
          _currentIsLoggedIn = newIsLoggedIn;
          _currentUserProfile = newUserProfile;
        });
      }
    });
  }
  
  // 마이그레이션 팝업 확인 및 표시
  void _checkAndShowMigrationDialog() async {
    // 약간의 지연을 두고 실행 (UI가 안정화된 후)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // 로컬 데이터가 있는지 확인
    final localDiaries = LocalStorageService.getLocalDiaries();
    if (localDiaries.isNotEmpty) {
      // 마이그레이션 안내 팝업 표시
      showDialog(
        context: context,
        barrierDismissible: false, // 외부 클릭으로 닫기 방지
        builder: (context) => MigrationGuideDialog(
          onMigrationComplete: () {
            // 마이그레이션 완료 시 프로필 변경 플래그 설정
            setState(() {
              _profileChanged = true;
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(_profileChanged);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 80), // 하단 80px 여백
        children: [_buildAccountSection(context), _buildInfoSection(context)],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Padding(
        //   padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        //   child: Text(
        //     '👤 계정',
        //     style: TextStyle(
        //       fontSize: 18,
        //       fontWeight: FontWeight.bold,
        //       color: Colors.grey,
        //     ),
        //   ),
        // ),
        if (!_currentIsLoggedIn) ...[
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Google로 로그인'),
            subtitle: const Text('클라우드 저장 및 친구 기능 사용'),
            onTap: () => _signInWithGoogle(context),
          ),
        ] else ...[
          ListTile(
            leading: _getProfileAvatar(),
            title: Text(_currentUserProfile?['display_name'] ?? '사용자'),
            subtitle: Text(_currentUserProfile?['email'] ?? ''),
            onTap: () => _editProfile(context),
          ),
          // 마이그레이션 버튼 (로컬 데이터가 있을 때만 표시)
          if (LocalStorageService.hasLocalDiaries()) ...[
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
              title: const Text('기기에 저장된 일지 가져오기'),
              subtitle: const Text('로그인 전에 작성한 일지를 계정에 연결'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showMigrationDialog(context),
            ),
          ],
        ],
        const Divider(),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Padding(
        //   padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        //   child: Text(
        //     'ℹ️ 정보',
        //     style: TextStyle(
        //       fontSize: 18,
        //       fontWeight: FontWeight.bold,
        //       color: Colors.grey,
        //     ),
        //   ),
        // ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('앱 사용 가이드'),
          onTap: () async {
            const url = 'https://www.notion.so/24747766bdcc808590bff52a289077fe?source=copy_link';
            try {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                throw 'Could not launch $url';
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('링크를 열 수 없습니다: $e')),
                );
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
            const url = 'https://www.notion.so/24747766bdcc80b4aa06c0200b58aa26?source=copy_link';
            try {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                throw 'Could not launch $url';
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('링크를 열 수 없습니다: $e')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('오픈소스 라이선스'),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: '탈출일지',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(
                Icons.exit_to_app,
                size: 64,
                color: Colors.blue,
              ),
            );
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
    final currentProfile = _currentUserProfile;
    if (currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필 정보를 불러오는 중입니다...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          userProfile: currentProfile,
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
  
  // 프로필 아바타 가져오기 (null-safe)
  Widget _getProfileAvatar() {
    final currentProfile = _currentUserProfile;
    if (currentProfile != null && currentProfile['avatar_url'] != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(currentProfile['avatar_url'] as String),
      );
    }
    return const CircleAvatar(
      child: Icon(Icons.person),
    );
  }

  // 마이그레이션 확인 다이얼로그 표시
  Future<void> _showMigrationDialog(BuildContext context) async {
    final stats = LocalStorageService.getLocalDataStats();
    final diariesCount = stats['diaries'] ?? 0;
    
    if (diariesCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('가져올 일지가 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('일지 가져오기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기기에 저장된 일지 ${diariesCount}개를 계정에 연결하시겠습니까?'),
            const SizedBox(height: 16),
            const Text(
              '📱 안내:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Text('• 연결 완료 후 기기 데이터는 정리됩니다'),
            const Text('• 연결 실패 시 해당 일지는 유지됩니다'),
            const Text('• 인터넷 연결이 필요합니다'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _performMigration(context);
    }
  }

  // 실제 마이그레이션 수행
  Future<void> _performMigration(BuildContext context) async {
    // 진행률 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('일지 가져오는 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('기기에 저장된 일지를 계정에 연결하고 있어요...'),
            const SizedBox(height: 8),
            const Text(
              '잠시만 기다려주세요',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      // 로컬 데이터 가져오기
      final localDiaries = LocalStorageService.getLocalDiaries();
      
      if (localDiaries.isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop(); // 진행률 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가져올 일지가 없습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 로컬 친구 목록도 가져오기
      final localFriends = LocalStorageService.getLocalFriends();
      
      // DB로 마이그레이션 (친구 포함)
      final result = await DatabaseService.migrateLocalDataToDatabase(
        localDiaries,
        localFriends,
      );
      
      // 진행률 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // 결과 확인
      final successCount = result['successCount'] as int;
      final errors = result['errors'] as List<String>;
      final migratedLocalIds = result['migratedLocalIds'] as List<int>;
      
      if (successCount > 0) {
        // 성공한 항목들만 로컬에서 삭제
        for (var localId in migratedLocalIds) {
          try {
            await LocalStorageService.deleteDiary(localId);
          } catch (e) {
            if (kDebugMode) {
              print('❌ 로컬 데이터 삭제 실패: ID=$localId, 에러: $e');
            }
          }
        }
        
        // 메인 화면 데이터 새로고침 요청
        setState(() {
          _profileChanged = true; // 데이터 변경됨을 알림
        });
        
        if (kDebugMode) {
          print('🔄 마이그레이션 완료: 메인화면 새로고침 요청됨');
        }
      }
      
      // 결과 다이얼로그 표시
      if (context.mounted) {
        _showMigrationResultDialog(context, successCount, errors, localDiaries.length);
      }
      
    } catch (e) {
      // 진행률 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (kDebugMode) {
        print('❌ 마이그레이션 실패: $e');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일지 가져오기 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 마이그레이션 결과 다이얼로그
  void _showMigrationResultDialog(
    BuildContext context, 
    int successCount, 
    List<String> errors, 
    int totalCount
  ) {
    final failedCount = totalCount - successCount;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          successCount == totalCount ? '✅ 일지 가져오기 완료' : '⚠️ 일부 가져오기 완료',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('총 ${totalCount}개 중 ${successCount}개가 성공적으로 연결되었습니다.'),
            if (failedCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                '실패한 ${failedCount}개 항목:',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              ...errors.take(3).map((error) => Text(
                '• $error',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              )),
              if (errors.length > 3) 
                Text(
                  '• 그 외 ${errors.length - 3}개...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
            if (successCount > 0) ...[
              const SizedBox(height: 12),
              const Text(
                '✅ 연결된 일지는 정리되었습니다',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 결과 다이얼로그 닫을 때도 데이터 변경 표시
              setState(() {
                _profileChanged = true;
              });
              if (kDebugMode) {
                print('✅ 마이그레이션 결과 다이얼로그 닫힘: 데이터 변경 상태 유지');
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

}
