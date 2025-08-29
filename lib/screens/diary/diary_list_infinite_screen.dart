import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/diary/write_diary_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_detail_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/edit_diary_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/widgets/login_dialog.dart';
import 'package:jiyong_in_the_room/widgets/diary_entry_card.dart';
import 'package:jiyong_in_the_room/widgets/common_input_fields.dart';

// 인피니트 스크롤이 적용된 일지 목록 화면
class DiaryListInfiniteScreen extends StatefulWidget {
  final List<Friend> friends;
  final void Function(Friend) onAddFriend;
  final void Function(Friend) onRemoveFriend;
  final void Function(Friend, Friend) onUpdateFriend;
  final VoidCallback? onDataRefresh;

  const DiaryListInfiniteScreen({
    super.key,
    required this.friends,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.onUpdateFriend,
    this.onDataRefresh,
  });

  @override
  State<DiaryListInfiniteScreen> createState() => _DiaryListInfiniteScreenState();
}

class _DiaryListInfiniteScreenState extends State<DiaryListInfiniteScreen> {
  // 페이징 관련 변수들
  final List<DiaryEntry> _diaryList = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  
  // 검색 및 필터 관련 변수들
  final TextEditingController _searchController = TextEditingController();
  final List<Friend> _selectedFriends = [];
  String? _currentSearchQuery;
  Timer? _searchTimer;
  bool _showFilters = false;
  

