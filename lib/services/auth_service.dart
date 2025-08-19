import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';

class AuthService {
  // 현재 사용자 상태
  static User? get currentUser => supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Google 로그인 (Google Sign-In 플러그인 사용)
  static Future<bool> signInWithGoogle() async {
    try {
      print('🔍 Debug: kIsWeb = $kIsWeb, Platform.isAndroid = ${!kIsWeb}');
      
      if (kIsWeb) {
        // 웹에서는 기존 방식 사용
        final bool success = await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://localhost:3000',
        );
        return success;
      } else {
        // 모바일에서는 Google Sign-In 플러그인 사용
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
        );
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return false;
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? accessToken = googleAuth.accessToken;
        final String? idToken = googleAuth.idToken;
        
        if (accessToken == null) {
          throw Exception('Google Access Token을 가져올 수 없습니다');
        }
        
        // Supabase에 Google 토큰으로 로그인
        final AuthResponse response = await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken!,
          accessToken: accessToken,
        );
        
        if (response.user != null) {
          await _createUserProfile();
          return true;
        }
        
        return false;
      }
    } catch (e) {
      print('❌ Google 로그인 오류: $e');
      throw Exception('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // 로그아웃
  static Future<void> signOut() async {
    try {
      // Google Sign-In 로그아웃 (모바일에서만)
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }
      
      // Supabase 로그아웃
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // 인증 상태 변경 리스너
  static Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // 현재 사용자 프로필 가져오기 또는 생성
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (!isLoggedIn) return null;
    
    try {
      // 먼저 기존 프로필 확인
      var response = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      // 프로필이 없으면 생성
      if (response == null) {
        print('프로필이 없어서 새로 생성합니다.');
        await _createUserProfile();
        
        // 다시 조회
        response = await supabase
            .from('profiles')
            .select()
            .eq('id', currentUser!.id)
            .maybeSingle();
      }
      
      return response;
    } catch (e) {
      print('프로필 조회 중 오류: $e');
      return null;
    }
  }

  // 사용자 프로필 생성
  static Future<void> _createUserProfile() async {
    if (!isLoggedIn) return;
    
    final user = currentUser!;
    final userMetaData = user.userMetadata;
    
    try {
      // UPSERT 사용 (존재하면 업데이트, 없으면 생성)
      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': userMetaData?['full_name'] ?? userMetaData?['name'] ?? user.email?.split('@')[0],
        'avatar_url': userMetaData?['avatar_url'] ?? userMetaData?['picture'],
      });
      
      print('프로필 생성/업데이트 완료: ${user.email}');
    } catch (e) {
      print('프로필 생성 중 오류: $e');
      // 중복 키 에러는 무시 (이미 존재한다는 뜻)
      if (!e.toString().contains('23505')) {
        throw Exception('프로필 생성에 실패했습니다: $e');
      }
    }
  }
}