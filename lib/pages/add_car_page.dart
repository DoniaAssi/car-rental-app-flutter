import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/session.dart';
import '../services/manager_service.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _service = ManagerService();

  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: "2022");
  final _typeCtrl = TextEditingController(text: "SUV");
  final _seatsCtrl = TextEditingController(text: "5");
  final _transCtrl = TextEditingController(text: "AUTO");
  final _fuelCtrl = TextEditingController(text: "GAS");
  final _dailyCtrl = TextEditingController(text: "65");
  final _depositCtrl = TextEditingController(text: "200");
  final _statusCtrl = TextEditingController(text: "AVAILABLE");
  final _mileageCtrl = TextEditingController(text: "42000");
  final _colorCtrl = TextEditingController(text: "White");
  final _descCtrl = TextEditingController(text: "Comfortable SUV for city and trips.");

  List<File> _images = [];
  bool _loading = false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _typeCtrl.dispose();
    _seatsCtrl.dispose();
    _transCtrl.dispose();
    _fuelCtrl.dispose();
    _dailyCtrl.dispose();
    _depositCtrl.dispose();
    _statusCtrl.dispose();
    _mileageCtrl.dispose();
    _colorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (res == null) return;

    final files = res.paths.whereType<String>().map((p) => File(p)).toList();
    setState(() => _images = files);
  }

  Future<void> _submit() async {
    final user = await Session.getUser();
    if (user == null) {
      _toast("Login first");
      return;
    }

    if (_images.isEmpty) {
      _toast("Please pick at least 1 image");
      return;
    }

    setState(() => _loading = true);

    try {
      final fields = <String, String>{
        "plate_number": _plateCtrl.text.trim(),
        "brand": _brandCtrl.text.trim(),
        "model": _modelCtrl.text.trim(),
        "model_year": _yearCtrl.text.trim(),
        "type": _typeCtrl.text.trim(),
        "seats": _seatsCtrl.text.trim(),
        "transmission": _transCtrl.text.trim(),
        "fuel_type": _fuelCtrl.text.trim(),
        "daily_price": _dailyCtrl.text.trim(),
        "deposit_amount": _depositCtrl.text.trim(),
        "status": _statusCtrl.text.trim(),
        "mileage_km": _mileageCtrl.text.trim(),
        "color": _colorCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "created_by": user["user_id"].toString(),
      };

      final r = await _service.addCar(fields: fields, images: _images);
      _toast("Added ✅ Car ID: ${r["car_id"]}");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController c, String label, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Car (MR-02)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field(_plateCtrl, "Plate Number (ex: P-12345)"),
            _field(_brandCtrl, "Brand (ex: Toyota)"),
            _field(_modelCtrl, "Model (ex: RAV4)"),
            _field(_yearCtrl, "Model Year (ex: 2022)", type: TextInputType.number),
            _field(_typeCtrl, "Type (SUV/SEDAN/..)", type: TextInputType.text),
            _field(_seatsCtrl, "Seats (ex: 5)", type: TextInputType.number),
            _field(_transCtrl, "Transmission (AUTO/MANUAL)"),
            _field(_fuelCtrl, "Fuel Type (GAS/DIESEL)"),
            _field(_dailyCtrl, "Daily Price (ex: 65)", type: TextInputType.number),
            _field(_depositCtrl, "Deposit Amount (ex: 200)", type: TextInputType.number),
            _field(_statusCtrl, "Status (AVAILABLE/MAINTENANCE)"),
            _field(_mileageCtrl, "Mileage KM (ex: 42000)", type: TextInputType.number),
            _field(_colorCtrl, "Color (ex: White)"),
            _field(_descCtrl, "Description"),

            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _pickImages,
                icon: const Icon(Icons.photo_library),
                label: Text(_images.isEmpty ? "Pick Images" : "Picked: ${_images.length} image(s)"),
              ),
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save Car"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
