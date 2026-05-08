<?php
/**
 * Secure Login Implementation
 * ASTU-Q Admin Panel
 */

require_once 'SecurityManager.php';
require_once '../config/database.php';

class SecureLogin {
    private $security;
    private $db;
    
    public function __construct() {
        $this->security = SecurityManager::getInstance();
        $this->db = new Database();
        
        // Set security headers
        $this->security->setSecurityHeaders();
        
        // Initialize secure session
        $this->security->initializeSecureSession();
    }
    
    /**
     * Process secure login
     */
    public function processLogin($username, $password, $mfaCode = null) {
        try {
            // Rate limiting check
            $this->security->checkRateLimit('login', 5, 300); // 5 attempts per 5 minutes
            
            // Input validation
            $username = $this->security->validateInput($username, 'username');
            $password = $this->security->validateInput($password, 'password');
            
            // Check login attempts
            $this->security->checkLoginAttempts($username);
            
            // CSRF validation (if form submission)
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                $csrfToken = $_POST['csrf_token'] ?? '';
                if (!$this->security->validateCSRFToken($csrfToken)) {
                    throw new SecurityException('CSRF token validation failed');
                }
            }
            
            // Get user from database
            $user = $this->getUserByUsername($username);
            
            if (!$user) {
                $this->handleFailedLogin($username, 'User not found');
                throw new SecurityException('Invalid credentials');
            }
            
            // Verify password
            if (!$this->security->verifyPassword($password, $user['password_hash'])) {
                $this->handleFailedLogin($username, 'Invalid password');
                throw new SecurityException('Invalid credentials');
            }
            
            // Check account status
            if ($user['status'] !== 'active') {
                throw new SecurityException('Account is not active');
            }
            
            // MFA verification (if enabled)
            if ($user['mfa_enabled']) {
                if (!$this->verifyMFA($user['user_id'], $mfaCode)) {
                    $this->handleFailedLogin($username, 'MFA failed');
                    throw new SecurityException('Invalid MFA code');
                }
            }
            
            // Successful login
            $this->handleSuccessfulLogin($user);
            
            return ['success' => true, 'message' => 'Login successful'];
            
        } catch (SecurityException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (ValidationException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        } catch (Exception $e) {
            error_log("Login error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Login system error'];
        }
    }
    
    /**
     * Get user by username with secure query
     */
    private function getUserByUsername($username) {
        $sql = "SELECT user_id, username, email, password_hash, first_name, last_name, 
                       status, role_name, permissions, mfa_enabled, last_login
                FROM users u
                JOIN user_roles ur ON u.user_id = ur.user_id AND ur.is_active = TRUE
                JOIN roles r ON ur.role_id = r.role_id
                WHERE u.username = ? AND u.status = 'active'";
        
        $stmt = $this->security->executeQuery($sql, [$username]);
        return $stmt->fetch_assoc();
    }
    
    /**
     * Handle failed login
     */
    private function handleFailedLogin($username, $reason) {
        // Record failed attempt
        $this->security->recordFailedLogin($username);
        
        // Log security event
        $this->security->logSecurityEvent('FAILED_LOGIN', [
            'username' => $username,
            'reason' => $reason,
            'ip_address' => $_SERVER['REMOTE_ADDR'],
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? ''
        ]);
    }
    
    /**
     * Handle successful login
     */
    private function handleSuccessfulLogin($user) {
        // Clear failed attempts
        $this->security->clearFailedLogins($user['username']);
        
        // Update last login
        $this->updateLastLogin($user['user_id']);
        
        // Regenerate session ID
        session_regenerate_id(true);
        
        // Set session data
        $_SESSION['admin_user'] = [
            'user_id' => $user['user_id'],
            'username' => $user['username'],
            'email' => $user['email'],
            'first_name' => $user['first_name'],
            'last_name' => $user['last_name'],
            'role_name' => $user['role_name'],
            'permissions' => json_decode($user['permissions'] ?: '{}', true),
            'login_time' => time()
        ];
        
        // Set security session variables
        $_SESSION['ip_address'] = $_SERVER['REMOTE_ADDR'];
        $_SESSION['user_agent'] = $_SERVER['HTTP_USER_AGENT'];
        $_SESSION['last_activity'] = time();
        
        // Log successful login
        $this->security->logSecurityEvent('SUCCESSFUL_LOGIN', [
            'user_id' => $user['user_id'],
            'username' => $user['username'],
            'ip_address' => $_SERVER['REMOTE_ADDR']
        ]);
    }
    
    /**
     * Update last login time
     */
    private function updateLastLogin($userId) {
        $sql = "UPDATE users SET last_login = NOW() WHERE user_id = ?";
        $this->security->executeQuery($sql, [$userId]);
    }
    
    /**
     * Verify MFA code (simplified implementation)
     */
    private function verifyMFA($userId, $code) {
        // In production, implement proper TOTP verification
        // For demo purposes, accept code '123456'
        return $code === '123456';
    }
    
    /**
     * Logout securely
     */
    public function logout() {
        if (isset($_SESSION['admin_user'])) {
            // Log logout
            $this->security->logSecurityEvent('LOGOUT', [
                'user_id' => $_SESSION['admin_user']['user_id'],
                'username' => $_SESSION['admin_user']['username']
            ]);
        }
        
        // Destroy session
        $this->security->destroySession();
        
        return ['success' => true, 'message' => 'Logged out successfully'];
    }
}

// Example usage:
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'login') {
    $login = new SecureLogin();
    
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $mfaCode = $_POST['mfa_code'] ?? null;
    
    $result = $login->processLogin($username, $password, $mfaCode);
    
    if ($result['success']) {
        header('Location: dashboard.php');
        exit;
    } else {
        $error = $result['message'];
    }
}
?>
