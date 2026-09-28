<?php
require_once "db.php";

header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

function safe($v) {
  return trim((string)$v);
}

$booking_id    = (int)($_POST["booking_id"] ?? 0);
$customer_id   = (int)($_POST["customer_id"] ?? 0);
$accident_time = safe($_POST["accident_time"] ?? "");
$location_text = safe($_POST["location_text"] ?? "");
$description   = safe($_POST["description"] ?? "");

// required
if ($booking_id <= 0 || $customer_id <= 0 || $accident_time === "" || $description === "") {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing required fields"]);
  exit;
}

try {
  // ✅ verify booking belongs to customer
  $st = $pdo->prepare("SELECT booking_id, car_id, customer_id, status FROM bookings WHERE booking_id=:bid LIMIT 1");
  $st->execute([":bid" => $booking_id]);
  $b = $st->fetch(PDO::FETCH_ASSOC);

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

  $car_id = (int)$b["car_id"];

  // ✅ parse accident_time (accepts: 2026-01-17 14:30:00 OR ISO)
  $dt = date_create($accident_time);
  if (!$dt) {
    http_response_code(400);
    echo json_encode(["ok" => false, "message" => "Invalid accident_time"]);
    exit;
  }
  $accident_time_db = $dt->format("Y-m-d H:i:s");

  $pdo->beginTransaction();

  // ✅ insert accident
  $ins = $pdo->prepare("
    INSERT INTO accidents (booking_id, car_id, customer_id, accident_time, location_text, description, status)
    VALUES (:bid, :cid, :uid, :tm, :loc, :des, 'REPORTED')
  ");
  $ins->execute([
    ":bid" => $booking_id,
    ":cid" => $car_id,
    ":uid" => $customer_id,
    ":tm"  => $accident_time_db,
    ":loc" => $location_text !== "" ? $location_text : null,
    ":des" => $description,
  ]);

  $accident_id = (int)$pdo->lastInsertId();

  // ✅ upload images (optional)
  $saved = [];
  if (!empty($_FILES["images"]) && isset($_FILES["images"]["name"]) && is_array($_FILES["images"]["name"])) {

    $uploadDir = __DIR__ . "/uploads/accidents/";
    if (!is_dir($uploadDir)) {
      @mkdir($uploadDir, 0777, true);
    }

    $count = count($_FILES["images"]["name"]);
    for ($i = 0; $i < $count; $i++) {
      if ($_FILES["images"]["error"][$i] !== UPLOAD_ERR_OK) continue;

      $tmp  = $_FILES["images"]["tmp_name"][$i];
      $name = $_FILES["images"]["name"][$i];

      $ext = strtolower(pathinfo($name, PATHINFO_EXTENSION));
      if (!in_array($ext, ["jpg", "jpeg", "png", "webp"])) continue;

      $newName = "accident_" . $accident_id . "_" . ($i+1) . "." . $ext;
      $dest = $uploadDir . $newName;

      if (move_uploaded_file($tmp, $dest)) {
        $pdo->prepare("INSERT INTO accident_images (accident_id, image_name) VALUES (:aid, :img)")
            ->execute([":aid" => $accident_id, ":img" => $newName]);
        $saved[] = $newName;
      }
    }
  }

  // ✅ (OPTIONAL) change booking status
  // ⚠️ شغّلها فقط إذا نظامك بيسمح بالحالة INCIDENT_REPORTED
  $CHANGE_BOOKING_STATUS = false;
  if ($CHANGE_BOOKING_STATUS) {
    $pdo->prepare("UPDATE bookings SET status='INCIDENT_REPORTED' WHERE booking_id=:bid")
        ->execute([":bid" => $booking_id]);
  }

  $pdo->commit();

  echo json_encode([
    "ok" => true,
    "message" => "Accident reported successfully ✅",
    "accident" => [
      "accident_id" => $accident_id,
      "booking_id" => $booking_id,
      "car_id" => $car_id,
      "customer_id" => $customer_id,
      "accident_time" => $accident_time_db,
      "location_text" => $location_text,
      "description" => $description,
      "status" => "REPORTED",
      "images" => $saved
    ]
  ]);

} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
