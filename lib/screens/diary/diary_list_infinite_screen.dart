import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/diary/write_diary_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_detail_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/widgets/login_dialog.dart';
import 'package:jiyong_in_the_room/widgets/diary_entry_card.dart';

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
  Friend? _selectedFriend;
  String? _currentSearchQuery;
  Timer? _searchTimer;
  

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
        filterFriendId: _selectedFriend?.id,
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

  // 친구 필터 변경
  void _changeFriendFilter(Friend? friend) {
    setState(() {
      _selectedFriend = friend;
    });
    _loadDiaries(reset: true);
  }

  // 필터 초기화
  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedFriend = null;
      _currentSearchQuery = null;
    });
    _loadDiaries(reset: true);
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 검색 및 필터 영역
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 검색 입력창
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '테마명이나 카페명을 검색하세요',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty || _selectedFriend != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearFilters,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (value) => _performSearch(),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                // 친구 필터 드롭다운
                Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    const Text('친구 필터:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<Friend?>(
                        value: _selectedFriend,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        hint: const Text('전체 친구'),
                        items: [
                          const DropdownMenuItem<Friend?>(
                            value: null,
                            child: Text('전체 친구'),
                          ),
                          ...widget.friends.map((friend) => DropdownMenuItem<Friend?>(
                            value: friend,
                            child: Text(friend.displayName),
                          )),
                        ],
                        onChanged: _changeFriendFilter,
                      ),
                    ),
                  ],
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), // 하단 80px + 기본 16px 여백
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