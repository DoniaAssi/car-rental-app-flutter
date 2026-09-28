import 'package:flutter/material.dart';
import '../services/manager_service.dart';

class ManagerEmployeesPage extends StatefulWidget {
  const ManagerEmployeesPage({super.key});

  @override
  State<ManagerEmployeesPage> createState() => _ManagerEmployeesPageState();
}

class _ManagerEmployeesPageState extends State<ManagerEmployeesPage> {
  final _service = ManagerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      return await _service.getEmployees();
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

  Future<void> _toggleEmployee(int userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    final action = newStatus ? "enable" : "disable";

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$action Employee?"),
        content: Text("Are you sure you want to $action this employee?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.toggleEmployeeStatus(userId: userId, isActive: newStatus);
      _toast("Employee ${newStatus ? "enabled" : "disabled"} ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees"),
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
            return const Center(child: Text("No employees found"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final e = list[i];

                final userId = int.tryParse(e["user_id"].toString()) ?? 0;
                final name = e["full_name"] ?? "Unknown";
                final email = e["email"] ?? "";
                final phone = e["phone"] ?? "";
                final role = e["role"] ?? "";
                final isActive = (e["is_active"] ?? 0) == 1;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.green : Colors.grey,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email),
                        Text(phone),
                        Text("Role: $role", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Switch(
                      value: isActive,
                      onChanged: (v) => _toggleEmployee(userId, isActive),
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
