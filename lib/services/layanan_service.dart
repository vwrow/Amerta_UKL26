import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/layanan_model.dart';
import 'url.dart';

class LayananService {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'APP-KEY': appKey,
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _buildPayload({
    required String name,
    required String minUsage,
    required String maxUsage,
    required String price,
  }) {
    return {
      'name': name.trim(),
      'min_usage': int.tryParse(minUsage.trim()) ?? 0,
      'max_usage': int.tryParse(maxUsage.trim()) ?? 0,
      'price': int.tryParse(price.trim()) ?? 0,
    };
  }

  String _extractMessage(dynamic message, String fallback) {
    if (message == null) return fallback;
    if (message is String) return message.isNotEmpty ? message : fallback;
    if (message is Map) {
      final buffer = StringBuffer();
      for (final key in message.keys) {
        final value = message[key];
        if (value is List && value.isNotEmpty) {
          buffer.write('${value.first} ');
        } else if (value != null) {
          buffer.write('$value ');
        }
      }
      final text = buffer.toString().trim();
      return text.isNotEmpty ? text : fallback;
    }
    return message.toString();
  }

  Map<String, dynamic> _parseResponse(
    http.Response response, {
    String successMessage = 'Berhasil',
  }) {
    final statusOk = response.statusCode >= 200 && response.statusCode < 300;

    if (response.body.isEmpty) {
      return {
        'success': statusOk,
        'message': statusOk
            ? successMessage
            : 'Request gagal (${response.statusCode})',
      };
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'] == true ||
            (decoded['success'] == null && statusOk);
        return {
          'success': success,
          'message': _extractMessage(
            decoded['message'],
            success
                ? successMessage
                : 'Request gagal (${response.statusCode})',
          ),
          if (decoded['data'] != null) 'data': decoded['data'],
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Response tidak valid (${response.statusCode})',
      };
    }

    return {
      'success': false,
      'message': 'Response tidak valid (${response.statusCode})',
    };
  }

  Future<List<LayananModel>?> getLayanan({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse(servicesURL),
        headers: _headers(token),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => LayananModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList();
        }
      }
    } catch (_) {
      // API call error
    }
    return null;
  }

  Future<Map<String, dynamic>> createLayanan({
    required String token,
    required String name,
    required String minUsage,
    required String maxUsage,
    required String price,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(servicesURL),
        headers: _headers(token),
        body: jsonEncode(_buildPayload(
          name: name,
          minUsage: minUsage,
          maxUsage: maxUsage,
          price: price,
        )),
      );

      return _parseResponse(
        response,
        successMessage: 'Layanan berhasil ditambahkan',
      );
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateLayanan({
    required String token,
    required int id,
    required String name,
    required String minUsage,
    required String maxUsage,
    required String price,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$servicesURL/$id'),
        headers: _headers(token),
        body: jsonEncode(_buildPayload(
          name: name,
          minUsage: minUsage,
          maxUsage: maxUsage,
          price: price,
        )),
      );

      return _parseResponse(
        response,
        successMessage: 'Layanan berhasil diperbarui',
      );
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteLayanan({
    required String token,
    required int id,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$servicesURL/$id'),
        headers: _headers(token),
      );

      return _parseResponse(
        response,
        successMessage: 'Layanan berhasil dihapus',
      );
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
