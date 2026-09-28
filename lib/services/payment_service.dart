import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class PaymentService {
  Future<Map<String, dynamic>> payMock({
    required int bookingId,
    required double amount,
    required String method, // MOCK_CARD / MOCK_PAYPAL / CASH
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/payment_mock.php");

    final body = {
      "booking_id": bookingId,
      "amount": amount,
      "method": method,
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Payment failed");
    }
    return json;
  }
}
