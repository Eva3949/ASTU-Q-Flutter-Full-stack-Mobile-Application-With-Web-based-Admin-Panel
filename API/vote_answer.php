<?php
/**
 * Vote Answer API
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
$voteType = $data['vote_type'] ?? null; // 'up' or 'down'

if (!$answerId || !$userId || !$voteType) {
    sendJsonResponse(false, "Missing required fields: answer_id, user_id, and vote_type are required.", [], 400);
}

if (!in_array($voteType, ['up', 'down'])) {
    sendJsonResponse(false, "Invalid vote_type. Must be 'up' or 'down'.", [], 400);
}

try {
    // Check if user has already voted
    $stmt = $pdo->prepare("SELECT vote_id, vote_type FROM answer_votes WHERE answer_id = :answer_id AND user_id = :user_id");
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $existingVote = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($existingVote) {
        if ($existingVote['vote_type'] === $voteType) {
            // Remove vote if same type (toggle off)
            $stmt = $pdo->prepare("DELETE FROM answer_votes WHERE vote_id = :vote_id");
            $stmt->bindParam(':vote_id', $existingVote['vote_id'], PDO::PARAM_INT);
            $stmt->execute();
            $message = "Vote removed.";
        } else {
            // Change vote type
            $stmt = $pdo->prepare("UPDATE answer_votes SET vote_type = :vote_type WHERE vote_id = :vote_id");
            $stmt->bindParam(':vote_type', $voteType, PDO::PARAM_STR);
            $stmt->bindParam(':vote_id', $existingVote['vote_id'], PDO::PARAM_INT);
            $stmt->execute();
            $message = "Vote updated to $voteType.";

            // Notification for upvote change
            if ($voteType === 'up') {
                createAnswerVoteNotification($pdo, $answerId, $userId);
            }
        }
    } else {
        // New vote
        $stmt = $pdo->prepare("INSERT INTO answer_votes (answer_id, user_id, vote_type, created_at) VALUES (:answer_id, :user_id, :vote_type, NOW())");
        $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':vote_type', $voteType, PDO::PARAM_STR);
        $stmt->execute();
        $message = "Vote cast as $voteType.";

        // Notification for new upvote
        if ($voteType === 'up') {
            createAnswerVoteNotification($pdo, $answerId, $userId);
        }
    }

    // Fetch updated counts (triggers in DB handle the actual count updates in answers table)
    $stmt = $pdo->prepare("SELECT upvotes, downvotes FROM answers WHERE answer_id = :answer_id");
    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
    $stmt->execute();
    $counts = $stmt->fetch(PDO::FETCH_ASSOC);

    sendJsonResponse(true, $message, [
        'upvotes' => (int)$counts['upvotes'],
        'downvotes' => (int)$counts['downvotes']
    ]);

} catch (PDOException $e) {
    error_log("Error voting on answer: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}

/**
 * Helper function to create answer vote notification
 */
function createAnswerVoteNotification($pdo, $answerId, $userId) {
    try {
        // Get answer author and question ID
        $aStmt = $pdo->prepare("SELECT user_id, question_id FROM answers WHERE answer_id = :answer_id");
        $aStmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
        $aStmt->execute();
        $answerData = $aStmt->fetch(PDO::FETCH_ASSOC);

        if ($answerData && $answerData['user_id'] != $userId) {
            $authorId = $answerData['user_id'];
            $questionId = $answerData['question_id'];
            
            $notifTitle = "Answer Upvoted";
            $notifMessage = "Your answer received an upvote!";
            
            // Check if 'data' column exists before inserting
            $checkCol = $pdo->query("SHOW COLUMNS FROM notifications LIKE 'data'");
            $hasDataCol = $checkCol->rowCount() > 0;
            
            if ($hasDataCol) {
                $notifData = json_encode(['question_id' => (int)$questionId, 'answer_id' => (int)$answerId]);
                $notifStmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, message, data, priority, created_at) 
                                           VALUES (:user_id, 'system', :title, :message, :data, 'low', NOW())");
                $notifStmt->bindParam(':data', $notifData, PDO::PARAM_STR);
            } else {
                $notifStmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, message, priority, created_at) 
                                           VALUES (:user_id, 'system', :title, :message, 'low', NOW())");
            }
            
            $notifStmt->bindParam(':user_id', $authorId, PDO::PARAM_INT);
            $notifStmt->bindParam(':title', $notifTitle, PDO::PARAM_STR);
            $notifStmt->bindParam(':message', $notifMessage, PDO::PARAM_STR);
            $notifStmt->execute();
        }
    } catch (Exception $e) {
        error_log("Failed to create answer vote notification: " . $e->getMessage());
    }
}
?>
