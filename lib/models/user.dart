// 用户数据模型
// 从后端 API 返回的用户信息

class User {
  final int id;
  final String email;
  final String nickname;
  final String avatarUrl;

  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // 处理 id 可能是字符串或数字的情况
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return User(
      id: id,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
      };
}
