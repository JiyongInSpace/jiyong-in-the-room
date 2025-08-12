import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // 현재 사용자 상태
  static User? get currentUser => supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Google 로그인
  static Future<bool> signInWithGoogle() async {
    try {
      // 플랫폼에 따라 다른 방법 사용
      if (kIsWeb) {
        // 웹에서는 Supabase OAuth 사용 
        final bool success = await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://localhost:3000',
        );
        
        return success;
      } else {
        // 모바일에서는 OAuth 사용 (추후 구현)
        final bool success = await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
        );
        
        return success;
      }
    } catch (e) {
      throw Exception('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // 로그아웃
  static Future<void> signOut() async {
    try {
      // Supabase 로그아웃
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // 인증 상태 변경 리스너
  static Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // 현재 사용자 프로필 가져오기
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (!isLoggedIn) return null;
    
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      // TODO: 로깅 프레임워크로 교체
      // print('프로필 조회 중 오류: $e');
      return null;
    }
  }
}