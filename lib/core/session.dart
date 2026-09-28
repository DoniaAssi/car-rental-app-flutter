import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _kUser = "user";
  static const _kRole = "role";

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user));
    await prefs.setString(_kRole, user["role"]?.toString() ?? "");
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kUser);
    if (s == null) return null;
    return Map<String, dynamic>.from(jsonDecode(s));
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRole);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
    await prefs.remove(_kRole);
  }
}
