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
$accidentId = (int)($input['accident_id'] ?? 0);
$decision = strtoupper(trim($input['decision'] ?? ''));
$notes = trim($input['notes'] ?? '');

if ($accidentId <= 0 || $decision === '') {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "accident_id and decision are required"]);
  exit;
}

try {
  $stmt = $pdo->prepare("UPDATE accidents SET status = :s WHERE accident_id = :id");
  $stmt->execute([':s' => $decision, ':id' => $accidentId]);

  // If we had a notes column we would store it; currently we only update status.
  echo json_encode(["ok" => true, "message" => "Accident updated"]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
