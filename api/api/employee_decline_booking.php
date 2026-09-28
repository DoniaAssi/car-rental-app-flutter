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
$reason = trim($data['reason'] ?? 'Declined by employee');

if ($bookingId <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid booking ID"]);
  exit;
}

try {
  // Check if booking exists and is pending
  $stmt = $pdo->prepare("SELECT status FROM bookings WHERE booking_id = :id");
  $stmt->execute([":id" => $bookingId]);
  $booking = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$booking) {
    http_response_code(404);
    echo json_encode(["ok" => false, "message" => "Booking not found"]);
    exit;
  }

  if ($booking['status'] !== 'PENDING') {
    http_response_code(400);
    echo json_encode(["ok" => false, "message" => "Booking is not pending"]);
    exit;
  }

  // Update booking status to REJECTED
  $updateStmt = $pdo->prepare("
    UPDATE bookings 
    SET status = 'REJECTED', notes = :reason, updated_at = NOW()
    WHERE booking_id = :id
  ");
  $updateStmt->execute([
    ":id" => $bookingId,
    ":reason" => $reason
  ]);

  // Log status change
  $historyStmt = $pdo->prepare("
    INSERT INTO booking_status_history (booking_id, old_status, new_status, comment)
    VALUES (:id, 'PENDING', 'REJECTED', :reason)
  ");
  $historyStmt->execute([
    ":id" => $bookingId,
    ":reason" => $reason
  ]);

  echo json_encode([
    "ok" => true,
    "message" => "Booking declined successfully"
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
