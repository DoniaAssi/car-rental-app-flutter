<?php
require_once "db.php";

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid car id"]);
  exit;
}

// ✅ Build base URL dynamically (works for 127.0.0.1 in browser + 10.0.2.2 in emulator + real domain in production)
$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https" : "http";
$host = $_SERVER['HTTP_HOST']; // e.g. 127.0.0.1 or 10.0.2.2
$base = "$scheme://$host/api/uploads/cars/";

// ✅ Default placeholder image (must exist)
$placeholder = $base . "placeholder.jpg";


$stmt = $pdo->prepare("
  SELECT car_id, plate_number, brand, model, model_year, type, seats,
         transmission, fuel_type, daily_price, status, description
  FROM cars
  WHERE car_id = :id
  LIMIT 1
");
$stmt->execute([":id" => $id]);
$car = $stmt->fetch();

if (!$car) {
  http_response_code(404);
  echo json_encode(["ok" => false, "message" => "Car not found"]);
  exit;
}

$img = $pdo->prepare("
  SELECT CONCAT('$base', image_name) AS url
  FROM car_images
  WHERE car_id = :id
  ORDER BY sort_order ASC
");
$img->execute([":id" => $id]);
$images = $img->fetchAll();

if (!$images || count($images) == 0) {
  $images = [["url" => $placeholder]];
}

echo json_encode([
  "ok" => true,
  "car" => $car,
  "images" => $images
]);
