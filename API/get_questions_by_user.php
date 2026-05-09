<?php
/**
 * Get Questions by User API
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

try {
    // Pagination parameters
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
    $offset = ($page - 1) * $limit;

    // User ID parameter
    $userId = isset($_GET['user_id']) ? $_GET['user_id'] : null;
    $viewerId = isset($_GET['viewer_id']) ? $_GET['viewer_id'] : null;

    if (!$userId) {
        sendJsonResponse(false, "Missing required parameter: user_id.", [], 400);
    }

    $sql = "SELECT 
                q.question_id AS id, 
                q.user_id AS userId, 
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
                (SELECT answer_id FROM answers WHERE question_id = q.question_id AND is_best = 1 LIMIT 1) AS bestAnswerId,
                q.created_at, 
                q.updated_at,
                u.username AS userName,
                u.first_name AS userFirstName,
                u.last_name AS userLastName,
                u.profile_picture AS userAvatarUrl,
                (u.role = 'admin' OR u.role = 'moderator') AS userIsVerified";

    if ($viewerId) {
        $sql .= ", (SELECT COUNT(*) FROM question_votes WHERE question_id = q.question_id AND user_id = :viewer_id_up AND vote_type = 'up') > 0 AS is_upvoted";
        $sql .= ", (SELECT COUNT(*) FROM question_votes WHERE question_id = q.question_id AND user_id = :viewer_id_down AND vote_type = 'down') > 0 AS is_downvoted";
        $sql .= ", (SELECT COUNT(*) FROM bookmarks WHERE question_id = q.question_id AND user_id = :viewer_id_book) > 0 AS is_bookmarked";
    } else {
        $sql .= ", 0 AS is_upvoted, 0 AS is_downvoted, 0 AS is_bookmarked";
    }

    $sql .= " FROM questions q
            JOIN users u ON q.user_id = u.user_id
            WHERE q.user_id = :user_id AND q.status != 'deleted'
            ORDER BY q.created_at DESC LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':user_id', (int)$userId, PDO::PARAM_INT);
    if ($viewerId) {
        $stmt->bindValue(':viewer_id_up', (int)$viewerId, PDO::PARAM_INT);
        $stmt->bindValue(':viewer_id_down', (int)$viewerId, PDO::PARAM_INT);
        $stmt->bindValue(':viewer_id_book', (int)$viewerId, PDO::PARAM_INT);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Decode JSON fields and format types to match Flutter Question entity
    foreach ($questions as &$question) {
        // Map to match Flutter Question.fromJson expectations
        $question['id'] = (int)$question['id'];
        $question['user_id'] = (int)$question['userId']; // Flutter expects user_id
        $question['user_name'] = $question['userName']; // Flutter expects user_name
        $question['user_avatar_url'] = $question['userAvatarUrl']; // Flutter expects user_avatar_url
        $question['best_answer_id'] = $question['bestAnswerId']; // Flutter expects best_answer_id
        $question['upvotes'] = (int)$question['upvotes'];
        $question['downvotes'] = (int)$question['downvotes'];
        $question['answer_count'] = (int)$question['answer_count'];
        $question['created_at'] = $question['created_at']; // Flutter expects created_at
        $question['updated_at'] = $question['updated_at']; // Flutter expects updated_at
        $question['is_solved'] = $question['answer_count'] > 0; // Flutter expects is_solved
        
        // Handle tags
        if ($question['tags']) {
            $question['tags'] = json_decode($question['tags']);
        } else {
            $question['tags'] = [];
        }
        
        // Remove fields that aren't needed by Flutter Question entity
        unset($question['userId'], $question['userName'], $question['userAvatarUrl'], 
              $question['bestAnswerId'], $question['createdAt'], $question['updatedAt'], $question['isSolved'],
              $question['category'], $question['featured'], $question['view_count'],
              $question['userFirstName'], $question['userLastName'], $question['userIsVerified'],
              $question['is_upvoted'], $question['is_downvoted'], $question['is_bookmarked'],
              $question['images']);
    }

    // Get total count for pagination metadata
    $countSql = "SELECT COUNT(*) FROM questions q WHERE q.user_id = :user_id AND q.status != 'deleted'";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->bindValue(':user_id', (int)$userId, PDO::PARAM_INT);
    $countStmt->execute();
    $totalQuestions = $countStmt->fetchColumn();

    sendJsonResponse(true, "Questions fetched by user successfully.", [
        'questions' => $questions,
        'total' => (int)$totalQuestions,
        'page' => $page,
        'limit' => $limit
    ]);

} catch (PDOException $e) {
    error_log("Error fetching questions by user: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
} catch (Exception $e) {
    error_log("An unexpected error occurred: " . $e->getMessage());
    sendJsonResponse(false, "An unexpected error occurred: " . $e->getMessage(), [], 500);
}
?>
