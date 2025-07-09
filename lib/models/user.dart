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
  final User user; // 실제 유저 정보
  final DateTime addedAt;
  final String? nickname; // 내가 부르는 이름
  final String? memo;

  Friend({
    required this.user,
    required this.addedAt,
    this.nickname,
    this.memo,
  });
}