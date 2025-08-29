import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiyong_in_the_room/models/diary.dart';

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

  /// 컨텍스트 메뉴 아이템 빌더
  Widget _buildContextMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  /// 롱프레스 시 바텀시트 표시 (친구목록과 동일한 스타일)
  void _handleLongPress() {
    if (widget.onEdit == null && widget.onDelete == null) return;
    
    // 햅틱 피드백 제공
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // 메뉴 헤더
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // 일지 테마 아이콘
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_stories,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // 테마 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.entry.theme?.name ?? '알 수 없는 테마',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.entry.cafe?.name ?? '알 수 없음'} • ${_formatDate(widget.entry.date)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1, thickness: 0.5),
                
                // 메뉴 옵션들
                if (widget.onEdit != null)
                  _buildContextMenuItem(
                    icon: Icons.edit_outlined,
                    iconColor: Colors.blue,
                    title: '정보 수정',
                    subtitle: '일지 내용을 수정',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEdit?.call();
                    },
                  ),
                
                if (widget.onDelete != null)
                  _buildContextMenuItem(
                    icon: Icons.delete_outline,
                    iconColor: Colors.red,
                    title: '일지 삭제',
                    subtitle: '일지를 영구적으로 삭제',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete?.call();
                    },
                  ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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