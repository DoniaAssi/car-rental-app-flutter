<?php
// Set CORS headers first (before any output)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit;
}

require_once "db.php";

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$full_name = trim($data['full_name'] ?? '');
$phone     = trim($data['phone'] ?? '');
$email     = trim($data['email'] ?? '');
$password  = (string)($data['password'] ?? '');
$role      = strtoupper(trim($data['role'] ?? ''));

// 🔐 Manager invite code
$manager_code = trim($data['manager_code'] ?? '');
$MANAGER_INVITE_CODE = "RAMALLAH2026";

$allowedRoles = ['CUSTOMER', 'WASHING_EMPLOYEE', 'COMPANY_MANAGER'];

if ($full_name === '' || $phone === '' || $email === '' || $password === '' || $role === '') {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Missing required fields"]);
  exit;
}

if (!in_array($role, $allowedRoles)) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid role"]);
  exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid email"]);
  exit;
}

if (strlen($password) < 6) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Password must be at least 6 characters"]);
  exit;
}

$phone = preg_replace('/\s+/', '', $phone);

// ❗ حماية حساب المدير
if ($role === "COMPANY_MANAGER" && $manager_code !== $MANAGER_INVITE_CODE) {
  http_response_code(403);
  echo json_encode(["ok" => false, "message" => "Invalid manager code"]);
  exit;
}

try {
  $check = $pdo->prepare("SELECT user_id FROM users WHERE email = :email OR phone = :phone");
  $check->execute([":email" => $email, ":phone" => $phone]);

  if ($check->fetch()) {
    http_response_code(409);
    echo json_encode(["ok" => false, "message" => "Email or phone already exists"]);
    exit;
  }

  $hash = password_hash($password, PASSWORD_BCRYPT);

  $stmt = $pdo->prepare("
    INSERT INTO users (full_name, email, phone, password_hash, role, is_active)
    VALUES (:full_name, :email, :phone, :password_hash, :role, 1)
  ");

  $stmt->execute([
    ":full_name" => $full_name,
    ":email" => $email,
    ":phone" => $phone,
    ":password_hash" => $hash,
    ":role" => $role
  ]);

  echo json_encode([
    "ok" => true,
    "message" => "Account created successfully",
    "role" => $role
  ]);

} catch (Throwable $e) {
  http_response_code(500);
  // Log error for debugging (remove in production or log to file)
  error_log("Registration error: " . $e->getMessage());
  echo json_encode(["ok" => false, "message" => "Server error: " . $e->getMessage()]);
}
?>