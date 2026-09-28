<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$input = json_decode(file_get_contents('php://input'), true) ?? [];
$bookingId = (int)($input['booking_id'] ?? 0);

if ($bookingId <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "booking_id is required"]);
  exit;
}

try {
  $stmt = $pdo->prepare("UPDATE bookings SET status = 'CONFIRMED' WHERE booking_id = :id");
  $stmt->execute([':id' => $bookingId]);
  echo json_encode(["ok" => true, "message" => "Booking approved"]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
