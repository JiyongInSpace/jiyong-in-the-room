import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jiyong_in_the_room/screens/contact_screen.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? userProfile;

  const SettingsScreen({
    super.key, 
    required this.isLoggedIn,
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
        if (!isLoggedIn) ...[
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Google로 로그인'),
            subtitle: const Text('클라우드 저장 및 친구 기능 사용'),
            onTap: () => _signInWithGoogle(context),
          ),
        ] else ...[
          ListTile(
            leading: userProfile?['avatar_url'] != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(userProfile!['avatar_url']),
                  )
                : const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
            title: Text(userProfile?['display_name'] ?? '사용자'),
            subtitle: Text(userProfile?['email'] ?? ''),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 편집 기능은 준비중입니다')),
              );
            },
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

      final response = await AuthService.signInWithGoogle();
      
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.user != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${response.user!.email}으로 로그인되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          // 설정 화면 닫기
          Navigator.of(context).pop();
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
