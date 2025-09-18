import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/constants/app_colors.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_detail_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_list_infinite_screen.dart';
import 'package:jiyong_in_the_room/widgets/friend_management_bottom_sheet.dart';
import 'package:jiyong_in_the_room/utils/rating_utils.dart';

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
  late Friend currentFriend;
  late List<DiaryEntry> sharedEntries;
  
  @override
  void initState() {
    super.initState();
    currentFriend = widget.friend;
    sharedEntries = _getSharedDiaryEntries();
  }
  
  List<DiaryEntry> _getSharedDiaryEntries() {
    return widget.diaryList.where((entry) {
        if (entry.friends == null) return false;
        return entry.friends!.any(
          (friend) => friend.displayName == currentFriend.displayName,
        );
      }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
  }
  
  void _updateFriend(Friend updatedFriend) {
    // 친구 정보만 업데이트하고 테마 목록은 유지
    setState(() {
      currentFriend = updatedFriend;
      // displayName이 변경된 경우에만 테마 목록 재계산
      if (currentFriend.displayName != updatedFriend.displayName) {
        sharedEntries = _getSharedDiaryEntries();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 친구 관리 바텀시트 표시
  void _showFriendManagementBottomSheet() {
    FriendManagementBottomSheet.show(
      context: context,
      friend: currentFriend,
      onUpdateFriend: (oldFriend, updatedFriend) {
        _updateFriend(updatedFriend);
        if (widget.onUpdateFriend != null) {
          widget.onUpdateFriend!(oldFriend, updatedFriend);
        }
      },
      onRemoveFriend: (friend) {
        if (widget.onRemoveFriend != null) {
          widget.onRemoveFriend!(friend);
        }
        Navigator.of(context).pop(); // 친구 삭제 시 상세 화면 닫기
      },
      onClose: () {
        // 상세페이지에서는 바텀시트가 이미 닫혔으므로 추가 Navigator.pop 불필요
        // 필요시 여기에 추가 동작 구현
      },
    );
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
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            currentFriend.isConnected ? null : AppColors.grey,
                        backgroundImage:
                            currentFriend.isConnected &&
                                    currentFriend.user?.avatarUrl != null
                                ? NetworkImage(currentFriend.user!.avatarUrl!)
                                : null,
                        child:
                            (!currentFriend.isConnected ||
                                    currentFriend.user?.avatarUrl == null)
                                ? Text(
                                  currentFriend.displayName.isNotEmpty
                                      ? currentFriend.displayName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppColors.white,
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
                                  currentFriend.displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!currentFriend.isConnected)
                                  Icon(
                                    Icons.link_off,
                                    size: 20,
                                    color: AppColors.grey,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (currentFriend.isConnected &&
                                currentFriend.realName != null) ...[
                              Text(
                                currentFriend.realName!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (currentFriend.memo != null &&
                                currentFriend.memo!.isNotEmpty) ...[
                              Text(
                                currentFriend.memo!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
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
                      title: '총 테마 수',
                      value: '$totalThemes개',
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      title: '탈출 성공률',
                      value: '$successRate%',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 최근 함께한 테마 목록 (최대 3개)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 함께한 테마',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (sharedEntries.length > 3)
                    TextButton.icon(
                      onPressed: () {
                        // 일지 리스트로 이동하면서 해당 친구 필터 적용
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryListInfiniteScreen(
                              friends: widget.allFriends,
                              onAddFriend: widget.onAddFriend ?? (friend) {},
                              onRemoveFriend: widget.onRemoveFriend ?? (friend) {},
                              onUpdateFriend: widget.onUpdateFriend ?? (old, updated) {},
                              initialSelectedFriends: [currentFriend], // 초기 필터 설정
                            ),
                          ),
                        );
                      },
                      label: const Text('더 보기'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (sharedEntries.isNotEmpty)
                ...sharedEntries.take(3).map( // 최대 3개만 표시
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
                                      backgroundColor: AppColors.stampSuccessBackground,
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
                                          backgroundColor: AppColors.stampFailBackground,
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
                                      backgroundColor: AppColors.stampUnknownBackground,
                                      child: Icon(
                                        Icons.help_outline,
                                        color: AppColors.textSecondary,
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
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RatingUtils.getRatingWithIcon(
                              entry.rating,
                              fontSize: 12,
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: AppColors.grey),
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
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${currentFriend.displayName}님과\n함께한 테마가 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
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
      // 친구 관리 플로팅 액션 버튼 (일지 상세페이지와 동일한 스타일)
      floatingActionButton: FloatingActionButton(
        onPressed: _showFriendManagementBottomSheet,
        child: const Icon(Icons.more_vert),
      ),
    );
  }
}
