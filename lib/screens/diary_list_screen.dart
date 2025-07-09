import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/write_diary_screen.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/user.dart';

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
                                entry.cafe.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.theme.name} | ${formatDate(entry.date)}',
                          ),
                          const SizedBox(height: 8),
                          if (entry.friends != null && entry.friends!.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: entry.friends!
                                  .map((friend) => Chip(label: Text(friend.user.name)))
                                  .toList(),
                            ),
                          if (entry.memo != null) ...[
                            const SizedBox(height: 8),
                            Text(entry.memo!),
                          ],
                          if (entry.rating != null || entry.escaped != null || entry.hintUsedCount != null || entry.timeTaken != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (entry.rating != null)
                                  Text('평점: ${entry.rating}'),
                                if (entry.escaped != null)
                                  Text('탈출: ${entry.escaped! ? "성공" : "실패"}'),
                                if (entry.hintUsedCount != null)
                                  Text('힌트: ${entry.hintUsedCount}회'),
                                if (entry.timeTaken != null)
                                  Text('소요시간: ${entry.timeTaken!.inMinutes}분'),
                              ],
                            ),
                          ],
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
              result['friends'] is List<dynamic>) {
            final entry = DiaryEntry(
              id: DateTime.now().millisecondsSinceEpoch,
              theme: EscapeTheme(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: result['theme'] as String,
                cafe: EscapeCafe(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: result['cafe'] as String,
                ),
                difficulty: 3,
              ),
              date: result['date'] as DateTime,
              friends: (result['friends'] as List<dynamic>).map((name) => Friend(
                user: User(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name as String,
                  email: '$name@example.com',
                  joinedAt: DateTime.now(),
                ),
                addedAt: DateTime.now(),
              )).toList(),
              memo: result['memo'] as String?,
              rating: result['rating'] as double?,
              escaped: result['escaped'] as bool?,
              hintUsedCount: result['hintUsedCount'] as int?,
              timeTaken: result['timeTaken'] as Duration?,
            );
            onAdd(entry);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
