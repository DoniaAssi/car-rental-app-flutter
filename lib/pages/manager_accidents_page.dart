import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../services/manager_service.dart';

class ManagerAccidentsPage extends StatefulWidget {
  const ManagerAccidentsPage({super.key});

  @override
  State<ManagerAccidentsPage> createState() => _ManagerAccidentsPageState();
}

class _ManagerAccidentsPageState extends State<ManagerAccidentsPage> {
  final _service = ManagerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      return await _service.getAccidents();
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
    return "${ApiConfig.baseUrl}/uploads/accidents/$name";
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "PENDING":
        return Colors.orange;
      case "APPROVED":
        return Colors.green;
      case "REJECTED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleAccident(int accidentId, String decision) async {
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(decision == "APPROVED" ? "Approve Accident?" : "Reject Accident?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Decision: $decision"),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: "Notes (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            child: Text(decision == "APPROVED" ? "Approve" : "Reject"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.handleAccident(
        accidentId: accidentId,
        decision: decision,
        notes: notesCtrl.text.trim(),
      );
      _toast("Accident $decision ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accident Reports"),
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
            return const Center(child: Text("No accident reports found"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];

                final status = (a["status"] ?? "PENDING").toString();
                final statusUpper = status.toUpperCase();

                final accidentId = int.tryParse(a["accident_id"].toString()) ?? 0;
                final carTitle = "${a["brand"]} ${a["model"]} (${a["model_year"]})";
                final customerName = a["customer_name"] ?? "Unknown";
                final description = a["description"] ?? "";
                final location = a["location_text"] ?? "";
                final accidentTime = a["accident_time"] ?? "";

                final images = (a["images"] as List?)?.map((e) => e.toString()).toList() ?? [];
                final canHandle = statusUpper == "PENDING";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    carTitle,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text("Customer: $customerName", style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
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
                        const SizedBox(height: 12),
                        if (accidentTime.isNotEmpty)
                          Text("Time: $accidentTime", style: const TextStyle(fontSize: 12)),
                        if (location.isNotEmpty)
                          Text("Location: $location", style: const TextStyle(fontSize: 12)),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text("Description: $description", style: const TextStyle(fontSize: 13)),
                        ],
                        if (images.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, idx) {
                                final imgUrl = _imgUrl(images[idx]);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imgUrl.isEmpty
                                        ? Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.black12,
                                            child: const Icon(Icons.image),
                                          )
                                        : Image.network(
                                            imgUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.black12,
                                              child: const Icon(Icons.image_not_supported),
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (canHandle) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: () => _handleAccident(accidentId, "APPROVED"),
                                    child: const Text("Approve"),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: OutlinedButton(
                                    onPressed: () => _handleAccident(accidentId, "REJECTED"),
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
