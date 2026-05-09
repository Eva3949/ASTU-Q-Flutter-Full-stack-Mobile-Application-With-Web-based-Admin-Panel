<?php
/**
 * User Registration Endpoint
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
$name = $data['name'] ?? '';
$username = $data['username'] ?? '';
$email = $data['email'] ?? '';
$password = $data['password'] ?? '';
$password_confirmation = $data['password_confirmation'] ?? ''; // Flutter sends this, but PHP won't use it for hashing

try {
    // Basic validation
    $errors = [];
    if (empty($name)) $errors[] = 'Name is required';
    if (empty($username)) $errors[] = 'Username is required';
    if (strlen($username) < 3) $errors[] = 'Username must be at least 3 characters';
    if (strlen($username) > 20) $errors[] = 'Username must not exceed 20 characters';
    if (!preg_match('/^[a-zA-Z][a-zA-Z0-9_-]*$/', $username)) $errors[] = 'Username must start with a letter and contain only letters, numbers, underscores, and hyphens';
    if (empty($email)) $errors[] = 'Email is required';
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = 'Invalid email format';
    if (empty($password)) $errors[] = 'Password is required';
    if (strlen($password) < 8) $errors[] = 'Password must be at least 8 characters long';
    if ($password !== $password_confirmation) $errors[] = 'Passwords do not match';

    if (!empty($errors)) {
        sendJsonResponse(['success' => false, 'message' => 'Validation failed', 'errors' => $errors], 400);
    }

    // Derive first_name, last_name
    $name_parts = explode(' ', $name, 2);
    $first_name = $name_parts[0];
    $last_name = isset($name_parts[1]) ? $name_parts[1] : '';

    // Check if user already exists
    $stmt = $pdo->prepare("SELECT user_id FROM users WHERE username = ? OR email = ?");
    $stmt->execute([$username, $email]);
    if ($stmt->fetch()) {
        sendJsonResponse(['success' => false, 'message' => 'Username or email already exists'], 409); // 409 Conflict
    }

    // Hash password
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    // Insert new user
    $stmt = $pdo->prepare("INSERT INTO users (username, email, password, first_name, last_name, role, level, status, created_at, updated_at) 
                           VALUES (?, ?, ?, ?, ?, 'user', 1, 'active', NOW(), NOW())");
    $stmt->execute([$username, $email, $hashed_password, $first_name, $last_name]);
    $user_id = $pdo->lastInsertId();

    // Generate token for immediate login after signup
    $token = bin2hex(random_bytes(32));
    $expires_at = date('Y-m-d H:i:s', strtotime('+30 days'));

    // Store token
    $stmtToken = $pdo->prepare("INSERT INTO auth_tokens (user_id, token, expires_at, created_at) VALUES (?, ?, ?, NOW())");
    $stmtToken->execute([$user_id, $token, $expires_at]);

    // Get the created user (excluding password)
    $stmt = $pdo->prepare("SELECT user_id, username, email, first_name, last_name, role, level, profile_picture, bio, status, created_at, updated_at FROM users WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();

    if ($user) {
        // Format types for Flutter compatibility
        $user['user_id'] = (int)$user['user_id'];
        $user['level'] = (int)$user['level'];
        
        sendJsonResponse([
            'success' => true,
            'message' => 'User registered successfully',
            'data' => [
                'user' => $user,
                'token' => $token,
                'expires_at' => $expires_at
            ]
        ], 201); // 201 Created
    } else {
        sendJsonResponse(['success' => false, 'message' => 'User registered but failed to retrieve'], 500);
    }

} catch (PDOException $e) {
    error_log("Registration failed: " . $e->getMessage());
    sendJsonResponse(['success' => false, 'message' => 'Registration failed due to database error: ' . $e->getMessage()], 500);
} catch (Exception $e) {
    error_log("Registration failed: " . $e->getMessage());
    sendJsonResponse(['success' => false, 'message' => 'Registration failed: ' . $e->getMessage()], 500);
}
?>