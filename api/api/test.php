<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit;
}

echo json_encode([
  "ok" => true,
  "message" => "API is accessible",
  "endpoint" => "test.php",
  "request_method" => $_SERVER['REQUEST_METHOD'],
  "request_uri" => $_SERVER['REQUEST_URI'] ?? 'unknown'
]);
?>

