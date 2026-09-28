import 'package:flutter/material.dart';
import '../services/in_app_notifications_store.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _store = InAppNotificationsStore();
  late Future<List<AppNotification>> _future;

  bool _changed = false; // ✅ عشان نرجع للدashboard ونحدث البادج

  @override
  void initState() {
    super.initState();
    _future = _store.getAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = _store.getAll());
    await _future;
  }

  IconData _icon(String type) {
    switch (type) {
      case "REMINDER":
        return Icons.alarm;
      case "RENT_END":
        return Icons.timer_off;
      case "STATUS":
        return Icons.sync;
      case "SYSTEM":
        return Icons.bolt;
      default:
        return Icons.notifications;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case "REMINDER":
        return "FR-17";
      case "RENT_END":
        return "FR-18";
      case "STATUS":
        return "FR-19";
      default:
        return "";
    }
  }

  Future<void> _clearAll() async {
    await _store.clearAll();
    _changed = true;
    _refresh();
  }

  Future<void> _markAllRead() async {
    await _store.markAllRead();
    _changed = true;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ لما نرجع Back نبعث للدashboard انه صار تغيير
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Notifications"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: "Clear all",
              onPressed: _clearAll,
            ),
            IconButton(
              icon: const Icon(Icons.bolt),
              tooltip: "Test notification",
              onPressed: () async {
                await NotificationService.instance.testNow();
                _changed = true;
                _refresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: "Mark all read",
              onPressed: _markAllRead,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
        ),
        body: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text("Error: ${snap.error}"));
            }

            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Center(child: Text("No notifications yet"));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = list[i];
                  final tag = _typeLabel(n.type);

                  return ListTile(
                    leading: Stack(
                      children: [
                        Icon(_icon(n.type)),
                        if (!n.read)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                          )
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  n.read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(tag,
                                style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    subtitle: Text("${n.body}\n${n.createdAt}"),
                    isThreeLine: true,
                    onTap: () async {
                      // ✅ ما نعمل markRead إلا إذا مش مقروء
                      if (!n.read) {
                        await _store.markRead(n.id);
                        _changed = true;
                        await _refresh();
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
