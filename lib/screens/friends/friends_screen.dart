// 플러터의 기본 Material Design 위젯들을 사용하기 위한 import
import 'package:flutter/material.dart';
// Friend 모델 클래스를 사용하기 위한 import
import 'package:jiyong_in_the_room/models/user.dart';
// DiaryEntry 모델 import
import 'package:jiyong_in_the_room/models/diary.dart';
// 인증 서비스를 사용하기 위한 import
import 'package:jiyong_in_the_room/services/auth_service.dart';

// 친구 관리 화면 - 친구 추가, 수정, 삭제 기능을 제공
class FriendsScreen extends StatefulWidget {
  // 표시할 친구 목록
  final List<Friend> friends;
  // 일지 목록 (친구별 참여 횟수 계산용)
  final List diaryList;
  // 친구 추가 시 호출될 콜백 함수
  final void Function(Friend) onAdd;
  // 친구 삭제 시 호출될 콜백 함수
  final void Function(Friend) onRemove;
  // 친구 정보 수정 시 호출될 콜백 함수 (이전 친구, 새 친구)
  final void Function(Friend, Friend) onUpdate;

  // 생성자: 친구 목록과 콜백 함수들을 필수로 받음
  const FriendsScreen({
    super.key,
    required this.friends,
    required this.diaryList,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

// 친구 화면의 상태를 관리하는 State 클래스
class _FriendsScreenState extends State<FriendsScreen> {
  // 친구 별명 입력을 위한 컨트롤러
  final TextEditingController _nicknameController = TextEditingController();
  // 친구 메모 입력을 위한 컨트롤러
  final TextEditingController _memoController = TextEditingController();

  // 메모리 누수 방지를 위해 컨트롤러들을 정리
  @override
  void dispose() {
    _nicknameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 친구 추가 다이얼로그를 표시하는 메서드
  void _showAddFriendDialog() {
    // 로그인 확인
    if (!AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('친구 추가 기능을 사용하려면 로그인이 필요합니다'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // 입력 필드들을 초기화
    _nicknameController.clear();
    _memoController.clear();

    // showDialog(): 다이얼로그를 화면에 표시하는 함수
    showDialog(
      context: context,
      // builder: 다이얼로그의 모양을 정의하는 함수
      builder: (context) => AlertDialog(
        title: const Text('친구 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '별명',
                  border: OutlineInputBorder(),
                  helperText: '이 친구를 부르는 이름을 입력하세요',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final nickname = _nicknameController.text.trim();

              if (nickname.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('별명을 입력해주세요')),
                );
                return;
              }

              final friend = Friend(
                connectedUserId: null, // 연결되지 않은 친구로 추가
                user: null,
                addedAt: DateTime.now(),
                nickname: nickname,
                memo: _memoController.text.isEmpty ? null : _memoController.text,
              );

              widget.onAdd(friend);
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditFriendDialog(Friend friend) {
    _nicknameController.text = friend.nickname;
    _memoController.text = friend.memo ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 정보 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '별명',
                  border: OutlineInputBorder(),
                  helperText: '이 친구를 부르는 이름을 입력하세요',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final nickname = _nicknameController.text.trim();

              if (nickname.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('별명을 입력해주세요')),
                );
                return;
              }

              final updatedFriend = Friend(
                connectedUserId: friend.connectedUserId,
                user: friend.user,
                addedAt: friend.addedAt,
                nickname: nickname,
                memo: _memoController.text.isEmpty ? null : _memoController.text,
              );

              widget.onUpdate(friend, updatedFriend);
              Navigator.pop(context);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${friend.displayName}을(를) 친구 목록에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onRemove(friend);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 친구별 참여 횟수를 계산하는 메서드
  int _getFriendParticipationCount(Friend friend) {
    if (widget.diaryList.isEmpty) return 0;
    
    int count = 0;
    for (var diary in widget.diaryList) {
      if (diary is DiaryEntry && diary.friends != null) {
        // 친구 ID 또는 별명으로 매칭 확인
        bool isParticipant = diary.friends!.any((diaryFriend) {
          if (friend.id != null && diaryFriend.id != null) {
            return friend.id == diaryFriend.id;
          } else {
            // ID가 없는 경우 별명으로 비교
            return friend.nickname == diaryFriend.nickname;
          }
        });
        if (isParticipant) count++;
      }
    }
    return count;
  }

  // 친구 화면의 UI를 구성하는 메서드
  @override
  Widget build(BuildContext context) {
    // 친구 목록을 참여 횟수 순으로 정렬 (많이 함께한 순서)
    final sortedFriends = List<Friend>.from(widget.friends)
      ..sort((a, b) {
        final countA = _getFriendParticipationCount(a);
        final countB = _getFriendParticipationCount(b);
        return countB.compareTo(countA); // 내림차순 정렬
      });
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
        // Theme.of(context): 현재 테마의 색상 정보를 가져옴
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // body: 친구 목록이 비어있는지에 따라 다른 UI 표시
      body: sortedFriends.isEmpty
          // 친구가 없을 때 표시할 안내 메시지
          ? const Center(
              child: Column(
                // mainAxisAlignment: 세로 방향 정렬 방식
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 사람 모양의 아이콘
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '등록된 친구가 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '친구를 추가해보세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          // 친구가 있을 때 목록으로 표시
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedFriends.length, // 리스트 아이템 개수
              // itemBuilder: 각 아이템의 모양을 정의하는 함수
              itemBuilder: (context, index) {
                final friend = sortedFriends[index];
                final participationCount = _getFriendParticipationCount(friend);
                
                // Card: 그림자가 있는 사각형 컨테이너
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  // ListTile: 리스트 아이템을 표시하는 데 특화된 위젯
                  child: ListTile(
                    // leading: 리스트 아이템의 맨 앞에 표시될 위젯
                    // CircleAvatar: 원형 아바타 위젯
                    leading: CircleAvatar(
                      // 친구 연결 상태에 따라 다른 색상 사용
                      backgroundColor: friend.isConnected 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey,
                      child: Text(
                        // 친구 이름의 첫 글자를 대문자로 표시
                        friend.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold, // 굵은 글씨
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(friend.displayName),
                        const SizedBox(width: 8),
                        if (friend.isConnected)
                          const Icon(
                            Icons.link,
                            size: 16,
                            color: Colors.green,
                          )
                        else
                          const Icon(
                            Icons.link_off,
                            size: 16,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (friend.isConnected && friend.realName != null)
                          Text('실명: ${friend.realName}'),
                        if (friend.isConnected && friend.displayEmail != null)
                          Text('이메일: ${friend.displayEmail}'),
                        if (!friend.isConnected)
                          Text(
                            '연결되지 않음',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (friend.memo != null)
                          Text('메모: ${friend.memo}'),
                        Text(
                          '함께한 횟수: $participationCount회',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // trailing: 리스트 아이템의 맨 뒤에 표시될 위젯
                    // PopupMenuButton: 클릭하면 팝업 메뉴가 나타나는 버튼
                    trailing: PopupMenuButton<String>(
                      // onSelected: 메뉴 아이템이 선택됐 때 실행될 함수
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditFriendDialog(friend);
                        } else if (value == 'delete') {
                          _showDeleteConfirmDialog(friend);
                        }
                      },
                      // itemBuilder: 팝업 메뉴에 표시될 아이템들을 정의
                      itemBuilder: (context) => [
                        // PopupMenuItem: 팝업 메뉴의 각 아이템
                        const PopupMenuItem(
                          value: 'edit', // 선택 시 반환될 값
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('수정'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      // FloatingActionButton: 화면 우하단에 떠 있는 둥근 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog, // 친구 추가 다이얼로그 표시
        child: const Icon(Icons.person_add), // 사람 추가 아이콘
      ),
    );
  }

}