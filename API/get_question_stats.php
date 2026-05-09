<?php
/**
 * Question Stats API
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

try {
    // Total questions
    $totalQuestions = (int)$pdo->query("SELECT COUNT(*) FROM questions WHERE status != 'deleted'")->fetchColumn();

    // Total answers
    $totalAnswers = (int)$pdo->query("SELECT COUNT(*) FROM answers WHERE status != 'deleted'")->fetchColumn();

    // Pending questions
    $pendingQuestions = (int)$pdo->query("SELECT COUNT(*) FROM questions WHERE status = 'pending'")->fetchColumn();

    // Questions by subject
    $stmt = $pdo->query("SELECT subject, COUNT(*) as count FROM questions WHERE status != 'deleted' GROUP BY subject ORDER BY count DESC LIMIT 5");
    $bySubject = $stmt->fetchAll(PDO::FETCH_ASSOC);

    sendJsonResponse(true, "Question stats fetched successfully.", [
        'total_questions' => $totalQuestions,
        'total_answers' => $totalAnswers,
        'pending_questions' => $pendingQuestions,
        'by_subject' => $bySubject
    ]);
} catch (PDOException $e) {
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
