import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';

class AuthService {
  static const List<String> _scopes = ['email', 'profile'];

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );

  // 현재 사용자 상태
  static User? get currentUser => supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Google 로그인
  static Future<AuthResponse> signInWithGoogle() async {
    try {
      // Google 로그인 수행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google 로그인이 취소되었습니다.');
      }

      // Google 인증 토큰 획득
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('Google 액세스 토큰을 가져올 수 없습니다.');
      }

      if (idToken == null) {
        throw Exception('Google ID 토큰을 가져올 수 없습니다.');
      }

      // Supabase로 Google OAuth 로그인
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 프로필 정보 자동 생성/업데이트
      if (response.user != null) {
        await _updateUserProfile(response.user!);
      }

      return response;
    } catch (e) {
      throw Exception('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // 로그아웃
  static Future<void> signOut() async {
    try {
      // Google 로그아웃
      await _googleSignIn.signOut();
      
      // Supabase 로그아웃
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // 사용자 프로필 정보 업데이트
  static Future<void> _updateUserProfile(User user) async {
    try {
      final Map<String, dynamic> profileData = {
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
        'avatar_url': user.userMetadata?['avatar_url'],
      };

      // profiles 테이블에 upsert (없으면 생성, 있으면 업데이트)
      await supabase.from('profiles').upsert(profileData);
    } catch (e) {
      print('프로필 업데이트 중 오류: $e');
      // 프로필 업데이트 실패는 로그인을 방해하지 않음
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
      print('프로필 조회 중 오류: $e');
      return null;
    }
  }
}