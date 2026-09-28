import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/session.dart';

import 'dashboards/customer_dashboard.dart';
import 'dashboards/employee_dashboard.dart';
import 'dashboards/manager_dashboard.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _goByRole(String role) {
    final r = role.trim().toUpperCase();

    Widget page;
    switch (r) {
      case "CUSTOMER":
        page = const CustomerDashboard();
        break;
      case "WASHING_EMPLOYEE":
        page = const EmployeeDashboard();
        break;
      case "COMPANY_MANAGER":
        page = const ManagerDashboard();
        break;
      default:
        page = const CustomerDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _toast("Fill email and password");
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await _auth.login(email: email, password: pass);
      final user = Map<String, dynamic>.from(res["user"]);

      await Session.saveUser(user);

      _toast("Welcome ${user["full_name"]} ✅");
      _goByRole(user["role"].toString());
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Car Image
            Image.asset('assets/carone.jpg', width: 200), // تأكد من إضافة الصورة في مجلد "assets"
            
            // Title
            SizedBox(height: 20),
            Text(
              'Car Rental Ramallah',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            // Subtitle/Description
            SizedBox(height: 10),
            Text(
              'Easily rent a car for any trip',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Email TextField
            SizedBox(height: 40),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            
            // Password TextField
            SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _hidePass,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hidePass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
              ),
            ),
            
            // Login Button
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // اللون الأزرق
                  minimumSize: Size(200, 50), // الحجم
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            
            // SignUp Button
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: _goToSignup,
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
