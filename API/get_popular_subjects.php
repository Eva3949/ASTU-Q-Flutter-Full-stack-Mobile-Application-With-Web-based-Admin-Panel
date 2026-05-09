<?php
/**
 * Popular Subjects API
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
    $stmt = $pdo->query("SELECT subject, COUNT(*) as question_count 
                        FROM questions 
                        WHERE status != 'deleted' 
                        GROUP BY subject 
                        ORDER BY question_count DESC 
                        LIMIT 10");
    $popularSubjects = $stmt->fetchAll(PDO::FETCH_ASSOC);

    sendJsonResponse(true, "Popular subjects fetched successfully.", $popularSubjects);
} catch (PDOException $e) {
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
