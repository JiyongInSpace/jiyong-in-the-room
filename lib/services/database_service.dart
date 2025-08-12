import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';

class DatabaseService {
  // 테마 관련 메서드들
  
  /// 모든 테마 목록 가져오기
  static Future<List<EscapeTheme>> getAllThemes() async {
    try {
      final response = await supabase
          .from('escape_themes')
          .select('''
            id, name, difficulty, time_limit_minutes, genre, theme_image_url,
            escape_cafes!inner(id, name, address, contact, logo_url)
          ''');

      return (response as List).map((json) {
        final themeData = Map<String, dynamic>.from(json);
        final cafeData = themeData['escape_cafes'] as Map<String, dynamic>;
        
        return EscapeTheme(
          id: themeData['id'],
          name: themeData['name'],
          cafe: EscapeCafe.fromJson(cafeData),
          difficulty: themeData['difficulty'],
          timeLimit: themeData['time_limit_minutes'] != null 
              ? Duration(minutes: themeData['time_limit_minutes'])
              : null,
          genre: themeData['genre'] != null 
              ? List<String>.from(themeData['genre'])
              : null,
          themeImageUrl: themeData['theme_image_url'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('테마 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// 새 카페 추가
  static Future<EscapeCafe> createCafe(EscapeCafe cafe) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final response = await supabase
          .from('escape_cafes')
          .insert(cafe.toJson())
          .select()
          .single();

      return EscapeCafe.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('카페 생성 실패: $e');
      }
      rethrow;
    }
  }

  /// 새 테마 추가
  static Future<EscapeTheme> createTheme(EscapeTheme theme) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      // 먼저 카페가 존재하는지 확인하고, 없으면 생성
      final cafeExists = await supabase
          .from('escape_cafes')
          .select('id')
          .eq('id', theme.cafe.id)
          .maybeSingle();

      if (cafeExists == null) {
        await createCafe(theme.cafe);
      }

      // 테마 생성
      final themeData = theme.toJson();
      themeData.remove('cafe'); // 중첩 객체 제거
      
      final response = await supabase
          .from('escape_themes')
          .insert(themeData)
          .select('''
            id, name, difficulty, time_limit_minutes, genre, theme_image_url,
            escape_cafes!inner(id, name, address, contact, logo_url)
          ''')
          .single();

      final cafeData = response['escape_cafes'] as Map<String, dynamic>;
      
      return EscapeTheme(
        id: response['id'],
        name: response['name'],
        cafe: EscapeCafe.fromJson(cafeData),
        difficulty: response['difficulty'],
        timeLimit: response['time_limit_minutes'] != null 
            ? Duration(minutes: response['time_limit_minutes'])
            : null,
        genre: response['genre'] != null 
            ? List<String>.from(response['genre'])
            : null,
        themeImageUrl: response['theme_image_url'],
      );
    } catch (e) {
      if (kDebugMode) {
        print('테마 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 친구 관련 메서드들
  
  /// 내 친구 목록 가져오기
  static Future<List<Friend>> getMyFriends() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      final response = await supabase
          .from('friends')
          .select('''
            connected, nickname, memo, added_at,
            users!friends_connected_fkey(id, name, email, avatar_url, joined_at)
          ''')
          .eq('user_id', currentUserId);

      return (response as List).map((json) {
        final userData = json['users'] as Map<String, dynamic>?;
        
        return Friend(
          connected: json['connected'],
          user: userData != null ? User.fromJson(userData) : null,
          nickname: json['nickname'],
          memo: json['memo'],
          addedAt: DateTime.parse(json['added_at']),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('친구 목록 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// 새 친구 추가
  static Future<Friend> addFriend(Friend friend) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      final friendData = {
        'user_id': currentUserId,
        'connected': friend.connected,
        'nickname': friend.nickname,
        'memo': friend.memo,
        'added_at': friend.addedAt.toIso8601String(),
      };

      final response = await supabase
          .from('friends')
          .insert(friendData)
          .select('''
            connected, nickname, memo, added_at,
            users!friends_connected_fkey(id, name, email, avatar_url, joined_at)
          ''')
          .single();

      final userData = response['users'] as Map<String, dynamic>?;
      
      return Friend(
        connected: response['connected'],
        user: userData != null ? User.fromJson(userData) : null,
        nickname: response['nickname'],
        memo: response['memo'],
        addedAt: DateTime.parse(response['added_at']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('친구 추가 실패: $e');
      }
      rethrow;
    }
  }

  /// 친구 정보 수정
  static Future<Friend> updateFriend(Friend friend, {
    String? newNickname,
    String? newMemo,
  }) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      final updateData = <String, dynamic>{};
      
      if (newNickname != null) updateData['nickname'] = newNickname;
      if (newMemo != null) updateData['memo'] = newMemo;

      if (updateData.isEmpty) return friend;

      final response = await supabase
          .from('friends')
          .update(updateData)
          .eq('user_id', currentUserId)
          .eq('nickname', friend.nickname) // 기존 닉네임으로 식별
          .select('''
            connected, nickname, memo, added_at,
            users!friends_connected_fkey(id, name, email, avatar_url, joined_at)
          ''')
          .single();

      final userData = response['users'] as Map<String, dynamic>?;
      
      return Friend(
        connected: response['connected'],
        user: userData != null ? User.fromJson(userData) : null,
        nickname: response['nickname'],
        memo: response['memo'],
        addedAt: DateTime.parse(response['added_at']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('친구 정보 수정 실패: $e');
      }
      rethrow;
    }
  }

  /// 친구 삭제
  static Future<void> deleteFriend(Friend friend) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      await supabase
          .from('friends')
          .delete()
          .eq('user_id', currentUserId)
          .eq('nickname', friend.nickname);
    } catch (e) {
      if (kDebugMode) {
        print('친구 삭제 실패: $e');
      }
      rethrow;
    }
  }
}