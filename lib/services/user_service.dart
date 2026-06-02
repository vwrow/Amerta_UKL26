import 'dart:convert';
import 'package:http/http.dart' as http;
import 'url.dart';

class UserService {
  Future<Map<String, dynamic>?> fetchProfile({
    required String token,
    required String role,
  }) async {
    final bool isAdmin = role.trim().toUpperCase() == 'ADMIN';
    final String url = isAdmin ? '$adminURL/me' : '$customerURL/me';
    final Uri uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      // Failed to retrieve profile from API
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String role,
    required String id,
    required String password,
    required String name,
    required String phone,
  }) async {
    final bool isAdmin = role.trim().toUpperCase() == 'ADMIN';
    final uri = Uri.parse(isAdmin ? '$adminURL/$id' : '$customerURL/$id');

    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
          'name': name,
          'phone': phone,
        }),
      );

      if (response.body.isEmpty) {
        final ok = response.statusCode >= 200 && response.statusCode < 300;
        return {
          'success': ok,
          'message': ok
              ? 'Profil berhasil diperbarui'
              : 'Gagal memperbarui profil (${response.statusCode})',
        };
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAccount({
    required String token,
    required String id,
  }) async {
    final uri = Uri.parse('$adminURL/$id');
    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
      );
      // Handle empty response body (some DELETE endpoints return 204 No Content)
      if (response.body.isEmpty) {
        final ok = response.statusCode >= 200 && response.statusCode < 300;
        return {
          'success': ok,
          'message': ok
              ? 'Akun berhasil dihapus'
              : 'Gagal menghapus akun (${response.statusCode})',
        };
      }
      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
