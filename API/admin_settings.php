<?php
/**
 * Admin Settings System
 * ASTU-Q Admin Control Panel - System Configuration
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

require_once 'db_connection.php';

// Check admin session
session_start();
if (!isset($_SESSION['admin_logged_in'])) {
    sendJsonResponse(false, "Unauthorized access", [], 401);
}

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

$action = $_GET['action'] ?? 'get';

try {
    switch ($action) {
        case 'get':
            // Get current system settings
            $stmt = $pdo->prepare("
                SELECT * FROM system_settings 
                ORDER BY category, setting_key
            ");
            $stmt->execute();
            $settings = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Group settings by category
            $groupedSettings = [];
            foreach ($settings as $setting) {
                $groupedSettings[$setting['category']][] = $setting;
            }
            
            sendJsonResponse(true, "Settings retrieved successfully", $groupedSettings);
            break;
            
        case 'update':
            $category = $_POST['category'] ?? '';
            $settings = $_POST['settings'] ?? [];
            
            if (!$category || empty($settings)) {
                sendJsonResponse(false, "Category and settings are required", [], 400);
            }
            
            // Update settings
            $pdo->beginTransaction();
            try {
                foreach ($settings as $key => $value) {
                    $stmt = $pdo->prepare("
                        INSERT INTO system_settings (category, setting_key, setting_value, updated_at) 
                        VALUES (:category, :key, :value, NOW())
                        ON DUPLICATE KEY UPDATE 
                        setting_value = :value, updated_at = NOW()
                    ");
                    $stmt->bindParam(':category', $category);
                    $stmt->bindParam(':key', $key);
                    $stmt->bindParam(':value', $value);
                    $stmt->execute();
                }
                
                $pdo->commit();
                sendJsonResponse(true, "Settings updated successfully");
            } catch (Exception $e) {
                $pdo->rollBack();
                sendJsonResponse(false, "Failed to update settings: " . $e->getMessage(), [], 500);
            }
            break;
            
        case 'toggle_feature':
            $feature = $_POST['feature'] ?? '';
            $enabled = $_POST['enabled'] ?? false;
            
            if (!$feature) {
                sendJsonResponse(false, "Feature name is required", [], 400);
            }
            
            // Update feature toggle
            $stmt = $pdo->prepare("
                INSERT INTO system_settings (category, setting_key, setting_value, updated_at) 
                VALUES ('features', :feature, :enabled, NOW())
                ON DUPLICATE KEY UPDATE 
                setting_value = :enabled, updated_at = NOW()
            ");
            $stmt->bindParam(':feature', $feature);
            $stmt->bindParam(':enabled', $enabled ? '1' : '0');
            $stmt->execute();
            
            sendJsonResponse(true, "Feature toggle updated successfully");
            break;
            
        default:
            sendJsonResponse(false, "Invalid action", [], 400);
    }
    
} catch (PDOException $e) {
    error_log("Database error: " . $e->getMessage());
    sendJsonResponse(false, "Database error occurred", [], 500);
} catch (Exception $e) {
    error_log("General error: " . $e->getMessage());
    sendJsonResponse(false, "An error occurred", [], 500);
}
?>
