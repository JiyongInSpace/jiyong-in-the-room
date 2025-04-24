import 'package:flutter/material.dart';
class WriteDiaryScreen extends StatefulWidget {
  const WriteDiaryScreen({super.key});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final TextEditingController _cafeNameController = TextEditingController();

  @override
  void dispose() {
    _cafeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일지 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cafeNameController,
              decoration: const InputDecoration(
                labelText: '방탈출명',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final input = _cafeNameController.text;
                Navigator.pop(context, input); // 입력값을 반환하면서 화면 닫기
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}