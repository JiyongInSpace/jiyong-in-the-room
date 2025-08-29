import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';

/// 일지 항목을 표시하는 재사용 가능한 카드 위젯
class DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback? onTap;
  final bool showPadding;

  const DiaryEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.showPadding = true,
  });

  /// 날짜를 YYYY.MM.DD 형식으로 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 탈출 상태 스탬프
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: entry.escaped == true 
                        ? Image.asset('assets/images/stamp_success.png')
                        : entry.escaped == false
                            ? Image.asset('assets/images/stamp_failed.png')
                            : CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.question_mark,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.theme?.name ?? '알 수 없는 테마',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${entry.cafe?.name ?? '알 수 없음'} • ${_formatDate(entry.date)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 평점 표시
                  if (entry.rating != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          entry.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
              // 친구 정보 표시
              if (entry.friends != null && entry.friends!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: entry.friends!
                      .map((friend) => Chip(
                            label: Text(
                              friend.displayName,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.blue[50],
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // padding이 필요한 경우 Padding으로 감싸기
    if (showPadding) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }
}