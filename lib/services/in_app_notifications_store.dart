import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class InAppNotificationsStore {
  static const _k = "APP_NOTIFICATIONS_V1";

  Future<List<AppNotification>> getAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.trim().isEmpty) return [];

    final List list = jsonDecode(raw);
    final items = list
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // ✅ sort newest first
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> _save(List<AppNotification> items) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await sp.setString(_k, raw);
  }

  /// ✅ add with dedup key
  Future<void> addUnique({
    required String id,
    required String title,
    required String body,
    required String type,
  }) async {
    final items = await getAll();

    final exists = items.any((n) => n.id == id);
    if (exists) return; // ✅ prevent duplicates

    items.add(
      AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        read: false,
      ),
    );

    await _save(items);
  }

  /// (اختياري) add بدون dedup
  Future<void> add({
    required String title,
    required String body,
    required String type,
  }) async {
    final items = await getAll();
    items.add(
      AppNotification(
        id: "GEN_${DateTime.now().millisecondsSinceEpoch}",
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        read: false,
      ),
    );
    await _save(items);
  }

  /// ✅ NEW: unread count (هاي اللي كانت ناقصتك)
  Future<int> unreadCount() async {
    final items = await getAll();
    return items.where((n) => n.read == false).length;
  }

  Future<void> markAllRead() async {
    final items = await getAll();
    final updated = items.map((n) => n.copyWith(read: true)).toList();
    await _save(updated);
  }

  Future<void> markRead(String id) async {
    final items = await getAll();
    final updated =
        items.map((n) => n.id == id ? n.copyWith(read: true) : n).toList();
    await _save(updated);
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_k);
  }
}
