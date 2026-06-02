class UserLoginRequest {
  final String username;
  final String password;

  UserLoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class UserLoginResponse {
  final bool success;
  final String message;
  final String? token;
  final String? role;

  UserLoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.role,
  });

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    return UserLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      role: json['role'],
    );
  }
}
