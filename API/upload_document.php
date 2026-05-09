<?php
/**
 * Document Upload API
 * Sami Backend
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

function sendJsonResponse($success, $message, $data = [], $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode(['success' => $success, 'message' => $message, 'data' => $data]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') sendJsonResponse(true, "Options request handled");

$uploadDir = 'uploads/documents/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

if (!isset($_FILES['file'])) {
    sendJsonResponse(false, "No document uploaded.", [], 400);
}

$file = $_FILES['file'];
$fileName = time() . '_' . basename($file['name']);
$targetPath = $uploadDir . $fileName;

// Document validation
$allowedExtensions = ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'];
$fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

if (!in_array($fileExtension, $allowedExtensions)) {
    sendJsonResponse(false, "Invalid document type. Allowed: " . implode(', ', $allowedExtensions), [], 400);
}

if (move_uploaded_file($file['tmp_name'], $targetPath)) {
    $fileUrl = 'https://evadevstudio.com/sami/' . $targetPath;
    sendJsonResponse(true, "Document uploaded successfully.", ['url' => $fileUrl]);
} else {
    sendJsonResponse(false, "Failed to move uploaded document.", [], 500);
}
?>
