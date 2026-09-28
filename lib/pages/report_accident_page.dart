import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/session.dart';
import '../services/accident_service.dart';

class ReportAccidentPage extends StatefulWidget {
  final int bookingId;
  final String carTitle;

  const ReportAccidentPage({
    super.key,
    required this.bookingId,
    required this.carTitle,
  });

  @override
  State<ReportAccidentPage> createState() => _ReportAccidentPageState();
}

class _ReportAccidentPageState extends State<ReportAccidentPage> {
  final _service = AccidentService();

  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _accidentTime;
  List<PlatformFile> _images = [];

  bool _sending = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pickAccidentTime() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDate: now,
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (t == null) return;

    setState(() {
      _accidentTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: kIsWeb, // ✅ للويب فقط
    );
    if (res == null) return;

    final files = res.files;
    if (files.length > 4) {
      _toast("Max 4 images فقط");
      setState(() => _images = files.take(4).toList());
      return;
    }

    setState(() => _images = files);
  }

  Future<void> _submit() async {
    final user = await Session.getUser();
    if (user == null) {
      _toast("Please login first");
      return;
    }

    final customerId = int.parse(user["user_id"].toString());

    if (_accidentTime == null) {
      _toast("Select accident time");
      return;
    }

    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      _toast("Write accident description");
      return;
    }

    setState(() => _sending = true);

    try {
      final json = await _service.reportAccident(
        bookingId: widget.bookingId,
        customerId: customerId,
        accidentTime: _accidentTime!,
        locationText: _locationCtrl.text.trim(),
        description: desc,
        images: _images,
      );

      _toast("Reported ✅ Accident #${json["accident"]["accident_id"]}");
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _accidentTime == null
        ? "Select accident time"
        : _accidentTime.toString().substring(0, 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Accident 🚗💥"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Booking #${widget.bookingId} • ${widget.carTitle}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(timeText),
              leading: const Icon(Icons.access_time),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickAccidentTime,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: "Location (optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: "Description (required)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(_images.isEmpty
                  ? "Add Photos (0-4)"
                  : "Photos selected: ${_images.length}"),
            ),

            if (_images.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images.map((f) {
                  return Chip(
                    label: Text(f.name, overflow: TextOverflow.ellipsis),
                    onDeleted: () {
                      setState(() => _images.remove(f));
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Submit Report"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
