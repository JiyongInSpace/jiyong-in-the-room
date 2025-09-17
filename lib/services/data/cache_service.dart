import 'package:flutter/foundation.dart';

/// 메모리 캐시 엔트리
class CacheEntry<T> {
  final T data;
  final DateTime expiry;
  
  CacheEntry(this.data, Duration duration)
    : expiry = DateTime.now().add(duration);
  
  bool get isExpired => DateTime.now().isAfter(expiry);
  bool get isValid => !isExpired;
}

/// 간단한 메모리 캐시 서비스
/// 네트워크 요청을 줄이고 앱 성능을 향상시킴
class CacheService {
  static final Map<String, CacheEntry> _cache = {};
  
  /// 기본 캐시 만료 시간
  static const Duration defaultCacheDuration = Duration(seconds: 30);
  static const Duration longCacheDuration = Duration(minutes: 5);
  static const Duration shortCacheDuration = Duration(seconds: 10);
  
  /// 캐시에서 데이터 가져오기 또는 새로 fetch
  static Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration duration = defaultCacheDuration,
    bool forceRefresh = false,
  }) async {
    // 강제 새로고침이 아니면 캐시 확인
    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null && cached.isValid) {
        if (kDebugMode) {
          print('✅ 캐시 히트: $key');
        }
        return cached.data as T;
      }
    }
    
    if (kDebugMode) {
      print('🔄 캐시 미스 또는 만료: $key - 새로 가져오는 중...');
    }
    
    try {
      // 새로 데이터 가져오기
      final data = await fetcher();
      
      // 캐시에 저장
      _cache[key] = CacheEntry(data, duration);
      
      if (kDebugMode) {
        print('💾 캐시 저장: $key (${duration.inSeconds}초)');
      }
      
      return data;
    } catch (e) {
      // 에러 발생 시 캐시된 데이터가 있으면 반환 (만료되었어도)
      final cached = _cache[key];
      if (cached != null) {
        if (kDebugMode) {
          print('⚠️ 페치 실패, 만료된 캐시 사용: $key');
        }
        return cached.data as T;
      }
      
      rethrow;
    }
  }
  
  /// 특정 키의 캐시 삭제
  static void invalidate(String key) {
    _cache.remove(key);
    if (kDebugMode) {
      print('🗑️ 캐시 무효화: $key');
    }
  }
  
  /// 패턴과 일치하는 모든 캐시 삭제
  static void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    if (kDebugMode) {
      print('🗑️ 캐시 패턴 무효화: $pattern (${keysToRemove.length}개)');
    }
  }
  
  /// 전체 캐시 삭제
  static void clear() {
    final count = _cache.length;
    _cache.clear();
    if (kDebugMode) {
      print('🗑️ 전체 캐시 삭제: $count개');
    }
  }
  
  /// 만료된 캐시 엔트리 정리
  static void cleanup() {
    final before = _cache.length;
    _cache.removeWhere((key, entry) => entry.isExpired);
    final after = _cache.length;
    
    if (kDebugMode && before != after) {
      print('🧹 만료된 캐시 정리: ${before - after}개 제거');
    }
  }
  
  /// 캐시 상태 정보
  static Map<String, dynamic> getStats() {
    final total = _cache.length;
    final expired = _cache.values.where((e) => e.isExpired).length;
    final valid = total - expired;
    
    return {
      'total': total,
      'valid': valid,
      'expired': expired,
      'keys': _cache.keys.toList(),
    };
  }
}

/// 캐시 키 생성 헬퍼
class CacheKeys {
  // 일지 관련
  static const String myDiaries = 'my_diaries';
  static String diaryDetail(String uuid) => 'diary_$uuid';
  static String diariesWithFriend(String friendUuid) => 'diaries_friend_$friendUuid';
  
  // 친구 관련
  static const String myFriends = 'my_friends';
  static String friendDetail(String uuid) => 'friend_$uuid';
  
  // 테마/카페 관련
  static const String allThemes = 'all_themes';
  static const String allCafes = 'all_cafes';
  static String themeSearch(String query) => 'theme_search_$query';
  
  // 통계 관련
  static const String homeStats = 'home_stats';
  static const String friendStats = 'friend_stats';
}