import 'package:flutter/material.dart';

// models/diary.dart

// models/diary.dart
class DiaryEntry {
  final int id;
  final String cafe;
  final String theme;
  final DateTime date;
  final List<String> friends; // ✅ 친구 이름 목록

  DiaryEntry({
    required this.id,
    required this.cafe,
    required this.theme,
    required this.date,
    required this.friends,
  });
}

class DiaryTag {
  final String label;
  final Color color;

  DiaryTag({required this.label, required this.color});
}
