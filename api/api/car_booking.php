<?php
require_once "db.php";

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$car_id = (int)($data["car_id"] ?? 0);
$customer_id = (int)($data["customer_id"] ?? 0);

$start_datetime = trim($data["start_datetime"] ?? "");
$end_datetime   = trim($data["end_datetime"] ?? "");

$pickup_address  = trim($data["pickup_address"] ?? "");
$dropoff_address = trim($data["dropoff_address"] ?? "");

$delivery_fee    = (float)($data["delivery_fee"] ?? 0);
$discount_amount = (float)($data["discount_amount"] ?? 0);
$addons_total    = (float)($data["addons_total"] ?? 0);

if ($car_id <= 0 || $customer_id <= 0 || $start_datetime === "" || $end_datetime === "" || $pickup_address === "" || $dropoff_address === "") {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing required fields"]);
  exit;
}

try {
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

  // Car exists + price
  $stmt = $pdo->prepare("SELECT daily_price, status FROM cars WHERE car_id = :id LIMIT 1");
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

  // Availability check (overlap) based on your columns
  $check = $pdo->prepare("
    SELECT COUNT(*)
    FROM bookings
    WHERE car_id = :car_id
      AND status IN ('PENDING','CONFIRMED','ACTIVE')
      AND (start_datetime < :end_dt AND end_datetime > :start_dt)
  ");
  $check->execute([
    ":car_id" => $car_id,
    ":start_dt" => $start_datetime,
    ":end_dt" => $end_datetime
  ]);

  if ((int)$check->fetchColumn() > 0) {
    echo json_encode(["ok" => false, "message" => "Car not available for selected time"]);
    exit;
  }

  // days_count
  $days_count = (int)ceil(($end_ts - $start_ts) / (60 * 60 * 24));
  if ($days_count < 1) $days_count = 1;

  // total
  $subtotal = $days_count * $daily_price;
  $total_price = $subtotal + $delivery_fee + $addons_total - $discount_amount;
  if ($total_price < 0) $total_price = 0;

  // Insert booking (matches your table)
  $ins = $pdo->prepare("
    INSERT INTO bookings
    (customer_id, car_id,
     pickup_location_id, dropoff_location_id,
     pickup_address, dropoff_address,
     start_datetime, end_datetime,
     days_count, daily_price_at_booking,
     delivery_fee, discount_amount, addons_total,
     total_price, status)
    VALUES
    (:customer_id, :car_id,
     NULL, NULL,
     :pickup_address, :dropoff_address,
     :start_dt, :end_dt,
     :days_count, :daily_price_at_booking,
     :delivery_fee, :discount_amount, :addons_total,
     :total_price, 'PENDING')
  ");

  $ins->execute([
    ":customer_id" => $customer_id,
    ":car_id" => $car_id,
    ":pickup_address" => $pickup_address,
    ":dropoff_address" => $dropoff_address,
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

  echo json_encode([
    "ok" => true,
    "message" => "Booking created successfully",
    "booking" => [
      "booking_id" => $booking_id,
      "status" => "PENDING",
      "days_count" => $days_count,
      "daily_price_at_booking" => $daily_price,
      "delivery_fee" => $delivery_fee,
      "discount_amount" => $discount_amount,
      "addons_total" => $addons_total,
      "total_price" => $total_price,
      "start_datetime" => $start_datetime,
      "end_datetime" => $end_datetime,
      "pickup_address" => $pickup_address,
      "dropoff_address" => $dropoff_address
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
