class UserSession {
  final String username;
  final String name;
  final String userId;
  final String phone;
  final String role;
  final String createdAt;
  final String token;

  const UserSession({
    required this.username,
    required this.name,
    required this.userId,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.token = '',
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'name': name,
        'user_id': userId,
        'phone': phone,
        'role': role,
        'createdAt': createdAt,
        'token': token,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Admin',
      createdAt: json['createdAt']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toStoredAccountJson({required String password}) => {
        ...toJson(),
        'password': password,
      };

  factory UserSession.fromStoredAccount(Map<String, dynamic> json) {
    return UserSession(
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Admin',
      createdAt: json['createdAt']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }
}
