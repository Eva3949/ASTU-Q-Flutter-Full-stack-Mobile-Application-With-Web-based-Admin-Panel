<?php
/**
 * Update Question API
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
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

// Get PUT data
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
$questionId = $data['question_id'] ?? null;
$userId = $data['user_id'] ?? null; // User performing the update (for authorization)
$title = $data['title'] ?? null;
$content = $data['content'] ?? null;
$subject = $data['subject'] ?? null;
$category = $data['category'] ?? null;
$tags = $data['tags'] ?? null; // Expect array, store as JSON
$images = $data['images'] ?? null; // Expect array, store as JSON
$status = $data['status'] ?? null;
$featured = $data['featured'] ?? null;

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
    // Basic authorization: only the owner can update their question
    if ($question['user_id'] != $userId) {
        sendJsonResponse(false, "Unauthorized: You do not own this question.", [], 403);
    }

} catch (PDOException $e) {
    error_log("Database error checking question ownership: " . $e->getMessage());
    sendJsonResponse(false, "Database error.", [], 500);
}

$updateFields = [];
$params = [':question_id' => $questionId];

if ($title !== null) {
    $updateFields[] = "title = :title";
    $params[':title'] = $title;
}
if ($content !== null) {
    $updateFields[] = "content = :content";
    $params[':content'] = $content;
}
if ($subject !== null) {
    $updateFields[] = "subject = :subject";
    $params[':subject'] = $subject;
}
if ($category !== null) {
    $updateFields[] = "category = :category";
    $params[':category'] = $category;
}
if ($tags !== null) {
    $updateFields[] = "tags = :tags";
    $params[':tags'] = json_encode($tags);
}
if ($images !== null) {
    $updateFields[] = "images = :images";
    $params[':images'] = json_encode($images);
}
if ($status !== null) {
    $updateFields[] = "status = :status";
    $params[':status'] = $status;
}
if ($featured !== null) {
    $updateFields[] = "featured = :featured";
    $params[':featured'] = (int)$featured;
}

if (empty($updateFields)) {
    sendJsonResponse(false, "No fields provided for update.", [], 400);
}

$sql = "UPDATE questions SET " . implode(", ", $updateFields) . ", updated_at = NOW() WHERE question_id = :question_id";

try {
    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => &$val) {
        $stmt->bindParam($key, $val);
    }
    $stmt->execute();

    // Fetch the updated question with correct mapping
    $stmt = $pdo->prepare("SELECT 
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
                                q.created_at, 
                                q.updated_at,
                                u.username AS author_name,
                                u.first_name AS author_first_name,
                                u.last_name AS author_last_name,
                                u.profile_picture AS author_avatar_url,
                                (u.role = 'admin' OR u.role = 'moderator') AS author_is_verified
                            FROM questions q
                            JOIN users u ON q.user_id = u.user_id
                            WHERE q.question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();
    $updatedQuestion = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($updatedQuestion) {
        // Decode JSON fields and format types
        $updatedQuestion['id'] = (int)$updatedQuestion['id'];
        $updatedQuestion['author_id'] = (string)$updatedQuestion['author_id'];
        $updatedQuestion['view_count'] = (int)$updatedQuestion['view_count'];
        $updatedQuestion['upvotes'] = (int)$updatedQuestion['upvotes'];
        $updatedQuestion['downvotes'] = (int)$updatedQuestion['downvotes'];
        $updatedQuestion['answer_count'] = (int)$updatedQuestion['answer_count'];
        $updatedQuestion['featured'] = (bool)$updatedQuestion['featured'];
        $updatedQuestion['author_is_verified'] = (bool)$updatedQuestion['author_is_verified'];
        $updatedQuestion['is_resolved'] = $updatedQuestion['answer_count'] > 0;

        if ($updatedQuestion['tags']) {
            $updatedQuestion['tags'] = json_decode($updatedQuestion['tags']);
        } else {
            $updatedQuestion['tags'] = [];
        }
        
        if ($updatedQuestion['images']) {
            $updatedQuestion['images'] = json_decode($updatedQuestion['images']);
        } else {
            $updatedQuestion['images'] = [];
        }
        
        sendJsonResponse(true, "Question updated successfully.", $updatedQuestion);
    } else {
        sendJsonResponse(false, "Question updated but failed to retrieve.", [], 500);
    }

} catch (PDOException $e) {
    error_log("Error updating question: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
} catch (Exception $e) {
    error_log("An unexpected error occurred: " . $e->getMessage());
    sendJsonResponse(false, "An unexpected error occurred: " . $e->getMessage(), [], 500);
}
?>
