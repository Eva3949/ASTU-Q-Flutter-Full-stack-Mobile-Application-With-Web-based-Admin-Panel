<?php
/**
 * Admin User Control System
 * ASTU-Q Admin Control Panel - Complete User Management
 */

require_once 'db_connection.php';

// Check admin session
session_start();
if (!isset($_SESSION['admin_logged_in'])) {
    header('Location: admin_login.php');
    exit;
}

// Handle API requests
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['api'])) {
    header("Content-Type: application/json");
    
    $action = $_GET['action'] ?? 'list';
    
    try {
        switch ($action) {
            case 'list':
                $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
                $limit = 10;
                $offset = ($page - 1) * $limit;
                $search = $_GET['search'] ?? '';
                $role = $_GET['role'] ?? '';
                $status = $_GET['status'] ?? '';
                
                $whereClause = "1=1";
                $params = [];
                
                if ($search) {
                    $whereClause .= " AND (u.username LIKE :search OR u.email LIKE :search)";
                    $params[':search'] = "%$search%";
                }
                
                if ($role) {
                    $whereClause .= " AND u.role = :role";
                    $params[':role'] = $role;
                }
                
                if ($status) {
                    $whereClause .= " AND u.status = :status";
                    $params[':status'] = $status;
                }
                
                $stmt = $pdo->prepare("
                    SELECT u.*, 
                           (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id) as question_count,
                           (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id) as answer_count,
                           (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1) as best_answer_count,
                           (SELECT SUM(CASE WHEN q.status = 'approved' THEN 1 ELSE 0 END) FROM questions WHERE user_id = u.user_id) as approved_questions
                    FROM users u 
                    WHERE $whereClause
                    ORDER BY u.created_at DESC 
                    LIMIT :limit OFFSET :offset
                ");
                
                foreach ($params as $key => $value) {
                    $stmt->bindValue($key, $value);
                }
                $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
                $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
                $stmt->execute();
                $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Calculate points for each user
                foreach ($users as &$user) {
                    $user['points'] = ($user['question_count'] * 10) + ($user['answer_count'] * 5) + ($user['best_answer_count'] * 20);
                }
                
                $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE $whereClause");
                foreach ($params as $key => $value) {
                    $countStmt->bindValue($key, $value);
                }
                $countStmt->execute();
                $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'users' => $users,
                        'pagination' => [
                            'current_page' => $page,
                            'total_pages' => ceil($total / $limit),
                            'total_items' => (int)$total,
                            'items_per_page' => $limit
                        ]
                    ]
                ]);
                break;
                
            case 'stats':
                // Get user statistics
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users");
                $stmt->execute();
                $totalUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE status = 'active'");
                $stmt->execute();
                $activeUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
                $stmt->execute();
                $newUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE status = 'suspended'");
                $stmt->execute();
                $suspendedUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'total_users' => (int)$totalUsers,
                        'active_users' => (int)$activeUsers,
                        'new_users' => (int)$newUsers,
                        'suspended_users' => (int)$suspendedUsers
                    ]
                ]);
                break;
                
            case 'top_users':
                $stmt = $pdo->prepare("
                    SELECT u.*, 
                           (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id) as question_count,
                           (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id) as answer_count,
                           (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1) as best_answer_count
                    FROM users u 
                    WHERE u.status = 'active'
                    ORDER BY best_answer_count DESC, answer_count DESC, question_count DESC 
                    LIMIT 10
                ");
                $stmt->execute();
                $topUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                foreach ($topUsers as &$user) {
                    $user['points'] = ($user['question_count'] * 10) + ($user['answer_count'] * 5) + ($user['best_answer_count'] * 20);
                }
                
                echo json_encode([
                    'success' => true,
                    'data' => $topUsers
                ]);
                break;
                
            default:
                echo json_encode(['success' => false, 'message' => 'Invalid action']);
        }
    } catch (PDOException $e) {
        error_log("Database error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Database error occurred']);
    } catch (Exception $e) {
        error_log("General error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'An error occurred']);
    }
    exit;
}

// Handle POST actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header("Content-Type: application/json");
    
    $action = $_POST['action'] ?? '';
    
    try {
        switch ($action) {
            case 'suspend':
                $userId = $_POST['user_id'] ?? null;
                $reason = $_POST['reason'] ?? '';
                
                if (!$userId) {
                    echo json_encode(['success' => false, 'message' => 'User ID is required']);
                    exit;
                }
                
                $stmt = $pdo->prepare("
                    UPDATE users 
                    SET status = 'suspended', suspension_reason = :reason, updated_at = NOW() 
                    WHERE user_id = :user_id
                ");
                $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $stmt->bindParam(':reason', $reason, PDO::PARAM_STR);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    echo json_encode(['success' => true, 'message' => 'User suspended successfully']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'User not found']);
                }
                break;
                
            case 'activate':
                $userId = $_POST['user_id'] ?? null;
                
                if (!$userId) {
                    echo json_encode(['success' => false, 'message' => 'User ID is required']);
                    exit;
                }
                
                $stmt = $pdo->prepare("
                    UPDATE users 
                    SET status = 'active', suspension_reason = NULL, updated_at = NOW() 
                    WHERE user_id = :user_id
                ");
                $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    echo json_encode(['success' => true, 'message' => 'User activated successfully']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'User not found']);
                }
                break;
                
            case 'delete':
                $userId = $_POST['user_id'] ?? null;
                
                if (!$userId) {
                    echo json_encode(['success' => false, 'message' => 'User ID is required']);
                    exit;
                }
                
                $stmt = $pdo->prepare("
                    UPDATE users 
                    SET status = 'deleted', updated_at = NOW() 
                    WHERE user_id = :user_id
                ");
                $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    echo json_encode(['success' => true, 'message' => 'User deleted successfully']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'User not found']);
                }
                break;
                
            case 'update_role':
                $userId = $_POST['user_id'] ?? null;
                $role = $_POST['role'] ?? 'user';
                
                if (!$userId) {
                    echo json_encode(['success' => false, 'message' => 'User ID is required']);
                    exit;
                }
                
                $stmt = $pdo->prepare("
                    UPDATE users 
                    SET role = :role, updated_at = NOW() 
                    WHERE user_id = :user_id
                ");
                $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $stmt->bindParam(':role', $role, PDO::PARAM_STR);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    echo json_encode(['success' => true, 'message' => 'User role updated successfully']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'User not found']);
                }
                break;
                
            default:
                echo json_encode(['success' => false, 'message' => 'Invalid action']);
        }
    } catch (PDOException $e) {
        error_log("Database error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Database error occurred']);
    } catch (Exception $e) {
        error_log("General error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'An error occurred']);
    }
    exit;
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Control - ASTU-Q Admin Panel</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f6fa;
            color: #333;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1rem 2rem;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 1000;
        }

        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 100%;
        }

        .logo h1 {
            font-size: 24px;
            font-weight: bold;
        }

        .menu-toggle {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            padding: 8px 12px;
            border-radius: 5px;
            cursor: pointer;
            display: none;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .user-info span {
            font-size: 14px;
        }

        .logout-btn {
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 5px;
            cursor: pointer;
            transition: background 0.3s;
        }

        .logout-btn:hover {
            background: rgba(255, 255, 255, 0.3);
        }

        .sidebar {
            position: fixed;
            top: 70px;
            left: 0;
            width: 250px;
            height: calc(100vh - 70px);
            background: white;
            box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
            overflow-y: auto;
            z-index: 999;
            transition: transform 0.3s;
        }

        .sidebar.collapsed {
            transform: translateX(-250px);
        }

        .sidebar-header {
            padding: 1.5rem;
            border-bottom: 1px solid #eee;
        }

        .sidebar-header h3 {
            color: #333;
            font-size: 18px;
        }

        .sidebar-menu {
            padding: 1rem 0;
        }

        .menu-item {
            display: block;
            padding: 0.75rem 1.5rem;
            color: #333;
            text-decoration: none;
            transition: background 0.3s;
            border: none;
            background: none;
            width: 100%;
            text-align: left;
            cursor: pointer;
            font-size: 14px;
        }

        .menu-item:hover {
            background: #f8f9fa;
        }

        .menu-item.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .submenu {
            background: #f8f9fa;
            display: none;
        }

        .submenu.open {
            display: block;
        }

        .submenu .menu-item {
            padding-left: 3rem;
            font-size: 13px;
        }

        .main-content {
            margin-left: 250px;
            padding-top: 90px;
            min-height: 100vh;
            transition: margin-left 0.3s;
        }

        .main-content.expanded {
            margin-left: 0;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 2rem 2rem;
        }

        .page-header {
            margin-bottom: 2rem;
        }

        .page-header h1 {
            color: #333;
            margin-bottom: 0.5rem;
        }

        .page-header p {
            color: #666;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-card h3 {
            color: #667eea;
            font-size: 14px;
            text-transform: uppercase;
            margin-bottom: 0.5rem;
        }

        .stat-card .number {
            font-size: 32px;
            font-weight: bold;
            color: #333;
            margin-bottom: 0.5rem;
        }

        .stat-card .change {
            font-size: 12px;
            color: #666;
        }

        .filters {
            background: white;
            padding: 1.5rem;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 2rem;
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
            align-items: center;
        }

        .filter-group {
            display: flex;
            gap: 0.5rem;
            align-items: center;
        }

        .filter-group label {
            font-weight: 500;
            color: #555;
        }

        .filter-group select,
        .filter-group input {
            padding: 8px 12px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 14px;
        }

        .filter-group select:focus,
        .filter-group input:focus {
            outline: none;
            border-color: #667eea;
        }

        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s;
        }

        .btn-primary {
            background: #667eea;
            color: white;
        }

        .btn-primary:hover {
            background: #5a67d8;
        }

        .users-table {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }

        .table-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1rem 1.5rem;
            font-weight: bold;
        }

        .table-content {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            padding: 1rem;
            text-align: left;
            border-bottom: 1px solid #eee;
        }

        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }

        tr:hover {
            background: #f8f9fa;
        }

        .user-info-cell {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }

        .user-details {
            flex: 1;
        }

        .user-name {
            font-weight: bold;
            color: #333;
            margin-bottom: 0.25rem;
        }

        .user-email {
            font-size: 12px;
            color: #666;
        }

        .status-badge {
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: 500;
        }

        .status-active {
            background: #d4edda;
            color: #155724;
        }

        .status-suspended {
            background: #fff3cd;
            color: #856404;
        }

        .status-deleted {
            background: #f8d7da;
            color: #721c24;
        }

        .role-badge {
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: 500;
            background: #e7f3ff;
            color: #0066cc;
        }

        .stats-row {
            display: flex;
            gap: 1rem;
            font-size: 12px;
            color: #666;
        }

        .stat-item {
            display: flex;
            align-items: center;
            gap: 0.25rem;
        }

        .actions {
            display: flex;
            gap: 0.5rem;
        }

        .btn-sm {
            padding: 4px 8px;
            font-size: 12px;
        }

        .btn-suspend {
            background: #fdcb6e;
            color: #333;
        }

        .btn-suspend:hover {
            background: #f39c12;
        }

        .btn-activate {
            background: #00b894;
            color: white;
        }

        .btn-activate:hover {
            background: #00a885;
        }

        .btn-delete {
            background: #ff4757;
            color: white;
        }

        .btn-delete:hover {
            background: #ff3838;
        }

        .btn-view {
            background: #667eea;
            color: white;
        }

        .btn-view:hover {
            background: #5a67d8;
        }

        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 1rem;
            margin-top: 2rem;
        }

        .pagination button {
            padding: 8px 12px;
            border: 1px solid #ddd;
            background: white;
            cursor: pointer;
            border-radius: 5px;
        }

        .pagination button:hover {
            background: #f8f9fa;
        }

        .pagination button.active {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }

        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 1000;
        }

        .modal-content {
            background: white;
            margin: 5% auto;
            padding: 2rem;
            border-radius: 10px;
            max-width: 600px;
            max-height: 80vh;
            overflow-y: auto;
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
        }

        .modal-header h2 {
            color: #333;
        }

        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #666;
        }

        .user-details-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .detail-item {
            padding: 0.5rem 0;
        }

        .detail-label {
            font-weight: bold;
            color: #333;
            margin-bottom: 0.25rem;
        }

        .detail-value {
            color: #666;
        }

        .modal-actions {
            display: flex;
            gap: 1rem;
            justify-content: flex-end;
            margin-top: 2rem;
        }

        .loading {
            text-align: center;
            padding: 2rem;
            color: #666;
        }

        .loading::after {
            content: '';
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid #f3f3f3;
            border-top: 3px solid #667eea;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-left: 10px;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .error {
            background: #ff4757;
            color: white;
            padding: 1rem;
            border-radius: 5px;
            margin-bottom: 1rem;
        }

        .success {
            background: #00b894;
            color: white;
            padding: 1rem;
            border-radius: 5px;
            margin-bottom: 1rem;
        }

        @media (max-width: 768px) {
            .menu-toggle {
                display: block;
            }
            
            .sidebar {
                transform: translateX(-250px);
            }
            
            .sidebar:not(.collapsed) {
                transform: translateX(0);
            }
            
            .main-content {
                margin-left: 0;
            }
            
            .filters {
                flex-direction: column;
                align-items: stretch;
            }
            
            .table-content {
                overflow-x: auto;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="logo">
                <button class="menu-toggle" onclick="toggleSidebar()">Menu</button>
                <h1>ASTU-Q Admin Panel</h1>
            </div>
            <div class="user-info">
                <span>Welcome, <strong><?php echo htmlspecialchars($_SESSION['admin_username']); ?></strong></span>
                <span>Role: <?php echo htmlspecialchars($_SESSION['admin_role'] ?? 'Administrator'); ?></span>
                <button class="logout-btn" onclick="logout()">Logout</button>
            </div>
        </div>
    </div>

    <div class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <h3>Navigation</h3>
        </div>
        <div class="sidebar-menu">
            <a href="admin_dashboard.php" class="menu-item">
                Dashboard
            </a>
            
            <button class="menu-item" onclick="toggleSubmenu('content-menu')">
                Content Management
            </button>
            <div class="submenu" id="content-menu">
                <a href="admin_approve_questions.php" class="menu-item">
                    Questions
                </a>
                <a href="admin_approve_answers.php" class="menu-item">
                    Answers
                </a>
                <a href="admin_content_moderation.php" class="menu-item">
                    Content Moderation
                </a>
            </div>
            
            <button class="menu-item" onclick="toggleSubmenu('user-menu')">
                User Management
            </button>
            <div class="submenu" id="user-menu">
                <a href="admin_user_control.php" class="menu-item active">
                    User Control
                </a>
                <a href="admin_user_roles.php" class="menu-item">
                    User Roles
                </a>
                <a href="admin_user_activity.php" class="menu-item">
                    User Activity
                </a>
            </div>
            
            <button class="menu-item" onclick="toggleSubmenu('analytics-menu')">
                Analytics
            </button>
            <div class="submenu" id="analytics-menu">
                <a href="admin_analytics.php" class="menu-item">
                    Analytics Dashboard
                </a>
                <a href="admin_reports.php" class="menu-item">
                    Reports
                </a>
                <a href="admin_leaderboard.php" class="menu-item">
                    Leaderboard
                </a>
            </div>
            
            <button class="menu-item" onclick="toggleSubmenu('system-menu')">
                System Control
            </button>
            <div class="submenu" id="system-menu">
                <a href="admin_settings.php" class="menu-item">
                    Settings
                </a>
                <a href="admin_system_health.php" class="menu-item">
                    System Health
                </a>
                <a href="admin_logs.php" class="menu-item">
                    System Logs
                </a>
                <a href="admin_maintenance.php" class="menu-item">
                    Maintenance
                </a>
            </div>
        </div>
    </div>

    <div class="main-content" id="main-content">
        <div class="container">
            <div id="error-message" class="error" style="display: none;"></div>
            <div id="success-message" class="success" style="display: none;"></div>
            
            <div class="page-header">
                <h1>User Control Center</h1>
                <p>Complete user management and control system</p>
            </div>

            <div class="stats-grid" id="user-stats">
                <div class="loading">Loading user statistics...</div>
            </div>

            <div class="filters">
                <div class="filter-group">
                    <label for="status-filter">Status:</label>
                    <select id="status-filter" onchange="filterUsers()">
                        <option value="">All</option>
                        <option value="active">Active</option>
                        <option value="suspended">Suspended</option>
                        <option value="deleted">Deleted</option>
                    </select>
                </div>
                <div class="filter-group">
                    <label for="role-filter">Role:</label>
                    <select id="role-filter" onchange="filterUsers()">
                        <option value="">All</option>
                        <option value="user">User</option>
                        <option value="moderator">Moderator</option>
                        <option value="admin">Admin</option>
                    </select>
                </div>
                <div class="filter-group">
                    <label for="search-input">Search:</label>
                    <input type="text" id="search-input" placeholder="Search users..." onkeyup="filterUsers()">
                </div>
                <button class="btn btn-primary" onclick="filterUsers()">Search</button>
            </div>

            <div class="users-table">
                <div class="table-header">User Management</div>
                <div class="table-content">
                    <table id="users-table">
                        <thead>
                            <tr>
                                <th>User</th>
                                <th>Role</th>
                                <th>Status</th>
                                <th>Statistics</th>
                                <th>Points</th>
                                <th>Joined</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="users-tbody">
                            <tr>
                                <td colspan="7" class="loading">Loading users...</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="pagination" id="pagination">
                <!-- Pagination will be generated dynamically -->
            </div>
        </div>
    </div>

    <!-- User Details Modal -->
    <div id="user-modal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>User Details</h2>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <div id="modal-body">
                <!-- User details will be loaded here -->
            </div>
        </div>
    </div>

    <script>
        let currentPage = 1;
        let currentStatus = '';
        let currentRole = '';
        let currentSearch = '';

        // Sidebar functionality
        function toggleSidebar() {
            const sidebar = document.getElementById('sidebar');
            const mainContent = document.getElementById('main-content');
            sidebar.classList.toggle('collapsed');
            mainContent.classList.toggle('expanded');
        }

        function toggleSubmenu(menuId) {
            const submenu = document.getElementById(menuId);
            submenu.classList.toggle('open');
        }

        // Load user statistics
        function loadUserStats() {
            fetch('admin_user_control.php?api=1&action=stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderUserStats(data.data);
                    } else {
                        showError('Failed to load user statistics: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading user statistics: ' + error.message));
        }

        // Render user statistics
        function renderUserStats(stats) {
            const container = document.getElementById('user-stats');
            container.innerHTML = `
                <div class="stat-card">
                    <h3>Total Users</h3>
                    <div class="number">${stats.total_users}</div>
                    <div class="change">All registered users</div>
                </div>
                <div class="stat-card">
                    <h3>Active Users</h3>
                    <div class="number">${stats.active_users}</div>
                    <div class="change positive">${Math.floor((stats.active_users / stats.total_users) * 100)}% active rate</div>
                </div>
                <div class="stat-card">
                    <h3>New Users</h3>
                    <div class="number">${stats.new_users}</div>
                    <div class="change positive">This week</div>
                </div>
                <div class="stat-card">
                    <h3>Suspended</h3>
                    <div class="number">${stats.suspended_users}</div>
                    <div class="change">Under review</div>
                </div>
            `;
        }

        // Load users
        function loadUsers(page = 1, status = '', role = '', search = '') {
            currentPage = page;
            currentStatus = status;
            currentRole = role;
            currentSearch = search;
            
            fetch(`admin_user_control.php?api=1&action=list&page=${page}&status=${status}&role=${role}&search=${encodeURIComponent(search)}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderUsers(data.data.users);
                        renderPagination(data.data.pagination);
                    } else {
                        showError('Failed to load users: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading users: ' + error.message));
        }

        // Render users
        function renderUsers(users) {
            const tbody = document.getElementById('users-tbody');
            
            if (users.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: #666;">No users found</td></tr>';
                return;
            }

            tbody.innerHTML = users.map(user => `
                <tr>
                    <td>
                        <div class="user-info-cell">
                            <div class="user-avatar">${user.name ? user.name.charAt(0).toUpperCase() : 'U'}</div>
                            <div class="user-details">
                                <div class="user-name">${user.name || 'Unknown User'}</div>
                                <div class="user-email">${user.email}</div>
                            </div>
                        </div>
                    </td>
                    <td><span class="role-badge">${user.role || 'user'}</span></td>
                    <td><span class="status-badge status-${user.status || 'active'}">${user.status || 'active'}</span></td>
                    <td>
                        <div class="stats-row">
                            <div class="stat-item">Q: ${user.question_count || 0}</div>
                            <div class="stat-item">A: ${user.answer_count || 0}</div>
                            <div class="stat-item">Best: ${user.best_answer_count || 0}</div>
                        </div>
                    </td>
                    <td><strong>${user.points || 0}</strong></td>
                    <td>${new Date(user.created_at).toLocaleDateString()}</td>
                    <td>
                        <div class="actions">
                            <button class="btn btn-sm btn-view" onclick="viewUser(${user.user_id})">View</button>
                            ${user.status === 'active' ? `
                                <button class="btn btn-sm btn-suspend" onclick="suspendUser(${user.user_id})">Suspend</button>
                            ` : user.status === 'suspended' ? `
                                <button class="btn btn-sm btn-activate" onclick="activateUser(${user.user_id})">Activate</button>
                            ` : ''}
                            <button class="btn btn-sm btn-delete" onclick="deleteUser(${user.user_id})">Delete</button>
                        </div>
                    </td>
                </tr>
            `).join('');
        }

        // Render pagination
        function renderPagination(pagination) {
            const container = document.getElementById('pagination');
            
            let html = '';
            
            // Previous button
            html += `<button ${pagination.current_page <= 1 ? 'disabled' : ''} onclick="loadUsers(${pagination.current_page - 1}, '${currentStatus}', '${currentRole}', '${currentSearch}')">Previous</button>`;
            
            // Page numbers
            for (let i = 1; i <= pagination.total_pages; i++) {
                html += `<button class="${i === pagination.current_page ? 'active' : ''}" onclick="loadUsers(${i}, '${currentStatus}', '${currentRole}', '${currentSearch}')">${i}</button>`;
            }
            
            // Next button
            html += `<button ${pagination.current_page >= pagination.total_pages ? 'disabled' : ''} onclick="loadUsers(${pagination.current_page + 1}, '${currentStatus}', '${currentRole}', '${currentSearch}')">Next</button>`;
            
            container.innerHTML = html;
        }

        // Filter users
        function filterUsers() {
            const status = document.getElementById('status-filter').value;
            const role = document.getElementById('role-filter').value;
            const search = document.getElementById('search-input').value;
            loadUsers(1, status, role, search);
        }

        // View user details
        function viewUser(userId) {
            // For now, show a simple modal with user info
            const modal = document.getElementById('user-modal');
            const modalBody = document.getElementById('modal-body');
            
            modalBody.innerHTML = `
                <div class="user-details-grid">
                    <div class="detail-item">
                        <div class="detail-label">User ID</div>
                        <div class="detail-value">${userId}</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Status</div>
                        <div class="detail-value">Active</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Role</div>
                        <div class="detail-value">User</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Joined</div>
                        <div class="detail-value">${new Date().toLocaleDateString()}</div>
                    </div>
                </div>
                
                <div class="modal-actions">
                    <button class="btn btn-suspend" onclick="suspendUser(${userId}, true)">Suspend User</button>
                    <button class="btn btn-delete" onclick="deleteUser(${userId}, true)">Delete User</button>
                    <button class="btn" onclick="closeModal()">Close</button>
                </div>
            `;
            
            modal.style.display = 'block';
        }

        // Close modal
        function closeModal() {
            document.getElementById('user-modal').style.display = 'none';
        }

        // Suspend user
        function suspendUser(userId, closeModal = false) {
            const reason = prompt('Please provide a reason for suspension:');
            if (reason) {
                fetch('admin_user_control.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `action=suspend&user_id=${userId}&reason=${encodeURIComponent(reason)}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess('User suspended successfully');
                        if (closeModal) closeModal();
                        loadUsers(currentPage, currentStatus, currentRole, currentSearch);
                        loadUserStats();
                    } else {
                        showError('Failed to suspend user: ' + data.message);
                    }
                })
                .catch(error => showError('Error suspending user: ' + error.message));
            }
        }

        // Activate user
        function activateUser(userId) {
            if (confirm('Are you sure you want to activate this user?')) {
                fetch('admin_user_control.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `action=activate&user_id=${userId}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess('User activated successfully');
                        loadUsers(currentPage, currentStatus, currentRole, currentSearch);
                        loadUserStats();
                    } else {
                        showError('Failed to activate user: ' + data.message);
                    }
                })
                .catch(error => showError('Error activating user: ' + error.message));
            }
        }

        // Delete user
        function deleteUser(userId, closeModal = false) {
            if (confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
                fetch('admin_user_control.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `action=delete&user_id=${userId}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess('User deleted successfully');
                        if (closeModal) closeModal();
                        loadUsers(currentPage, currentStatus, currentRole, currentSearch);
                        loadUserStats();
                    } else {
                        showError('Failed to delete user: ' + data.message);
                    }
                })
                .catch(error => showError('Error deleting user: ' + error.message));
            }
        }

        // Logout function
        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'admin_logout.php';
            }
        }

        // Show messages
        function showError(message) {
            const errorDiv = document.getElementById('error-message');
            errorDiv.textContent = message;
            errorDiv.style.display = 'block';
            setTimeout(() => errorDiv.style.display = 'none', 5000);
        }

        function showSuccess(message) {
            const successDiv = document.getElementById('success-message');
            successDiv.textContent = message;
            successDiv.style.display = 'block';
            setTimeout(() => successDiv.style.display = 'none', 5000);
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('user-modal');
            if (event.target === modal) {
                closeModal();
            }
        }

        // Load data on page load
        document.addEventListener('DOMContentLoaded', () => {
            loadUserStats();
            loadUsers();
        });
    </script>
</body>
</html>
