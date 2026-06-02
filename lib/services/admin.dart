import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/response_data_map.dart';
import 'url.dart';

class AdminService {
  Future<ResponseDataMap> registerAdmin(Map<String, dynamic> payload) async {
    var uri = Uri.parse(adminURL);
    
    var register = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'APP-KEY': appKey,
      },
      body: jsonEncode(payload),
    );

    if (register.statusCode == 200 || register.statusCode == 201) {
      var data = json.decode(register.body);
      
      // Note: Your screenshot showed the boolean key is "success", not "status"
      if (data["success"] == true) {
        ResponseDataMap response = ResponseDataMap(
          status: true,
          message: "Sukses Menambah Admin",
          data: data["data"], 
        );
        return response;
      } else {
        var message = '';
        
        // If the API returns a structured message object
        if (data["message"] is Map) {
          for (String key in data["message"].keys) {
            message += data["message"][key][0].toString() + " ";
          }
        } else {
          message = data["message"] ?? "Terjadi kesalahan";
        }

        if (message.trim() == "The email has already been taken.") {
          message = "Email Sudah Terdaftar";
        }
        if (message.trim() == "The username has already been taken.") {
          message = "Username Sudah Terdaftar";
        }

        ResponseDataMap response = ResponseDataMap(
          status: false,
          message: message.trim(),
        );
        return response;
      }
    } else {
      ResponseDataMap response = ResponseDataMap(
        status: false,
        message: "Request Gagal - Error ${register.statusCode}",
      );
      return response;
    }
  }
}