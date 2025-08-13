// models/diary.dart
import 'package:jiyong_in_the_room/models/escape_cafe.dart';
import 'package:jiyong_in_the_room/models/user.dart';

class DiaryEntry {
  final int id;
  final EscapeTheme theme;
  final DateTime date;
  final List<Friend>? friends;
  final String? memo;
  final double? rating;
  final bool? escaped;
  final int? hintUsedCount;
  final Duration? timeTaken;

  DiaryEntry({
    required this.id,
    required this.theme,
    required this.date,
    this.friends,
    this.memo,
    this.rating,
    this.hintUsedCount,
    this.timeTaken,
    this.escaped,
  });

  EscapeCafe? get cafe => theme.cafe;
}
