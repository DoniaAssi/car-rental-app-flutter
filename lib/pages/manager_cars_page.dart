import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../services/manager_service.dart';
import 'car_details_page.dart';
import 'edit_car_page.dart';

class ManagerCarsPage extends StatefulWidget {
  const ManagerCarsPage({super.key});

  @override
  State<ManagerCarsPage> createState() => _ManagerCarsPageState();
}

class _ManagerCarsPageState extends State<ManagerCarsPage> {
  final _service = ManagerService();
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _cars = [];

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    setState(() => _loading = true);
    try {
      final cars = await _service.getAllCars();
      setState(() => _cars = cars);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _imgUrl(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    if (name.startsWith("http")) return name;
    return "${ApiConfig.carsImagesBase}/$name";
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "AVAILABLE":
        return Colors.green;
      case "BOOKED":
      case "UNAVAILABLE":
        return Colors.red;
      case "MAINTENANCE":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ✅ EDIT: يتحدّث فورًا
  Future<void> _editCar(Map<String, dynamic> car, int index) async {
    final updatedCar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCarPage(car: car)),
    );

    if (updatedCar != null && mounted) {
      setState(() {
        _cars[index] = updatedCar; // تحديث مباشر بدون reload
      });
    }
  }

  // ✅ DELETE: ينحذف فورًا من القائمة
  Future<void> _deleteCar(int carId, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Car"),
        content: const Text("هل أنت متأكد؟ (Soft Delete)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.softDeleteCar(carId: carId);
      setState(() {
        _cars.removeAt(index); // 🔥 حذف مباشر من UI
      });
      _toast("Deleted ✅");
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _toggleStatus(int carId, String currentStatus, int index) async {
    final newStatus =
        currentStatus.toUpperCase() == "AVAILABLE" ? "UNAVAILABLE" : "AVAILABLE";

    try {
      await _service.updateCarStatus(carId: carId, status: newStatus);
      setState(() {
        _cars[index]["status"] = newStatus;
      });
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCars = _searchCtrl.text.isEmpty
        ? _cars
        : _cars.where((c) {
            final q = _searchCtrl.text.toLowerCase();
            return c["brand"].toString().toLowerCase().contains(q) ||
                c["model"].toString().toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Cars"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCars),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: "Search by brand/model",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredCars.length,
                    itemBuilder: (context, i) {
                      final c = filteredCars[i];
                      final status = c["status"].toString();
                      final carId = int.parse(c["car_id"].toString());
                      final coverUrl = _imgUrl(c["cover_url"]);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: coverUrl.isEmpty
                                ? const Icon(Icons.directions_car, size: 40)
                                : Image.network(
                                    coverUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                          ),

                          // ✅ FIX النص
                          title: Text(
                            "${c["brand"]} ${c["model"]} (${c["model_year"]})",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "${c["type"]} • \$${c["daily_price"]}/day",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // ✅ FIX trailing
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _statusColor(status)),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                  onPressed: () => _editCar(c, i),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteCar(carId, i),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz, size: 20),
                                  onPressed: () => _toggleStatus(carId, status, i),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
