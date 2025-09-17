import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:jiyong_in_the_room/services/cache_service.dart';
import 'package:jiyong_in_the_room/services/connectivity_service.dart';
import 'package:jiyong_in_the_room/services/sync_queue_service.dart';
import 'package:jiyong_in_the_room/utils/uuid_helper.dart';

/// 로컬 우선 통합 스토리지 서비스
/// 
/// 핵심 원칙:
/// 1. 로컬 저장소가 진짜 데이터 (Source of Truth)
/// 2. DB는 백업 및 동기화용
/// 3. 즉시 UI 업데이트 (Optimistic UI)
/// 4. 백그라운드 동기화
class UnifiedStorageService {
  
  // ============ 일지 관리 ============
  
  /// 일지 목록 조회 (로컬 우선)
  static Future<List<DiaryEntry>> getDiaries({
    bool forceRefresh = false,
  }) async {
    return await CacheService.getOrFetch(
      CacheKeys.myDiaries,
      () async {
        if (AuthService.isLoggedIn) {
          // 회원: 로컬 우선, 백그라운드 동기화
          final localDiaries = LocalStorageService.getLocalDiaries();
          
          // 백그라운드에서 DB 동기화 확인
          _checkDiariesSync();
          
          return localDiaries;
        } else {
          // 비회원: 로컬만 사용
          return LocalStorageService.getLocalDiaries();
        }
      },
      duration: CacheService.shortCacheDuration,
      forceRefresh: forceRefresh,
    );
  }
  
