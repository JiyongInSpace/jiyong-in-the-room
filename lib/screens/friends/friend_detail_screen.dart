import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_detail_screen.dart';

class FriendDetailScreen extends StatefulWidget {
  final Friend friend;
  final List<DiaryEntry> diaryList;
  final List<Friend> allFriends;
  final void Function(DiaryEntry, DiaryEntry)? onUpdate;
  final void Function(DiaryEntry)? onDelete;
  final void Function(Friend)? onAddFriend;
  final void Function(Friend)? onRemoveFriend;
  final void Function(Friend, Friend)? onUpdateFriend;

  const FriendDetailScreen({
    super.key,
    required this.friend,
    required this.diaryList,
    required this.allFriends,
    this.onUpdate,
    this.onDelete,
    this.onAddFriend,
    this.onRemoveFriend,
    this.onUpdateFriend,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  List<DiaryEntry> _getSharedDiaryEntries() {
    return widget.diaryList.where((entry) {
        if (entry.friends == null) return false;
        return entry.friends!.any(
          (friend) => friend.displayName == widget.friend.displayName,
        );
      }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sharedEntries = _getSharedDiaryEntries();
    final totalThemes = sharedEntries.length;
    final successfulEscapes =
        sharedEntries.where((entry) => entry.escaped == true).length;
    final successRate =
        totalThemes > 0 ? (successfulEscapes / totalThemes * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 친구 프로필 카드
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // 친구 아바타
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            widget.friend.isConnected ? null : Colors.grey,
                        backgroundImage:
                            widget.friend.isConnected &&
                                    widget.friend.user?.avatarUrl != null
                                ? NetworkImage(widget.friend.user!.avatarUrl!)
                                : null,
                        child:
                            (!widget.friend.isConnected ||
                                    widget.friend.user?.avatarUrl == null)
                                ? Text(
                                  widget.friend.displayName.isNotEmpty
                                      ? widget.friend.displayName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      // 친구 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.friend.displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!widget.friend.isConnected)
                                  const Icon(
                                    Icons.link_off,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (widget.friend.isConnected &&
                                widget.friend.realName != null) ...[
                              Text(
                                widget.friend.realName!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (widget.friend.memo != null &&
                                widget.friend.memo!.isNotEmpty) ...[
                              Text(
                                widget.friend.memo!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 통계 카드들
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.games,
                      title: '함께한 테마',
                      value: '$totalThemes개',
                      color: Colors.blue[600]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      title: '탈출 성공률',
                      value: '$successRate%',
                      color: Colors.green[600]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 함께한 테마 목록
              Text(
                '함께한 테마 (${sharedEntries.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              if (sharedEntries.isNotEmpty)
                ...sharedEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DiaryDetailScreen(
                                    entry: entry,
                                    friends: widget.allFriends,
                                    onUpdate: widget.onUpdate,
                                    onDelete: widget.onDelete,
                                    onAddFriend: widget.onAddFriend,
                                    onRemoveFriend: widget.onRemoveFriend,
                                    onUpdateFriend: widget.onUpdateFriend,
                                  ),
                            ),
                          );
                        },
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: entry.escaped == true 
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 연한 초록 배경
                                    CircleAvatar(
                                      backgroundColor: Colors.green[100],
                                      radius: 20,
                                    ),
                                    // 스탬프 이미지 (위에 덮기)
                                    Image.asset(
                                      'assets/images/stamp_success.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                  ],
                                )
                              : entry.escaped == false
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // 연한 빨강 배경
                                        CircleAvatar(
                                          backgroundColor: Colors.red[100],
                                          radius: 20,
                                        ),
                                        // 스탬프 이미지 (위에 덮기)
                                        Image.asset(
                                          'assets/images/stamp_failed.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                      ],
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Colors.grey[100],
                                      child: Icon(
                                        Icons.help_outline,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                    ),
                        ),
                        title: Text(
                          entry.theme?.name ?? '테마 정보 없음',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.theme?.cafe?.name ?? ''),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(entry.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (entry.rating != null) ...[
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                entry.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.friend.displayName}님과\n함께한 테마가 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
