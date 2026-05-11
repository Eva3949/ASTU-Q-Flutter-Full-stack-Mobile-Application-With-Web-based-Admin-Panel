<?php
/**
 * Report Question API
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

require_once 'db_connection.php';

// Helper function for JSON response
function sendJsonResponse($success, $message, $data = [], $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    sendJsonResponse(true, "Options request handled");
}

// Get POST data
$data = json_decode(file_get_contents("php://input"), true);

$questionId = $data['question_id'] ?? null;
$reporterId = $data['reporter_id'] ?? null;
$reason = $data['reason'] ?? null; // 'spam', 'inappropriate', 'harassment', 'copyright', 'off_topic', 'other'
$description = $data['description'] ?? null;

if (!$questionId || !$reporterId || !$reason) {
    sendJsonResponse(false, "Missing required fields: question_id, reporter_id, and reason are required.", [], 400);
}

// Validate reason enum
if (!in_array($reason, ['spam', 'inappropriate', 'harassment', 'copyright', 'off_topic', 'other'])) {
    sendJsonResponse(false, "Invalid reason.", [], 400);
}

try {
    // Check if question exists
    $stmt = $pdo->prepare("SELECT question_id FROM questions WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();
    if (!$stmt->fetch()) {
        sendJsonResponse(false, "Question not found.", [], 404);
    }

    // Insert report
    $stmt = $pdo->prepare(
        "INSERT INTO reports (reported_item_type, reported_item_id, reporter_id, reason, description, status, created_at) 
         VALUES ('question', :question_id, :reporter_id, :reason, :description, 'pending', NOW())"
    );
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->bindParam(':reporter_id', $reporterId, PDO::PARAM_INT);
    $stmt->bindParam(':reason', $reason, PDO::PARAM_STR);
    $stmt->bindParam(':description', $description, PDO::PARAM_STR);
    $stmt->execute();

    sendJsonResponse(true, "Report submitted successfully.");

} catch (PDOException $e) {
    error_log("Error reporting question: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
