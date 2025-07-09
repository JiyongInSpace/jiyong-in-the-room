import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';

class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({
    super.key,
    required this.entry,
  });

  String formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Stack(
            children: [
              Icon(
                Icons.star_border,
                color: Colors.grey[400],
                size: 20,
              ),
              if (rating > index) ...[
                if (rating >= index + 1)
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  )
                else
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.5,
                      child: const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.theme.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_clock, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          entry.cafe.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.theme.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (entry.friends != null && entry.friends!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '함께한 사람들',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: entry.friends!
                            .map((friend) => Chip(
                                  label: Text(friend.user.name),
                                  backgroundColor: Colors.blue[50],
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assessment, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '게임 결과',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (entry.rating != null) ...[
                      Row(
                        children: [
                          const Text('평점: '),
                          _buildStarRating(entry.rating!),
                          const SizedBox(width: 8),
                          Text(
                            entry.rating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (entry.escaped != null) ...[
                      Row(
                        children: [
                          const Text('탈출 결과: '),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: entry.escaped! ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.escaped! ? '성공' : '실패',
                              style: TextStyle(
                                color: entry.escaped! ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (entry.timeTaken != null) ...[
                      Row(
                        children: [
                          const Text('소요시간: '),
                          Text(
                            '${entry.timeTaken!.inMinutes}분',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (entry.hintUsedCount != null) ...[
                      Row(
                        children: [
                          const Text('힌트 사용: '),
                          Text(
                            '${entry.hintUsedCount}회',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            if (entry.memo != null && entry.memo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.note, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '메모',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.memo!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}