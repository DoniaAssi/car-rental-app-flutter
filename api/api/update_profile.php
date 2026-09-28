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

  $user_id   = intval($body["user_id"] ?? 0);
  $full_name = trim($body["full_name"] ?? "");
  $email     = trim($body["email"] ?? "");
  $phone     = trim($body["phone"] ?? "");

  if ($user_id <= 0) {
    echo json_encode(["ok" => false, "message" => "user_id is required"]);
    exit;
  }
  if ($full_name === "" || $email === "" || $phone === "") {
    echo json_encode(["ok" => false, "message" => "full_name, email, phone are required"]);
    exit;
  }

  // (اختياري) تأكد الإيميل مش مستخدم ليوزر ثاني
  $chk = $pdo->prepare("SELECT user_id FROM users WHERE email = :email AND user_id <> :uid LIMIT 1");
  $chk->execute([":email" => $email, ":uid" => $user_id]);
  if ($chk->fetch()) {
    echo json_encode(["ok" => false, "message" => "Email already used by another account"]);
    exit;
  }

  // update
  $sql = "UPDATE users
          SET full_name = :full_name,
              email     = :email,
              phone     = :phone,
              updated_at = NOW()
          WHERE user_id = :user_id
          LIMIT 1";
  $stmt = $pdo->prepare($sql);
  $stmt->execute([
    ":full_name" => $full_name,
    ":email" => $email,
    ":phone" => $phone,
    ":user_id" => $user_id
  ]);

  // رجّع بيانات محدثة (بدون password_hash)
  $get = $pdo->prepare("SELECT user_id, full_name, email, phone, role, is_active, avatar_url, created_at, updated_at
                        FROM users WHERE user_id = :uid LIMIT 1");
  $get->execute([":uid" => $user_id]);
  $user = $get->fetch(PDO::FETCH_ASSOC);

  if (!$user) {
    echo json_encode(["ok" => false, "message" => "User not found"]);
    exit;
  }

  echo json_encode(["ok" => true, "user" => $user]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    "ok" => false,
    "message" => "Server error",
    "debug" => $e->getMessage()
  ]);
}
