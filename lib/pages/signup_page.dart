import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _auth = AuthService();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // ✅ only for manager
  final _managerCodeCtrl = TextEditingController();

  String _selectedRole = 'CUSTOMER';

  bool _loading = false;
  bool _hidePass = true;

  final List<String> _roles = const [
    'CUSTOMER',
    'WASHING_EMPLOYEE',
    'COMPANY_MANAGER',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _managerCodeCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;
    final managerCode = _managerCodeCtrl.text.trim();

    if ([name, phone, email, pass, confirm].any((e) => e.isEmpty)) {
      _toast("Please fill all fields");
      return;
    }

    if (!email.contains("@")) {
      _toast("Invalid email");
      return;
    }

    if (pass.length < 6) {
      _toast("Password must be at least 6 characters");
      return;
    }

    if (pass != confirm) {
      _toast("Passwords do not match");
      return;
    }

    final isManager = _selectedRole == "COMPANY_MANAGER";
    if (isManager && managerCode.isEmpty) {
      _toast("Manager code is required");
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.register(
        fullName: name,
        phone: phone,
        email: email,
        password: pass,
        role: _selectedRole,
        managerCode: isManager ? managerCode : null,
      );

      _toast("Account created successfully ✅");
      if (!mounted) return;
      Navigator.pop(context); // back to Login
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = _selectedRole == "COMPANY_MANAGER";

    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Car Image
            Image.asset('assets/carone.jpg', width: 300), // Ensure the image is in the "assets" folder
            
            // Title
            SizedBox(height: 20),
            Text(
              'CarRentalRamallah',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            // Subtitle/Description
            SizedBox(height: 10),
            Text(
              'Create your account to rent a car easily.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Full Name
            _field(_nameCtrl, "Full Name", Icons.person),
            // Phone
            _field(_phoneCtrl, "Phone", Icons.phone),
            // Email
            _field(_emailCtrl, "Email", Icons.email),
            
            // Role Dropdown
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v ?? "CUSTOMER"),
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle),
              ),
            ),
            
            if (isManager) ...[
              // Manager Code
              const SizedBox(height: 12),
              _field(_managerCodeCtrl, "Manager Code", Icons.code),
            ],

            // Password
            const SizedBox(height: 12),
            _passwordField(_passCtrl, "Password"),
            _passwordField(_confirmPassCtrl, "Confirm Password"),

            // Create Account Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Create Account"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  minimumSize: Size(200, 50), // Size of the button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),

            // Already have an account link
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Login"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for form fields
  Widget _field(TextEditingController c, String label, IconData icon,
      [TextInputType type = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  // Password field with hide/show functionality
  Widget _passwordField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: _hidePass,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_hidePass ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _hidePass = !_hidePass),
          ),
        ),
      ),
    );
  }
}
