import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/userLogin_models.dart';
import 'url.dart';

class AuthService {
  Future<UserLoginResponse> login(UserLoginRequest request) async {
    final Uri uri = Uri.parse(loginURL);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserLoginResponse.fromJson(data);
      } else {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return UserLoginResponse(
            success: false,
            message: data['message'] ?? 'Login gagal dengan status ${response.statusCode}',
          );
        } catch (_) {
          return UserLoginResponse(
            success: false,
            message: 'Server error: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      return UserLoginResponse(
        success: false,
        message: 'Koneksi gagal: $e',
      );
    }
  }
}
