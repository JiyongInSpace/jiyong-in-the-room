// 플러터의 기본 Material Design 위젯들을 사용하기 위한 import
import 'package:flutter/material.dart';
// 사용자 정의 모델 클래스 import (Friend 모델 사용)
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/services/escape_room_service.dart';

// StatefulWidget: 상태가 변할 수 있는 위젯 클래스
// 사용자 입력에 따라 화면이 바뀌어야 하므로 StatefulWidget 사용
class WriteDiaryScreen extends StatefulWidget {
  final List<Friend> friends;
  
  const WriteDiaryScreen({super.key, required this.friends});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

// State 클래스: StatefulWidget의 실제 상태와 UI 로직을 담당
class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  // 카페와 테마 데이터
  List<EscapeCafe> cafes = [];
  Map<int, List<EscapeTheme>> cafeThemes = {};
  bool isLoading = true;

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
  
  // double: 소수점을 포함한 숫자 타입
  // 별점 평가를 저장하는 변수 (기본값 3.0)
  double _rating = 3.0;
  // bool?: null이 될 수 있는 불린(참/거짓) 타입
  // 탈출 성공 여부를 저장하는 변수
  bool? _escaped;
  // int?: null이 될 수 있는 정수 타입
  // 힌트 사용 횟수를 저장하는 변수
  int? _hintUsedCount;
  // Duration?: null이 될 수 있는 시간 간격 타입
  // 게임에 걸린 시간을 저장하는 변수
  Duration? _timeTaken;
  // bool: 불린 타입 (true/false만 가능)
  // 상세 정보 표시 여부를 저장하는 변수
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _loadCafesAndThemes();
  }

  Future<void> _loadCafesAndThemes() async {
    try {
      final loadedCafes = await EscapeRoomService.getAllCafes();
      final loadedThemes = await EscapeRoomService.getThemesGroupedByCafe();
      
      setState(() {
        cafes = loadedCafes;
        cafeThemes = loadedThemes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  // @override: 부모 클래스의 메서드를 재정의한다는 표시
  // dispose(): 위젯이 메모리에서 제거될 때 호출되는 메서드
  // TextEditingController 같은 리소스를 정리해야 메모리 누수 방지
  @override
  void dispose() {
    // 각 TextEditingController를 메모리에서 해제
    _cafeController.dispose();
    _themeController.dispose();
    _memoController.dispose();
    _hintController.dispose();
    _timeController.dispose();
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

  // 별점 드래그/클릭 시 평점을 업데이트하는 메서드
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
      // Padding: 자식 위젯 주변에 여백을 주는 위젯
      body: Padding(
        // EdgeInsets.all(): 모든 방향에 동일한 여백 적용
        padding: const EdgeInsets.all(16.0),
        // SingleChildScrollView: 내용이 화면을 넘을 때 스크롤 가능하게 하는 위젯
        child: SingleChildScrollView(
          // Column: 자식 위젯들을 세로로 배치하는 위젯
          child: Column(
            children: [
            // Row: 자식 위젯들을 가로로 배치하는 위젯
            Row(
              children: [
                // Expanded: 남은 공간을 채우도록 확장하는 위젯
                Expanded(child: Text('선택한 날짜: $selectedDateStr')),
                // ElevatedButton: 입체감 있는 버튼 위젯
                // onPressed: 버튼이 눌렸을 때 실행할 함수
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('날짜 선택'),
                ),
              ],
            ),
            // SizedBox: 특정 크기의 빈 공간을 만드는 위젯 (여백 용도)
            const SizedBox(height: 20),
            // 로딩 중이면 로딩 인디케이터 표시
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              // RawAutocomplete<타입>: 자동완성 기능을 제공하는 위젯
              RawAutocomplete<EscapeCafe>(
                textEditingController: _cafeController,
                focusNode: FocusNode(),
                optionsBuilder: (text) {
                  return cafes
                      .where((cafe) => cafe.name.contains(text.text))
                      .toList();
                },
                onSelected: (cafe) {
                  setState(() {
                    selectedCafe = cafe;
                    selectedTheme = null;
                    _themeController.clear(); // 이전 테마 입력 초기화
                  });
                },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: '방탈출 카페',
                    border: const OutlineInputBorder(),
                    suffixIcon: selectedCafe != null 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : controller.text.isNotEmpty
                            ? const Icon(Icons.edit, color: Colors.orange)
                            : null,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
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
                );
              },
            ),
            const SizedBox(height: 20),
            if (!isLoading)
              RawAutocomplete<EscapeTheme>(
                textEditingController: _themeController,
                focusNode: FocusNode(),
                optionsBuilder: (text) {
                  if (selectedCafe == null) return const Iterable<EscapeTheme>.empty();
                  final themes = cafeThemes[selectedCafe!.id] ?? [];
                  return themes.where((theme) => theme.name.contains(text.text)).toList();
                },
                onSelected: (theme) {
                  setState(() {
                    selectedTheme = theme;
                  });
                },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: selectedCafe != null,
                  decoration: InputDecoration(
                    labelText: selectedCafe != null ? '테마 선택' : '먼저 카페를 선택해주세요',
                    border: const OutlineInputBorder(),
                    suffixIcon: selectedTheme != null 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : controller.text.isNotEmpty && selectedCafe != null
                            ? const Icon(Icons.edit, color: Colors.orange)
                            : null,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
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
                );
              },
            ),
            const SizedBox(height: 20),
            RawAutocomplete<Friend>(
              textEditingController: friendSearchController,
              focusNode: FocusNode(),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<Friend>.empty();
                }
                return widget.friends
                    .where(
                      (f) =>
                          f.displayName.contains(textEditingValue.text) &&
                          !selectedFriends.contains(f),
                    )
                    .toList();
              },
              onSelected: (Friend selected) {
                setState(() {
                  selectedFriends.add(selected);
                  friendSearchController.clear();
                });
              },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: '친구 검색',
                    border: const OutlineInputBorder(),
                    suffixIcon: controller.text.isNotEmpty
                        ? const Icon(Icons.search, color: Colors.orange)
                        : null,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
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
                );
              },
            ),
            // Wrap: 자식 위젯들이 한 줄에 다 들어가지 않으면 다음 줄로 넘어가는 위젯
            Wrap(
              spacing: 8, // 아이템들 사이의 간격
              children:
                  // map(): 리스트의 각 요소를 다른 형태로 변환
                  selectedFriends.map((friend) {
                    // Chip: 작은 정보 조각을 표시하는 위젯 (삭제 버튼 포함)
                    return Chip(
                      label: Text(friend.displayName),
                      deleteIcon: const Icon(Icons.close),
                      // onDeleted: X 버튼을 눌렀을 때 실행되는 함수
                      onDeleted: () {
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
              icon: Icon(_showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              label: Text(_showDetails ? '간단히' : '자세히'),
            ),
            if (_showDetails) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
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
                              if (_rating > index) ...[
                                if (_rating >= index + 1)
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
                  Text(_rating.toStringAsFixed(1)),
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
                    child: TextField(
                      controller: _hintController,
                      decoration: const InputDecoration(
                        labelText: '힌트 사용 횟수',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _hintUsedCount = int.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: '소요시간 (분)',
                        border: OutlineInputBorder(),
                      ),
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
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (selectedCafe == null ||
                    selectedTheme == null ||
                    selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 항목을 선택해주세요')),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'cafe': selectedCafe!.name,
                  'theme': selectedTheme!.name,
                  'selectedCafe': selectedCafe,
                  'selectedTheme': selectedTheme,
                  'date': selectedDate,
                  'friends': selectedFriends,
                  'memo': _memoController.text.isEmpty ? null : _memoController.text,
                  'rating': _rating,
                  'escaped': _escaped,
                  'hintUsedCount': _hintUsedCount,
                  'timeTaken': _timeTaken,
                });
              },
              child: const Text('저장'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
