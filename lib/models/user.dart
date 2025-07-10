// 가입한 유저 정보
class User {
  final String id; // 고유 식별자
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
}

// 친구 정보
class Friend {
  final String? connected; // 연결된 유저 ID (없으면 연결되지 않은 상태)
  final User? user; // 연결된 경우에만 실제 유저 정보
  final DateTime addedAt;
  final String nickname; // 내가 부르는 이름 (필수)
  final String? memo;

  Friend({
    this.connected,
    this.user,
    required this.addedAt,
    required this.nickname,
    this.memo,
  });

  // 연결된 친구인지 확인
  bool get isConnected => connected != null && user != null;
  
  // 표시할 이름 (별명 우선)
  String get displayName => nickname;
  
  // 표시할 이메일 (연결된 경우만)
  String? get displayEmail => user?.email;
  
  // 표시할 아바타 URL (연결된 경우만)
  String? get displayAvatarUrl => user?.avatarUrl;
  
  // 실제 이름 (연결된 경우만)
  String? get realName => user?.name;
}