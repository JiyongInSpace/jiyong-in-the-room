import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/screens/diary/edit_diary_screen.dart';
import 'package:jiyong_in_the_room/screens/friends/friend_detail_screen.dart';

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
    return InkWell(
        onTap: () {
          // 친구 상세페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendDetailScreen(
                friend: friend,
                diaryList: [widget.entry], // 현재 일지만 전달
                allFriends: widget.friends,
                onUpdate: widget.onUpdate,
                onDelete: widget.onDelete,
                onAddFriend: widget.onAddFriend,
                onRemoveFriend: widget.onRemoveFriend,
                onUpdateFriend: widget.onUpdateFriend,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Row(
            children: [
              // 친구 아바타
              CircleAvatar(
                radius: 16,
                backgroundColor: friend.isConnected ? null : Colors.grey[400],
                backgroundImage: friend.isConnected && friend.user?.avatarUrl != null
                    ? NetworkImage(friend.user!.avatarUrl!)
                    : null,
                child: (!friend.isConnected || friend.user?.avatarUrl == null)
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
                          Icon(
                            Icons.link_off,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                        ],
                        
                        // 연동된 경우 사용자의 실제 닉네임 표시
                        if (friend.isConnected && friend.realName != null && friend.realName != friend.nickname) ...[
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
              // 화살표 아이콘
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
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
              Icon(
                Icons.star_border,
                color: Colors.grey[400],
                size: 20,
              ),
              if (rating > index) ...[
                if (rating >= index + 1)
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  )
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
      appBar: AppBar(
        title: Text(''),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0), // 하단 80px + 기본 16px 여백
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
            const SizedBox(height: 16),
            
            // 함께한 친구들 카드
            if (widget.entry.friends != null && widget.entry.friends!.isNotEmpty)
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
                      ...widget.entry.friends!.map((friend) => _buildFriendItem(friend)),
                    ],
                  ),
                ),
              ),
            
            if (widget.entry.friends != null && widget.entry.friends!.isNotEmpty)
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
                    
                    // 평점 정보 (별표 포함)
                    Row(
                      children: [
                        const Text('평점: '),
                        if (widget.entry.rating != null) ...[
                          _buildStarRating(widget.entry.rating!),
                          const SizedBox(width: 8),
                          Text(
                            widget.entry.rating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ] else
                          Text(
                            '미평가',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 탈출 결과 정보 (글자색으로 표시)
                    Row(
                      children: [
                        const Text('탈출 결과: '),
                        if (widget.entry.escaped != null)
                          Text(
                            widget.entry.escaped! ? '성공' : '실패',
                            style: TextStyle(
                              color: widget.entry.escaped! ? Colors.green[800] : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            '미입력',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 소요시간 정보
                    Row(
                      children: [
                        const Text('소요시간: '),
                        if (widget.entry.timeTaken != null)
                          Text(
                            '${widget.entry.timeTaken!.inMinutes}분',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        else
                          Text(
                            '미입력',
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
                            '미입력',
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
                    if (widget.entry.memo != null && widget.entry.memo!.isNotEmpty)
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
          ],
        ),
      ),
      // 수정 버튼 (플로팅 액션 버튼)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditDiaryScreen(
                entry: widget.entry,
                friends: widget.friends,
              ),
            ),
          );

          if (result != null && mounted) {
            if (result == 'deleted') {
              // 일지가 삭제된 경우 - 콜백 호출 후 메인 화면으로 돌아가면서 삭제 신호 전달
              if (widget.onDelete != null) {
                widget.onDelete!(widget.entry);
              }
              Navigator.pop(context, 'deleted');
            } else if (result is DiaryEntry) {
              // 일지가 수정된 경우 - 수정된 내용 반영
              if (widget.onUpdate != null) {
                widget.onUpdate!(widget.entry, result);
              }
              Navigator.pop(context, result);
            }
          }
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}