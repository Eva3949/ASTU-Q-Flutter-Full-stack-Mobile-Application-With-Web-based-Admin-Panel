<?php
/**
 * Get Subjects API
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

try {
    // Get unique subjects from questions table
    $stmt = $pdo->query("SELECT DISTINCT subject FROM questions WHERE status != 'deleted' ORDER BY subject ASC");
    $subjects = $stmt->fetchAll(PDO::FETCH_COLUMN);

    // If no questions yet, return some default ones common in ASTU
    if (empty($subjects)) {
        $subjects = ['Mathematics', 'Physics', 'Computer Science', 'Electrical Engineering', 'Mechanical Engineering', 'Chemistry', 'Biology'];
    }

    sendJsonResponse(true, "Subjects fetched successfully.", $subjects);

} catch (PDOException $e) {
    error_log("Error fetching subjects: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
