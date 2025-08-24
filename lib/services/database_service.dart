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
          id: json['id'] as int,
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
        id: response['id'] as int,
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
        id: response['id'] as int,
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
  
  /// 내 일지 목록 조회 (개인 일지만)
  static Future<List<DiaryEntry>> getMyDiaryEntries() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 내가 작성한 일지만 조회 (단순화)
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

      List<DiaryEntry> diaryEntries = [];
      
      for (var json in response as List) {
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

        // 해당 일지의 참여자 정보 조회
        final participants = await getDiaryParticipants(entryData['id']);

        // DiaryEntry 생성
        diaryEntries.add(DiaryEntry(
          id: entryData['id'],
          userId: entryData['user_id'],
          themeId: entryData['theme_id'],
          theme: theme,
          date: DateTime.parse(entryData['date']),
          friends: participants.isNotEmpty ? participants : null,
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
        ));
      }
      
      return diaryEntries;
    } catch (e) {
      if (kDebugMode) {
        print('일지 목록 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// 내 일지 목록 페이징 조회 (개인 일지만)
  static Future<List<DiaryEntry>> getMyDiaryEntriesPaginated({
    int page = 0,
    int limit = 10,
    String? searchQuery,
    List<int>? filterFriendIds,
  }) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 친구 필터가 있는 경우, 해당 친구와 함께한 일지 ID 조회
      Set<int>? filteredDiaryIds;
      if (filterFriendIds != null && filterFriendIds.isNotEmpty) {
        Set<int> allFilteredIds = {};
        
        for (int friendId in filterFriendIds) {
          final friendParticipantResponse = await supabase
              .from('diary_entry_participants')
              .select('diary_entry_id')
              .eq('friend_id', friendId);
          
          final friendDiaryIds = friendParticipantResponse
              .map((row) => row['diary_entry_id'] as int)
              .toSet();
          
          // 첫 번째 친구면 전체 집합으로 초기화, 이후는 교집합
          if (allFilteredIds.isEmpty) {
            allFilteredIds = friendDiaryIds;
          } else {
            allFilteredIds = allFilteredIds.intersection(friendDiaryIds);
          }
        }
        
        filteredDiaryIds = allFilteredIds;
        if (filteredDiaryIds.isEmpty) {
          return [];
        }
      }
      
      // 내가 작성한 일지 조회 쿼리 구성
      var queryBuilder = supabase
          .from('diary_entries')
          .select('''
            *,
            escape_themes!inner(
              id, name, difficulty, time_limit_minutes, genre, theme_image_url, cafe_id,
              escape_cafes!inner(id, name, address, contact, logo_url)
            )
          ''')
          .eq('user_id', currentUserId);
      
      // 친구 필터 적용
      if (filteredDiaryIds != null) {
        queryBuilder = queryBuilder.inFilter('id', filteredDiaryIds.toList());
      }
      
      final query = queryBuilder.order('date', ascending: false);
      
      // 검색어와 페이징 적용
      final List<dynamic> response;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // 검색어가 있는 경우: 모든 데이터를 가져온 후 필터링
        final allResponse = await query;
        final searchLower = searchQuery.toLowerCase();
        final filteredResponse = (allResponse as List).where((item) {
          final themeData = item['escape_themes'] as Map<String, dynamic>;
          final cafeData = themeData['escape_cafes'] as Map<String, dynamic>;
          
          final themeName = (themeData['name'] as String).toLowerCase();
          final cafeName = (cafeData['name'] as String).toLowerCase();
          
          return themeName.contains(searchLower) || cafeName.contains(searchLower);
        }).toList();
        
        // 페이징 적용
        final startIndex = page * limit;
        final endIndex = (startIndex + limit).clamp(0, filteredResponse.length);
        response = filteredResponse.sublist(
          startIndex.clamp(0, filteredResponse.length), 
          endIndex
        );
      } else {
        // 검색어가 없는 경우: DB 레벨에서 페이징
        response = await query.range(page * limit, (page + 1) * limit - 1);
      }

      List<DiaryEntry> diaryEntries = [];
      
      for (var json in response as List) {
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

        // 해당 일지의 참여자 정보 조회
        final participants = await getDiaryParticipants(entryData['id']);

        // DiaryEntry 생성
        diaryEntries.add(DiaryEntry(
          id: entryData['id'],
          userId: entryData['user_id'],
          themeId: entryData['theme_id'],
          theme: theme,
          date: DateTime.parse(entryData['date']),
          friends: participants.isNotEmpty ? participants : null,
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
        ));
      }
      
      return diaryEntries;
    } catch (e) {
      if (kDebugMode) {
        print('페이징된 일지 목록 조회 실패: $e');
      }
      rethrow;
    }
  }


  /// 일지의 참여자 목록 가져오기 (실시간 프로필 정보 반영)
  static Future<List<Friend>> getDiaryParticipants(int diaryEntryId) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      // 새로 생성한 뷰를 사용하여 최신 프로필 정보 가져오기
      final response = await supabase
          .from('diary_participants_with_details')
          .select('*')
          .eq('diary_entry_id', diaryEntryId);

      List<Friend> participants = [];
      
      for (var json in response as List) {
        if (json['user_id'] != null) {
          // 연결된 사용자 (실제 프로필 있음) - 실시간 프로필 정보 사용
          participants.add(Friend(
            id: null, // 연결된 사용자의 경우 Friend.id는 null (friend_id가 없으므로)
            connectedUserId: json['user_id'],
            user: User(
              id: json['user_id'],
              name: json['profile_display_name'] ?? '알 수 없는 사용자',
              email: json['profile_email'] ?? '',
              avatarUrl: json['profile_avatar_url'],
              joinedAt: DateTime.now(),
            ),
            addedAt: DateTime.now(),
            nickname: json['profile_display_name'] ?? '알 수 없는 사용자',
          ));
        } else if (json['friend_id'] != null) {
          // 연결되지 않은 친구 (nickname 사용)
          participants.add(Friend(
            id: json['friend_table_id'] as int?,
            connectedUserId: json['friend_connected_user_id'],
            user: null,
            addedAt: DateTime.now(),
            nickname: json['friend_nickname'] ?? '알 수 없는 친구',
          ));
        }
      }
      
      return participants;
    } catch (e) {
      if (kDebugMode) {
        print('참여자 목록 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// 새 일지 추가
  static Future<DiaryEntry> addDiaryEntry(DiaryEntry entry, {List<int>? friendIds}) async {
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
      List<Map<String, dynamic>> participantRelations = [];
      
      // 1. 본인(작성자)을 참여자로 추가
      participantRelations.add({
        'diary_entry_id': savedEntry.id,
        'user_id': currentUserId,
        'friend_id': null,
      });
      
      // 2. 선택된 친구들을 참여자로 추가
      if (friendIds != null && friendIds.isNotEmpty) {
        for (int friendId in friendIds) {
          // friendId가 실제 user_id인지 friends 테이블의 ID인지 확인
          final friend = await supabase
              .from('friends')
              .select('id, connected_user_id')
              .eq('id', friendId)
              .maybeSingle();
              
          if (friend != null) {
            participantRelations.add({
              'diary_entry_id': savedEntry.id,
              'user_id': friend['connected_user_id'], // null일 수 있음
              'friend_id': friend['id'], // friends 테이블의 ID
            });
          }
        }
      }
      
      // participants 테이블에 저장
      if (participantRelations.isNotEmpty) {
        await supabase
            .from('diary_entry_participants')
            .insert(participantRelations);
      }

      // 친구 정보를 포함한 완전한 일지 데이터 반환
      final entryWithFriends = savedEntry.copyWith(
        friends: await getDiaryParticipants(savedEntry.id),
      );
      
      return entryWithFriends;
    } catch (e) {
      if (kDebugMode) {
        print('일지 추가 실패: $e');
      }
      rethrow;
    }
  }

  /// 일지 수정
  static Future<DiaryEntry> updateDiaryEntry(DiaryEntry entry, {List<int>? friendIds}) async {
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

      final updatedEntry = DiaryEntry.fromJson(response);
      
      // 기존 참여자 관계 삭제 후 새로 추가
      await supabase
          .from('diary_entry_participants')
          .delete()
          .eq('diary_entry_id', entry.id);
          
      // 참여자 관계 재구성
      List<Map<String, dynamic>> participantRelations = [];
      
      // 1. 본인(작성자)을 참여자로 추가
      participantRelations.add({
        'diary_entry_id': updatedEntry.id,
        'user_id': currentUserId,
        'friend_id': null,
      });
      
      // 2. 선택된 친구들을 참여자로 추가
      if (friendIds != null && friendIds.isNotEmpty) {
        for (int friendId in friendIds) {
          final friend = await supabase
              .from('friends')
              .select('id, connected_user_id')
              .eq('id', friendId)
              .maybeSingle();
              
          if (friend != null) {
            participantRelations.add({
              'diary_entry_id': updatedEntry.id,
              'user_id': friend['connected_user_id'],
              'friend_id': friend['id'],
            });
          }
        }
      }
      
      // participants 테이블에 저장
      if (participantRelations.isNotEmpty) {
        await supabase
            .from('diary_entry_participants')
            .insert(participantRelations);
      }
      
      // 친구 정보를 포함한 완전한 일지 데이터 반환
      final entryWithFriends = updatedEntry.copyWith(
        friends: await getDiaryParticipants(updatedEntry.id),
      );
      
      return entryWithFriends;
    } catch (e) {
      if (kDebugMode) {
        print('일지 수정 실패: $e');
      }
      rethrow;
    }
  }

  /// 일지 삭제 - 작성자면 전체 삭제, 참여자면 자신만 참여자에서 제거
  static Future<void> deleteDiaryEntry(int entryId) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 해당 일지의 작성자 확인
      final diaryResponse = await supabase
          .from('diary_entries')
          .select('user_id')
          .eq('id', entryId)
          .maybeSingle();
          
      if (diaryResponse == null) {
        throw Exception('일지를 찾을 수 없습니다');
      }
      
      final authorId = diaryResponse['user_id'] as String;
      
      if (authorId == currentUserId) {
        // 작성자인 경우: 일지 전체 삭제 (participants도 CASCADE로 함께 삭제됨)
        await supabase
            .from('diary_entries')
            .delete()
            .eq('id', entryId)
            .eq('user_id', currentUserId);
            
        if (kDebugMode) {
          print('✅ 일지 전체 삭제 완료 (작성자)');
        }
      } else {
        // 참여자인 경우: 자신만 참여자 목록에서 제거
        final deleteResult = await supabase
            .from('diary_entry_participants')
            .delete()
            .eq('diary_entry_id', entryId)
            .eq('user_id', currentUserId);
            
        if (kDebugMode) {
          print('✅ 참여자 목록에서 제거 완료 (참여자)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 일지 삭제/참여 해제 실패: $e');
      }
      rethrow;
    }
  }

  // 사용자 코드 관련 메서드들

  /// 내 사용자 코드 조회
  static Future<String?> getMyUserCode() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      final response = await supabase
          .from('profiles')
          .select('user_code')
          .eq('id', currentUserId)
          .maybeSingle();

      return response?['user_code'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('사용자 코드 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// 내 사용자 코드 갱신 (새로운 코드 생성)
  static Future<String> refreshMyUserCode() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 새로운 코드 생성
      final response = await supabase
          .rpc('generate_unique_user_code');
      
      final newCode = response as String;
      
      // 프로필에 새 코드 저장
      await supabase
          .from('profiles')
          .update({'user_code': newCode})
          .eq('id', currentUserId);

      return newCode;
    } catch (e) {
      if (kDebugMode) {
        print('사용자 코드 갱신 실패: $e');
      }
      rethrow;
    }
  }

  /// 사용자 코드로 사용자 검색
  static Future<Map<String, dynamic>?> findUserByCode(String userCode) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('id, display_name, email, avatar_url, user_code')
          .eq('user_code', userCode.toUpperCase())
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('사용자 코드 검색 실패: $e');
      }
      rethrow;
    }
  }

  /// 사용자 코드로 친구 추가
  static Future<Friend> addFriendByCode(String userCode, {String? nickname, String? memo}) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final currentUserId = AuthService.currentUser!.id;
      
      // 사용자 코드로 사용자 검색
      final targetUser = await findUserByCode(userCode);
      if (targetUser == null) {
        throw Exception('해당 코드의 사용자를 찾을 수 없습니다');
      }
      
      final targetUserId = targetUser['id'] as String;
      
      // 자기 자신을 친구로 추가하려는 경우 방지
      if (targetUserId == currentUserId) {
        throw Exception('자기 자신을 친구로 추가할 수 없습니다');
      }
      
      // 이미 친구로 등록되어 있는지 확인
      final existingFriend = await supabase
          .from('friends')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('connected_user_id', targetUserId)
          .maybeSingle();
          
      if (existingFriend != null) {
        throw Exception('이미 친구로 등록된 사용자입니다');
      }
      
      // 친구 추가
      final friend = Friend(
        connectedUserId: targetUserId,
        nickname: nickname ?? targetUser['display_name'],
        memo: memo,
        addedAt: DateTime.now(),
      );
      
      return await addFriend(friend);
    } catch (e) {
      if (kDebugMode) {
        print('코드로 친구 추가 실패: $e');
      }
      rethrow;
    }
  }
}