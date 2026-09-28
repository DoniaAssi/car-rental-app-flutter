import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../core/api_config.dart';
import 'booking_page.dart';

class CarDetailsPage extends StatefulWidget {
  final int carId;
  const CarDetailsPage({super.key, required this.carId});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final _service = CarService();
  late Future<Map<String, dynamic>> _future;

  final PageController _pageController = PageController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchCarDetails(widget.carId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Placeholder when image fails
  Widget _placeholder({double w = double.infinity, double h = 220}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
    );
  }


  // Resolve URL (supports "url" or "image_name")
  String _resolveImageUrl(Map<String, dynamic> img) {
    final url = (img["url"] ?? "").toString().trim();
    if (url.isNotEmpty && (url.startsWith("http://") || url.startsWith("https://"))) {
      return url;
    }

    final name = (img["image_name"] ?? "").toString().trim();
    if (name.isEmpty) return "";

    return "${ApiConfig()}/$name";
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 18 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2F6BFF) : Colors.black26,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _specText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
        height: 1.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Car Details",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // زر ثابت تحت مثل الصورة
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          final car = data == null ? <String, dynamic>{} : Map<String, dynamic>.from(data["car"] ?? {});
          final dailyPrice = double.tryParse((car["daily_price"] ?? "").toString()) ?? 0;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF2F6BFF), Color(0xFF55A8FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (snap.connectionState == ConnectionState.done && dailyPrice > 0)
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingPage(
                                carId: widget.carId,
                                dailyPrice: dailyPrice,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Center(
                    child: Text(
                      "Book This Car",
                      style: TextStyle(
                        color: Colors.white.withOpacity(
                          (snap.connectionState == ConnectionState.done && dailyPrice > 0) ? 1 : 0.6,
                        ),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          if (!snap.hasData) {
            return const Center(child: Text("No data"));
          }

          final data = snap.data!;
          final car = Map<String, dynamic>.from(data["car"] ?? {});
          final images = (data["images"] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          final dailyPrice = double.tryParse((car["daily_price"] ?? "").toString()) ?? 0;

          final brand = (car["brand"] ?? "").toString();
          final model = (car["model"] ?? "").toString();
          final year = (car["model_year"] ?? "").toString();

          final type = (car["type"] ?? "").toString();
          final trans = (car["transmission"] ?? "").toString();
          final fuel = (car["fuel_type"] ?? "").toString();
          final seats = (car["seats"] ?? "").toString();

          final desc = (car["description"] ?? "No description").toString();

          // URLs list
          final urls = images
              .map(_resolveImageUrl)
              .where((u) => u.trim().isNotEmpty)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), // مساحة للزرّ تحت
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ====== Main Image Carousel (like screenshot) ======
                    if (urls.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 220,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: urls.length,
                                onPageChanged: (i) => setState(() => _activeIndex = i),
                                itemBuilder: (context, i) {
                                  return Image.network(
                                    urls[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stack) => _placeholder(h: 220),
                                  );
                                },
                              ),
                              // Dots overlay bottom center
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(urls.length, (i) => _dot(i == _activeIndex)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      _placeholder(h: 220),

                    const SizedBox(height: 16),

                    // ====== Title ======
                    Text(
                      "$brand $model $year",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ====== Specs row (Sedan • Automatic • Gasoline • Seats: 5) ======
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _specText(type.isEmpty ? "Sedan" : type),
                        Text("•", style: TextStyle(color: Colors.grey.shade500)),
                        _specText(trans.isEmpty ? "Automatic" : trans),
                        Text("•", style: TextStyle(color: Colors.grey.shade500)),
                        _specText(fuel.isEmpty ? "Gasoline" : fuel),
                        Text("•", style: TextStyle(color: Colors.grey.shade500)),
                        _specText("Seats: ${seats.isEmpty ? "5" : seats}"),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ====== Price ======
                    Row(
                      children: [
                        const Text(
                          "Price: ",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          dailyPrice > 0 ? "\$${dailyPrice.toStringAsFixed(0)}/day" : "\$--/day",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F6BFF),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ====== Thumbnails row (like screenshot) ======
                    if (urls.length > 1)
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: urls.length.clamp(0, 5), // 3-5 صور مثل الصورة
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 118,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: i == _activeIndex ? const Color(0xFF2F6BFF) : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Image.network(
                                    urls[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        Container(color: Colors.black12, child: const Icon(Icons.image_not_supported)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 18),

                    // ====== Description ======
                    const Text(
                      "Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                    ),

                    const SizedBox(height: 18),

                    // ====== Rental Terms ======
                    const Text(
                      "Rental Terms",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),

                    _term("ID required"),
                    _term("Return on time to avoid extra fees"),
                    _term("Fuel should be returned same level"),
                    _term("Damage fees apply if needed"),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _term(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  ", style: TextStyle(fontSize: 16, height: 1.2)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],

        
      ),
    );
  }
}
