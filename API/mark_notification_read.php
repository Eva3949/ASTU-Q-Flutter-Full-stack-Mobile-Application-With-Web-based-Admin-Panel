<?php
/**
 * Mark Notification as Read API
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

$data = json_decode(file_get_contents("php://input"), true);
$notificationId = $data['notification_id'] ?? null;
$userId = $data['user_id'] ?? null;

if (!$notificationId || !$userId) {
    sendJsonResponse(false, "Missing required fields: notification_id and user_id are required.", [], 400);
}

try {
    $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1, read_at = NOW() WHERE notification_id = :notification_id AND user_id = :user_id");
    $stmt->bindParam(':notification_id', $notificationId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        sendJsonResponse(true, "Notification marked as read.");
    } else {
        sendJsonResponse(false, "Notification not found or already read.", [], 404);
    }

} catch (PDOException $e) {
    error_log("Error marking notification as read: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
