import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/error_service.dart';
import 'package:jiyong_in_the_room/screens/friends/friend_detail_screen.dart';
import 'package:jiyong_in_the_room/widgets/skeleton_widgets.dart';
import 'package:jiyong_in_the_room/widgets/common_input_fields.dart';
import 'package:jiyong_in_the_room/widgets/friend_management_bottom_sheet.dart';
import 'dart:async';

// 친구 정렬 옵션 열거형
enum FriendSortOption {
  name('가나다순', Icons.sort_by_alpha),
  participation('함께한 횟수순', Icons.bar_chart),
  recent('최근 추가순', Icons.schedule);
  
  const FriendSortOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

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
  
  // 정렬 옵션
  FriendSortOption _sortOption = FriendSortOption.name;
  
  // 필터 표시 상태
  bool _showFilters = false;
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
        
        // 정렬 적용
        _sortFriends();
        
        _hasMoreData = friends.length == _pageSize;
        _currentPage++;
      });
    } catch (e) {
      if (mounted) {
        ErrorService.showErrorSnackBar(
          context, 
          e,
          customMessage: '친구 목록을 불러올 수 없습니다',
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
  
  // 친구 목록 정렬
  void _sortFriends() {
    switch (_sortOption) {
      case FriendSortOption.name:
        _friends.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case FriendSortOption.participation:
        _friends.sort((a, b) {
          final aCount = _getFriendParticipationCount(a);
          final bCount = _getFriendParticipationCount(b);
          return bCount.compareTo(aCount); // 내림차순 (많은 순)
        });
        break;
      case FriendSortOption.recent:
        _friends.sort((a, b) => b.addedAt.compareTo(a.addedAt)); // 최근 순
        break;
    }
  }
  
  // 정렬 옵션 변경
  void _changeSortOption(FriendSortOption newOption) {
    if (_sortOption != newOption) {
      setState(() {
        _sortOption = newOption;
        _sortFriends();
      });
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
                  CommonTextField(
                    controller: _userCodeController,
                    labelText: '친구 코드 (선택사항)',
                    hintText: '친구 코드가 있으면 입력하세요',
                    helperText: '6자리 영숫자 코드',
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    onChanged: (value) {
                      // 코드 입력 상태가 변경될 때 다이얼로그 UI 업데이트
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 별명 입력 (조건부 필수)
                  CommonTextField(
                    controller: _nicknameController,
                    labelText: hasUserCode ? '별명 (선택사항)' : '별명 (필수)',
                    hintText: hasUserCode 
                        ? '비워두면 상대방 이름을 사용합니다' 
                        : '이 친구를 부르는 이름을 입력하세요',
                  ),
                  const SizedBox(height: 16),
                  
                  // 메모 입력 (선택사항)
                  CommonTextArea(
                    controller: _memoController,
                    labelText: '메모 (선택사항)',
                    hintText: '친구에 대한 메모를 남겨보세요',
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
                      final errorInfo = ErrorService.parseError(e);
                      setDialogState(() {
                        errorMessage = errorInfo.message;
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
              CommonTextField(
                controller: _userCodeController,
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
              CommonTextField(
                controller: _nicknameController,
                labelText: '별명',
                helperText: '이 친구를 부르는 이름을 입력하세요',
              ),
              const SizedBox(height: 16),
              CommonTextArea(
                controller: _memoController,
                labelText: '메모 (선택사항)',
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
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text(
          '${friend.displayName}을(를) 친구 목록에서 정말 삭제하시겠습니까?\n\n'
          '삭제된 친구 정보는 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          // 친구 삭제 처리
          widget.onRemove(friend);
          
          // 목록 새로고침
          _refreshFriendsList();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
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
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('친구 삭제에 실패했습니다: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    });
  }

  // 길게 눌렀을 때 나타나는 컨텍스트 메뉴
  void _showFriendContextMenu(BuildContext context, Friend friend) {
    FriendManagementBottomSheet.show(
      context: context,
      friend: friend,
      onUpdateFriend: (oldFriend, updatedFriend) {
        // 로컬 목록 즉시 업데이트
        setState(() {
          final index = _friends.indexWhere((f) => f.id == oldFriend.id);
          if (index != -1) {
            _friends[index] = updatedFriend;
          }
        });
        // 상위 콜백 호출
        widget.onUpdate(oldFriend, updatedFriend);
      },
      onRemoveFriend: (removedFriend) {
        // 로컬 목록에서 제거
        setState(() {
          _friends.removeWhere((f) => f.id == removedFriend.id);
        });
        // 상위 콜백 호출
        widget.onRemove(removedFriend);
      },
      onClose: () {
        // 추가 작업이 필요한 경우 여기에 작성
      },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: _showFilters ? null : Colors.grey,
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 애니메이션이 적용된 필터 영역
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _showFilters ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showFilters ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 검색 입력창
                    Row(
                      children: [
                        const Icon(Icons.search, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CommonTextField(
                            controller: _searchController,
                            labelText: '',
                            hintText: '친구 이름이나 메모로 검색...',
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 정렬 옵션
                    Row(
                      children: [
                        const Icon(Icons.sort, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CommonDropdownField<FriendSortOption>(
                            value: _sortOption,
                            labelText: '',
                            items: FriendSortOption.values.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Row(
                                  children: [
                                    Icon(option.icon, size: 18),
                                    const SizedBox(width: 8),
                                    Text(option.label),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _changeSortOption(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 친구 목록
          Expanded(
            child: _isLoading && _friends.isEmpty
          // 첫 로딩 시 스켈레톤 표시
          ? const FriendsListSkeleton()
          : _friends.isEmpty && !_isLoading
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
                    onTap: () async {
                      await Navigator.push(
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
                            onUpdateFriend: (oldFriend, updatedFriend) {
                              // 로컬 목록 업데이트
                              setState(() {
                                final index = _friends.indexWhere((f) => f.id == oldFriend.id);
                                if (index != -1) {
                                  _friends[index] = updatedFriend;
                                }
                              });
                              // 상위 콜백 호출
                              widget.onUpdate(oldFriend, updatedFriend);
                            },
                          ),
                        ),
                      );
                      // 화면에서 돌아온 후 목록 새로고침
                      setState(() {});
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
                                    // 내가 등록한 별명 (메인)
                                    Text(
                                      friend.displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    
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

  // 연동 해제 확인 다이얼로그
  void _showUnlinkConfirmDialog(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '연동 해제 안내',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• 프로필 이미지와 실제 이름이 사라집니다\n• 기존 일지 기록은 유지됩니다\n• 나중에 올바른 코드로 다시 연동 가능합니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedFriend = await DatabaseService.unlinkFriend(friend);
                
                // UI 업데이트를 위해 콜백 호출
                widget.onUpdate(friend, updatedFriend);
                Navigator.pop(context);
                
                // 목록 새로고침
                _refreshFriendsList();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${friend.displayName}님과의 연동이 해제되었습니다')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('연동 해제에 실패했습니다: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }

}