<?php
/**
 * Mark All Notifications as Read API
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
$userId = $data['user_id'] ?? null;

if (!$userId) {
    sendJsonResponse(false, "Missing required field: user_id.", [], 400);
}

try {
    $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1, read_at = NOW() WHERE user_id = :user_id AND is_read = 0");
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();

    sendJsonResponse(true, "All notifications marked as read.");

} catch (PDOException $e) {
    error_log("Error marking all notifications as read: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
