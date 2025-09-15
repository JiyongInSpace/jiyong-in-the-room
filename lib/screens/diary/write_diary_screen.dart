// 플러터의 기본 Material Design 위젯들을 사용하기 위한 import
import 'package:flutter/material.dart';
// 사용자 정의 모델 클래스 import (Friend 모델 사용)
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/services/escape_room_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:jiyong_in_the_room/services/friend_service.dart';
import 'package:jiyong_in_the_room/widgets/skeleton_widgets.dart';
import 'package:jiyong_in_the_room/utils/rating_utils.dart';
import 'package:jiyong_in_the_room/widgets/common_input_fields.dart';
import 'dart:async';

// StatefulWidget: 상태가 변할 수 있는 위젯 클래스
// 사용자 입력에 따라 화면이 바뀌어야 하므로 StatefulWidget 사용
class WriteDiaryScreen extends StatefulWidget {
  final List<Friend> friends;
  final Function(Friend)? onAddFriend;
  final bool isLoggedIn; // 로그인 상태

  const WriteDiaryScreen({
    super.key, 
    required this.friends, 
    this.onAddFriend,
    this.isLoggedIn = false, // 기본값 false
  });

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

// State 클래스: StatefulWidget의 실제 상태와 UI 로직을 담당
class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  // 카페와 테마 데이터
  List<EscapeCafe> cafes = [];
  List<EscapeTheme> currentThemes = []; // 현재 선택된 카페의 테마들
  List<EscapeTheme> searchedThemes = []; // 검색된 테마들 (테마 직접 검색용)
  bool isLoadingCafes = true;
  bool isLoadingThemes = false;
  bool isSearchingThemes = false; // 테마 검색 중인지 표시
  bool _isSaving = false; // 일지 저장 중인지 표시

  // 테마 필드의 포커스 노드
  final FocusNode _themeFocusNode = FocusNode();
  // 친구 검색 필드의 포커스 노드
  final FocusNode _friendSearchFocusNode = FocusNode();

  // 사용자가 선택한 카페를 저장하는 변수
  EscapeCafe? selectedCafe;
  // 사용자가 선택한 테마를 저장하는 변수
  EscapeTheme? selectedTheme;
  // 사용자가 선택한 날짜를 저장하는 변수
  DateTime? selectedDate;

  // List<타입>: 여러 개의 같은 타입 데이터를 순서대로 저장하는 자료구조
  // 선택된 친구들을 저장하는 리스트
  final List<Friend> selectedFriends = [];

  // TextEditingController: TextField의 텍스트 입력을 제어하는 컨트롤러
  // 각 입력 필드마다 별도의 컨트롤러가 필요함
  final TextEditingController _cafeController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController friendSearchController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // double?: nullable 소수점 타입
  // 별점 평가를 저장하는 변수 (기본값 null - 평가하지 않은 상태)
  double? _rating;
  // bool?: null이 될 수 있는 불린(참/거짓) 타입
  // 탈출 성공 여부를 저장하는 변수 (기본값: 성공)
  bool? _escaped = true;
  // int?: null이 될 수 있는 정수 타입
  // 힌트 사용 횟수를 저장하는 변수
  int? _hintUsedCount;
  // Duration?: null이 될 수 있는 시간 간격 타입
  // 게임에 걸린 시간을 저장하는 변수
  Duration? _timeTaken;
  // bool: 불린 타입 (true/false만 가능)
  // 상세 정보 표시 여부를 저장하는 변수
  bool _showDetails = false;
  // 메모 공개 여부를 저장하는 변수
  final bool _memoPublic = false;
  // 친구 일지에도 추가할지 여부 (기본값: false - 안전한 쪽으로)
  final bool _addToFriendsJournal = false;

