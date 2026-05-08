<?php
/**
 * Authentication and Session Management
 * ASTU-Q Admin Panel
 */

require_once 'database.php';

class Auth {
    private $db;
    private $session_timeout = 3600; // 1 hour
    private $max_login_attempts = 5;
    private $lockout_duration = 1800; // 30 minutes
    
    public function __construct() {
        $this->db = new Database();
        session_start();
    }
    
    /**
     * Admin login with MFA support
     */
    public function login($username, $password, $mfa_code = null) {
        try {
            // Check if account is locked
            if ($this->isAccountLocked($username)) {
                return ['success' => false, 'message' => 'Account temporarily locked due to multiple failed attempts'];
            }
            
            // Get user with role information
            $sql = "SELECT u.*, r.role_name, r.permissions 
                    FROM users u 
                    JOIN user_roles ur ON u.user_id = ur.user_id 
                    JOIN roles r ON ur.role_id = r.role_id 
                    WHERE u.username = ? AND u.status = 'active' 
                    AND ur.is_active = TRUE 
                    AND (ur.expires_at IS NULL OR ur.expires_at > NOW())";
            
            $stmt = $this->db->execute($sql, [$username]);
            $user = $stmt->fetch();
            
            if (!$user || !password_verify($password, $user['password_hash'])) {
                $this->recordFailedLogin($username);
                return ['success' => false, 'message' => 'Invalid credentials'];
            }
            
            // Verify MFA if enabled (simplified for demo)
            if ($this->isMFARequired($user['user_id']) && !$this->verifyMFA($user['user_id'], $mfa_code)) {
                return ['success' => false, 'message' => 'Invalid MFA code'];
            }
            
            // Create session
            $this->createSession($user);
            
            // Clear failed login attempts
            $this->clearFailedAttempts($username);
            
            // Log successful login
            $this->logAdminAction($user['user_id'], 'login', 'user', $user['user_id'], null, null);
            
            return ['success' => true, 'message' => 'Login successful', 'user' => $this->sanitizeUserData($user)];
            
        } catch (Exception $e) {
            error_log("Login error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Login system error'];
        }
    }
    
    /**
     * Admin logout
     */
    public function logout() {
        try {
            if ($this->isLoggedIn()) {
                $user_id = $_SESSION['admin_user']['user_id'];
                $this->logAdminAction($user_id, 'logout', 'user', $user_id, null, null);
            }
            
            // Destroy session
            session_destroy();
            setcookie(session_name(), '', time() - 3600, '/');
            
            return ['success' => true, 'message' => 'Logged out successfully'];
            
        } catch (Exception $e) {
            error_log("Logout error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Logout error'];
        }
    }
    
    /**
     * Check if admin is logged in
     */
    public function isLoggedIn() {
        if (!isset($_SESSION['admin_user']) || !isset($_SESSION['admin_session_id'])) {
            return false;
        }
        
        // Check session timeout
        if (time() > $_SESSION['admin_session_timeout']) {
            $this->logout();
            return false;
        }
        
        // Validate session
        $session_id = $_SESSION['admin_session_id'];
        $sql = "SELECT session_id FROM admin_sessions WHERE session_id = ? AND expires_at > NOW()";
        $stmt = $this->db->execute($sql, [$session_id]);
        
        if ($stmt->rowCount() === 0) {
            $this->logout();
            return false;
        }
        
        // Refresh session timeout
        $_SESSION['admin_session_timeout'] = time() + $this->session_timeout;
        $this->refreshSession($session_id);
        
        return true;
    }
    
    /**
     * Get current admin user
     */
    public function getCurrentUser() {
        if (!$this->isLoggedIn()) {
            return null;
        }
        
        return $_SESSION['admin_user'];
    }
    
    /**
     * Check if user has specific permission
     */
    public function hasPermission($permission) {
        if (!$this->isLoggedIn()) {
            return false;
        }
        
        $user = $this->getCurrentUser();
        $permissions = json_decode($user['permissions'], true) ?: [];
        
        // Check for full access
        if (isset($permissions['all']) && $permissions['all'] === true) {
            return true;
        }
        
        // Check for specific permission
        return $this->checkNestedPermission($permissions, $permission);
    }
    
    /**
     * Check nested permission (e.g., users.create)
     */
    private function checkNestedPermission($permissions, $permission) {
        $keys = explode('.', $permission);
        $current = $permissions;
        
        foreach ($keys as $key) {
            if (!isset($current[$key])) {
                return false;
            }
            $current = $current[$key];
        }
        
        return true;
    }
    
    /**
     * Create admin session
     */
    private function createSession($user) {
        $session_id = session_id();
        $expires_at = date('Y-m-d H:i:s', time() + $this->session_timeout);
        $ip_address = $this->getClientIP();
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
        
        // Store session in database
        $sql = "INSERT INTO admin_sessions (session_id, user_id, ip_address, user_agent, expires_at) 
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE 
                ip_address = VALUES(ip_address),
                user_agent = VALUES(user_agent),
                expires_at = VALUES(expires_at)";
        
        $this->db->execute($sql, [$session_id, $user['user_id'], $ip_address, $user_agent, $expires_at]);
        
        // Set session variables
        $_SESSION['admin_user'] = $this->sanitizeUserData($user);
        $_SESSION['admin_session_id'] = $session_id;
        $_SESSION['admin_session_timeout'] = time() + $this->session_timeout;
        $_SESSION['admin_login_time'] = time();
    }
    
    /**
     * Refresh session
     */
    private function refreshSession($session_id) {
        $expires_at = date('Y-m-d H:i:s', time() + $this->session_timeout);
        $sql = "UPDATE admin_sessions SET expires_at = ? WHERE session_id = ?";
        $this->db->execute($sql, [$expires_at, $session_id]);
    }
    
    /**
     * Check if account is locked
     */
    private function isAccountLocked($username) {
        $sql = "SELECT COUNT(*) as attempts, MAX(created_at) as last_attempt 
                FROM failed_logins 
                WHERE username = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)";
        
        $stmt = $this->db->execute($sql, [$username, $this->lockout_duration]);
        $result = $stmt->fetch();
        
        return $result['attempts'] >= $this->max_login_attempts;
    }
    
    /**
     * Record failed login attempt
     */
    private function recordFailedLogin($username) {
        $ip_address = $this->getClientIP();
        $sql = "INSERT INTO failed_logins (username, ip_address, created_at) VALUES (?, ?, NOW())";
        $this->db->execute($sql, [$username, $ip_address]);
    }
    
    /**
     * Clear failed login attempts
     */
    private function clearFailedAttempts($username) {
        $sql = "DELETE FROM failed_logins WHERE username = ?";
        $this->db->execute($sql, [$username]);
    }
    
    /**
     * Check if MFA is required for user
     */
    private function isMFARequired($user_id) {
        // Simplified MFA check - in production, implement proper TOTP/Google Authenticator
        $sql = "SELECT mfa_enabled FROM users WHERE user_id = ?";
        $stmt = $this->db->execute($sql, [$user_id]);
        $user = $stmt->fetch();
        
        return $user && $user['mfa_enabled'] == 1;
    }
    
    /**
     * Verify MFA code
     */
    private function verifyMFA($user_id, $code) {
        // Simplified MFA verification - implement proper TOTP verification
        if ($code === '123456') { // Demo code
            return true;
        }
        return false;
    }
    
    /**
     * Sanitize user data for session
     */
    private function sanitizeUserData($user) {
        unset($user['password_hash']);
        return $user;
    }
    
    /**
     * Get client IP address
     */
    private function getClientIP() {
        $ip_keys = ['HTTP_CLIENT_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_FORWARDED', 'HTTP_FORWARDED_FOR', 'HTTP_FORWARDED', 'REMOTE_ADDR'];
        
        foreach ($ip_keys as $key) {
            if (array_key_exists($key, $_SERVER) === true) {
                foreach (explode(',', $_SERVER[$key]) as $ip) {
                    $ip = trim($ip);
                    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) !== false) {
                        return $ip;
                    }
                }
            }
        }
        
