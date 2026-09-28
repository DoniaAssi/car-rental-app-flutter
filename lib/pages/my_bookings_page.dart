import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../core/session.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../services/booking_status_notifier.dart';
import 'payment_page.dart';
import 'report_accident_page.dart'; // ✅ اضفناها

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final _service = BookingService();
  final _statusNotifier = BookingStatusNotifier();

  late Future<List<Map<String, dynamic>>> _future;

  // عشان ما نعيد جدولة نفس الإشعار كل مرة
  final Set<int> _scheduledForBooking = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final user = await Session.getUser();
    if (user == null) throw Exception("Please login first");
    final customerId = int.parse(user["user_id"].toString());

    final list = await _service.getMyBookings(customerId);

    // ✅ FR-19: إشعار تغيير الحالة
    await _statusNotifier.checkAndNotify(list);

    // ✅ FR-17 / FR-18 + تنظيف الإشعارات
    await _scheduleRemindersIfNeeded(list);

    return list;
  }

  Future<void> _scheduleRemindersIfNeeded(List<Map<String, dynamic>> list) async {
    for (final b in list) {
      final status = (b["status"] ?? "").toString().toUpperCase();
      final bookingId = int.tryParse(b["booking_id"].toString()) ?? 0;
      if (bookingId <= 0) continue;

      // 🔴 لو الحجز انلغى → ألغي الإشعارات
      if (status == "CANCELLED" || status == "REJECTED") {
        await NotificationService.instance.cancelBookingReminders(bookingId);
        _scheduledForBooking.remove(bookingId);
        continue;
      }

      // فقط للحجوزات المؤكدة
      if (status != "CONFIRMED") continue;

      // إذا جدولناه قبل هيك لا تعيد
      if (_scheduledForBooking.contains(bookingId)) continue;

      final endStr = (b["end_datetime"] ?? "").toString();
      if (endStr.trim().isEmpty) continue;

      DateTime? end;
      try {
        end = DateTime.parse(endStr);
      } catch (_) {
        continue;
      }

      final carTitle = "${b["brand"]} ${b["model"]} (${b["model_year"]})";

      await NotificationService.instance.scheduleBookingReminders(
        bookingId: bookingId,
        endDateTime: end,
        carTitle: carTitle,
      );

      _scheduledForBooking.add(bookingId);
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  String _imgUrl(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    return "${ApiConfig.carsImagesBase}/$name";
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "PENDING":
        return Colors.orange;
      case "CONFIRMED":
      case "ACTIVE":
        return Colors.green;
      case "COMPLETED":
        return Colors.blue;
      case "CANCELLED":
      case "REJECTED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelBooking({
    required int bookingId,
    required String carTitle,
  }) async {
    final user = await Session.getUser();
    if (user == null) {
      _toast("Please login first");
      return;
    }
    final customerId = int.parse(user["user_id"].toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel booking?"),
        content: Text(
          "Are you sure you want to cancel:\n$carTitle\n\nThis will set status to CANCELLED.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, cancel"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.cancelBooking(
        bookingId: bookingId,
        customerId: customerId,
        reason: "Cancelled by customer",
      );

      // ✅ ألغي إشعارات هذا الحجز
      await NotificationService.instance.cancelBookingReminders(bookingId);
      _scheduledForBooking.remove(bookingId);

      _toast("Cancelled ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _openReportAccident({
    required int bookingId,
    required String carTitle,
  }) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportAccidentPage(
          bookingId: bookingId,
          carTitle: carTitle,
        ),
      ),
    );

    // لو رجعت true معناها تم الإرسال بنجاح
    if (changed == true) {
      _toast("Accident reported ✅");
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error: ${snap.error}"),
              ),
            );
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final b = list[i];

                final status = (b["status"] ?? "").toString();
                final statusUpper = status.toUpperCase();

                final cover = b["cover_image"]?.toString();
                final coverUrl = _imgUrl(cover);

                final title = "${b["brand"]} ${b["model"]} (${b["model_year"]})";
                final total = double.tryParse(b["total_price"].toString()) ?? 0;
                final bookingId = int.tryParse(b["booking_id"].toString()) ?? 0;

                final canPay = statusUpper == "PENDING";
                final canCancel = (statusUpper == "PENDING" || statusUpper == "CONFIRMED");

                // ✅ Report Accident يظهر للحالات اللي فعلاً فيها استلام سيارة أو حجز مؤكد
                final canReportAccident = (statusUpper == "CONFIRMED" || statusUpper == "ACTIVE");

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: coverUrl.isEmpty
                                  ? Container(
                                      width: 74,
                                      height: 74,
                                      color: Colors.black12,
                                      child: const Icon(Icons.directions_car),
                                    )
                                  : Image.network(
                                      coverUrl,
                                      width: 74,
                                      height: 74,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 74,
                                        height: 74,
                                        color: Colors.black12,
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text("From: ${b["start_datetime"]}"),
                                  Text("To: ${b["end_datetime"]}"),
                                  const SizedBox(height: 6),
                                  Text("Pickup: ${b["pickup_address"]}"),
                                  Text("Drop-off: ${b["dropoff_address"]}"),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Total: \$${total.toStringAsFixed(2)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _statusColor(status)),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ✅ أزرار تحت بعض (Pay / Cancel / Report Accident)
                        if (canPay || canCancel || canReportAccident) ...[
                          const SizedBox(height: 12),

                          if (canPay)
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final ok = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentPage(
                                        bookingId: bookingId,
                                        amount: total,
                                      ),
                                    ),
                                  );

                                  if (ok == true) {
                                    _toast("Paid ✅ Booking confirmed");
                                    _refresh();
                                  }
                                },
                                child: const Text("Pay Now"),
                              ),
                            ),

                          if (canPay && (canCancel || canReportAccident)) const SizedBox(height: 10),

                          if (canCancel)
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => _cancelBooking(
                                  bookingId: bookingId,
                                  carTitle: title,
                                ),
                                child: const Text("Cancel Booking"),
                              ),
                            ),

                          if (canCancel && canReportAccident) const SizedBox(height: 10),

                          if (canReportAccident)
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.car_crash),
                                onPressed: () => _openReportAccident(
                                  bookingId: bookingId,
                                  carTitle: title,
                                ),
                                label: const Text("Report Accident 🚗💥"),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

