<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

// Accept multipart or JSON
$fields = $_POST;
if (empty($fields)) {
  $json = json_decode(file_get_contents('php://input'), true) ?? [];
  $fields = $json;
}

$plate = trim($fields['plate_number'] ?? '');
$brand = trim($fields['brand'] ?? '');
$model = trim($fields['model'] ?? '');
$modelYear = (int)($fields['model_year'] ?? 0);
$type = strtoupper(trim($fields['type'] ?? 'SEDAN'));
$seats = (int)($fields['seats'] ?? 5);
$transmission = strtoupper(trim($fields['transmission'] ?? 'AUTO'));
$fuel = strtoupper(trim($fields['fuel_type'] ?? 'GAS'));
$daily = (float)($fields['daily_price'] ?? 0);
$deposit = (float)($fields['deposit_amount'] ?? 0);
$status = strtoupper(trim($fields['status'] ?? 'AVAILABLE'));
$mileage = (int)($fields['mileage_km'] ?? 0);
$color = trim($fields['color'] ?? '');
$desc = trim($fields['description'] ?? '');

if ($plate === '' || $brand === '' || $model === '' || $modelYear <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Required: plate_number, brand, model, model_year"]);
  exit;
}

try {
  $stmt = $pdo->prepare("INSERT INTO cars (plate_number, brand, model, model_year, type, seats, transmission, fuel_type, daily_price, deposit_amount, status, mileage_km, color, description, created_by) 
    VALUES (:plate, :brand, :model, :year, :type, :seats, :trans, :fuel, :daily, :deposit, :status, :mileage, :color, :desc, NULL)");
  $stmt->execute([
    ':plate' => $plate,
    ':brand' => $brand,
    ':model' => $model,
    ':year' => $modelYear,
    ':type' => $type,
    ':seats' => $seats,
    ':trans' => $transmission,
    ':fuel' => $fuel,
    ':daily' => $daily,
    ':deposit' => $deposit,
    ':status' => $status,
    ':mileage' => $mileage,
    ':color' => $color,
    ':desc' => $desc,
  ]);

  $carId = (int)$pdo->lastInsertId();

  echo json_encode(["ok" => true, "message" => "Car added", "car_id" => $carId]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
