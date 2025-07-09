import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/screens/edit_diary_screen.dart';

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  final void Function(DiaryEntry)? onUpdate;

  const DiaryDetailScreen({
    super.key,
    required this.entry,
    this.onUpdate,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {

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
        title: Text(widget.entry.theme.name),
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
                          widget.entry.cafe.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.entry.theme.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(widget.entry.date),
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
            
            if (widget.entry.friends != null && widget.entry.friends!.isNotEmpty) ...[
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
                        children: widget.entry.friends!
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
                    
                    if (widget.entry.rating != null) ...[
                      Row(
                        children: [
                          const Text('평점: '),
                          _buildStarRating(widget.entry.rating!),
                          const SizedBox(width: 8),
                          Text(
                            widget.entry.rating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (widget.entry.escaped != null) ...[
                      Row(
                        children: [
                          const Text('탈출 결과: '),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.entry.escaped! ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.entry.escaped! ? '성공' : '실패',
                              style: TextStyle(
                                color: widget.entry.escaped! ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (widget.entry.timeTaken != null) ...[
                      Row(
                        children: [
                          const Text('소요시간: '),
                          Text(
                            '${widget.entry.timeTaken!.inMinutes}분',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (widget.entry.hintUsedCount != null) ...[
                      Row(
                        children: [
                          const Text('힌트 사용: '),
                          Text(
                            '${widget.entry.hintUsedCount}회',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            if (widget.entry.memo != null && widget.entry.memo!.isNotEmpty) ...[
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
                        widget.entry.memo!,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditDiaryScreen(entry: widget.entry),
            ),
          );

          if (result != null && result is DiaryEntry && mounted) {
            if (widget.onUpdate != null) {
              widget.onUpdate!(result);
            }
            Navigator.pop(context, result);
          }
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}