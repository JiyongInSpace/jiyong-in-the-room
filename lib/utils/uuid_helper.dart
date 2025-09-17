import 'package:uuid/uuid.dart';

/// UUID 생성 및 관리를 위한 헬퍼 클래스
class UuidHelper {
  static const _uuid = Uuid();
  
  /// 새로운 UUID v4 생성
  static String generate() {
    return _uuid.v4();
  }
  
  /// UUID 검증
  static bool isValid(String? uuid) {
    if (uuid == null || uuid.isEmpty) return false;
    
    // UUID v4 형식 검증 (8-4-4-4-12)
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    
    return regex.hasMatch(uuid);
  }
}