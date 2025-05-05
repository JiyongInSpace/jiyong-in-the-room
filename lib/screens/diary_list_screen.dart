import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/write_diary_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';

class DiaryListScreen extends StatelessWidget {
  final List<DiaryEntry> diaryList;
  final void Function(DiaryEntry) onAdd;

  const DiaryListScreen({
    super.key,
    required this.diaryList,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime date) {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('탈출일지')),
      body:
          diaryList.isEmpty
              ? const Center(child: Text('작성된 일지가 없습니다.'))
              : ListView.builder(
                itemCount: diaryList.length,
                itemBuilder: (context, index) {
                  final entry = diaryList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_clock),
                              const SizedBox(width: 8),
                              Text(
                                entry.cafe,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${entry.theme} | ${formatDate(entry.date)}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                entry.friends
                                    .map((friend) => Chip(label: Text(friend)))
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WriteDiaryScreen()),
          );

          if (result != null &&
              result is Map<String, dynamic> &&
              result['cafe'] is String &&
              result['theme'] is String &&
              result['date'] is DateTime &&
              result['friends'] is List<String>) {
            final entry = DiaryEntry(
              id: DateTime.now().millisecondsSinceEpoch,
              cafe: result['cafe'],
              theme: result['theme'],
              date: result['date'],
              friends: result['friends'],
            );
            onAdd(entry);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
