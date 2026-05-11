<?php
/**
 * Mark Best Answer API
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

$answerId = $data['answer_id'] ?? null;
$questionId = $data['question_id'] ?? null;

if (!$answerId || !$questionId) {
    sendJsonResponse(false, "Missing required fields: answer_id and question_id are required.", [], 400);
}

try {
    // Start transaction
    $pdo->beginTransaction();

    // 1. Reset all answers for this question to NOT best
    $stmt = $pdo->prepare("UPDATE answers SET is_best = 0 WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();

    // 2. Set the selected answer as best
    $stmt = $pdo->prepare("UPDATE answers SET is_best = 1 WHERE answer_id = :answer_id AND question_id = :question_id");
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        $pdo->rollBack();
        sendJsonResponse(false, "Answer not found or does not belong to the specified question.", [], 404);
    }

    // 3. Award 10 points to the answer author
    try {
        // Get the answer author ID
        $authorStmt = $pdo->prepare("SELECT user_id FROM answers WHERE answer_id = :answer_id");
        $authorStmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
        $authorStmt->execute();
        $answerData = $authorStmt->fetch(PDO::FETCH_ASSOC);

        if ($answerData) {
            $authorId = $answerData['user_id'];
            
            // Insert into user_points table for history
            $pointStmt = $pdo->prepare("INSERT INTO user_points (user_id, points, reason, reference_id, created_at) VALUES (:user_id, 10, 'best_answer', :source_id, NOW())");
            $pointStmt->bindParam(':user_id', $authorId, PDO::PARAM_INT);
            $pointStmt->bindParam(':source_id', $answerId, PDO::PARAM_INT);
            $pointStmt->execute();
        }
    } catch (PDOException $e) {
        // Log error but don't fail the whole transaction if point awarding fails
        error_log("Failed to award points for best answer: " . $e->getMessage());
    }

    $pdo->commit();
    sendJsonResponse(true, "Answer marked as best successfully.");

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log("Error marking best answer: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
