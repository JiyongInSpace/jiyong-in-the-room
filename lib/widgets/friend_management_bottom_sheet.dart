import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/friend_service.dart';
import 'package:jiyong_in_the_room/services/error_service.dart';
import 'package:jiyong_in_the_room/widgets/common_input_fields.dart';

/// 친구 관리 바텀시트 공통 위젯
class FriendManagementBottomSheet extends StatefulWidget {
  final Friend friend;
  final void Function(Friend, Friend)? onUpdateFriend;
  final void Function(Friend)? onRemoveFriend;
  final VoidCallback? onClose; // 바텀시트가 닫힐 때 호출 (선택적)

  const FriendManagementBottomSheet({
    super.key,
    required this.friend,
    this.onUpdateFriend,
    this.onRemoveFriend,
    this.onClose,
  });

  @override
  State<FriendManagementBottomSheet> createState() => _FriendManagementBottomSheetState();

  /// 바텀시트 표시 헬퍼 메서드
  static Future<T?> show<T>({
    required BuildContext context,
    required Friend friend,
    void Function(Friend, Friend)? onUpdateFriend,
    void Function(Friend)? onRemoveFriend,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FriendManagementBottomSheet(
        friend: friend,
        onUpdateFriend: onUpdateFriend,
        onRemoveFriend: onRemoveFriend,
        onClose: onClose,
      ),
    );
  }
}

class _FriendManagementBottomSheetState extends State<FriendManagementBottomSheet> {
  late Friend currentFriend;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    currentFriend = widget.friend;
  }

  void _closeWithResult([dynamic result]) {
    if (!mounted || _isProcessing) return;
    setState(() => _isProcessing = true);
    
    Navigator.of(context).pop(result);
    
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  // 친구 정보 수정 다이얼로그
  void _showEditFriendDialog() {
    if (_isProcessing) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => _EditFriendDialog(
        friend: currentFriend,
        onUpdate: (updatedFriend) {
          if (mounted) {
            setState(() => currentFriend = updatedFriend);
            
            if (widget.onUpdateFriend != null) {
              widget.onUpdateFriend!(widget.friend, updatedFriend);
            }
            
            _closeWithResult(updatedFriend);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('친구 정보가 수정되었습니다')),
            );
          }
        },
      ),
    );
  }

  // 코드 등록 다이얼로그
  void _showLinkCodeDialog() {
    if (_isProcessing) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => _LinkCodeDialog(
        friend: currentFriend,
        onUpdate: (updatedFriend) async {
          if (mounted) {
            setState(() => currentFriend = updatedFriend);
            
            if (widget.onUpdateFriend != null) {
              widget.onUpdateFriend!(widget.friend, updatedFriend);
            }
            
            _closeWithResult(updatedFriend);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${updatedFriend.displayName}님과 연동되었습니다')),
            );
          }
        },
      ),
    );
  }

  // 연동 해제 확인 다이얼로그
  void _showUnlinkConfirmDialog() {
    if (_isProcessing) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => _UnlinkConfirmDialog(
        friend: currentFriend,
        onUpdate: (updatedFriend) {
          if (mounted) {
            setState(() => currentFriend = updatedFriend);
            
            if (widget.onUpdateFriend != null) {
              widget.onUpdateFriend!(widget.friend, updatedFriend);
            }
            
            _closeWithResult(updatedFriend);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${updatedFriend.displayName}님과의 연동이 해제되었습니다'),
                backgroundColor: Colors.orange[600],
              ),
            );
          }
        },
      ),
    );
  }

  // 친구 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog() {
    if (_isProcessing) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => _DeleteConfirmDialog(
        friend: currentFriend,
        onDelete: () {
          if (mounted) {
            if (widget.onRemoveFriend != null) {
              widget.onRemoveFriend!(currentFriend);
            }
            
            _closeWithResult('deleted');
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('친구가 삭제되었습니다'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
  
  // 컨텍스트 메뉴 아이템 빌더
  Widget _buildContextMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 메뉴 헤더
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 친구 아바타
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: currentFriend.isConnected 
                        ? null
                        : Colors.grey,
                    backgroundImage: currentFriend.isConnected && currentFriend.user?.avatarUrl != null
                        ? NetworkImage(currentFriend.user!.avatarUrl!)
                        : null,
                    child: (!currentFriend.isConnected || currentFriend.user?.avatarUrl == null)
                        ? Text(
                            currentFriend.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // 친구 이름과 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 내가 등록한 별명
                            Text(
                              currentFriend.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            
                            // 연동된 경우 사용자의 실제 닉네임
                            if (currentFriend.isConnected && currentFriend.realName != null && currentFriend.realName != currentFriend.nickname) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${currentFriend.realName})',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                            
                            if (!currentFriend.isConnected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.link_off,
                                size: 18,
                                color: Colors.orange[700],
                              ),
                            ],
                          ],
                        ),
                        if (currentFriend.memo != null && currentFriend.memo!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentFriend.memo!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
            
            const Divider(height: 1, thickness: 0.5),
            
            // 메뉴 옵션들
            _buildContextMenuItem(
              icon: Icons.edit_outlined,
              iconColor: Colors.blue,
              title: '정보 수정',
              subtitle: '별명이나 메모를 변경',
              onTap: _showEditFriendDialog,
            ),
            
            // 연동 상태에 따른 메뉴 표시 (로그인 상태에서만)
            if (AuthService.isLoggedIn)
              if (!currentFriend.isConnected)
                _buildContextMenuItem(
                  icon: Icons.link_outlined,
                  iconColor: Colors.green,
                  title: '코드 등록',
                  subtitle: '실제 사용자와 연동하여 프로필 정보 동기화',
                  onTap: _showLinkCodeDialog,
                )
              else
                _buildContextMenuItem(
                  icon: Icons.link_off,
                  iconColor: Colors.orange,
                  title: '연동 해제',
                  subtitle: '잘못 연동된 경우 해제하여 수정 가능',
                  onTap: _showUnlinkConfirmDialog,
                ),
            
            _buildContextMenuItem(
              icon: Icons.delete_outline,
              iconColor: Colors.red,
              title: '친구 삭제',
              subtitle: '친구 목록에서 완전히 제거',
              onTap: _showDeleteConfirmDialog,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// 친구 정보 수정 다이얼로그
class _EditFriendDialog extends StatefulWidget {
  final Friend friend;
  final void Function(Friend) onUpdate;

  const _EditFriendDialog({
    required this.friend,
    required this.onUpdate,
  });

  @override
  State<_EditFriendDialog> createState() => _EditFriendDialogState();
}

class _EditFriendDialogState extends State<_EditFriendDialog> {
  late TextEditingController nicknameController;
  late TextEditingController memoController;

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController(text: widget.friend.nickname);
    memoController = TextEditingController(text: widget.friend.memo ?? '');
  }

  @override
  void dispose() {
    nicknameController.dispose();
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.friend.displayName} 정보 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonTextField(
              controller: nicknameController,
              labelText: '별명',
              helperText: '내가 부르는 이름',
            ),
            const SizedBox(height: 16),
            CommonTextArea(
              controller: memoController,
              labelText: '메모',
              helperText: '이 친구에 대한 메모 (선택)',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            final nickname = nicknameController.text.trim();
            
            if (nickname.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('별명을 입력해주세요')),
              );
              return;
            }
            
            try {
              // 통합 친구 서비스 사용
              final updatedFriend = await FriendService.updateFriend(
                widget.friend,
                nickname: nickname,
                memo: memoController.text.trim(),
              );
              
              Navigator.of(context).pop();
              widget.onUpdate(updatedFriend);
            } catch (e) {
              Navigator.of(context).pop();
              
              final errorInfo = ErrorService.parseError(e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorInfo.message)),
              );
            }
          },
          child: const Text('수정'),
        ),
      ],
    );
  }
}

