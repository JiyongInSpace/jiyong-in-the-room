import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';

class ProfileService {
  
  /// 프로필 이미지를 Supabase Storage에 업로드
  static Future<String> uploadProfileImage(File imageFile) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      // 파일 확장자 추출
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final fileName = 'profile$fileExtension';
      final filePath = '${user.id}/$fileName';
      
      // 기존 이미지가 있으면 삭제
      try {
        await supabase.storage.from('avatars').remove([filePath]);
      } catch (e) {
        // 파일이 없으면 무시
        print('기존 파일 삭제 시도: $e');
      }

      // 새 이미지 업로드
      final response = await supabase.storage
          .from('avatars')
          .upload(filePath, imageFile);

      // 공개 URL 생성
      final publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  /// 사용자 프로필 정보 업데이트
  static Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final updateData = <String, dynamic>{};
      
      if (displayName != null) {
        updateData['display_name'] = displayName;
      }
      
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toUtc().toIso8601String();
        
        await supabase
            .from('profiles')
            .update(updateData)
            .eq('id', user.id);
      }
    } catch (e) {
      throw Exception('프로필 업데이트 실패: $e');
    }
  }

  /// 현재 사용자의 최신 프로필 정보 가져오기
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      print('프로필 조회 실패: $e');
      return null;
    }
  }

  /// 프로필 이미지 삭제 (기본 이미지로 되돌리기)
  static Future<void> deleteProfileImage() async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      // Storage에서 이미지 파일들 삭제
      final filesToDelete = [
        '${user.id}/profile.jpg',
        '${user.id}/profile.jpeg', 
        '${user.id}/profile.png',
        '${user.id}/profile.webp',
      ];
      
      for (final filePath in filesToDelete) {
        try {
          await supabase.storage.from('avatars').remove([filePath]);
        } catch (e) {
          // 파일이 없으면 무시
        }
      }

      // 프로필에서 avatar_url 제거 (Google 기본 이미지로 되돌아감)
      await supabase
          .from('profiles')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);
      
    } catch (e) {
      throw Exception('프로필 이미지 삭제 실패: $e');
    }
  }
}