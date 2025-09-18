import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/diary.dart';

/// 팀 통계를 보여주는 다이얼로그
class TeamStatsDialog extends StatelessWidget {
  final List<DiaryEntry> diaryList;

  const TeamStatsDialog({super.key, required this.diaryList});

  // 평균 팀 크기 계산
  double _getAverageTeamSize() {
    if (diaryList.isEmpty) return 1.0;

    int totalParticipants = 0;
    int validEntries = 0;

    for (var entry in diaryList) {
      if (entry.friends != null) {
        // 본인 포함해서 계산 (+1)
        totalParticipants += entry.friends!.length + 1;
        validEntries++;
      } else {
        // 친구 정보가 없으면 혼자 플레이 (1명)
        totalParticipants += 1;
        validEntries++;
      }
    }

    return validEntries > 0 ? totalParticipants / validEntries : 1.0;
  }

  // 팀 크기별 통계
  Map<int, int> _getTeamSizeDistribution() {
    Map<int, int> distribution = {};

    for (var entry in diaryList) {
      int teamSize = 1; // 본인
      if (entry.friends != null) {
        teamSize += entry.friends!.length;
      }

      distribution[teamSize] = (distribution[teamSize] ?? 0) + 1;
    }

    return distribution;
  }

  // 가장 흔한 팀 크기
  int _getMostCommonTeamSize() {
    final distribution = _getTeamSizeDistribution();
    if (distribution.isEmpty) return 1;

    int maxCount = 0;
    int mostCommonSize = 1;

    distribution.forEach((size, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonSize = size;
      }
    });

    return mostCommonSize;
  }

  // 팀 크기에 따른 아이콘
  IconData _getTeamIcon(int size) {
    switch (size) {
      case 1:
        return Icons.person;
      case 2:
        return Icons.people_alt;
      case 3:
      case 4:
        return Icons.groups;
      default:
        return Icons.groups_3;
    }
  }

  // 팀 크기에 따른 색상
  Color _getTeamColor(int size) {
    switch (size) {
      case 1:
        return Colors.grey[600]!;
      case 2:
        return Colors.blue[600]!;
      case 3:
        return Colors.green[600]!;
      case 4:
        return Colors.orange[600]!;
      default:
        return Colors.purple[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final averageSize = _getAverageTeamSize();
    final distribution = _getTeamSizeDistribution();
    final mostCommonSize = _getMostCommonTeamSize();
    final soloCount = distribution[1] ?? 0;
    final teamCount = diaryList.length - soloCount;

    // 가장 큰 팀 크기
    final maxTeamSize =
        distribution.isEmpty
            ? 1
            : distribution.keys.reduce((a, b) => a > b ? a : b);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.groups, color: Colors.orange[600], size: 28),
          const SizedBox(width: 8),
          const Text('내 팀플레이'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 평균 팀 크기 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange[100]!.withOpacity(0.5),
                  Colors.orange[50]!.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange[300]!.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getTeamIcon(averageSize.round()),
                      color: Colors.orange[600],
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '평균 ${averageSize.toStringAsFixed(1)}명',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[600],
                          ),
                        ),
                        Text(
                          '함께 플레이',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 팀 크기 분포
          if (distribution.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '팀 크기별 플레이 횟수',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 16),

            // 팀 크기별 막대 그래프
            ...List.generate(maxTeamSize, (index) {
              final size = index + 1;
              final count = distribution[size] ?? 0;
              final isMax = size == mostCommonSize;

              if (count == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Row(
                        children: [
                          Icon(
                            _getTeamIcon(size),
                            size: 16,
                            color: _getTeamColor(size),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$size명',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isMax ? FontWeight.bold : FontWeight.normal,
                              color:
                                  isMax
                                      ? _getTeamColor(size)
                                      : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: count / diaryList.length,
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    isMax
                                        ? _getTeamColor(size)
                                        : _getTeamColor(size).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '$count회',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isMax ? FontWeight.bold : FontWeight.normal,
                          color: isMax ? _getTeamColor(size) : Colors.grey[600],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    if (isMax) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _getTeamColor(size).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '최다',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _getTeamColor(size),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required int percentage,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
