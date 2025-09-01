import 'package:hive_flutter/hive_flutter.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:flutter/foundation.dart';

/// 로컬 저장소 서비스
/// 비회원 사용자의 데이터를 Hive를 사용하여 로컬에 저장/관리
/// 
/// 마이그레이션을 쉽게 하기 위해 DB와 동일한 구조 사용
class LocalStorageService {
  static const String _diaryBoxName = 'local_diaries';
  static const String _friendBoxName = 'local_friends';
  static const String _settingsBoxName = 'local_settings';
  
  static late Box<Map> _diaryBox;
  static late Box<Map> _friendBox;
  static late Box<Map> _settingsBox;
  
  /// 로컬 저장소 초기화
  static Future<void> initialize() async {
    try {
      _diaryBox = await Hive.openBox<Map>(_diaryBoxName);
      _friendBox = await Hive.openBox<Map>(_friendBoxName);
      _settingsBox = await Hive.openBox<Map>(_settingsBoxName);
      
      if (kDebugMode) {
        print('📦 로컬 저장소 초기화 완료');
        print('  - 저장된 일지: ${_diaryBox.length}개');
        print('  - 저장된 친구: ${_friendBox.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 저장소 초기화 실패: $e');
      }
    }
  }
  
  /// 로컬 일지 ID 생성 (큰 양수 사용하여 DB ID와 구분)
  static int _generateLocalDiaryId() {
    final existingIds = _diaryBox.keys.cast<int>().toList();
    if (existingIds.isEmpty) return 1000000; // 백만부터 시작 (DB와 충돌 방지)
    
    // 가장 큰 ID + 1
    final maxId = existingIds.reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
  
  /// 로컬 친구 ID 생성 (Hive 32비트 범위 내에서 생성)
  static int _generateLocalFriendId() {
    final existingIds = _friendBox.keys.cast<int>().toList();
    if (existingIds.isEmpty) return 2000000; // 2백만부터 시작 (일지ID와 구분)
    
    // 가장 큰 ID + 1 (단, 32비트 부호 있는 정수 범위 내에서)
    final maxId = existingIds.reduce((a, b) => a > b ? a : b);
    final nextId = maxId + 1;
    
    // 32비트 부호 있는 정수 최대값 확인 (2,147,483,647)
    if (nextId > 2147483647) {
      throw Exception('로컬 친구 ID 한계 초과');
    }
    
    return nextId;
  }
  
  
  // ============ 일지 관련 메서드 ============
  
  /// 로컬에 일지 저장
  static Future<DiaryEntry> saveDiary(DiaryEntry entry) async {
    try {
      // 로컬 ID 생성 (큰 양수 사용)
      final localId = _generateLocalDiaryId();
      
      // 로컬용 엔트리 생성 (ID만 변경, 나머지는 동일)
      final localEntry = entry.copyWith(id: localId);
      
      // JSON으로 변환하여 저장 (마이그레이션 용이)
      final jsonData = localEntry.toJson();
      await _diaryBox.put(localId, jsonData);
      
      if (kDebugMode) {
        print('💾 로컬 일지 저장 완료: ID=$localId');
      }
      
      return localEntry;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 일지 저장 실패: $e');
      }
      throw Exception('로컬 저장 실패: $e');
    }
  }
  
