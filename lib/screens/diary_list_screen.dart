import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/write_diary_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';


class DiaryListScreen extends StatelessWidget {
  final List<DiaryEntry> diaryList;
  final void Function(String) onAdd;

  const DiaryListScreen({
    super.key,
    required this.diaryList,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('탈출일지')),
      body: diaryList.isEmpty
          ? const Center(child: Text('작성된 일지가 없습니다.'))
          : ListView.builder(
              itemCount: diaryList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(diaryList[index].name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          print(diaryList);

          final newDiary = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WriteDiaryScreen(),
            ),
          );

          if (newDiary != null && newDiary is String) {
            onAdd(newDiary);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}