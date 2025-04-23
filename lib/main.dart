import 'package:flutter/material.dart';
import 'screens/write_diary_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '방탈일지',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DiaryListScreen(),
    );
  }
}

class DiaryListScreen extends StatelessWidget {
  const DiaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일지 작성')),
      body: const Center(child: Text('작성된 일지가 없습니다.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 일기 작성 화면으로 이동할 예정
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WriteDiaryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
