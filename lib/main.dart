import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/diary_list_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<DiaryEntry> diaryList = [];
  void addDiary(String name) {
    final newEntry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch, // 유니크 ID 생성용
      name: name,
      theme: 'default', // 필수 파라미터 theme 추가
    );
    setState(() {
      diaryList.add(newEntry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '탈출일지',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: DiaryListScreen(diaryList: diaryList, onAdd: addDiary),
    );
  }
}
