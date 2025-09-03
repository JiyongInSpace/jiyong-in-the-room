import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_list_infinite_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_detail_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/write_diary_screen.dart';
import 'package:jiyong_in_the_room/screens/friends/friends_screen.dart';
import 'package:jiyong_in_the_room/screens/friends/friend_detail_screen.dart';
import 'package:jiyong_in_the_room/screens/auth/settings_screen.dart';
import 'package:jiyong_in_the_room/widgets/login_dialog.dart';
import 'package:jiyong_in_the_room/widgets/diary_entry_card.dart';
import 'package:jiyong_in_the_room/widgets/skeleton_widgets.dart';
import 'package:jiyong_in_the_room/widgets/title_progress_dialog.dart';
import 'package:jiyong_in_the_room/widgets/team_stats_dialog.dart';

class HomeScreen extends StatelessWidget {
  final List<DiaryEntry> diaryList;
  final List<Friend> friends;
  final Function(DiaryEntry) onAdd;
  final Function(DiaryEntry, DiaryEntry) onUpdate;
  final Function(DiaryEntry) onDelete;
  final Function(Friend) onAddFriend;
  final Function(Friend) onRemoveFriend;
  final Function(Friend, Friend) onUpdateFriend;
  final bool isLoggedIn;
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onDataRefresh; // 데이터 새로고침 콜백 추가

  const HomeScreen({
    super.key,
    required this.diaryList,
    required this.friends,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.onUpdateFriend,
    required this.isLoggedIn,
    this.userProfile,
    this.onDataRefresh,
  });

  Map<Friend, int> _getFriendStats() {
    Map<String, int> friendCountByName = {};
    Map<String, Friend> friendByName = {};
    
    // 현재 사용자의 ID (가장 정확한 식별자)
    final currentUserId = userProfile?['id'];
    
    if (kDebugMode) {
      print('🔍 친구 통계 집계 시작');
      print('📊 총 일지 수: ${diaryList.length}');
    }
    
    // 친구 이름(displayName)을 기준으로 그룹화하여 카운트 (본인 제외)
    for (var entry in diaryList) {
      if (entry.friends != null) {
        for (var friend in entry.friends!) {
          // 본인은 제외 (connectedUserId로 정확히 식별)
          if (currentUserId != null && friend.connectedUserId == currentUserId) {
            continue;
          }
          
          final name = friend.displayName;
          
          if (kDebugMode) {
            // print('👤 친구 발견: $name (ID: ${friend.id}, connectedUserId: ${friend.connectedUserId})');
          }
          
          friendCountByName[name] = (friendCountByName[name] ?? 0) + 1;
          
          // 각 이름의 대표 Friend 객체 저장 
          // 연동된 친구를 우선적으로 저장 (connectedUserId가 있는 경우)
          if (!friendByName.containsKey(name) || 
              (friendByName[name]!.connectedUserId == null && friend.connectedUserId != null)) {
            friendByName[name] = friend;
            if (kDebugMode) {
              // print('✅ 대표 친구로 설정: $name (연동: ${friend.connectedUserId != null})');
            }
          }
        }
      }
    }
    
    if (kDebugMode) {
      print('📊 집계 결과: $friendCountByName');
    }
    
    // 결과를 Map<Friend, int> 형태로 변환
    Map<Friend, int> friendStats = {};
    friendCountByName.forEach((name, count) {
      final friend = friendByName[name];
      if (friend != null) {
        friendStats[friend] = count;
      }
    });
    
    return friendStats;
  }

  List<MapEntry<Friend, int>> _getTopFriends() {
    var stats = _getFriendStats();
    var sortedEntries = stats.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(3).toList();
  }

  // 방탈 횟수에 따른 칭호 계산
  String _getEscapeTitle(int escapeCount) {
    if (escapeCount <= 5) {
      return '방알못';
    } else if (escapeCount <= 49) {
      return '방린이';
    } else if (escapeCount <= 99) {
      return '방청년';
    } else if (escapeCount <= 299) {
      return '고인물';
    } else {
      return '썩은물';
    }
  }
  
