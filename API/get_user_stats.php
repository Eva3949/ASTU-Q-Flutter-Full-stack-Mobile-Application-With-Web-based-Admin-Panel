<?php
/**
 * User Stats API
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
    // Questions count
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM questions WHERE user_id = :user_id AND status != 'deleted'");
    $stmt->execute([':user_id' => $userId]);
    $questionsCount = (int)$stmt->fetchColumn();

    // Answers count
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM answers WHERE user_id = :user_id AND status != 'deleted'");
    $stmt->execute([':user_id' => $userId]);
    $answersCount = (int)$stmt->fetchColumn();

    // Best answers count
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM answers WHERE user_id = :user_id AND is_best = 1 AND status != 'deleted'");
    $stmt->execute([':user_id' => $userId]);
    $bestAnswersCount = (int)$stmt->fetchColumn();

    // Total points
    $stmt = $pdo->prepare("SELECT SUM(points) FROM user_points WHERE user_id = :user_id");
    $stmt->execute([':user_id' => $userId]);
    $totalPoints = (int)$stmt->fetchColumn();

    sendJsonResponse(true, "User stats fetched successfully.", [
        'questions_count' => $questionsCount,
        'answers_count' => $answersCount,
        'best_answers_count' => $bestAnswersCount,
        'total_points' => $totalPoints
    ]);
} catch (PDOException $e) {
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
