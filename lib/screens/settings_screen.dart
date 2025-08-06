import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jiyong_in_the_room/screens/contact_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool isLoggedIn; // 회원/비회원 상태

  const SettingsScreen({
    super.key,
    this.isLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildAccountSection(context),
          _buildInfoSection(context),
        ],
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
            title: const Text('회원가입하기'),
            subtitle: const Text('클라우드 저장 및 친구 기능 사용'),
            onTap: () {
              // TODO: 회원가입 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('회원가입 기능은 준비중입니다')),
              );
            },
          ),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('지용님'),
            subtitle: const Text('프로필 편집'),
            onTap: () {
              // TODO: 프로필 편집 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 편집 기능은 준비중입니다')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              // TODO: 로그아웃 처리
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 기능은 준비중입니다')),
              );
            },
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
            const url = 'https://notion.so'; // 실제 노션 링크로 교체 필요
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('링크를 열 수 없습니다')),
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
              MaterialPageRoute(
                builder: (context) => const ContactScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('개인정보처리방침'),
          onTap: () async {
            // TODO: 노션 링크로 연결
            const url = 'https://notion.so'; // 실제 노션 링크로 교체 필요
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('링크를 열 수 없습니다')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}