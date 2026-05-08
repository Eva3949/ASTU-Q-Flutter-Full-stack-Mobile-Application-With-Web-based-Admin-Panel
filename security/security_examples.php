<?php
/**
 * Security Implementation Examples
 * ASTU-Q Admin Panel
 * Practical Examples of Security Features
 */

require_once 'SecurityManager.php';
require_once 'InputValidator.php';

// Initialize security components
$security = SecurityManager::getInstance();
$validator = InputValidator::getInstance();

// Set security headers for all pages
$security->setSecurityHeaders();

// Initialize secure session
$security->initializeSecureSession();

/**
 * EXAMPLE 1: SECURE USER REGISTRATION
 */
function secureUserRegistration($userData) {
    global $validator, $security;
    
    try {
        // Validate input data
        $validatedData = $validator->validateUserProfile($userData);
        
        // Hash password securely
        $passwordHash = $security->hashPassword($validatedData['password']);
        
        // Insert user with prepared statement
        $sql = "INSERT INTO users (username, email, password_hash, first_name, last_name, phone, bio, created_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
        
        $stmt = $security->executeQuery($sql, [
            $validatedData['username'],
            $validatedData['email'],
            $passwordHash,
            $validatedData['first_name'],
            $validatedData['last_name'],
            $validatedData['phone'] ?? null,
            $validatedData['bio'] ?? null
        ]);
        
        // Get user ID
        $userId = $stmt->insert_id;
        
        // Assign role
        if (isset($validatedData['role_id'])) {
            $roleSql = "INSERT INTO user_roles (user_id, role_id, assigned_by, assigned_at) 
                       VALUES (?, ?, ?, NOW())";
            $security->executeQuery($roleSql, [$userId, $validatedData['role_id'], $_SESSION['admin_user']['user_id'] ?? null]);
        }
        
        return ['success' => true, 'user_id' => $userId];
        
    } catch (ValidationException $e) {
        return ['success' => false, 'errors' => $e->getErrors()];
    } catch (Exception $e) {
        error_log("Registration error: " . $e->getMessage());
        return ['success' => false, 'message' => 'Registration failed'];
    }
}

/**
 * EXAMPLE 2: SECURE LOGIN PROCESS
 */
