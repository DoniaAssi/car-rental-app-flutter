import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1/api";
    if (Platform.isAndroid) return "http://10.0.2.2/api"; // emulator
    return "http://127.0.0.1/api"; // windows/desktop
  }

  static String get carsImagesBase => "$baseUrl/uploads/cars";
}
