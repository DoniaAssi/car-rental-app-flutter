<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

try {
  // Get today's stats
  $today = date('Y-m-d');
  
  // Count rented cars (cars with active bookings today)
  $rented = $pdo->query("
    SELECT COUNT(DISTINCT c.car_id) AS cnt
    FROM cars c
    INNER JOIN bookings b ON c.car_id = b.car_id
    WHERE b.status IN ('CONFIRMED', 'ACTIVE')
      AND DATE('$today') BETWEEN DATE(b.start_datetime) AND DATE(b.end_datetime)
  ")->fetch(PDO::FETCH_ASSOC);
  
  // Count available cars
  $available = $pdo->query("
    SELECT COUNT(*) AS cnt
    FROM cars
    WHERE status = 'AVAILABLE'
      AND car_id NOT IN (
        SELECT DISTINCT car_id FROM bookings
        WHERE status IN ('CONFIRMED', 'ACTIVE')
          AND DATE('$today') BETWEEN DATE(start_datetime) AND DATE(end_datetime)
      )
  ")->fetch(PDO::FETCH_ASSOC);
  
  // Count maintenance cars
  $maintenance = $pdo->query("
    SELECT COUNT(*) AS cnt
    FROM cars
    WHERE status = 'MAINTENANCE'
  ")->fetch(PDO::FETCH_ASSOC);

  echo json_encode([
    "ok" => true,
    "data" => [
      "rented" => (int)($rented["cnt"] ?? 0),
      "available" => (int)($available["cnt"] ?? 0),
      "maintenance" => (int)($maintenance["cnt"] ?? 0),
    ]
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
