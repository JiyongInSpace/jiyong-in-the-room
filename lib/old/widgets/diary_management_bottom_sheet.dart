import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';

/// 일지 관리 바텀시트 공통 위젯
class DiaryManagementBottomSheet extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DiaryManagementBottomSheet({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
  });

  /// 바텀시트 표시 헬퍼 메서드
  static Future<T?> show<T>({
    required BuildContext context,
    required DiaryEntry entry,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaryManagementBottomSheet(
        entry: entry,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
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

  /// 날짜를 YYYY.MM.DD 형식으로 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeName = entry.theme?.name ?? '테마 정보 없음';
    final cafeName = entry.theme?.cafe?.name ?? '카페 정보 없음';
    
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
            
            // 메뉴 헤더 - 일지 정보 표시
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 탈출 결과 아이콘
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: entry.escaped == true 
                          ? Colors.green.shade50
                          : entry.escaped == false
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      entry.escaped == true
                          ? Icons.check_circle
                          : entry.escaped == false
                              ? Icons.cancel
                              : Icons.help_outline,
                      color: entry.escaped == true
                          ? Colors.green.shade600
                          : entry.escaped == false
                              ? Colors.red.shade600
                              : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 일지 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          themeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cafeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(entry.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
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
            if (onEdit != null)
              _buildContextMenuItem(
                icon: Icons.edit_outlined,
                iconColor: Colors.blue,
                title: '일지 수정',
                subtitle: '날짜, 친구, 결과 등을 변경',
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            
            if (onDelete != null)
              _buildContextMenuItem(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: '일지 삭제',
                subtitle: '이 일지를 완전히 제거',
                onTap: () {
                  Navigator.pop(context);
                  // 삭제 확인 다이얼로그 표시
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('일지 삭제'),
                      content: Text('정말로 "$themeName" 일지를 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}