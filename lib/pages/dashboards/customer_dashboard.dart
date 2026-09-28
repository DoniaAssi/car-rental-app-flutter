import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../cars_page.dart';
import '../login_page.dart';
import '../my_bookings_page.dart';
import '../notifications_page.dart';
import '../profile_page.dart';
import '../../services/in_app_notifications_store.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final _store = InAppNotificationsStore();
  int _unread = 0;

  // نفس ألوان التصميم بالصورة (تقريب جدًا)
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _hoverBlue = Color(0xFF6EA8FF); // لون الكارد الأزرق الفاتح
  static const Color _textDark = Color(0xFF1F2A44);
  static const Color _textMuted = Color(0xFF6C7A92);

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    final c = await _store.unreadCount();
    if (!mounted) return;
    setState(() => _unread = c);
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

  Future<void> _openCars() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CarsPage()));
  }

  Future<void> _openBookings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsPage()));
  }

  Future<void> _openNotifications() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    if (changed == true) await _loadUnread();
  }

  Future<void> _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  Future<void> _openAccidentReport() async {
    // حسب مشروعك: بدك تفتحي صفحة report_accident_page ولا SnackBar
    // عدّليها حسب الصفحة الموجودة عندك:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Open Report Accident from My Bookings (better)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Customer Dashboard",
          style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
        ),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: _textMuted),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          children: [
            // ===== Header Illustration Card (مثل الصورة) =====
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
                  // إذا عندك صورة نفس اللي فوق حطيها هون، وإلا خليه asset بسيط
                  // ملاحظة: حطي الصورة اللي بدك ياهـا داخل assets
                  Image.asset(
                    'assets/carone.jpg',
                    height: 170,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 170,
                      child: Center(child: Icon(Icons.directions_car, size: 54, color: _textMuted)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== Browse Cars (كارد كبيرة مثل الصورة - بس مش زرقاء إلا على hover) =====
            _HoverTile(
              height: 92,
              baseColor: _card, // ✅ مش أزرق
              hoverColor: _hoverBlue, // ✅ يصير مثل لون الأولى بالصورة عند hover
              borderRadius: 20,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/carone.jpg',
                  width: 78,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 78,
                    height: 56,
                    color: Colors.black12,
                    child: const Icon(Icons.directions_car, color: _textMuted),
                  ),
                ),
              ),
              title: "Browse Cars",
              subtitle: "Explore available vehicles",
              onTap: _openCars,
            ),

            const SizedBox(height: 12),

            // ===== List Cards like screenshot =====
            _HoverTile(
              leadingIcon: Icons.receipt_long,
              title: "My Bookings",
              onTap: _openBookings,
            ),
            const SizedBox(height: 12),

            _HoverTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, size: 28, color: _textMuted),
                  if (_unread > 0)
                    Positioned(
                      right: -3,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE14B4B),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          _unread > 99 ? "99+" : _unread.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              title: "Notifications",
              onTap: _openNotifications,
            ),
            const SizedBox(height: 12),

            _HoverTile(
              leadingIcon: Icons.person_outline,
              title: "Profile",
              onTap: _openProfile,
            ),
            const SizedBox(height: 12),

            _HoverTile(
              leadingIcon: Icons.report_gmailerrorred_outlined,
              title: "Report Incident",
              onTap: _openAccidentReport,
            ),
            const SizedBox(height: 12),

            _HoverTile(
              leadingIcon: Icons.people_alt_outlined,
              title: "Report Accident",
              onTap: _openAccidentReport,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile with Hover effect (للويب/الديسكتوب) + Tap للموبايل
class _HoverTile extends StatefulWidget {
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color hoverColor;

  final Widget? leading; // إذا بدك ويدجت مخصص
  final IconData? leadingIcon; // أو أيقونة جاهزة

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
              // Leading
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

              // Texts
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

              // Trailing arrow
              Icon(Icons.chevron_right_rounded, size: 34, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
