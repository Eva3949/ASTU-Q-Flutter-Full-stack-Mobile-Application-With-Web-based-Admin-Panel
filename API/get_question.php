<?php
/**
 * Get Single Question API
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

// Get question ID from query parameters
$questionId = $_GET['question_id'] ?? null;
$viewerId = isset($_GET['viewer_id']) ? (int)$_GET['viewer_id'] : null;

if (!$questionId) {
    sendJsonResponse(false, "Missing required parameter: question_id.", [], 400);
}

try {
    // Update view count
    $stmt = $pdo->prepare("UPDATE questions SET view_count = view_count + 1 WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();

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
                (u.role = 'admin' OR u.role = 'moderator') AS author_is_verified";

    if ($viewerId) {
        $sql .= ", (SELECT COUNT(*) FROM question_votes WHERE question_id = q.question_id AND user_id = :viewer_id_up AND vote_type = 'up') > 0 AS is_upvoted";
        $sql .= ", (SELECT COUNT(*) FROM question_votes WHERE question_id = q.question_id AND user_id = :viewer_id_down AND vote_type = 'down') > 0 AS is_downvoted";
        $sql .= ", (SELECT COUNT(*) FROM bookmarks WHERE question_id = q.question_id AND user_id = :viewer_id_book) > 0 AS is_bookmarked";
    } else {
        $sql .= ", 0 AS is_upvoted, 0 AS is_downvoted, 0 AS is_bookmarked";
    }

    $sql .= " FROM questions q
            JOIN users u ON q.user_id = u.user_id
            WHERE q.question_id = :question_id";

    $stmt = $pdo->prepare($sql);
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    if ($viewerId) {
        $stmt->bindParam(':viewer_id_up', $viewerId, PDO::PARAM_INT);
        $stmt->bindParam(':viewer_id_down', $viewerId, PDO::PARAM_INT);
        $stmt->bindParam(':viewer_id_book', $viewerId, PDO::PARAM_INT);
    } 
    $stmt->execute();
    $question = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($question) {
        // Decode JSON fields and format types
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
        
        sendJsonResponse(true, "Question fetched successfully.", $question);
    } else {
        sendJsonResponse(false, "Question not found.", [], 404);
    }

} catch (PDOException $e) {
    error_log("Error fetching question: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
} catch (Exception $e) {
    error_log("An unexpected error occurred: " . $e->getMessage());
    sendJsonResponse(false, "An unexpected error occurred: " . $e->getMessage(), [], 500);
}
?>
