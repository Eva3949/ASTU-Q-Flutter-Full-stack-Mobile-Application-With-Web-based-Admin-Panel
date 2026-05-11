<?php
/**
 * Update Report API
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

require_once 'db_connection.php';

function sendJsonResponse($success, $message, $data = [], $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode(['success' => $success, 'message' => $message, 'data' => $data]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') sendJsonResponse(true, "Options request handled");

$data = json_decode(file_get_contents("php://input"), true);
$reportId = $data['report_id'] ?? null;
$status = $data['status'] ?? null; // 'reviewed', 'resolved', 'dismissed'
$adminId = $data['admin_id'] ?? null;
$notes = $data['review_notes'] ?? null;

if (!$reportId || !$status || !$adminId) {
    sendJsonResponse(false, "Missing required fields.", [], 400);
}

try {
    $stmt = $pdo->prepare("UPDATE reports SET status = :status, reviewed_by = :admin_id, reviewed_at = NOW(), review_notes = :notes 
                            WHERE report_id = :report_id");
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':admin_id', $adminId, PDO::PARAM_INT);
    $stmt->bindParam(':notes', $notes);
    $stmt->bindParam(':report_id', $reportId, PDO::PARAM_INT);
    $stmt->execute();

    sendJsonResponse(true, "Report updated successfully.");
} catch (PDOException $e) {
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
