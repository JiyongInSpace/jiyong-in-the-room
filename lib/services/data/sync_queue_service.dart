import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth/auth_service.dart';
import 'package:jiyong_in_the_room/services/data/database_service.dart';
import 'package:jiyong_in_the_room/services/core/connectivity_service.dart';

/// 동기화 작업 타입
enum SyncOperation {
  createDiary,
  updateDiary,
  deleteDiary,
  createFriend,
  updateFriend,
  deleteFriend,
}

/// 동기화 작업 우선순위
enum SyncPriority {
  low,      // 삭제 작업
  normal,   // 수정 작업
  high,     // 생성 작업
}

/// 동기화 큐 아이템
class SyncQueueItem {
  final String id;
  final SyncOperation operation;
  final SyncPriority priority;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? lastAttempt;
  final int attemptCount;
  final DateTime? nextRetry;
  
  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.priority,
    required this.data,
    required this.createdAt,
    this.lastAttempt,
    this.attemptCount = 0,
    this.nextRetry,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation.name,
    'priority': priority.name,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'lastAttempt': lastAttempt?.toIso8601String(),
    'attemptCount': attemptCount,
    'nextRetry': nextRetry?.toIso8601String(),
  };
  
  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
    id: json['id'],
    operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
    priority: SyncPriority.values.firstWhere((e) => e.name == json['priority']),
    data: Map<String, dynamic>.from(json['data']),
    createdAt: DateTime.parse(json['createdAt']),
    lastAttempt: json['lastAttempt'] != null ? DateTime.parse(json['lastAttempt']) : null,
    attemptCount: json['attemptCount'] ?? 0,
    nextRetry: json['nextRetry'] != null ? DateTime.parse(json['nextRetry']) : null,
  );
  
  /// 재시도 아이템 생성 (지수 백오프 적용)
  SyncQueueItem withRetry() {
    final newAttemptCount = attemptCount + 1;
    final backoffSeconds = [1, 5, 15, 60, 300][newAttemptCount.clamp(0, 4)]; // 1초, 5초, 15초, 1분, 5분
    
    return SyncQueueItem(
      id: id,
      operation: operation,
      priority: priority,
      data: data,
      createdAt: createdAt,
      lastAttempt: DateTime.now(),
      attemptCount: newAttemptCount,
      nextRetry: DateTime.now().add(Duration(seconds: backoffSeconds)),
    );
  }
  
  /// 재시도 가능한지 확인
  bool get canRetry => attemptCount < 5 && (nextRetry == null || DateTime.now().isAfter(nextRetry!));
  
  /// 만료 확인 (24시간 후 만료)
  bool get isExpired => DateTime.now().difference(createdAt).inHours > 24;
}

/// 동기화 큐 서비스
/// 
/// 주요 기능:
/// 1. 오프라인 작업을 큐에 저장
/// 2. 온라인 상태 시 자동 동기화
/// 3. 실패 시 지수 백오프로 재시도
/// 4. 우선순위 기반 처리
class SyncQueueService {
  static const String _boxName = 'sync_queue';
  static Box<String>? _queueBox;
  static Timer? _syncTimer;
  static bool _isProcessing = false;
  
  /// 초기화
  static Future<void> initialize() async {
    try {
      _queueBox = await Hive.openBox<String>(_boxName);
      
      // 연결 상태 변화 감지하여 자동 동기화
      ConnectivityService.connectionStreamStatic.listen((isOnline) {
        if (isOnline && AuthService.isLoggedIn) {
          _startPeriodicSync();
        } else {
          _stopPeriodicSync();
        }
      });
      
      // 로그인 상태에서 즉시 동기화 시작
      if (ConnectivityService.isOnline && AuthService.isLoggedIn) {
        _startPeriodicSync();
      }
      
      if (kDebugMode) {
        print('🔄 SyncQueueService 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SyncQueueService 초기화 실패: $e');
      }
    }
  }
  
