<?php
/**
 * Create Question API
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

// Log incoming data for debugging
error_log("Create Question Request: " . print_r($data, true));

// Validate input
$userId = $data['user_id'] ?? null;
$title = $data['title'] ?? null;
$content = $data['content'] ?? null;
$subject = $data['subject'] ?? null;
$category = $data['category'] ?? null;
$tags = $data['tags'] ?? []; // Expect array, store as JSON
$images = $data['images'] ?? []; // Expect array, store as JSON

error_log("Images received: " . print_r($images, true));

if (!$userId || !$title || !$content || !$subject) {
    sendJsonResponse(false, "Missing required fields: user_id, title, content, subject are required.", [], 400);
}

// Check if user exists
try {
    $stmt = $pdo->prepare("SELECT user_id FROM users WHERE user_id = :user_id");
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    if (!$stmt->fetch()) {
        sendJsonResponse(false, "User not found.", [], 404);
    }
} catch (PDOException $e) {
    error_log("Database error checking user: " . $e->getMessage());
    sendJsonResponse(false, "Database error.", [], 500);
}

// Convert arrays to JSON strings for database storage
$tagsJson = json_encode($tags);
$imagesJson = json_encode($images);

error_log("Tags JSON: " . $tagsJson);
error_log("Images JSON: " . $imagesJson);

try {
    $stmt = $pdo->prepare(
        "INSERT INTO questions (user_id, title, content, subject, category, tags, images, status, created_at, updated_at)
         VALUES (:user_id, :title, :content, :subject, :category, :tags, :images, 'pending', NOW(), NOW())"
    );
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':title', $title, PDO::PARAM_STR);
    $stmt->bindParam(':content', $content, PDO::PARAM_STR);
    $stmt->bindParam(':subject', $subject, PDO::PARAM_STR);
    $stmt->bindParam(':category', $category, PDO::PARAM_STR);
    $stmt->bindParam(':tags', $tagsJson, PDO::PARAM_STR);
    $stmt->bindParam(':images', $imagesJson, PDO::PARAM_STR);

    $stmt->execute();
    error_log("Question inserted successfully. ID: " . $pdo->lastInsertId());

    $newQuestionId = $pdo->lastInsertId();

    // 2. Add points for asking (e.g., 10 points)
    try {
        $stmt = $pdo->prepare("INSERT INTO user_points (user_id, points, type, source_id, created_at) VALUES (:user_id, 10, 'question', :source_id, NOW())");
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':source_id', $newQuestionId, PDO::PARAM_INT);
        $stmt->execute();
    } catch (PDOException $e) {
        // Table might not exist or other error, log it but don't fail question creation
        error_log("Failed to add points: " . $e->getMessage());
    }

    // Fetch the newly created question with correct mapping
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
                                (SELECT answer_id FROM answers WHERE question_id = q.question_id AND is_best = 1 LIMIT 1) AS accepted_answer_id,
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
    $stmt->bindParam(':question_id', $newQuestionId, PDO::PARAM_INT);
    $stmt->execute();
    $newQuestion = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($newQuestion) {
        // Decode JSON fields and format types
        $newQuestion['id'] = (int)$newQuestion['id'];
        $newQuestion['author_id'] = (string)$newQuestion['author_id'];
        $newQuestion['accepted_answer_id'] = $newQuestion['accepted_answer_id'] ? (string)$newQuestion['accepted_answer_id'] : null;
        $newQuestion['view_count'] = (int)$newQuestion['view_count'];
        $newQuestion['upvotes'] = (int)$newQuestion['upvotes'];
        $newQuestion['downvotes'] = (int)$newQuestion['downvotes'];
        $newQuestion['answer_count'] = (int)$newQuestion['answer_count'];
        $newQuestion['featured'] = (bool)$newQuestion['featured'];
        $newQuestion['author_is_verified'] = (bool)$newQuestion['author_is_verified'];
        $newQuestion['is_upvoted'] = false;
        $newQuestion['is_downvoted'] = false;
        $newQuestion['is_bookmarked'] = false;
        $newQuestion['is_resolved'] = false;

        if ($newQuestion['tags']) {
            $newQuestion['tags'] = json_decode($newQuestion['tags']);
        } else {
            $newQuestion['tags'] = [];
        }
        
        if ($newQuestion['images']) {
            $newQuestion['images'] = json_decode($newQuestion['images']);
        } else {
            $newQuestion['images'] = [];
        }
        
        sendJsonResponse(true, "Question submitted successfully. It will be visible after admin approval.", $newQuestion, 201);
    } else {
        sendJsonResponse(false, "Failed to retrieve new question.", [], 500);
    }

} catch (PDOException $e) {
    error_log("Error creating question: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
} catch (Exception $e) {
    error_log("An unexpected error occurred: " . $e->getMessage());
    sendJsonResponse(false, "An unexpected error occurred: " . $e->getMessage(), [], 500);
}
?>
