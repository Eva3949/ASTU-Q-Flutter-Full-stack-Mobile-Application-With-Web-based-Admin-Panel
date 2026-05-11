<?php
/**
 * Delete Answer API
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
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

$answerId = $_GET['answer_id'] ?? null;
$userId = $_GET['user_id'] ?? null;

if (!$answerId || !$userId) {
    sendJsonResponse(false, "Missing required parameters: answer_id and user_id are required.", [], 400);
}

try {
    // Check if answer exists and belongs to user
    $stmt = $pdo->prepare("SELECT user_id, question_id FROM answers WHERE answer_id = :answer_id");
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->execute();
    $answer = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$answer) {
        sendJsonResponse(false, "Answer not found.", [], 404);
    }

    if ($answer['user_id'] != $userId) {
        sendJsonResponse(false, "Unauthorized: You do not own this answer.", [], 403);
    }

    $questionId = $answer['question_id'];

    // Delete answer
    $stmt = $pdo->prepare("DELETE FROM answers WHERE answer_id = :answer_id");
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->execute();

    // Decrement answer count in questions table
    $stmt = $pdo->prepare("UPDATE questions SET answer_count = answer_count - 1 WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();

    sendJsonResponse(true, "Answer deleted successfully.");

} catch (PDOException $e) {
    error_log("Error deleting answer: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