  @override
  void initState() {
    super.initState();
    _loadDiaries(reset: true);
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // 스크롤 감지
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadDiaries();
      }
    }
  }

  // 일지 목록 로딩
  Future<void> _loadDiaries({bool reset = false}) async {
    if (_isLoading) return;
    
    if (!AuthService.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (reset) {
        _currentPage = 0;
        _diaryList.clear();
        _hasMore = true;
      }

      final diaries = await DatabaseService.getMyDiaryEntriesPaginated(
        page: _currentPage,
        limit: _pageSize,
        searchQuery: _currentSearchQuery,
        filterFriendIds: _selectedFriends.map((f) => f.id!).toList(),
      );

      if (mounted) {
        setState(() {
          if (diaries.length < _pageSize) {
            _hasMore = false;
          }
          
          _diaryList.addAll(diaries);
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일지 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  // Pull to refresh
  Future<void> _onRefresh() async {
    await _loadDiaries(reset: true);
  }

  // 검색 실행 (즉시)
  void _performSearch() {
    final searchText = _searchController.text.trim();
    _currentSearchQuery = searchText.isEmpty ? null : searchText;
    _loadDiaries(reset: true);
  }

  // 딜레이된 검색 (타이핑 중 실시간 검색)
  void _onSearchChanged(String value) {
    setState(() {}); // suffixIcon 업데이트를 위해
    
    // 기존 타이머 취소
    _searchTimer?.cancel();
    
    // 새 타이머 설정 (500ms 후 검색 실행)
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  // 친구 추가
  void _addFriendFilter(Friend friend) {
    if (!_selectedFriends.contains(friend)) {
      setState(() {
        _selectedFriends.add(friend);
      });
      _loadDiaries(reset: true);
    }
  }

  // 친구 제거
  void _removeFriendFilter(Friend friend) {
    setState(() {
      _selectedFriends.remove(friend);
    });
    _loadDiaries(reset: true);
  }

  // 필터 초기화
  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedFriends.clear();
      _currentSearchQuery = null;
    });
    _loadDiaries(reset: true);
  }

  // 필터 요약 텍스트 생성
  String _buildFilterSummary() {
    List<String> parts = [];
    
    if (_searchController.text.isNotEmpty) {
      parts.add('검색: "${_searchController.text}"');
    }
    
    if (_selectedFriends.isNotEmpty) {
      final friendNames = _selectedFriends.map((f) => f.displayName).join(', ');
      parts.add('친구: $friendNames');
    }
    
    return parts.join(' • ');
  }

  // 일지 추가
  void _addDiary(DiaryEntry newEntry) {
    setState(() {
      _diaryList.insert(0, newEntry);
    });
    if (widget.onDataRefresh != null) {
      widget.onDataRefresh!();
    }
  }

  // 일지 수정
  void _updateDiary(DiaryEntry oldEntry, DiaryEntry newEntry) {
    setState(() {
      final index = _diaryList.indexWhere((entry) => entry.id == oldEntry.id);
      if (index != -1) {
        _diaryList[index] = newEntry;
      }
    });
    if (widget.onDataRefresh != null) {
      widget.onDataRefresh!();
    }
  }

  // 일지 삭제
  void _deleteDiary(DiaryEntry entry) {
    setState(() {
      _diaryList.removeWhere((item) => item.id == entry.id);
    });
    if (widget.onDataRefresh != null) {
      widget.onDataRefresh!();
    }
  }

  // 일지 수정 페이지로 이동
  void _editDiary(DiaryEntry entry) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditDiaryScreen(
            entry: entry,
            friends: widget.friends,
            onUpdate: _updateDiary,
          ),
        ),
      );
      
      if (result != null && result is DiaryEntry) {
        _updateDiary(entry, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일지 수정 페이지를 열 수 없습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmation(DiaryEntry entry) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일지 삭제'),
        content: Text(
          '${entry.theme?.name ?? "일지"}를 정말 삭제하시겠습니까?\n\n'
          '삭제된 일지는 복구할 수 없습니다.',
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
          // 데이터베이스에서 삭제
          await DatabaseService.deleteDiaryEntry(entry.id);
          
          // UI에서 제거
          _deleteDiary(entry);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('일지가 삭제되었습니다'),
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
                content: Text('일지 삭제에 실패했습니다: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
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
                    // 검색 입력창 (아이콘 외부로 이동)
                    Row(
                      children: [
                        const Icon(Icons.search, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CommonTextField(
                            controller: _searchController,
                            labelText: '',
                            hintText: '테마명, 카페명',
                            suffixIcon: _searchController.text.isNotEmpty || _selectedFriends.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearFilters,
                                  )
                                : null,
                            onSubmitted: (value) => _performSearch(),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 친구 필터 드롭다운
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CommonDropdownField<Friend?>(
                            key: ValueKey(_selectedFriends.length),
                            value: null,
                            labelText: '',
                            hintText: '같이 한 친구',
                            items: widget.friends
                                .where((friend) => !_selectedFriends.contains(friend))
                                .map((friend) => DropdownMenuItem<Friend?>(
                                  value: friend,
                                  child: Text(friend.displayName),
                                ))
                                .toList(),
                            onChanged: (Friend? friend) {
                              if (friend != null) {
                                _addFriendFilter(friend);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    // 선택된 친구 칩들
                    if (_selectedFriends.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _selectedFriends.map((friend) {
                          return Chip(
                            label: Text(friend.displayName),
                            onDeleted: () => _removeFriendFilter(friend),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            backgroundColor: Colors.blue[50],
                            deleteIconColor: Colors.blue[700],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 필터 요약 정보 (한 줄)
          if (!_showFilters && (_searchController.text.isNotEmpty || _selectedFriends.isNotEmpty))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildFilterSummary(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('초기화', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          // 일지 목록
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _diaryList.isEmpty && !_isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '조건에 맞는 일지가 없습니다',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '검색어나 필터를 변경해보세요!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16, 
                        // 필터가 완전히 숨겨져 있을 때만 상단 여백 추가
                        !_showFilters && _searchController.text.isEmpty && _selectedFriends.isEmpty ? 16 : 0, 
                        16, 
                        96
                      ), // 하단 80px + 기본 16px 여백
                      itemCount: _diaryList.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // 로딩 인디케이터
                        if (index >= _diaryList.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final entry = _diaryList[index];
                        
                        return DiaryEntryCard(
                          entry: entry,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiaryDetailScreen(
                                  entry: entry,
                                  friends: widget.friends,
                                  onUpdate: _updateDiary,
                                  onDelete: _deleteDiary,
                                  onAddFriend: widget.onAddFriend,
                                  onRemoveFriend: widget.onRemoveFriend,
                                  onUpdateFriend: widget.onUpdateFriend,
                                ),
                              ),
                            );
                            
                            if (result == 'deleted') {
                              _deleteDiary(entry);
                            }
                          },
                          onEdit: () => _editDiary(entry),
                          onDelete: () => _showDeleteConfirmation(entry),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!AuthService.isLoggedIn) {
            await LoginDialog.show(
              context: context,
              title: '일지 작성',
              message: '일지를 작성하려면 로그인이 필요해요.',
            );
            return;
          }
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WriteDiaryScreen(friends: widget.friends),
            ),
          );
          
          if (result is DiaryEntry) {
            _addDiary(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}