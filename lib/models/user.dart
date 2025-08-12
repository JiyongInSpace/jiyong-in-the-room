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
  final String? connectedUserId; // 연결된 유저 ID (없으면 연결되지 않은 상태)
  final User? user; // 연결된 경우에만 실제 유저 정보
  final DateTime addedAt;
  final String nickname; // 내가 부르는 이름 (필수)
  final String? memo;

  Friend({
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
      'connected_user_id': connectedUserId,
      'user': user?.toJson(),
      'added_at': addedAt.toIso8601String(),
      'nickname': nickname,
      'memo': memo,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
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