import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/escape_room_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/widgets/skeleton_widgets.dart';
import 'package:jiyong_in_the_room/widgets/common_input_fields.dart';

class EditDiaryScreen extends StatefulWidget {
  final DiaryEntry entry;
  final List<Friend> friends;
  final Function(DiaryEntry, DiaryEntry)? onUpdate;

  const EditDiaryScreen({
    super.key,
    required this.entry,
    required this.friends,
    this.onUpdate,
  });

  @override
  State<EditDiaryScreen> createState() => _EditDiaryScreenState();
}

class _EditDiaryScreenState extends State<EditDiaryScreen> {
  // 카페와 테마 데이터
  List<EscapeCafe> cafes = [];
  List<EscapeTheme> currentThemes = [];
  List<EscapeTheme> searchedThemes = [];
  bool isLoadingCafes = true;
  bool isLoadingThemes = false;
  bool isSearchingThemes = false;
  bool _isSaving = false; // 일지 저장 중인지 표시
  
  // 테마 필드의 포커스 노드
  final FocusNode _themeFocusNode = FocusNode();
  final FocusNode _friendSearchFocusNode = FocusNode();

  // 선택된 데이터
  EscapeCafe? selectedCafe;
  EscapeTheme? selectedTheme;
  DateTime? selectedDate;

  // 선택된 친구들
  final List<Friend> selectedFriends = [];
  
  // 컨트롤러들
  final TextEditingController _cafeController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController friendSearchController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  // 게임 관련 데이터
  double? _rating;
  bool? _escaped;
  int? _hintUsedCount;
  Duration? _timeTaken;
  bool _showDetails = false;
  bool _memoPublic = false;

  @override
  void initState() {
    super.initState();
    _loadCafes();
    _initializeFields();
  }

