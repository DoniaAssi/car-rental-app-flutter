<?php
require_once "db.php";

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$booking_id = (int)($data["booking_id"] ?? 0);
$amount     = (float)($data["amount"] ?? 0);

// ✅ طرق دفع متعددة
$method = trim($data["method"] ?? "MOCK_CARD");
$allowed = ["MOCK_CARD", "MOCK_PAYPAL", "CASH"];
if (!in_array($method, $allowed)) $method = "MOCK_CARD";

// ✅ الحالة في payments
$status = "SUCCESS";

if ($booking_id <= 0 || $amount <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing booking_id or amount"]);
  exit;
}

try {
  // ✅ تأكد الحجز موجود و Pending + طابق المبلغ مع total_price
  $stmt = $pdo->prepare("SELECT booking_id, status, total_price FROM bookings WHERE booking_id = :bid LIMIT 1");
  $stmt->execute([":bid" => $booking_id]);
  $b = $stmt->fetch();

  if (!$b) {
    http_response_code(404);
    echo json_encode(["ok" => false, "message" => "Booking not found"]);
    exit;
  }

  // ✅ بنسمح بس لو PENDING
  if ($b["status"] !== "PENDING") {
    echo json_encode(["ok" => false, "message" => "Booking is not pending"]);
    exit;
  }

  $total = (float)$b["total_price"];
  if (abs($amount - $total) > 0.01) {
    echo json_encode(["ok" => false, "message" => "Amount must equal total price"]);
    exit;
  }

  // ✅ لو CASH: نخلي booking status مختلف عشان يتأكد لاحقاً
  $newBookingStatus = ($method === "CASH") ? "PENDING_CASH" : "CONFIRMED";

  $pdo->beginTransaction();

  // ✅ transaction_ref مثل جدولك
  $ref = "MOCK-TXN-" . random_int(10000, 99999);

  // ✅ insert مطابق للأعمدة عندك
  $ins = $pdo->prepare("
    INSERT INTO payments (booking_id, amount, method, status, transaction_ref, paid_at)
    VALUES (:bid, :amt, :mth, :st, :ref, NOW())
  ");
  $ins->execute([
    ":bid" => $booking_id,
    ":amt" => $amount,
    ":mth" => $method,
    ":st"  => $status,
    ":ref" => $ref
  ]);

  $payment_id = (int)$pdo->lastInsertId();

  // ✅ Update booking status حسب الطريقة
  $up = $pdo->prepare("UPDATE bookings SET status = :st WHERE booking_id = :bid");
  $up->execute([
    ":st" => $newBookingStatus,
    ":bid" => $booking_id
  ]);

  $pdo->commit();

  $msg = ($method === "CASH")
    ? "Cash selected ✅ Waiting for confirmation"
    : "Payment SUCCESS ✅ Booking confirmed";

  echo json_encode([
    "ok" => true,
    "message" => $msg,
    "booking" => [
      "booking_id" => $booking_id,
      "new_status" => $newBookingStatus
    ],
    "payment" => [
      "payment_id" => $payment_id,
      "booking_id" => $booking_id,
      "amount" => $amount,
      "method" => $method,
      "status" => $status,
      "transaction_ref" => $ref
    ]
  ]);

} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  http_response_code(500);
  echo json_encode([
    "ok" => false,
    "message" => "Server error",
    "debug" => $e->getMessage()
  ]);
}
