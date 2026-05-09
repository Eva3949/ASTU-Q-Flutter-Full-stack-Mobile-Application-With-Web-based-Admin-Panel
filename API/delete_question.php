<?php
/**
 * Delete Question API
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: DELETE, OPTIONS");
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

// Get DELETE data (from query parameters or JSON body)
$questionId = $_GET['question_id'] ?? null;
$userId = $_GET['user_id'] ?? null; // User performing the delete (for authorization)

// If not in query params, try JSON body for more complex DELETE requests
if (!$questionId && $_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = json_decode(file_get_contents("php://input"), true);
    $questionId = $data['question_id'] ?? null;
    $userId = $data['user_id'] ?? null;
}


if (!$questionId || !$userId) {
    sendJsonResponse(false, "Missing required fields: question_id and user_id are required.", [], 400);
}

// Check if question exists and belongs to the user
try {
    $stmt = $pdo->prepare("SELECT user_id FROM questions WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();
    $question = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$question) {
        sendJsonResponse(false, "Question not found.", [], 404);
    }
    // Basic authorization: only the owner can delete their question
    // In a real app, you might also allow admins/moderators
    if ($question['user_id'] != $userId) {
        sendJsonResponse(false, "Unauthorized: You do not own this question.", [], 403);
    }

} catch (PDOException $e) {
    error_log("Database error checking question ownership: " . $e->getMessage());
    sendJsonResponse(false, "Database error.", [], 500);
}

try {
    $stmt = $pdo->prepare("DELETE FROM questions WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        sendJsonResponse(true, "Question deleted successfully.", [], 200);
    } else {
        sendJsonResponse(false, "Question not found or already deleted.", [], 404);
    }

} catch (PDOException $e) {
    error_log("Error deleting question: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
} catch (Exception $e) {
    error_log("An unexpected error occurred: " . $e->getMessage());
    sendJsonResponse(false, "An unexpected error occurred: " . $e->getMessage(), [], 500);
}
?>