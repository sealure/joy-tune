// 用户数据模型
// 从后端 API 返回的用户信息

class User {
  final int id;
  final String email;
  final String nickname;
  final String avatarUrl;
  final String authProvider; // 登录方式（google / github / qq / wechat，多个用逗号分隔）

  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatarUrl,
    this.authProvider = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // 处理 id 可能是字符串或数字的情况
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    // 后端 gRPC-gateway 统一输出 snake_case（如 avatar_url / auth_provider），
    // 这里优先解析 snake_case，同时兼容历史 camelCase 数据
    final avatarUrl = json['avatar_url'] as String? ?? json['avatarUrl'] as String? ?? '';
    final authProvider = json['auth_provider'] as String? ?? json['authProvider'] as String? ?? '';

    return User(
      id: id,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: avatarUrl,
      authProvider: authProvider,
    );
  }

  /// 是否通过指定的 Provider 登录过
  bool hasProvider(String provider) => authProvider.contains(provider);

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'authProvider': authProvider,
      };
}
