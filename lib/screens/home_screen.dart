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
  final Function(Friend) onAddFriend;
  final Function(Friend) onRemoveFriend;
  final Function(Friend, Friend) onUpdateFriend;

  const HomeScreen({
    super.key,
    required this.diaryList,
    required this.friends,
    required this.onAdd,
    required this.onUpdate,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.onUpdateFriend,
  });

  Map<Friend, int> _getFriendStats() {
    Map<Friend, int> friendStats = {};
    
    for (var entry in diaryList) {
      if (entry.friends != null) {
        for (var friend in entry.friends!) {
          friendStats[friend] = (friendStats[friend] ?? 0) + 1;
        }
      }
    }
    
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
                  builder: (context) => const SettingsScreen(
                    isLoggedIn: false, // TODO: 실제 로그인 상태로 변경
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
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
                        '총 $totalThemes개의 테마를 진행했습니다!',
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
                  child: ListTile(
                    leading: CircleAvatar(
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
                      ),
                    ),
                    title: Text(entry.theme.name),
                    subtitle: Text(
                      '${entry.cafe.name} • ${entry.date.year}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: entry.rating != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(entry.rating!.toStringAsFixed(1)),
                            ],
                          )
                        : null,
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