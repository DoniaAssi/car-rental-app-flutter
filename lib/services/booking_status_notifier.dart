import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BookingStatusNotifier {
  static const String _cacheKey = "booking_status_cache_v1";

  Future<void> checkAndNotify(List<Map<String, dynamic>> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    final Map<String, dynamic> cache =
        raw == null ? <String, dynamic>{} : jsonDecode(raw);

    for (final b in bookings) {
      final bookingId = (b["booking_id"] ?? "").toString();
      if (bookingId.isEmpty) continue;

      final newStatus = (b["status"] ?? "").toString().toUpperCase();
      if (newStatus.isEmpty) continue;

      final oldStatus = (cache[bookingId] ?? "").toString().toUpperCase();

      if (oldStatus.isEmpty) {
        cache[bookingId] = newStatus;
        continue;
      }

      if (oldStatus != newStatus) {
        await NotificationService.instance.showNow(
          id: 900000 + int.parse(bookingId),
          title: "Booking Status Updated",
          body: "Booking #$bookingId: $oldStatus → $newStatus",
          type: "STATUS",
        );

        cache[bookingId] = newStatus;
      }
    }

    await prefs.setString(_cacheKey, jsonEncode(cache));
  }
}
