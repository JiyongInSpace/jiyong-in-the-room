class EscapeCafe {
  final String id;
  final String name;
  final String? address;
  final String? contact;
  final String? logoUrl;

  EscapeCafe({
    required this.id,
    required this.name,
    this.address,
    this.contact,
    this.logoUrl,
  });
}

class EscapeTheme {
  final String id;
  final String name;
  final EscapeCafe cafe;
  final int difficulty; // 1~5
  final Duration? timeLimit;
  final List<String>? genre; // ex: 추리, 공포, SF 등
  final String? themeImageUrl;

  EscapeTheme({
    required this.id,
    required this.name,
    required this.cafe,
    required this.difficulty,
    this.timeLimit,
    this.genre,
    this.themeImageUrl,
  });
}