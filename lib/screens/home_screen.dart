import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/screens/diary_list_screen.dart';
import 'package:jiyong_in_the_room/screens/friends_screen.dart';
import 'package:jiyong_in_the_room/screens/settings_screen.dart';

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
  });

  Map<Friend, int> _getFriendStats() {
    Map<String, int> friendCountByName = {};
    Map<String, Friend> friendByName = {};
    
    // 현재 사용자의 이름들 (제외할 대상)
    final currentUserNames = <String>{};
    if (userProfile != null) {
      if (userProfile!['display_name'] != null) {
        currentUserNames.add(userProfile!['display_name']);
      }
      if (userProfile!['email'] != null) {
        currentUserNames.add(userProfile!['email']);
      }
    }
    
    // 친구 이름(displayName)을 기준으로 그룹화하여 카운트 (본인 제외)
    for (var entry in diaryList) {
      if (entry.friends != null) {
        for (var friend in entry.friends!) {
          final name = friend.displayName;
          
          // 본인은 제외
          if (currentUserNames.contains(name)) {
            continue;
          }
          
          friendCountByName[name] = (friendCountByName[name] ?? 0) + 1;
          
          // 각 이름의 대표 Friend 객체 저장 (첫 번째로 등장한 것)
          if (!friendByName.containsKey(name)) {
            friendByName[name] = friend;
          }
        }
      }
    }
    
    // 결과를 Map<Friend, int> 형태로 변환
    Map<Friend, int> friendStats = {};
    friendCountByName.forEach((name, count) {
      friendStats[friendByName[name]!] = count;
    });
    
    return friendStats;
  }

  List<MapEntry<Friend, int>> _getTopFriends() {
    var stats = _getFriendStats();
    var sortedEntries = stats.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalThemes = diaryList.length;
    final topFriends = _getTopFriends();
    
    // 함께한 친구들의 총 수 계산 (중복 제거, 본인 제외)
    final uniqueFriendNames = <String>{};
    
    // 현재 사용자의 이름들 (제외할 대상)
    final currentUserNames = <String>{};
    if (userProfile != null) {
      if (userProfile!['display_name'] != null) {
        currentUserNames.add(userProfile!['display_name']);
      }
      if (userProfile!['email'] != null) {
        currentUserNames.add(userProfile!['email']);
      }
    }
    
    for (var entry in diaryList) {
      if (entry.friends != null) {
        for (var friend in entry.friends!) {
          final name = friend.displayName;
          // 본인은 제외
          if (!currentUserNames.contains(name)) {
            uniqueFriendNames.add(name);
          }
        }
      }
    }
    final totalFriendsCount = uniqueFriendNames.length;
    
    final recentEntries = diaryList
        .toList()
        ..sort((a, b) => b.date.compareTo(a.date))
        ..take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('탈출일지'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    isLoggedIn: isLoggedIn,
                    userProfile: userProfile,
                  ),
                ),
              );
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: isLoggedIn ? Colors.blue[400] : Colors.grey[300],
              backgroundImage: (isLoggedIn && userProfile?['avatar_url'] != null)
                  ? NetworkImage(userProfile!['avatar_url'])
                  : null,
              child: (isLoggedIn && userProfile?['avatar_url'] != null)
                  ? null
                  : Icon(
                      Icons.person,
                      size: 20,
                      color: isLoggedIn ? Colors.white : Colors.grey[600],
                    ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        totalFriendsCount > 0 
                            ? '총 $totalThemes개의 테마를\n${totalFriendsCount}명의 친구들과 진행했습니다!'
                            : '총 $totalThemes개의 테마를 진행했습니다!',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryListScreen(
                            diaryList: diaryList,
                            onAdd: onAdd,
                            onUpdate: onUpdate,
                            onDelete: onDelete,
                            friends: friends,
                            onAddFriend: onAddFriend,
                            onRemoveFriend: onRemoveFriend,
                            onUpdateFriend: onUpdateFriend,
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
                ...recentEntries.map((entry) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: entry.escaped == true 
                                  ? Colors.green 
                                  : entry.escaped == false 
                                      ? Colors.red 
                                      : Colors.grey,
                              child: Icon(
                                entry.escaped == true 
                                    ? Icons.check 
                                    : entry.escaped == false 
                                        ? Icons.close 
                                        : Icons.question_mark,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.theme?.name ?? '알 수 없는 테마',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${entry.cafe?.name ?? '알 수 없음'} • ${entry.date.year}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.day.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (entry.rating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    entry.rating!.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // 친구 정보 표시
                        if (entry.friends != null && entry.friends!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: entry.friends!
                                .map((friend) => Chip(
                                      label: Text(
                                        friend.displayName,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: Colors.blue[50],
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ))
              else
                const Card(
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
                    onPressed: () {
                      if (!isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('친구 기능을 사용하려면 로그인이 필요합니다'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendsScreen(
                            friends: friends,
                            onAdd: onAddFriend,
                            onRemove: onRemoveFriend,
                            onUpdate: onUpdateFriend,
                          ),
                        ),
                      );
                    },
                    child: const Text('더보기'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (topFriends.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: topFriends.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final friend = entry.value.key;
                        final count = entry.value.value;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: rank == 1 
                                ? Colors.amber 
                                : rank == 2 
                                    ? Colors.grey[400] 
                                    : Colors.brown[300],
                            child: Text(
                              rank.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Text(friend.displayName),
                          trailing: Text('$count회'),
                        );
                      }).toList(),
                    ),
                  ),
                )
              else
                const Card(
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