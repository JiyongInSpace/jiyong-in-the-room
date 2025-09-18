import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/screens/diary/edit_diary_screen.dart';
import 'package:jiyong_in_the_room/screens/friends/friend_detail_screen.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/widgets/diary_management_bottom_sheet.dart';
import 'package:jiyong_in_the_room/utils/rating_utils.dart';

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  final List<Friend> friends;
  final void Function(DiaryEntry, DiaryEntry)? onUpdate;
  final void Function(DiaryEntry)? onDelete;
  final void Function(Friend)? onAddFriend;
  final void Function(Friend)? onRemoveFriend;
  final void Function(Friend, Friend)? onUpdateFriend;

  const DiaryDetailScreen({
    super.key,
    required this.entry,
    required this.friends,
    this.onUpdate,
    this.onDelete,
    this.onAddFriend,
    this.onRemoveFriend,
    this.onUpdateFriend,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {

  // 날짜를 YYYY.MM.DD 형식으로 포맷팅하는 함수
  String formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 친구 아이템을 생성하는 함수
  Widget _buildFriendItem(Friend friend) {
    // 현재 로그인한 사용자와 같은 사용자인지 확인
    final isCurrentUser = AuthService.isLoggedIn && 
        friend.connectedUserId == AuthService.currentUser?.id;
    
    return InkWell(
      onTap: isCurrentUser ? null : () async {
        // 본인이 아닌 경우에만 친구 상세페이지로 이동
        if (friend.id == null) {
          // 친구 ID가 없는 경우 현재 일지만 전달 (기존 방식)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendDetailScreen(
                friend: friend,
                diaryList: [widget.entry],
                allFriends: widget.friends,
                onUpdate: widget.onUpdate,
                onDelete: widget.onDelete,
                onAddFriend: widget.onAddFriend,
                onRemoveFriend: widget.onRemoveFriend,
                onUpdateFriend: widget.onUpdateFriend,
              ),
            ),
          );
          return;
        }

        // 로딩 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // 해당 친구와 함께한 모든 일지 조회
          final friendDiaries = await DatabaseService.getDiaryEntriesWithFriend(friend.id!);
          
          if (context.mounted) {
            Navigator.pop(context); // 로딩 다이얼로그 닫기
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FriendDetailScreen(
                  friend: friend,
                  diaryList: friendDiaries.isNotEmpty ? friendDiaries : [widget.entry],
                  allFriends: widget.friends,
                  onUpdate: widget.onUpdate,
                  onDelete: widget.onDelete,
                  onAddFriend: widget.onAddFriend,
                  onRemoveFriend: widget.onRemoveFriend,
                  onUpdateFriend: widget.onUpdateFriend,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // 로딩 다이얼로그 닫기
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('친구 일지를 불러오는데 실패했습니다: $e')),
            );
          }
        }
      },
      borderRadius: isCurrentUser ? null : BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isCurrentUser 
              ? Colors.orange.shade50  // 본인은 연한 오렌지 배경
              : Theme.of(context).scaffoldBackgroundColor,
          border: isCurrentUser 
              ? Border.all(color: Colors.orange.shade200, width: 1)
              : null,
        ),
        child: Row(
          children: [
            // 친구 아바타
            CircleAvatar(
              radius: 16,
              backgroundColor: friend.isConnected ? null : Colors.grey[400],
              backgroundImage:
                  friend.isConnected && friend.user?.avatarUrl != null
                      ? NetworkImage(friend.user!.avatarUrl!)
                      : null,
              child:
                  (!friend.isConnected || friend.user?.avatarUrl == null)
                      ? Text(
                        friend.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            // 친구 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 내가 등록한 별명 (메인)
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // 미연동 아이콘
                      if (!friend.isConnected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.link_off, size: 14, color: Colors.grey[500]),
                      ],

                      // 연동된 경우 사용자의 실제 닉네임 표시
                      if (friend.isConnected &&
                          friend.realName != null &&
                          friend.realName != friend.nickname) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${friend.realName})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 화살표 아이콘 (본인이 아닌 경우에만 표시)
            if (!isCurrentUser)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])
            else
              // 본인인 경우 "나" 텍스트 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '나',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 별점을 표시하는 위젯을 생성하는 함수
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Stack(
            children: [
              Icon(Icons.star_border, color: Colors.grey[400], size: 20),
              if (rating > index) ...[
                if (rating >= index + 1)
                  const Icon(Icons.star, color: Colors.amber, size: 20)
                else
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.5,
                      child: const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }

  @override
  // 화면의 UI를 구성하는 메인 빌드 함수
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          96.0,
        ), // 하단 80px + 기본 16px 여백
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 정보 카드 - 메인/목록 페이지 스타일로 통일
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 메인 헤더 - 테마/카페 정보만 간단히 표시
                    Row(
                      children: [
                        const Icon(Icons.lock_clock, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.entry.theme?.name ?? '알 수 없는 테마',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${widget.entry.cafe?.name ?? '알 수 없음'} • ${formatDate(widget.entry.date)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (widget.entry.friends != null &&
                widget.entry.friends!.isNotEmpty)
              const SizedBox(height: 16),

            // 게임 상세 정보 카드 (항상 표시)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assessment, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '상세 정보',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 만족도 정보 (방탈출 은어) - 평점이 있을 때만
                    if (widget.entry.rating != null) ...[
                      Row(
                        children: [
                          const Text('만족도: '),
                          RatingUtils.getRatingWithIcon(
                            widget.entry.rating,
                            fontSize: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 탈출 결과 정보 (글자색으로 표시)
                    Row(
                      children: [
                        const Text('탈출 결과: '),
                        if (widget.entry.escaped != null)
                          Text(
                            widget.entry.escaped! ? '성공' : '실패',
                            style: TextStyle(
                              color:
                                  widget.entry.escaped!
                                      ? Colors.green[800]
                                      : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            '-',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 소요 시간 정보
                    Row(
                      children: [
                        const Text('소요 시간: '),
                        if (widget.entry.timeTaken != null)
                          Text(
                            '${widget.entry.timeTaken!.inMinutes}분',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        else
                          Text(
                            '-',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 힌트 사용 정보
                    Row(
                      children: [
                        const Text('힌트 사용: '),
                        if (widget.entry.hintUsedCount != null)
                          Text(
                            '${widget.entry.hintUsedCount}회',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        else
                          Text(
                            '-',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 메모 카드 (항상 표시)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '메모',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.entry.memo != null &&
                        widget.entry.memo!.isNotEmpty)
                      Text(
                        widget.entry.memo!,
                        style: const TextStyle(fontSize: 14),
                      )
                    else
                      Text(
                        '메모가 없습니다',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 함께한 친구들 카드
            if (widget.entry.friends != null &&
                widget.entry.friends!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 12),
                          Text(
                            '함께한 친구들 (${widget.entry.friends!.length}명)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...widget.entry.friends!.map(
                        (friend) => _buildFriendItem(friend),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      // 관리 버튼 (플로팅 액션 버튼)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 일지 관리 바텀시트 표시
          DiaryManagementBottomSheet.show(
            context: context,
            entry: widget.entry,
            onEdit: () async {
              // 수정 버튼 클릭 시
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDiaryScreen(
                    entry: widget.entry,
                    friends: widget.friends,
                    onAddFriend: widget.onAddFriend,
                  ),
                ),
              );

              if (result != null && mounted) {
                if (result == 'deleted') {
                  // 일지가 삭제된 경우
                  if (widget.onDelete != null) {
                    widget.onDelete!(widget.entry);
                  }
                  Navigator.pop(context, 'deleted');
                } else if (result is DiaryEntry) {
                  // 일지가 수정된 경우
                  if (widget.onUpdate != null) {
                    widget.onUpdate!(widget.entry, result);
                  }
                  Navigator.pop(context, result);
                }
              }
            },
            onDelete: () async {
              // 삭제 버튼 클릭 시
              try {
                if (kDebugMode) {
                  print('🗑️ 일지 상세페이지에서 삭제 시도: ID=${widget.entry.id}, 로그인 여부=${AuthService.isLoggedIn}');
                }
                
                if (AuthService.isLoggedIn) {
                  // 회원: 데이터베이스에서 삭제
                  await DatabaseService.deleteDiaryEntry(widget.entry.id);
                } else {
                  // 비회원: 로컬에서 삭제
                  await LocalStorageService.deleteDiary(widget.entry.id);
                }
                
                // UI 콜백 호출
                if (widget.onDelete != null) {
                  widget.onDelete!(widget.entry);
                }
                
                if (kDebugMode) {
                  print('✅ 일지 상세페이지에서 삭제 성공');
                }
                
                Navigator.pop(context, 'deleted');
              } catch (e) {
                if (kDebugMode) {
                  print('❌ 일지 상세페이지에서 삭제 실패: $e');
                }
                
                // 에러 메시지 표시
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('일지 삭제에 실패했습니다: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
          );
        },
        child: const Icon(Icons.more_vert),
      ),
    );
  }
}
