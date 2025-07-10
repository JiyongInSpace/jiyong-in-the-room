import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/user.dart';

class EditDiaryScreen extends StatefulWidget {
  final DiaryEntry entry;
  final List<Friend> friends;

  const EditDiaryScreen({
    super.key,
    required this.entry,
    required this.friends,
  });

  @override
  State<EditDiaryScreen> createState() => _EditDiaryScreenState();
}

class _EditDiaryScreenState extends State<EditDiaryScreen> {
  final Map<String, List<String>> cafeThemes = {
    '비밀의화원': ['유령의집', '황금마차'],
    '키이스': ['타임머신', '사라진 도시'],
    '넥스트에디션': ['미궁의탑', '어둠의 마법서'],
  };

  String? selectedCafe;
  String? selectedTheme;
  DateTime? selectedDate;

  final List<Friend> selectedFriends = [];
  final TextEditingController _cafeController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController friendSearchController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  double _rating = 3.0;
  bool? _escaped;
  int? _hintUsedCount;
  Duration? _timeTaken;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    selectedCafe = widget.entry.cafe.name;
    selectedTheme = widget.entry.theme.name;
    selectedDate = widget.entry.date;
    
    _cafeController.text = selectedCafe!;
    _themeController.text = selectedTheme!;
    
    if (widget.entry.friends != null) {
      selectedFriends.addAll(widget.entry.friends!);
    }
    
    if (widget.entry.memo != null) {
      _memoController.text = widget.entry.memo!;
    }
    
    if (widget.entry.rating != null) {
      _rating = widget.entry.rating!;
    }
    
    _escaped = widget.entry.escaped;
    _hintUsedCount = widget.entry.hintUsedCount;
    _timeTaken = widget.entry.timeTaken;
    
    if (widget.entry.hintUsedCount != null) {
      _hintController.text = widget.entry.hintUsedCount.toString();
    }
    
    if (widget.entry.timeTaken != null) {
      _timeController.text = widget.entry.timeTaken!.inMinutes.toString();
    }
    
    // Show details if there's additional info
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

                final updatedEntry = DiaryEntry(
                  id: widget.entry.id,
                  theme: EscapeTheme(
                    id: widget.entry.theme.id,
                    name: selectedTheme!,
                    cafe: EscapeCafe(
                      id: widget.entry.cafe.id,
                      name: selectedCafe!,
                    ),
                    difficulty: widget.entry.theme.difficulty,
                  ),
                  date: selectedDate!,
                  friends: selectedFriends,
                  memo: _memoController.text.isEmpty ? null : _memoController.text,
                  rating: _rating,
                  escaped: _escaped,
                  hintUsedCount: _hintUsedCount,
                  timeTaken: _timeTaken,
                );

                Navigator.pop(context, updatedEntry);
              },
              child: const Text('수정 완료'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}