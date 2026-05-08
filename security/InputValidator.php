<?php
/**
 * Input Validator Class
 * ASTU-Q Admin Panel
 * Comprehensive Input Validation and Sanitization
 */

class InputValidator {
    private static $instance = null;
    private $security;
    
    private function __construct() {
        $this->security = SecurityManager::getInstance();
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Validate and sanitize form data
     */
    public function validateFormData($data, $rules) {
        $validated = [];
        $errors = [];
        
        foreach ($rules as $field => $rule) {
            try {
                $value = $data[$field] ?? null;
                
                // Check if required
                if (isset($rule['required']) && $rule['required'] && ($value === null || $value === '')) {
                    throw new ValidationException("Field '{$field}' is required");
                }
                
                // Skip validation if field is empty and not required
                if (($value === null || $value === '') && !isset($rule['required'])) {
                    $validated[$field] = null;
                    continue;
                }
                
                // Validate based on type
                $type = $rule['type'] ?? 'string';
                $options = $rule['options'] ?? [];
                
                $validated[$field] = $this->security->validateInput($value, $type, $options);
                
                // Additional custom validations
                if (isset($rule['custom'])) {
                    foreach ($rule['custom'] as $customRule => $customValue) {
                        $this->validateCustomRule($field, $validated[$field], $customRule, $customValue);
                    }
                }
                
            } catch (ValidationException $e) {
                $errors[$field] = $e->getMessage();
            }
        }
        
        if (!empty($errors)) {
            throw new ValidationException('Validation failed', 0, null, $errors);
        }
        
        return $validated;
    }
    
    /**
     * Validate custom rules
     */
    private function validateCustomRule($field, $value, $rule, $constraint) {
        switch ($rule) {
            case 'min_length':
                if (strlen($value) < $constraint) {
                    throw new ValidationException("Field '{$field}' must be at least {$constraint} characters");
                }
                break;
                
            case 'max_length':
                if (strlen($value) > $constraint) {
                    throw new ValidationException("Field '{$field}' must not exceed {$constraint} characters");
                }
                break;
                
            case 'pattern':
                if (!preg_match($constraint, $value)) {
                    throw new ValidationException("Field '{$field}' format is invalid");
                }
                break;
                
            case 'in':
                if (!in_array($value, $constraint)) {
                    throw new ValidationException("Field '{$field}' must be one of: " . implode(', ', $constraint));
                }
                break;
                
            case 'unique':
                $this->validateUnique($field, $value, $constraint);
                break;
                
            case 'exists':
                $this->validateExists($field, $value, $constraint);
                break;
        }
    }
    
    /**
     * Validate unique constraint
     */
    private function validateUnique($field, $value, $table) {
        $sql = "SELECT COUNT(*) as count FROM {$table} WHERE {$field} = ?";
        $stmt = $this->security->executeQuery($sql, [$value]);
        $result = $stmt->fetch_assoc();
        
        if ($result['count'] > 0) {
            throw new ValidationException("Field '{$field}' must be unique");
        }
    }
    
    /**
     * Validate exists constraint
     */
    private function validateExists($field, $value, $table) {
        $sql = "SELECT COUNT(*) as count FROM {$table} WHERE {$field} = ?";
        $stmt = $this->security->executeQuery($sql, [$value]);
        $result = $stmt->fetch_assoc();
        
        if ($result['count'] === 0) {
            throw new ValidationException("Field '{$field}' reference does not exist");
        }
    }
    
    /**
     * Sanitize array data
     */
    public function sanitizeArray($data) {
        return array_map([$this->security, 'sanitizeOutput'], $data);
    }
    
    /**
     * Validate file upload
     */
    public function validateFileUpload($file, $allowedTypes = [], $maxSize = 5242880) {
        $errors = [];
        
        // Check if file was uploaded
        if (!isset($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
            throw new ValidationException('Invalid file upload');
        }
        
        // Check file size
        if ($file['size'] > $maxSize) {
            throw new ValidationException('File size exceeds maximum allowed size');
        }
        
        // Check file type
        if (!empty($allowedTypes)) {
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $mimeType = finfo_file($finfo, $file['tmp_name']);
            finfo_close($finfo);
            
            if (!in_array($mimeType, $allowedTypes)) {
                throw new ValidationException('File type not allowed');
            }
        }
        
        // Generate secure filename
        $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
        $filename = bin2hex(random_bytes(16)) . '.' . $extension;
        
        return [
            'tmp_name' => $file['tmp_name'],
            'name' => $filename,
            'original_name' => $file['name'],
            'size' => $file['size'],
            'type' => $file['type']
        ];
    }
    
    /**
     * Validate API request
     */
    public function validateAPIRequest($method, $endpoint, $data = []) {
        // Rate limiting
        $this->security->checkRateLimit('api_' . $method . '_' . $endpoint, 100, 3600);
        
        // Validate method
        $allowedMethods = ['GET', 'POST', 'PUT', 'DELETE'];
        if (!in_array($method, $_SERVER['REQUEST_METHOD'])) {
            throw new SecurityException('Method not allowed');
        }
        
        // CSRF validation for state-changing methods
        if (in_array($method, ['POST', 'PUT', 'DELETE'])) {
            $csrfToken = $data['csrf_token'] ?? '';
            if (!$this->security->validateCSRFToken($csrfToken)) {
                throw new SecurityException('CSRF token validation failed');
            }
        }
        
        return true;
    }
    
    /**
     * Validate search query
     */
    public function validateSearchQuery($query, $maxLength = 100) {
        $query = trim($query);
        
        if (strlen($query) > $maxLength) {
            throw new ValidationException('Search query too long');
        }
        
        // Check for SQL injection patterns
        $maliciousPatterns = [
            '/\b(UNION|SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC)\b/i',
            '/--/',
            '/\/\*/',
            '/\*\/',
            '/;/'
        ];
        
        foreach ($maliciousPatterns as $pattern) {
            if (preg_match($pattern, $query)) {
                throw new SecurityException('Invalid search query');
            }
        }
        
        return $this->security->sanitizeOutput($query);
    }
    
    /**
     * Validate date range
     */
    public function validateDateRange($startDate, $endDate, $maxDays = 365) {
        $start = new DateTime($startDate);
        $end = new DateTime($endDate);
        $now = new DateTime();
        
        // Validate dates are valid
        if ($start > $end) {
            throw new ValidationException('Start date must be before end date');
        }
        
        // Validate range is not too large
        $interval = $start->diff($end);
        if ($interval->days > $maxDays) {
            throw new ValidationException("Date range cannot exceed {$maxDays} days");
        }
        
        // Validate dates are not in the future
        if ($end > $now) {
            throw new ValidationException('End date cannot be in the future');
        }
        
        // Validate dates are not too old
        $minDate = clone $now;
        $minDate->sub(new DateInterval("P{$maxDays}D"));
        if ($start < $minDate) {
            throw new ValidationException("Date range cannot exceed {$maxDays} days in the past");
        }
        
        return [
            'start' => $start->format('Y-m-d'),
            'end' => $end->format('Y-m-d')
        ];
    }
    
    /**
     * Validate pagination parameters
     */
    public function validatePagination($page = 1, $limit = 25, $maxLimit = 100) {
        $page = $this->security->validateInput($page, 'integer', ['min' => 1]);
        $limit = $this->security->validateInput($limit, 'integer', ['min' => 1, 'max' => $maxLimit]);
        
        return [
            'page' => $page,
            'limit' => $limit,
            'offset' => ($page - 1) * $limit
        ];
    }
    
    /**
     * Validate sorting parameters
     */
    public function validateSorting($sortBy, $allowedColumns, $defaultSort = 'id') {
        if (!in_array($sortBy, $allowedColumns)) {
            $sortBy = $defaultSort;
        }
        
        return $sortBy;
    }
    
    /**
     * Validate filter parameters
     */
    public function validateFilters($filters, $allowedFilters) {
        $validatedFilters = [];
        
        foreach ($filters as $key => $value) {
            if (!in_array($key, $allowedFilters)) {
                continue; // Skip unknown filters
            }
            
            $validatedFilters[$key] = $this->security->sanitizeOutput($value);
        }
        
        return $validatedFilters;
    }
    
    /**
     * Validate bulk operation parameters
     */
    public function validateBulkOperation($ids, $action, $allowedActions) {
        // Validate IDs
        if (!is_array($ids) || empty($ids)) {
            throw new ValidationException('No items selected for bulk operation');
        }
        
        foreach ($ids as $id) {
            $this->security->validateInput($id, 'integer', ['min' => 1]);
        }
        
        // Validate action
        if (!in_array($action, $allowedActions)) {
            throw new ValidationException('Invalid bulk operation action');
        }
        
        return [
            'ids' => array_map('intval', $ids),
            'action' => $action,
            'count' => count($ids)
        ];
    }
    
    /**
     * Validate notification data
     */
    public function validateNotification($data) {
        $rules = [
            'user_id' => ['type' => 'integer', 'required' => true, 'min' => 1],
            'type' => ['type' => 'string', 'required' => true, 'max_length' => 50],
            'title' => ['type' => 'text', 'required' => true, 'max_length' => 255],
            'message' => ['type' => 'text', 'required' => true, 'max_length' => 1000],
            'priority' => ['type' => 'string', 'custom' => ['in' => ['low', 'medium', 'high', 'urgent']]]
        ];
        
        return $this->validateFormData($data, $rules);
    }
    
    /**
     * Validate user profile data
     */
    public function validateUserProfile($data) {
        $rules = [
            'username' => ['type' => 'username', 'required' => true],
            'email' => ['type' => 'email', 'required' => true],
            'first_name' => ['type' => 'text', 'required' => true, 'max_length' => 50],
            'last_name' => ['type' => 'text', 'required' => true, 'max_length' => 50],
            'phone' => ['type' => 'text', 'max_length' => 20],
            'bio' => ['type' => 'text', 'max_length' => 500, 'allow_html' => true],
            'role_id' => ['type' => 'integer', 'min' => 1],
            'status' => ['type' => 'string', 'custom' => ['in' => ['active', 'banned', 'suspended', 'pending']]]
        ];
        
        return $this->validateFormData($data, $rules);
    }
    
    /**
     * Validate question data
     */
    public function validateQuestion($data) {
        $rules = [
            'title' => ['type' => 'text', 'required' => true, 'min_length' => 10, 'max_length' => 255],
            'content' => ['type' => 'html', 'required' => true, 'min_length' => 20, 'max_length' => 10000],
            'subject' => ['type' => 'text', 'required' => true, 'max_length' => 100],
            'category' => ['type' => 'text', 'required' => true, 'max_length' => 100],
            'tags' => ['type' => 'text', 'max_length' => 500],
            'difficulty' => ['type' => 'string', 'custom' => ['in' => ['beginner', 'intermediate', 'advanced']]]
        ];
        
        return $this->validateFormData($data, $rules);
    }
    
    /**
     * Validate answer data
     */
    public function validateAnswer($data) {
        $rules = [
            'question_id' => ['type' => 'integer', 'required' => true, 'min' => 1],
            'content' => ['type' => 'html', 'required' => true, 'min_length' => 20, 'max_length' => 10000],
            'verification_level' => ['type' => 'string', 'custom' => ['in' => ['basic', 'expert', 'official']]]
        ];
        
        return $this->validateFormData($data, $rules);
    }
    
    /**
     * Validate report data
     */
    public function validateReport($data) {
        $rules = [
            'reporter_id' => ['type' => 'integer', 'required' => true, 'min' => 1],
            'reported_item_type' => ['type' => 'string', 'required' => true, 'custom' => ['in' => ['question', 'answer', 'user', 'comment']]],
            'reported_item_id' => ['type' => 'integer', 'required' => true, 'min' => 1],
            'reason' => ['type' => 'string', 'required' => true, 'custom' => ['in' => ['spam', 'inappropriate', 'harassment', 'copyright', 'misinformation', 'duplicate', 'other']]],
            'description' => ['type' => 'text', 'max_length' => 1000],
            'priority' => ['type' => 'string', 'custom' => ['in' => ['low', 'medium', 'high', 'critical']]]
        ];
        
        return $this->validateFormData($data, $rules);
    }
}

// Example usage:
/*
$validator = InputValidator::getInstance();

// Validate user registration
try {
    $userData = $validator->validateUserProfile($_POST);
    // Process valid data
} catch (ValidationException $e) {
    $errors = $e->getErrors();
    // Handle validation errors
}

// Validate API request
try {
    $validator->validateAPIRequest('POST', 'users', $_POST);
    // Process valid request
} catch (SecurityException $e) {
    // Handle security error
}

// Validate file upload
try {
    $fileData = $validator->validateFileUpload($_FILES['avatar'], ['image/jpeg', 'image/png'], 2097152);
    // Process valid file
} catch (ValidationException $e) {
    // Handle file validation error
}
*/
