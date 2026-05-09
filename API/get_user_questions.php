<?php
/**
 * Get User Questions API
 * Sami Backend - Shows user's own questions including pending ones
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
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

try {
    // Get parameters
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
    $offset = ($page - 1) * $limit;

    if (!$userId) {
        sendJsonResponse(false, "User ID is required", [], 400);
    }

    // Check if user exists
    $stmt = $pdo->prepare("SELECT user_id FROM users WHERE user_id = :user_id");
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    if (!$stmt->fetch()) {
        sendJsonResponse(false, "User not found", [], 404);
    }

    $sql = "SELECT 
                q.question_id AS id, 
                q.user_id AS author_id, 
                q.title, 
                q.content, 
                q.subject, 
                q.category, 
                q.tags, 
                q.images, 
                q.status, 
                q.featured, 
                q.view_count, 
                q.upvotes, 
                q.downvotes, 
                q.answer_count, 
                (SELECT answer_id FROM answers WHERE question_id = q.question_id AND is_best = 1 LIMIT 1) AS accepted_answer_id,
                q.created_at, 
                q.updated_at,
                u.username AS author_name,
                u.first_name AS author_first_name,
                u.last_name AS author_last_name,
                u.profile_picture AS author_avatar_url,
                (u.role = 'admin' OR u.role = 'moderator') AS author_is_verified,
                0 AS is_upvoted, 
                0 AS is_downvoted, 
                0 AS is_bookmarked
            FROM questions q
            JOIN users u ON q.user_id = u.user_id
            WHERE q.user_id = :user_id AND q.status != 'deleted'
            ORDER BY q.created_at DESC LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($sql);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Decode JSON fields and format types
    foreach ($questions as &$question) {
        $question['id'] = (int)$question['id'];
        $question['author_id'] = (string)$question['author_id'];
        $question['accepted_answer_id'] = $question['accepted_answer_id'] ? (string)$question['accepted_answer_id'] : null;
        $question['view_count'] = (int)$question['view_count'];
        $question['upvotes'] = (int)$question['upvotes'];
        $question['downvotes'] = (int)$question['downvotes'];
        $question['answer_count'] = (int)$question['answer_count'];
        $question['featured'] = (bool)$question['featured'];
        $question['author_is_verified'] = (bool)$question['author_is_verified'];
        $question['is_upvoted'] = (bool)$question['is_upvoted'];
        $question['is_downvoted'] = (bool)$question['is_downvoted'];
        $question['is_bookmarked'] = (bool)$question['is_bookmarked'];
        $question['is_resolved'] = $question['answer_count'] > 0;

        if ($question['tags']) {
            $question['tags'] = json_decode($question['tags']);
        } else {
            $question['tags'] = [];
        }
        
        if ($question['images']) {
            $question['images'] = json_decode($question['images']);
        } else {
            $question['images'] = [];
        }
    }

    // Get total count for pagination metadata
    $countStmt = $pdo->prepare("SELECT COUNT(*) FROM questions WHERE user_id = :user_id AND status != 'deleted'");
    $countStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $countStmt->execute();
    $totalQuestions = $countStmt->fetchColumn();

    sendJsonResponse(true, "User questions fetched successfully", [
        'questions' => $questions,
        'total' => (int)$totalQuestions,
        'page' => $page,
        'limit' => $limit
    ]);

} catch (PDOException $e) {
    error_log("Error fetching user questions: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
} catch (Exception $e) {
    error_log("An unexpected error occurred: " . $e->getMessage());
    sendJsonResponse(false, "An unexpected error occurred: " . $e->getMessage(), [], 500);
}
?>
