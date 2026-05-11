<?php
/**
 * Update Answer API
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
$userId = $data['user_id'] ?? null;
$content = $data['content'] ?? null;

if (!$answerId || !$userId || !$content) {
    sendJsonResponse(false, "Missing required fields: answer_id, user_id, and content are required.", [], 400);
}

try {
    // Check if answer exists and belongs to user
    $stmt = $pdo->prepare("SELECT user_id FROM answers WHERE answer_id = :answer_id");
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->execute();
    $answer = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$answer) {
        sendJsonResponse(false, "Answer not found.", [], 404);
    }

    if ($answer['user_id'] != $userId) {
        sendJsonResponse(false, "Unauthorized: You do not own this answer.", [], 403);
    }

    // Update answer
    $stmt = $pdo->prepare("UPDATE answers SET content = :content, updated_at = NOW() WHERE answer_id = :answer_id");
    $stmt->bindParam(':content', $content, PDO::PARAM_STR);
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->execute();

    // Fetch updated answer
    $stmt = $pdo->prepare("SELECT 
                                a.answer_id AS id, 
                                a.question_id, 
                                a.user_id AS author_id, 
                                a.content, 
                                a.status, 
                                a.is_best, 
                                a.upvotes, 
                                a.downvotes, 
                                a.created_at, 
                                a.updated_at,
                                u.username AS author_name,
                                u.profile_picture AS author_avatar_url,
                                (u.role = 'admin' OR u.role = 'moderator') AS author_is_verified
                            FROM answers a
                            JOIN users u ON a.user_id = u.user_id
                            WHERE a.answer_id = :answer_id");
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->execute();
    $updatedAnswer = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($updatedAnswer) {
        $updatedAnswer['id'] = (int)$updatedAnswer['id'];
        $updatedAnswer['question_id'] = (int)$updatedAnswer['question_id'];
        $updatedAnswer['author_id'] = (string)$updatedAnswer['author_id'];
        $updatedAnswer['upvotes'] = (int)$updatedAnswer['upvotes'];
        $updatedAnswer['downvotes'] = (int)$updatedAnswer['downvotes'];
        $updatedAnswer['is_best'] = (bool)$updatedAnswer['is_best'];
        $updatedAnswer['author_is_verified'] = (bool)$updatedAnswer['author_is_verified'];
        $updatedAnswer['images'] = [];

        sendJsonResponse(true, "Answer updated successfully.", $updatedAnswer);
    } else {
        sendJsonResponse(false, "Failed to retrieve updated answer.", [], 500);
    }

} catch (PDOException $e) {
    error_log("Error updating answer: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
