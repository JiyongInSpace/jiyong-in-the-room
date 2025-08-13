class EscapeCafe {
  final int id;
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
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      contact: json['contact'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }
}

class EscapeTheme {
  final int id;
  final String name;
  final int cafeId; // cafe_id 필드 추가
  final EscapeCafe? cafe; // nullable로 변경 (조인 시에만 사용)
  final int? difficulty; // nullable로 변경 - DB에서 null이 올 수 있음
  final Duration? timeLimit;
  final List<String>? genre; // ex: 추리, 공포, SF 등
  final String? themeImageUrl;

  EscapeTheme({
    required this.id,
    required this.name,
    required this.cafeId,
    this.cafe,
    this.difficulty, // required 제거 - nullable로 변경
    this.timeLimit,
    this.genre,
    this.themeImageUrl,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cafe_id': cafeId,
      'difficulty': difficulty,
      'time_limit_minutes': timeLimit?.inMinutes,
      'genre': genre,
      'theme_image_url': themeImageUrl,
      if (cafe != null) 'escape_cafes': cafe!.toJson(),
    };
  }

  factory EscapeTheme.fromJson(Map<String, dynamic> json) {
    print('EscapeTheme.fromJson received: $json');
    
    // cafe_id가 null인지 확인
    final cafeId = json['cafe_id'];
    if (cafeId == null) {
      throw Exception('cafe_id is null in EscapeTheme data: $json');
    }
    
    return EscapeTheme(
      id: json['id'] as int,
      name: json['name'] as String,
      cafeId: cafeId as int,
      cafe: json['escape_cafes'] != null 
          ? EscapeCafe.fromJson(json['escape_cafes'] as Map<String, dynamic>)
          : null,
      difficulty: json['difficulty'] as int?, // nullable로 변경
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