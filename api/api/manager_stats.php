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
  // ✅ Cars stats
  // (ملاحظة: عدّل أسماء الأعمدة حسب جدول cars عندك)
  // افتراض شائع: cars.status = AVAILABLE / UNAVAILABLE / MAINTENANCE
  $cars = [
    "available" => 0,
    "unavailable" => 0,
    "maintenance" => 0
  ];

  try {
    $st = $pdo->query("
      SELECT 
        SUM(CASE WHEN UPPER(status)='AVAILABLE' THEN 1 ELSE 0 END) AS available,
        SUM(CASE WHEN UPPER(status)='UNAVAILABLE' THEN 1 ELSE 0 END) AS unavailable,
        SUM(CASE WHEN UPPER(status)='MAINTENANCE' THEN 1 ELSE 0 END) AS maintenance
      FROM cars
    ");
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if ($row) {
      $cars["available"] = (int)($row["available"] ?? 0);
      $cars["unavailable"] = (int)($row["unavailable"] ?? 0);
      $cars["maintenance"] = (int)($row["maintenance"] ?? 0);
    }
  } catch (Throwable $e) {
    // لو جدول cars عندك أعمدته مختلفة، بنخليها صفر وما نوقع السيرفر
  }

  // ✅ New bookings count (آخر 24 ساعة مثلا أو status=PENDING)
  $newBookings = 0;
  try {
    $st2 = $pdo->query("
      SELECT COUNT(*) AS c
      FROM bookings
      WHERE UPPER(status)='PENDING'
    ");
    $newBookings = (int)$st2->fetchColumn();
  } catch (Throwable $e) {}

  // ✅ Revenue today & week
  // افتراض payments.amount موجود و payments.created_at موجود و payments.status = PAID (اختياري)
  $revToday = 0.0;
  $revWeek  = 0.0;

  try {
    $st3 = $pdo->query("
      SELECT COALESCE(SUM(amount),0) AS total
      FROM payments
      WHERE DATE(created_at)=CURDATE()
    ");
    $revToday = (float)$st3->fetchColumn();
  } catch (Throwable $e) {}

  try {
    $st4 = $pdo->query("
      SELECT COALESCE(SUM(amount),0) AS total
      FROM payments
      WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ");
    $revWeek = (float)$st4->fetchColumn();
  } catch (Throwable $e) {}

  echo json_encode([
    "ok" => true,
    "data" => [
      "cars" => $cars,
      "new_bookings" => $newBookings,
      "revenue" => [
        "today" => $revToday,
        "week"  => $revWeek
      ]
    ]
  ]);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
