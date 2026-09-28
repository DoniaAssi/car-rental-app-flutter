import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class AuthService {
  
  Uri _endpoint(String fileName) {
    final base = ApiConfig.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/$fileName');
  }

  Map<String, dynamic> _decodeJsonOrThrow(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // ✅ Most common reason: wrong URL -> Apache returns HTML 404 page
      throw Exception(
        "Server response is not JSON.\n"
        "Status: ${res.statusCode}\n"
        "URL may be wrong or file not found.\n"
        "Body (first 300 chars):\n${res.body.substring(0, res.body.length > 300 ? 300 : res.body.length)}",
      );
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = _endpoint("auth_login.php");

    final res = await http
        .post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode({
            "email": email.trim(),
            "password": password,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final json = _decodeJsonOrThrow(res);

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Login failed");
    }

    return json;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
    String? managerCode, // optional
  }) async {
    final url = _endpoint("auth_register.php");

    final body = <String, dynamic>{
      "full_name": fullName.trim(),
      "phone": phone.trim(),
      "email": email.trim(),
      "password": password,
      "role": role.trim(),
    };

    // ✅ Only send manager code if role is COMPANY_MANAGER
    if (role.trim().toUpperCase() == "COMPANY_MANAGER") {
      body["manager_code"] = (managerCode ?? "").trim();
    }

    final res = await http
        .post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    final json = _decodeJsonOrThrow(res);

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Register failed");
    }

    return json;
  }
}

