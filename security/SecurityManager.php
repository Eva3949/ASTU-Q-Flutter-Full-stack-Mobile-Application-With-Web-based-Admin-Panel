<?php
/**
 * Security Manager
 * ASTU-Q Admin Panel
 * Comprehensive Security Implementation
 */

class SecurityManager {
    private static $instance = null;
    private $db;
    private $csrfTokenLength = 32;
    private $maxLoginAttempts = 5;
    private $lockoutDuration = 1800; // 30 minutes
    
    private function __construct() {
        $this->db = new Database();
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * 1. PASSWORD HASHING (BCRYPT)
     */
    
    /**
     * Hash password using bcrypt
     */
    public function hashPassword($password) {
        // Use bcrypt with cost factor 12 (high security)
        $options = [
            'cost' => 12,
        ];
        
        return password_hash($password, PASSWORD_BCRYPT, $options);
    }
    
    /**
     * Verify password against hash
     */
    public function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    /**
     * Check if password needs rehashing
     */
    public function needsRehash($hash) {
        return password_needs_rehash($hash, PASSWORD_BCRYPT, ['cost' => 12]);
    }
    
    /**
     * Validate password strength
     */
    public function validatePasswordStrength($password) {
        $errors = [];
        
        // Minimum length
        if (strlen($password) < 12) {
            $errors[] = 'Password must be at least 12 characters long';
        }
        
        // Must contain uppercase
        if (!preg_match('/[A-Z]/', $password)) {
            $errors[] = 'Password must contain at least one uppercase letter';
        }
        
        // Must contain lowercase
        if (!preg_match('/[a-z]/', $password)) {
            $errors[] = 'Password must contain at least one lowercase letter';
        }
        
        // Must contain number
        if (!preg_match('/[0-9]/', $password)) {
            $errors[] = 'Password must contain at least one number';
        }
        
        // Must contain special character
        if (!preg_match('/[!@#$%^&*(),.?":{}|<>]/', $password)) {
            $errors[] = 'Password must contain at least one special character';
        }
        
        // Check for common patterns
        $commonPatterns = [
            '/^(.)\1{11,}$/', // All same character
            '/^(123456|password|qwerty|admin|letmein)/i', // Common passwords
            '/^(abc|123|qwe)[a-z0-9]*$/i' // Sequential patterns
        ];
        
        foreach ($commonPatterns as $pattern) {
            if (preg_match($pattern, $password)) {
                $errors[] = 'Password contains common patterns and is not secure';
                break;
            }
        }
        
        return $errors;
    }
    
    /**
     * 2. SQL INJECTION PREVENTION
     */
    
    /**
     * Execute prepared statement safely
     */
    public function executeQuery($sql, $params = []) {
        try {
            // Validate SQL for dangerous patterns
            if ($this->containsMaliciousSQL($sql)) {
                throw new SecurityException('Potentially malicious SQL detected');
            }
            
            // Use prepared statement
            $stmt = $this->db->prepare($sql);
            
            // Bind parameters securely
            if (!empty($params)) {
                $types = $this->getParamTypes($params);
                $stmt->bind_param($types, ...$params);
            }
            
            $stmt->execute();
            return $stmt;
            
        } catch (Exception $e) {
            // Log security violations
            $this->logSecurityEvent('SQL_INJECTION_ATTEMPT', [
                'sql' => $sql,
                'params' => $params,
                'error' => $e->getMessage()
            ]);
            
            throw new SecurityException('Database query failed', 0, $e);
        }
    }
    
    /**
     * Check for malicious SQL patterns
     */
    private function containsMaliciousSQL($sql) {
        $maliciousPatterns = [
            '/\b(DROP|DELETE|TRUNCATE|ALTER|CREATE|EXEC|UNION|INSERT|UPDATE)\s+/i',
            '/\b(OR|AND)\s+\d+\s*=\s*\d+/i',
            '/\b(OR|AND)\s+["\']?\w+["\']?\s*=\s*["\']?\w+["\']?/i',
            '/--/',
            '/\/\*/',
            '/\*\/',
            '/;/',
            '/xp_cmdshell/i',
            '/sp_executesql/i',
            '/information_schema/i'
        ];
        
        foreach ($maliciousPatterns as $pattern) {
            if (preg_match($pattern, $sql)) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Get parameter types for prepared statements
     */
    private function getParamTypes($params) {
        $types = '';
        foreach ($params as $param) {
            if (is_int($param)) {
                $types .= 'i';
            } elseif (is_float($param)) {
                $types .= 'd';
            } else {
                $types .= 's';
            }
        }
        return $types;
    }
    
    /**
     * 3. SESSION SECURITY
     */
    
    /**
     * Initialize secure session
     */
    public function initializeSecureSession() {
        // Set secure session parameters
        ini_set('session.cookie_httponly', 1);
        ini_set('session.cookie_secure', 1);
        ini_set('session.use_strict_mode', 1);
        ini_set('session.cookie_samesite', 'Strict');
        
        // Set session name
        session_name('ASTUQ_ADMIN_SESSION');
        
        // Start session
        session_start();
        
        // Regenerate session ID on login
        if (!isset($_SESSION['initiated'])) {
            session_regenerate_id(true);
            $_SESSION['initiated'] = true;
            $_SESSION['ip_address'] = $_SERVER['REMOTE_ADDR'];
            $_SESSION['user_agent'] = $_SERVER['HTTP_USER_AGENT'];
            $_SESSION['last_activity'] = time();
            $_SESSION['csrf_token'] = $this->generateCSRFToken();
        }
        
        // Validate session
        $this->validateSession();
    }
    
    /**
     * Validate session security
     */
    private function validateSession() {
        // Check session age
        if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity']) > 1800) {
            $this->destroySession();
            throw new SecurityException('Session expired');
        }
        
        // Check IP address
        if (isset($_SESSION['ip_address']) && $_SESSION['ip_address'] !== $_SERVER['REMOTE_ADDR']) {
            $this->destroySession();
            $this->logSecurityEvent('SESSION_HIJACK_ATTEMPT', [
                'session_ip' => $_SESSION['ip_address'],
                'current_ip' => $_SERVER['REMOTE_ADDR']
            ]);
            throw new SecurityException('Session validation failed');
        }
        
        // Check user agent
        if (isset($_SESSION['user_agent']) && $_SESSION['user_agent'] !== $_SERVER['HTTP_USER_AGENT']) {
            $this->destroySession();
            $this->logSecurityEvent('SESSION_HIJACK_ATTEMPT', [
                'session_ua' => $_SESSION['user_agent'],
                'current_ua' => $_SERVER['HTTP_USER_AGENT']
            ]);
            throw new SecurityException('Session validation failed');
        }
        
        // Update last activity
        $_SESSION['last_activity'] = time();
    }
    
    /**
     * Destroy session securely
     */
    public function destroySession() {
        $_SESSION = [];
        
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000,
                $params['path'], $params['domain'],
                $params['secure'], $params['httponly']
            );
        }
        
        session_destroy();
    }
    
