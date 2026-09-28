<?php
header('Content-Type: application/json; charset=utf-8');
require_once "db.php";

try {
  $raw = file_get_contents("php://input");
  $body = json_decode($raw, true);

  $car_id = isset($body["car_id"]) ? intval($body["car_id"]) : 0;
  if ($car_id <= 0) {
    echo json_encode(["ok" => false, "message" => "Invalid car_id"]);
    exit;
  }

  // ✅ PDO soft delete
  $stmt = $pdo->prepare("UPDATE cars SET deleted_at = NOW() WHERE car_id = :id AND deleted_at IS NULL");
  $stmt->execute([":id" => $car_id]);

  if ($stmt->rowCount() <= 0) {
    echo json_encode(["ok" => false, "message" => "Car not found or already deleted"]);
    exit;
  }

  echo json_encode(["ok" => true, "message" => "Deleted (soft)"]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    "ok" => false,
    "message" => "Server error",
    "debug" => $e->getMessage()
  ]);
}