        return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    }
    
    /**
     * Log admin action
     */
    public function logAdminAction($admin_user_id, $action_type, $target_type, $target_id, $old_values, $new_values) {
        try {
            $ip_address = $this->getClientIP();
            $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
            $session_id = session_id();
            
            $sql = "INSERT INTO admin_logs (admin_user_id, action_type, target_type, target_id, old_values, new_values, ip_address, user_agent, session_id) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            $this->db->execute($sql, [
                $admin_user_id,
                $action_type,
                $target_type,
                $target_id,
                $old_values ? json_encode($old_values) : null,
                $new_values ? json_encode($new_values) : null,
                $ip_address,
                $user_agent,
                $session_id
            ]);
            
        } catch (Exception $e) {
            error_log("Failed to log admin action: " . $e->getMessage());
        }
    }
    
    /**
     * Require authentication
     */
    public function requireAuth() {
        if (!$this->isLoggedIn()) {
            header('HTTP/1.0 403 Forbidden');
            header('Content-Type: application/json');
            echo json_encode(['success' => false, 'message' => 'Authentication required']);
            exit;
        }
    }
    
    /**
     * Require specific permission
     */
    public function requirePermission($permission) {
        $this->requireAuth();
        
        if (!$this->hasPermission($permission)) {
            header('HTTP/1.0 403 Forbidden');
            header('Content-Type: application/json');
            echo json_encode(['success' => false, 'message' => 'Insufficient permissions']);
            exit;
        }
    }
}
