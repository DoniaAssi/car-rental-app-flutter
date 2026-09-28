<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$status = strtoupper(trim($_GET['status'] ?? 'ALL'));

// Dynamic base URL
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$base = "$protocol://$host/api/uploads/cars/";
$placeholder = "$protocol://$host/api/uploads/cars/placeholder.jpg";

try {
  // First, check if required columns exist
  $checkColumns = $pdo->query("SHOW COLUMNS FROM bookings LIKE 'checkin_%'")->fetchAll();
  
  if (empty($checkColumns)) {
    throw new Exception("Database migration required. Please run: http://127.0.0.1/api/run_migration.php");
  }
  
  $sql = "
    SELECT 
      c.car_id,
      c.brand,
      c.model,
      c.model_year,
      c.status,
      c.plate_number,
      COALESCE(
        (SELECT CONCAT('$base', image_name)
         FROM car_images
         WHERE car_id = c.car_id
         ORDER BY sort_order ASC
         LIMIT 1),
        '$placeholder'
      ) AS cover_image,
      b.booking_id,
      u.full_name AS customer_name,
      b.start_datetime,
      b.end_datetime,
      COALESCE(b.checkin_odometer, 0) AS checkin_odometer,
      COALESCE(b.checkout_odometer, 0) AS checkout_odometer,
      DATE(b.checkin_datetime) AS checkin_date,
      DATE(b.checkout_datetime) AS checkout_date
    FROM cars c
    LEFT JOIN bookings b ON c.car_id = b.car_id 
      AND b.status IN ('CONFIRMED', 'ACTIVE')
      AND NOW() BETWEEN b.start_datetime AND b.end_datetime
    LEFT JOIN users u ON b.customer_id = u.user_id
    WHERE 1=1
  ";

  if ($status !== 'ALL') {
    if ($status === 'RENTED') {
      $sql .= " AND c.status = 'AVAILABLE' AND b.booking_id IS NOT NULL";
    } else {
      $sql .= " AND c.status = :status";
    }
  }

  $sql .= " ORDER BY c.car_id DESC";

  $stmt = $pdo->prepare($sql);
  if ($status !== 'ALL' && $status !== 'RENTED') {
    $stmt->execute([":status" => $status]);
  } else {
    $stmt->execute();
  }
  
  $cars = $stmt->fetchAll(PDO::FETCH_ASSOC);

  echo json_encode([
    "ok" => true,
    "data" => $cars,
    "count" => count($cars),
    "status_filter" => $status
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  
  // Provide helpful error message
  $errorMsg = $e->getMessage();
  $helpfulMsg = "Server error";
  
  if (strpos($errorMsg, "Unknown column") !== false || strpos($errorMsg, "checkin") !== false) {
    $helpfulMsg = "Database migration required. Open http://127.0.0.1/api/run_migration.php in your browser to fix this.";
  }
  
  echo json_encode([
    "ok" => false, 
    "message" => $helpfulMsg,
    "error_details" => $errorMsg,
    "fix_url" => "http://127.0.0.1/api/run_migration.php"
  ]);
}
