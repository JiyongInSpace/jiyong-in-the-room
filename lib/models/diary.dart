import 'package:flutter/material.dart';

// models/diary.dart

class DiaryEntry {
  final int id;
  final String name;
  final String theme;

  DiaryEntry({
    required this.id,
    required this.name,
    required this.theme,
  });
}

class DiaryTag {
  final String label;
  final Color color;

  DiaryTag({
    required this.label,
    required this.color,
  });
}