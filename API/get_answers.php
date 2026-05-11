<?php
/**
 * Get Answers API
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

$questionId = $_GET['question_id'] ?? null;
$userId = $_GET['user_id'] ?? null;
$viewerId = $_GET['viewer_id'] ?? null;
$page = (int)($_GET['page'] ?? 1);
$limit = (int)($_GET['limit'] ?? 20);
$offset = ($page - 1) * $limit;

if (!$questionId && !$userId) {
    sendJsonResponse(false, "Missing required parameter: question_id or user_id.", [], 400);
}

// Map userId to user_id if needed (frontend uses user_id)
$userId = $_GET['user_id'] ?? $_GET['userId'] ?? null;
$questionId = $_GET['question_id'] ?? $_GET['questionId'] ?? null;

try {
    $sql = "SELECT 
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
                (u.role = 'admin' OR u.role = 'moderator') AS author_is_verified";

    if ($viewerId) {
        $sql .= ", (SELECT COUNT(*) FROM answer_votes WHERE answer_id = a.answer_id AND user_id = :viewer_id_up AND vote_type = 'up') > 0 AS is_upvoted";
        $sql .= ", (SELECT COUNT(*) FROM answer_votes WHERE answer_id = a.answer_id AND user_id = :viewer_id_down AND vote_type = 'down') > 0 AS is_downvoted";
    } else {
        $sql .= ", 0 AS is_upvoted, 0 AS is_downvoted";
    }

    $sql .= " FROM answers a
            JOIN users u ON a.user_id = u.user_id
            WHERE a.status != 'deleted'";
    
    if ($questionId) {
        $sql .= " AND a.question_id = :question_id";
    }
    
    if ($userId) {
        $sql .= " AND a.user_id = :user_id";
    }

    $sql .= " ORDER BY a.is_best DESC, a.upvotes DESC, a.created_at ASC
            LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($sql);
    
    if ($questionId) {
        $stmt->bindValue(':question_id', (int)$questionId, PDO::PARAM_INT);
    }
    
    if ($userId) {
        $stmt->bindValue(':user_id', (int)$userId, PDO::PARAM_INT);
    }

    if ($viewerId) {
        $stmt->bindValue(':viewer_id_up', (int)$viewerId, PDO::PARAM_INT);
        $stmt->bindValue(':viewer_id_down', (int)$viewerId, PDO::PARAM_INT);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $answers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format types for Flutter
    foreach ($answers as &$answer) {
        $answer['id'] = (int)$answer['id'];
        $answer['question_id'] = (int)$answer['question_id'];
        $answer['author_id'] = (string)$answer['author_id'];
        $answer['upvotes'] = (int)$answer['upvotes'];
        $answer['downvotes'] = (int)$answer['downvotes'];
        $answer['is_best'] = (bool)$answer['is_best'];
        $answer['is_upvoted'] = (bool)$answer['is_upvoted'];
        $answer['is_downvoted'] = (bool)$answer['is_downvoted'];
        $answer['author_is_verified'] = (bool)$answer['author_is_verified'];
        $answer['images'] = []; // Schema doesn't have images for answers yet
    }

    // Get total count
    $countSql = "SELECT COUNT(*) FROM answers WHERE status != 'deleted'";
    if ($questionId) $countSql .= " AND question_id = :question_id";
    if ($userId) $countSql .= " AND user_id = :user_id";
    
    $stmt = $pdo->prepare($countSql);
    if ($questionId) $stmt->bindValue(':question_id', (int)$questionId, PDO::PARAM_INT);
    if ($userId) $stmt->bindValue(':user_id', (int)$userId, PDO::PARAM_INT);
    $stmt->execute();
    $total = (int)$stmt->fetchColumn();

    sendJsonResponse(true, "Answers fetched successfully.", [
        'answers' => $answers,
        'total' => $total,
        'page' => $page,
        'limit' => $limit
    ]);

} catch (PDOException $e) {
    error_log("Error fetching answers: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
