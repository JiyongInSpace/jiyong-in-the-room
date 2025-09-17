import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/services/auth/auth_service.dart';
import 'package:jiyong_in_the_room/widgets/terms_agreement_dialog.dart';

class LoginDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onLoginSuccess;

  const LoginDialog({
    super.key,
    required this.title,
    required this.message,
    this.onLoginSuccess,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onLoginSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LoginDialog(
        title: title,
        message: message,
        onLoginSuccess: onLoginSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.login,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          Text(
            '로그인하면 다음 기능을 사용할 수 있어요:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem('✅ 클라우드에 안전하게 데이터 저장'),
          _buildFeatureItem('👥 친구들과 함께한 방탈출 기록'),
          _buildFeatureItem('📊 상세한 통계 및 분석'),
          _buildFeatureItem('🔄 여러 기기간 동기화'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('나중에'),
        ),
        ElevatedButton.icon(
          onPressed: () => _signInWithGoogle(context),
          icon: const Icon(
            Icons.account_circle,
            size: 20,
          ),
          label: const Text('Google로 로그인'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

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

      final result = await AuthService.signInWithGoogle();
      
      if (kDebugMode) {
        print('🚀 로그인 팝업에서 OAuth 결과: $result');
        print('🔍 현재 로그인 상태 (OAuth 완료 후): ${AuthService.isLoggedIn}');
        print('🔍 currentUser: ${AuthService.currentUser?.email}');
      }
      
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final success = result['success'] as bool? ?? false;
      final isNewUser = result['isNewUser'] as bool? ?? false;
      final needsTermsAgreement = result['needsTermsAgreement'] as bool? ?? false;

      if (success) {
        // 신규 사용자이고 약관 동의가 필요한 경우
        if (isNewUser && needsTermsAgreement && context.mounted) {
          if (kDebugMode) {
            print('📝 약관 동의 다이얼로그 표시 전 상태:');
            print('  - 로그인 상태: ${AuthService.isLoggedIn}');
            print('  - currentUser: ${AuthService.currentUser?.email}');
          }
          
          final termsResult = await showDialog<Map<String, dynamic>>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const TermsAgreementDialog(),
          );
          
          if (termsResult != null && (termsResult['agreed'] as bool? ?? false)) {
            if (kDebugMode) {
              print('📝 약관 동의 결과 받음: ${termsResult}');
              print('🔍 현재 로그인 상태: ${AuthService.isLoggedIn}');
            }
            
            // 약관 동의 저장
            await AuthService.saveTermsAgreement(
              isOver14: termsResult['isOver14'] as bool,
              agreeToTerms: termsResult['agreeToTerms'] as bool,
              agreeToPrivacy: termsResult['agreeToPrivacy'] as bool,
            );
            
            if (kDebugMode) {
              print('🔍 약관 저장 후 로그인 상태: ${AuthService.isLoggedIn}');
            }
            
            // 약관 동의 완료 후 프로필 생성
            try {
              await AuthService.completeSignUp();
              
              if (kDebugMode) {
                print('📝 신규 사용자 약관 동의 및 프로필 생성 완료');
              }
              
              // 프로필 생성 완료 후 잠시 대기 (상태 동기화)
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (signupError) {
              if (kDebugMode) {
                print('❌ completeSignUp 오류: $signupError');
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('회원가입 처리 중 오류: $signupError'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          } else {
            // 약관 동의하지 않으면 로그아웃
            await AuthService.signOut();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('약관 동의가 필요합니다'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        }
        
        if (context.mounted) {
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isNewUser ? '회원가입 완료!' : '로그인 완료!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 성공 콜백 먼저 실행 (데이터 새로고침)
          onLoginSuccess?.call();
          
          // 로그인 다이얼로그 닫기
          Navigator.of(context).pop(true);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 취소되었습니다'),
              backgroundColor: Colors.orange,
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
}