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
$userId = (int)($input['user_id'] ?? 0);
$isActive = (int)($input['is_active'] ?? 1);

if ($userId <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "user_id is required"]);
  exit;
}

try {
  $stmt = $pdo->prepare("UPDATE users SET is_active = :a WHERE user_id = :id");
  $stmt->execute([':a' => $isActive, ':id' => $userId]);
  echo json_encode(["ok" => true, "message" => "Employee updated"]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
