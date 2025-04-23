// lib/screens/write_diary_screen.dart
import 'package:flutter/material.dart';

class WriteDiaryScreen extends StatelessWidget {
  const WriteDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일지 작성')),
      body: const Center(child: Text('여기서 일지를 쓸 수 있어요')),
    );
  }
}