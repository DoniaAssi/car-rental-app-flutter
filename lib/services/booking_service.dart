import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class BookingService {
  /// ✅ 1) Check availability (car_availability.php)
  Future<Map<String, dynamic>> checkAvailability({
    required int carId,
    required DateTime start,
    required DateTime end,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/car_availability.php");

    final body = {
      "car_id": carId,
      "start_datetime": start.toString().substring(0, 19),
      "end_datetime": end.toString().substring(0, 19),
    };

    final res = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Availability check failed");
    }

    return json;
  }

  /// ✅ 2) Create booking (car_booking.php)
  Future<Map<String, dynamic>> createBooking({
    required int carId,
    required int customerId,
    required DateTime start,
    required DateTime end,
    required String pickupAddress,
    required String dropoffAddress,

    // ✅ new coords
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,

    double deliveryFee = 0,
    double discountAmount = 0,
    double addonsTotal = 0,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/car_booking.php");

    final body = {
      "car_id": carId,
      "customer_id": customerId,
      "start_datetime": start.toString().substring(0, 19),
      "end_datetime": end.toString().substring(0, 19),

      "pickup_address": pickupAddress,
      "dropoff_address": dropoffAddress,

      // ✅ send coordinates
      "pickup_lat": pickupLat,
      "pickup_lng": pickupLng,
      "dropoff_lat": dropoffLat,
      "dropoff_lng": dropoffLng,

      "delivery_fee": deliveryFee,
      "discount_amount": discountAmount,
      "addons_total": addonsTotal,
    };

    final res = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Booking failed");
    }

    return json;
  }

  /// ✅ 3) Get my bookings (my_bookings.php)
  Future<List<Map<String, dynamic>>> getMyBookings(int customerId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/my_bookings.php?customer_id=$customerId");

    final res = await http.get(url).timeout(const Duration(seconds: 12));

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load bookings");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// ✅ 4) Cancel booking (cancel_booking.php)
  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    required int customerId,
    String reason = "Cancelled by customer",
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/cancel_booking.php");

    final body = {
      "booking_id": bookingId,
      "customer_id": customerId,
      "reason": reason,
    };

    final res = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Cancel failed");
    }

    return json;
  }
}
