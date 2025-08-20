// 플러터의 기본 Material Design 위젯들을 사용하기 위한 import
import 'package:flutter/material.dart';
// 다이어리 엔트리 데이터 모델 import
import 'package:jiyong_in_the_room/models/diary.dart';
// 카페와 테마 데이터 모델 import
// 사용자와 친구 데이터 모델 import
import 'package:jiyong_in_the_room/models/user.dart';
// 데이터베이스 서비스 import
import 'package:jiyong_in_the_room/services/database_service.dart';
// 인증 서비스 import
import 'package:jiyong_in_the_room/services/auth_service.dart';

// 일지 수정 화면 - 기존 일지 엔트리를 수정하는 위젯
class EditDiaryScreen extends StatefulWidget {
  // 수정할 기존 일지 엔트리 데이터
  final DiaryEntry entry;
  // 선택 가능한 친구 목록
  final List<Friend> friends;

  // const 생성자: 컴파일 타임에 값이 결정되는 생성자
  // required: 필수 매개변수임을 표시
  const EditDiaryScreen({
    super.key,
    required this.entry,
    required this.friends,
  });

  // createState(): StatefulWidget의 상태 객체를 생성하는 메서드
  @override
  State<EditDiaryScreen> createState() => _EditDiaryScreenState();
}

// 수정 화면의 상태를 관리하는 State 클래스
class _EditDiaryScreenState extends State<EditDiaryScreen> {
  // 카페별 테마 목록을 저장하는 Map
  final Map<String, List<String>> cafeThemes = {
    '비밀의화원': ['유령의집', '황금마차'],
    '키이스': ['타임머신', '사라진 도시'],
    '넥스트에디션': ['미궁의탑', '어둠의 마법서'],
  };

  // 수정 중인 데이터를 저장하는 변수들
  String? selectedCafe;
  String? selectedTheme;
  DateTime? selectedDate;

  // 선택된 친구들을 저장하는 리스트
  final List<Friend> selectedFriends = [];
  // 각 입력 필드를 제어하는 컨트롤러들
  final TextEditingController _cafeController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController friendSearchController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  // 게임 관련 데이터를 저장하는 변수들
  double _rating = 3.0;        // 별점 평가
  bool? _escaped;              // 탈출 성공 여부
  int? _hintUsedCount;         // 힌트 사용 횟수
  Duration? _timeTaken;        // 게임 소요 시간
  bool _showDetails = false;   // 상세 정보 표시 여부

  // initState(): 위젯이 처음 생성될 때 한 번만 호출되는 메서드
  // 기존 데이터로 필드들을 초기화하기 위해 사용
  @override
  void initState() {
    super.initState();
    _initializeFields(); // 기존 데이터로 필드 초기화
  }

  // 기존 일지 데이터로 모든 필드를 초기화하는 메서드
  void _initializeFields() {
    // widget.entry: 부모 위젯에서 전달받은 기존 일지 데이터
    selectedCafe = widget.entry.cafe?.name ?? '알 수 없음';
    selectedTheme = widget.entry.theme?.name ?? '알 수 없는 테마';
    selectedDate = widget.entry.date;
    
    // TextEditingController에 기존 값을 설정
    _cafeController.text = selectedCafe!;
    _themeController.text = selectedTheme!;
    
    // 기존에 선택된 친구들이 있다면 추가
    if (widget.entry.friends != null) {
      selectedFriends.addAll(widget.entry.friends!);
    }
    
    // 기존 메모가 있다면 설정
    if (widget.entry.memo != null) {
      _memoController.text = widget.entry.memo!;
    }
    
    // 기존 별점이 있다면 설정
    if (widget.entry.rating != null) {
      _rating = widget.entry.rating!;
    }
    
    // 게임 결과 데이터 설정
    _escaped = widget.entry.escaped;
    _hintUsedCount = widget.entry.hintUsedCount;
    _timeTaken = widget.entry.timeTaken;
    
    // 힌트 사용 횟수를 텍스트로 변환하여 설정
    if (widget.entry.hintUsedCount != null) {
      _hintController.text = widget.entry.hintUsedCount.toString();
    }
    
    // 소요 시간을 분 단위로 변환하여 설정
    if (widget.entry.timeTaken != null) {
      _timeController.text = widget.entry.timeTaken!.inMinutes.toString();
    }
    
    // 추가 정보가 있다면 상세 정보 영역을 기본적으로 표시
    // ||(OR) 연산자: 하나라도 참이면 참
    _showDetails = widget.entry.memo != null || 
                   widget.entry.rating != null || 
                   widget.entry.escaped != null || 
                   widget.entry.hintUsedCount != null || 
                   widget.entry.timeTaken != null;
  }