  /// 로컬 일지 목록 조회
  static List<DiaryEntry> getLocalDiaries() {
    try {
      final diaries = <DiaryEntry>[];
      
      for (var key in _diaryBox.keys) {
        final data = _diaryBox.get(key);
        if (data != null) {
          try {
            // Map<dynamic, dynamic>을 Map<String, dynamic>으로 안전하게 변환
            final jsonData = _convertToStringMap(data);
            diaries.add(DiaryEntry.fromJson(jsonData));
          } catch (e) {
            if (kDebugMode) {
              print('❌ 일지 데이터 변환 실패 (key: $key): $e');
            }
            continue; // 에러가 난 항목은 건너뛰고 계속 진행
          }
        }
      }
      
      // 날짜 기준 내림차순 정렬
      diaries.sort((a, b) => b.date.compareTo(a.date));
      
      if (kDebugMode) {
        print('📋 로컬 일지 ${diaries.length}개 조회');
      }
      
      return diaries;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 일지 조회 실패: $e');
      }
      return [];
    }
  }
  
  /// Map<dynamic, dynamic>을 Map<String, dynamic>으로 안전하게 변환
  static Map<String, dynamic> _convertToStringMap(Map<dynamic, dynamic> source) {
    final result = <String, dynamic>{};
    
    source.forEach((key, value) {
      final stringKey = key.toString();
      
      if (value is Map) {
        // 중첩된 Map도 재귀적으로 변환
        result[stringKey] = _convertToStringMap(Map<dynamic, dynamic>.from(value));
      } else if (value is List) {
        // List 안의 Map들도 변환
        result[stringKey] = value.map((item) {
          if (item is Map) {
            return _convertToStringMap(Map<dynamic, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        result[stringKey] = value;
      }
    });
    
    return result;
  }
  
  /// 로컬 일지 수정
  static Future<DiaryEntry> updateDiary(DiaryEntry entry) async {
    try {
      if (entry.id < 1000000) {
        throw Exception('로컬 일지가 아닙니다');
      }
      
      final jsonData = entry.toJson();
      await _diaryBox.put(entry.id, jsonData);
      
      if (kDebugMode) {
        print('✏️ 로컬 일지 수정 완료: ID=${entry.id}');
      }
      
      return entry;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 일지 수정 실패: $e');
      }
      throw Exception('로컬 수정 실패: $e');
    }
  }
  
  /// 로컬 일지 삭제
  static Future<void> deleteDiary(int id) async {
    try {
      if (kDebugMode) {
        print('🗑️ 로컬 일지 삭제 시도: ID=$id');
        print('📦 삭제 전 저장된 키들: ${_diaryBox.keys.toList()}');
      }
      
      final existsBefore = _diaryBox.containsKey(id);
      await _diaryBox.delete(id);
      final existsAfter = _diaryBox.containsKey(id);
      
      if (kDebugMode) {
        print('🗑️ 로컬 일지 삭제 완료: ID=$id');
        print('  - 삭제 전 존재: $existsBefore');
        print('  - 삭제 후 존재: $existsAfter');
        print('📦 삭제 후 저장된 키들: ${_diaryBox.keys.toList()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 일지 삭제 실패: $e');
      }
      throw Exception('로컬 삭제 실패: $e');
    }
  }
  
  // ============ 친구 관련 메서드 ============
  
  /// 로컬에 친구 저장
  static Future<Friend> saveFriend(Friend friend) async {
    try {
      // 로컬 친구 ID 생성 (32비트 범위 내)
      final localId = _generateLocalFriendId();
      
      // 로컬용 친구 생성
      final localFriend = Friend(
        id: localId,
        nickname: friend.nickname,
        memo: friend.memo,
        connectedUserId: null, // 로컬은 항상 미연동
        addedAt: DateTime.now(),
      );
      
      // Map으로 변환하여 저장
      final data = {
        'id': localFriend.id,
        'nickname': localFriend.nickname,
        'memo': localFriend.memo,
        'connected_user_id': localFriend.connectedUserId,
        'added_at': localFriend.addedAt.toIso8601String(),
      };
      
      await _friendBox.put(localId, data);
      
      if (kDebugMode) {
        print('💾 로컬 친구 저장 완료: $localId');
      }
      
      return localFriend;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 친구 저장 실패: $e');
      }
      throw Exception('로컬 저장 실패: $e');
    }
  }
  
  /// 로컬 친구 목록 조회
  static List<Friend> getLocalFriends() {
    try {
      final friends = <Friend>[];
      
      for (var key in _friendBox.keys) {
        final data = _friendBox.get(key);
        if (data != null) {
          friends.add(Friend(
            id: data['id'] as int?,
            nickname: data['nickname'] as String,
            memo: data['memo'] as String?,
            connectedUserId: data['connected_user_id'] as String?,
            addedAt: DateTime.parse(data['added_at'] as String),
          ));
        }
      }
      
      // 이름순 정렬
      friends.sort((a, b) => a.nickname.compareTo(b.nickname));
      
      if (kDebugMode) {
        print('📋 로컬 친구 ${friends.length}명 조회');
      }
      
      return friends;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 친구 조회 실패: $e');
      }
      return [];
    }
  }
  
  /// 로컬 친구 수정
  static Future<Friend> updateFriend(Friend friend) async {
    try {
      if (friend.id == null) {
        throw Exception('친구 ID가 없습니다');
      }
      
      final data = {
        'id': friend.id,
        'nickname': friend.nickname,
        'memo': friend.memo,
        'connected_user_id': friend.connectedUserId,
        'added_at': friend.addedAt.toIso8601String(),
      };
      
      await _friendBox.put(friend.id!, data);
      
      if (kDebugMode) {
        print('✏️ 로컬 친구 수정 완료: ${friend.id}');
      }
      
      return friend;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 친구 수정 실패: $e');
      }
      throw Exception('로컬 수정 실패: $e');
    }
  }
  
  /// 로컬 친구 삭제
  static Future<void> deleteFriend(int friendId) async {
    try {
      await _friendBox.delete(friendId);
      
      if (kDebugMode) {
        print('🗑️ 로컬 친구 삭제 완료: $friendId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 친구 삭제 실패: $e');
      }
      throw Exception('로컬 삭제 실패: $e');
    }
  }
  
  /// 로컬 친구만 존재하는지 확인
  static bool hasLocalFriends() {
    return _friendBox.isNotEmpty;
  }
  
  // ============ 마이그레이션 관련 메서드 ============
  
  /// 마이그레이션을 위한 로컬 데이터 준비
  /// DB 저장 형식과 동일하게 변환
  static Map<String, dynamic> prepareForMigration() {
    try {
      final diaries = getLocalDiaries();
      final friends = getLocalFriends();
      
      // 친구 ID 매핑을 위한 Map 생성 (일지와 친구 연결에 사용)
      final friendsWithMapping = <Map<String, dynamic>>[];
      for (final friend in friends) {
        friendsWithMapping.add({
          'local_id': friend.id,
          'nickname': friend.nickname,
          'memo': friend.memo,
          'connected_user_id': friend.connectedUserId,
          'added_at': friend.addedAt.toIso8601String(),
        });
      }
      
      // 일지 데이터 준비 (친구 ID는 로컬 ID 그대로 유지)
      final diariesWithMapping = <Map<String, dynamic>>[];
      for (final diary in diaries) {
        final diaryJson = diary.toJson();
        diariesWithMapping.add({
          ...diaryJson,
          'local_id': diary.id, // 원본 로컬 ID 보존
          'id': null, // DB에서 새로 생성될 ID
          // friends 배열은 로컬 ID 그대로 유지 (나중에 매핑)
        });
      }
      
      // DB 형식으로 변환
      final migrationData = {
        'diaries': diariesWithMapping,
        'friends': friendsWithMapping,
      };
      
      if (kDebugMode) {
        print('📦 마이그레이션 데이터 준비 완료');
        print('  - 일지: ${diaries.length}개');
        print('  - 친구: ${friends.length}개');
      }
      
      return migrationData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 마이그레이션 데이터 준비 실패: $e');
      }
      throw Exception('마이그레이션 준비 실패: $e');
    }
  }
  
  /// 마이그레이션 완료 후 로컬 데이터 삭제
  static Future<void> clearLocalData() async {
    try {
      await _diaryBox.clear();
      await _friendBox.clear();
      
      if (kDebugMode) {
        print('🧹 로컬 데이터 삭제 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로컬 데이터 삭제 실패: $e');
      }
      throw Exception('로컬 데이터 삭제 실패: $e');
    }
  }
  
  /// 로컬 데이터 존재 여부 확인
  static bool hasLocalData() {
    return _diaryBox.isNotEmpty || _friendBox.isNotEmpty;
  }
  
  /// 로컬 일지만 존재하는지 확인 (마이그레이션용)
  static bool hasLocalDiaries() {
    return _diaryBox.isNotEmpty;
  }
  
  /// 로컬 데이터 통계
  static Map<String, int> getLocalDataStats() {
    return {
      'diaries': _diaryBox.length,
      'friends': _friendBox.length,
    };
  }
}