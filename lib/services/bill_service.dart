import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/bill_model.dart';
import 'url.dart';

class BillService {
  Future<List<BillModel>?> getBills({
    required String token,
  }) async {
    final Uri uri = Uri.parse('$baseURL/bills');

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
          return dataList.map((json) => BillModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // API error
    }
    return null;
  }

  Future<Map<String, dynamic>> createBill({
    required String token,
    required int customerId,
    required int month,
    required int year,
    required String measurementNumber,
    required int usageValue,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/bills'),
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'month': month,
          'year': year,
          'measurement_number': measurementNumber,
          'usage_value': usageValue,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> updateBill({
    required String token,
    required int id,
    required int month,
    required int year,
    required String measurementNumber,
    required int usageValue,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseURL/bills/$id'),
        headers: {
          'Content-Type': 'application/json',
          'APP-KEY': appKey,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'month': month,
          'year': year,
          'measurement_number': measurementNumber,
          'usage_value': usageValue,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteBill({
    required String token,
    required int id,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseURL/bills/$id'),
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

  Future<Map<String, dynamic>> acceptPayment({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseURL/payments/$paymentId'),
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

  Future<Map<String, dynamic>> rejectPayment({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseURL/payments/$paymentId'),
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

  Future<List<BillModel>?> getMyBills({
    required String token,
  }) async {
    final Uri uri = Uri.parse('$baseURL/bills/me');

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
          return dataList.map((json) => BillModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // API error
    }
    return null;
  }

  MediaType _contentTypeForFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  String _fileNameFromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    if (name.isNotEmpty) return name;
    return 'bukti_pembayaran.png';
  }

  Future<Map<String, dynamic>> uploadPayment({
    required String token,
    required int billId,
    required File file,
    String? fileName,
  }) async {
    final uri = Uri.parse('$baseURL/payments');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'APP-KEY': appKey,
        'Authorization': 'Bearer $token',
      });
      request.fields['bill_id'] = billId.toString();

      final resolvedName = fileName ?? _fileNameFromPath(file.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: resolvedName,
          contentType: _contentTypeForFile(resolvedName),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.body.isEmpty) {
        final ok = response.statusCode >= 200 && response.statusCode < 300;
        return {
          'success': ok,
          'message': ok
              ? 'Bukti pembayaran berhasil diunggah'
              : 'Upload gagal (${response.statusCode})',
        };
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
