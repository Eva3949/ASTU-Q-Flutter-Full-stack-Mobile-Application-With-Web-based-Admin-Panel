<?php
/**
 * Create Report API
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
$type = $data['reported_item_type'] ?? null; // 'question', 'answer', 'user'
$itemId = $data['reported_item_id'] ?? null;
$reporterId = $data['reporter_id'] ?? null;
$reason = $data['reason'] ?? null;
$description = $data['description'] ?? null;

if (!$type || !$itemId || !$reporterId || !$reason) {
    sendJsonResponse(false, "Missing required fields.", [], 400);
}

try {
    $stmt = $pdo->prepare("INSERT INTO reports (reported_item_type, reported_item_id, reporter_id, reason, description, status, created_at) 
                            VALUES (:type, :item_id, :reporter_id, :reason, :description, 'pending', NOW())");
    $stmt->bindParam(':type', $type);
    $stmt->bindParam(':item_id', $itemId, PDO::PARAM_INT);
    $stmt->bindParam(':reporter_id', $reporterId, PDO::PARAM_INT);
    $stmt->bindParam(':reason', $reason);
    $stmt->bindParam(':description', $description);
    $stmt->execute();

    sendJsonResponse(true, "Report submitted successfully.", ['report_id' => $pdo->lastInsertId()]);
} catch (PDOException $e) {
    sendJsonResponse(false, "Database error: " . $e->getMessage(), [], 500);
}
?>