    /**
     * 4. CSRF PROTECTION
     */
    
    /**
     * Generate CSRF token
     */
    private function generateCSRFToken() {
        return bin2hex(random_bytes($this->csrfTokenLength));
    }
    
    /**
     * Get current CSRF token
     */
    public function getCSRFToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = $this->generateCSRFToken();
        }
        
        return $_SESSION['csrf_token'];
    }
    
    /**
     * Validate CSRF token
     */
    public function validateCSRFToken($token) {
        if (!isset($_SESSION['csrf_token']) || $token !== $_SESSION['csrf_token']) {
            $this->logSecurityEvent('CSRF_TOKEN_MISMATCH', [
                'provided_token' => $token,
                'session_token' => $_SESSION['csrf_token'] ?? 'none'
            ]);
            return false;
        }
        
        return true;
    }
    
    /**
     * Generate CSRF field for forms
     */
    public function generateCSRFField() {
        $token = $this->getCSRFToken();
        return '<input type="hidden" name="csrf_token" value="' . htmlspecialchars($token, ENT_QUOTES, 'UTF-8') . '">';
    }
    
    /**
     * 5. INPUT VALIDATION
     */
    
    /**
     * Validate and sanitize input
     */
    public function validateInput($input, $type = 'string', $options = []) {
        if ($input === null) {
            return null;
        }
        
        switch ($type) {
            case 'email':
                return $this->validateEmail($input);
                
            case 'username':
                return $this->validateUsername($input);
                
            case 'password':
                return $this->validatePassword($input);
                
            case 'integer':
                return $this->validateInteger($input, $options);
                
            case 'float':
                return $this->validateFloat($input, $options);
                
            case 'url':
                return $this->validateURL($input);
                
            case 'html':
                return $this->validateHTML($input);
                
            case 'text':
            default:
                return $this->validateText($input, $options);
        }
    }
    
    /**
     * Validate email
     */
    private function validateEmail($email) {
        $email = trim($email);
        
        // Basic format validation
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ValidationException('Invalid email format');
        }
        
        // Length validation
        if (strlen($email) > 254) {
            throw new ValidationException('Email too long');
        }
        
        // Domain validation
        $domain = substr(strrchr($email, '@'), 1);
        if (!checkdnsrr($domain, 'MX') && !checkdnsrr($domain, 'A')) {
            throw new ValidationException('Email domain does not exist');
        }
        
        return strtolower($email);
    }
    
    /**
     * Validate username
     */
    private function validateUsername($username) {
        $username = trim($username);
        
        // Length validation
        if (strlen($username) < 3 || strlen($username) > 50) {
            throw new ValidationException('Username must be 3-50 characters');
        }
        
        // Format validation
        if (!preg_match('/^[a-zA-Z0-9_]+$/', $username)) {
            throw new ValidationException('Username can only contain letters, numbers, and underscores');
        }
        
        // Reserved names
        $reserved = ['admin', 'administrator', 'root', 'system', 'api', 'www', 'mail'];
        if (in_array(strtolower($username), $reserved)) {
            throw new ValidationException('Username is reserved');
        }
        
        return $username;
    }
    
    /**
     * Validate password
     */
    private function validatePassword($password) {
        $errors = $this->validatePasswordStrength($password);
        
        if (!empty($errors)) {
            throw new ValidationException(implode(', ', $errors));
        }
        
        return $password;
    }
    
    /**
     * Validate integer
     */
    private function validateInteger($value, $options = []) {
        $min = $options['min'] ?? null;
        $max = $options['max'] ?? null;
        
        if (!filter_var($value, FILTER_VALIDATE_INT)) {
            throw new ValidationException('Invalid integer value');
        }
        
        $value = (int) $value;
        
        if ($min !== null && $value < $min) {
            throw new ValidationException("Value must be at least {$min}");
        }
        
        if ($max !== null && $value > $max) {
            throw new ValidationException("Value must be at most {$max}");
        }
        
        return $value;
    }
    
    /**
     * Validate float
     */
    private function validateFloat($value, $options = []) {
        $min = $options['min'] ?? null;
        $max = $options['max'] ?? null;
        
        if (!filter_var($value, FILTER_VALIDATE_FLOAT)) {
            throw new ValidationException('Invalid float value');
        }
        
        $value = (float) $value;
        
        if ($min !== null && $value < $min) {
            throw new ValidationException("Value must be at least {$min}");
        }
        
        if ($max !== null && $value > $max) {
            throw new ValidationException("Value must be at most {$max}");
        }
        
        return $value;
    }
    
    /**
     * Validate URL
     */
    private function validateURL($url) {
        $url = trim($url);
        
        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            throw new ValidationException('Invalid URL format');
        }
        
        // Check for dangerous protocols
        $allowedSchemes = ['http', 'https'];
        $scheme = parse_url($url, PHP_URL_SCHEME);
        
        if (!in_array($scheme, $allowedSchemes)) {
            throw new ValidationException('URL protocol not allowed');
        }
        
        return $url;
    }
    
    /**
     * Validate HTML content
     */
    private function validateHTML($html) {
        // Use HTML Purifier or similar library in production
        // For now, basic sanitization
        $html = trim($html);
        
        // Remove dangerous tags
        $dangerousTags = ['script', 'iframe', 'object', 'embed', 'form', 'input', 'textarea'];
        foreach ($dangerousTags as $tag) {
            $html = preg_replace('/<' . $tag . '.*?>.*?<\/' . $tag . '>/is', '', $html);
            $html = preg_replace('/<' . $tag . '.*?>/is', '', $html);
        }
        
        // Remove dangerous attributes
        $dangerousAttrs = ['onclick', 'onload', 'onerror', 'onmouseover'];
        foreach ($dangerousAttrs as $attr) {
            $html = preg_replace('/\b' . $attr . '\s*=\s*["\'][^"\']*["\']/', '', $html);
        }
        
        return $html;
    }
    
    /**
     * Validate text input
     */
    private function validateText($text, $options = []) {
        $maxLength = $options['max_length'] ?? 1000;
        $allowHTML = $options['allow_html'] ?? false;
        $required = $options['required'] ?? false;
        
        $text = trim($text);
        
        if ($required && empty($text)) {
            throw new ValidationException('Field is required');
        }
        
        if (strlen($text) > $maxLength) {
            throw new ValidationException("Text too long (max {$maxLength} characters)");
        }
        
        if (!$allowHTML) {
            $text = htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
        }
        
        return $text;
    }
    
    /**
     * LOGIN SECURITY
     */
    
    /**
     * Check login attempts
     */
    public function checkLoginAttempts($username) {
        $sql = "SELECT COUNT(*) as attempts, MAX(created_at) as last_attempt 
                FROM failed_logins 
                WHERE username = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)";
        
        $stmt = $this->executeQuery($sql, [$username, $this->lockoutDuration]);
        $result = $stmt->fetch_assoc();
        
        if ($result['attempts'] >= $this->maxLoginAttempts) {
            throw new SecurityException('Account temporarily locked due to multiple failed attempts');
        }
        
        return true;
    }
    
    /**
     * Record failed login
     */
    public function recordFailedLogin($username) {
        $sql = "INSERT INTO failed_logins (username, ip_address, user_agent, created_at) 
                VALUES (?, ?, ?, NOW())";
        
        $this->executeQuery($sql, [
            $username,
            $_SERVER['REMOTE_ADDR'],
            $_SERVER['HTTP_USER_AGENT'] ?? ''
        ]);
    }
    
    /**
     * Clear failed login attempts
     */
    public function clearFailedLogins($username) {
        $sql = "DELETE FROM failed_logins WHERE username = ?";
        $this->executeQuery($sql, [$username]);
    }
    
    /**
     * SECURITY LOGGING
     */
    
    /**
     * Log security event
     */
    private function logSecurityEvent($eventType, $details = []) {
        $sql = "INSERT INTO security_logs (event_type, ip_address, user_agent, details, created_at) 
                VALUES (?, ?, ?, ?, NOW())";
        
        $this->executeQuery($sql, [
            $eventType,
            $_SERVER['REMOTE_ADDR'],
            $_SERVER['HTTP_USER_AGENT'] ?? '',
            json_encode($details)
        ]);
    }
    
    /**
     * RATE LIMITING
     */
    
    /**
     * Check rate limit
     */
    public function checkRateLimit($action, $limit = 100, $window = 3600) {
        $sql = "SELECT COUNT(*) as attempts 
                FROM rate_limits 
                WHERE action = ? AND ip_address = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)";
        
        $stmt = $this->executeQuery($sql, [$action, $_SERVER['REMOTE_ADDR'], $window]);
        $result = $stmt->fetch_assoc();
        
        if ($result['attempts'] >= $limit) {
            throw new SecurityException('Rate limit exceeded');
        }
        
        // Record this attempt
        $this->recordRateLimitAttempt($action);
        
        return true;
    }
    
    /**
     * Record rate limit attempt
     */
    private function recordRateLimitAttempt($action) {
        $sql = "INSERT INTO rate_limits (action, ip_address, created_at) 
                VALUES (?, ?, NOW())";
        
        $this->executeQuery($sql, [$action, $_SERVER['REMOTE_ADDR']]);
    }
    
    /**
     * XSS PROTECTION
     */
    
    /**
     * Sanitize output
     */
    public function sanitizeOutput($data) {
        if (is_array($data)) {
            return array_map([$this, 'sanitizeOutput'], $data);
        }
        
        return htmlspecialchars($data, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }
    
    /**
     * Generate secure headers
     */
    public function setSecurityHeaders() {
        // Prevent clickjacking
        header('X-Frame-Options: DENY');
        
        // Prevent MIME type sniffing
        header('X-Content-Type-Options: nosniff');
        
        // XSS Protection
        header('X-XSS-Protection: 1; mode=block');
        
        // Content Security Policy
        header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'");
        
        // Strict Transport Security
        header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
        
        // Referrer Policy
        header('Referrer-Policy: strict-origin-when-cross-origin');
    }
}

// Custom exceptions
class SecurityException extends Exception {}
class ValidationException extends Exception {}
