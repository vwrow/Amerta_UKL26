import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pelanggan_model.dart';
import 'url.dart';

class PelangganService {
  Future<List<PelangganModel>?> getPelanggan({
    required String token,
  }) async {
    final Uri uri = Uri.parse(customerURL);

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
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> dataList = body['data'];
          return dataList.map((json) => PelangganModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // API call error
    }
    return null;
  }

  Future<Map<String, dynamic>> createPelanggan({
    required String token,
    required String username,
    required String password,
    required String customerNumber,
    required String address,
    required int serviceId,
    required String name,
    required String phone,
  }) async {
    try {
      final requestBody = {
        'username': username,
        'password': password,
        'password_confirmation': password,
        'customer_number': customerNumber,
        'address': address,
        'service_id': serviceId,
        'name': name,
        'phone': phone,
      };
      print('[DEBUG] createPelanggan request body: $requestBody');

      final response = await http.post(
        Uri.parse(customerURL),
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[DEBUG] createPelanggan response status: ${response.statusCode}');
      print('[DEBUG] createPelanggan response body: ${response.body}');

      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePelanggan({
    required String token,
    required int id,
    required String customerNumber,
    required String address,
    required int serviceId,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$customerURL/$id'),
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'customer_number': customerNumber,
          'address': address,
          'service_id': serviceId,
          'name': name,
          'phone': phone,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePelanggan({
    required String token,
    required int id,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$customerURL/$id'),
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
