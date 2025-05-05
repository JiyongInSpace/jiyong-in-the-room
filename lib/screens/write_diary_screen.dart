import 'package:flutter/material.dart';

class WriteDiaryScreen extends StatefulWidget {
  const WriteDiaryScreen({super.key});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final Map<String, List<String>> cafeThemes = {
    '비밀의화원': ['유령의집', '황금마차'],
    '키이스': ['타임머신', '사라진 도시'],
    '넥스트에디션': ['미궁의탑', '어둠의 마법서'],
  };

  final List<String> dummyFriends = ['수환', '지용', '민지', '철수', '은영'];

  String? selectedCafe;
  String? selectedTheme;
  DateTime? selectedDate;

  final List<String> selectedFriends = [];
  final TextEditingController _cafeController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController friendSearchController = TextEditingController();

  @override
  void dispose() {
    _cafeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr =
        selectedDate != null
            ? selectedDate!.toLocal().toString().split(' ')[0]
            : '날짜를 선택하세요';

    return Scaffold(
      appBar: AppBar(title: const Text('일지 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
              textEditingController: friendSearchController,
              focusNode: FocusNode(),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text == '')
                  return const Iterable<String>.empty();
                return dummyFriends
                    .where(
                      (f) =>
                          f.contains(textEditingValue.text) &&
                          !selectedFriends.contains(f),
                    )
                    .toList();
              },
              onSelected: (String selected) {
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
            Wrap(
              spacing: 8,
              children:
                  selectedFriends.map((friend) {
                    return Chip(
                      label: Text(friend),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () {
                        setState(() {
                          selectedFriends.remove(friend);
                        });
                      },
                    );
                  }).toList(),
            ),
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
                  'cafe': selectedCafe,
                  'theme': selectedTheme,
                  'date': selectedDate,
                  'friends': selectedFriends,
                });
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
