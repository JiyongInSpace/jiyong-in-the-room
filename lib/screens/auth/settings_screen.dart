import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jiyong_in_the_room/screens/misc/contact_screen.dart';
import 'package:jiyong_in_the_room/screens/auth/profile_edit_screen.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
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
    return Scaffold(
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
        children: [_buildAccountSection(context), _buildInfoSection(context)],
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
}
