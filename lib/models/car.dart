class Car {
  final int id;
  final String brand;
  final String model;
  final int year;
  final String type;
  final int seats;
  final String transmission;
  final String fuelType;
  final double dailyPrice;
  final String status;
  final String coverUrl;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.type,
    required this.seats,
    required this.transmission,
    required this.fuelType,
    required this.dailyPrice,
    required this.status,
    required this.coverUrl,
  });

  factory Car.fromJson(Map<String, dynamic> j) {
    return Car(
      id: int.parse(j['car_id'].toString()),
      brand: j['brand'].toString(),
      model: j['model'].toString(),
      year: int.parse(j['model_year'].toString()),
      type: j['type'].toString(),
      seats: int.parse(j['seats'].toString()),
      transmission: j['transmission'].toString(),
      fuelType: j['fuel_type'].toString(),
      dailyPrice: double.parse(j['daily_price'].toString()),
      status: j['status'].toString(),
      coverUrl: (j['cover_url'] ?? '').toString().trim(), // ✅ fixed
    );
  }
}