  // 프로필 이미지 가져오기 (null-safe)
  ImageProvider? _getProfileImage() {
    if (!isLoggedIn || userProfile == null) {
      return null;
    }
    
    final avatarUrl = userProfile!['avatar_url'];
    if (avatarUrl != null && avatarUrl is String) {
      return NetworkImage(avatarUrl);
    }
    
    return null;
  }

  // 칭호별 색상 반환
  Color _getTitleColor(String title) {
    switch (title) {
      case '방알못':
        return Colors.grey[600]!;
      case '방린이':
        return Colors.green[600]!;
      case '방청년':
        return Colors.blue[600]!;
      case '고인물':
        return Colors.purple[600]!;
      case '썩은물':
        return Colors.amber[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
  
  // 칭호별 아이콘 반환
  IconData _getTitleIcon(String title) {
    switch (title) {
      case '방알못':
        return Icons.sentiment_very_dissatisfied;
      case '방린이':
        return Icons.child_care;
      case '방청년':
        return Icons.person;
      case '고인물':
        return Icons.water_drop;
      case '썩은물':
        return Icons.whatshot;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalThemes = diaryList.length;
    final topFriends = _getTopFriends();
    
    // 함께한 친구들의 총 수 계산 (중복 제거, 본인 제외)
    final uniqueFriendNames = <String>{};
    final currentUserId = userProfile?['id'];
    
    for (var entry in diaryList) {
      if (entry.friends != null) {
        for (var friend in entry.friends!) {
          // null 체크 추가
          if (friend.displayName.isEmpty) continue;
          
          // 본인은 제외 (connectedUserId로 정확히 식별)
          if (currentUserId != null && friend.connectedUserId == currentUserId) {
            continue;
          }
          
          uniqueFriendNames.add(friend.displayName);
        }
      }
    }
    final totalFriendsCount = uniqueFriendNames.length;
    
    final sortedDiaryList = diaryList.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentEntries = sortedDiaryList.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 일지 작성 버튼 (비회원도 표시)
          IconButton(
            onPressed: () async {
              final result = await Navigator.push<DiaryEntry>(
                context,
                MaterialPageRoute(
                  builder: (context) => WriteDiaryScreen(
                    friends: friends,
                    onAddFriend: onAddFriend,
                    isLoggedIn: isLoggedIn, // 로그인 상태 전달
                  ),
                ),
              );
              
              // 새로운 일지가 작성되면 홈 화면 데이터 새로고침
              if (result != null) {
                onAdd(result);
                if (onDataRefresh != null) {
                  onDataRefresh!();
                }
              }
            },
            icon: const Icon(Icons.edit_outlined),
            iconSize: 28,
            tooltip: '일지 작성',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    isLoggedIn: isLoggedIn,
                    userProfile: userProfile,
                  ),
                ),
              );
              
              // 프로필이 변경되면 홈 화면 데이터 새로고침
              if (result == true && onDataRefresh != null) {
                if (kDebugMode) {
                  print('🏠 HomeScreen: 설정 페이지에서 데이터 변경 감지, 새로고침 시작');
                }
                onDataRefresh!(); // 메인 앱에서 일지 데이터 새로고침
              } else if (kDebugMode) {
                print('🏠 HomeScreen: 데이터 변경 없음 (result: $result)');
              }
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: isLoggedIn ? Colors.blue[400] : Colors.grey[300],
              backgroundImage: _getProfileImage(),
              child: _getProfileImage() == null
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: isLoggedIn ? Colors.white : Colors.grey[600],
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0), // 하단 80px + 기본 16px 여백
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 통계 카드 (2개 카드 나란히 배치)
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    // 왼쪽 카드: 방탈 횟수 & 칭호
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          // 칭호 진행 상황 팝업 표시
                          showDialog(
                            context: context,
                            builder: (context) => TitleProgressDialog(
                              currentCount: totalThemes,
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  _getTitleIcon(_getEscapeTitle(totalThemes)),
                                  size: 32,
                                  color: _getTitleColor(_getEscapeTitle(totalThemes)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getEscapeTitle(totalThemes),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getTitleColor(_getEscapeTitle(totalThemes)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '방탈 $totalThemes회',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // 오른쪽 카드: 팀 통계
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          // 팀 통계 팝업 표시
                          showDialog(
                            context: context,
                            builder: (context) => TeamStatsDialog(
                              diaryList: diaryList,
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 32,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '함께한 친구들',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[600],
                                ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalFriendsCount > 0 
                                      ? '총 $totalFriendsCount명'
                                      : '혼자 진행',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 진행한 테마',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () async {
                      // 비회원/회원 구분 없이 일지 목록으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryListInfiniteScreen(
                            friends: friends,
                            onAddFriend: onAddFriend,
                            onRemoveFriend: onRemoveFriend,
                            onUpdateFriend: onUpdateFriend,
                            onDataRefresh: onDataRefresh,
                          ),
                        ),
                      );
                    },
                    child: const Text('더보기'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (recentEntries.isNotEmpty)
                ...recentEntries.asMap().entries.expand((indexedEntry) {
                  final entry = indexedEntry.value;
                  final index = indexedEntry.key;
                  
                  return [
                    if (index > 0) const SizedBox(height: 8),
                    DiaryEntryCard(
                      entry: entry,
                      showPadding: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryDetailScreen(
                              entry: entry,
                              friends: friends,
                              onUpdate: onUpdate,
                              onDelete: onDelete,
                              onAddFriend: onAddFriend,
                              onRemoveFriend: onRemoveFriend,
                              onUpdateFriend: onUpdateFriend,
                            ),
                          ),
                        );
                      },
                    ),
                  ];
                })
              else
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('아직 기록이 없습니다.'),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '가장 많이 함께한 친구들',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () async {
                      // 비회원도 친구 기능 사용 가능
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendsScreen(
                            diaryList: diaryList,
                            onAdd: onAddFriend,
                            onRemove: onRemoveFriend,
                            onUpdate: onUpdateFriend,
                          ),
                        ),
                      );
                      
                      // 친구 관리 화면에서 돌아왔을 때 데이터 새로고침
                      if (onDataRefresh != null) {
                        onDataRefresh!();
                      }
                    },
                    child: const Text('더보기'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (topFriends.isNotEmpty)
                ...topFriends.asMap().entries.expand((entry) {
                  final index = entry.key;
                  final rank = index + 1;
                  final friend = entry.value.key;
                  final count = entry.value.value;
                  
                  return [
                    if (index > 0) const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FriendDetailScreen(
                                friend: friend,
                                diaryList: diaryList,
                                allFriends: friends,
                                onUpdate: onUpdate,
                                onDelete: onDelete,
                                onAddFriend: onAddFriend,
                                onRemoveFriend: onRemoveFriend,
                                onUpdateFriend: onUpdateFriend,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                          children: [
                            // 메달 이미지 (에러 방지)
                            Image.asset(
                              rank == 1 
                                  ? 'assets/images/medal_gold.png'
                                  : rank == 2 
                                      ? 'assets/images/medal_silver.png' 
                                      : 'assets/images/medal_bronze.png',
                              width: 32,
                              height: 32,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: rank == 1 
                                        ? Colors.amber 
                                        : rank == 2 
                                            ? Colors.grey[400] 
                                            : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$rank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            // 친구 아이콘 (친구 목록과 동일한 스타일)
                            CircleAvatar(
                              backgroundColor: friend.isConnected 
                                  ? null
                                  : Colors.grey,
                              backgroundImage: friend.isConnected && friend.user?.avatarUrl != null
                                  ? NetworkImage(friend.user!.avatarUrl!)
                                  : null,
                              child: (!friend.isConnected || friend.user?.avatarUrl == null)
                                  ? Text(
                                      friend.displayName.isNotEmpty 
                                          ? friend.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // 친구 이름
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        friend.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!friend.isConnected)
                                        const Icon(
                                          Icons.link_off,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                    ],
                                  ),
                                  // 친구 메모 표시
                                  if (friend.memo != null && friend.memo!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      friend.memo!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // 횟수 (오른쪽 정렬)
                            Text(
                              '$count회',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ];
                })
              else
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('아직 친구와 함께한 기록이 없습니다.'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}