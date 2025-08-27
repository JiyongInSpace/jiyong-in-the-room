import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/screens/friends/friend_detail_screen.dart';
import 'dart:async';

// 친구 관리 화면 - 인피니트 스크롤과 검색 기능을 제공
class FriendsScreen extends StatefulWidget {
  // 일지 목록 (친구별 참여 횟수 계산용)
  final List diaryList;
  // 친구 추가 시 호출될 콜백 함수
  final void Function(Friend) onAdd;
  // 친구 삭제 시 호출될 콜백 함수
  final void Function(Friend) onRemove;
  // 친구 정보 수정 시 호출될 콜백 함수 (이전 친구, 새 친구)
  final void Function(Friend, Friend) onUpdate;

  // 생성자: 콜백 함수들을 필수로 받음
  const FriendsScreen({
    super.key,
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
  // 사용자 코드 입력을 위한 컨트롤러
  final TextEditingController _userCodeController = TextEditingController();
  // 검색을 위한 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  
  // 스크롤 컨트롤러 (인피니트 스크롤용)
  final ScrollController _scrollController = ScrollController();
  
  // 친구 목록 상태
  List<Friend> _friends = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String _searchQuery = '';
  Timer? _searchTimer;
  
  // 페이지 당 아이템 수
  static const int _pageSize = 20;
  @override
  void initState() {
    super.initState();
    
    // 스크롤 리스너 등록
    _scrollController.addListener(_onScroll);
    
    // 검색 컨트롤러에 리스너 추가 (디바운싱 적용)
    _searchController.addListener(_onSearchChanged);
    
    // 초기 데이터 로드
    _loadFriends();
  }

  // 메모리 누수 방지를 위해 컨트롤러들을 정리
  @override
  void dispose() {
    _nicknameController.dispose();
    _memoController.dispose();
    _userCodeController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // 스크롤 리스너 - 인피니트 스크롤 처리
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFriends();
    }
  }
  
  // 검색어 변경 처리 (디바운싱 적용)
  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        _searchQuery = query;
        _currentPage = 0;
        _friends.clear();
        _hasMoreData = true;
        _loadFriends();
      }
    });
  }
  
  // 친구 목록 로드
  Future<void> _loadFriends() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final friends = await DatabaseService.getMyFriendsPaginated(
        page: _currentPage,
        limit: _pageSize,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      setState(() {
        if (_currentPage == 0) {
          _friends = friends;
        } else {
          _friends.addAll(friends);
        }
        _hasMoreData = friends.length == _pageSize;
        _currentPage++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 목록을 불러오지 못했습니다: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 더 많은 친구 로드
  Future<void> _loadMoreFriends() async {
    if (!_hasMoreData || _isLoading) return;
    await _loadFriends();
  }


  // 통합 친구 추가 다이얼로그
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
    
    _userCodeController.clear();
    _nicknameController.clear();
    _memoController.clear();
    
    showDialog(
      context: context,
      builder: (context) {
        String? errorMessage; // 에러 메시지 상태
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 친구 코드가 입력되었는지 확인
            final hasUserCode = _userCodeController.text.trim().isNotEmpty;
          
          return AlertDialog(
            title: const Text('친구 추가'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 친구 코드 입력 (선택사항)
                  TextField(
                    controller: _userCodeController,
                    decoration: InputDecoration(
                      labelText: '친구 코드 (선택사항)',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: errorMessage != null && errorMessage!.contains('코드') 
                              ? Colors.red 
                              : Colors.grey,
                        ),
                      ),
                      hintText: '친구 코드가 있으면 입력하세요',
                      helperText: '6자리 영숫자 코드',
                      errorText: errorMessage != null && errorMessage!.contains('코드') 
                          ? errorMessage 
                          : null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    onChanged: (value) {
                      // 코드 입력 상태가 변경될 때 다이얼로그 UI 업데이트
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 별명 입력 (조건부 필수)
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: hasUserCode ? '별명 (선택사항)' : '별명 (필수)',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: errorMessage != null && errorMessage!.contains('별명') 
                              ? Colors.red 
                              : Colors.grey,
                        ),
                      ),
                      hintText: hasUserCode 
                          ? '비워두면 상대방 이름을 사용합니다' 
                          : '이 친구를 부르는 이름을 입력하세요',
                      errorText: errorMessage != null && errorMessage!.contains('별명') 
                          ? errorMessage 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 메모 입력 (선택사항)
                  TextField(
                    controller: _memoController,
                    decoration: const InputDecoration(
                      labelText: '메모 (선택사항)',
                      border: OutlineInputBorder(),
                      hintText: '친구에 대한 메모를 남겨보세요',
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
                onPressed: () async {
                  // 에러 메시지 초기화
                  errorMessage = null;
                  setDialogState(() {});
                  
                  final userCode = _userCodeController.text.trim();
                  final nickname = _nicknameController.text.trim();
                  final memo = _memoController.text.trim();
                  
                  // 밸리데이션
                  if (hasUserCode) {
                    // 친구 코드가 있는 경우
                    if (userCode.length != 6) {
                      setDialogState(() {
                        errorMessage = '6자리 코드를 입력해주세요';
                      });
                      return;
                    }
                    
                    // 코드로 친구 추가 시도
                    try {
                      final friend = await DatabaseService.addFriendByCode(
                        userCode,
                        nickname: nickname.isEmpty ? null : nickname,
                        memo: memo.isEmpty ? null : memo,
                      );
                      
                      widget.onAdd(friend);
                      Navigator.pop(context);
                      
                      // 목록 새로고침
                      _refreshFriendsList();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('친구가 추가되었습니다')),
                      );
                    } catch (e) {
                      String userFriendlyMessage;
                      final errorMessageText = e.toString();
                      
                      if (errorMessageText.contains('해당 코드의 사용자를 찾을 수 없습니다')) {
                        userFriendlyMessage = '입력한 코드가 올바르지 않아요.\n코드를 다시 확인해주세요.';
                      } else if (errorMessageText.contains('자기 자신을 친구로 추가할 수 없습니다')) {
                        userFriendlyMessage = '자신의 코드는 사용할 수 없어요.';
                      } else if (errorMessageText.contains('이미 친구로 등록된 사용자입니다')) {
                        userFriendlyMessage = '이미 친구로 등록된 사용자예요.';
                      } else {
                        userFriendlyMessage = '친구 추가에 실패했어요.\n잠시 후 다시 시도해주세요.';
                      }
                      
                      setDialogState(() {
                        errorMessage = userFriendlyMessage;
                      });
                    }
                  } else {
                    // 친구 코드가 없는 경우
                    if (nickname.isEmpty) {
                      setDialogState(() {
                        errorMessage = '별명을 입력해주세요';
                      });
                      return;
                    }
                    
                    // 직접 입력으로 친구 추가
                    final friend = Friend(
                      connectedUserId: null, // 연결되지 않은 친구로 추가
                      user: null,
                      addedAt: DateTime.now(),
                      nickname: nickname,
                      memo: memo.isEmpty ? null : memo,
                    );

                    widget.onAdd(friend);
                    Navigator.pop(context);
                    
                    // 목록 새로고침
                    _refreshFriendsList();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('친구가 추가되었습니다')),
                    );
                  }
                },
                child: const Text('추가'),
              ),
            ],
          );
        },
      );
    },
    );
  }

  // 기존 친구에게 코드 등록 다이얼로그
  void _showLinkCodeDialog(Friend friend) {
    _userCodeController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${friend.displayName}의 코드 등록'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${friend.displayName}님의 6자리 친구 코드를 입력하면\n실제 사용자와 연동됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userCodeController,
                decoration: const InputDecoration(
                  labelText: '친구 코드',
                  border: OutlineInputBorder(),
                  helperText: '6자리 영숫자 코드',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
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
            onPressed: () async {
              final userCode = _userCodeController.text.trim();
              
              if (userCode.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('6자리 코드를 입력해주세요')),
                );
                return;
              }
              
              try {
                final updatedFriend = await DatabaseService.linkFriendWithCode(friend, userCode);
                
                // UI 업데이트를 위해 콜백 호출
                widget.onUpdate(friend, updatedFriend);
                Navigator.pop(context);
                
                // 목록 새로고침
                _refreshFriendsList();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${friend.displayName}님과 연동되었습니다')),
                );
              } catch (e) {
                Navigator.pop(context);
                
                String userFriendlyMessage;
                final errorMessage = e.toString();
                
                if (errorMessage.contains('해당 코드의 사용자를 찾을 수 없습니다')) {
                  userFriendlyMessage = '입력한 코드가 올바르지 않아요.\n코드를 다시 확인해주세요.';
                } else if (errorMessage.contains('자기 자신을 친구로 연동할 수 없습니다')) {
                  userFriendlyMessage = '자신의 코드는 사용할 수 없어요.';
                } else {
                  userFriendlyMessage = '코드 등록에 실패했어요.\n잠시 후 다시 시도해주세요.';
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(userFriendlyMessage)),
                );
              }
            },
            child: const Text('등록'),
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
              
              // 목록 새로고침
              _refreshFriendsList();
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
              
              // 목록 새로고침
              _refreshFriendsList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 길게 눌렀을 때 나타나는 컨텍스트 메뉴
  void _showFriendContextMenu(BuildContext context, Friend friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
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
                        backgroundColor: friend.isConnected 
                            ? null
                            : Colors.grey,
                        backgroundImage: friend.isConnected && friend.user?.avatarUrl != null
                            ? NetworkImage(friend.user!.avatarUrl!)
                            : null,
                        child: (!friend.isConnected || friend.user?.avatarUrl == null)
                            ? Text(
                                friend.displayName[0].toUpperCase(),
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
                                Text(
                                  friend.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (!friend.isConnected) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.link_off,
                                    size: 18,
                                    color: Colors.orange[700],
                                  ),
                                ],
                              ],
                            ),
                            if (friend.memo != null && friend.memo!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                friend.memo!,
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
                  onTap: () {
                    Navigator.pop(context);
                    _showEditFriendDialog(friend);
                  },
                ),
                
                // 연동되지 않은 친구의 경우에만 "코드 등록" 메뉴 표시
                if (!friend.isConnected)
                  _buildContextMenuItem(
                    icon: Icons.link_outlined,
                    iconColor: Colors.green,
                    title: '코드 등록',
                    subtitle: '실제 사용자와 연동하여 프로필 정보 동기화',
                    onTap: () {
                      Navigator.pop(context);
                      _showLinkCodeDialog(friend);
                    },
                  ),
                
                _buildContextMenuItem(
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  title: '친구 삭제',
                  subtitle: '친구 목록에서 완전히 제거',
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(friend);
                  },
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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

  // 친구 목록 새로고침
  void _refreshFriendsList() {
    _currentPage = 0;
    _friends.clear();
    _hasMoreData = true;
    _loadFriends();
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
    // 로그인 상태 확인
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
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
                '친구 기능을 사용하려면\n로그인이 필요합니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
      
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        // Theme.of(context): 현재 테마의 색상 정보를 가져옴
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '친구 이름이나 메모로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          
          // 친구 목록
          Expanded(
            child: _friends.isEmpty && !_isLoading
          // 친구가 없을 때 또는 검색 결과가 없을 때 표시할 안내 메시지
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty 
                        ? '검색 결과가 없습니다'
                        : '등록된 친구가 없습니다',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty 
                        ? '다른 검색어를 시도해보세요'
                        : '친구를 추가해보세요!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          // 친구가 있을 때 목록으로 표시
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _friends.length + (_hasMoreData ? 1 : 0), // 로딩 인디케이터 포함
              itemBuilder: (context, index) {
                // 로딩 인디케이터 표시
                if (index >= _friends.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final friend = _friends[index];
                final participationCount = _getFriendParticipationCount(friend);
                
                // Card: 그림자가 있는 사각형 컨테이너
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  // GestureDetector: 제스처를 감지하는 위젯
                  child: GestureDetector(
                    // 전체 카드 영역에서 터치 이벤트 감지
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendDetailScreen(
                            friend: friend,
                            diaryList: widget.diaryList.cast<DiaryEntry>(),
                            allFriends: _friends,
                            onUpdate: null, // 친구 상세에서는 일지 수정 불가
                            onDelete: null, // 친구 상세에서는 일지 삭제 불가
                            onAddFriend: null, // 친구 상세에서는 친구 추가 불가
                            onRemoveFriend: null, // 친구 상세에서는 친구 삭제 불가
                            onUpdateFriend: widget.onUpdate,
                          ),
                        ),
                      );
                    },
                    // 길게 눌렀을 때 컨텍스트 메뉴 표시
                    onLongPress: () {
                      // 햅틱 피드백 제공
                      HapticFeedback.mediumImpact();
                      _showFriendContextMenu(context, friend);
                    },
                    // 커스텀 ListTile 대신 Container 사용
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // 프로필 아바타
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: friend.isConnected 
                                ? null
                                : Colors.grey,
                            backgroundImage: friend.isConnected && friend.user?.avatarUrl != null
                                ? NetworkImage(friend.user!.avatarUrl!)
                                : null,
                            child: (!friend.isConnected || friend.user?.avatarUrl == null)
                                ? Text(
                                    friend.displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
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
                                // 친구 이름과 연동 상태
                                Row(
                                  children: [
                                    Text(
                                      friend.displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!friend.isConnected)
                                      const Icon(
                                        Icons.link_off,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 메모 (있는 경우)
                                if (friend.memo != null && friend.memo!.isNotEmpty) ...[
                                  Text(
                                    friend.memo!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                // 연동된 사용자 정보
                                if (friend.isConnected) ...[
                                  if (friend.realName != null)
                                    Text(
                                      '실명: ${friend.realName}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (friend.displayEmail != null)
                                    Text(
                                      '이메일: ${friend.displayEmail}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                                // 함께한 횟수
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
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // FloatingActionButton: 화면 우하단에 떠 있는 둥근 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog, // 친구 추가 다이얼로그 표시
        child: const Icon(Icons.person_add), // 사람 추가 아이콘
      ),
    );
  }

}