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

$car_id = (int)($data["car_id"] ?? 0);
$start  = trim($data["start_datetime"] ?? "");
$end    = trim($data["end_datetime"] ?? "");

if ($car_id <= 0 || $start === "" || $end === "") {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing car_id/start/end"]);
  exit;
}

try {
  // ✅ أي تداخل زمني = غير متاح
  // overlap if: start < existing_end AND end > existing_start
  $sql = "
    SELECT booking_id, start_datetime, end_datetime
    FROM bookings
    WHERE car_id = :cid
      AND status IN ('PENDING','CONFIRMED','ACTIVE')
      AND (:start < end_datetime AND :end > start_datetime)
    ORDER BY start_datetime ASC
    LIMIT 1
  ";

  $stmt = $pdo->prepare($sql);
  $stmt->execute([
    ":cid" => $car_id,
    ":start" => $start,
    ":end" => $end,
  ]);

  $conflict = $stmt->fetch(PDO::FETCH_ASSOC);

  if ($conflict) {
    echo json_encode([
      "ok" => true,
      "available" => false,
      "message" => "Car is booked in this period",
      "conflict" => $conflict
    ]);
    exit;
  }

  echo json_encode([
    "ok" => true,
    "available" => true
  ]);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