  @override
  void initState() {
    super.initState();
    _loadCafes();

    // 날짜를 오늘 날짜로 기본 설정
    selectedDate = DateTime.now();
    
    // 비회원도 친구 기능 사용 가능
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('카페 목록을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  // 테마 검색 메서드 (2글자 이상 입력시에만 서버 검색)
  String? _lastSearchQuery; // 마지막 검색 쿼리를 저장하여 중복 검색 방지
  Timer? _searchTimer; // 디바운싱을 위한 타이머

  void _searchThemesWithDebounce(String query) {
    // 이전 타이머 취소
    _searchTimer?.cancel();

    // 300ms 후에 검색 실행
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _searchThemes(query);
    });
  }

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
        print(
          'Updated searchedThemes: ${searchedThemes.map((t) => t.name).toList()}',
        );

        // 테마가 선택되어 있지 않을 때만 UI 갱신을 위한 텍스트 조작 수행
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              selectedTheme == null &&
              _themeController.text.trim() == trimmedQuery) {
            final currentText = _themeController.text;
            _themeController.text = '$currentText ';
            _themeController.text = currentText;
          }
        });
      }
    } catch (e) {
      print('Search failed: $e');
      if (mounted) {
        setState(() {
          searchedThemes = [];
          isSearchingThemes = false;
          _lastSearchQuery = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('테마 검색에 실패했습니다: $e')));
      }
    }
  }

  Future<void> _loadThemesForCafe(int cafeId) async {
    print('Loading themes for cafe ID: $cafeId');
    setState(() {
      isLoadingThemes = true;
      currentThemes = [];
      selectedTheme = null;
      _themeController.clear();
    });

    try {
      final loadedThemes = await EscapeRoomService.getThemesByCafe(cafeId);
      print('Loaded ${loadedThemes.length} themes');

      setState(() {
        currentThemes = loadedThemes;
        isLoadingThemes = false;
      });

      // 테마 로딩 완료 후 포커스 주고 optionsBuilder 트리거 (테마가 아직 선택되지 않고, 테마 텍스트가 비어있는 경우에만)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && selectedTheme == null && _themeController.text.isEmpty) {
          _themeFocusNode.requestFocus();
          // 빈 스페이스를 추가했다가 바로 제거하여 optionsBuilder 트리거
          _themeController.text = ' ';
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              _themeController.text = '';
            }
          });
        }
      });
    } catch (e) {
      print('Error loading themes: $e');
      setState(() {
        isLoadingThemes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('테마 목록을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  // 테마 선택 후 카페의 테마 목록을 업데이트하는 메서드 (선택된 테마는 유지)
  Future<void> _loadThemesForCafeWithoutClearingSelection(
    int cafeId,
    EscapeTheme selectedThemeToKeep,
  ) async {
    print(
      'Loading themes for cafe ID: $cafeId (keeping selected theme: ${selectedThemeToKeep.name})',
    );
    setState(() {
      isLoadingThemes = true;
      // selectedTheme과 컨트롤러 텍스트는 유지
    });

    try {
      final loadedThemes = await EscapeRoomService.getThemesByCafe(cafeId);
      print('Loaded ${loadedThemes.length} themes');

      setState(() {
        currentThemes = loadedThemes;
        isLoadingThemes = false;
        // selectedTheme은 이미 설정되어 있으므로 건드리지 않음
      });
    } catch (e) {
      print('Error loading themes: $e');
      setState(() {
        isLoadingThemes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('테마 목록을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  // @override: 부모 클래스의 메서드를 재정의한다는 표시
  // dispose(): 위젯이 메모리에서 제거될 때 호출되는 메서드
  // TextEditingController 같은 리소스를 정리해야 메모리 누수 방지
  @override
  void dispose() {
    // 타이머 취소
    _searchTimer?.cancel();
    // 각 TextEditingController를 메모리에서 해제
    _cafeController.dispose();
    _themeController.dispose();
    _memoController.dispose();
    _hintController.dispose();
    _timeController.dispose();
    // 포커스 노드들도 해제
    _themeFocusNode.dispose();
    _friendSearchFocusNode.dispose();
    // 부모 클래스의 dispose() 메서드도 호출해야 함
    super.dispose();
  }

  // Future<void>: 비동기 작업을 나타내는 타입 (결과값 없음)
  // async: 비동기 메서드임을 표시
  // 날짜 선택 다이얼로그를 표시하는 메서드
  Future<void> _pickDate() async {
    // DateTime.now(): 현재 날짜와 시간을 가져옴
    final now = DateTime.now();
    // await: 비동기 작업이 완료될 때까지 기다림
    // showDatePicker(): 플러터에서 제공하는 날짜 선택 다이얼로그
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    // 사용자가 날짜를 선택했는지 확인 (취소하면 null 반환)
    if (picked != null) {
      // setState(): 상태가 변경되었음을 플러터에 알려서 화면을 다시 그리게 함
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // 별점 드래그/클릭 시 만족도를 업데이트하는 메서드
  // position: 사용자가 터치한 가로 위치
  void _updateRating(double position) {
    setState(() {
      // const: 컴파일 타임에 값이 결정되는 상수
      const starWidth = 36.0; // 32 (icon size) + 4 (padding)
      // floor(): 소수점 이하를 버림 (몇 번째 별인지 계산)
      final starIndex = (position / starWidth).floor();
      // %: 나머지 연산자 (별 내에서의 위치 계산)
      final positionInStar = position % starWidth;

      if (starIndex >= 0 && starIndex < 5) {
        // 별의 왼쪽 절반을 클릭했는지 오른쪽 절반을 클릭했는지 판단
        if (positionInStar < starWidth / 2) {
          // clamp(): 값을 최소값과 최대값 사이로 제한
          _rating = (starIndex + 0.5).clamp(0.5, 5.0);
        } else {
          _rating = (starIndex + 1.0).clamp(0.5, 5.0);
        }
      }
    });
  }

  // build(): 위젯의 UI를 구성하는 메서드 (상태가 변경될 때마다 호출됨)
  // BuildContext: 위젯 트리에서 현재 위젯의 위치 정보를 담고 있는 객체
  @override
  Widget build(BuildContext context) {
    print(
      'Build - selectedCafe: ${selectedCafe?.name}, selectedTheme: ${selectedTheme?.name}, isLoadingThemes: $isLoadingThemes, currentThemes: ${currentThemes.length}',
    );

    // 삼항연산자 (조건 ? 참일때값 : 거짓일때값)
    // selectedDate!: null이 아님을 확신할 때 사용하는 연산자
    final selectedDateStr =
        selectedDate != null
            ? selectedDate!.toLocal().toString().split(' ')[0]
            : '날짜를 선택하세요';

    // Scaffold: 기본적인 화면 구조를 제공하는 위젯 (AppBar, Body 등)
    return Scaffold(
      // AppBar: 화면 상단에 제목과 뒒로가기 버튼을 표시하는 위젯
      appBar: AppBar(title: const Text('일지 작성')),
      // body: 화면의 주요 내용을 담는 영역
      // LoadingOverlay: 저장 중일 때 로딩 오버레이 표시
      body: LoadingOverlay(
        isLoading: _isSaving,
        message: '일지를 저장하는 중...',
        child: Padding(
          // 하단 80px + 기본 16px 여백
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
          // SingleChildScrollView: 내용이 화면을 넘을 때 스크롤 가능하게 하는 위젯
          child: SingleChildScrollView(
            // Column: 자식 위젯들을 세로로 배치하는 위젯
            child: Column(
              children: [
                CommonDateField(
                  selectedDate: selectedDate,
                  labelText: '탈출 날짜',
                  onTap: _pickDate,
                ),
                // SizedBox: 특정 크기의 빈 공간을 만드는 위젯 (여백 용도)
                const SizedBox(height: 20),
                // 카페 로딩 중이면 로딩 인디케이터 표시
                if (isLoadingCafes)
                  const Center(child: CircularProgressIndicator())
                else
                  CommonAutocompleteField<EscapeCafe>(
                    controller: _cafeController,
                    labelText: '방탈출 카페',
                    optionsBuilder: (text) {
                      final searchQuery = text.text.toLowerCase().replaceAll(
                        ' ',
                        '',
                      );
                      return cafes.where((cafe) {
                        final cafeName = cafe.name.toLowerCase().replaceAll(
                          ' ',
                          '',
                        );
                        return cafeName.contains(searchQuery);
                      }).toList();
                    },
                    onSelected: (cafe) {
                      print('Cafe selected: ${cafe.name} (ID: ${cafe.id})');
                      setState(() {
                        selectedCafe = cafe;
                      });
                      _cafeController.text = cafe.name;
                      FocusScope.of(context).unfocus();
                      _loadThemesForCafe(cafe.id);
                    },
                    displayStringForOption: (cafe) => cafe.name,
                    suffixIcon:
                        selectedCafe != null
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
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
                // 테마 선택 영역 - 카페를 먼저 선택하거나 모든 테마에서 직접 검색 가능
                CommonAutocompleteField<EscapeTheme>(
                  controller: _themeController,
                  focusNode: _themeFocusNode,
                  labelText: '테마 선택',
                  hintText:
                      selectedCafe != null
                          ? '${selectedCafe!.name}의 테마를 선택하거나 다른 테마를 검색하세요'
                          : '테마를 검색하세요 (2글자 이상 입력)',
                  displayStringForOption: (theme) => theme.name,
                  suffixIcon:
                      selectedTheme != null
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
                    final query = text.text.trim();

                    // 테마가 이미 선택된 경우 빈 목록 반환 (수정하려는 경우 제외)
                    if (selectedTheme != null) {
                      if (text.text == selectedTheme!.name) {
                        return const Iterable<EscapeTheme>.empty();
                      } else {
                        // 사용자가 직접 텍스트를 수정하는 경우만 선택 해제
                        // (검색 결과로 인한 자동 업데이트는 무시)
                        if (text.text.isNotEmpty &&
                            text.text != selectedTheme!.name) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted &&
                                _themeController.text != selectedTheme?.name) {
                              setState(() {
                                selectedTheme = null;
                                _lastSearchQuery = null; // 검색 쿼리도 초기화
                              });
                            }
                          });
                        }
                      }
                    }

                    // 검색어가 2글자 이상이면 서버 검색 트리거
                    if (query.length >= 2) {
                      print('Query >= 2, checking existing results');
                      // 이미 같은 검색 결과가 있는지 확인
                      if (_lastSearchQuery != query || searchedThemes.isEmpty) {
                        print('Triggering search for: "$query"');
                        // 비동기 검색 시작
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _searchThemesWithDebounce(query);
                        });
                        // 검색 중일 때도 기존 결과가 있으면 보여주기
                        if (searchedThemes.isEmpty) {
                          return [
                            EscapeTheme(id: -1, name: '검색 중...', cafeId: -1),
                          ];
                        }
                      }
                      // 현재 검색된 결과 반환 - 항상 최신 검색 결과 반환
                      print(
                        'Returning ${searchedThemes.length} searched themes',
                      );
                      return List<EscapeTheme>.from(
                        searchedThemes,
                      ); // 새로운 리스트로 반환하여 UI 갱신 보장
                    }

                    // 텍스트 길이가 2 미만인 경우
                    if (query.length < 2) {
                      // 카페가 선택되어 있으면 해당 카페의 테마들 표시
                      if (selectedCafe != null &&
                          !isLoadingThemes &&
                          currentThemes.isNotEmpty) {
                        if (query.isEmpty) {
                          return currentThemes;
                        } else {
                          // 1글자 검색은 로컬에서 필터링
                          final filtered =
                              currentThemes.where((theme) {
                                final themeName = theme.name.toLowerCase();
                                return themeName.contains(query.toLowerCase());
                              }).toList();
                          return filtered;
                        }
                      }

                      // 검색어도 짧고 카페도 선택되지 않았으면 최근 검색 결과라도 보여주자
                      if (searchedThemes.isNotEmpty && query.length == 1) {
                        final filtered =
                            searchedThemes.where((theme) {
                              final themeName = theme.name.toLowerCase();
                              return themeName.contains(query.toLowerCase());
                            }).toList();
                        return filtered;
                      }
                    }

                    return const Iterable<EscapeTheme>.empty();
                  },
                  onSelected: (theme) {
                    print(
                      'Theme onSelected called: ${theme.name} (ID: ${theme.id})',
                    );
                    // 더미 로딩 항목 무시
                    if (theme.id == -1) {
                      print('Ignoring dummy loading item');
                      return;
                    }
                    setState(() {
                      selectedTheme = theme;
                      print('Set selectedTheme: ${selectedTheme?.name}');
                      // 테마가 선택되면 해당 카페도 자동으로 설정
                      if (selectedCafe?.id != theme.cafe?.id) {
                        selectedCafe = theme.cafe;
                        _cafeController.text = theme.cafe?.name ?? '';
                        print('Auto-selected cafe: ${selectedCafe?.name}');
                        // 카페가 바뀌었지만 테마는 이미 선택되었으므로 테마 목록만 조용히 업데이트
                        if (theme.cafe != null) {
                          _loadThemesForCafeWithoutClearingSelection(
                            theme.cafe!.id,
                            theme,
                          );
                        }
                      }
                    });
                    _themeController.text = theme.name;
                    print(
                      'Set theme controller text: ${_themeController.text}',
                    );
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
                CommonAutocompleteField<Friend>(
                  controller: friendSearchController,
                  focusNode: _friendSearchFocusNode,
                  labelText: '친구 검색',
                  enabled: true, // 비회원도 사용 가능
                  optionsBuilder: (textEditingValue) {
                    final availableFriends =
                        widget.friends
                            .where((f) => !selectedFriends.contains(f))
                            .toList();

                    if (textEditingValue.text.isEmpty) {
                      return availableFriends;
                    }

                    final searchQuery = textEditingValue.text
                        .toLowerCase()
                        .replaceAll(' ', '');
                    final filteredFriends =
                        availableFriends.where((f) {
                          final friendName = f.displayName
                              .toLowerCase()
                              .replaceAll(' ', '');
                          return friendName.contains(searchQuery);
                        }).toList();

                    // 전체 친구 목록에서도 검색하여 이미 존재하는지 확인
                    final allMatchingFriends = widget.friends.where((f) {
                      final friendName = f.displayName
                          .toLowerCase()
                          .replaceAll(' ', '');
                      return friendName.contains(searchQuery);
                    }).toList();

                    // 검색 결과가 없고 (전체 목록에서도 없고) 검색어가 2글자 이상이면 "새 친구 추가" 옵션 표시
                    if (allMatchingFriends.isEmpty &&
                        textEditingValue.text.trim().length >= 2) {
                      return [
                        Friend(
                          id: -1, // 특별한 ID로 구분
                          nickname:
                              '+ "${textEditingValue.text.trim()}" 친구로 추가',
                          addedAt: DateTime.now(),
                        ),
                      ];
                    }

                    // 이미 선택된 친구인 경우 안내 메시지 표시
                    if (filteredFriends.isEmpty && allMatchingFriends.isNotEmpty) {
                      return [
                        Friend(
                          id: -2, // 안내 메시지용 특별한 ID
                          nickname: '이미 선택된 친구입니다',
                          addedAt: DateTime.now(),
                        ),
                      ];
                    }

                    return filteredFriends;
                  },
                  onSelected: (Friend selected) async {
                    // 비회원도 친구 선택 가능
                    
                    // 안내 메시지인 경우 아무 동작 안함
                    if (selected.id == -2) {
                      friendSearchController.clear();
                      _friendSearchFocusNode.unfocus();
                      return;
                    }
                    
                    // 새 친구 추가 옵션이 선택된 경우
                    if (selected.id == -1) {
                      
                      try {
                        // 새 친구 생성 - 실제 이름에서 "+" 부분 제거
                        final friendName = selected.nickname
                            .replaceAll(RegExp(r'^\+ "'), '')
                            .replaceAll(RegExp(r'" 친구로 추가$'), '');
                        
                        Friend savedFriend;
                        
                        // 통합 친구 서비스 사용
                        savedFriend = await FriendService.addFriend(
                          nickname: friendName,
                          memo: null,
                        );

                        // 부모 위젯의 친구 목록에도 추가
                        if (widget.onAddFriend != null) {
                          widget.onAddFriend!(savedFriend);
                        }

                        setState(() {
                          selectedFriends.add(savedFriend); // 실제 ID가 있는 객체 사용
                          friendSearchController.clear();
                        });

                        // 성공 메시지
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${savedFriend.nickname} 친구를 추가했습니다!',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('친구 추가 실패: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } else {
                      // 기존 친구 선택 (비회원도 가능하지만 DB에 있는 친구가 없을 것임)
                      setState(() {
                        selectedFriends.add(selected);
                        friendSearchController.clear();
                      });
                    }
                    _friendSearchFocusNode.unfocus();
                  },
                  displayStringForOption:
                      (friend) =>
                          friend.id == -1
                              ? friend.nickname
                              : friend.displayName,
                  suffixIcon:
                      friendSearchController.text.isNotEmpty
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

                                  // 안내 메시지인 경우
                                  if (option.id == -2) {
                                    return ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      title: Text(
                                        option.nickname,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      enabled: false,
                                    );
                                  }
                                  
                                  // 새 친구 추가 옵션인 경우
                                  if (option.id == -1) {
                                    return ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.person_add,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      title: Text(
                                        option.nickname,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        '새 친구로 추가하기',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  }

                                  // 기존 친구 옵션
                                  return ListTile(
                                    title: Text(option.nickname),
                                    subtitle:
                                        option.isConnected &&
                                                option.realName != null
                                            ? Text(option.realName!)
                                            : null,
                                    leading: Icon(
                                      option.isConnected
                                          ? Icons.link
                                          : Icons.link_off,
                                      size: 16,
                                      color:
                                          option.isConnected
                                              ? Colors.green
                                              : Colors.grey,
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
                  // Wrap: 자식 위젯들이 한 줄에 다 들어가지 않으면 다음 줄로 넘어가는 위젯
                  Wrap(
                    spacing: 8, // 아이템들 사이의 간격
                    children:
                        // map(): 리스트의 각 요소를 다른 형태로 변환
                        selectedFriends.map((friend) {
                          // 현재 사용자 ID 확인
                          final currentUserId = AuthService.currentUser?.id;
                          final isCurrentUser = currentUserId != null && 
                                               friend.connectedUserId == currentUserId;
                          
                          // Chip: 작은 정보 조각을 표시하는 위젯 (삭제 버튼 포함)
                          return Chip(
                            label: Text(friend.displayName),
                            deleteIcon: isCurrentUser ? null : const Icon(Icons.close),
                            // onDeleted: X 버튼을 눌렀을 때 실행되는 함수 (본인은 삭제 불가)
                            onDeleted: isCurrentUser ? null : () {
                              setState(() {
                                selectedFriends.remove(friend); // 선택된 친구 목록에서 제거
                              });
                            },
                          );
                        }).toList(), // map 결과를 List로 변환
                  ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  icon: Icon(
                    _showDetails
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  label: Text(_showDetails ? '간단히' : '자세히'),
                ),
                if (_showDetails) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('만족도: '),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTapDown:
                            (details) =>
                                _updateRating(details.localPosition.dx),
                        onPanUpdate:
                            (details) =>
                                _updateRating(details.localPosition.dx),
                        child: Row(
                          children: List.generate(5, (index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
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
                      RatingUtils.getRatingWidget(_rating, fontSize: 14),
                      if (_rating != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _rating = null;
                            });
                          },
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: '만족도 제거',
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
                          labelText: '소요 시간 (분)',
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

                  // 메모 공개 옵션은 현재 비활성화됨 (기능 제거)
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
                  const SizedBox(height: 20),

                  // 친구 일지 추가 기능은 현재 비활성화됨 (더 신중한 검토 필요)
                  // if (selectedFriends.isNotEmpty) ...[
                  //   CheckboxListTile(
                  //     title: const Text(
                  //       '친구 일지에도 추가하기',
                  //       style: TextStyle(fontSize: 16),
                  //     ),
                  //     subtitle: const Text(
                  //       '⚠️ 주의: 선택한 친구와 서로 친구 등록이 되어있다면 친구의 일지 목록에도 이 기록을 추가합니다. 날짜와 테마, 탈출 결과가 동일하게 기록되며, 만족도과 메모는 공유되지 않습니다.\n과거 날짜 일지 작성 시 신중하게 선택해주세요.',
                  //       style: TextStyle(fontSize: 12, color: Colors.orange),
                  //     ),
                  //     value: _addToFriendsJournal,
                  //     onChanged: (value) {
                  //       setState(() {
                  //         _addToFriendsJournal = value ?? false;
                  //       });
                  //     },
                  //     controlAffinity: ListTileControlAffinity.leading,
                  //     contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  //   ),
                  // ],
                ],
                const SizedBox(height: 20),
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

                      // DiaryEntry 생성
                      final now = DateTime.now();
                      
                      // 비회원/회원 분기
                      if (!widget.isLoggedIn) {
                        // ========== 비회원: 로컬 저장 ==========
                        final localEntry = DiaryEntry(
                          id: 0, // 로컬 저장소에서 자동 생성 (큰 양수로 교체될 예정)
                          userId: 'local_user', // 로컬 사용자 ID
                          themeId: selectedTheme!.id,
                          theme: selectedTheme,
                          date: selectedDate!,
                          friends: selectedFriends, // 비회원도 친구 기능 사용 가능
                          memo: _memoController.text.isEmpty
                              ? null
                              : _memoController.text,
                          memoPublic: _memoController.text.isNotEmpty
                              ? _memoPublic
                              : false,
                          rating: _rating,
                          escaped: _escaped,
                          hintUsedCount: _hintUsedCount,
                          timeTaken: _timeTaken,
                          photos: null,
                          createdAt: now,
                          updatedAt: now,
                        );

                        // 로컬에 저장
                        final savedEntry = await LocalStorageService.saveDiary(localEntry);

                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });

                          // 성공 메시지
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('일지가 저장되었습니다!'),
                              backgroundColor: Colors.blue,
                            ),
                          );

                          // 저장된 일지와 함께 이전 화면으로 돌아가기
                          Navigator.pop(context, savedEntry);
                        }
                      } else {
                        // ========== 회원: DB 저장 ==========
                        final newEntry = DiaryEntry(
                          id: 0, // DB에서 자동 생성
                          userId: AuthService.currentUser!.id,
                          themeId: selectedTheme!.id,
                          theme: selectedTheme,
                          date: selectedDate!,
                          friends: null, // 별도 테이블로 관리
                          memo: _memoController.text.isEmpty
                              ? null
                              : _memoController.text,
                          memoPublic: _memoController.text.isNotEmpty
                              ? _memoPublic
                              : false,
                          rating: _rating,
                          escaped: _escaped,
                          hintUsedCount: _hintUsedCount,
                          timeTaken: _timeTaken,
                          photos: null,
                          createdAt: now,
                          updatedAt: now,
                        );

                        // 친구 ID 목록 생성 (모든 선택된 친구)
                        final friendIds = selectedFriends
                            .where((friend) => friend.id != null)
                            .map((friend) => friend.id!)
                            .toList();

                        // DB에 저장
                        final savedEntry = await DatabaseService.addDiaryEntry(
                          newEntry,
                          friendIds: friendIds.isNotEmpty ? friendIds : null,
                          enableMutualFriendsEntries: false, // 친구 일지 공유 비활성화
                        );

                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });

                          // 성공 메시지
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('일지가 저장되었습니다!')),
                          );

                          // 저장된 일지와 함께 이전 화면으로 돌아가기
                          Navigator.pop(context, savedEntry);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });

                        // 에러 메시지
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('일지 저장에 실패했습니다: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      ), // LoadingOverlay 닫기
    );
  }
}
