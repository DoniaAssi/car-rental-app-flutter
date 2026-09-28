import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../login_page.dart';
import '../../services/manager_service.dart';
import '../add_car_page.dart';
import '../manager_cars_page.dart';
import '../manager_bookings_page.dart';
import '../manager_accidents_page.dart';
import '../manager_employees_page.dart';
import '../profile_page.dart';

// ✅ NEW: Statistics page import
import '../manager_statistics_page.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final _service = ManagerService();
  late Future<Map<String, dynamic>> _future;

  // نفس ألوان التصميم بالصورة (تقريب جدًا)
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _hoverBlue = Color(0xFF6EA8FF);
  static const Color _textDark = Color(0xFF1F2A44);
  static const Color _textMuted = Color(0xFF6C7A92);

  @override
  void initState() {
    super.initState();
    _future = _service.fetchStats();
  }

  Future<void> _logout(BuildContext context) async {
    await Session.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _refresh() {
    setState(() => _future = _service.fetchStats());
  }

  Future<void> _openAddCar() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCarPage()),
    );
    if (ok == true) _refresh();
  }

  Future<void> _openCars() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerCarsPage()),
    );
  }

  Future<void> _openBookings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerBookingsPage()),
    );
  }

  Future<void> _openAccidents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerAccidentsPage()),
    );
  }

  Future<void> _openEmployees() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerEmployeesPage()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  // ✅ NEW: open Statistics
  Future<void> _openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerStatisticsPage()),
    );
  }

  double _toDouble(dynamic v) => double.tryParse(v.toString()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Manager Dashboard",
          style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh, color: _textMuted),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: _textMuted),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final d = snap.data ?? {};
          final cars = (d["cars"] ?? {}) as Map<String, dynamic>;
          final revenue = (d["revenue"] ?? {}) as Map<String, dynamic>;
          final today = _toDouble(revenue["today"]);
          final week = _toDouble(revenue["week"]);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              children: [
                // ===== Header Stats Card =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            "Available",
                            (cars["available"] ?? 0).toString(),
                            Icons.directions_car,
                            Colors.green,
                          ),
                          _statItem(
                            "Unavailable",
                            (cars["unavailable"] ?? 0).toString(),
                            Icons.block,
                            Colors.red,
                          ),
                          _statItem(
                            "Maintenance",
                            (cars["maintenance"] ?? 0).toString(),
                            Icons.build,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            "New Bookings",
                            (d["new_bookings"] ?? 0).toString(),
                            Icons.receipt_long,
                            Colors.blue,
                          ),
                          _statItem(
                            "Revenue Today",
                            "\$${today.toStringAsFixed(0)}",
                            Icons.attach_money,
                            Colors.green,
                          ),
                          _statItem(
                            "Revenue Week",
                            "\$${week.toStringAsFixed(0)}",
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ===== Add Car (Large Card) =====
                _HoverTile(
                  height: 92,
                  baseColor: _card,
                  hoverColor: _hoverBlue,
                  borderRadius: 20,
                  leading: Container(
                    width: 78,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _hoverBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      size: 32,
                      color: _hoverBlue,
                    ),
                  ),
                  title: "Add New Car",
                  subtitle: "Register a new vehicle",
                  onTap: _openAddCar,
                ),

                const SizedBox(height: 12),

                // ===== Manager Actions =====
                _HoverTile(
                  leadingIcon: Icons.directions_car,
                  title: "Manage Cars",
                  subtitle: "View, edit, and manage vehicles",
                  onTap: _openCars,
                ),
                const SizedBox(height: 12),

                _HoverTile(
                  leadingIcon: Icons.receipt_long,
                  title: "All Bookings",
                  subtitle: "View and manage reservations",
                  onTap: _openBookings,
                ),
                const SizedBox(height: 12),

                _HoverTile(
                  leadingIcon: Icons.report,
                  title: "Accident Reports",
                  subtitle: "Review and handle incidents",
                  onTap: _openAccidents,
                ),
                const SizedBox(height: 12),

                _HoverTile(
                  leadingIcon: Icons.people_outline,
                  title: "Employees",
                  subtitle: "Manage employee accounts",
                  onTap: _openEmployees,
                ),
                const SizedBox(height: 12),

                // ✅ NEW: Statistics tile
                _HoverTile(
                  leadingIcon: Icons.insights_rounded,
                  title: "Statistics",
                  subtitle: "Bookings, revenue & top cars",
                  onTap: _openStatistics,
                ),
                const SizedBox(height: 12),

                _HoverTile(
                  leadingIcon: Icons.person_outline,
                  title: "Profile",
                  onTap: _openProfile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _textMuted),
        ),
      ],
    );
  }
}

/// Tile with Hover effect (للويب/الديسكتوب) + Tap للموبايل
class _HoverTile extends StatefulWidget {
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color hoverColor;

  final Widget? leading;
  final IconData? leadingIcon;

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _HoverTile({
    super.key,
    this.height = 78,
    this.borderRadius = 18,
    this.baseColor = Colors.white,
    this.hoverColor = const Color(0xFF6EA8FF),
    this.leading,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  State<_HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<_HoverTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover ? widget.hoverColor : widget.baseColor;
    final titleColor = _hover ? Colors.white : const Color(0xFF1F2A44);
    final subColor = _hover ? Colors.white.withOpacity(0.85) : const Color(0xFF6C7A92);
    final iconColor = _hover ? Colors.white : const Color(0xFF6C7A92);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: widget.height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.leading != null)
                widget.leading!
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hover ? Colors.white.withOpacity(0.18) : const Color(0xFFF1F4FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.leadingIcon ?? Icons.circle, color: iconColor, size: 26),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.subtitle == null ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, size: 34, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
