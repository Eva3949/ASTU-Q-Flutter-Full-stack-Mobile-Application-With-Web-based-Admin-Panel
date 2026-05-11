<?php
/**
 * Create Answer API
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

$questionId = $data['question_id'] ?? null;
$userId = $data['user_id'] ?? null;
$content = $data['content'] ?? null;

if (!$questionId || !$userId || !$content) {
    $missing = [];
    if (!$questionId) $missing[] = 'question_id';
    if (!$userId) $missing[] = 'user_id';
    if (!$content) $missing[] = 'content';
    sendJsonResponse(false, "Missing required fields: " . implode(', ', $missing), [], 400);
}

try {
    // Check if question exists
    $stmt = $pdo->prepare("SELECT question_id FROM questions WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();
    if (!$stmt->fetch()) {
        sendJsonResponse(false, "Question not found.", [], 404);
    }

    // Insert answer
    $stmt = $pdo->prepare(
        "INSERT INTO answers (question_id, user_id, content, status, created_at, updated_at) 
         VALUES (:question_id, :user_id, :content, 'approved', NOW(), NOW())"
    );
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':content', $content, PDO::PARAM_STR);
    $stmt->execute();

    $newAnswerId = $pdo->lastInsertId();

    // Increment answer count in questions table
    $stmt = $pdo->prepare("UPDATE questions SET answer_count = answer_count + 1 WHERE question_id = :question_id");
    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
    $stmt->execute();

    // 2. Create Notification for question author
    try {
        // Get question details to find author and title
        $qStmt = $pdo->prepare("SELECT user_id, title FROM questions WHERE question_id = :question_id");
        $qStmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
        $qStmt->execute();
        $questionData = $qStmt->fetch(PDO::FETCH_ASSOC);

        if ($questionData && $questionData['user_id'] != $userId) {
            $authorId = $questionData['user_id'];
            $qTitle = $questionData['title'];
            $notifTitle = "New Answer Received";
            $notifMessage = "Your question '$qTitle' has a new answer.";
            
            // Check if 'data' column exists before inserting
            $checkCol = $pdo->query("SHOW COLUMNS FROM notifications LIKE 'data'");
            $hasDataCol = $checkCol->rowCount() > 0;
            
            if ($hasDataCol) {
                $notifData = json_encode(['question_id' => (int)$questionId, 'answer_id' => (int)$newAnswerId]);
                $notifStmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, message, data, priority, created_at) 
                                           VALUES (:user_id, 'system', :title, :message, :data, 'medium', NOW())");
                $notifStmt->bindParam(':data', $notifData, PDO::PARAM_STR);
            } else {
                $notifStmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, message, priority, created_at) 
                                           VALUES (:user_id, 'system', :title, :message, 'medium', NOW())");
            }
            
            $notifStmt->bindParam(':user_id', $authorId, PDO::PARAM_INT);
            $notifStmt->bindParam(':title', $notifTitle, PDO::PARAM_STR);
            $notifStmt->bindParam(':message', $notifMessage, PDO::PARAM_STR);
            $notifStmt->execute();
        }
    } catch (PDOException $e) {
        error_log("Failed to create notification: " . $e->getMessage());
    }

    // 3. Add points for answering (3 points)
    try {
        // a. Insert into user_points table for history
        $stmt = $pdo->prepare("INSERT INTO user_points (user_id, points, reason, reference_id, created_at) VALUES (:user_id, 3, 'answer_posted', :source_id, NOW())");
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':source_id', $newAnswerId, PDO::PARAM_INT);
        $stmt->execute();
    } catch (PDOException $e) {
        error_log("Failed to add points: " . $e->getMessage());
    }

    // Clear existing accepted answer from question if any (handled by answers is_best now)

    // Fetch the newly created answer with author details
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
    $stmt->bindParam(':answer_id', $newAnswerId, PDO::PARAM_INT);
    $stmt->execute();
    $newAnswer = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($newAnswer) {
        // Format types for Flutter
        $newAnswer['id'] = (int)$newAnswer['id'];
        $newAnswer['question_id'] = (int)$newAnswer['question_id'];
        $newAnswer['author_id'] = (string)$newAnswer['author_id'];
        $newAnswer['upvotes'] = (int)$newAnswer['upvotes'];
        $newAnswer['downvotes'] = (int)$newAnswer['downvotes'];
        $newAnswer['is_best'] = (bool)$newAnswer['is_best'];
        $newAnswer['author_is_verified'] = (bool)$newAnswer['author_is_verified'];
        $newAnswer['is_upvoted'] = false;
        $newAnswer['is_downvoted'] = false;
        $newAnswer['images'] = []; // Schema doesn't have images for answers yet, but entity expects it

        sendJsonResponse(true, "Answer created successfully.", $newAnswer, 201);
    } else {
        sendJsonResponse(false, "Failed to retrieve new answer.", [], 500);
    }

} catch (PDOException $e) {
    error_log("Error creating answer: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
