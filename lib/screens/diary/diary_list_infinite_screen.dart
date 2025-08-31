import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jiyong_in_the_room/screens/diary/write_diary_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/diary_detail_screen.dart';
import 'package:jiyong_in_the_room/screens/diary/edit_diary_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:jiyong_in_the_room/widgets/login_dialog.dart';
import 'package:jiyong_in_the_room/widgets/diary_entry_card.dart';
import 'package:jiyong_in_the_room/widgets/diary_filter_dialog.dart';
import 'package:jiyong_in_the_room/utils/rating_utils.dart';

// 인피니트 스크롤이 적용된 일지 목록 화면
class DiaryListInfiniteScreen extends StatefulWidget {
  final List<Friend> friends;
  final void Function(Friend) onAddFriend;
  final void Function(Friend) onRemoveFriend;
  final void Function(Friend, Friend) onUpdateFriend;
  final VoidCallback? onDataRefresh;
  final List<Friend>? initialSelectedFriends; // 초기 선택된 친구들

  const DiaryListInfiniteScreen({
    super.key,
    required this.friends,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.onUpdateFriend,
    this.onDataRefresh,
    this.initialSelectedFriends,
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
  String? _currentSearchQuery;
  final List<Friend> _selectedFriends = [];
  final List<RatingFilter> _selectedRatingFilters = [];
  DateTime? _startDate;
  DateTime? _endDate;
  

  @override
  void initState() {
    super.initState();
    
    // 초기 선택된 친구들 설정
    if (widget.initialSelectedFriends != null) {
      _selectedFriends.addAll(widget.initialSelectedFriends!);
    }
    
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

  // 일지 목록 로딩 (회원: DB, 비회원: 로컬)
  Future<void> _loadDiaries({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (reset) {
        _currentPage = 0;
        _diaryList.clear();
        _hasMore = true;
      }

      List<DiaryEntry> diaries;
      
      if (AuthService.isLoggedIn) {
        // 회원: DB에서 페이징 조회
        diaries = await DatabaseService.getMyDiaryEntriesPaginated(
          page: _currentPage,
          limit: _pageSize,
          searchQuery: _currentSearchQuery,
          filterFriendIds: _selectedFriends.map((f) => f.id!).toList(),
          ratingFilters: _selectedRatingFilters.isNotEmpty ? _selectedRatingFilters : null,
          startDate: _startDate,
          endDate: _endDate,
        );
        
        if (mounted) {
          setState(() {
            if (diaries.length < _pageSize) {
              _hasMore = false;
            }
            
            _diaryList.addAll(diaries);
            _currentPage++;
          });
        }
      } else {
        // 비회원: 로컬에서 전체 조회 후 클라이언트 사이드 필터링/페이징
        var localDiaries = LocalStorageService.getLocalDiaries();
        
        // 검색 필터 적용
        if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
          final query = _currentSearchQuery!.toLowerCase();
          localDiaries = localDiaries.where((diary) {
            final themeName = diary.theme?.name?.toLowerCase() ?? '';
            final cafeName = diary.theme?.cafe?.name?.toLowerCase() ?? '';
            return themeName.contains(query) || cafeName.contains(query);
          }).toList();
        }
        
        // 만족도 필터 적용
        if (_selectedRatingFilters.isNotEmpty) {
          localDiaries = localDiaries.where((diary) {
            for (final filter in _selectedRatingFilters) {
              if (filter.matches(diary.rating)) {
                return true;
              }
            }
            return false;
          }).toList();
        }
        
        // 날짜 필터 적용
        if (_startDate != null || _endDate != null) {
          localDiaries = localDiaries.where((diary) {
            if (_startDate != null && diary.date.isBefore(_startDate!)) {
              return false;
            }
            if (_endDate != null) {
              // endDate의 23:59:59까지 포함
              final adjustedEndDate = _endDate!.add(const Duration(days: 1));
              if (diary.date.isAfter(adjustedEndDate) || diary.date.isAtSameMomentAs(adjustedEndDate)) {
                return false;
              }
            }
            return true;
          }).toList();
        }
        
        // 비회원은 친구 필터 무시 (친구 기능 사용 불가)
        
        // 클라이언트 사이드 페이징
        final startIndex = _currentPage * _pageSize;
        final endIndex = startIndex + _pageSize;
        
        if (startIndex < localDiaries.length) {
          diaries = localDiaries.sublist(
            startIndex,
            endIndex > localDiaries.length ? localDiaries.length : endIndex,
          );
        } else {
          diaries = [];
        }
        
        if (mounted) {
          setState(() {
            if (diaries.length < _pageSize || startIndex + diaries.length >= localDiaries.length) {
              _hasMore = false;
            }
            
            _diaryList.addAll(diaries);
            _currentPage++;
          });
        }
      }
      
      if (mounted) {
        setState(() {
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
  
  // 필터 팝업 표시
  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DiaryFilterDialog(
        initialSearchQuery: _currentSearchQuery,
        initialSelectedFriends: _selectedFriends,
        initialSelectedRatings: _selectedRatingFilters,
        availableFriends: widget.friends,
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );
    
    if (result != null) {
      setState(() {
        _currentSearchQuery = result['searchQuery'];
        _selectedFriends.clear();
        _selectedFriends.addAll(result['selectedFriends'] ?? []);
        _selectedRatingFilters.clear();
        _selectedRatingFilters.addAll(result['selectedRatings'] ?? []);
        _startDate = result['startDate'];
        _endDate = result['endDate'];
      });
      _loadDiaries(reset: true);
    }
  }

  // 필터 초기화
  void _clearFilters() {
    setState(() {
      _selectedFriends.clear();
      _selectedRatingFilters.clear();
      _currentSearchQuery = null;
      _startDate = null;
      _endDate = null;
    });
    _loadDiaries(reset: true);
  }

  // 필터 요약 텍스트 생성
  String _buildFilterSummary() {
    List<String> parts = [];
    
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      parts.add('검색: "$_currentSearchQuery"');
    }
    
    // 회원만 친구 필터 표시
    if (AuthService.isLoggedIn && _selectedFriends.isNotEmpty) {
      final friendNames = _selectedFriends.map((f) => f.displayName).join(', ');
      parts.add('친구: $friendNames');
    }
    
    // 만족도 필터 표시
    if (_selectedRatingFilters.isNotEmpty) {
      final ratingNames = _selectedRatingFilters.map((f) => f.name).join(', ');
      parts.add('만족도: $ratingNames');
    }
    
    // 날짜 필터 표시
    if (_startDate != null || _endDate != null) {
      String dateText = '';
      if (_startDate != null && _endDate != null) {
        final start = _formatDate(_startDate!);
        final end = _formatDate(_endDate!);
        if (start == end) {
          dateText = start;
        } else {
          dateText = '$start ~ $end';
        }
      } else if (_startDate != null) {
        dateText = '${_formatDate(_startDate!)} 이후';
      } else if (_endDate != null) {
        dateText = '${_formatDate(_endDate!)} 이전';
      }
      parts.add('기간: $dateText');
    }
    
    return parts.join(' • ');
  }
  
  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
  
  // 필터가 적용되어 있는지 확인
  bool get _hasActiveFilters => 
      (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) ||
      _selectedFriends.isNotEmpty ||
      _selectedRatingFilters.isNotEmpty ||
      _startDate != null ||
      _endDate != null;

  // 일지 추가
  void _addDiary(DiaryEntry newEntry) {
    setState(() {
      _diaryList.insert(0, newEntry);
    });
    // 메인 화면 데이터 새로고침
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
    // 메인 화면 데이터 새로고침
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
            onAddFriend: widget.onAddFriend,
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
          if (kDebugMode) {
            print('🗑️ 일지 삭제 시작: ID=${entry.id}, 로그인 여부=${AuthService.isLoggedIn}');
          }
          
          if (AuthService.isLoggedIn) {
            // 회원: 데이터베이스에서 삭제
            await DatabaseService.deleteDiaryEntry(entry.id);
          } else {
            // 비회원: 로컬에서 삭제
            await LocalStorageService.deleteDiary(entry.id);
          }
          
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
            icon: Icon(
              Icons.filter_list,
              color: _hasActiveFilters 
                  ? Theme.of(context).primaryColor 
                  : null,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 요약 정보
          if (_hasActiveFilters)
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
                      padding: const EdgeInsets.fromLTRB(
                        16, 
                        16, 
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WriteDiaryScreen(
                friends: widget.friends,
                onAddFriend: widget.onAddFriend,
                isLoggedIn: AuthService.isLoggedIn, // 현재 로그인 상태 전달
              ),
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