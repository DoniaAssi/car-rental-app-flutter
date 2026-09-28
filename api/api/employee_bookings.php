<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$filter = strtoupper(trim($_GET['filter'] ?? 'ALL'));
$base = "http://127.0.0.1/car_rental_api/uploads/cars/";
$placeholder = "http://127.0.0.1/car_rental_api/uploads/cars/placeholder.jpg";

try {
  $sql = "
    SELECT 
      b.booking_id,
      b.customer_id,
      u.full_name AS customer_name,
      b.car_id,
      c.brand,
      c.model,
      c.type,
      b.start_datetime,
      b.end_datetime,
      b.status,
      b.pickup_address,
      b.dropoff_address,
      COALESCE(
        (SELECT CONCAT('$base', image_name)
         FROM car_images
         WHERE car_id = c.car_id
         ORDER BY sort_order ASC
         LIMIT 1),
        '$placeholder'
      ) AS cover_image
    FROM bookings b
    JOIN users u ON b.customer_id = u.user_id
    JOIN cars c ON b.car_id = c.car_id
    WHERE 1=1
  ";

  $today = date('Y-m-d H:i:s');
  
  switch ($filter) {
    case 'UPCOMING':
      $sql .= " AND b.status = 'CONFIRMED' AND b.start_datetime > '$today'";
      break;
    case 'ACTIVE':
      $sql .= " AND b.status IN ('CONFIRMED', 'ACTIVE') 
                AND '$today' BETWEEN b.start_datetime AND b.end_datetime";
      break;
    case 'COMPLETED':
      $sql .= " AND b.status = 'COMPLETED'";
      break;
    case 'ALL':
    default:
      // Show all bookings
      break;
  }

  $sql .= " ORDER BY b.created_at DESC";

  $stmt = $pdo->prepare($sql);
  $stmt->execute();
  $bookings = $stmt->fetchAll(PDO::FETCH_ASSOC);

  echo json_encode([
    "ok" => true,
    "data" => $bookings
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
