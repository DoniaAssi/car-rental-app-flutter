import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/session.dart';
import '../services/booking_service.dart';
import 'pick_location_page.dart';

class BookingPage extends StatefulWidget {
  final int carId;
  final double dailyPrice;

  const BookingPage({super.key, required this.carId, required this.dailyPrice});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? pickup, dropoff;

  // Map selection
  LatLng? pickupLatLng;
  LatLng? dropoffLatLng;
  String pickupAddress = "";
  String dropoffAddress = "";

  double total = 0;
  final _service = BookingService();
  bool _sending = false;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _fmtDateTime(DateTime dt) {
    return "${dt.year}-${_two(dt.month)}-${_two(dt.day)}  ${_two(dt.hour)}:${_two(dt.minute)}";
  }

  void _calc() {
    if (pickup == null || dropoff == null) {
      setState(() => total = 0);
      return;
    }

    final diffMinutes = dropoff!.difference(pickup!).inMinutes;
    if (diffMinutes <= 0) {
      setState(() => total = 0);
      return;
    }

    final days = (diffMinutes / (24 * 60)).ceil();
    final safeDays = days <= 0 ? 1 : days;
    setState(() => total = safeDays * widget.dailyPrice);
  }

  Future<void> _pickDateTime({required bool isPickup}) async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: isPickup
          ? (pickup ?? now)
          : (dropoff ?? (pickup?.add(const Duration(hours: 1)) ?? now)),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        isPickup
            ? (pickup ?? now)
            : (dropoff ?? (pickup?.add(const Duration(hours: 1)) ?? now)),
      ),
    );
    if (t == null) return;

    final selected = DateTime(d.year, d.month, d.day, t.hour, t.minute);

    setState(() {
      if (isPickup) {
        pickup = selected;
        if (dropoff != null && !dropoff!.isAfter(pickup!)) {
          dropoff = null;
        }
      } else {
        dropoff = selected;
      }
      _calc();
    });
  }

  Future<void> _pickOnMap({required bool isPickup}) async {
    const defaultRamallah = LatLng(31.9038, 35.2034);

    final initial = isPickup
        ? (pickupLatLng ?? defaultRamallah)
        : (dropoffLatLng ?? defaultRamallah);

    final PickLocationResult? res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationPage(
          title: isPickup ? "Select Pickup Location" : "Select Drop-off Location",
          initial: initial,
        ),
      ),
    );

    if (res == null) return;

    setState(() {
      if (isPickup) {
        pickupLatLng = res.latLng;
        pickupAddress = res.address;
      } else {
        dropoffLatLng = res.latLng;
        dropoffAddress = res.address;
      }
    });
  }

  Future<void> _submit() async {
    if (pickup == null || dropoff == null) {
      _toast("Please select pickup & drop-off date/time");
      return;
    }
    if (!dropoff!.isAfter(pickup!)) {
      _toast("Drop-off must be after pickup");
      return;
    }

    if (pickupLatLng == null || dropoffLatLng == null) {
      _toast("Please select pickup & drop-off locations on the map");
      return;
    }

    if (pickupAddress.trim().isEmpty || dropoffAddress.trim().isEmpty) {
      _toast("Please confirm pickup & drop-off locations");
      return;
    }

    final user = await Session.getUser();
    if (user == null) {
      _toast("Please login first");
      return;
    }

    setState(() => _sending = true);

    try {
      final availability = await _service.checkAvailability(
        carId: widget.carId,
        start: pickup!,
        end: dropoff!,
      );

      final available = availability["available"] == true;
      if (!available) {
        final conflict = availability["conflict"];
        final cStart = conflict?["start_datetime"]?.toString() ?? "";
        final cEnd = conflict?["end_datetime"]?.toString() ?? "";
        _toast("محجوزة من $cStart إلى $cEnd ✅ جرّب تاريخ بعد $cEnd");
        return;
      }

      final res = await _service.createBooking(
        carId: widget.carId,
        customerId: int.parse(user["user_id"].toString()),
        start: pickup!,
        end: dropoff!,
        pickupAddress: pickupAddress.trim(),
        dropoffAddress: dropoffAddress.trim(),
        pickupLat: pickupLatLng!.latitude,
        pickupLng: pickupLatLng!.longitude,
        dropoffLat: dropoffLatLng!.latitude,
        dropoffLng: dropoffLatLng!.longitude,
      );

      _toast("Booking created ✅ Total: \$${res["booking"]["total_price"]}");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _mapPickTile({
    required String title,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? title : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: value.isEmpty ? Colors.black54 : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickupText = pickup == null
        ? "Select Pickup Date & Time"
        : _fmtDateTime(pickup!);

    final dropoffText = dropoff == null
        ? "Select Drop-off Date & Time"
        : _fmtDateTime(dropoff!);

    return Scaffold(
      appBar: AppBar(title: const Text("Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(pickupText),
              trailing: const Icon(Icons.date_range),
              onTap: () => _pickDateTime(isPickup: true),
            ),
            ListTile(
              title: Text(dropoffText),
              trailing: const Icon(Icons.date_range),
              onTap: () => _pickDateTime(isPickup: false),
            ),
            const SizedBox(height: 12),

            _mapPickTile(
              title: "Select Pickup Location on Map",
              value: pickupAddress,
              icon: Icons.location_on_rounded,
              onTap: () => _pickOnMap(isPickup: true),
            ),
            const SizedBox(height: 12),
            _mapPickTile(
              title: "Select Drop-off Location on Map",
              value: dropoffAddress,
              icon: Icons.flag_rounded,
              onTap: () => _pickOnMap(isPickup: false),
            ),

            const SizedBox(height: 20),

            Text(
              "Total: \$${total.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Confirm Booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