  @override
  void dispose() {
    _cafeController.dispose();
    _themeController.dispose();
    friendSearchController.dispose();
    _memoController.dispose();
    _hintController.dispose();
    _timeController.dispose();
    _themeFocusNode.dispose();
    _friendSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCafes() async {
    try {
      final loadedCafes = await EscapeRoomService.getAllCafes();
      
      setState(() {
        cafes = loadedCafes;
        isLoadingCafes = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCafes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카페 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  // 테마 검색 메서드 (2글자 이상 입력시에만 서버 검색)
  String? _lastSearchQuery; // 마지막 검색 쿼리를 저장하여 중복 검색 방지
  
  Future<void> _searchThemes(String query) async {
    final trimmedQuery = query.trim();
    print('_searchThemes called with: "$trimmedQuery"');
    
    if (trimmedQuery.length < 2) {
      print('Query too short, clearing results');
      setState(() {
        searchedThemes = [];
        isSearchingThemes = false;
        _lastSearchQuery = null;
      });
      return;
    }

    // 이미 같은 검색 결과가 있으면 스킵
    if (_lastSearchQuery == trimmedQuery && searchedThemes.isNotEmpty) {
      print('Already have results for "$trimmedQuery", skipping');
      return;
    }

    print('Starting search for: "$trimmedQuery"');
    setState(() {
      isSearchingThemes = true;
      _lastSearchQuery = trimmedQuery;
    });

    try {
      final results = await DatabaseService.searchThemes(trimmedQuery);
      print('Search completed, found ${results.length} results');
      if (mounted) {
        setState(() {
          searchedThemes = results;
          isSearchingThemes = false;
        });
        print('Updated searchedThemes: ${searchedThemes.map((t) => t.name).toList()}');
      }
    } catch (e) {
      print('Search failed: $e');
      if (mounted) {
        setState(() {
          searchedThemes = [];
          isSearchingThemes = false;
          _lastSearchQuery = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('테마 검색에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _loadThemesForCafe(int cafeId) async {
    print('Loading themes for cafe ID: $cafeId');
    setState(() {
      isLoadingThemes = true;
      currentThemes = [];
    });

    try {
      final loadedThemes = await EscapeRoomService.getThemesByCafe(cafeId);
      print('Loaded ${loadedThemes.length} themes');
      
      setState(() {
        currentThemes = loadedThemes;
        isLoadingThemes = false;
      });
    } catch (e) {
      print('Error loading themes: $e');
      setState(() {
        isLoadingThemes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('테마 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  void _initializeFields() {
    // 기존 데이터로 필드 초기화
    selectedCafe = widget.entry.theme?.cafe;
    selectedTheme = widget.entry.theme;
    selectedDate = widget.entry.date;
    
    // 컨트롤러 설정
    _cafeController.text = selectedCafe?.name ?? '';
    _themeController.text = selectedTheme?.name ?? '';
    
    // 기존 친구들 추가
    if (widget.entry.friends != null) {
      selectedFriends.addAll(widget.entry.friends!);
    }
    
    // 기존 메모
    if (widget.entry.memo != null) {
      _memoController.text = widget.entry.memo!;
    }
    
    // 메모 공개 설정
    _memoPublic = widget.entry.memoPublic;
    
    // 게임 데이터
    _rating = widget.entry.rating;
    _escaped = widget.entry.escaped;
    _hintUsedCount = widget.entry.hintUsedCount;
    _timeTaken = widget.entry.timeTaken;
    
    if (widget.entry.hintUsedCount != null) {
      _hintController.text = widget.entry.hintUsedCount.toString();
    }
    
    if (widget.entry.timeTaken != null) {
      _timeController.text = widget.entry.timeTaken!.inMinutes.toString();
    }
    
    // 추가 정보가 있다면 상세 정보 영역을 기본적으로 표시
    _showDetails = widget.entry.memo != null || 
                   widget.entry.rating != null || 
                   widget.entry.escaped != null || 
                   widget.entry.hintUsedCount != null || 
                   widget.entry.timeTaken != null;

    // 카페가 선택되어 있으면 테마 목록 로드
    if (selectedCafe != null) {
      _loadThemesForCafe(selectedCafe!.id);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _updateRating(double position) {
    setState(() {
      const starWidth = 36.0;
      final starIndex = (position / starWidth).floor();
      final positionInStar = position % starWidth;
      
      if (starIndex >= 0 && starIndex < 5) {
        if (positionInStar < starWidth / 2) {
          _rating = (starIndex + 0.5).clamp(0.5, 5.0);
        } else {
          _rating = (starIndex + 1.0).clamp(0.5, 5.0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = selectedDate != null
        ? selectedDate!.toLocal().toString().split(' ')[0]
        : '날짜를 선택하세요';

    return Scaffold(
      appBar: AppBar(title: const Text('일지 수정')),
      body: LoadingOverlay(
        isLoading: _isSaving,
        message: '일지를 수정하는 중...',
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CommonDateField(
                selectedDate: selectedDate,
                labelText: '탈출 날짜',
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),
              
              // 카페 선택
              if (isLoadingCafes)
                const Center(child: CircularProgressIndicator())
              else
                CommonAutocompleteField<EscapeCafe>(
                  controller: _cafeController,
                  labelText: '방탈출 카페',
                  optionsBuilder: (text) {
                    final searchQuery = text.text.toLowerCase().replaceAll(' ', '');
                    return cafes
                        .where((cafe) {
                          final cafeName = cafe.name.toLowerCase().replaceAll(' ', '');
                          return cafeName.contains(searchQuery);
                        })
                        .toList();
                  },
                  onSelected: (cafe) {
                    print('Cafe selected: ${cafe.name} (ID: ${cafe.id})');
                    setState(() {
                      selectedCafe = cafe;
                      if (selectedTheme?.cafe?.id != cafe.id) {
                        selectedTheme = null;
                        _themeController.clear();
                      }
                    });
                    _cafeController.text = cafe.name;
                    FocusScope.of(context).unfocus();
                    _loadThemesForCafe(cafe.id);
                  },
                  displayStringForOption: (cafe) => cafe.name,
                  suffixIcon: selectedCafe != null 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _cafeController.text.isNotEmpty
                          ? const Icon(Icons.edit, color: Colors.orange)
                          : null,
                  optionsViewBuilder: (context, onSelected, options) {
                    return Stack(
                      children: [
                        // 전체 화면을 덮는 투명한 터치 감지 영역
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              // 바깥쪽 클릭 시 포커스 해제하여 옵션박스 닫기
                              FocusScope.of(context).unfocus();
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(),
                          ),
                        ),
                        // 실제 옵션 리스트
                        Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option.name),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 20),
              
              // 테마 선택
              CommonAutocompleteField<EscapeTheme>(
                controller: _themeController,
                focusNode: _themeFocusNode,
                labelText: '테마 선택',
                hintText: selectedCafe != null 
                    ? '${selectedCafe!.name}의 테마를 선택하거나 다른 테마를 검색하세요'
                    : '테마를 검색하세요 (2글자 이상 입력)',
                displayStringForOption: (theme) => theme.name,
                suffixIcon: selectedTheme != null 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : isSearchingThemes
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _themeController.text.isNotEmpty
                            ? const Icon(Icons.search, color: Colors.orange)
                            : null,
                optionsBuilder: (text) {
                  print('optionsBuilder called - text: "${text.text}", selectedCafe: ${selectedCafe?.name}, currentThemes: ${currentThemes.length}, searchedThemes: ${searchedThemes.length}, selectedTheme: ${selectedTheme?.name}');
                  
                  // 테마가 이미 선택된 경우 빈 목록 반환 (수정하려는 경우 제외)
                  if (selectedTheme != null) {
                    // 현재 입력된 텍스트가 선택된 테마 이름과 다르면 수정 중인 것으로 간주
                    if (text.text == selectedTheme!.name) {
                      print('Returning empty - theme selected and text matches');
                      return const Iterable<EscapeTheme>.empty();
                    } else {
                      // 선택된 테마와 다른 텍스트가 입력되면 선택 해제
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            selectedTheme = null;
                          });
                        }
                      });
                    }
                  }
                  
                  final query = text.text.trim();
                  print('Search query: "$query", length: ${query.length}');
                  
                  // 검색어가 2글자 이상이면 서버 검색 트리거
                  if (query.length >= 2) {
                    print('Query >= 2, checking existing results');
                    // 이미 같은 검색 결과가 있는지 확인
                    if (_lastSearchQuery != query || searchedThemes.isEmpty) {
                      print('Triggering search for: "$query"');
                      // 비동기 검색 시작
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _searchThemes(query);
                      });
                      // 검색 중일 때 로딩 상태를 표시하기 위해 더미 결과 반환
                      if (searchedThemes.isEmpty) {
                        return [EscapeTheme(
                          id: -1, 
                          name: '검색 중...', 
                          cafeId: -1,
                        )];
                      }
                    }
                    // 현재 검색된 결과 반환
                    print('Returning ${searchedThemes.length} searched themes');
                    return searchedThemes;
                  }
                  
                  // 카페가 선택되어 있고 검색어가 짧으면 해당 카페의 테마들
                  if (selectedCafe != null && !isLoadingThemes && currentThemes.isNotEmpty && query.length < 2) {
                    if (query.isEmpty) {
                      print('Returning ${currentThemes.length} current themes');
                      return currentThemes;
                    } else {
                      // 1글자 검색은 로컬에서 필터링
                      final filtered = currentThemes.where((theme) {
                        final themeName = theme.name.toLowerCase();
                        return themeName.contains(query.toLowerCase());
                      }).toList();
                      print('Returning ${filtered.length} locally filtered themes');
                      return filtered;
                    }
                  }
                  
                  print('Returning empty list');
                  return const Iterable<EscapeTheme>.empty();
                },
                onSelected: (theme) {
                  // 더미 로딩 항목 무시
                  if (theme.id == -1) {
                    return;
                  }
                  setState(() {
                    selectedTheme = theme;
                    // 테마가 선택되면 해당 카페도 자동으로 설정
                    if (selectedCafe?.id != theme.cafe?.id) {
                      selectedCafe = theme.cafe;
                      _cafeController.text = theme.cafe?.name ?? '';
                      if (theme.cafe != null) {
                        _loadThemesForCafe(theme.cafe!.id);
                      }
                    }
                  });
                  _themeController.text = theme.name;
                  _themeFocusNode.unfocus();
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Stack(
                    children: [
                      // 전체 화면을 덮는 투명한 터치 감지 영역
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            // 바깥쪽 클릭 시 포커스 해제하여 옵션박스 닫기
                            FocusScope.of(context).unfocus();
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Container(),
                        ),
                      ),
                      // 실제 옵션 리스트
                      Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option.name),
                                  subtitle: Text(option.cafe?.name ?? ''),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              
              // 친구 선택
              CommonAutocompleteField<Friend>(
                controller: friendSearchController,
                focusNode: _friendSearchFocusNode,
                labelText: '친구 검색',
                optionsBuilder: (textEditingValue) {
                  final availableFriends = widget.friends
                      .where((f) => !selectedFriends.contains(f))
                      .toList();
                  
                  if (textEditingValue.text.isEmpty) {
                    return availableFriends;
                  }
                  
                  final searchQuery = textEditingValue.text.toLowerCase().replaceAll(' ', '');
                  return availableFriends
                      .where((f) {
                        final friendName = f.displayName.toLowerCase().replaceAll(' ', '');
                        return friendName.contains(searchQuery);
                      })
                      .toList();
                },
                onSelected: (Friend selected) {
                  setState(() {
                    selectedFriends.add(selected);
                    friendSearchController.clear();
                  });
                  _friendSearchFocusNode.unfocus();
                },
                displayStringForOption: (friend) => friend.displayName,
                suffixIcon: friendSearchController.text.isNotEmpty
                    ? const Icon(Icons.search, color: Colors.orange)
                    : null,
                optionsViewBuilder: (context, onSelected, options) {
                  return Stack(
                    children: [
                      // 전체 화면을 덮는 투명한 터치 감지 영역
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            // 바깥쪽 클릭 시 포커스 해제하여 옵션박스 닫기
                            FocusScope.of(context).unfocus();
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Container(),
                        ),
                      ),
                      // 실제 옵션 리스트
                      Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option.displayName),
                                  subtitle: option.isConnected && option.realName != null 
                                      ? Text(option.realName!) 
                                      : null,
                                  leading: Icon(
                                    option.isConnected ? Icons.link : Icons.link_off,
                                    size: 16,
                                    color: option.isConnected ? Colors.green : Colors.grey,
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              // 선택된 친구들
              Wrap(
                spacing: 8,
                children: selectedFriends.map((friend) {
                  return Chip(
                    label: Text(friend.displayName),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        selectedFriends.remove(friend);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              // 상세 정보 토글
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showDetails = !_showDetails;
                  });
                },
                icon: Icon(_showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                label: Text(_showDetails ? '간단히' : '자세히'),
              ),
              
              if (_showDetails) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('평점: '),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTapDown: (details) => _updateRating(details.localPosition.dx),
                      onPanUpdate: (details) => _updateRating(details.localPosition.dx),
                      child: Row(
                        children: List.generate(5, (index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.star_border,
                                  color: Colors.grey[400],
                                  size: 32,
                                ),
                                if (_rating != null && _rating! > index) ...[
                                  if (_rating! >= index + 1)
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 32,
                                    )
                                  else
                                    ClipRect(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: 0.5,
                                        child: const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(_rating?.toStringAsFixed(1) ?? '-'),
                    if (_rating != null) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _rating = null;
                          });
                        },
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: '평점 제거',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('탈출 결과: '),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _escaped,
                          onChanged: (value) {
                            setState(() {
                              _escaped = value;
                            });
                          },
                        ),
                        const Text('성공'),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _escaped,
                          onChanged: (value) {
                            setState(() {
                              _escaped = value;
                            });
                          },
                        ),
                        const Text('실패'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        controller: _hintController,
                        labelText: '힌트 사용 횟수',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _hintUsedCount = int.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CommonTextField(
                        controller: _timeController,
                        labelText: '소요시간 (분)',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final minutes = int.tryParse(value);
                          if (minutes != null) {
                            _timeTaken = Duration(minutes: minutes);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CommonTextArea(
                  controller: _memoController,
                  labelText: '메모',
                  maxLines: 3,
                  onChanged: (value) {
                    // 메모 내용 변경 시 UI 업데이트 (체크박스 표시/숨김용)
                    setState(() {});
                  },
                ),
                
                // 메모가 있을 때만 공개 옵션 표시
                // if (_memoController.text.isNotEmpty) ...[
                //   CheckboxListTile(
                //     title: const Text(
                //       '친구들에게 메모 공개',
                //       style: TextStyle(fontSize: 16),
                //     ),
                //     subtitle: const Text(
                //       '같은 테마를 플레이한 친구들이 볼 수 있어요',
                //       style: TextStyle(fontSize: 12),
                //     ),
                //     value: _memoPublic,
                //     onChanged: (value) {
                //       setState(() {
                //         _memoPublic = value ?? false;
                //       });
                //     },
                //     controlAffinity: ListTileControlAffinity.leading,
                //     contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                //   ),
                // ],
              ],
              const SizedBox(height: 20),
              
              // 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 삭제 버튼
                  ElevatedButton.icon(
                    onPressed: () async {
                      final currentUserId = AuthService.currentUser?.id;
                      final isAuthor = widget.entry.userId == currentUserId;
                      
                      final String title = isAuthor ? '일지 삭제' : '참여 해제';
                      final String content = isAuthor 
                          ? '정말로 이 일지를 삭제하시겠습니까?\n일지가 완전히 삭제되며 복구할 수 없습니다.'
                          : '이 일지에서 나가시겠습니까?\n다른 참여자들은 계속 볼 수 있습니다.';
                      final String buttonText = isAuthor ? '삭제' : '나가기';
                      
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(title),
                          content: Text(content),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(buttonText),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await DatabaseService.deleteDiaryEntry(widget.entry.id);
                          
                          if (mounted) {
                            Navigator.pop(context, 'deleted');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('삭제 실패: $e')),
                            );
                          }
                        }
                      }
                    },
                    icon: Icon(AuthService.currentUser?.id == widget.entry.userId 
                        ? Icons.delete 
                        : Icons.exit_to_app),
                    label: Text(AuthService.currentUser?.id == widget.entry.userId 
                        ? '삭제' 
                        : '나가기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[800],
                    ),
                  ),
                  
                  // 수정 완료 버튼
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedCafe == null ||
                          selectedTheme == null ||
                          selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('모든 항목을 선택해주세요')),
                        );
                        return;
                      }

                      try {
                        // 저장 상태 표시
                        setState(() {
                          _isSaving = true;
                        });

                        // 수정된 데이터로 DiaryEntry 생성
                        final updatedEntry = DiaryEntry(
                          id: widget.entry.id,
                          userId: widget.entry.userId,
                          themeId: selectedTheme!.id,
                          theme: selectedTheme,
                          date: selectedDate!,
                          friends: null, // 별도 테이블로 관리
                          memo: _memoController.text.isEmpty ? null : _memoController.text,
                          memoPublic: _memoController.text.isNotEmpty ? _memoPublic : false,
                          rating: _rating,
                          escaped: _escaped,
                          hintUsedCount: _hintUsedCount,
                          timeTaken: _timeTaken,
                          photos: widget.entry.photos,
                          createdAt: widget.entry.createdAt,
                          updatedAt: DateTime.now(),
                        );

                        // 친구 ID 목록 생성
                        final friendIds = selectedFriends
                            .where((friend) => friend.id != null)
                            .map((friend) => friend.id!)
                            .toList();
                        
                        // 데이터베이스에 수정 사항 저장
                        // 수정 시에는 기존 참여자 구조 유지하면서 선택된 친구들로 업데이트
                        final savedEntry = await DatabaseService.updateDiaryEntry(
                          updatedEntry,
                          friendIds: friendIds.isNotEmpty ? friendIds : null,
                        );
                        
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                          
                          // 성공 메시지
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('일지가 수정되었습니다!')),
                          );
                          
                          // 업데이트 콜백 호출 (부모 화면에서 데이터 갱신용)
                          if (widget.onUpdate != null) {
                            widget.onUpdate!(widget.entry, savedEntry);
                          }
                          
                          // 수정된 데이터와 함께 화면 닫기
                          Navigator.pop(context, savedEntry);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                          
                          // 에러 메시지
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('수정 실패: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('수정 완료'),
                  ),
                ],
              ),
            ],
          ),
        ),
        ), // LoadingOverlay 닫기
      ),
    );
  }
}