<?php
/**
 * Get Subject Categories API
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

$subject = $_GET['subject'] ?? null;

try {
    if ($subject) {
        $stmt = $pdo->prepare("SELECT DISTINCT category FROM questions WHERE subject = :subject AND category IS NOT NULL AND status != 'deleted' ORDER BY category ASC");
        $stmt->bindParam(':subject', $subject, PDO::PARAM_STR);
        $stmt->execute();
    } else {
        $stmt = $pdo->query("SELECT DISTINCT category FROM questions WHERE category IS NOT NULL AND status != 'deleted' ORDER BY category ASC");
    }
    
    $categories = $stmt->fetchAll(PDO::FETCH_COLUMN);

    sendJsonResponse(true, "Categories fetched successfully.", $categories);

} catch (PDOException $e) {
    error_log("Error fetching categories: " . $e->getMessage());
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
