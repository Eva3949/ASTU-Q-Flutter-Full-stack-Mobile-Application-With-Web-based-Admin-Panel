<?php
/**
 * User Login Endpoint
 * Sami Backend
 */

// Include database connection
require_once 'db_connection.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Function to send JSON response
function sendJsonResponse($data, $status_code = 200) {
    if (isset($data['success']) && $data['success'] === false && $status_code === 200) {
        $status_code = 400; // Default to 400 Bad Request for client-side errors
    }
    http_response_code($status_code);
    echo json_encode($data);
    exit;
}

// Get JSON input
$json_input = file_get_contents('php://input');
$data = json_decode($json_input, true);

// Extract data
$email = $data['email'] ?? ''; // Flutter sends email for login
$password = $data['password'] ?? '';

try {
    // Basic validation
    if (empty($email) || empty($password)) {
        sendJsonResponse(['success' => false, 'message' => 'Email and password are required'], 400);
    }

    // Find user by email or username
    $stmt = $pdo->prepare("SELECT * FROM users WHERE (username = ? OR email = ?) AND status = 'active'");
    $stmt->execute([$email, $email]); // Use email for both username and email check
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password'])) {
        sendJsonResponse(['success' => false, 'message' => 'Invalid credentials'], 401); // 401 Unauthorized
    }

    // Generate token
    $token = bin2hex(random_bytes(32));
    $expires_at = date('Y-m-d H:i:s', strtotime('+30 days'));

    // Store token
    $stmt = $pdo->prepare("INSERT INTO auth_tokens (user_id, token, expires_at, created_at) VALUES (?, ?, ?, NOW())");
    $stmt->execute([$user['user_id'], $token, $expires_at]);

    // Update last login
    $stmt = $pdo->prepare("UPDATE users SET last_login_at = NOW() WHERE user_id = ?");
    $stmt->execute([$user['user_id']]);

    // Remove password from response
    unset($user['password']);

    sendJsonResponse([
        'success' => true,
        'message' => 'Login successful',
        'data' => [
            'user' => $user,
            'token' => $token,
            'expires_at' => $expires_at
        ]
    ]);

} catch (PDOException $e) {
    error_log("Login failed: " . $e->getMessage());
    sendJsonResponse(['success' => false, 'message' => 'Login failed due to database error: ' . $e->getMessage()], 500);
} catch (Exception $e) {
    error_log("Login failed: " . $e->getMessage());
    sendJsonResponse(['success' => false, 'message' => 'Login failed: ' . $e->getMessage()], 500);
}
?>