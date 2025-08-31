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
  final bool memoPublic;        // 메모 공개 여부
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
    this.memoPublic = false,
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

  // copyWith 메서드
  DiaryEntry copyWith({
    int? id,
    String? userId,
    int? themeId,
    EscapeTheme? theme,
    DateTime? date,
    List<Friend>? friends,
    String? memo,
    bool? memoPublic,
    double? rating,
    bool? escaped,
    int? hintUsedCount,
    Duration? timeTaken,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      themeId: themeId ?? this.themeId,
      theme: theme ?? this.theme,
      date: date ?? this.date,
      friends: friends ?? this.friends,
      memo: memo ?? this.memo,
      memoPublic: memoPublic ?? this.memoPublic,
      rating: rating ?? this.rating,
      escaped: escaped ?? this.escaped,
      hintUsedCount: hintUsedCount ?? this.hintUsedCount,
      timeTaken: timeTaken ?? this.timeTaken,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'theme_id': themeId,
      // 로컬 저장을 위해 theme 객체도 포함
      if (theme != null) 'theme': theme!.toJson(),
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형태
      'memo': memo,
      'memo_public': memoPublic,
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
      // DB에서 오는 경우 'escape_themes', 로컬에서 오는 경우 'theme'
      theme: json['escape_themes'] != null 
          ? EscapeTheme.fromJson(json['escape_themes'] as Map<String, dynamic>)
          : json['theme'] != null
              ? EscapeTheme.fromJson(json['theme'] as Map<String, dynamic>)
              : null,
      date: DateTime.parse(json['date'] as String),
      friends: null, // 비회원은 친구 기능 사용 불가
      memo: json['memo'] as String?,
      memoPublic: json['memo_public'] as bool? ?? false,
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