// 코드 등록 다이얼로그
class _LinkCodeDialog extends StatefulWidget {
  final Friend friend;
  final void Function(Friend) onUpdate;

  const _LinkCodeDialog({
    required this.friend,
    required this.onUpdate,
  });

  @override
  State<_LinkCodeDialog> createState() => _LinkCodeDialogState();
}

class _LinkCodeDialogState extends State<_LinkCodeDialog> {
  late TextEditingController userCodeController;

  @override
  void initState() {
    super.initState();
    userCodeController = TextEditingController();
  }

  @override
  void dispose() {
    userCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.friend.displayName}의 코드 등록'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.friend.displayName}님의 6자리 친구 코드를 입력하면\n실제 사용자와 연동됩니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CommonTextField(
              controller: userCodeController,
              labelText: '친구 코드',
              helperText: '6자리 영숫자 코드',
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            final userCode = userCodeController.text.trim();
            
            if (userCode.length != 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('6자리 코드를 입력해주세요')),
              );
              return;
            }
            
            try {
              final updatedFriend = await DatabaseService.linkFriendWithCode(
                widget.friend,
                userCode,
              );
              
              Navigator.of(context).pop();
              widget.onUpdate(updatedFriend);
            } catch (e) {
              Navigator.of(context).pop();
              
              final errorInfo = ErrorService.parseError(e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorInfo.message)),
              );
            }
          },
          child: const Text('등록'),
        ),
      ],
    );
  }
}

// 연동 해제 확인 다이얼로그
class _UnlinkConfirmDialog extends StatelessWidget {
  final Friend friend;
  final void Function(Friend) onUpdate;

  const _UnlinkConfirmDialog({
    required this.friend,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('연동 해제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${friend.displayName}님과의 연동을 해제하시겠습니까?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      '연동 해제 시 변화',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 프로필 이미지가 사라집니다\n• 실제 이름이 표시되지 않습니다\n• 언제든 다시 연동할 수 있습니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () async {
            try {
              final unlinkedFriend = await DatabaseService.unlinkFriend(friend);
              
              Navigator.of(context).pop();
              onUpdate(unlinkedFriend);
            } catch (e) {
              Navigator.of(context).pop();
              
              final errorInfo = ErrorService.parseError(e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorInfo.message)),
              );
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.orange[700],
          ),
          child: const Text('해제'),
        ),
      ],
    );
  }
}

// 친구 삭제 확인 다이얼로그
class _DeleteConfirmDialog extends StatelessWidget {
  final Friend friend;
  final VoidCallback onDelete;

  const _DeleteConfirmDialog({
    required this.friend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('친구 삭제'),
      content: Text(
        '${friend.displayName}을(를) 친구 목록에서 정말 삭제하시겠습니까?\n\n'
        '삭제된 친구 정보는 복구할 수 없습니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDelete();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}