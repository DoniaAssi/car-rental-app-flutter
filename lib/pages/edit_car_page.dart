import 'package:flutter/material.dart';
import '../services/manager_service.dart';

class EditCarPage extends StatefulWidget {
  final Map<String, dynamic> car;
  const EditCarPage({super.key, required this.car});

  @override
  State<EditCarPage> createState() => _EditCarPageState();
}

class _EditCarPageState extends State<EditCarPage> {
  final _service = ManagerService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController plateCtrl;
  late TextEditingController brandCtrl;
  late TextEditingController modelCtrl;
  late TextEditingController yearCtrl;
  late TextEditingController seatsCtrl;
  late TextEditingController dailyPriceCtrl;
  late TextEditingController depositCtrl;
  late TextEditingController mileageCtrl;
  late TextEditingController colorCtrl;
  late TextEditingController descCtrl;

  String typeVal = "SEDAN";
  String transmissionVal = "AUTOMATIC";
  String fuelVal = "GAS";
  String statusVal = "AVAILABLE";

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.car;

    plateCtrl = TextEditingController(text: (c["plate_number"] ?? "").toString());
    brandCtrl = TextEditingController(text: (c["brand"] ?? "").toString());
    modelCtrl = TextEditingController(text: (c["model"] ?? "").toString());
    yearCtrl = TextEditingController(text: (c["model_year"] ?? "").toString());
    seatsCtrl = TextEditingController(text: (c["seats"] ?? "").toString());
    dailyPriceCtrl = TextEditingController(text: (c["daily_price"] ?? "").toString());
    depositCtrl = TextEditingController(text: (c["deposit_amount"] ?? "").toString());
    mileageCtrl = TextEditingController(text: (c["mileage_km"] ?? "").toString());
    colorCtrl = TextEditingController(text: (c["color"] ?? "").toString());
    descCtrl = TextEditingController(text: (c["description"] ?? "").toString());

    typeVal = (c["type"] ?? "SEDAN").toString();
    transmissionVal = (c["transmission"] ?? "AUTOMATIC").toString();
    fuelVal = (c["fuel_type"] ?? "GAS").toString();
    statusVal = (c["status"] ?? "AVAILABLE").toString();
  }

  @override
  void dispose() {
    plateCtrl.dispose();
    brandCtrl.dispose();
    modelCtrl.dispose();
    yearCtrl.dispose();
    seatsCtrl.dispose();
    dailyPriceCtrl.dispose();
    depositCtrl.dispose();
    mileageCtrl.dispose();
    colorCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _req(String? v) {
    if (v == null || v.trim().isEmpty) return "Required";
    return null;
  }

  String? _numReq(String? v) {
    if (v == null || v.trim().isEmpty) return "Required";
    final n = double.tryParse(v.trim());
    if (n == null) return "Must be a number";
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final carId = int.tryParse(widget.car["car_id"].toString()) ?? 0;
    if (carId == 0) {
      _toast("Invalid car_id");
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateCar(
        carId: carId,
        plateNumber: plateCtrl.text.trim(),
        brand: brandCtrl.text.trim(),
        model: modelCtrl.text.trim(),
        modelYear: int.tryParse(yearCtrl.text.trim()) ?? 0,
        type: typeVal,
        seats: int.tryParse(seatsCtrl.text.trim()) ?? 0,
        transmission: transmissionVal,
        fuelType: fuelVal,
        dailyPrice: double.tryParse(dailyPriceCtrl.text.trim()) ?? 0,
        depositAmount: double.tryParse(depositCtrl.text.trim()) ?? 0,
        status: statusVal,
        mileageKm: int.tryParse(mileageCtrl.text.trim()) ?? 0,
        color: colorCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );

      // ✅ رجّع نسخة محدثة للـ UI (عشان تتغير فوراً)
      final updated = Map<String, dynamic>.from(widget.car);
      updated["plate_number"] = plateCtrl.text.trim();
      updated["brand"] = brandCtrl.text.trim();
      updated["model"] = modelCtrl.text.trim();
      updated["model_year"] = int.tryParse(yearCtrl.text.trim()) ?? updated["model_year"];
      updated["type"] = typeVal;
      updated["seats"] = int.tryParse(seatsCtrl.text.trim()) ?? updated["seats"];
      updated["transmission"] = transmissionVal;
      updated["fuel_type"] = fuelVal;
      updated["daily_price"] = double.tryParse(dailyPriceCtrl.text.trim()) ?? updated["daily_price"];
      updated["deposit_amount"] = double.tryParse(depositCtrl.text.trim()) ?? updated["deposit_amount"];
      updated["status"] = statusVal;
      updated["mileage_km"] = int.tryParse(mileageCtrl.text.trim()) ?? updated["mileage_km"];
      updated["color"] = colorCtrl.text.trim();
      updated["description"] = descCtrl.text.trim();

      if (!mounted) return;
      Navigator.pop(context, updated); // ✅ هذا اللي بخلي ManageCars يتغير فوراً
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Car")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _text("Plate Number", plateCtrl, validator: _req),
              const SizedBox(height: 10),
              _text("Brand", brandCtrl, validator: _req),
              const SizedBox(height: 10),
              _text("Model", modelCtrl, validator: _req),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _text("Model Year", yearCtrl, validator: _numReq, keyboard: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _text("Seats", seatsCtrl, validator: _numReq, keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _dropdown("Type", typeVal, ["SEDAN", "SUV", "HATCHBACK", "PICKUP", "VAN", "LUXURY"],
                        (v) => setState(() => typeVal = v)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown("Status", statusVal, ["AVAILABLE", "UNAVAILABLE", "BOOKED", "MAINTENANCE"],
                        (v) => setState(() => statusVal = v)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _dropdown("Transmission", transmissionVal, ["AUTOMATIC", "MANUAL"],
                        (v) => setState(() => transmissionVal = v)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown("Fuel Type", fuelVal, ["GAS", "DIESEL", "ELECTRIC", "HYBRID"],
                        (v) => setState(() => fuelVal = v)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _text("Daily Price", dailyPriceCtrl, validator: _numReq, keyboard: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _text("Deposit", depositCtrl, validator: _numReq, keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _text("Mileage (km)", mileageCtrl, validator: _numReq, keyboard: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _text("Color", colorCtrl, validator: _req)),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Save Changes"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(String label, TextEditingController c,
      {String? Function(String?)? validator, TextInputType? keyboard}) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, void Function(String v) onChanged) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : items.first,
          items: items.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }
}
