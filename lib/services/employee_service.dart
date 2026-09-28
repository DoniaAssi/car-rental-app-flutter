import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class EmployeeService {
  Future<Map<String, dynamic>> getTodayStats() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_today_stats.php");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load stats");
    }
    return Map<String, dynamic>.from(json["data"] ?? {});
  }

  Future<List<Map<String, dynamic>>> getBookings({
    String filter = "ALL", // ALL, UPCOMING, ACTIVE, COMPLETED
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_bookings.php?filter=$filter");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load bookings");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getBookingDetails(int bookingId) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_booking_details.php?id=$bookingId");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load booking details");
    }
    return Map<String, dynamic>.from(json["data"] ?? {});
  }

  Future<Map<String, dynamic>> approveBooking({
    required int bookingId,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_approve_booking.php");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"booking_id": bookingId}),
    ).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to approve booking");
    }
    return Map<String, dynamic>.from(json);
  }

  Future<Map<String, dynamic>> declineBooking({
    required int bookingId,
    String reason = "Declined by employee",
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_decline_booking.php");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_id": bookingId,
        "reason": reason,
      }),
    ).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to decline booking");
    }
    return Map<String, dynamic>.from(json);
  }

  Future<List<Map<String, dynamic>>> getCarsByStatus({
    String status = "ALL", // ALL, AVAILABLE, RENTED, MAINTENANCE
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_cars_status.php?status=$status");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load cars");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> checkInCar({
    required int bookingId,
    required int odometerKm,
    String? notes,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_checkin_car.php");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_id": bookingId,
        "odometer_km": odometerKm,
        "notes": notes ?? "",
      }),
    ).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to check in car");
    }
    return Map<String, dynamic>.from(json);
  }

  Future<Map<String, dynamic>> checkOutCar({
    required int bookingId,
    required int odometerKm,
    String? notes,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_checkout_car.php");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_id": bookingId,
        "odometer_km": odometerKm,
        "notes": notes ?? "",
      }),
    ).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to check out car");
    }
    return Map<String, dynamic>.from(json);
  }

  Future<List<Map<String, dynamic>>> getBookingNotes(int bookingId) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_booking_notes.php?booking_id=$bookingId");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load notes");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> addBookingNote({
    required int bookingId,
    required String note,
    required String category, // DELAY, VIOLATION, DAMAGE, GENERAL
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/employee_add_booking_note.php");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_id": bookingId,
        "note": note,
        "category": category,
      }),
    ).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to add note");
    }
    return Map<String, dynamic>.from(json);
  }
}
