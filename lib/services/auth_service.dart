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
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
          // disconnect는 선택적으로 처리 (실패해도 무시)
          try {
            await googleSignIn.disconnect();
          } catch (disconnectError) {
            print('⚠️ Google disconnect 실패 (무시됨): $disconnectError');
          }
        } catch (googleError) {
          print('⚠️ Google Sign-In 로그아웃 실패 (무시됨): $googleError');
        }
      }
      
      // Supabase 로그아웃 (핵심)
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
      // 먼저 기존 프로필이 있는지 확인
      final existingProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingProfile == null) {
        // 새 프로필 생성
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'display_name': userMetaData?['full_name'] ?? userMetaData?['name'] ?? user.email?.split('@')[0],
          'avatar_url': userMetaData?['avatar_url'] ?? userMetaData?['picture'],
        });
        print('새 프로필 생성 완료: ${user.email}');
      } else {
        // 기존 프로필이 있으면 기본적으로 이메일만 업데이트
        // display_name과 avatar_url은 사용자가 직접 변경했을 수 있으므로 보존
        final updateData = <String, dynamic>{
          'email': user.email, // 이메일은 항상 최신으로 유지
        };
        
        // avatar_url이 null이고 Google에서 제공하는 이미지가 있다면 업데이트
        if (existingProfile['avatar_url'] == null && 
            (userMetaData?['avatar_url'] != null || userMetaData?['picture'] != null)) {
          updateData['avatar_url'] = userMetaData?['avatar_url'] ?? userMetaData?['picture'];
        }
        
        // display_name이 기본값(이메일 앞부분)과 동일하다면 Google 정보로 업데이트
        final currentDisplayName = existingProfile['display_name'];
        final emailPrefix = user.email?.split('@')[0];
        final googleDisplayName = userMetaData?['full_name'] ?? userMetaData?['name'];
        
        if (currentDisplayName == emailPrefix && googleDisplayName != null && googleDisplayName != emailPrefix) {
          updateData['display_name'] = googleDisplayName;
        }
        
        if (updateData.length > 1) { // 이메일 외에 다른 변경사항이 있을 때만 업데이트
          await supabase
              .from('profiles')
              .update(updateData)
              .eq('id', user.id);
          print('기존 프로필 업데이트 완료: ${user.email}');
        } else {
          print('기존 프로필 유지 (변경사항 없음): ${user.email}');
        }
      }
    } catch (e) {
      print('프로필 생성 중 오류: $e');
      // 중복 키 에러는 무시 (이미 존재한다는 뜻)
      if (!e.toString().contains('23505')) {
        throw Exception('프로필 생성에 실패했습니다: $e');
      }
    }
  }
}