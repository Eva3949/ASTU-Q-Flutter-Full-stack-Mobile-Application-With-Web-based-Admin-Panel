<?php
/**
 * Database Connection File
 * Sami Backend
 */

// Database credentials
$host = 'evadevstudio.com';
$db_name = 'evadevih_astu_q_user';
$username = 'evadevih_astu_q';
$password = 'eva_3949@3949'; //eva_3949
$charset = 'utf8mb4';

$dsn = "mysql:host={$host};dbname={$db_name};charset={$charset}";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
];

try {
    $pdo = new PDO($dsn, $username, $password, $options);
} catch (PDOException $e) {
    // Log the error instead of dying
    error_log("Database connection failed: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed.'
    ]);
    exit;
}
?>