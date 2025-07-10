import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/user.dart';

class FriendsScreen extends StatefulWidget {
  final List<Friend> friends;
  final void Function(Friend) onAdd;
  final void Function(Friend) onRemove;
  final void Function(Friend, Friend) onUpdate;

  const FriendsScreen({
    super.key,
    required this.friends,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _showAddFriendDialog() {
    _nicknameController.clear();
    _memoController.clear();

    showDialog(
      context: context,
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
                connected: friend.connected,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: widget.friends.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.friends.length,
              itemBuilder: (context, index) {
                final friend = widget.friends[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: friend.isConnected 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey,
                      child: Text(
                        friend.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                          '추가일: ${friend.addedAt.year}.${friend.addedAt.month.toString().padLeft(2, '0')}.${friend.addedAt.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditFriendDialog(friend);
                        } else if (value == 'delete') {
                          _showDeleteConfirmDialog(friend);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}