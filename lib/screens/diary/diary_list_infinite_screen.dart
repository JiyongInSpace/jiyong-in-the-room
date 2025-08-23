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
        title: const Text('탈출일지'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _diaryList.isEmpty && !_isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '작성된 일지가 없습니다',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '아래 버튼을 눌러 첫 일지를 작성해보세요!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // 하단 80px + 기본 16px 여백
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