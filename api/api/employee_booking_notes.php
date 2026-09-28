<?php
require_once "db.php";
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  http_response_code(405);
  echo json_encode(["ok" => false, "message" => "Method not allowed"]);
  exit;
}

$bookingId = (int)($_GET['booking_id'] ?? 0);

if ($bookingId <= 0) {
  http_response_code(400);
  echo json_encode(["ok" => false, "message" => "Invalid booking ID"]);
  exit;
}

try {
  // Check if booking_notes table exists, if not create it
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

  $stmt = $pdo->prepare("
    SELECT 
      bn.note_id,
      bn.booking_id,
      bn.note,
      bn.category,
      bn.created_at,
      DATE_FORMAT(bn.created_at, '%h:%i %p') AS time,
      DATE_FORMAT(bn.created_at, '%M %d, %Y') AS date,
      u.full_name AS created_by_name
    FROM booking_notes bn
    LEFT JOIN users u ON bn.created_by = u.user_id
    WHERE bn.booking_id = :id
    ORDER BY bn.created_at DESC
  ");
  
  $stmt->execute([":id" => $bookingId]);
  $notes = $stmt->fetchAll(PDO::FETCH_ASSOC);

  echo json_encode([
    "ok" => true,
    "data" => $notes
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["ok" => false, "message" => "Server error", "debug" => $e->getMessage()]);
}
