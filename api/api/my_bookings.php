<?php
require_once "db.php";

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$customer_id = (int)($_GET["customer_id"] ?? 0);

if ($customer_id <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing customer_id"]);
  exit;
}

try {
  // ✅ جلب حجوزات العميل + معلومات السيارة
  $stmt = $pdo->prepare("
    SELECT
      b.booking_id,
      b.car_id,
      b.customer_id,
      b.start_datetime,
      b.end_datetime,
      b.days_count,
      b.daily_price_at_booking,
      b.delivery_fee,
      b.discount_amount,
      b.addons_total,
      b.total_price,
      b.status,
      b.pickup_address,
      b.dropoff_address,
      b.created_at,

      c.brand,
      c.model,
      c.model_year,
      c.type,
      c.transmission,
      c.fuel_type,
      c.seats
    FROM bookings b
    JOIN cars c ON c.car_id = b.car_id
    WHERE b.customer_id = :cid
    ORDER BY b.created_at DESC
  ");
  $stmt->execute([":cid" => $customer_id]);
  $rows = $stmt->fetchAll();

  // ✅ Optional: نجيب أول صورة لكل سيارة (لو عندك جدول car_images)
  // إذا ما عندك car_images، احذف هالجزء ببساطة.
  $carIds = array_values(array_unique(array_map(fn($r) => (int)$r["car_id"], $rows)));
  $firstImages = [];

  if (count($carIds) > 0) {
    $in = implode(",", array_fill(0, count($carIds), "?"));
    $imgStmt = $pdo->prepare("
      SELECT car_id, MIN(image_id) as min_id
      FROM car_images
      WHERE car_id IN ($in)
      GROUP BY car_id
    ");
    $imgStmt->execute($carIds);
    $mins = $imgStmt->fetchAll();

    if ($mins) {
      // هات اسم الصورة حسب min image_id
      $pairs = [];
      foreach ($mins as $m) {
        $pairs[] = " (car_id = " . (int)$m["car_id"] . " AND image_id = " . (int)$m["min_id"] . ") ";
      }
      $where = implode(" OR ", $pairs);

      $img2 = $pdo->query("
        SELECT car_id, image_name
        FROM car_images
        WHERE $where
      ")->fetchAll();

      foreach ($img2 as $i) {
        $firstImages[(int)$i["car_id"]] = $i["image_name"];
      }
    }
  }

  // ضيف cover_image لكل row
  $data = [];
  foreach ($rows as $r) {
    $carId = (int)$r["car_id"];
    $r["cover_image"] = $firstImages[$carId] ?? null;
    $data[] = $r;
  }

  echo json_encode(["ok" => true, "data" => $data]);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
