import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../services/employee_service.dart';
import 'employee_bookings_page.dart';
import 'profile_page.dart';
import 'dashboards/employee_dashboard.dart';

class EmployeeCarStatusPage extends StatefulWidget {
  const EmployeeCarStatusPage({super.key});

  @override
  State<EmployeeCarStatusPage> createState() => _EmployeeCarStatusPageState();
}

class _EmployeeCarStatusPageState extends State<EmployeeCarStatusPage> {
  final _service = EmployeeService();
  String _selectedStatus = "RENTED";
  late Future<List<Map<String, dynamic>>> _carsFuture;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primaryBlue = Color(0xFF6EA8FF);
  static const Color _textDark = Color(0xFF1F2A44);
  static const Color _textMuted = Color(0xFF6C7A92);

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  void _loadCars() {
    setState(() {
      _carsFuture = _service.getCarsByStatus(status: _selectedStatus);
    });
  }

  Future<void> _refresh() async {
    _loadCars();
    await _carsFuture;
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _imgUrl(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    if (name.startsWith("http")) return name;
    return "${ApiConfig.carsImagesBase}/$name";
  }

  Future<void> _checkIn(int bookingId) async {
    final odometerCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Check In Car"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: odometerCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Odometer (km)",
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
            child: const Text("Check In"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final odometer = int.tryParse(odometerCtrl.text) ?? 0;
    if (odometer <= 0) {
      _toast("Please enter valid odometer reading");
      return;
    }

    try {
      await _service.checkInCar(
        bookingId: bookingId,
        odometerKm: odometer,
      );
      _toast("Car checked in ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _checkOut(int bookingId) async {
    final odometerCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Check Out Car"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: odometerCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Odometer (km)",
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
            child: const Text("Check Out"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final odometer = int.tryParse(odometerCtrl.text) ?? 0;
    if (odometer <= 0) {
      _toast("Please enter valid odometer reading");
      return;
    }

    try {
      await _service.checkOutCar(
        bookingId: bookingId,
        odometerKm: odometer,
      );
      _toast("Car checked out ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Car Status",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: _textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatusTab("AVAILABLE", _selectedStatus == "AVAILABLE"),
                _buildStatusTab("RENTED", _selectedStatus == "RENTED"),
                _buildStatusTab("MAINTENANCE", _selectedStatus == "MAINTENANCE"),
              ],
            ),
          ),

          // Cars List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _carsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }

                final cars = snap.data ?? [];
                if (cars.isEmpty) {
                  return const Center(child: Text("No cars found"));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cars.length,
                    itemBuilder: (context, i) {
                      final car = cars[i];
                      final carTitle = "${car["brand"]} ${car["model"]}";
                      final customerName = car["customer_name"] ?? "Available";
                      final status = car["status"] ?? "";
                      final coverUrl = _imgUrl(car["cover_image"]);
                      final bookingId = int.tryParse(car["booking_id"]?.toString() ?? "0") ?? 0;
                      final checkInOdometer = car["checkin_odometer"] ?? 0;
                      final checkOutOdometer = car["checkout_odometer"] ?? 0;
                      final checkInDate = car["checkin_date"] ?? "";
                      final checkOutDate = car["checkout_date"] ?? "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: coverUrl.isEmpty
                                      ? Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.directions_car),
                                        )
                                      : Image.network(
                                          coverUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
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
                                        carTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                            color: _primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedStatus == "RENTED" && bookingId > 0) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _checkIn(bookingId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryBlue,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text("Check In"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _checkOut(bookingId),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: _primaryBlue),
                                        foregroundColor: _primaryBlue,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text("Check Out"),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Check-In Section
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Check-In",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: _textMuted),
                                        const SizedBox(width: 8),
                                        Text(
                                          checkInDate.isNotEmpty ? checkInDate : "Not checked in",
                                          style: const TextStyle(color: _textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.speed, size: 16, color: _textMuted),
                                        const SizedBox(width: 8),
                                        Text(
                                          checkInOdometer > 0 ? "$checkInOdometer km" : "N/A",
                                          style: const TextStyle(color: _textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Check-Out Section
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Check-Out",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: _textMuted),
                                        const SizedBox(width: 8),
                                        Text(
                                          checkOutDate.isNotEmpty ? checkOutDate : "Not checked out",
                                          style: const TextStyle(color: _textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.speed, size: 16, color: _textMuted),
                                        const SizedBox(width: 8),
                                        Text(
                                          checkOutOdometer > 0 ? "$checkOutOdometer km" : "N/A",
                                          style: const TextStyle(color: _textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStatusTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = label;
            _loadCars();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _primaryBlue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _primaryBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? _primaryBlue : _textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeBookingsPage()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _primaryBlue,
      unselectedItemColor: _textMuted,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Bookings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: "Status",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
    );
  }
}
