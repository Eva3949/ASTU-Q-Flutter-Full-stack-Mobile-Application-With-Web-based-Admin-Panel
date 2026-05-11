<?php
/**
 * Admin Leaderboard Management System
 * ASTU-Q Admin Control Panel - Leaderboard Control
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
    
    $action = $_GET['action'] ?? 'leaderboard';
    
    try {
        switch ($action) {
            case 'leaderboard':
                $period = $_GET['period'] ?? 'all';
                $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
                $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
                $offset = ($page - 1) * $limit;
                
                $whereClause = "u.status = 'active'";
                $params = [];
                
                if ($period === 'week') {
                    $whereClause .= " AND u.created_at >= DATE_SUB(NOW(), INTERVAL 1 WEEK)";
                } elseif ($period === 'month') {
                    $whereClause .= " AND u.created_at >= DATE_SUB(NOW(), INTERVAL 1 MONTH)";
                }
                
                $stmt = $pdo->prepare("
                    SELECT 
                        u.user_id,
                        u.username,
                        u.name,
                        u.email,
                        u.created_at,
                        u.last_login,
                        (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id AND status = 'approved') as question_count,
                        (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id) as answer_count,
                        (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1) as best_answer_count,
                        (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id AND status = 'approved' AND created_at >= DATE_SUB(NOW(), INTERVAL 1 WEEK)) as weekly_questions,
                        (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND created_at >= DATE_SUB(NOW(), INTERVAL 1 WEEK)) as weekly_answers,
                        (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1 AND created_at >= DATE_SUB(NOW(), INTERVAL 1 WEEK)) as weekly_best_answers
                    FROM users u
                    WHERE $whereClause
                    ORDER BY best_answer_count DESC, answer_count DESC, question_count DESC
                    LIMIT :limit OFFSET :offset
                ");
                
                $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
                $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
                $stmt->execute();
                $leaderboard = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Calculate points for each user
                foreach ($leaderboard as &$user) {
                    $user['total_points'] = ($user['question_count'] * 10) + ($user['answer_count'] * 5) + ($user['best_answer_count'] * 20);
                    $user['weekly_points'] = ($user['weekly_questions'] * 10) + ($user['weekly_answers'] * 5) + ($user['weekly_best_answers'] * 20);
                    $user['rank'] = 0; // Will be calculated below
                }
                
                // Calculate ranks
                for ($i = 0; $i < count($leaderboard); $i++) {
                    $leaderboard[$i]['rank'] = $i + 1 + $offset;
                }
                
                // Get total count for pagination
                $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE $whereClause");
                $countStmt->execute();
                $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'leaderboard' => $leaderboard,
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
                // Get leaderboard statistics
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE status = 'active'");
                $stmt->execute();
                $totalUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM answers WHERE is_best_answer = 1");
                $stmt->execute();
                $totalBestAnswers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM questions WHERE status = 'approved'");
                $stmt->execute();
                $totalQuestions = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM answers");
                $stmt->execute();
                $totalAnswers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                // Top performer this week
                $stmt = $pdo->prepare("
                    SELECT 
                        u.username,
                        (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1 AND created_at >= DATE_SUB(NOW(), INTERVAL 1 WEEK)) as weekly_best
                    FROM users u
                    WHERE u.status = 'active'
                    ORDER BY weekly_best DESC
                    LIMIT 1
                ");
                $stmt->execute();
                $topPerformer = $stmt->fetch(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'total_users' => (int)$totalUsers,
                        'total_best_answers' => (int)$totalBestAnswers,
                        'total_questions' => (int)$totalQuestions,
                        'total_answers' => (int)$totalAnswers,
                        'top_performer' => $topPerformer
                    ]
                ]);
                break;
                
            case 'top_performers':
                $period = $_GET['period'] ?? 'all';
                $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
                
                if ($period === 'week') {
                    $stmt = $pdo->prepare("
                        SELECT 
                            u.username,
                            u.name,
                            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1 AND created_at >= DATE_SUB(NOW(), INTERVAL 1 WEEK)) as weekly_best,
                            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND created_at >= DATE_SUB(NOW(), INTERVAL 1 WEEK)) as weekly_answers
                        FROM users u
                        WHERE u.status = 'active'
                        ORDER BY weekly_best DESC, weekly_answers DESC
                        LIMIT :limit
                    ");
                    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
                    $stmt->execute();
                    $performers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    foreach ($performers as &$performer) {
                        $performer['weekly_points'] = ($performer['weekly_answers'] * 5) + ($performer['weekly_best'] * 20);
                    }
                } else {
                    $stmt = $pdo->prepare("
                        SELECT 
                            u.username,
                            u.name,
                            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1) as total_best,
                            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id) as total_answers,
                            (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id AND status = 'approved') as total_questions
                        FROM users u
                        WHERE u.status = 'active'
                        ORDER BY total_best DESC, total_answers DESC, total_questions DESC
                        LIMIT :limit
                    ");
                    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
                    $stmt->execute();
                    $performers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    foreach ($performers as &$performer) {
                        $performer['total_points'] = ($performer['total_questions'] * 10) + ($performer['total_answers'] * 5) + ($performer['total_best'] * 20);
                    }
                }
                
                echo json_encode([
                    'success' => true,
                    'data' => $performers
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
            case 'reset_leaderboard':
                // Reset leaderboard (recalculate all points)
                $stmt = $pdo->prepare("
                    UPDATE users u SET 
                        points = (
                            (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id AND status = 'approved') * 10 +
                            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id) * 5 +
                            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1) * 20
                        )
                    WHERE u.status = 'active'
                ");
                $stmt->execute();
                
                echo json_encode(['success' => true, 'message' => 'Leaderboard reset successfully']);
                break;
                
            case 'update_points':
                $userId = $_POST['user_id'] ?? null;
                $points = $_POST['points'] ?? 0;
                
                if (!$userId) {
                    echo json_encode(['success' => false, 'message' => 'User ID is required']);
                    exit;
                }
                
                $stmt = $pdo->prepare("UPDATE users SET points = :points, updated_at = NOW() WHERE user_id = :user_id");
                $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $stmt->bindParam(':points', $points, PDO::PARAM_INT);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    echo json_encode(['success' => true, 'message' => 'Points updated successfully']);
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
    <title>Leaderboard Management - ASTU-Q Admin Panel</title>
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

        .controls {
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

        .control-group {
            display: flex;
            gap: 0.5rem;
            align-items: center;
        }

        .control-group label {
            font-weight: 500;
            color: #555;
        }

        .control-group select {
            padding: 8px 12px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 14px;
        }

        .control-group select:focus {
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

        .btn-danger {
            background: #ff4757;
            color: white;
        }

        .btn-danger:hover {
            background: #ff3838;
        }

        .leaderboard-section {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .leaderboard-table {
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
            max-height: 600px;
            overflow-y: auto;
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
            position: sticky;
            top: 0;
        }

        tr:hover {
            background: #f8f9fa;
        }

        .rank-cell {
            font-weight: bold;
            font-size: 18px;
            text-align: center;
            width: 60px;
        }

        .rank-1 { color: #ffd700; }
        .rank-2 { color: #c0c0c0; }
        .rank-3 { color: #cd7f32; }

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

        .points-cell {
            font-weight: bold;
            font-size: 18px;
            color: #667eea;
            text-align: center;
        }

        .top-performers {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }

        .performer-item {
            padding: 1rem;
            border-bottom: 1px solid #eee;
            display: flex;
            align-items: center;
            gap: 1rem;
            transition: background 0.3s;
        }

        .performer-item:hover {
            background: #f8f9fa;
        }

        .performer-item:last-child {
            border-bottom: none;
        }

        .performer-rank {
            width: 30px;
            height: 30px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 14px;
        }

        .performer-info {
            flex: 1;
        }

        .performer-name {
            font-weight: bold;
            color: #333;
            margin-bottom: 0.25rem;
        }

        .performer-stats {
            font-size: 12px;
            color: #666;
        }

        .performer-points {
            font-weight: bold;
            color: #667eea;
            font-size: 16px;
        }

        .chart-container {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        .chart-header {
            margin-bottom: 1rem;
        }

        .chart-header h3 {
            color: #333;
            margin-bottom: 0.5rem;
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
            
            .leaderboard-section {
                grid-template-columns: 1fr;
            }
            
            .controls {
                flex-direction: column;
                align-items: stretch;
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
                <a href="admin_user_control.php" class="menu-item">
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
                <a href="admin_leaderboard.php" class="menu-item active">
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
                <h1>Leaderboard Management</h1>
                <p>Control and monitor user rankings and performance</p>
            </div>

            <div class="stats-grid" id="leaderboard-stats">
                <div class="loading">Loading leaderboard statistics...</div>
            </div>

            <div class="controls">
                <div class="control-group">
                    <label for="period-filter">Period:</label>
                    <select id="period-filter" onchange="loadLeaderboard()">
                        <option value="all">All Time</option>
                        <option value="week">This Week</option>
                        <option value="month">This Month</option>
                    </select>
                </div>
                <div class="control-group">
                    <label for="limit-filter">Show:</label>
                    <select id="limit-filter" onchange="loadLeaderboard()">
                        <option value="50">Top 50</option>
                        <option value="100">Top 100</option>
                        <option value="20">Top 20</option>
                        <option value="10">Top 10</option>
                    </select>
                </div>
                <button class="btn btn-primary" onclick="loadLeaderboard()">Refresh</button>
                <button class="btn btn-danger" onclick="resetLeaderboard()">Reset Leaderboard</button>
            </div>

            <div class="leaderboard-section">
                <div class="leaderboard-table">
                    <div class="table-header">User Rankings</div>
                    <div class="table-content">
                        <table id="leaderboard-table">
                            <thead>
                                <tr>
                                    <th>Rank</th>
                                    <th>User</th>
                                    <th>Statistics</th>
                                    <th>Points</th>
                                </tr>
                            </thead>
                            <tbody id="leaderboard-tbody">
                                <tr>
                                    <td colspan="4" class="loading">Loading leaderboard...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="top-performers">
                    <div class="table-header">Top Performers</div>
                    <div id="top-performers">
                        <div class="loading">Loading top performers...</div>
                    </div>
                </div>
            </div>

            <div class="chart-container">
                <div class="chart-header">
                    <h3>Points Distribution</h3>
                    <p>Visual representation of user points distribution</p>
                </div>
                <canvas id="pointsChart" width="400" height="200"></canvas>
            </div>

            <div class="pagination" id="pagination">
                <!-- Pagination will be generated dynamically -->
            </div>
        </div>
    </div>

    <script>
        let currentPage = 1;
        let currentPeriod = 'all';
        let currentLimit = 50;

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

        // Load leaderboard statistics
        function loadLeaderboardStats() {
            fetch('admin_leaderboard.php?api=1&action=stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderLeaderboardStats(data.data);
                    } else {
                        showError('Failed to load leaderboard statistics: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading leaderboard statistics: ' + error.message));
        }

        // Render leaderboard statistics
        function renderLeaderboardStats(stats) {
            const container = document.getElementById('leaderboard-stats');
            container.innerHTML = `
                <div class="stat-card">
                    <h3>Total Users</h3>
                    <div class="number">${stats.total_users}</div>
                    <div class="change">Active participants</div>
                </div>
                <div class="stat-card">
                    <h3>Best Answers</h3>
                    <div class="number">${stats.total_best_answers}</div>
                    <div class="change">Quality contributions</div>
                </div>
                <div class="stat-card">
                    <h3>Total Questions</h3>
                    <div class="number">${stats.total_questions}</div>
                    <div class="change">Approved questions</div>
                </div>
                <div class="stat-card">
                    <h3>Total Answers</h3>
                    <div class="number">${stats.total_answers}</div>
                    <div class="change">All responses</div>
                </div>
            `;
        }

        // Load leaderboard
        function loadLeaderboard(page = 1) {
            currentPage = page;
            currentPeriod = document.getElementById('period-filter').value;
            currentLimit = parseInt(document.getElementById('limit-filter').value);
            
            fetch(`admin_leaderboard.php?api=1&action=leaderboard&period=${currentPeriod}&limit=${currentLimit}&page=${page}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderLeaderboard(data.data.leaderboard);
                        renderPagination(data.data.pagination);
                        loadTopPerformers();
                        initializePointsChart(data.data.leaderboard);
                    } else {
                        showError('Failed to load leaderboard: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading leaderboard: ' + error.message));
        }

        // Render leaderboard
        function renderLeaderboard(leaderboard) {
            const tbody = document.getElementById('leaderboard-tbody');
            
            if (leaderboard.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; color: #666;">No users found</td></tr>';
                return;
            }

            tbody.innerHTML = leaderboard.map(user => {
                const rankClass = user.rank <= 3 ? `rank-${user.rank}` : '';
                return `
                    <tr>
                        <td class="rank-cell ${rankClass}">#${user.rank}</td>
                        <td>
                            <div class="user-info-cell">
                                <div class="user-avatar">${user.name ? user.name.charAt(0).toUpperCase() : 'U'}</div>
                                <div class="user-details">
                                    <div class="user-name">${user.name || 'Unknown User'}</div>
                                    <div class="user-email">${user.email}</div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="stats-row">
                                <div class="stat-item">Q: ${user.question_count || 0}</div>
                                <div class="stat-item">A: ${user.answer_count || 0}</div>
                                <div class="stat-item">Best: ${user.best_answer_count || 0}</div>
                            </div>
                        </td>
                        <td class="points-cell">${user.total_points || 0}</td>
                    </tr>
                `;
            }).join('');
        }

        // Render pagination
        function renderPagination(pagination) {
            const container = document.getElementById('pagination');
            
            let html = '';
            
            // Previous button
            html += `<button ${pagination.current_page <= 1 ? 'disabled' : ''} onclick="loadLeaderboard(${pagination.current_page - 1})">Previous</button>`;
            
            // Page numbers
            for (let i = 1; i <= pagination.total_pages; i++) {
                html += `<button class="${i === pagination.current_page ? 'active' : ''}" onclick="loadLeaderboard(${i})">${i}</button>`;
            }
            
            // Next button
            html += `<button ${pagination.current_page >= pagination.total_pages ? 'disabled' : ''} onclick="loadLeaderboard(${pagination.current_page + 1})">Next</button>`;
            
            container.innerHTML = html;
        }

        // Load top performers
        function loadTopPerformers() {
            fetch(`admin_leaderboard.php?api=1&action=top_performers&period=${currentPeriod}&limit=10`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderTopPerformers(data.data);
                    } else {
                        showError('Failed to load top performers: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading top performers: ' + error.message));
        }

        // Render top performers
        function renderTopPerformers(performers) {
            const container = document.getElementById('top-performers');
            
            if (performers.length === 0) {
                container.innerHTML = '<div style="text-align: center; color: #666; padding: 2rem;">No performers found</div>';
                return;
            }

            container.innerHTML = performers.map((performer, index) => {
                const points = currentPeriod === 'week' ? performer.weekly_points : performer.total_points;
                return `
                    <div class="performer-item">
                        <div class="performer-rank">${index + 1}</div>
                        <div class="performer-info">
                            <div class="performer-name">${performer.name || 'Unknown User'}</div>
                            <div class="performer-stats">
                                ${currentPeriod === 'week' ? 
                                    `Best: ${performer.weekly_best || 0} | Answers: ${performer.weekly_answers || 0}` :
                                    `Best: ${performer.total_best || 0} | Answers: ${performer.total_answers || 0} | Questions: ${performer.total_questions || 0}`
                                }
                            </div>
                        </div>
                        <div class="performer-points">${points} pts</div>
                    </div>
                `;
            }).join('');
        }

        // Initialize points chart
        function initializePointsChart(leaderboard) {
            const ctx = document.getElementById('pointsChart').getContext('2d');
            
            // Get top 10 users for chart
            const topUsers = leaderboard.slice(0, 10);
            const labels = topUsers.map(user => user.name || 'User ' + user.user_id);
            const points = topUsers.map(user => user.total_points || 0);
            
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Points',
                        data: points,
                        backgroundColor: 'rgba(102, 126, 234, 0.6)',
                        borderColor: 'rgba(102, 126, 234, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Points'
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: 'Users'
                            }
                        }
                    }
                }
            });
        }

        // Reset leaderboard
        function resetLeaderboard() {
            if (confirm('Are you sure you want to reset the leaderboard? This will recalculate all user points.')) {
                fetch('admin_leaderboard.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: 'action=reset_leaderboard'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess('Leaderboard reset successfully');
                        loadLeaderboard();
                        loadLeaderboardStats();
                    } else {
                        showError('Failed to reset leaderboard: ' + data.message);
                    }
                })
                .catch(error => showError('Error resetting leaderboard: ' + error.message));
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

        // Load data on page load
        document.addEventListener('DOMContentLoaded', () => {
            loadLeaderboardStats();
            loadLeaderboard();
        });
    </script>
</body>
</html>
