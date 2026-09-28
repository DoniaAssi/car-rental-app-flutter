import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class ManagerService {
  Future<Map<String, dynamic>> addCar({
    required Map<String, String> fields,
    required List<File> images,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_add_car.php");

    final req = http.MultipartRequest("POST", uri);

    // fields
    req.fields.addAll(fields);

    // images
    for (final f in images) {
      req.files.add(await http.MultipartFile.fromPath("images[]", f.path));
    }

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception("HTTP ${streamed.statusCode}: $body");
    }

    final data = jsonDecode(body);
    if (data["ok"] != true) {
      throw Exception(data["message"] ?? "Failed");
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_dashboard_stats.php");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load stats");
    }
    return Map<String, dynamic>.from(json["data"] ?? {});
  }

  /// ✅ fetch report for manager statistics (range based)
  Future<Map<String, dynamic>> fetchReport({
    required DateTime from,
    required DateTime to,
  }) async {
    String fmt(DateTime d) =>
        "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "${ApiConfig.baseUrl}/manager_report.php?from=${fmt(from)}&to=${fmt(to)}",
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic>) {
      throw Exception("Invalid JSON response: ${res.body}");
    }

    if (json["ok"] == true) {
      if (json.containsKey("totals") || json.containsKey("series")) {
        return Map<String, dynamic>.from(json);
      }
      return Map<String, dynamic>.from(json["data"] ?? json);
    }

    throw Exception(json["message"] ?? "Failed to load report");
  }

  Future<List<Map<String, dynamic>>> getAllCars() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/cars_list.php");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load cars");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> updateCarStatus({
    required int carId,
    required String status,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_update_car_status.php");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "car_id": carId,
            "status": status,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to update car");
    }
    return Map<String, dynamic>.from(json);
  }

  // ============================================================
  // ✅ NEW: Update full car data (matches your DB columns)
  // Table columns:
  // car_id, plate_number, brand, model, model_year, type, seats,
  // transmission, fuel_type, daily_price, deposit_amount,
  // status, mileage_km, color, description, deleted_at
  // ============================================================
  Future<Map<String, dynamic>> updateCar({
    required int carId,
    required String plateNumber,
    required String brand,
    required String model,
    required int modelYear,
    required String type,
    required int seats,
    required String transmission,
    required String fuelType,
    required double dailyPrice,
    required double depositAmount,
    required String status,
    required int mileageKm,
    required String color,
    required String description,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_update_car.php");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "car_id": carId,
            "plate_number": plateNumber,
            "brand": brand,
            "model": model,
            "model_year": modelYear,
            "type": type,
            "seats": seats,
            "transmission": transmission,
            "fuel_type": fuelType,
            "daily_price": dailyPrice,
            "deposit_amount": depositAmount,
            "status": status,
            "mileage_km": mileageKm,
            "color": color,
            "description": description,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to update car");
    }
    return Map<String, dynamic>.from(json);
  }

  // ============================================================
  // ✅ NEW: Soft delete car (deleted_at)
  // ============================================================
  Future<Map<String, dynamic>> softDeleteCar({required int carId}) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_delete_car.php");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"car_id": carId}),
        )
        .timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to delete car");
    }
    return Map<String, dynamic>.from(json);
  }

  // ============================================================

  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_bookings_list.php");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load bookings");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> approveBooking({
    required int bookingId,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_approve_booking.php");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"booking_id": bookingId}),
        )
        .timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to approve booking");
    }
    return Map<String, dynamic>.from(json);
  }

  Future<Map<String, dynamic>> rejectBooking({
    required int bookingId,
    String reason = "Rejected by manager",
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_reject_booking.php");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "booking_id": bookingId,
            "reason": reason,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to reject booking");
    }
    return Map<String, dynamic>.from(json);
  }

  Future<List<Map<String, dynamic>>> getAccidents() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_accidents_list.php");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load accidents");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> handleAccident({
    required int accidentId,
    required String decision,
    String? notes,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_handle_accident.php");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "accident_id": accidentId,
            "decision": decision,
            "notes": notes ?? "",
          }),
        )
        .timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to handle accident");
    }
    return Map<String, dynamic>.from(json);
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_employees_list.php");
    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to load employees");
    }

    final List list = (json["data"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> toggleEmployeeStatus({
    required int userId,
    required bool isActive,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_toggle_employee.php");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "is_active": isActive ? 1 : 0,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Failed to update employee");
    }
    return Map<String, dynamic>.from(json);
  }
}
