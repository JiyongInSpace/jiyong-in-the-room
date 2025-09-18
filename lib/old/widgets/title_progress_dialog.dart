import 'package:flutter/material.dart';

/// 칭호 진행 상황을 보여주는 다이얼로그
class TitleProgressDialog extends StatelessWidget {
  final int currentCount;

  const TitleProgressDialog({super.key, required this.currentCount});

  // 칭호별 정보 정의
  static const List<Map<String, dynamic>> _titles = [
    {
      'name': '방알못',
      'min': 0,
      'max': 5,
      'color': 0xFF757575,
      'icon': Icons.sentiment_very_dissatisfied,
    },
    {
      'name': '방린이',
      'min': 6,
      'max': 49,
      'color': 0xFF4CAF50,
      'icon': Icons.child_care,
    },
    {
      'name': '방청년',
      'min': 50,
      'max': 99,
      'color': 0xFF2196F3,
      'icon': Icons.person,
    },
    {
      'name': '고인물',
      'min': 100,
      'max': 299,
      'color': 0xFF9C27B0,
      'icon': Icons.water_drop,
    },
    {
      'name': '썩은물',
      'min': 300,
      'max': 9999,
      'color': 0xFFFFA000,
      'icon': Icons.whatshot,
    },
  ];

  // 현재 칭호 정보 가져오기
  Map<String, dynamic> _getCurrentTitle() {
    for (var title in _titles) {
      if (currentCount >= title['min'] && currentCount <= title['max']) {
        return title;
      }
    }
    return _titles.last;
  }

  // 다음 칭호 정보 가져오기
  Map<String, dynamic>? _getNextTitle() {
    final currentTitle = _getCurrentTitle();
    final currentIndex = _titles.indexOf(currentTitle);

    if (currentIndex < _titles.length - 1) {
      return _titles[currentIndex + 1];
    }
    return null; // 최고 칭호인 경우
  }

  // 현재 칭호 내에서의 진행률 계산
  double _getCurrentTitleProgress() {
    final current = _getCurrentTitle();
    final min = current['min'] as int;
    final max = current['max'] as int;

    if (max == 9999) {
      // 최고 칭호는 진행률 100%로 표시
      return 1.0;
    }

    final range = max - min + 1;
    final progress = currentCount - min + 1;
    return progress / range;
  }

  // 다음 칭호까지 남은 횟수
  int _getRemainingToNext() {
    final next = _getNextTitle();
    if (next == null) return 0;

    return (next['min'] as int) - currentCount;
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = _getCurrentTitle();
    final nextTitle = _getNextTitle();
    final progress = _getCurrentTitleProgress();
    final remaining = _getRemainingToNext();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: Color(currentTitle['color'] as int),
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text('내 방탈출 레벨'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 현재 칭호 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(currentTitle['color'] as int).withOpacity(0.1),
                  Color(currentTitle['color'] as int).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(currentTitle['color'] as int).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentTitle['icon'] as IconData,
                      color: Color(currentTitle['color'] as int),
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTitle['name'] as String,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(currentTitle['color'] as int),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 진행률 바
                if (nextTitle != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currentTitle['min']}회',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        currentTitle['max'] == 9999
                            ? '∞'
                            : '${currentTitle['max']}회',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(currentTitle['color'] as int),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
