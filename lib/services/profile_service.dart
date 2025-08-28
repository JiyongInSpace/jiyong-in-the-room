import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';

class ProfileService {
  
  /// 프로필 이미지를 원형에 최적화하여 용량을 줄이는 메서드
  static Future<Uint8List> _optimizeProfileImage(File imageFile) async {
    // 원본 이미지 읽기
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) {
      throw Exception('이미지를 읽을 수 없습니다');
    }
    
    // 프로필 이미지 최적화 설정 (원형 프로필에 최적화)
    const int profileSize = 150; // 프로필 이미지는 150x150으로 충분 (더 작게)
    const int quality = 85; // 품질 85% (품질과 용량의 최적 균형)
    
    // 정사각형 크롭 (중앙 기준)
    int cropSize = originalImage.width < originalImage.height 
        ? originalImage.width 
        : originalImage.height;
    
    int offsetX = (originalImage.width - cropSize) ~/ 2;
    int offsetY = (originalImage.height - cropSize) ~/ 2;
    
    img.Image croppedImage = img.copyCrop(
      originalImage,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );
    
    // 프로필 크기로 리사이즈
    img.Image resizedImage = img.copyResize(
      croppedImage,
      width: profileSize,
      height: profileSize,
        interpolation: img.Interpolation.linear, // 고품질 보간법
      );
    
    // 메타데이터 제거 및 JPEG로 압축 (고품질 + 작은 용량)
    // EXIF 데이터도 자동 제거되어 추가 용량 절약
    final optimizedBytes = img.encodeJpg(
      resizedImage,
      quality: quality,
    );
    
    return Uint8List.fromList(optimizedBytes);
  }
  
  /// 프로필 이미지를 Supabase Storage에 업로드
  static Future<String> uploadProfileImage(File imageFile) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      // 프로필 이미지 최적화 (원형 크롭 + 용량 절약)
      final optimizedImageBytes = await _optimizeProfileImage(imageFile);
      
      // 최적화된 이미지는 JPEG 형식으로 저장 (호환성 + 압축)
      const fileName = 'profile.jpg';
      final filePath = '${user.id}/$fileName';
      
      // 기존 이미지들이 있으면 모두 삭제 (다양한 확장자 대응)
      final filesToDelete = [
        '${user.id}/profile.jpg',
        '${user.id}/profile.jpeg', 
        '${user.id}/profile.png',
        '${user.id}/profile.webp',
      ];
      
      for (final deleteFilePath in filesToDelete) {
        try {
          await supabase.storage.from('avatars').remove([deleteFilePath]);
        } catch (e) {
          // 파일이 없으면 무시
        }
      }

      // 최적화된 이미지 업로드
      await supabase.storage
          .from('avatars')
          .uploadBinary(filePath, optimizedImageBytes);

      // 공개 URL 생성 - timestamp를 추가하여 캐싱 문제 방지
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);
          
      // URL에 timestamp 쿼리 파라미터 추가하여 캐시 무효화
      final finalUrl = '$publicUrl?t=$timestamp';
      
      return finalUrl;
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