// models/diary.dart
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/user.dart';

class DiaryEntry {
  final int id;                 // SERIAL (DB와 일치)
  final String userId;          // 작성자 ID (UUID)
  final int themeId;            // 테마 ID (INTEGER)
  final EscapeTheme? theme;     // 테마 정보 (조인 시에만)
  final DateTime date;          // 진행 날짜
  final List<Friend>? friends;  // 친구들 정보 (조인 시에만)
  final String? memo;           // 메모/후기
  final double? rating;         // 별점 (0.0~5.0)
  final bool? escaped;          // 탈출 성공 여부
  final int? hintUsedCount;     // 사용한 힌트 횟수
  final Duration? timeTaken;    // 소요 시간
  final List<String>? photos;   // 사진 URL 목록
  final DateTime createdAt;     // 생성 시간
  final DateTime updatedAt;     // 수정 시간

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.themeId,
    this.theme,
    required this.date,
    this.friends,
    this.memo,
    this.rating,
    this.escaped,
    this.hintUsedCount,
    this.timeTaken,
    this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getter
  EscapeCafe? get cafe => theme?.cafe;

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'theme_id': themeId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형태
      'memo': memo,
      'rating': rating,
      'escaped': escaped,
      'hint_used_count': hintUsedCount,
      'time_taken_minutes': timeTaken?.inMinutes,
      'photos': photos,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      themeId: json['theme_id'] as int,
      theme: json['escape_themes'] != null 
          ? EscapeTheme.fromJson(json['escape_themes'] as Map<String, dynamic>)
          : null,
      date: DateTime.parse(json['date'] as String),
      memo: json['memo'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      escaped: json['escaped'] as bool?,
      hintUsedCount: json['hint_used_count'] as int?,
      timeTaken: json['time_taken_minutes'] != null 
          ? Duration(minutes: json['time_taken_minutes'] as int)
          : null,
      photos: json['photos'] != null 
          ? List<String>.from(json['photos'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
