<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

// ✅ Debug مؤقت (خليه true بس وقت التطوير)
$APP_DEBUG = true;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

function fail($code, $msg, $extra = null) {
  http_response_code($code);
  $res = ["ok" => false, "message" => $msg];
  if ($extra !== null) $res["extra"] = $extra;
  echo json_encode($res);
  exit;
}

try {
  // ✅ حقول السيارة (من multipart/form-data)
  $plate_number   = trim($_POST["plate_number"] ?? "");
  $brand          = trim($_POST["brand"] ?? "");
  $model          = trim($_POST["model"] ?? "");
  $model_year     = (int)($_POST["model_year"] ?? 0);
  $type           = strtoupper(trim($_POST["type"] ?? ""));
  $seats          = (int)($_POST["seats"] ?? 0);
  $transmission   = strtoupper(trim($_POST["transmission"] ?? ""));
  $fuel_type      = strtoupper(trim($_POST["fuel_type"] ?? ""));
  $daily_price    = (float)($_POST["daily_price"] ?? 0);
  $deposit_amount = (float)($_POST["deposit_amount"] ?? 0);
  $status         = strtoupper(trim($_POST["status"] ?? "AVAILABLE"));
  $mileage_km     = (int)($_POST["mileage_km"] ?? 0);
  $color          = trim($_POST["color"] ?? "");
  $description    = trim($_POST["description"] ?? "");
  $created_by     = (int)($_POST["created_by"] ?? 0);

  if ($plate_number === "" || $brand === "" || $model === "" || $model_year <= 0 || $daily_price <= 0 || $created_by <= 0) {
    fail(400, "Missing required fields (plate_number, brand, model, model_year, daily_price, created_by)");
  }

  // ✅ تحقق من الصور
  if (!isset($_FILES["images"])) {
    fail(400, "images field is required (multi images)");
  }

  // ✅ تجهيز مجلد الرفع
  $uploadDir = __DIR__ . "/uploads/cars/";
  if (!is_dir($uploadDir)) {
    if (!mkdir($uploadDir, 0777, true)) {
      fail(500, "Failed to create upload directory");
    }
  }

  // ✅ معالجة ملفات متعددة
  $names = $_FILES["images"]["name"];
  $tmp   = $_FILES["images"]["tmp_name"];
  $errs  = $_FILES["images"]["error"];

  if (!is_array($names) || count($names) === 0) {
    fail(400, "No images uploaded");
  }

  $pdo->beginTransaction();

  // ✅ Insert car
  $stmt = $pdo->prepare("
    INSERT INTO cars
    (plate_number, brand, model, model_year, type, seats, transmission, fuel_type,
     daily_price, deposit_amount, status, mileage_km, color, description, created_by, created_at)
    VALUES
    (:plate_number, :brand, :model, :model_year, :type, :seats, :transmission, :fuel_type,
     :daily_price, :deposit_amount, :status, :mileage_km, :color, :description, :created_by, NOW())
  ");

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
    ":created_by"     => $created_by,
  ]);

  $carId = (int)$pdo->lastInsertId();

  // ✅ Insert images
  $imgStmt = $pdo->prepare("
    INSERT INTO car_images (car_id, image_name, is_cover, created_at)
    VALUES (:car_id, :image_name, :is_cover, NOW())
  ");

  $saved = [];
  for ($i = 0; $i < count($names); $i++) {
    if ((int)$errs[$i] !== UPLOAD_ERR_OK) continue;

    $original = $names[$i];
    $ext = strtolower(pathinfo($original, PATHINFO_EXTENSION));
    if (!in_array($ext, ["jpg","jpeg","png","webp"])) {
      continue; // تجاهل أي ملف غريب
    }

    $newName = "car_" . $carId . "_" . uniqid() . "." . $ext;
    $dest = $uploadDir . $newName;

    if (!move_uploaded_file($tmp[$i], $dest)) {
      throw new Exception("Failed to move uploaded file: " . $original);
    }

    $isCover = ($i === 0) ? 1 : 0; // أول صورة cover
    $imgStmt->execute([
      ":car_id" => $carId,
      ":image_name" => $newName,
      ":is_cover" => $isCover
    ]);

    $saved[] = $newName;
  }

  if (count($saved) === 0) {
    throw new Exception("No valid images were saved");
  }

  $pdo->commit();

  echo json_encode([
    "ok" => true,
    "message" => "Car added successfully",
    "car_id" => $carId,
    "images" => $saved
  ]);

} catch (Throwable $e) {
  if ($pdo && $pdo->inTransaction()) $pdo->rollBack();

  if ($APP_DEBUG) {
    fail(500, "Server error: " . $e->getMessage());
  }
  fail(500, "Server error");
}
