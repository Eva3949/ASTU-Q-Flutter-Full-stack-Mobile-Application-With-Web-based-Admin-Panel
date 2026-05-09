<?php
/**
 * Get User Profile API
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

require_once 'db_connection.php';

function sendJsonResponse($success, $message, $data = [], $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode(['success' => $success, 'message' => $message, 'data' => $data]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') sendJsonResponse(true, "Options request handled");

$userId = $_GET['user_id'] ?? null;

if (!$userId) sendJsonResponse(false, "User ID is required.", [], 400);

try {
    $stmt = $pdo->prepare("SELECT user_id, username, email, first_name, last_name, role, level, profile_picture, bio, status, created_at, updated_at FROM users WHERE user_id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        sendJsonResponse(false, "User not found.", [], 404);
    }

    // Format types for Flutter compatibility
    $user['user_id'] = (int)$user['user_id'];
    $user['level'] = (int)$user['level'];
    
    // Fetch real points from user_points table
    $stmtPoints = $pdo->prepare("SELECT COALESCE(SUM(points), 0) FROM user_points WHERE user_id = ?");
    $stmtPoints->execute([$userId]);
    $realPoints = (int)$stmtPoints->fetchColumn();
    $user['points'] = $realPoints;
    
    // Fetch counts
    $stmtQ = $pdo->prepare("SELECT COUNT(*) FROM questions WHERE user_id = ? AND status != 'deleted'");
    $stmtQ->execute([$userId]);
    $user['questions_count'] = (int)$stmtQ->fetchColumn();

    $stmtA = $pdo->prepare("SELECT COUNT(*) FROM answers WHERE user_id = ? AND status != 'deleted'");
    $stmtA->execute([$userId]);
    $user['answers_count'] = (int)$stmtA->fetchColumn();

    $stmtB = $pdo->prepare("SELECT COUNT(*) FROM answers WHERE user_id = ? AND is_best = 1 AND status != 'deleted'");
    $stmtB->execute([$userId]);
    $user['best_answers_count'] = (int)$stmtB->fetchColumn();
    
    $user['role'] = $user['role'] ? (string)$user['role'] : 'user';
    
    // Add missing optional fields for Flutter
    $user['email_verified_at'] = null;
    $user['last_login_at'] = null;
    
    // Ensure dates are strings
    $user['created_at'] = $user['created_at'] ? (string)$user['created_at'] : date('Y-m-d H:i:s');
    $user['updated_at'] = $user['updated_at'] ? (string)$user['updated_at'] : date('Y-m-d H:i:s');

    sendJsonResponse(true, "User profile fetched successfully.", $user);
} catch (PDOException $e) {
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
