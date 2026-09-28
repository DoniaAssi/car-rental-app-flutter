import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../core/api_config.dart';
import 'car_details_page.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  final _service = CarService();
  final _searchCtrl = TextEditingController();

  final _types = const ["ALL", "SUV", "SEDAN", "HATCHBACK", "VAN", "PICKUP", "LUXURY"];
  String _selectedType = "ALL";

  RangeValues _priceRange = const RangeValues(0, 200);
  bool _loading = false;
  List<Car> _cars = [];

  // نفس منطق CarDetailsPage لحل الرابط
  String _resolveCoverUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return "";
    if (v.startsWith("http://") || v.startsWith("https://")) return v;

    final cleaned = v.startsWith("uploads/cars/")
        ? v.substring("uploads/cars/".length)
        : (v.startsWith("/uploads/cars/") ? v.substring("/uploads/cars/".length) : v);

    return "${ApiConfig.carsImagesBase}/$cleaned";
  }

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    setState(() => _loading = true);
    try {
      final cars = await _service.fetchCars(
        type: _selectedType,
        query: _searchCtrl.text,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
      );
      setState(() => _cars = cars);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Badge للحالة (محجوزة/متاحة) بنفس ستايل نظيف
  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    final isBooked = (s == "BOOKED");

    final text = isBooked ? "محجوزة" : "متاحة";
    final color = isBooked ? const Color(0xFFE85D5D) : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  // Chip للسعر مثل التصميم
  Widget _priceChip(double dailyPrice) {
    final txt = "\$${dailyPrice.toStringAsFixed(0)}/day";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2F6BFF).withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2F6BFF).withOpacity(0.35)),
      ),
      child: Text(
        txt,
        style: const TextStyle(
          color: Color(0xFF2F6BFF),
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F7FB);
    const primary = Color(0xFF2F6BFF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Cars",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loadCars,
            icon: const Icon(Icons.refresh_rounded),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ====== Filters Card (مثل التصميم) ======
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            items: _types
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _selectedType = v!);
                              _loadCars();
                            },
                            decoration: InputDecoration(
                              labelText: "Type",
                              filled: true,
                              fillColor: const Color(0xFFF2F4FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: _loadCars,
                            icon: const Icon(Icons.tune_rounded, color: primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search brand/model",
                        filled: true,
                        fillColor: const Color(0xFFF2F4FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _loadCars,
                        ),
                      ),
                      onSubmitted: (_) => _loadCars(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          "Price Range",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          "\$${_priceRange.start.toStringAsFixed(0)} - \$${_priceRange.end.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 200,
                      divisions: 20,
                      onChanged: (v) => setState(() => _priceRange = v),
                      onChangeEnd: (_) => _loadCars(),
                      activeColor: primary,
                      inactiveColor: primary.withOpacity(0.18),
                      labels: RangeLabels(
                        _priceRange.start.toStringAsFixed(0),
                        _priceRange.end.toStringAsFixed(0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====== List ======
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cars.isEmpty
                      ? const Center(child: Text("No cars found"))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _cars.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final c = _cars[i];
                            final isBooked = c.status.toUpperCase() == "BOOKED";
                            final imgUrl = _resolveCoverUrl(c.coverUrl);

                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                if (isBooked) {
                                  _toast("هاي السيارة محجوزة حالياً ✅ جرّب سيارة ثانية");
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CarDetailsPage(carId: c.id)),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 72,
                                        height: 72,
                                        color: const Color(0xFFF2F4FA),
                                        child: imgUrl.isEmpty
                                            ? const Icon(Icons.image_not_supported, color: Colors.black26)
                                            : Image.network(
                                                imgUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image_not_supported, color: Colors.black26),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${c.brand} ${c.model} (${c.year})",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${c.type} • ${c.transmission}",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _priceChip(c.dailyPrice),
                                              const SizedBox(width: 8),
                                              _statusBadge(c.status),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // arrow
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}