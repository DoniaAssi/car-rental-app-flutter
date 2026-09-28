import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  final int bookingId;
  final double amount;

  const PaymentPage({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _service = PaymentService();
  bool _loading = false;

  // ✅ طرق الدفع
  final _methods = const [
    "MOCK_CARD",
    "MOCK_PAYPAL",
    "CASH",
  ];
  String _method = "MOCK_CARD";

  // ✅ حقول تظهر بس لو Card
  final _cardCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _cardCtrl.dispose();
    _nameCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _methodLabel(String m) {
    switch (m) {
      case "MOCK_CARD":
        return "Mock Card";
      case "MOCK_PAYPAL":
        return "Mock PayPal";
      case "CASH":
        return "Cash";
      default:
        return m;
    }
  }

  Future<void> _pay() async {
    // ✅ Validation بسيط للـ Card بس
    if (_method == "MOCK_CARD") {
      if (_cardCtrl.text.trim().length < 12) return _toast("Enter valid card number");
      if (_nameCtrl.text.trim().isEmpty) return _toast("Enter card holder name");
      if (_cvvCtrl.text.trim().length < 3) return _toast("Enter valid CVV");
    }

    setState(() => _loading = true);

    try {
      final res = await _service.payMock(
        bookingId: widget.bookingId,
        amount: widget.amount,
        method: _method,
      );

      _toast(res["message"] ?? "Paid ✅");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Amount: \$${widget.amount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // ✅ Spinner طرق الدفع
            DropdownButtonFormField<String>(
              value: _method,
              items: _methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(_methodLabel(m))))
                  .toList(),
              onChanged: (v) => setState(() => _method = v!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Payment Method",
              ),
            ),

            const SizedBox(height: 12),

            // ✅ يظهر فقط لو الدفع Card
            if (_method == "MOCK_CARD") ...[
              TextField(
                controller: _cardCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Card Number",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Card Holder Name",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cvvCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "CVV",
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _pay,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Pay Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
