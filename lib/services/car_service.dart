import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/car.dart';

class CarService {
  Future<List<Car>> fetchCars({
    String type = "ALL",
    String query = "",
    double? minPrice,
    double? maxPrice,
  }) async {
    final params = <String, String>{};

    if (type != "ALL") params["type"] = type;
    if (query.trim().isNotEmpty) params["q"] = query.trim();
    if (minPrice != null) params["minPrice"] = minPrice.toStringAsFixed(0);
    if (maxPrice != null) params["maxPrice"] = maxPrice.toStringAsFixed(0);

    final uri = Uri.parse("${ApiConfig.baseUrl}/cars_list.php").replace(queryParameters: params);

    final res = await http.get(uri);
    final decoded = jsonDecode(res.body);

    if (res.statusCode >= 400 || decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Failed to load cars");
    }

    final list = (decoded["data"] as List)
        .map((e) => Car.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return list;
  }

  Future<Map<String, dynamic>> fetchCarDetails(int carId) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/car_details.php?id=$carId");
    final res = await http.get(uri);
    final decoded = jsonDecode(res.body);

    if (res.statusCode >= 400 || decoded["ok"] != true) {
      throw Exception(decoded["message"] ?? "Failed to load details");
    }

    return Map<String, dynamic>.from(decoded);
  }
}