function secureLoginProcess($username, $password, $mfaCode = null) {
    global $security;
    
    try {
        // Rate limiting check
        $security->checkRateLimit('login', 5, 300); // 5 attempts per 5 minutes
        
        // Input validation
        $username = $security->validateInput($username, 'username');
        $password = $security->validateInput($password, 'password');
        
        // Check login attempts
        $security->checkLoginAttempts($username);
        
        // CSRF validation
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $csrfToken = $_POST['csrf_token'] ?? '';
            if (!$security->validateCSRFToken($csrfToken)) {
                throw new SecurityException('CSRF token validation failed');
            }
        }
        
        // Get user with secure query
        $sql = "SELECT user_id, username, email, password_hash, first_name, last_name, 
                       status, mfa_enabled, last_login
                FROM users 
                WHERE username = ? AND status = 'active'";
        
        $stmt = $security->executeQuery($sql, [$username]);
        $user = $stmt->fetch_assoc();
        
        if (!$user || !$security->verifyPassword($password, $user['password_hash'])) {
            $security->recordFailedLogin($username);
            throw new SecurityException('Invalid credentials');
        }
        
        // MFA verification
        if ($user['mfa_enabled'] && !$verifyMFA($user['user_id'], $mfaCode)) {
            $security->recordFailedLogin($username);
            throw new SecurityException('Invalid MFA code');
        }
        
        // Success - update session
        session_regenerate_id(true);
        $_SESSION['admin_user'] = [
            'user_id' => $user['user_id'],
            'username' => $user['username'],
            'email' => $user['email'],
            'first_name' => $user['first_name'],
            'last_name' => $user['last_name'],
            'login_time' => time()
        ];
        
        // Clear failed attempts
        $security->clearFailedLogins($username);
        
        return ['success' => true, 'user' => $user];
        
    } catch (SecurityException $e) {
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

/**
 * EXAMPLE 3: SECURE DATA RETRIEVAL
 */
function secureGetUsers($page = 1, $limit = 25, $search = '', $status = '') {
    global $security, $validator;
    
    try {
        // Validate pagination
        $pagination = $validator->validatePagination($page, $limit);
        
        // Validate search query
        $search = $search ? $validator->validateSearchQuery($search) : '';
        
        // Validate status
        $allowedStatuses = ['active', 'banned', 'suspended', 'pending'];
        $status = in_array($status, $allowedStatuses) ? $status : '';
        
        // Build secure query
        $sql = "SELECT user_id, username, email, first_name, last_name, status, points, level, created_at
                FROM users 
                WHERE 1=1";
        
        $params = [];
        
        // Add search condition
        if ($search) {
            $sql .= " AND (username LIKE ? OR email LIKE ? OR first_name LIKE ? OR last_name LIKE ?)";
            $searchParam = "%{$search}%";
            $params = array_merge($params, [$searchParam, $searchParam, $searchParam, $searchParam]);
        }
        
        // Add status condition
        if ($status) {
            $sql .= " AND status = ?";
            $params[] = $status;
        }
        
        // Add pagination
        $sql .= " ORDER BY created_at DESC LIMIT ? OFFSET ?";
        $params[] = $pagination['limit'];
        $params[] = $pagination['offset'];
        
        // Execute secure query
        $stmt = $security->executeQuery($sql, $params);
        $users = $stmt->fetch_all(MYSQLI_ASSOC);
        
        // Sanitize output
        $users = $security->sanitizeOutput($users);
        
        return ['success' => true, 'data' => $users];
        
    } catch (Exception $e) {
        error_log("Get users error: " . $e->getMessage());
        return ['success' => false, 'message' => 'Failed to retrieve users'];
    }
}

/**
 * EXAMPLE 4: SECURE DATA UPDATE
 */
function secureUpdateUser($userId, $userData) {
    global $security, $validator;
    
    try {
        // Validate user ID
        $userId = $security->validateInput($userId, 'integer', ['min' => 1]);
        
        // Validate input data
        $validatedData = $validator->validateUserProfile($userData);
        
        // Get current user data for logging
        $currentSql = "SELECT * FROM users WHERE user_id = ?";
        $currentStmt = $security->executeQuery($currentSql, [$userId]);
        $currentUser = $currentStmt->fetch_assoc();
        
        if (!$currentUser) {
            throw new ValidationException('User not found');
        }
        
        // Build update query
        $updateFields = [];
        $params = [];
        
        $allowedFields = ['username', 'email', 'first_name', 'last_name', 'phone', 'bio', 'status'];
        
        foreach ($allowedFields as $field) {
            if (isset($validatedData[$field])) {
                $updateFields[] = "{$field} = ?";
                $params[] = $validatedData[$field];
            }
        }
        
        // Handle password change
        if (isset($validatedData['password'])) {
            $updateFields[] = "password_hash = ?";
            $params[] = $security->hashPassword($validatedData['password']);
        }
        
        if (empty($updateFields)) {
            throw new ValidationException('No valid fields to update');
        }
        
        $params[] = $userId;
        
        $sql = "UPDATE users SET " . implode(', ', $updateFields) . " WHERE user_id = ?";
        $security->executeQuery($sql, $params);
        
        // Log the action
        $security->logSecurityEvent('USER_UPDATE', [
            'user_id' => $userId,
            'admin_id' => $_SESSION['admin_user']['user_id'] ?? null,
            'changes' => array_diff_assoc($validatedData, $currentUser)
        ]);
        
        return ['success' => true, 'message' => 'User updated successfully'];
        
    } catch (ValidationException $e) {
        return ['success' => false, 'errors' => $e->getErrors()];
    } catch (Exception $e) {
        error_log("Update user error: " . $e->getMessage());
        return ['success' => false, 'message' => 'Failed to update user'];
    }
}

/**
 * EXAMPLE 5: SECURE BULK OPERATIONS
 */
function secureBulkUserAction($userIds, $action) {
    global $security, $validator;
    
    try {
        // Validate bulk operation
        $bulkData = $validator->validateBulkOperation($userIds, $action, ['ban', 'unban', 'delete']);
        
        // Start transaction
        $security->db->beginTransaction();
        
        $updatedCount = 0;
        
        foreach ($bulkData['ids'] as $userId) {
            try {
                switch ($bulkData['action']) {
                    case 'ban':
                        $sql = "UPDATE users SET status = 'banned', updated_at = NOW() WHERE user_id = ?";
                        $security->executeQuery($sql, [$userId]);
                        break;
                        
                    case 'unban':
                        $sql = "UPDATE users SET status = 'active', updated_at = NOW() WHERE user_id = ?";
                        $security->executeQuery($sql, [$userId]);
                        break;
                        
                    case 'delete':
                        $sql = "UPDATE users SET status = 'deleted', updated_at = NOW() WHERE user_id = ?";
                        $security->executeQuery($sql, [$userId]);
                        break;
                }
                
                $updatedCount++;
                
            } catch (Exception $e) {
                error_log("Bulk operation error for user {$userId}: " . $e->getMessage());
                continue;
            }
        }
        
        // Commit transaction
        $security->db->commit();
        
        // Log bulk action
        $security->logSecurityEvent('BULK_USER_ACTION', [
            'action' => $bulkData['action'],
            'admin_id' => $_SESSION['admin_user']['user_id'] ?? null,
            'updated_count' => $updatedCount,
            'total_count' => $bulkData['count']
        ]);
        
        return [
            'success' => true,
            'message' => "Bulk {$bulkData['action']} completed",
            'updated_count' => $updatedCount,
            'total_count' => $bulkData['count']
        ];
        
    } catch (Exception $e) {
        $security->db->rollback();
        error_log("Bulk operation error: " . $e->getMessage());
        return ['success' => false, 'message' => 'Bulk operation failed'];
    }
}

/**
 * EXAMPLE 6: SECURE FILE UPLOAD
 */
function secureFileUpload($file, $allowedTypes = ['image/jpeg', 'image/png'], $maxSize = 2097152) {
    global $validator;
    
    try {
        // Validate file upload
        $fileData = $validator->validateFileUpload($file, $allowedTypes, $maxSize);
        
        // Generate secure upload path
        $uploadDir = '../uploads/avatars/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }
        
        $uploadPath = $uploadDir . $fileData['name'];
        
        // Move uploaded file
        if (!move_uploaded_file($fileData['tmp_name'], $uploadPath)) {
            throw new ValidationException('Failed to move uploaded file');
        }
        
        // Set file permissions
        chmod($uploadPath, 0644);
        
        return [
            'success' => true,
            'filename' => $fileData['name'],
            'path' => $uploadPath,
            'size' => $fileData['size']
        ];
        
    } catch (ValidationException $e) {
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

/**
 * EXAMPLE 7: SECURE API ENDPOINT
 */
function secureAPIEndpoint($method, $endpoint, $data = []) {
    global $security, $validator;
    
    try {
        // Validate API request
        $security->validateAPIRequest($method, $endpoint, $data);
        
        // Route to appropriate handler
        switch ($endpoint) {
            case 'users':
                return handleUsersAPI($method, $data);
                
            case 'questions':
                return handleQuestionsAPI($method, $data);
                
            default:
                throw new SecurityException('Invalid endpoint');
        }
        
    } catch (SecurityException $e) {
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

/**
 * EXAMPLE 8: CSRF PROTECTION IN FORMS
 */
function generateSecureForm($action, $method = 'POST') {
    global $security;
    
    // Generate CSRF token
    $csrfToken = $security->getCSRFToken();
    
    // Generate form HTML
    $formHtml = "
        <form method=\"{$method}\" action=\"{$action}\">
            <input type=\"hidden\" name=\"csrf_token\" value=\"{$csrfToken}\">
            <div class=\"form-group\">
                <label for=\"username\">Username:</label>
                <input type=\"text\" name=\"username\" id=\"username\" required>
            </div>
            <div class=\"form-group\">
                <label for=\"password\">Password:</label>
                <input type=\"password\" name=\"password\" id=\"password\" required>
            </div>
            <button type=\"submit\">Login</button>
        </form>
    ";
    
    return $formHtml;
}

/**
 * EXAMPLE 9: SECURE DATA EXPORT
 */
function secureDataExport($format, $dataType, $filters = []) {
    global $security, $validator;
    
    try {
        // Validate export parameters
        $allowedFormats = ['csv', 'excel', 'pdf'];
        $allowedDataTypes = ['users', 'questions', 'answers', 'reports'];
        
        if (!in_array($format, $allowedFormats)) {
            throw new ValidationException('Invalid export format');
        }
        
        if (!in_array($dataType, $allowedDataTypes)) {
            throw new ValidationException('Invalid data type');
        }
        
        // Rate limiting for exports
        $security->checkRateLimit('export', 5, 3600); // 5 exports per hour
        
        // Get data securely
        $data = secureGetDataForExport($dataType, $filters);
        
        // Export data in requested format
        switch ($format) {
            case 'csv':
                return exportToCSV($data, $dataType);
            case 'excel':
                return exportToExcel($data, $dataType);
            case 'pdf':
                return exportToPDF($data, $dataType);
        }
        
    } catch (Exception $e) {
        error_log("Export error: " . $e->getMessage());
        return ['success' => false, 'message' => 'Export failed'];
    }
}

/**
 * EXAMPLE 10: SESSION SECURITY VALIDATION
 */
function validateSessionSecurity() {
    global $security;
    
    try {
        // Check if session is valid
        if (!isset($_SESSION['admin_user'])) {
            throw new SecurityException('No active session');
        }
        
        // Validate session age
        $maxSessionAge = 3600; // 1 hour
        if (isset($_SESSION['admin_user']['login_time'])) {
            $sessionAge = time() - $_SESSION['admin_user']['login_time'];
            if ($sessionAge > $maxSessionAge) {
                $security->destroySession();
                throw new SecurityException('Session expired');
            }
        }
        
        // Update last activity
        $_SESSION['last_activity'] = time();
        
        return true;
        
    } catch (SecurityException $e) {
        return false;
    }
}

// Helper function for MFA verification (simplified)
function verifyMFA($userId, $code) {
    // In production, implement proper TOTP verification
    return $code === '123456';
}

// Helper function for data export
function secureGetDataForExport($dataType, $filters) {
    // Implement secure data retrieval for export
    return [];
}

// Helper functions for export formats
function exportToCSV($data, $dataType) {
    // Implement CSV export
    return ['success' => true, 'file' => 'export.csv'];
}

function exportToExcel($data, $dataType) {
    // Implement Excel export
    return ['success' => true, 'file' => 'export.xlsx'];
}

function exportToPDF($data, $dataType) {
    // Implement PDF export
    return ['success' => true, 'file' => 'export.pdf'];
}

// Usage examples:
/*
// User registration
$registrationResult = secureUserRegistration([
    'username' => $_POST['username'],
    'email' => $_POST['email'],
    'password' => $_POST['password'],
    'first_name' => $_POST['first_name'],
    'last_name' => $_POST['last_name']
]);

// Login process
$loginResult = secureLoginProcess($_POST['username'], $_POST['password'], $_POST['mfa_code']);

// Get users with search and pagination
$usersResult = secureGetUsers($_GET['page'], $_GET['limit'], $_GET['search'], $_GET['status']);

// Update user
$updateResult = secureUpdateUser($_POST['user_id'], $_POST);

// Bulk operation
$bulkResult = secureBulkUserAction($_POST['user_ids'], $_POST['action']);

// File upload
$uploadResult = secureFileUpload($_FILES['avatar']);

// Generate secure form
$formHtml = generateSecureForm('login.php');

// Data export
$exportResult = secureDataExport($_GET['format'], $_GET['data_type'], $_GET['filters']);
*/
