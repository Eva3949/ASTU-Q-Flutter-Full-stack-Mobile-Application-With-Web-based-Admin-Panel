<?php
/**
 * Helper Functions
 * ASTU-Q Admin Panel
 */

// Include database and authentication
require_once 'config/database.php';
require_once 'config/auth.php';

// Initialize database
$db = new Database();
$auth = new Auth();

/**
 * Check if current user has specific permission
 */
function hasPermission($permission) {
    global $auth;
    return $auth->hasPermission($permission);
}

/**
 * Get current user data
 */
function getCurrentUser() {
    global $auth;
    return $auth->getCurrentUser();
}

/**
 * Make API request
 */
function apiRequest($endpoint, $method = 'GET', $data = null) {
    $url = "api/{$endpoint}";
    
    $options = [
        'http' => [
            'method' => $method,
            'header' => 'Content-Type: application/json',
            'ignore_errors' => true
        ]
    ];
    
    if ($data && ($method === 'POST' || $method === 'PUT')) {
        $options['http']['content'] = json_encode($data);
    }
    
    $context = stream_context_create($options);
    $result = file_get_contents($url, false, $context);
    
    if ($result === false) {
        return ['success' => false, 'message' => 'API request failed'];
    }
    
    return json_decode($result, true);
}

/**
 * Get pending counts for badges
 */
function getPendingUserCount() {
    if (!hasPermission('users.read')) return 0;
    
    $result = apiRequest('users?status=pending&limit=1');
    return $result['success'] ? $result['pagination']['total'] : 0;
}

function getPendingQuestionCount() {
    if (!hasPermission('questions.read')) return 0;
    
    $result = apiRequest('questions?status=pending&limit=1');
    return $result['success'] ? $result['pagination']['total'] : 0;
}

function getPendingAnswerCount() {
    if (!hasPermission('answers.read')) return 0;
    
    $result = apiRequest('answers?status=pending&limit=1');
    return $result['success'] ? $result['pagination']['total'] : 0;
}

function getPendingReportCount() {
    if (!hasPermission('reports.read')) return 0;
    
    $result = apiRequest('reports?status=pending&limit=1');
    return $result['success'] ? $result['pagination']['total'] : 0;
}

/**
 * Format date for display
 */
function formatDate($dateString, $format = 'M j, Y H:i') {
    $date = new DateTime($dateString);
    return $date->format($format);
}

/**
 * Format relative time
 */
function formatRelativeTime($dateString) {
    $date = new DateTime($dateString);
    $now = new DateTime();
    $interval = $date->diff($now);
    
    if ($interval->days > 0) {
        return $interval->days . ' day' . ($interval->days > 1 ? 's' : '') . ' ago';
    } elseif ($interval->h > 0) {
        return $interval->h . ' hour' . ($interval->h > 1 ? 's' : '') . ' ago';
    } elseif ($interval->i > 0) {
        return $interval->i . ' minute' . ($interval->i > 1 ? 's' : '') . ' ago';
    } else {
        return 'Just now';
    }
}

/**
 * Format file size
 */
function formatFileSize($bytes) {
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    
    $bytes /= pow(1024, $pow);
    
    return round($bytes, 2) . ' ' . $units[$pow];
}

/**
 * Generate pagination HTML
 */
function generatePagination($current_page, $total_pages, $base_url, $params = []) {
    if ($total_pages <= 1) return '';
    
    $query_string = '';
    if (!empty($params)) {
        $query_string = '&' . http_build_query($params);
    }
    
    $html = '<nav aria-label="Page navigation"><ul class="pagination justify-content-center">';
    
    // Previous button
    if ($current_page > 1) {
        $html .= '<li class="page-item"><a class="page-link" href="' . $base_url . '?page=' . ($current_page - 1) . $query_string . '">Previous</a></li>';
    } else {
        $html .= '<li class="page-item disabled"><span class="page-link">Previous</span></li>';
    }
    
    // Page numbers
    $start = max(1, $current_page - 2);
    $end = min($total_pages, $current_page + 2);
    
    if ($start > 1) {
        $html .= '<li class="page-item"><a class="page-link" href="' . $base_url . '?page=1' . $query_string . '">1</a></li>';
        if ($start > 2) {
            $html .= '<li class="page-item disabled"><span class="page-link">...</span></li>';
        }
    }
    
    for ($i = $start; $i <= $end; $i++) {
        if ($i == $current_page) {
            $html .= '<li class="page-item active"><span class="page-link">' . $i . '</span></li>';
        } else {
            $html .= '<li class="page-item"><a class="page-link" href="' . $base_url . '?page=' . $i . $query_string . '">' . $i . '</a></li>';
        }
    }
    
    if ($end < $total_pages) {
        if ($end < $total_pages - 1) {
            $html .= '<li class="page-item disabled"><span class="page-link">...</span></li>';
        }
        $html .= '<li class="page-item"><a class="page-link" href="' . $base_url . '?page=' . $total_pages . $query_string . '">' . $total_pages . '</a></li>';
    }
    
    // Next button
    if ($current_page < $total_pages) {
        $html .= '<li class="page-item"><a class="page-link" href="' . $base_url . '?page=' . ($current_page + 1) . $query_string . '">Next</a></li>';
    } else {
        $html .= '<li class="page-item disabled"><span class="page-link">Next</span></li>';
    }
    
    $html .= '</ul></nav>';
    
    return $html;
}

/**
 * Generate status badge HTML
 */
