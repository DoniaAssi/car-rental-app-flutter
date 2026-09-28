import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'in_app_notifications_store.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final _store = InAppNotificationsStore();

  Future<void> init() async {
    tz.initializeTimeZones();
    //final tzName = await FlutterTimezone.getLocalTimezone();
    //tz.setLocalLocation(tz.getLocation(tzName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'rent_channel',
      'Rent Notifications',
      channelDescription: 'Rent reminders and booking status updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    return const NotificationDetails(android: android);
  }

  /// ✅ إشعار فوري: System + داخل التطبيق
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String type,
    String? uniqueKey, // ✅ optional dedup key
  }) async {
    await _plugin.show(id, title, body, _details());

    // ✅ dedup support
    if (uniqueKey != null) {
      await _store.addUnique(id: uniqueKey, title: title, body: body, type: type);
    } else {
      await _store.add(title: title, body: body, type: type);
    }
  }

  /// ⏰ إشعار مجدول (System)
  Future<void> scheduleSystem({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    final t = tz.TZDateTime.from(when, tz.local);
    if (t.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      t,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// ✅ FR-17/18: داخل التطبيق + system schedule (بدون تكرار)
  Future<void> scheduleBookingReminders({
    required int bookingId,
    required DateTime endDateTime,
    required String carTitle,
  }) async {
    final beforeId = bookingId * 10 + 1;
    final endId = bookingId * 10 + 2;

    // ✅ Dedup keys
    final keyReminder = "REM_24H_#$bookingId";
    final keyEnd = "RENT_END_#$bookingId";

    // ✅ داخل التطبيق (مرة واحدة)
    await _store.addUnique(
      id: keyReminder,
      title: "⏳ 24h Reminder Scheduled (FR-17)",
      body: "Reminder set for $carTitle (Booking #$bookingId).",
      type: "REMINDER",
    );

    await _store.addUnique(
      id: keyEnd,
      title: "🚗 Rent End Scheduled (FR-18)",
      body: "End notification set for $carTitle (Booking #$bookingId).",
      type: "RENT_END",
    );

    // ✅ System schedule
    await scheduleSystem(
      id: beforeId,
      title: "Reminder ⏳",
      body: "Your rent for $carTitle ends in 24 hours.",
      when: endDateTime.subtract(const Duration(hours: 24)),
    );

    await scheduleSystem(
      id: endId,
      title: "Rent End 🚗",
      body: "Your rent for $carTitle has ended.",
      when: endDateTime,
    );
  }

  Future<void> cancelBookingReminders(int bookingId) async {
    final beforeId = bookingId * 10 + 1;
    final endId = bookingId * 10 + 2;

    await _plugin.cancel(beforeId);
    await _plugin.cancel(endId);

    await _store.addUnique(
      id: "CANCEL_REM_#$bookingId",
      title: "❌ Reminders Cancelled",
      body: "Reminders cancelled for Booking #$bookingId.",
      type: "REMINDER",
    );
  }

  /// ✅ زر Test (مفيد جدًا)
  Future<void> testNow() async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    await showNow(
      id: id,
      title: "Test Notification ✅",
      body: "If you see this, notifications are working.",
      type: "SYSTEM",
      uniqueKey: "TEST_$id",
    );
  }
}