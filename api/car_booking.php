<?php
require_once "db.php";

header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$data = json_decode(file_get_contents("php://input"), true);

// =====================
// Required IDs
// =====================
$car_id      = (int)($data["car_id"] ?? 0);
$customer_id = (int)($data["customer_id"] ?? 0);

// =====================
// Dates
// =====================
$start_datetime = trim($data["start_datetime"] ?? "");
$end_datetime   = trim($data["end_datetime"] ?? "");

// =====================
// Addresses (text)
// =====================
$pickup_address  = trim($data["pickup_address"] ?? "");
$dropoff_address = trim($data["dropoff_address"] ?? "");

// =====================
// Map coordinates ✅ NEW
// =====================
$pickup_lat  = isset($data["pickup_lat"])  ? (float)$data["pickup_lat"]  : null;
$pickup_lng  = isset($data["pickup_lng"])  ? (float)$data["pickup_lng"]  : null;
$dropoff_lat = isset($data["dropoff_lat"]) ? (float)$data["dropoff_lat"] : null;
$dropoff_lng = isset($data["dropoff_lng"]) ? (float)$data["dropoff_lng"] : null;

// =====================
// Pricing extras
// =====================
$delivery_fee    = (float)($data["delivery_fee"] ?? 0);
$discount_amount = (float)($data["discount_amount"] ?? 0);
$addons_total    = (float)($data["addons_total"] ?? 0);

// =====================
// Validation
// =====================
if (
  $car_id <= 0 ||
  $customer_id <= 0 ||
  $start_datetime === "" ||
  $end_datetime === "" ||
  $pickup_address === "" ||
  $dropoff_address === ""
) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing required fields"]);
  exit;
}

try {
  // =====================
  // Date validation
  // =====================
  $start_ts = strtotime($start_datetime);
  $end_ts   = strtotime($end_datetime);

  if ($start_ts === false || $end_ts === false) {
    http_response_code(400);
    echo json_encode(["ok" => false, "message" => "Invalid date format"]);
    exit;
  }

  if ($end_ts <= $start_ts) {
    http_response_code(400);
    echo json_encode(["ok" => false, "message" => "End must be after start"]);
    exit;
  }

  // =====================
  // Get car price & status
  // =====================
  $stmt = $pdo->prepare("
    SELECT daily_price, status
    FROM cars
    WHERE car_id = :id
    LIMIT 1
  ");
  $stmt->execute([":id" => $car_id]);
  $car = $stmt->fetch();

  if (!$car) {
    http_response_code(404);
    echo json_encode(["ok" => false, "message" => "Car not found"]);
    exit;
  }

  if ($car["status"] !== "AVAILABLE") {
    echo json_encode(["ok" => false, "message" => "Car is not available"]);
    exit;
  }

  $daily_price = (float)$car["daily_price"];

  // =====================
  // Availability check
  // =====================
  $check = $pdo->prepare("
    SELECT COUNT(*)
    FROM bookings
    WHERE car_id = :car_id
      AND status IN ('PENDING','CONFIRMED','ACTIVE')
      AND (start_datetime < :end_dt AND end_datetime > :start_dt)
  ");

  $check->execute([
    ":car_id"  => $car_id,
    ":start_dt" => $start_datetime,
    ":end_dt"   => $end_datetime
  ]);

  if ((int)$check->fetchColumn() > 0) {
    echo json_encode(["ok" => false, "message" => "Car not available for selected time"]);
    exit;
  }

  // =====================
  // Calculate days & price
  // =====================
  $days_count = (int)ceil(($end_ts - $start_ts) / (60 * 60 * 24));
  if ($days_count < 1) $days_count = 1;

  $subtotal = $days_count * $daily_price;
  $total_price = $subtotal + $delivery_fee + $addons_total - $discount_amount;
  if ($total_price < 0) $total_price = 0;

  // =====================
  // Insert booking ✅ UPDATED
  // =====================
  $ins = $pdo->prepare("
    INSERT INTO bookings (
      customer_id, car_id,
      pickup_address, pickup_lat, pickup_lng,
      dropoff_address, dropoff_lat, dropoff_lng,
      start_datetime, end_datetime,
      days_count, daily_price_at_booking,
      delivery_fee, discount_amount, addons_total,
      total_price, status
    ) VALUES (
      :customer_id, :car_id,
      :pickup_address, :pickup_lat, :pickup_lng,
      :dropoff_address, :dropoff_lat, :dropoff_lng,
      :start_dt, :end_dt,
      :days_count, :daily_price_at_booking,
      :delivery_fee, :discount_amount, :addons_total,
      :total_price, 'PENDING'
    )
  ");

  $ins->execute([
    ":customer_id" => $customer_id,
    ":car_id" => $car_id,

    ":pickup_address" => $pickup_address,
    ":pickup_lat" => $pickup_lat,
    ":pickup_lng" => $pickup_lng,

    ":dropoff_address" => $dropoff_address,
    ":dropoff_lat" => $dropoff_lat,
    ":dropoff_lng" => $dropoff_lng,

    ":start_dt" => $start_datetime,
    ":end_dt" => $end_datetime,

    ":days_count" => $days_count,
    ":daily_price_at_booking" => $daily_price,
    ":delivery_fee" => $delivery_fee,
    ":discount_amount" => $discount_amount,
    ":addons_total" => $addons_total,
    ":total_price" => $total_price
  ]);

  $booking_id = (int)$pdo->lastInsertId();

  // =====================
  // Success response
  // =====================
  echo json_encode([
    "ok" => true,
    "message" => "Booking created successfully",
    "booking" => [
      "booking_id" => $booking_id,
      "status" => "PENDING",
      "total_price" => $total_price,
      "pickup_address" => $pickup_address,
      "pickup_lat" => $pickup_lat,
      "pickup_lng" => $pickup_lng,
      "dropoff_address" => $dropoff_address,
      "dropoff_lat" => $dropoff_lat,
      "dropoff_lng" => $dropoff_lng
    ]
  ]);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    "ok" => false,
    "message" => "Server error",
    "debug" => $e->getMessage()
  ]);
}
