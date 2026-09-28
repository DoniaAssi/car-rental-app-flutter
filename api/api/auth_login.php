<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$email = trim($data['email'] ?? '');
$password = (string)($data['password'] ?? '');

if ($email === '' || $password === '') {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing email or password"]);
  exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid email"]);
  exit;
}

try {
  $stmt = $pdo->prepare("
    SELECT user_id, full_name, email, phone, password_hash, role, is_active
    FROM users
    WHERE email = :email
    LIMIT 1
  ");
  $stmt->execute([":email" => $email]);
  $user = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$user) {
    http_response_code(401);
    echo json_encode(["ok" => false, "message" => "Invalid credentials"]);
    exit;
  }

  if ((int)$user['is_active'] !== 1) {
    http_response_code(403);
    echo json_encode(["ok" => false, "message" => "Account disabled"]);
    exit;
  }

  if (!password_verify($password, $user['password_hash'])) {
    http_response_code(401);
    echo json_encode(["ok" => false, "message" => "Invalid credentials"]);
    exit;
  }

  echo json_encode([
    "ok" => true,
    "message" => "Login successful",
    "user" => [
      "user_id" => (int)$user["user_id"],
      "full_name" => $user["full_name"],
      "email" => $user["email"],
      "phone" => $user["phone"],
      "role" => strtoupper((string)$user["role"]),
      "is_active" => (int)$user["is_active"]
    ]
  ]);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error"]);
}
