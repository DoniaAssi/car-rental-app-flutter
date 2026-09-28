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

$booking_id  = (int)($data["booking_id"] ?? 0);
$customer_id = (int)($data["customer_id"] ?? 0);
$reason      = trim($data["reason"] ?? "Cancelled by customer");

if ($booking_id <= 0 || $customer_id <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing booking_id or customer_id"]);
  exit;
}

try {
  // 1) تأكد الحجز موجود + تبع نفس العميل
  $stmt = $pdo->prepare("
    SELECT booking_id, customer_id, status
    FROM bookings
    WHERE booking_id = :bid
    LIMIT 1
  ");
  $stmt->execute([":bid" => $booking_id]);
  $b = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$b) {
    http_response_code(404);
    echo json_encode(["ok" => false, "message" => "Booking not found"]);
    exit;
  }

  if ((int)$b["customer_id"] !== $customer_id) {
    http_response_code(403);
    echo json_encode(["ok" => false, "message" => "Not allowed"]);
    exit;
  }

  $status = strtoupper((string)$b["status"]);

  // 2) فقط PENDING أو CONFIRMED مسموح إلغاء
  if (!in_array($status, ["PENDING", "CONFIRMED"], true)) {
    echo json_encode([
      "ok" => false,
      "message" => "Booking cannot be cancelled in status: $status"
    ]);
    exit;
  }

  $pdo->beginTransaction();

  // 3) تحديث حالة الحجز
  // (لو عندك عمود cancel_reason / cancelled_at ضيفهم هون. إذا مش موجودين، خليها بسيطة)
  $up = $pdo->prepare("
    UPDATE bookings
    SET status = 'CANCELLED'
    WHERE booking_id = :bid
  ");
  $up->execute([":bid" => $booking_id]);

  $pdo->commit();

  echo json_encode([
    "ok" => true,
    "message" => "Booking cancelled ✅",
    "booking_id" => $booking_id,
    "status" => "CANCELLED",
    "reason" => $reason
  ]);

} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
