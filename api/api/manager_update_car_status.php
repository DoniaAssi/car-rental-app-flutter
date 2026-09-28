<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$input = json_decode(file_get_contents('php://input'), true) ?? [];
$carId = (int)($input['car_id'] ?? 0);
$status = strtoupper(trim($input['status'] ?? ''));

if ($carId <= 0 || $status === '') {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "car_id and status are required"]);
  exit;
}

try {
  $stmt = $pdo->prepare("UPDATE cars SET status = :s WHERE car_id = :id");
  $stmt->execute([':s' => $status, ':id' => $carId]);

  echo json_encode(["ok" => true, "message" => "Status updated"]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
