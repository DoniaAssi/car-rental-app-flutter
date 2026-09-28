import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class ManagerCarsService {
  Future<Map<String, dynamic>> addCar({
    required int createdBy,
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
    List<PlatformFile> images = const [],
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/manager_add_car.php");
    final req = http.MultipartRequest("POST", uri);

    req.fields["created_by"] = createdBy.toString();
    req.fields["plate_number"] = plateNumber.trim();
    req.fields["brand"] = brand.trim();
    req.fields["model"] = model.trim();
    req.fields["model_year"] = modelYear.toString();
    req.fields["type"] = type.trim();
    req.fields["seats"] = seats.toString();
    req.fields["transmission"] = transmission.trim();
    req.fields["fuel_type"] = fuelType.trim();
    req.fields["daily_price"] = dailyPrice.toString();
    req.fields["deposit_amount"] = depositAmount.toString();
    req.fields["status"] = status.trim();
    req.fields["mileage_km"] = mileageKm.toString();
    req.fields["color"] = color.trim();
    req.fields["description"] = description.trim();

    for (final f in images) {
      // ✅ اسم الحقل: images[]
      if (f.bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes(
            "images[]",
            f.bytes as Uint8List,
            filename: f.name,
          ),
        );
      } else if (f.path != null) {
        req.files.add(
          await http.MultipartFile.fromPath(
            "images[]",
            f.path!,
            filename: f.name,
          ),
        );
      }
    }

    final streamed = await req.send().timeout(const Duration(seconds: 45));
    final res = await http.Response.fromStream(streamed);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Add car failed");
    }

    return json;
  }
}
