import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/manager_service.dart';

class ManagerStatisticsPage extends StatefulWidget {
  const ManagerStatisticsPage({super.key});

  @override
  State<ManagerStatisticsPage> createState() => _ManagerStatisticsPageState();
}

class _ManagerStatisticsPageState extends State<ManagerStatisticsPage>
    with SingleTickerProviderStateMixin {
  final _service = ManagerService();

  late TabController _tab;

  DateTime _to = DateTime.now();
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));

  late Future<Map<String, dynamic>> _future;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF1F2A44);
  static const Color _textMuted = Color(0xFF6C7A92);
  static const Color _blue = Color(0xFF4C86FF);
  static const Color _greenPill = Color(0xFFE7F7EE);
  static const Color _greenText = Color(0xFF1F9D55);

  // ✅ NEW: نخزن تواريخ X-axis هنا (نفس ترتيب spots)
  final List<String> _xDates = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _future = _service.fetchReport(from: _from, to: _to);
  }

  void _refresh() {
    setState(() => _future = _service.fetchReport(from: _from, to: _to));
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked == null) return;

    setState(() {
      _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _to = DateTime(picked.end.year, picked.end.month, picked.end.day);
      _future = _service.fetchReport(from: _from, to: _to);
    });
  }

  double _toDouble(dynamic v) => double.tryParse(v.toString()) ?? 0.0;
  int _toInt(dynamic v) => int.tryParse(v.toString()) ?? 0;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Statistics",
          style: TextStyle(fontWeight: FontWeight.w900, color: _textDark),
        ),
        actions: [
          IconButton(
            tooltip: "Pick range",
            icon: const Icon(Icons.date_range, color: _textMuted),
            onPressed: _pickRange,
          ),
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh, color: _textMuted),
            onPressed: _refresh,
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: const [
                Tab(text: "Bookings"),
                Tab(text: "Revenue"),
                Tab(text: "Top Cars"),
              ],
            ),
          ),
        ),
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

          final data = snap.data ?? {};
          final totals = (data["totals"] ?? {}) as Map<String, dynamic>;
          final series = (data["series"] ?? {}) as Map<String, dynamic>;

          final bookingsSeries = (series["bookings"] ?? []) as List;
          final revenueSeries = (series["revenue"] ?? []) as List;

          final totalBookings = _toInt(totals["bookings"]);
          final totalRevenue = _toDouble(totals["revenue"]);

          final topCars = (data["top_cars"] ?? []) as List;
          final breakdown = (data["breakdown"] ?? []) as List;

          return TabBarView(
            controller: _tab,
            children: [
              _buildBookingsTab(
                  totalBookings, totalRevenue, bookingsSeries, breakdown),
              _buildRevenueTab(
                  totalBookings, totalRevenue, revenueSeries, breakdown),
              _buildTopCarsTab(topCars),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsTab(
      int totalBookings, double totalRevenue, List bookingsSeries, List breakdown) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        children: [
          _chartCard(
            spots: _spotsFromSeries(bookingsSeries, keyY: "c"),
            maxYPad: 5,
          ),
          const SizedBox(height: 12),
          _twoStatRow(
            leftTitle: "Total Bookings",
            leftValue: "$totalBookings",
            leftDelta: "+11.53%",
            rightTitle: "Revenue",
            rightValue: "\$${totalRevenue.toStringAsFixed(0)}",
            rightDelta: "+12.03%",
          ),
          const SizedBox(height: 14),
          _breakdownCard(breakdown),
        ],
      ),
    );
  }

  Widget _buildRevenueTab(
      int totalBookings, double totalRevenue, List revenueSeries, List breakdown) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        children: [
          _chartCard(
            spots: _spotsFromSeries(revenueSeries, keyY: "s"),
            maxYPad: 50,
          ),
          const SizedBox(height: 12),
          _twoStatRow(
            leftTitle: "Total Revenue",
            leftValue: "\$${totalRevenue.toStringAsFixed(0)}",
            leftDelta: "+12.03%",
            rightTitle: "Total Bookings",
            rightValue: "$totalBookings",
            rightDelta: "+11.53%",
          ),
          const SizedBox(height: 14),
          _breakdownCard(breakdown),
        ],
      ),
    );
  }

  Widget _buildTopCarsTab(List topCars) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      itemCount: topCars.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = topCars[i] as Map;
        final name = (c["name"] ?? "Car").toString();
        final count = (c["bookings_count"] ?? 0).toString();

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.directions_car, color: _textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$count bookings",
                      style: const TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 30, color: _textMuted),
            ],
          ),
        );
      },
    );
  }

  // ✅ NEW: تحسين المحاور + عناوين + Grid
  Widget _chartCard({
    required List<FlSpot> spots,
    double maxYPad = 5,
  }) {
    final maxYRaw =
        (spots.isEmpty ? 1.0 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b));
    final maxY = (maxYRaw + maxYPad).clamp(1.0, double.infinity);

    // فواصل لطيفة للمحور Y (0, 5, 10, 15...) أو (0, 500, 1000..)
    final yInterval = _niceInterval(maxY);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 190,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,

            // ✅ Grid خفيف
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.black.withOpacity(0.06),
                  strokeWidth: 1,
                );
              },
            ),

            // ✅ Titles للمحاور
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              // Y-axis (يسار)
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    // نخفي آخر رقم لو صار يلخبط
                    if (value < 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // X-axis (تحت)
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _xInterval(spots.length),
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= _xDates.length) {
                      return const SizedBox.shrink();
                    }

                    // نخليها زي الصورة: Apr 1, Apr 7, Apr 15...
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _xDates[i],
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            borderData: FlBorderData(show: false),

            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 10,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((s) {
                    final idx = s.x.toInt();
                    final date = (idx >= 0 && idx < _xDates.length) ? _xDates[idx] : "";
                    return LineTooltipItem(
                      "$date\n${s.y.toStringAsFixed(0)}",
                      const TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                isCurved: true,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: _blue.withOpacity(0.12),
                ),
                color: _blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _twoStatRow({
    required String leftTitle,
    required String leftValue,
    required String leftDelta,
    required String rightTitle,
    required String rightValue,
    required String rightDelta,
  }) {
    return Row(
      children: [
        Expanded(child: _miniStatCard(leftTitle, leftValue, leftDelta)),
        const SizedBox(width: 10),
        Expanded(child: _miniStatCard(rightTitle, rightValue, rightDelta)),
      ],
    );
  }

  Widget _miniStatCard(String title, String value, String delta) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _textMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _greenPill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(delta,
                style: const TextStyle(
                    color: _greenText,
                    fontWeight: FontWeight.w900,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _breakdownCard(List breakdown) {
    int maxV = 1;
    for (final x in breakdown) {
      final m = x as Map;
      final v = _toInt(m["v"]);
      if (v > maxV) maxV = v;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Booking Breakdown",
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.take(5).map((e) {
            final m = e as Map;
            final label = (m["label"] ?? "").toString();
            final v = _toInt(m["v"]);
            final p = v / maxV;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(label,
                        style: const TextStyle(
                            color: _textMuted, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: p.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: const Color(0xFFF1F4FB),
                        valueColor: AlwaysStoppedAnimation(
                            _blue.withOpacity(0.85)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 32,
                    child: Text(
                      "$v",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: _textMuted, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ✅ NEW: spots + تواريخ تحت الرسم
  List<FlSpot> _spotsFromSeries(List series, {required String keyY}) {
    final spots = <FlSpot>[];
    _xDates.clear();

    for (int i = 0; i < series.length; i++) {
      final m = series[i] as Map;
      final y = double.tryParse((m[keyY] ?? 0).toString()) ?? 0.0;
      final d = (m["d"] ?? "").toString(); // YYYY-MM-DD

      _xDates.add(_prettyDate(d)); // Apr 01
      spots.add(FlSpot(i.toDouble(), y));
    }
    return spots;
  }

  String _prettyDate(String iso) {
    // iso: YYYY-MM-DD
    final parts = iso.split("-");
    if (parts.length != 3) return "";
    final mm = parts[1];
    final dd = parts[2];
    return "${_monthName(mm)} ${dd.startsWith('0') ? dd.substring(1) : dd}";
  }

  String _monthName(String m) {
    switch (m) {
      case "01":
        return "Jan";
      case "02":
        return "Feb";
      case "03":
        return "Mar";
      case "04":
        return "Apr";
      case "05":
        return "May";
      case "06":
        return "Jun";
      case "07":
        return "Jul";
      case "08":
        return "Aug";
      case "09":
        return "Sep";
      case "10":
        return "Oct";
      case "11":
        return "Nov";
      case "12":
        return "Dec";
      default:
        return "";
    }
  }

  // ✅ Interval ذكي لمحور X: حسب عدد النقاط
  double _xInterval(int len) {
    if (len <= 6) return 1;
    if (len <= 12) return 2;
    if (len <= 20) return 4;
    if (len <= 35) return 6;
    return 8;
  }

  // ✅ Interval “حلو” لمحور Y
  double _niceInterval(double maxY) {
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    return (maxY / 4).ceilToDouble();
  }
}
