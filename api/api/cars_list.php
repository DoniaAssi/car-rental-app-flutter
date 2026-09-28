<?php
require_once "db.php";

header("Content-Type: application/json; charset=UTF-8");

$type = trim($_GET['type'] ?? '');
$q    = trim($_GET['q'] ?? '');
$minP = trim($_GET['minPrice'] ?? '');
$maxP = trim($_GET['maxPrice'] ?? '');

// ✅ Build base URL dynamically (works for 127.0.0.1 in browser + 10.0.2.2 in emulator + real domain in production)
$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https" : "http";
$host = $_SERVER['HTTP_HOST']; // e.g. 127.0.0.1 or 10.0.2.2
$base = "$scheme://$host/api/uploads/cars/";

// ✅ Default placeholder image (must exist)
$placeholder = $base . "placeholder.jpg";

$sql = "
SELECT
  c.car_id, c.brand, c.model, c.model_year, c.type,
  c.seats, c.transmission, c.fuel_type, c.daily_price,

  -- ✅ status calculated based on current bookings
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.car_id = c.car_id
        AND b.status IN ('CONFIRMED','ACTIVE')
        AND NOW() BETWEEN b.start_datetime AND b.end_datetime
    ) THEN 'BOOKED'
    ELSE 'AVAILABLE'
  END AS status,

  COALESCE(
    (SELECT CONCAT('$base', image_name)
     FROM car_images
     WHERE car_id = c.car_id
     ORDER BY sort_order ASC
     LIMIT 1),
    '$placeholder'
  ) AS cover_url

FROM cars c
WHERE 1=1
";

$params = [];

// ✅ Filter by type
if ($type !== '' && $type !== 'ALL') {
  $sql .= " AND c.type = :type";
  $params[':type'] = $type;
}

// ✅ Search by brand/model
if ($q !== '') {
  $sql .= " AND (c.brand LIKE :q OR c.model LIKE :q)";
  $params[':q'] = "%$q%";
}

// ✅ Filter by price
if ($minP !== '' && is_numeric($minP)) {
  $sql .= " AND c.daily_price >= :minP";
  $params[':minP'] = (float)$minP;
}

if ($maxP !== '' && is_numeric($maxP)) {
  $sql .= " AND c.daily_price <= :maxP";
  $params[':maxP'] = (float)$maxP;
}

// ✅ Sort
$sql .= " ORDER BY c.daily_price ASC";

try {
  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);

  echo json_encode(["ok" => true, "data" => $stmt->fetchAll()]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    "ok" => false,
    "message" => "Server error",
    "debug" => $e->getMessage()
  ]);
}
