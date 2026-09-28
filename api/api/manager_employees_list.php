<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

try {
  $sql = "SELECT user_id, full_name, email, phone, role, is_active FROM users WHERE role = 'WASHING_EMPLOYEE' ORDER BY full_name";
  $rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
  echo json_encode(["ok" => true, "data" => $rows]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
