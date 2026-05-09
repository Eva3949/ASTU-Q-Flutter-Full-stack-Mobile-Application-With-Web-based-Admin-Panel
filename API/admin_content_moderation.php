<?php
/**
 * Admin Content Moderation System
 * ASTU-Q Admin Control Panel - Content Management
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

require_once 'db_connection.php';

// Check admin session
session_start();
if (!isset($_SESSION['admin_logged_in'])) {
    sendJsonResponse(false, "Unauthorized access", [], 401);
}

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

$action = $_GET['action'] ?? 'list';

try {
    switch ($action) {
        case 'list':
            // Get flagged content with pagination
            $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
            $limit = 10;
            $offset = ($page - 1) * $limit;
            $contentType = $_GET['content_type'] ?? 'all';
            $status = $_GET['status'] ?? 'flagged';
            
            $whereClause = "1=1";
            $params = [];
            
            if ($contentType !== 'all') {
                $whereClause .= " AND content_type = :content_type";
                $params[':content_type'] = $contentType;
            }
            
            if ($status !== 'all') {
                $whereClause .= " AND status = :status";
                $params[':status'] = $status;
            }
            
            // Get questions
            $questionStmt = $pdo->prepare("
                SELECT q.*, u.username as author_name 
                FROM questions q 
                LEFT JOIN users u ON q.user_id = u.user_id 
                WHERE $whereClause
                ORDER BY q.created_at DESC 
                LIMIT :limit OFFSET :offset
            ");
            
            foreach ($params as $key => $value) {
                $questionStmt->bindValue($key, $value);
            }
            $questionStmt->execute();
            $questions = $questionStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get answers
            $answerStmt = $pdo->prepare("
                SELECT a.*, q.title as question_title, u.username as author_name 
                FROM answers a 
                LEFT JOIN questions q ON a.question_id = q.question_id 
                LEFT JOIN users u ON a.user_id = u.user_id 
                WHERE $whereClause
                ORDER BY a.created_at DESC 
                LIMIT :limit OFFSET :offset
            ");
            
            foreach ($params as $key => $value) {
                $answerStmt->bindValue($key, $value);
            }
            $answerStmt->execute();
            $answers = $answerStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Combine all content
            $content = array_merge($questions, $answers);
            
            // Sort by created_at
            usort($content, function($a, $b) {
                return strtotime($b['created_at']) - strtotime($a['created_at']);
            });
            
            // Get total count
            $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM questions WHERE $whereClause UNION SELECT COUNT(*) FROM answers WHERE $whereClause");
            foreach ($params as $key => $value) {
                $countStmt->bindValue($key, $value);
            }
            $countStmt->execute();
            $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            sendJsonResponse(true, "Content retrieved", [
                'content' => $content,
                'pagination' => [
                    'current_page' => $page,
                    'total_pages' => ceil($total / $limit),
                    'total_items' => (int)$total,
                    'items_per_page' => $limit
                ]
            ]);
            break;
            
        case 'review':
            $contentId = $_GET['content_id'] ?? null;
            $contentType = $_GET['content_type'] ?? 'question';
            
            if (!$contentId) {
                sendJsonResponse(false, "Content ID is required", [], 400);
            }
            
            // Get content details
            if ($contentType === 'question') {
                $stmt = $pdo->prepare("
                    SELECT q.*, u.username as author_name 
                    FROM questions q 
                    LEFT JOIN users u ON q.user_id = u.user_id 
                    WHERE q.question_id = :content_id
                ");
            } else {
                $stmt = $pdo->prepare("
                    SELECT a.*, q.title as question_title, u.username as author_name 
                    FROM answers a 
                    LEFT JOIN questions q ON a.question_id = q.question_id 
                    LEFT JOIN users u ON a.user_id = u.user_id 
                    WHERE a.answer_id = :content_id
                ");
            }
            
            $stmt->bindParam(':content_id', $contentId, PDO::PARAM_INT);
            $stmt->execute();
            $content = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($content) {
                sendJsonResponse(true, "Content details retrieved", $content);
            } else {
                sendJsonResponse(false, "Content not found", [], 404);
            }
            break;
            
        case 'approve':
            $contentId = $_POST['content_id'] ?? null;
            $contentType = $_POST['content_type'] ?? 'question';
            
            if (!$contentId) {
                sendJsonResponse(false, "Content ID is required", [], 400);
            }
            
            // Approve content
            if ($contentType === 'question') {
                $stmt = $pdo->prepare("UPDATE questions SET status = 'approved', approved_at = NOW() WHERE question_id = :content_id");
            } else {
                $stmt = $pdo->prepare("UPDATE answers SET status = 'approved', approved_at = NOW() WHERE answer_id = :content_id");
            }
            $stmt->bindParam(':content_id', $contentId, PDO::PARAM_INT);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                sendJsonResponse(true, "Content approved successfully");
            } else {
                sendJsonResponse(false, "Content not found", [], 404);
            }
            break;
            
        case 'reject':
            $contentId = $_POST['content_id'] ?? null;
            $contentType = $_POST['content_type'] ?? 'question';
            $reason = $_POST['reason'] ?? '';
            
            if (!$contentId) {
                sendJsonResponse(false, "Content ID is required", [], 400);
            }
            
            // Reject content
            if ($contentType === 'question') {
                $stmt = $pdo->prepare("UPDATE questions SET status = 'rejected', rejection_reason = :reason WHERE question_id = :content_id");
            } else {
                $stmt = $pdo->prepare("UPDATE answers SET status = 'rejected', rejection_reason = :reason WHERE answer_id = :content_id");
            }
            $stmt->bindParam(':content_id', $contentId, PDO::PARAM_INT);
            $stmt->bindParam(':reason', $reason, PDO::PARAM_STR);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                sendJsonResponse(true, "Content rejected successfully");
            } else {
                sendJsonResponse(false, "Content not found", [], 404);
            }
            break;
            
        case 'delete':
            $contentId = $_POST['content_id'] ?? null;
            $contentType = $_POST['content_type'] ?? 'question';
            
            if (!$contentId) {
                sendJsonResponse(false, "Content ID is required", [], 400);
            }
            
            // Delete content
            if ($contentType === 'question') {
                $stmt = $pdo->prepare("UPDATE questions SET status = 'deleted', updated_at = NOW() WHERE question_id = :content_id");
            } else {
                $stmt = $pdo->prepare("UPDATE answers SET status = 'deleted', updated_at = NOW() WHERE answer_id = :content_id");
            }
            $stmt->bindParam(':content_id', $contentId, PDO::PARAM_INT);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                sendJsonResponse(true, "Content deleted successfully");
            } else {
                sendJsonResponse(false, "Content not found", [], 404);
            }
            break;
            
        default:
            sendJsonResponse(false, "Invalid action", [], 400);
    }
    
} catch (PDOException $e) {
    error_log("Database error: " . $e->getMessage());
    sendJsonResponse(false, "Database error occurred", [], 500);
} catch (Exception $e) {
    error_log("General error: " . $e->getMessage());
    sendJsonResponse(false, "An error occurred", [], 500);
}
?>
