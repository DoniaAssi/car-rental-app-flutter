import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class AccidentService {
  Future<Map<String, dynamic>> reportAccident({
    required int bookingId,
    required int customerId,
    required DateTime accidentTime,
    required String locationText,
    required String description,
    List<PlatformFile> images = const [],
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/report_accident.php");

    final req = http.MultipartRequest("POST", uri);

    req.fields["booking_id"] = bookingId.toString();
    req.fields["customer_id"] = customerId.toString();
    req.fields["accident_time"] = accidentTime.toString().substring(0, 19);
    req.fields["location_text"] = locationText.trim();
    req.fields["description"] = description.trim();

    // attach images
    for (final f in images) {
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

    final streamed = await req.send().timeout(const Duration(seconds: 25));
    final res = await http.Response.fromStream(streamed);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server response is not JSON:\n${res.body}");
    }

    if (res.statusCode != 200 || json["ok"] != true) {
      throw Exception(json["message"] ?? "Report accident failed");
    }

    return json;
  }
}
