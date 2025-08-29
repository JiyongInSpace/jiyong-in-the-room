// 가입한 유저 정보
class User {
  final String id; // 고유 식별자 (UUID - auth.users와 동일)
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime joinedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.joinedAt,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

// 친구 정보
class Friend {
  final int? id; // 친구 고유 ID (SERIAL INTEGER)
  final String? connectedUserId; // 연결된 유저 ID (없으면 연결되지 않은 상태) - UUID 유지
  final User? user; // 연결된 경우에만 실제 유저 정보
  final DateTime addedAt;
  final String nickname; // 내가 부르는 이름 (필수)
  final String? memo;

  Friend({
    this.id,
    this.connectedUserId,
    this.user,
    required this.addedAt,
    required this.nickname,
    this.memo,
  });

  // 연결된 친구인지 확인
  bool get isConnected => connectedUserId != null && user != null;
  
  // 표시할 이름 (별명 우선)
  String get displayName => nickname;
  
  // 표시할 이메일 (연결된 경우만)
  String? get displayEmail => user?.email;
  
  // 표시할 아바타 URL (연결된 경우만)
  String? get displayAvatarUrl => user?.avatarUrl;
  
  // 실제 이름 (연결된 경우만)
  String? get realName => user?.name;

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connected_user_id': connectedUserId,
      'user': user?.toJson(),
      'added_at': addedAt.toUtc().toIso8601String(),
      'nickname': nickname,
      'memo': memo,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as int?,
      connectedUserId: json['connected_user_id'] as String?,
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      addedAt: DateTime.parse(json['added_at'] as String),
      nickname: json['nickname'] as String,
      memo: json['memo'] as String?,
    );
  }
}

// 친구의 일지 정보 (같은 테마로 진행한 경우)
class FriendDiaryInfo {
  final String userId;      // 친구의 user_id
  final String displayName; // 친구의 표시 이름
  final String? avatarUrl;  // 친구의 아바타 URL
  final DateTime date;      // 진행 날짜
  final double? rating;     // 친구의 평점 (항상 공개)
  final String? memo;       // 친구의 메모 (공개 설정된 경우만)
  final bool? escaped;      // 친구의 탈출 결과

  FriendDiaryInfo({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.date,
    this.rating,
    this.memo,
    this.escaped,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'date': date.toIso8601String(),
      'rating': rating,
      'memo': memo,
      'escaped': escaped,
    };
  }

  factory FriendDiaryInfo.fromJson(Map<String, dynamic> json) {
    return FriendDiaryInfo(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      date: DateTime.parse(json['date'] as String),
      rating: json['rating']?.toDouble(),
      memo: json['memo'] as String?,
      escaped: json['escaped'] as bool?,
    );
  }
}