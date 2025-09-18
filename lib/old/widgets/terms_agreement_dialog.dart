import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 14세 이상 확인 및 약관 동의 다이얼로그
class TermsAgreementDialog extends StatefulWidget {
  const TermsAgreementDialog({super.key});

  @override
  State<TermsAgreementDialog> createState() => _TermsAgreementDialogState();
}

class _TermsAgreementDialogState extends State<TermsAgreementDialog> {
  bool _isOver14 = false;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;

  // 모든 필수 약관에 동의했는지 확인
  bool get _canProceed => _isOver14 && _agreeToTerms && _agreeToPrivacy;

  // 약관 전문 다이얼로그 표시
  void _showTermsDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
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

  // 서비스 이용약관 내용
  String get _termsContent => '''
1. 서비스 이용에 관한 기본 사항

본 방탈출 일지 서비스는 사용자가 방탈출 체험 기록을 관리할 수 있도록 지원하는 서비스입니다.

2. 회원가입 및 계정 관리

- Google 계정을 통한 간편 로그인을 지원합니다.
- 사용자는 언제든지 계정을 삭제할 수 있습니다.

3. 서비스 이용 규칙

- 서비스를 부적절하게 사용하거나 다른 사용자에게 피해를 주는 행위는 금지됩니다.
- 허위 정보 입력 및 타인의 개인정보 도용은 금지됩니다.

4. 데이터 백업 및 보안

- 클라우드 저장을 통해 데이터 안전성을 보장합니다.
- 사용자 데이터는 암호화되어 저장됩니다.

5. 서비스 변경 및 중단

- 서비스 개선을 위한 업데이트가 있을 수 있습니다.
- 중요한 변경사항은 사전에 공지됩니다.

본 약관은 2025년 1월 2일부터 시행됩니다.
''';

  // 개인정보 처리방침 내용
  String get _privacyContent => '''
1. 개인정보 수집 및 이용 목적

방탈출 일지 서비스 제공을 위해 다음과 같은 개인정보를 수집합니다.

2. 수집하는 개인정보 항목

필수항목:
- Google 계정 정보 (이메일, 이름, 프로필 사진)
- 서비스 이용 기록

선택항목:
- 방탈출 체험 기록 및 후기

3. 개인정보 이용 기간

- 회원 탈퇴 시까지 보관
- 탈퇴 후 즉시 삭제 (법령에 의해 보관이 필요한 경우 제외)

4. 개인정보 제3자 제공

- 원칙적으로 개인정보를 외부에 제공하지 않습니다.
- 법령에 의한 요구가 있는 경우에만 제공합니다.

5. 개인정보 보호 조치

- 데이터 암호화 저장
- 접근 권한 관리
- 정기적인 보안 점검

6. 개인정보 처리 위탁

- 클라우드 서비스 (Supabase)를 통한 데이터 저장

7. 정보주체의 권리

사용자는 다음과 같은 권리를 가집니다:
- 개인정보 열람 요구권
- 개인정보 정정·삭제 요구권
- 개인정보 처리 정지 요구권

문의사항이 있으시면 앱 내 문의하기를 이용해 주세요.

본 방침은 2025년 1월 2일부터 시행됩니다.
''';

  // 외부 링크 열기 (필요한 경우를 위해 유지)
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('서비스 이용 약관'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 메시지
              const Text(
                '서비스를 이용하시기 위해 다음 사항에 동의해 주세요.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // 14세 이상 확인
              CheckboxListTile(
                value: _isOver14,
                onChanged: (value) {
                  setState(() {
                    _isOver14 = value ?? false;
                  });
                },
                title: const Text(
                  '만 14세 이상입니다',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  '14세 미만은 법정대리인의 동의가 필요합니다',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              // 서비스 이용약관
              CheckboxListTile(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                title: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '서비스 이용약관',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showTermsDialog(context, '서비스 이용약관', _termsContent),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              // 개인정보 처리방침
              CheckboxListTile(
                value: _agreeToPrivacy,
                onChanged: (value) {
                  setState(() {
                    _agreeToPrivacy = value ?? false;
                  });
                },
                title: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '개인정보 처리방침',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showTermsDialog(context, '개인정보 처리방침', _privacyContent),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              const SizedBox(height: 16),

              // 디바이더
              const Divider(
                color: Colors.grey,
                height: 1,
                thickness: 0.5,
              ),

              const SizedBox(height: 12),

              // 전체 동의 체크박스
              CheckboxListTile(
                value: (_isOver14 && _agreeToTerms && _agreeToPrivacy),
                onChanged: (value) {
                  final agreeAll = value ?? false;
                  setState(() {
                    _isOver14 = agreeAll;
                    _agreeToTerms = agreeAll;
                    _agreeToPrivacy = agreeAll;
                  });
                },
                title: const Text(
                  '전체 약관에 동의합니다',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({'agreed': false}),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _canProceed
              ? () {
                  Navigator.of(context).pop({
                    'agreed': true,
                    'isOver14': _isOver14,
                    'agreeToTerms': _agreeToTerms,
                    'agreeToPrivacy': _agreeToPrivacy,
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canProceed ? Colors.blue : Colors.grey[300],
            foregroundColor: _canProceed ? Colors.white : Colors.grey[600],
          ),
          child: const Text('동의하고 계속'),
        ),
      ],
    );
  }
}