<?php
/**
 * Get Notifications API
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

$userId = $_GET['user_id'] ?? null;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
$offset = ($page - 1) * $limit;

if (!$userId) {
    sendJsonResponse(false, "Missing required parameter: user_id.", [], 400);
}

try {
    // First, check if 'data' column exists in notifications table
    $checkColumn = $pdo->query("SHOW COLUMNS FROM notifications LIKE 'data'");
    $hasDataColumn = $checkColumn->rowCount() > 0;
    
    $query = "SELECT notification_id AS id, user_id, type, title, message, ";
    if ($hasDataColumn) {
        $query .= "data, ";
    }
    $query .= "priority, is_read, read_at, created_at 
               FROM notifications 
               WHERE user_id = :user_id 
               ORDER BY created_at DESC 
               LIMIT :limit OFFSET :offset";
               
    $stmt = $pdo->prepare($query);
    $stmt->bindValue(':user_id', (int)$userId, PDO::PARAM_INT);
    $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
    $stmt->execute();
    $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format types for Flutter
    foreach ($notifications as &$notification) {
        $notification['id'] = (int)$notification['id'];
        $notification['user_id'] = (int)$notification['user_id'];
        $notification['is_read'] = (bool)$notification['is_read'];
        
        // Handle metadata/data field safely
        $metadataRaw = isset($notification['data']) ? $notification['data'] : null;
        if ($metadataRaw) {
            $notification['metadata'] = json_decode($metadataRaw, true);
        } else {
            $notification['metadata'] = null;
        }
        
        // For Flutter entity compatibility
        $notification['related_id'] = (isset($notification['metadata']) && isset($notification['metadata']['question_id'])) 
            ? (int)$notification['metadata']['question_id'] 
            : null;
            
        // Ensure all string fields are strings (avoid null issues)
        $notification['title'] = (string)$notification['title'];
        $notification['message'] = (string)$notification['message'];
        $notification['type'] = (string)$notification['type'];
    }

    // Get total count
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM notifications WHERE user_id = :user_id");
    $stmt->bindValue(':user_id', (int)$userId, PDO::PARAM_INT);
    $stmt->execute();
    $total = (int)$stmt->fetchColumn();

    sendJsonResponse(true, "Notifications fetched successfully.", [
        'notifications' => $notifications,
        'total' => $total,
        'page' => $page,
        'limit' => $limit
    ]);

} catch (PDOException $e) {
    error_log("Error fetching notifications: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
