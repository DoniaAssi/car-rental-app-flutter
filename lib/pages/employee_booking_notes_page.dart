import 'package:flutter/material.dart';
import '../services/employee_service.dart';
import 'employee_bookings_page.dart';
import 'employee_car_status_page.dart';
import 'profile_page.dart';
import 'dashboards/employee_dashboard.dart';

class EmployeeBookingNotesPage extends StatefulWidget {
  final int bookingId;

  const EmployeeBookingNotesPage({super.key, required this.bookingId});

  @override
  State<EmployeeBookingNotesPage> createState() => _EmployeeBookingNotesPageState();
}

class _EmployeeBookingNotesPageState extends State<EmployeeBookingNotesPage> {
  final _service = EmployeeService();
  final _noteCtrl = TextEditingController();
  String _selectedCategory = "GENERAL";
  late Future<List<Map<String, dynamic>>> _notesFuture;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primaryBlue = Color(0xFF6EA8FF);
  static const Color _textDark = Color(0xFF1F2A44);
  static const Color _textMuted = Color(0xFF6C7A92);

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _loadNotes() {
    setState(() {
      _notesFuture = _service.getBookingNotes(widget.bookingId);
    });
  }

  Future<void> _refresh() async {
    _loadNotes();
    await _notesFuture;
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _addNote() async {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty) {
      _toast("Please enter a note");
      return;
    }

    try {
      await _service.addBookingNote(
        bookingId: widget.bookingId,
        note: note,
        category: _selectedCategory,
      );
      _noteCtrl.clear();
      _toast("Note added ✅");
      _refresh();
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case "VIOLATION":
        return Colors.red;
      case "DELAY":
        return _primaryBlue;
      case "DAMAGE":
        return Colors.orange;
      default:
        return _textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case "VIOLATION":
        return Icons.receipt;
      case "DELAY":
        return Icons.access_time;
      case "DAMAGE":
        return Icons.warning;
      default:
        return Icons.note;
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
          "Booking Notes",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: _textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Notes List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _notesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }

                final notes = snap.data ?? [];
                if (notes.isEmpty) {
                  return const Center(child: Text("No notes yet"));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final note = notes[i];
                      final category = note["category"] ?? "GENERAL";
                      final noteText = note["note"] ?? "";
                      final createdAt = note["created_at"] ?? "";
                      final createdBy = note["created_by_name"] ?? "Employee";
                      final time = note["time"] ?? "";

                      return Container(
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(category).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: _getCategoryColor(category),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        time.isNotEmpty ? time : createdAt,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    noteText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    createdBy,
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
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Add Note Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Add a note...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Buttons
                Row(
                  children: [
                    _buildCategoryButton("VIOLATION", Colors.red),
                    const SizedBox(width: 8),
                    _buildCategoryButton("DELAY", _primaryBlue),
                    const SizedBox(width: 8),
                    _buildCategoryButton("DAMAGE", Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Add Note"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCategoryButton(String category, Color color) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            category,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeBookingsPage()),
          );
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
