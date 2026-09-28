<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$bookingId = (int)($_GET['id'] ?? 0);

if ($bookingId <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid booking ID"]);
  exit;
}

$base = "http://127.0.0.1/car_rental_api/uploads/cars/";
$placeholder = "http://127.0.0.1/car_rental_api/uploads/cars/placeholder.jpg";

try {
  $stmt = $pdo->prepare("
    SELECT 
      b.booking_id,
      b.customer_id,
      u.full_name AS customer_name,
      u.email AS customer_email,
      u.phone AS customer_phone,
      b.car_id,
      c.brand,
      c.model,
      c.type,
      c.model_year,
      b.start_datetime,
      b.end_datetime,
      b.days_count,
      b.total_price,
      b.status,
      b.pickup_address,
      b.dropoff_address,
      b.notes,
      b.created_at,
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
    WHERE b.booking_id = :id
  ");
  
  $stmt->execute([":id" => $bookingId]);
  $booking = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$booking) {
    http_response_code(404);
    echo json_encode(["ok" => false, "message" => "Booking not found"]);
    exit;
  }

  echo json_encode([
    "ok" => true,
    "data" => $booking
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
