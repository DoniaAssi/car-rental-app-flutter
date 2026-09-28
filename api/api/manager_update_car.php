<?php
header('Content-Type: application/json; charset=utf-8');
require_once "db.php";

try {
  $raw = file_get_contents("php://input");
  $body = json_decode($raw, true);

  $need = function($k) use ($body) {
    if (!isset($body[$k])) {
      echo json_encode(["ok" => false, "message" => "Missing field: $k"]);
      exit;
    }
    return $body[$k];
  };

  $car_id         = intval($need("car_id"));
  $plate_number   = trim((string)$need("plate_number"));
  $brand          = trim((string)$need("brand"));
  $model          = trim((string)$need("model"));
  $model_year     = intval($need("model_year"));
  $type           = trim((string)$need("type"));
  $seats          = intval($need("seats"));
  $transmission   = trim((string)$need("transmission"));
  $fuel_type      = trim((string)$need("fuel_type"));
  $daily_price    = floatval($need("daily_price"));
  $deposit_amount = floatval($need("deposit_amount"));
  $status         = trim((string)$need("status"));
  $mileage_km     = intval($need("mileage_km"));
  $color          = trim((string)$need("color"));
  $description    = trim((string)$need("description"));

  if ($car_id <= 0) {
    echo json_encode(["ok" => false, "message" => "Invalid car_id"]);
    exit;
  }

  $sql = "
    UPDATE cars SET
      plate_number   = :plate_number,
      brand          = :brand,
      model          = :model,
      model_year     = :model_year,
      type           = :type,
      seats          = :seats,
      transmission   = :transmission,
      fuel_type      = :fuel_type,
      daily_price    = :daily_price,
      deposit_amount = :deposit_amount,
      status         = :status,
      mileage_km     = :mileage_km,
      color          = :color,
      description    = :description,
      updated_at     = NOW()
    WHERE car_id = :car_id AND deleted_at IS NULL
  ";

  $stmt = $pdo->prepare($sql);
  $stmt->execute([
    ":plate_number"   => $plate_number,
    ":brand"          => $brand,
    ":model"          => $model,
    ":model_year"     => $model_year,
    ":type"           => $type,
    ":seats"          => $seats,
    ":transmission"   => $transmission,
    ":fuel_type"      => $fuel_type,
    ":daily_price"    => $daily_price,
    ":deposit_amount" => $deposit_amount,
    ":status"         => $status,
    ":mileage_km"     => $mileage_km,
    ":color"          => $color,
    ":description"    => $description,
    ":car_id"         => $car_id,
  ]);

  if ($stmt->rowCount() <= 0) {
    echo json_encode(["ok" => false, "message" => "Car not found / deleted or no changes"]);
    exit;
  }

  echo json_encode(["ok" => true, "message" => "Updated successfully"]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    "ok" => false,
    "message" => "Server error",
    "debug" => $e->getMessage()
  ]);
}
