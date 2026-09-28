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
  $sql = "SELECT a.*, 
      c.brand, c.model, c.model_year,
      u.full_name AS customer_name,
      COALESCE((SELECT CONCAT('$base', image_name) FROM car_images WHERE car_id=c.car_id ORDER BY sort_order ASC LIMIT 1), '$placeholder') AS cover_image
    FROM accidents a
    JOIN cars c ON a.car_id = c.car_id
    JOIN bookings b ON a.booking_id = b.booking_id
    JOIN users u ON a.customer_id = u.user_id
    ORDER BY a.accident_id DESC";

  $rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
  echo json_encode(["ok" => true, "data" => $rows]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