  /// 주기적 동기화 시작 (30초마다)
  static void _startPeriodicSync() {
    _stopPeriodicSync(); // 기존 타이머 정리
    
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      processQueue();
    });
    
    // 즉시 한 번 실행
    processQueue();
    
    if (kDebugMode) {
      print('🔄 주기적 동기화 시작 (30초 간격)');
    }
  }
  
  /// 주기적 동기화 중지
  static void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    
    if (kDebugMode) {
      print('⏸️ 주기적 동기화 중지');
    }
  }
  
  /// 일지 생성 큐에 추가
  static Future<void> queueCreateDiary(DiaryEntry diary, {List<int>? friendIds}) async {
    await _addToQueue(SyncQueueItem(
      id: 'diary_create_${diary.uuid}',
      operation: SyncOperation.createDiary,
      priority: SyncPriority.high,
      data: {
        'diary': diary.toJson(),
        'friendIds': friendIds,
      },
      createdAt: DateTime.now(),
    ));
  }
  
  /// 일지 수정 큐에 추가
  static Future<void> queueUpdateDiary(DiaryEntry diary, {List<int>? friendIds}) async {
    await _addToQueue(SyncQueueItem(
      id: 'diary_update_${diary.uuid}',
      operation: SyncOperation.updateDiary,
      priority: SyncPriority.normal,
      data: {
        'diary': diary.toJson(),
        'friendIds': friendIds,
      },
      createdAt: DateTime.now(),
    ));
  }
  
  /// 일지 삭제 큐에 추가
  static Future<void> queueDeleteDiary(String uuid, int legacyId) async {
    await _addToQueue(SyncQueueItem(
      id: 'diary_delete_$uuid',
      operation: SyncOperation.deleteDiary,
      priority: SyncPriority.low,
      data: {
        'uuid': uuid,
        'legacyId': legacyId,
      },
      createdAt: DateTime.now(),
    ));
  }
  
  /// 친구 생성 큐에 추가
  static Future<void> queueCreateFriend(Friend friend) async {
    await _addToQueue(SyncQueueItem(
      id: 'friend_create_${friend.uuid}',
      operation: SyncOperation.createFriend,
      priority: SyncPriority.high,
      data: {
        'friend': friend.toJson(),
      },
      createdAt: DateTime.now(),
    ));
  }
  
  /// 친구 수정 큐에 추가
  static Future<void> queueUpdateFriend(Friend friend) async {
    await _addToQueue(SyncQueueItem(
      id: 'friend_update_${friend.uuid}',
      operation: SyncOperation.updateFriend,
      priority: SyncPriority.normal,
      data: {
        'friend': friend.toJson(),
      },
      createdAt: DateTime.now(),
    ));
  }
  
  /// 친구 삭제 큐에 추가
  static Future<void> queueDeleteFriend(String uuid, int legacyId) async {
    await _addToQueue(SyncQueueItem(
      id: 'friend_delete_$uuid',
      operation: SyncOperation.deleteFriend,
      priority: SyncPriority.low,
      data: {
        'uuid': uuid,
        'legacyId': legacyId,
      },
      createdAt: DateTime.now(),
    ));
  }
  
  /// 큐에 아이템 추가
  static Future<void> _addToQueue(SyncQueueItem item) async {
    if (_queueBox == null) return;
    
    try {
      await _queueBox!.put(item.id, jsonEncode(item.toJson()));
      
      if (kDebugMode) {
        print('📝 동기화 큐 추가: ${item.operation.name} (${item.id})');
      }
      
      // 온라인이면 즉시 처리 시도
      if (ConnectivityService.isOnline && AuthService.isLoggedIn) {
        processQueue();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 동기화 큐 추가 실패: $e');
      }
    }
  }
  
  /// 큐 처리
  static Future<void> processQueue() async {
    if (_queueBox == null || _isProcessing || !ConnectivityService.isOnline || !AuthService.isLoggedIn) {
      return;
    }
    
    _isProcessing = true;
    
    try {
      final items = await _getQueueItems();
      if (items.isEmpty) return;
      
      if (kDebugMode) {
        print('🔄 동기화 큐 처리 시작: ${items.length}개 아이템');
      }
      
      // 우선순위 및 생성 시간 기준 정렬
      items.sort((a, b) {
        final priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });
      
      for (final item in items) {
        if (!item.canRetry) {
          if (kDebugMode) {
            print('⏭️ 재시도 대기 중: ${item.id}');
          }
          continue;
        }
        
        if (item.isExpired) {
          await _removeFromQueue(item.id);
          if (kDebugMode) {
            print('🗑️ 만료된 아이템 제거: ${item.id}');
          }
          continue;
        }
        
        final success = await _processItem(item);
        if (success) {
          await _removeFromQueue(item.id);
          if (kDebugMode) {
            print('✅ 동기화 성공: ${item.id}');
          }
        } else {
          // 재시도 카운터 업데이트
          final retryItem = item.withRetry();
          await _queueBox!.put(retryItem.id, jsonEncode(retryItem.toJson()));
          if (kDebugMode) {
            print('🔄 재시도 스케줄: ${item.id} (${retryItem.attemptCount}/${5})');
          }
        }
      }
      
      if (kDebugMode) {
        print('✅ 동기화 큐 처리 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 동기화 큐 처리 실패: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }
  
  /// 큐 아이템들 가져오기
  static Future<List<SyncQueueItem>> _getQueueItems() async {
    if (_queueBox == null) return [];
    
    final items = <SyncQueueItem>[];
    for (final key in _queueBox!.keys) {
      try {
        final jsonString = _queueBox!.get(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          items.add(SyncQueueItem.fromJson(json));
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ 큐 아이템 파싱 실패: $key - $e');
        }
        // 파싱 실패한 아이템은 제거
        await _queueBox!.delete(key);
      }
    }
    
    return items;
  }
  
  /// 개별 아이템 처리
  static Future<bool> _processItem(SyncQueueItem item) async {
    try {
      switch (item.operation) {
        case SyncOperation.createDiary:
          final diaryJson = item.data['diary'] as Map<String, dynamic>;
          final diary = DiaryEntry.fromJson(diaryJson);
          final friendIds = item.data['friendIds'] as List<int>?;
          await DatabaseService.addDiaryEntry(diary, friendIds: friendIds);
          break;
          
        case SyncOperation.updateDiary:
          final diaryJson = item.data['diary'] as Map<String, dynamic>;
          final diary = DiaryEntry.fromJson(diaryJson);
          final friendIds = item.data['friendIds'] as List<int>?;
          await DatabaseService.updateDiaryEntry(diary, friendIds: friendIds);
          break;
          
        case SyncOperation.deleteDiary:
          final legacyId = item.data['legacyId'] as int;
          await DatabaseService.deleteDiaryEntry(legacyId);
          break;
          
        case SyncOperation.createFriend:
          final friendJson = item.data['friend'] as Map<String, dynamic>;
          final friend = Friend.fromJson(friendJson);
          await DatabaseService.addFriend(
            nickname: friend.nickname,
            memo: friend.memo,
          );
          break;
          
        case SyncOperation.updateFriend:
          final friendJson = item.data['friend'] as Map<String, dynamic>;
          final friend = Friend.fromJson(friendJson);
          await DatabaseService.updateFriend(
            friend,
            newNickname: friend.nickname,
            newMemo: friend.memo,
          );
          break;
          
        case SyncOperation.deleteFriend:
          final legacyId = item.data['legacyId'] as int;
          // Friend 객체 생성 (삭제용)
          final friend = Friend(
            id: legacyId,
            nickname: '',
            addedAt: DateTime.now(),
          );
          await DatabaseService.deleteFriend(friend);
          break;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 아이템 처리 실패: ${item.id} - $e');
      }
      return false;
    }
  }
  
  /// 큐에서 아이템 제거
  static Future<void> _removeFromQueue(String id) async {
    if (_queueBox == null) return;
    
    try {
      await _queueBox!.delete(id);
    } catch (e) {
      if (kDebugMode) {
        print('❌ 큐 아이템 제거 실패: $id - $e');
      }
    }
  }
  
  /// 큐 상태 정보
  static Future<Map<String, dynamic>> getQueueStatus() async {
    if (_queueBox == null) return {};
    
    final items = await _getQueueItems();
    final pending = items.where((item) => item.canRetry && !item.isExpired).length;
    final waiting = items.where((item) => !item.canRetry && !item.isExpired).length;
    final expired = items.where((item) => item.isExpired).length;
    
    return {
      'total': items.length,
      'pending': pending,
      'waiting': waiting,
      'expired': expired,
      'isProcessing': _isProcessing,
      'isOnline': ConnectivityService.isOnline,
      'isLoggedIn': AuthService.isLoggedIn,
    };
  }
  
  /// 모든 큐 정리 (주로 디버깅용)
  static Future<void> clearQueue() async {
    if (_queueBox == null) return;
    
    try {
      await _queueBox!.clear();
      if (kDebugMode) {
        print('🗑️ 동기화 큐 전체 삭제');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 큐 삭제 실패: $e');
      }
    }
  }
  
  /// 만료된 아이템 정리
  static Future<void> cleanupExpired() async {
    if (_queueBox == null) return;
    
    try {
      final items = await _getQueueItems();
      final expiredItems = items.where((item) => item.isExpired).toList();
      
      for (final item in expiredItems) {
        await _removeFromQueue(item.id);
      }
      
      if (kDebugMode && expiredItems.isNotEmpty) {
        print('🧹 만료된 큐 아이템 ${expiredItems.length}개 정리');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 만료 아이템 정리 실패: $e');
      }
    }
  }
  
  /// 서비스 종료
  static Future<void> dispose() async {
    _stopPeriodicSync();
    _isProcessing = false;
    
    // 마지막으로 한 번 더 큐 처리 시도
    if (ConnectivityService.isOnline && AuthService.isLoggedIn) {
      await processQueue();
    }
    
    await _queueBox?.close();
    _queueBox = null;
    
    if (kDebugMode) {
      print('🔄 SyncQueueService 종료');
    }
  }
}