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
  // Cars counts
  $cars = $pdo->query("
    SELECT
      SUM(CASE WHEN UPPER(status)='AVAILABLE' THEN 1 ELSE 0 END) AS available,
      SUM(CASE WHEN UPPER(status)='UNAVAILABLE' THEN 1 ELSE 0 END) AS unavailable,
      SUM(CASE WHEN UPPER(status)='MAINTENANCE' THEN 1 ELSE 0 END) AS maintenance
    FROM cars
  ")->fetch(PDO::FETCH_ASSOC);

  // New bookings (pending)
  $newBookings = $pdo->query("
    SELECT COUNT(*) AS cnt
    FROM bookings
    WHERE UPPER(status)='PENDING'
  ")->fetch(PDO::FETCH_ASSOC);

  // Revenue today + this week (from payments)
  // ⚠️ assumes payments has amount + status + created_at
  $revToday = $pdo->query("
    SELECT COALESCE(SUM(amount),0) AS total
    FROM payments
    WHERE (UPPER(status)='PAID' OR UPPER(status)='SUCCESS')
      AND DATE(created_at) = CURDATE()
  ")->fetch(PDO::FETCH_ASSOC);

  $revWeek = $pdo->query("
    SELECT COALESCE(SUM(amount),0) AS total
    FROM payments
    WHERE (UPPER(status)='PAID' OR UPPER(status)='SUCCESS')
      AND YEARWEEK(created_at, 1) = YEARWEEK(NOW(), 1)
  ")->fetch(PDO::FETCH_ASSOC);

  echo json_encode([
    "ok" => true,
    "data" => [
      "cars" => [
        "available" => (int)($cars["available"] ?? 0),
        "unavailable" => (int)($cars["unavailable"] ?? 0),
        "maintenance" => (int)($cars["maintenance"] ?? 0),
      ],
      "new_bookings" => (int)($newBookings["cnt"] ?? 0),
      "revenue" => [
        "today" => (float)($revToday["total"] ?? 0),
        "week"  => (float)($revWeek["total"] ?? 0),
      ]
    ]
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
