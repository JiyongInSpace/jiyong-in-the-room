import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/widgets/diary_management_bottom_sheet.dart';

/// 일지 항목을 표시하는 재사용 가능한 카드 위젯
class DiaryEntryCard extends StatefulWidget {
  final DiaryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showPadding;

  const DiaryEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showPadding = true,
  });

  @override
  State<DiaryEntryCard> createState() => _DiaryEntryCardState();
}

class _DiaryEntryCardState extends State<DiaryEntryCard> {
  /// 날짜를 YYYY.MM.DD 형식으로 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 롱프레스 시 바텀시트 표시 (친구목록과 동일한 스타일)
  void _handleLongPress() {
    if (widget.onEdit == null && widget.onDelete == null) return;
    
    // 햅틱 피드백 제공
    HapticFeedback.mediumImpact();

    // 공통 바텀시트 위젯 사용
    DiaryManagementBottomSheet.show(
      context: context,
      entry: widget.entry,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: (widget.onEdit != null || widget.onDelete != null) 
            ? _handleLongPress 
            : null,
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
                    child: widget.entry.escaped == true 
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              // 연한 초록 배경
                              CircleAvatar(
                                backgroundColor: Colors.green[100],
                                radius: 20,
                              ),
                              // 스탬프 이미지 (위에 덮기)
                              Image.asset(
                                'assets/images/stamp_success.png',
                                width: 40,
                                height: 40,
                              ),
                            ],
                          )
                        : widget.entry.escaped == false
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 연한 빨강 배경
                                  CircleAvatar(
                                    backgroundColor: Colors.red[100],
                                    radius: 20,
                                  ),
                                  // 스탬프 이미지 (위에 덮기)
                                  Image.asset(
                                    'assets/images/stamp_failed.png',
                                    width: 40,
                                    height: 40,
                                  ),
                                ],
                              )
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
                          widget.entry.theme?.name ?? '알 수 없는 테마',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${widget.entry.cafe?.name ?? '알 수 없음'} • ${_formatDate(widget.entry.date)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 평점 표시
                  if (widget.entry.rating != null)
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
                          widget.entry.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
              // 친구 정보 표시
              if (widget.entry.friends != null && widget.entry.friends!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 52), // 40 (아바타 너비) + 12 (간격)
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.entry.friends!.map((friend) => friend.displayName).join(', '),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // padding이 필요한 경우 Padding으로 감싸기
    if (widget.showPadding) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }
}