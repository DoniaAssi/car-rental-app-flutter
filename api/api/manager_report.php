<?php
header('Content-Type: application/json; charset=utf-8');
require_once "db.php";

/*
GET:
  manager_report.php?from=2026-01-01&to=2026-01-31

ملاحظات:
- from/to بصيغة YYYY-MM-DD
- إذا ما انبعثوا: افتراضي آخر 30 يوم
*/

$from = isset($_GET['from']) ? $_GET['from'] : date('Y-m-d', strtotime('-30 days'));
$to   = isset($_GET['to'])   ? $_GET['to']   : date('Y-m-d');

try {
  // 1) Total bookings (استثني الملغي/المرفوض)
  $stmt = $pdo->prepare("
    SELECT COUNT(*) AS total
    FROM bookings
    WHERE DATE(start_datetime) BETWEEN :from AND :to
      AND status NOT IN ('CANCELLED','REJECTED')
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $totalBookings = (int)$stmt->fetch()['total'];

  // 2) Revenue: من payments SUCCESS (ولو ما في دفعات، بنستخدم bookings.total_price)
  $stmt = $pdo->prepare("
    SELECT COALESCE(SUM(amount),0) AS revenue
    FROM payments
    WHERE status='SUCCESS'
      AND DATE(COALESCE(paid_at, created_at)) BETWEEN :from AND :to
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $revenuePayments = (float)$stmt->fetch()['revenue'];

  $stmt = $pdo->prepare("
    SELECT COALESCE(SUM(total_price),0) AS revenue
    FROM bookings
    WHERE DATE(start_datetime) BETWEEN :from AND :to
      AND status IN ('CONFIRMED','ACTIVE','COMPLETED')
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $revenueBookings = (float)$stmt->fetch()['revenue'];

  $totalRevenue = $revenuePayments > 0 ? $revenuePayments : $revenueBookings;

  // 3) Bookings per day (line)
  $stmt = $pdo->prepare("
    SELECT DATE(start_datetime) AS d, COUNT(*) AS c
    FROM bookings
    WHERE DATE(start_datetime) BETWEEN :from AND :to
      AND status NOT IN ('CANCELLED','REJECTED')
    GROUP BY DATE(start_datetime)
    ORDER BY d ASC
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $bookingsSeries = $stmt->fetchAll(PDO::FETCH_ASSOC);

  // 4) Revenue per day (line) - payments SUCCESS
  $stmt = $pdo->prepare("
    SELECT DATE(COALESCE(paid_at, created_at)) AS d, COALESCE(SUM(amount),0) AS s
    FROM payments
    WHERE status='SUCCESS'
      AND DATE(COALESCE(paid_at, created_at)) BETWEEN :from AND :to
    GROUP BY DATE(COALESCE(paid_at, created_at))
    ORDER BY d ASC
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $revenueSeries = $stmt->fetchAll(PDO::FETCH_ASSOC);

  // لو ما في payments رجع revenue من bookings
  if (count($revenueSeries) == 0) {
    $stmt = $pdo->prepare("
      SELECT DATE(start_datetime) AS d, COALESCE(SUM(total_price),0) AS s
      FROM bookings
      WHERE DATE(start_datetime) BETWEEN :from AND :to
        AND status IN ('CONFIRMED','ACTIVE','COMPLETED')
      GROUP BY DATE(start_datetime)
      ORDER BY d ASC
    ");
    $stmt->execute([':from'=>$from, ':to'=>$to]);
    $revenueSeries = $stmt->fetchAll(PDO::FETCH_ASSOC);
  }

  // 5) Top Cars
  $stmt = $pdo->prepare("
    SELECT c.car_id,
           CONCAT(c.brand,' ',c.model) AS name,
           COUNT(*) AS bookings_count
    FROM bookings b
    JOIN cars c ON c.car_id=b.car_id
    WHERE DATE(b.start_datetime) BETWEEN :from AND :to
      AND b.status NOT IN ('CANCELLED','REJECTED')
    GROUP BY c.car_id
    ORDER BY bookings_count DESC
    LIMIT 8
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $topCars = $stmt->fetchAll(PDO::FETCH_ASSOC);

  // 6) Booking Breakdown (SUV/Sedan + Electric كفئة لحال)
  $stmt = $pdo->prepare("
    SELECT c.type AS label, COUNT(*) AS v
    FROM bookings b
    JOIN cars c ON c.car_id=b.car_id
    WHERE DATE(b.start_datetime) BETWEEN :from AND :to
      AND b.status NOT IN ('CANCELLED','REJECTED')
    GROUP BY c.type
    ORDER BY v DESC
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $byType = $stmt->fetchAll(PDO::FETCH_ASSOC);

  $stmt = $pdo->prepare("
    SELECT 'Electric' AS label, COUNT(*) AS v
    FROM bookings b
    JOIN cars c ON c.car_id=b.car_id
    WHERE DATE(b.start_datetime) BETWEEN :from AND :to
      AND b.status NOT IN ('CANCELLED','REJECTED')
      AND c.fuel_type='ELECTRIC'
  ");
  $stmt->execute([':from'=>$from, ':to'=>$to]);
  $electric = $stmt->fetch(PDO::FETCH_ASSOC);

  // دمج breakdown + حافظ على Electric لو قيمته >0
  $breakdown = $byType;
  if ((int)$electric['v'] > 0) $breakdown[] = $electric;

  echo json_encode([
    "ok" => true,
    "range" => ["from"=>$from, "to"=>$to],
    "totals" => [
      "bookings" => $totalBookings,
      "revenue"  => $totalRevenue
    ],
    "series" => [
      "bookings" => $bookingsSeries, // [{d:'2026-01-01', c:5}, ...]
      "revenue"  => $revenueSeries   // [{d:'2026-01-01', s:120.50}, ...]
    ],
    "top_cars" => $topCars,
    "breakdown" => $breakdown
  ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
  http_response_code(500);
  echo json_encode(["ok"=>false, "error"=>$e->getMessage()]);
}