function getStatusBadge($status, $type = 'default') {
    $badges = [
        'active' => '<span class="badge bg-success">Active</span>',
        'banned' => '<span class="badge bg-danger">Banned</span>',
        'suspended' => '<span class="badge bg-warning">Suspended</span>',
        'pending' => '<span class="badge bg-warning">Pending</span>',
        'approved' => '<span class="badge bg-success">Approved</span>',
        'rejected' => '<span class="badge bg-danger">Rejected</span>',
        'deleted' => '<span class="badge bg-secondary">Deleted</span>',
        'under_review' => '<span class="badge bg-info">Under Review</span>',
        'resolved' => '<span class="badge bg-success">Resolved</span>',
        'dismissed' => '<span class="badge bg-secondary">Dismissed</span>',
    ];
    
    return $badges[$status] ?? '<span class="badge bg-secondary">' . ucfirst($status) . '</span>';
}

/**
 * Generate priority badge HTML
 */
function getPriorityBadge($priority) {
    $badges = [
        'low' => '<span class="badge bg-secondary">Low</span>',
        'medium' => '<span class="badge bg-info">Medium</span>',
        'high' => '<span class="badge bg-warning">High</span>',
        'critical' => '<span class="badge bg-danger">Critical</span>',
    ];
    
    return $badges[$priority] ?? '<span class="badge bg-secondary">' . ucfirst($priority) . '</span>';
}

/**
 * Generate verification badge HTML
 */
function getVerificationBadge($level) {
    if (!$level) return '';
    
    $badges = [
        'basic' => '<span class="badge bg-info"><i class="bi bi-check-circle me-1"></i>Basic</span>',
        'expert' => '<span class="badge bg-success"><i class="bi bi-award me-1"></i>Expert</span>',
        'official' => '<span class="badge bg-primary"><i class="bi bi-patch-check me-1"></i>Official</span>',
    ];
    
    return $badges[$level] ?? '';
}

/**
 * Generate user level badge HTML
 */
function getUserLevelBadge($level) {
    $colors = ['primary', 'success', 'info', 'warning', 'danger'];
    $color = $colors[($level - 1) % count($colors)];
    
    return '<span class="badge bg-' . $color . '">Level ' . $level . '</span>';
}

/**
 * Truncate text
 */
function truncateText($text, $length = 100, $suffix = '...') {
    if (strlen($text) <= $length) {
        return $text;
    }
    
    return substr($text, 0, $length) . $suffix;
}

/**
 * Sanitize output
 */
function e($string) {
    return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
}

/**
 * Get user avatar URL
 */
function getUserAvatar($user) {
    if (!empty($user['profile_picture'])) {
        return $user['profile_picture'];
    }
    
    // Generate avatar from initials
    $initials = strtoupper(substr($user['first_name'], 0, 1) . substr($user['last_name'], 0, 1));
    return "https://ui-avatars.com/api/?name={$initials}&background=random&color=fff&size=40";
}

/**
 * Check if user is online (based on last login)
 */
function isUserOnline($last_login) {
    if (!$last_login) return false;
    
    $login_time = new DateTime($last_login);
    $now = new DateTime();
    $interval = $login_time->diff($now);
    
    return $interval->i < 5; // Online if logged in within last 5 minutes
}

/**
 * Generate CSV export
 */
function generateCSV($data, $filename, $headers = []) {
    header('Content-Type: text/csv');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    
    $output = fopen('php://output', 'w');
    
    // Add BOM for UTF-8
    fwrite($output, "\xEF\xBB\xBF");
    
    // Write headers
    if (!empty($headers)) {
        fputcsv($output, $headers);
    }
    
    // Write data
    foreach ($data as $row) {
        fputcsv($output, $row);
    }
    
    fclose($output);
    exit;
}

/**
 * Log admin action (for manual logging)
 */
function logAction($action_type, $target_type, $target_id, $old_values = null, $new_values = null) {
    global $auth;
    $user = getCurrentUser();
    
    if ($user) {
        $auth->logAdminAction($user['user_id'], $action_type, $target_type, $target_id, $old_values, $new_values);
    }
}

/**
 * Get chart colors
 */
function getChartColors() {
    return [
        'primary' => '#0d6efd',
        'success' => '#198754',
        'info' => '#0dcaf0',
        'warning' => '#ffc107',
        'danger' => '#dc3545',
        'secondary' => '#6c757d',
        'light' => '#f8f9fa',
        'dark' => '#212529'
    ];
}

/**
 * Format number with commas
 */
function formatNumber($number) {
    return number_format($number, 0, '.', ',');
}

/**
 * Calculate percentage
 */
function calculatePercentage($value, $total) {
    if ($total == 0) return 0;
    return round(($value / $total) * 100, 1);
}

/**
 * Check if date is today
 */
function isToday($dateString) {
    $date = new DateTime($dateString);
    $today = new DateTime();
    return $date->format('Y-m-d') === $today->format('Y-m-d');
}

/**
 * Get time ago in words
 */
function timeAgo($dateString) {
    $date = new DateTime($dateString);
    $now = new DateTime();
    $interval = $date->diff($now);
    
    if ($interval->y > 0) {
        return $interval->y . ' year' . ($interval->y > 1 ? 's' : '') . ' ago';
    } elseif ($interval->m > 0) {
        return $interval->m . ' month' . ($interval->m > 1 ? 's' : '') . ' ago';
    } elseif ($interval->d > 0) {
        return $interval->d . ' day' . ($interval->d > 1 ? 's' : '') . ' ago';
    } elseif ($interval->h > 0) {
        return $interval->h . ' hour' . ($interval->h > 1 ? 's' : '') . ' ago';
    } elseif ($interval->i > 0) {
        return $interval->i . ' minute' . ($interval->i > 1 ? 's' : '') . ' ago';
    } else {
        return 'Just now';
    }
}
?>
