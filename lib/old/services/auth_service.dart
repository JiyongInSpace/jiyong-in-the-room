import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';

class AuthService {
  // 현재 사용자 상태
  static User? get currentUser => supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Google 로그인 (Google Sign-In 플러그인 사용)
  // 반환값: {'success': bool, 'isNewUser': bool?, 'needsTermsAgreement': bool?}
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🔍 Debug: kIsWeb = $kIsWeb, Platform.isAndroid = ${!kIsWeb}');
      
      if (kIsWeb) {
        // 웹에서는 기존 방식 사용
        final bool success = await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://localhost:3000',
        );
        
        if (success) {
          final result = await _checkUserStatus();
          return {
            'success': true,
            'isNewUser': result['isNewUser'],
            'needsTermsAgreement': result['needsTermsAgreement'],
          };
        }
        
        return {'success': false};
      } else {
        // 모바일에서는 Google Sign-In 플러그인 사용
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
        );
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return {'success': false};
        
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
          // 프로필 생성은 약관 동의 후에 진행
          final result = await _checkUserStatus();
          return {
            'success': true,
            'isNewUser': result['isNewUser'],
            'needsTermsAgreement': result['needsTermsAgreement'],
          };
        }
        
        return {'success': false};
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
      
      // 약관 동의 상태 삭제
      try {
        await LocalStorageService.clearTermsAgreement();
      } catch (termsError) {
        print('⚠️ 약관 동의 상태 삭제 실패 (무시됨): $termsError');
      }
      
      // Supabase 로그아웃 (핵심)
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // 인증 상태 변경 리스너
  static Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // 현재 사용자 프로필 가져오기 (프로필 없으면 로그아웃)
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (!isLoggedIn) return null;
    
    try {
      print('🔍 getCurrentUserProfile 호출됨 - 프로필 조회');
      
      // 기존 프로필 확인
      var response = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      if (response == null) {
        print('⚠️ 프로필이 없음 - 불완전한 계정 상태 감지');
        
        // 약관 동의 상태 확인
        final hasAgreedToTerms = LocalStorageService.hasAgreedToRequiredTerms();
        
        if (hasAgreedToTerms) {
          // 약관 동의는 했지만 프로필이 없는 경우 - 프로필 생성 시도
          print('🔧 약관 동의 완료상태에서 프로필 없음 - 프로필 생성 재시도');
          try {
            await _createUserProfile();
            
            // 프로필 생성 후 다시 조회
            response = await supabase
                .from('profiles')
                .select()
                .eq('id', currentUser!.id)
                .maybeSingle();
            
            if (response != null) {
              print('✅ 프로필 재생성 성공');
              return response;
            }
          } catch (profileError) {
            print('❌ 프로필 재생성 실패: $profileError');
          }
        } else {
          // 약관 동의가 없고 프로필도 없는 경우
          // 하지만 신규 사용자일 수 있으므로 바로 정리하지 않고 경고만 출력
          print('⚠️ 프로필 없음 - 약관 동의 대기 중이거나 불완전한 계정');
          return null;
        }
        
        // 약관 동의는 했지만 프로필 생성도 실패한 경우에만 정리
        print('🧹 프로필 생성 실패 - 불완전한 계정 정리 시작');
        await checkAndCleanupIncompleteAccount();
        return null;
      } else {
        print('✅ 기존 프로필 발견');
      }
      
      return response;
    } catch (e) {
      print('❌ 프로필 조회 중 오류: $e');
      return null;
    }
  }

  // 사용자 프로필 생성
  static Future<void> _createUserProfile() async {
    if (!isLoggedIn) return;
    
    final user = currentUser!;
    final userMetaData = user.userMetadata;
    
    print('🔧 _createUserProfile 호출됨 - 사용자: ${user.email}');
    
    try {
      // 먼저 기존 프로필이 있는지 확인
      final existingProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingProfile == null) {
        // 새 프로필 생성
        print('🆕 새 프로필을 profiles 테이블에 생성 중...');
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'display_name': userMetaData?['full_name'] ?? userMetaData?['name'] ?? user.email?.split('@')[0],
          'avatar_url': userMetaData?['avatar_url'] ?? userMetaData?['picture'],
        });
        print('✅ 새 프로필 생성 완료: ${user.email}');
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

  // 사용자 상태 확인 (프로필 생성은 하지 않음)
  static Future<Map<String, dynamic>> _checkUserStatus() async {
    if (!isLoggedIn) {
      return {'isNewUser': false, 'needsTermsAgreement': false};
    }
    
    try {
      // 기존 프로필이 있는지 확인 (생성하지 않음)
      final existingProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      final isNewUser = existingProfile == null;
      
      // 약관 동의 상태 확인
      bool needsTermsAgreement = false;
      if (isNewUser) {
        // 신규 사용자는 약관 동의가 필요한지 확인
        needsTermsAgreement = !LocalStorageService.hasAgreedToRequiredTerms();
      }
      
      return {
        'isNewUser': isNewUser,
        'needsTermsAgreement': needsTermsAgreement,
      };
    } catch (e) {
      print('❌ 사용자 상태 확인 오류: $e');
      return {'isNewUser': false, 'needsTermsAgreement': false};
    }
  }
  
  // 약관 동의 완료 후 프로필 생성
  static Future<void> completeSignUp() async {
    print('🎯 completeSignUp 호출됨 - 약관 동의 완료 후 프로필 생성');
    print('🔍 현재 로그인 상태: $isLoggedIn');
    
    if (!isLoggedIn) {
      print('❌ 로그인 상태가 아님 - currentUser: ${currentUser?.email}');
      throw Exception('로그인 상태가 아닙니다');
    }
    
    try {
      await _createUserProfile();
      print('✅ 회원가입 완료 - 프로필 생성됨');
      
      // 생성 확인
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      if (profile != null) {
        print('✅ 프로필 생성 검증 성공: ${profile['email']}');
      } else {
        print('❌ 프로필 생성 검증 실패 - 데이터가 없음');
      }
    } catch (e) {
      print('❌ 회원가입 완료 처리 오류: $e');
      print('📍 오류 스택: ${StackTrace.current}');
      throw Exception('회원가입 완료 처리 실패: $e');
    }
  }
  
  // 약관 동의 저장
  static Future<void> saveTermsAgreement({
    required bool isOver14,
    required bool agreeToTerms,
    required bool agreeToPrivacy,
  }) async {
    await LocalStorageService.saveTermsAgreement(
      isOver14: isOver14,
      agreeToTerms: agreeToTerms,
      agreeToPrivacy: agreeToPrivacy,
    );
  }
  
  // 필수 약관 동의 여부 확인
  static bool hasAgreedToRequiredTerms() {
    return LocalStorageService.hasAgreedToRequiredTerms();
  }
  
  // 약관 동의 상태 조회
  static Map<String, dynamic>? getTermsAgreement() {
    return LocalStorageService.getTermsAgreement();
  }
  
  // 불완전한 계정 상태 체크 및 정리 (약관 동의 완료 후 프로필 생성 실패 시에만)
  static Future<void> checkAndCleanupIncompleteAccount() async {
    if (!isLoggedIn) return;
    
    try {
      print('🔍 불완전한 계정 상태 체크 시작...');
      
      // 프로필 존재 여부 확인
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      // 약관 동의 상태 확인
      final hasAgreedToTerms = LocalStorageService.hasAgreedToRequiredTerms();
      
      // 계정 상태 로그 출력
      print('📊 계정 상태:');
      print('  - 프로필 존재: ${profile != null}');
      print('  - 약관 동의: $hasAgreedToTerms');
      print('  - 사용자 이메일: ${currentUser?.email}');
      
      // 약관 동의는 했지만 프로필 생성이 실패한 경우만 정리
      if (profile == null && hasAgreedToTerms) {
        print('🧹 약관 동의 완료했지만 프로필 생성 실패 - 계정 정리 중...');
        print('  📧 정리 대상: ${currentUser?.email}');
        await signOut();
        print('✅ 불완전한 계정 정리 완료');
      } else if (profile == null && !hasAgreedToTerms) {
        // 약관 동의도 없고 프로필도 없는 경우는 정상적인 신규 사용자일 수 있음 - 정리하지 않음
        print('⚠️ 신규 사용자 또는 약관 동의 대기 중 - 정리하지 않음');
      } else {
        print('✅ 정상적인 계정 상태');
      }
    } catch (e) {
      print('❌ 계정 상태 체크 실패: $e');
      // 에러가 발생해도 함부로 로그아웃하지 않음 (신규 사용자일 수 있음)
      print('⚠️ 에러 상황에서 안전을 위해 로그아웃하지 않음');
    }
  }
}