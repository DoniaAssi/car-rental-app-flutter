import 'package:flutter/material.dart';
import '../core/session.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _service = ProfileService();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _saving = false;
  bool _changingPass = false;

  int _userId = 0;

  // 🎨 ألوان/ستايل قريب جدًا من تصميم الصورة
  static const _bg = Color(0xFFF5F6FA);
  static const _card = Colors.white;
  static const _primary = Color(0xFF2F6FED);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _loadFromSession();
  }

  Future<void> _loadFromSession() async {
    final u = await Session.getUser();
    if (u == null) return;

    setState(() {
      _userId = int.tryParse(u["user_id"].toString()) ?? 0;
    });

    _nameCtrl.text = (u["full_name"] ?? "").toString();
    _emailCtrl.text = (u["email"] ?? "").toString();
    _phoneCtrl.text = (u["phone"] ?? "").toString();
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (_userId <= 0) {
      _toast("Invalid user");
      return;
    }
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _toast("Please fill all fields");
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await _service.updateProfile(
        userId: _userId,
        fullName: name,
        email: email,
        phone: phone,
      );

      final updatedUser = Map<String, dynamic>.from(res["user"]);
      await Session.saveUser(updatedUser);

      _toast("Saved ✅");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updatePassword() async {
    final oldP = _oldPassCtrl.text;
    final newP = _newPassCtrl.text;

    if (_userId <= 0) {
      _toast("Invalid user");
      return;
    }
    if (oldP.isEmpty || newP.isEmpty) {
      _toast("Fill old & new password");
      return;
    }

    setState(() => _changingPass = true);
    try {
      await _service.changePassword(
        userId: _userId,
        oldPassword: oldP,
        newPassword: newP,
      );

      _oldPassCtrl.clear();
      _newPassCtrl.clear();

      _toast("Password updated ✅");
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _changingPass = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "U";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  InputDecoration _dec({
    required String label,
    required IconData icon,
  }) {
    // InputDecoration رسميًا للـ TextField :contentReference[oaicite:4]{index=4}
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child, Widget? trailing}) {
    return Card(
      color: _card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text.trim().isEmpty ? "User" : _nameCtrl.text.trim();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: _bg,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar( // CircleAvatar رسميًا :contentReference[oaicite:5]{index=5}
              radius: 18,
              backgroundColor: const Color(0xFFEAF0FF),
              child: Text(
                _initials(name),
                style: const TextStyle(color: _primary, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          // ✅ Header زي الداشبورد (عنوان + سطر صغير)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFEAF0FF),
                  child: Text(
                    _initials(name),
                    style: const TextStyle(color: _primary, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Your Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text(
                        "Update your personal info and password",
                        style: TextStyle(color: _muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ✅ Profile Info Card
          _sectionCard(
            title: "Profile Information",
            trailing: const Icon(Icons.person_outline, color: _muted, size: 20),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: _dec(label: "Name", icon: Icons.person),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec(label: "Email", icon: Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec(label: "Phone", icon: Icons.phone_outlined),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // styleFrom رسميًا :contentReference[oaicite:6]{index=6}
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ✅ Password Card
          _sectionCard(
            title: "Security",
            trailing: const Icon(Icons.lock_outline, color: _muted, size: 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Change Password (Optional)",
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _oldPassCtrl,
                  obscureText: true,
                  decoration: _dec(label: "Old Password", icon: Icons.lock),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPassCtrl,
                  obscureText: true,
                  decoration: _dec(label: "New Password", icon: Icons.lock_outline),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.transparent,
                    ),
                    onPressed: _changingPass ? null : _updatePassword,
                    child: _changingPass
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Update Password", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
