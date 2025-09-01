import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';

/// 친구 관리 통합 서비스 클래스
/// 회원/비회원 상관없이 일관된 API 제공
class FriendService {
  
  /// 친구 추가 (회원/비회원 자동 구분)
  static Future<Friend> addFriend({
    required String nickname,
    String? memo,
  }) async {
    try {
      if (AuthService.isLoggedIn) {
        // 회원: DB에 저장
        return await DatabaseService.addFriend(
          nickname: nickname,
          memo: memo,
        );
      } else {
        // 비회원: 로컬에 저장
        return await LocalStorageService.saveFriend(Friend(
          nickname: nickname,
          memo: memo,
          addedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 추가 실패: $e');
      }
      rethrow;
    }
  }
  
  /// 친구 수정 (회원/비회원 자동 구분)
  static Future<Friend> updateFriend(
    Friend friend, {
    required String nickname,
    String? memo,
  }) async {
    try {
      if (AuthService.isLoggedIn) {
        // 회원: DB에서 수정
        return await DatabaseService.updateFriend(
          friend,
          newNickname: nickname,
          newMemo: memo,
        );
      } else {
        // 비회원: 로컬에서 수정
        final updatedFriend = Friend(
          id: friend.id,
          connectedUserId: friend.connectedUserId,
          user: friend.user,
          nickname: nickname,
          memo: memo,
          addedAt: friend.addedAt,
        );
        return await LocalStorageService.updateFriend(updatedFriend);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 수정 실패: $e');
      }
      rethrow;
    }
  }
  
  /// 친구 삭제 (회원/비회원 자동 구분)
  static Future<void> deleteFriend(Friend friend) async {
    try {
      if (AuthService.isLoggedIn) {
        // 회원: DB에서 삭제
        await DatabaseService.deleteFriend(friend);
      } else {
        // 비회원: 로컬에서 삭제
        if (friend.id != null) {
          await LocalStorageService.deleteFriend(friend.id!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 삭제 실패: $e');
      }
      rethrow;
    }
  }
  
  /// 친구 목록 조회 (회원/비회원 자동 구분)
  static Future<List<Friend>> getFriends() async {
    try {
      if (AuthService.isLoggedIn) {
        // 회원: DB에서 조회
        final friends = await DatabaseService.getMyFriends();
        return friends ?? [];
      } else {
        // 비회원: 로컬에서 조회
        return LocalStorageService.getLocalFriends();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 목록 조회 실패: $e');
      }
      return [];
    }
  }
  
  /// 친구 목록 페이징 조회 (회원 전용)
  static Future<List<Friend>> getFriendsPaginated({
    required int page,
    required int limit,
    String? searchQuery,
  }) async {
    if (!AuthService.isLoggedIn) {
      // 비회원: 로컬 데이터를 페이징 처리
      final allFriends = LocalStorageService.getLocalFriends();
      
      // 검색 필터 적용
      List<Friend> filteredFriends = allFriends;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredFriends = allFriends.where((friend) {
          return friend.nickname.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }
      
      // 페이징 적용
      final startIndex = page * limit;
      final endIndex = (startIndex + limit > filteredFriends.length) 
          ? filteredFriends.length 
          : startIndex + limit;
          
      if (startIndex < filteredFriends.length) {
        return filteredFriends.sublist(startIndex, endIndex);
      } else {
        return [];
      }
    }
    
    // 회원: DB에서 페이징 조회
    return await DatabaseService.getMyFriendsPaginated(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
    );
  }
  
  /// 친구 코드로 연동 (회원 전용)
  static Future<Friend> addFriendByCode(
    String userCode, {
    String? nickname,
    String? memo,
  }) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요한 기능입니다');
    }
    
    return await DatabaseService.addFriendByCode(
      userCode,
      nickname: nickname,
      memo: memo,
    );
  }
  
  /// 친구와 사용자 코드 연동 (회원 전용)
  static Future<Friend> linkFriendWithCode(Friend friend, String userCode) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요한 기능입니다');
    }
    
    return await DatabaseService.linkFriendWithCode(friend, userCode);
  }
  
  /// 친구 연동 해제 (회원 전용)
  static Future<Friend> unlinkFriend(Friend friend) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요한 기능입니다');
    }
    
    return await DatabaseService.unlinkFriend(friend);
  }
}