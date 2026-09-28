<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$bookingId = (int)($data['booking_id'] ?? 0);
$note = trim($data['note'] ?? '');
$category = strtoupper(trim($data['category'] ?? 'GENERAL'));

if ($bookingId <= 0 || $note === '') {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid booking ID or empty note"]);
  exit;
}

$allowedCategories = ['DELAY', 'VIOLATION', 'DAMAGE', 'GENERAL'];
if (!in_array($category, $allowedCategories)) {
  $category = 'GENERAL';
}

try {
  // Ensure booking_notes table exists
  $pdo->exec("
    CREATE TABLE IF NOT EXISTS booking_notes (
      note_id INT AUTO_INCREMENT PRIMARY KEY,
      booking_id INT NOT NULL,
      note TEXT NOT NULL,
      category ENUM('DELAY', 'VIOLATION', 'DAMAGE', 'GENERAL') DEFAULT 'GENERAL',
      created_by INT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
      FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
    )
  ");

  // Get current user from session (you may need to implement session handling)
  // For now, we'll set created_by to NULL or get from request
  $createdBy = (int)($data['created_by'] ?? null);

  $stmt = $pdo->prepare("
    INSERT INTO booking_notes (booking_id, note, category, created_by)
    VALUES (:booking_id, :note, :category, :created_by)
  ");
  
  $stmt->execute([
    ":booking_id" => $bookingId,
    ":note" => $note,
    ":category" => $category,
    ":created_by" => $createdBy ?: null
  ]);

  echo json_encode([
    "ok" => true,
    "message" => "Note added successfully",
    "note_id" => $pdo->lastInsertId()
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