  /// 일지 저장 (Optimistic UI)
  static Future<DiaryEntry> saveDiary(DiaryEntry entry, {List<int>? friendIds}) async {
    try {
      // 1. 즉시 로컬 저장 (UUID 자동 생성)
      final savedEntry = await LocalStorageService.saveDiary(entry);
      
      // 캐시 무효화
      CacheService.invalidatePattern('diaries');
      
      if (kDebugMode) {
        print('✅ 일지 로컬 저장 완료: ${savedEntry.uuid}');
      }
      
      // 2. 회원이면 동기화 큐에 추가
      if (AuthService.isLoggedIn) {
        await SyncQueueService.queueCreateDiary(savedEntry, friendIds: friendIds);
      }
      
      return savedEntry;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 일지 저장 실패: $e');
      }
      rethrow;
    }
  }
  
  /// 일지 수정
  static Future<DiaryEntry> updateDiary(DiaryEntry entry, {List<int>? friendIds}) async {
    try {
      // 1. 로컬 업데이트
      final updatedEntry = await LocalStorageService.updateDiary(entry);
      
      // 캐시 무효화
      CacheService.invalidatePattern('diaries');
      CacheService.invalidate(CacheKeys.diaryDetail(entry.uuid ?? ''));
      
      // 2. 회원이면 동기화 큐에 추가
      if (AuthService.isLoggedIn) {
        await SyncQueueService.queueUpdateDiary(updatedEntry, friendIds: friendIds);
      }
      
      return updatedEntry;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 일지 수정 실패: $e');
      }
      rethrow;
    }
  }
  
  /// 일지 삭제
  static Future<void> deleteDiary(DiaryEntry entry) async {
    try {
      // 1. 로컬 삭제
      await LocalStorageService.deleteDiary(entry.id);
      
      // 캐시 무효화
      CacheService.invalidatePattern('diaries');
      CacheService.invalidate(CacheKeys.diaryDetail(entry.uuid ?? ''));
      
      // 2. 회원이면 동기화 큐에 추가
      if (AuthService.isLoggedIn && entry.uuid != null) {
        await SyncQueueService.queueDeleteDiary(entry.uuid!, entry.id);
      }
      
      if (kDebugMode) {
        print('✅ 일지 삭제 완료: ${entry.uuid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 일지 삭제 실패: $e');
      }
      rethrow;
    }
  }
  
  // ============ 친구 관리 ============
  
  /// 친구 목록 조회 (로컬 우선)
  static Future<List<Friend>> getFriends({
    bool forceRefresh = false,
  }) async {
    return await CacheService.getOrFetch(
      CacheKeys.myFriends,
      () async {
        if (AuthService.isLoggedIn) {
          // 회원: 로컬 우선, 백그라운드 동기화
          final localFriends = LocalStorageService.getLocalFriends();
          
          // 백그라운드에서 DB 동기화 확인
          _checkFriendsSync();
          
          return localFriends;
        } else {
          // 비회원: 로컬만 사용
          return LocalStorageService.getLocalFriends();
        }
      },
      duration: CacheService.defaultCacheDuration,
      forceRefresh: forceRefresh,
    );
  }
  
  /// 친구 저장
  static Future<Friend> saveFriend({
    required String nickname,
    String? memo,
  }) async {
    try {
      final newFriend = Friend(
        nickname: nickname,
        memo: memo,
        addedAt: DateTime.now(),
      );
      
      // 1. 즉시 로컬 저장 (UUID 자동 생성)
      final savedFriend = await LocalStorageService.saveFriend(newFriend);
      
      // 캐시 무효화
      CacheService.invalidate(CacheKeys.myFriends);
      
      if (kDebugMode) {
        print('✅ 친구 로컬 저장 완료: ${savedFriend.uuid}');
      }
      
      // 2. 회원이면 동기화 큐에 추가
      if (AuthService.isLoggedIn) {
        await SyncQueueService.queueCreateFriend(savedFriend);
      }
      
      return savedFriend;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 저장 실패: $e');
      }
      rethrow;
    }
  }
  
  /// 친구 수정
  static Future<Friend> updateFriend(Friend friend, {
    String? newNickname,
    String? newMemo,
  }) async {
    try {
      // 1. 로컬 업데이트
      final updatedFriend = await LocalStorageService.updateFriend(
        friend.id!,
        nickname: newNickname ?? friend.nickname,
        memo: newMemo ?? friend.memo,
      );
      
      // 캐시 무효화
      CacheService.invalidate(CacheKeys.myFriends);
      CacheService.invalidate(CacheKeys.friendDetail(friend.uuid ?? ''));
      
      // 2. 회원이면 동기화 큐에 추가
      if (AuthService.isLoggedIn) {
        await SyncQueueService.queueUpdateFriend(updatedFriend);
      }
      
      return updatedFriend;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 수정 실패: $e');
      }
      rethrow;
    }
  }
  
  /// 친구 삭제
  static Future<void> deleteFriend(Friend friend) async {
    try {
      // 1. 로컬 삭제
      await LocalStorageService.deleteFriend(friend.id!);
      
      // 캐시 무효화
      CacheService.invalidate(CacheKeys.myFriends);
      CacheService.invalidate(CacheKeys.friendDetail(friend.uuid ?? ''));
      
      // 2. 회원이면 동기화 큐에 추가
      if (AuthService.isLoggedIn && friend.uuid != null) {
        await SyncQueueService.queueDeleteFriend(friend.uuid!, friend.id!);
      }
      
      if (kDebugMode) {
        print('✅ 친구 삭제 완료: ${friend.uuid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 삭제 실패: $e');
      }
      rethrow;
    }
  }
  
  // ============ 백그라운드 동기화 확인 메서드들 ============
  
  /// 일지 동기화 상태 확인
  static void _checkDiariesSync() {
    if (!ConnectivityService.isOnline || !AuthService.isLoggedIn) return;
    
    Future.microtask(() async {
      try {
        final queueStatus = await SyncQueueService.getQueueStatus();
        if (kDebugMode && queueStatus['pending'] > 0) {
          print('🔄 일지 동기화 대기 중: ${queueStatus['pending']}개');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ 일지 동기화 상태 확인 실패: $e');
        }
      }
    });
  }
  
  /// 친구 동기화 상태 확인
  static void _checkFriendsSync() {
    if (!ConnectivityService.isOnline || !AuthService.isLoggedIn) return;
    
    Future.microtask(() async {
      try {
        final queueStatus = await SyncQueueService.getQueueStatus();
        if (kDebugMode && queueStatus['pending'] > 0) {
          print('🔄 친구 동기화 대기 중: ${queueStatus['pending']}개');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ 친구 동기화 상태 확인 실패: $e');
        }
      }
    });
  }
  
  // ============ 유틸리티 메서드 ============
  
  /// 전체 캐시 새로고침
  static Future<void> refreshAll() async {
    CacheService.clear();
    await Future.wait([
      getDiaries(forceRefresh: true),
      getFriends(forceRefresh: true),
    ]);
  }
  
  /// 동기화 상태 확인
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final queueStatus = await SyncQueueService.getQueueStatus();
    
    return {
      'isOnline': ConnectivityService.isOnline,
      'isLoggedIn': AuthService.isLoggedIn,
      'cacheStats': CacheService.getStats(),
      'localDiaryCount': LocalStorageService.getLocalDiaries().length,
      'localFriendCount': LocalStorageService.getLocalFriends().length,
      'syncQueue': queueStatus,
    };
  }
}