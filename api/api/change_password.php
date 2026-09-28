<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

try {
  $raw = file_get_contents("php://input");
  $body = json_decode($raw, true);

  if (!is_array($body)) {
    echo json_encode(["ok" => false, "message" => "Invalid JSON body"]);
    exit;
  }

  $user_id = intval($body["user_id"] ?? 0);
  $oldPass = strval($body["old_password"] ?? "");
  $newPass = strval($body["new_password"] ?? "");

  if ($user_id <= 0) {
    echo json_encode(["ok" => false, "message" => "user_id is required"]);
    exit;
  }
  if ($oldPass === "" || $newPass === "") {
    echo json_encode(["ok" => false, "message" => "old_password and new_password are required"]);
    exit;
  }
  if (strlen($newPass) < 6) {
    echo json_encode(["ok" => false, "message" => "New password must be at least 6 characters"]);
    exit;
  }

  $stmt = $pdo->prepare("SELECT password_hash FROM users WHERE user_id = :uid LIMIT 1");
  $stmt->execute([":uid" => $user_id]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$row) {
    echo json_encode(["ok" => false, "message" => "User not found"]);
    exit;
  }

  $hash = $row["password_hash"] ?? "";

  // لازم يكون hash (password_hash)
  if (!password_verify($oldPass, $hash)) {
    echo json_encode(["ok" => false, "message" => "Old password is incorrect"]);
    exit;
  }

  $newHash = password_hash($newPass, PASSWORD_DEFAULT);

  $up = $pdo->prepare("UPDATE users SET password_hash = :h, updated_at = NOW() WHERE user_id = :uid LIMIT 1");
  $up->execute([":h" => $newHash, ":uid" => $user_id]);

  echo json_encode(["ok" => true, "message" => "Password updated"]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
