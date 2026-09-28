import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class ProfileService {
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/update_profile.php");

    final res = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "full_name": fullName,
            "email": email,
            "phone": phone,
          }),
        )
        .timeout(const Duration(seconds: 12));

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Server error");
    }

    return json;
  }

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/change_password.php");

    final res = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "old_password": oldPassword,
            "new_password": newPassword,
          }),
        )
        .timeout(const Duration(seconds: 12));

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Server error");
    }
  }
}
