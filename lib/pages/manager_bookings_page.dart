import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../services/manager_service.dart';

class ManagerBookingsPage extends StatefulWidget {
  const ManagerBookingsPage({super.key});

  @override
  State<ManagerBookingsPage> createState() => _ManagerBookingsPageState();
}

class _ManagerBookingsPageState extends State<ManagerBookingsPage> {
  final _service = ManagerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      return await _service.getAllBookings();
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst("Exception: ", ""));
      }
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _imgUrl(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    if (name.startsWith("http")) return name;
    return "${ApiConfig.carsImagesBase}/$name";
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

  Future<void> _approveBooking(int bookingId, String carTitle) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Approve Booking?"),
        content: Text("Approve booking for:\n$carTitle"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Approve"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.approveBooking(bookingId: bookingId);
      _toast("Booking approved ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _rejectBooking(int bookingId, String carTitle) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Booking?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Reject booking for:\n$carTitle"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: "Reason (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.rejectBooking(
        bookingId: bookingId,
        reason: reasonCtrl.text.trim().isEmpty ? "Rejected by manager" : reasonCtrl.text.trim(),
      );
      _toast("Booking rejected ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Bookings"),
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
            return const Center(child: Text("No bookings found"));
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
                final customerName = b["customer_name"] ?? "Unknown";
                final total = double.tryParse(b["total_price"].toString()) ?? 0;
                final bookingId = int.tryParse(b["booking_id"].toString()) ?? 0;

                final canApprove = statusUpper == "PENDING";
                final canReject = statusUpper == "PENDING";

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
                                  const SizedBox(height: 4),
                                  Text("Customer: $customerName", style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Text("From: ${b["start_datetime"]}", style: const TextStyle(fontSize: 12)),
                                  Text("To: ${b["end_datetime"]}", style: const TextStyle(fontSize: 12)),
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

                        if (canApprove || canReject) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (canApprove)
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      onPressed: () => _approveBooking(bookingId, title),
                                      child: const Text("Approve"),
                                    ),
                                  ),
                                ),
                              if (canApprove && canReject) const SizedBox(width: 10),
                              if (canReject)
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: OutlinedButton(
                                      onPressed: () => _rejectBooking(bookingId, title),
                                      child: const Text("Reject"),
                                    ),
                                  ),
                                ),
                            ],
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
