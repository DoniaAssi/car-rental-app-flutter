<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$base = "$protocol://$host/api/uploads/cars/";
$placeholder = "$protocol://$host/api/uploads/cars/placeholder.jpg";

try {
  $sql = "SELECT 
      b.booking_id,
      b.customer_id,
      b.car_id,
      b.start_datetime,
      b.end_datetime,
      b.status,
      b.total_price,
      b.notes,
      c.brand,
      c.model,
      c.model_year,
      c.type,
      COALESCE((SELECT CONCAT('$base', image_name) FROM car_images WHERE car_id=c.car_id ORDER BY sort_order ASC LIMIT 1), '$placeholder') AS cover_image,
      u.full_name AS customer_name,
      u.email AS customer_email
    FROM bookings b
    JOIN cars c ON b.car_id = c.car_id
    JOIN users u ON b.customer_id = u.user_id
    ORDER BY b.booking_id DESC";

  $rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
  echo json_encode(["ok" => true, "data" => $rows]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