  @override
  void dispose() {
    _cafeController.dispose();
    _themeController.dispose();
    _memoController.dispose();
    _hintController.dispose();
    _timeController.dispose();
    super.dispose();
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
      const starWidth = 36.0; // 32 (icon size) + 4 (padding)
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
    final selectedDateStr =
        selectedDate != null
            ? selectedDate!.toLocal().toString().split(' ')[0]
            : '날짜를 선택하세요';

    return Scaffold(
      appBar: AppBar(title: const Text('일지 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
            Row(
              children: [
                Expanded(child: Text('선택한 날짜: $selectedDateStr')),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('날짜 선택'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            RawAutocomplete<String>(
              textEditingController: _cafeController,
              focusNode: FocusNode(),
              optionsBuilder: (text) {
                return cafeThemes.keys
                    .where((cafe) => cafe.contains(text.text))
                    .toList();
              },
              onSelected: (value) {
                setState(() {
                  selectedCafe = value;
                  selectedTheme = null;
                  _themeController.clear();
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
                  decoration: const InputDecoration(
                    labelText: '방탈출 카페',
                    border: OutlineInputBorder(),
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
                            title: Text(option),
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
            RawAutocomplete<String>(
              textEditingController: _themeController,
              focusNode: FocusNode(),
              optionsBuilder: (text) {
                if (selectedCafe == null) return const Iterable<String>.empty();
                final themes = cafeThemes[selectedCafe]!;
                return themes.where((t) => t.contains(text.text)).toList();
              },
              onSelected: (value) {
                setState(() {
                  selectedTheme = value;
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
                            title: Text(option),
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
                  decoration: const InputDecoration(
                    labelText: '친구 검색',
                    border: OutlineInputBorder(),
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
            Wrap(
              spacing: 8,
              children:
                  selectedFriends.map((friend) {
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
            // 버튼들을 가로로 배치
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 삭제 버튼
                ElevatedButton.icon(
                  onPressed: () async {
                    // 현재 사용자가 작성자인지 확인
                    final currentUserId = AuthService.currentUser?.id;
                    final isAuthor = widget.entry.userId == currentUserId;
                    
                    // 사용자 역할에 따른 메시지
                    final String title = isAuthor ? '일지 삭제' : '참여 해제';
                    final String content = isAuthor 
                        ? '정말로 이 일지를 삭제하시겠습니까?\n일지가 완전히 삭제되며 복구할 수 없습니다.'
                        : '이 일지에서 나가시겠습니까?\n다른 참여자들은 계속 볼 수 있습니다.';
                    final String buttonText = isAuthor ? '삭제' : '나가기';
                    
                    // 삭제 확인 다이얼로그
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
                        // 데이터베이스에서 삭제
                        await DatabaseService.deleteDiaryEntry(widget.entry.id);
                        
                        // 삭제 성공 - 'deleted' 신호와 함께 화면 닫기
                        if (mounted) {
                          Navigator.pop(context, 'deleted');
                        }
                      } catch (e) {
                        // 삭제 실패 시 스낵바 표시
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
                      // 수정된 데이터로 새로운 DiaryEntry 객체 생성
                      final updatedEntry = DiaryEntry(
                        id: widget.entry.id, // 기존 ID 유지
                        userId: widget.entry.userId, // 기존 사용자 ID 유지
                        themeId: widget.entry.themeId, // 기존 테마 ID 유지
                        theme: widget.entry.theme, // 기존 테마 정보 유지
                        createdAt: widget.entry.createdAt, // 기존 생성일시 유지
                        updatedAt: DateTime.now(), // 수정일시는 현재 시간으로
                        date: selectedDate!,
                        friends: selectedFriends,
                        // 삼항연산자: 빈 텍스트면 null, 아니면 텍스트 값 사용
                        memo: _memoController.text.isEmpty ? null : _memoController.text,
                        rating: _rating,
                        escaped: _escaped,
                        hintUsedCount: _hintUsedCount,
                        timeTaken: _timeTaken,
                      );

                      // 데이터베이스에 수정 사항 저장
                      final savedEntry = await DatabaseService.updateDiaryEntry(updatedEntry);
                      
                      // 수정 성공 시 수정된 데이터와 함께 화면 닫기
                      if (mounted) {
                        Navigator.pop(context, savedEntry);
                      }
                    } catch (e) {
                      // 수정 실패 시 스낵바 표시
                      if (mounted) {
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
      ),
    );
  }
}