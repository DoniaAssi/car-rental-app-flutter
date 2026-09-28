import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../services/employee_service.dart';
import 'employee_booking_details_page.dart';
import 'employee_car_status_page.dart';
import 'profile_page.dart';

class EmployeeBookingsPage extends StatefulWidget {
  const EmployeeBookingsPage({super.key});

  @override
  State<EmployeeBookingsPage> createState() => _EmployeeBookingsPageState();
}

class _EmployeeBookingsPageState extends State<EmployeeBookingsPage> {
  final _service = EmployeeService();
  String _selectedTab = "ALL";
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primaryBlue = Color(0xFF6EA8FF);
  static const Color _textDark = Color(0xFF1F2A44);
  static const Color _textMuted = Color(0xFF6C7A92);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _statsFuture = _service.getTodayStats();
      _bookingsFuture = _service.getBookings(filter: _selectedTab);
    });
  }

  Future<void> _refresh() async {
    _loadData();
    await Future.wait([_statsFuture, _bookingsFuture]);
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _imgUrl(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    if (name.startsWith("http")) return name;
    return "${ApiConfig.carsImagesBase}/$name";
  }

  Future<void> _approveBooking(int bookingId) async {
    try {
      await _service.approveBooking(bookingId: bookingId);
      _toast("Booking approved ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _declineBooking(int bookingId) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Decline Booking?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to decline this booking?"),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Decline"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.declineBooking(
        bookingId: bookingId,
        reason: reasonCtrl.text.trim().isEmpty ? "Declined by employee" : reasonCtrl.text.trim(),
      );
      _toast("Booking declined ✅");
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
          "Bookings Dashboard",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: _textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's Status Card
          FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              }
              final stats = snap.data ?? {};
              final rented = stats["rented"] ?? 0;
              final available = stats["available"] ?? 0;
              final maintenance = stats["maintenance"] ?? 0;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted),
                          onPressed: _refresh,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("$rented Rented", style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
                        Text("$available Available", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text("$maintenance Maintenance", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab("ALL", _selectedTab == "ALL"),
                _buildTab("UPCOMING", _selectedTab == "UPCOMING"),
                _buildTab("ACTIVE", _selectedTab == "ACTIVE"),
                _buildTab("COMPLETED", _selectedTab == "COMPLETED"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bookings List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _bookingsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }

                final bookings = snap.data ?? [];
                if (bookings.isEmpty) {
                  return const Center(child: Text("No bookings found"));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      final bookingId = int.tryParse(b["booking_id"].toString()) ?? 0;
                      final customerName = b["customer_name"] ?? "Unknown";
                      final carTitle = "${b["brand"]} ${b["model"]} (${b["type"] ?? ""})";
                      final dates = "${b["start_datetime"]} - ${b["end_datetime"]}";
                      final location = b["pickup_address"] ?? "Ramallah, Palestine";
                      final coverUrl = _imgUrl(b["cover_image"]);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmployeeBookingDetailsPage(bookingId: bookingId),
                            ),
                          ).then((_) => _refresh());
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
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
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.directions_car),
                                          )
                                        : Image.network(
                                            coverUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 60,
                                              height: 60,
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
                                          customerName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          carTitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: _textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dates,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _textMuted,
                                          ),
                                        ),
                                        Text(
                                          location,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (b["status"] == "PENDING") ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _declineBooking(bookingId),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text("Decline"),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _approveBooking(bookingId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primaryBlue,
                                        ),
                                        child: const Text("Approve"),
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
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = label;
            _loadData();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
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
      currentIndex: 1,
      onTap: (index) {
        if (index == 0) {
          Navigator.pop(context);
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeCarStatusPage()),
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
