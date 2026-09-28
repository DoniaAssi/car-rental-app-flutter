<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$bookingId = (int)($data['booking_id'] ?? 0);
$odometerKm = (int)($data['odometer_km'] ?? 0);
$notes = trim($data['notes'] ?? '');

if ($bookingId <= 0 || $odometerKm <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid booking ID or odometer reading"]);
  exit;
}

try {
  // Check if booking exists
  $stmt = $pdo->prepare("SELECT car_id, status FROM bookings WHERE booking_id = :id");
  $stmt->execute([":id" => $bookingId]);
  $booking = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$booking) {
    http_response_code(404);
    echo json_encode(["ok" => false, "message" => "Booking not found"]);
    exit;
  }

  // Add columns if they don't exist (for compatibility)
  try {
    $pdo->exec("ALTER TABLE bookings ADD COLUMN checkin_datetime DATETIME DEFAULT NULL");
  } catch (PDOException $e) {
    // Column might already exist, ignore
  }
  try {
    $pdo->exec("ALTER TABLE bookings ADD COLUMN checkin_odometer INT DEFAULT NULL");
  } catch (PDOException $e) {}
  try {
    $pdo->exec("ALTER TABLE bookings ADD COLUMN checkin_notes TEXT DEFAULT NULL");
  } catch (PDOException $e) {}

  // Update booking with check-in info
  $updateStmt = $pdo->prepare("
    UPDATE bookings 
    SET 
      checkin_datetime = NOW(),
      checkin_odometer = :odometer,
      checkin_notes = :notes,
      status = 'ACTIVE',
      updated_at = NOW()
    WHERE booking_id = :id
  ");
  $updateStmt->execute([
    ":id" => $bookingId,
    ":odometer" => $odometerKm,
    ":notes" => $notes
  ]);

  // Update car status to RENTED
  $carStmt = $pdo->prepare("UPDATE cars SET status = 'RENTED' WHERE car_id = :car_id");
  $carStmt->execute([":car_id" => $booking['car_id']]);

  echo json_encode([
    "ok" => true,
    "message" => "Car checked in successfully"
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
