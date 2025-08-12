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

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact': contact,
      'logo_url': logoUrl,
    };
  }

  factory EscapeCafe.fromJson(Map<String, dynamic> json) {
    return EscapeCafe(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      contact: json['contact'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }
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

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cafe_id': cafe.id,
      'cafe': cafe.toJson(),
      'difficulty': difficulty,
      'time_limit_minutes': timeLimit?.inMinutes,
      'genre': genre,
      'theme_image_url': themeImageUrl,
    };
  }

  factory EscapeTheme.fromJson(Map<String, dynamic> json) {
    return EscapeTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      cafe: EscapeCafe.fromJson(json['cafe'] as Map<String, dynamic>),
      difficulty: json['difficulty'] as int,
      timeLimit: json['time_limit_minutes'] != null 
          ? Duration(minutes: json['time_limit_minutes'] as int)
          : null,
      genre: json['genre'] != null 
          ? List<String>.from(json['genre'] as List)
          : null,
      themeImageUrl: json['theme_image_url'] as String?,
    );
  }
}