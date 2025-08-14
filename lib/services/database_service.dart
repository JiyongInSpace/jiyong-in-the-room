import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/utils/supabase.dart';
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
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
          cafeId: themeData['cafe_id'],
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
          .eq('id', theme.cafe?.id ?? 0)
          .maybeSingle();

      if (cafeExists == null && theme.cafe != null) {
        await createCafe(theme.cafe!);
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
        cafeId: response['cafe_id'],
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
          .select('id, connected_user_id, nickname, memo, added_at')
          .eq('user_id', currentUserId);

      return (response as List).map((json) {
        return Friend(
          id: json['id'] as String,
          connectedUserId: json['connected_user_id'],
          user: null, // 일단 null로 처리, 추후 연결된 사용자 정보 로드 가능
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
        'connected_user_id': friend.connectedUserId,
        'nickname': friend.nickname,
        'memo': friend.memo,
        'added_at': friend.addedAt.toUtc().toIso8601String(),
      };

      final response = await supabase
          .from('friends')
          .insert(friendData)
          .select('id, connected_user_id, nickname, memo, added_at')
          .single();

      return Friend(
        id: response['id'] as String,
        connectedUserId: response['connected_user_id'],
        user: null, // 일단 null로 처리
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
          .eq('id', friend.id!) // ID로 식별
          .select('id, connected_user_id, nickname, memo, added_at')
          .single();

      return Friend(
        id: response['id'] as String,
        connectedUserId: response['connected_user_id'],
        user: null, // 일단 null로 처리
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
          .eq('id', friend.id!);
    } catch (e) {
      if (kDebugMode) {
        print('친구 삭제 실패: $e');
      }
      rethrow;
    }
  }

  // 일지 관련 메서드들
  
  /// 내 일지 목록 가져오기 (테마, 카페, 참여자 정보 포함)
  static Future<List<DiaryEntry>> getMyDiaryEntries() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      final response = await supabase
          .from('diary_entries')
          .select('''
            *,
            escape_themes!inner(
              id, name, difficulty, time_limit_minutes, genre, theme_image_url, cafe_id,
              escape_cafes!inner(id, name, address, contact, logo_url)
            )
          ''')
          .eq('user_id', currentUserId)
          .order('date', ascending: false);

      return (response as List).map((json) {
        final entryData = Map<String, dynamic>.from(json);
        final themeData = entryData['escape_themes'] as Map<String, dynamic>;
        
        // EscapeTheme 생성
        final theme = EscapeTheme(
          id: themeData['id'],
          name: themeData['name'],
          cafeId: themeData['cafe_id'],
          cafe: EscapeCafe.fromJson(themeData['escape_cafes'] as Map<String, dynamic>),
          difficulty: themeData['difficulty'],
          timeLimit: themeData['time_limit_minutes'] != null 
              ? Duration(minutes: themeData['time_limit_minutes'])
              : null,
          genre: themeData['genre'] != null 
              ? List<String>.from(themeData['genre'])
              : null,
          themeImageUrl: themeData['theme_image_url'],
        );

        // DiaryEntry 생성 (theme 포함, friends는 별도 조회 필요)
        return DiaryEntry(
          id: entryData['id'],
          userId: entryData['user_id'],
          themeId: entryData['theme_id'],
          theme: theme,
          date: DateTime.parse(entryData['date']),
          friends: null, // 별도 메서드로 조회
          memo: entryData['memo'],
          rating: entryData['rating'] != null ? (entryData['rating'] as num).toDouble() : null,
          escaped: entryData['escaped'],
          hintUsedCount: entryData['hint_used_count'],
          timeTaken: entryData['time_taken_minutes'] != null 
              ? Duration(minutes: entryData['time_taken_minutes'])
              : null,
          photos: entryData['photos'] != null 
              ? List<String>.from(entryData['photos'])
              : null,
          createdAt: DateTime.parse(entryData['created_at']),
          updatedAt: DateTime.parse(entryData['updated_at']),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('일지 목록 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// 일지의 참여자 목록 가져오기
  static Future<List<Friend>> getDiaryParticipants(int diaryEntryId) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final response = await supabase
          .from('diary_entry_participants')
          .select('''
            user_id,
            profiles!inner(id, name, email, avatar_url)
          ''')
          .eq('diary_entry_id', diaryEntryId);

      return (response as List).map((json) {
        final profile = json['profiles'] as Map<String, dynamic>;
        
        // 참여자를 Friend 객체로 변환 (실제 사용자 정보 포함)
        return Friend(
          id: json['user_id'], // 참여자의 user_id를 Friend의 id로 사용
          connectedUserId: json['user_id'],
          user: User(
            id: profile['id'],
            name: profile['name'],
            email: profile['email'],
            avatarUrl: profile['avatar_url'],
            joinedAt: DateTime.now(), // 실제로는 profiles에서 가져와야 함
          ),
          addedAt: DateTime.now(),
          nickname: profile['name'], // 기본적으로 실제 이름을 닉네임으로 사용
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('참여자 목록 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// 새 일지 추가
  static Future<DiaryEntry> addDiaryEntry(DiaryEntry entry, {List<String>? friendIds}) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 일지 데이터 준비
      final entryData = entry.toJson();
      entryData['user_id'] = currentUserId; // 현재 사용자로 설정
      entryData.remove('id'); // DB에서 자동 생성 (SERIAL)
      entryData.remove('created_at'); // DB에서 자동 생성
      entryData.remove('updated_at'); // DB에서 자동 생성
      
      // 일지 저장
      final response = await supabase
          .from('diary_entries')
          .insert(entryData)
          .select('''
            *,
            escape_themes!inner(
              id, name, difficulty, time_limit_minutes, genre, theme_image_url, cafe_id,
              escape_cafes!inner(id, name, address, contact, logo_url)
            )
          ''')
          .single();

      final savedEntry = DiaryEntry.fromJson(response);
      
      // 참여자 관계 저장
      if (friendIds != null && friendIds.isNotEmpty) {
        final participantRelations = friendIds.map((friendId) => {
          'diary_entry_id': savedEntry.id,
          'user_id': friendId,
        }).toList();
        
        await supabase
            .from('diary_entry_participants')
            .insert(participantRelations);
      }

      return savedEntry;
    } catch (e) {
      if (kDebugMode) {
        print('일지 추가 실패: $e');
      }
      rethrow;
    }
  }

  /// 일지 수정
  static Future<DiaryEntry> updateDiaryEntry(DiaryEntry entry, {List<String>? friendIds}) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 일지 데이터 준비
      final entryData = entry.toJson();
      entryData.remove('id');
      entryData.remove('user_id');
      entryData.remove('created_at');
      entryData.remove('updated_at'); // DB에서 자동 갱신
      
      // 일지 수정
      final response = await supabase
          .from('diary_entries')
          .update(entryData)
          .eq('id', entry.id)
          .eq('user_id', currentUserId) // 보안: 자신의 일지만 수정 가능
          .select('''
            *,
            escape_themes!inner(
              id, name, difficulty, time_limit_minutes, genre, theme_image_url, cafe_id,
              escape_cafes!inner(id, name, address, contact, logo_url)
            )
          ''')
          .single();

      // 기존 참여자 관계 삭제 후 새로 추가
      if (friendIds != null) {
        await supabase
            .from('diary_entry_participants')
            .delete()
            .eq('diary_entry_id', entry.id);
            
        if (friendIds.isNotEmpty) {
          final participantRelations = friendIds.map((friendId) => {
            'diary_entry_id': entry.id,
            'user_id': friendId,
          }).toList();
          
          await supabase
              .from('diary_entry_participants')
              .insert(participantRelations);
        }
      }

      return DiaryEntry.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('일지 수정 실패: $e');
      }
      rethrow;
    }
  }

  /// 일지 삭제
  static Future<void> deleteDiaryEntry(int entryId) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 참여자 관계 먼저 삭제 (CASCADE로 자동 삭제되지만 명시적으로)
      await supabase
          .from('diary_entry_participants')
          .delete()
          .eq('diary_entry_id', entryId);
      
      // 일지 삭제
      await supabase
          .from('diary_entries')
          .delete()
          .eq('id', entryId)
          .eq('user_id', currentUserId); // 보안: 자신의 일지만 삭제 가능
    } catch (e) {
      if (kDebugMode) {
        print('일지 삭제 실패: $e');
      }
      rethrow;
    }
  }
}