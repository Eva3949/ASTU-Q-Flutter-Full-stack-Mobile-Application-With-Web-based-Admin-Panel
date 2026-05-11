<?php
/**
 * Admin Analytics Dashboard
 * ASTU-Q Admin Control Panel - Comprehensive Analytics
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
    
    $action = $_GET['action'] ?? 'overview';
    
    try {
        switch ($action) {
            case 'overview':
                // Get overview statistics
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE status = 'active'");
                $stmt->execute();
                $totalUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM questions WHERE status = 'approved'");
                $stmt->execute();
                $totalQuestions = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM answers");
                $stmt->execute();
                $totalAnswers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM answers WHERE is_best_answer = 1");
                $stmt->execute();
                $totalBestAnswers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM questions WHERE status = 'pending'");
                $stmt->execute();
                $pendingQuestions = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM answers WHERE status = 'pending'");
                $stmt->execute();
                $pendingAnswers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                // Engagement rate
                $engagementRate = $totalQuestions > 0 ? round(($totalAnswers / $totalQuestions) * 100, 2) : 0;
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'total_users' => (int)$totalUsers,
                        'total_questions' => (int)$totalQuestions,
                        'total_answers' => (int)$totalAnswers,
                        'total_best_answers' => (int)$totalBestAnswers,
                        'pending_questions' => (int)$pendingQuestions,
                        'pending_answers' => (int)$pendingAnswers,
                        'engagement_rate' => $engagementRate
                    ]
                ]);
                break;
                
            case 'user_activity':
                // Get user activity over time
                $period = $_GET['period'] ?? '7';
                $days = (int)$period;
                
                $stmt = $pdo->prepare("
                    SELECT 
                        DATE(created_at) as date,
                        COUNT(*) as new_users
                    FROM users 
                    WHERE created_at >= DATE_SUB(NOW(), INTERVAL $days DAY)
                    GROUP BY DATE(created_at)
                    ORDER BY date ASC
                ");
                $stmt->execute();
                $newUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $stmt = $pdo->prepare("
                    SELECT 
                        DATE(created_at) as date,
                        COUNT(*) as active_users
                    FROM users 
                    WHERE last_login >= DATE_SUB(NOW(), INTERVAL $days DAY)
                    GROUP BY DATE(last_login)
                    ORDER BY date ASC
                ");
                $stmt->execute();
                $activeUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'new_users' => $newUsers,
                        'active_users' => $activeUsers
                    ]
                ]);
                break;
                
            case 'content_stats':
                // Get content statistics
                $stmt = $pdo->prepare("
                    SELECT 
                        DATE(created_at) as date,
                        COUNT(*) as questions
                    FROM questions 
                    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                    GROUP BY DATE(created_at)
                    ORDER BY date ASC
                ");
                $stmt->execute();
                $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $stmt = $pdo->prepare("
                    SELECT 
                        DATE(created_at) as date,
                        COUNT(*) as answers
                    FROM answers 
                    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                    GROUP BY DATE(created_at)
                    ORDER BY date ASC
                ");
                $stmt->execute();
                $answers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'questions' => $questions,
                        'answers' => $answers
                    ]
                ]);
                break;
                
            case 'subject_distribution':
                // Get subject distribution
                $stmt = $pdo->prepare("
                    SELECT 
                        subject,
                        COUNT(*) as count
                    FROM questions 
                    WHERE subject IS NOT NULL AND subject != '' AND status = 'approved'
                    GROUP BY subject
                    ORDER BY count DESC
                    LIMIT 10
                ");
                $stmt->execute();
                $subjects = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'data' => $subjects
                ]);
                break;
                
            case 'user_engagement':
                // Get user engagement metrics
                $stmt = $pdo->prepare("
                    SELECT 
                        u.user_id,
                        u.username,
                        u.name,
                        (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id AND status = 'approved') as question_count,
                        (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id) as answer_count,
                        (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND is_best_answer = 1) as best_answer_count
                    FROM users u
                    WHERE u.status = 'active'
                    ORDER BY best_answer_count DESC, answer_count DESC
                    LIMIT 10
                ");
                $stmt->execute();
                $topUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                foreach ($topUsers as &$user) {
                    $user['total_points'] = ($user['question_count'] * 10) + ($user['answer_count'] * 5) + ($user['best_answer_count'] * 20);
                }
                
                echo json_encode([
                    'success' => true,
                    'data' => $topUsers
                ]);
                break;
                
            case 'growth_metrics':
                // Get growth metrics
                $stmt = $pdo->prepare("
                    SELECT 
                        DATE_FORMAT(created_at, '%Y-%m') as month,
                        COUNT(*) as users
                    FROM users 
                    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
                    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
                    ORDER BY month ASC
                ");
                $stmt->execute();
                $userGrowth = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $stmt = $pdo->prepare("
                    SELECT 
                        DATE_FORMAT(created_at, '%Y-%m') as month,
                        COUNT(*) as questions
                    FROM questions 
                    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
                    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
                    ORDER BY month ASC
                ");
                $stmt->execute();
                $questionGrowth = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'user_growth' => $userGrowth,
                        'question_growth' => $questionGrowth
                    ]
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
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analytics Dashboard - ASTU-Q Admin Panel</title>
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

        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .chart-container {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            padding: 1.5rem;
        }

        .chart-header {
            margin-bottom: 1rem;
        }

        .chart-header h3 {
            color: #333;
            margin-bottom: 0.5rem;
        }

        .chart-header p {
            color: #666;
            font-size: 14px;
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

        .engagement-metrics {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        .metric-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
        }

        .metric-item {
            text-align: center;
            padding: 1rem;
            border-radius: 8px;
            background: #f8f9fa;
        }

        .metric-value {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 0.5rem;
        }

        .metric-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
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
            
            .charts-grid {
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
                <a href="admin_analytics.php" class="menu-item active">
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
                <h1>Analytics Dashboard</h1>
                <p>Comprehensive analytics and insights for ASTU-Q platform</p>
            </div>

            <div class="controls">
                <div class="control-group">
                    <label for="period-filter">Time Period:</label>
                    <select id="period-filter" onchange="updateCharts()">
                        <option value="7">Last 7 Days</option>
                        <option value="30">Last 30 Days</option>
                        <option value="90">Last 90 Days</option>
                    </select>
                </div>
                <button class="btn btn-primary" onclick="updateCharts()">Refresh Analytics</button>
            </div>

            <div class="stats-grid" id="overview-stats">
                <div class="loading">Loading overview statistics...</div>
            </div>

            <div class="engagement-metrics">
                <div class="chart-header">
                    <h3>Engagement Metrics</h3>
                    <p>Key performance indicators for user engagement</p>
                </div>
                <div class="metric-grid" id="engagement-metrics">
                    <div class="loading">Loading engagement metrics...</div>
                </div>
            </div>

            <div class="charts-grid">
                <div class="chart-container">
                    <div class="chart-header">
                        <h3>User Activity Trends</h3>
                        <p>New users vs active users over time</p>
                    </div>
                    <canvas id="userActivityChart" width="400" height="200"></canvas>
                </div>

                <div class="chart-container">
                    <div class="chart-header">
                        <h3>Content Creation Trends</h3>
                        <p>Questions and answers over time</p>
                    </div>
                    <canvas id="contentChart" width="400" height="200"></canvas>
                </div>

                <div class="chart-container">
                    <div class="chart-header">
                        <h3>Subject Distribution</h3>
                        <p>Most popular subjects</p>
                    </div>
                    <canvas id="subjectChart" width="400" height="200"></canvas>
                </div>

                <div class="chart-container">
                    <div class="chart-header">
                        <h3>Growth Metrics</h3>
                        <p>Monthly growth trends</p>
                    </div>
                    <canvas id="growthChart" width="400" height="200"></canvas>
                </div>
            </div>

            <div class="chart-container">
                <div class="chart-header">
                    <h3>Top Performers</h3>
                    <p>Most engaged users by points and contributions</p>
                </div>
                <canvas id="performersChart" width="400" height="200"></canvas>
            </div>
        </div>
    </div>

    <script>
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

        // Load overview statistics
        function loadOverviewStats() {
            fetch('admin_analytics.php?api=1&action=overview')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderOverviewStats(data.data);
                        renderEngagementMetrics(data.data);
                    } else {
                        showError('Failed to load overview statistics: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading overview statistics: ' + error.message));
        }

        // Render overview statistics
        function renderOverviewStats(stats) {
            const container = document.getElementById('overview-stats');
            container.innerHTML = `
                <div class="stat-card">
                    <h3>Total Users</h3>
                    <div class="number">${stats.total_users}</div>
                    <div class="change">Registered users</div>
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
                <div class="stat-card">
                    <h3>Best Answers</h3>
                    <div class="number">${stats.total_best_answers}</div>
                    <div class="change">Quality responses</div>
                </div>
                <div class="stat-card">
                    <h3>Pending Questions</h3>
                    <div class="number">${stats.pending_questions}</div>
                    <div class="change">Awaiting review</div>
                </div>
                <div class="stat-card">
                    <h3>Pending Answers</h3>
                    <div class="number">${stats.pending_answers}</div>
                    <div class="change">Awaiting review</div>
                </div>
            `;
        }

        // Render engagement metrics
        function renderEngagementMetrics(stats) {
            const container = document.getElementById('engagement-metrics');
            const avgAnswersPerQuestion = stats.total_questions > 0 ? (stats.total_answers / stats.total_questions).toFixed(2) : 0;
            const bestAnswerRate = stats.total_answers > 0 ? ((stats.total_best_answers / stats.total_answers) * 100).toFixed(2) : 0;
            
            container.innerHTML = `
                <div class="metric-item">
                    <div class="metric-value">${stats.engagement_rate}%</div>
                    <div class="metric-label">Engagement Rate</div>
                </div>
                <div class="metric-item">
                    <div class="metric-value">${avgAnswersPerQuestion}</div>
                    <div class="metric-label">Avg Answers/Question</div>
                </div>
                <div class="metric-item">
                    <div class="metric-value">${bestAnswerRate}%</div>
                    <div class="metric-label">Best Answer Rate</div>
                </div>
                <div class="metric-item">
                    <div class="metric-value">${stats.total_best_answers}</div>
                    <div class="metric-label">Total Best Answers</div>
                </div>
            `;
        }

        // Update all charts
        function updateCharts() {
            loadOverviewStats();
            loadUserActivityChart();
            loadContentChart();
            loadSubjectChart();
            loadGrowthChart();
            loadPerformersChart();
        }

        // Load user activity chart
        function loadUserActivityChart() {
            const period = document.getElementById('period-filter').value;
            fetch(`admin_analytics.php?api=1&action=user_activity&period=${period}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const ctx = document.getElementById('userActivityChart').getContext('2d');
                        
                        // Prepare data
                        const labels = [...new Set([...data.data.new_users.map(u => u.date), ...data.data.active_users.map(u => u.date)])].sort();
                        const newUsersData = labels.map(date => {
                            const item = data.data.new_users.find(u => u.date === date);
                            return item ? item.new_users : 0;
                        });
                        const activeUsersData = labels.map(date => {
                            const item = data.data.active_users.find(u => u.date === date);
                            return item ? item.active_users : 0;
                        });
                        
                        new Chart(ctx, {
                            type: 'line',
                            data: {
                                labels: labels,
                                datasets: [{
                                    label: 'New Users',
                                    data: newUsersData,
                                    borderColor: '#667eea',
                                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                                    tension: 0.4
                                }, {
                                    label: 'Active Users',
                                    data: activeUsersData,
                                    borderColor: '#00b894',
                                    backgroundColor: 'rgba(0, 184, 148, 0.1)',
                                    tension: 0.4
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: {
                                        beginAtZero: true
                                    }
                                }
                            }
                        });
                    } else {
                        showError('Failed to load user activity chart: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading user activity chart: ' + error.message));
        }

        // Load content chart
        function loadContentChart() {
            fetch('admin_analytics.php?api=1&action=content_stats')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const ctx = document.getElementById('contentChart').getContext('2d');
                        
                        // Prepare data
                        const labels = [...new Set([...data.data.questions.map(q => q.date), ...data.data.answers.map(a => a.date)])].sort();
                        const questionsData = labels.map(date => {
                            const item = data.data.questions.find(q => q.date === date);
                            return item ? item.questions : 0;
                        });
                        const answersData = labels.map(date => {
                            const item = data.data.answers.find(a => a.date === date);
                            return item ? item.answers : 0;
                        });
                        
                        new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: labels,
                                datasets: [{
                                    label: 'Questions',
                                    data: questionsData,
                                    backgroundColor: 'rgba(102, 126, 234, 0.6)'
                                }, {
                                    label: 'Answers',
                                    data: answersData,
                                    backgroundColor: 'rgba(0, 184, 148, 0.6)'
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: {
                                        beginAtZero: true
                                    }
                                }
                            }
                        });
                    } else {
                        showError('Failed to load content chart: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading content chart: ' + error.message));
        }

        // Load subject chart
        function loadSubjectChart() {
            fetch('admin_analytics.php?api=1&action=subject_distribution')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const ctx = document.getElementById('subjectChart').getContext('2d');
                        
                        new Chart(ctx, {
                            type: 'doughnut',
                            data: {
                                labels: data.data.map(s => s.subject),
                                datasets: [{
                                    data: data.data.map(s => s.count),
                                    backgroundColor: [
                                        '#667eea', '#00b894', '#fdcb6e', '#ff4757', '#6c5ce7',
                                        '#00cec9', '#fd79a8', '#a29bfe', '#ffeaa7', '#55a3ff'
                                    ]
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                plugins: {
                                    legend: {
                                        position: 'bottom'
                                    }
                                }
                            }
                        });
                    } else {
                        showError('Failed to load subject chart: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading subject chart: ' + error.message));
        }

        // Load growth chart
        function loadGrowthChart() {
            fetch('admin_analytics.php?api=1&action=growth_metrics')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const ctx = document.getElementById('growthChart').getContext('2d');
                        
                        new Chart(ctx, {
                            type: 'line',
                            data: {
                                labels: data.data.user_growth.map(u => u.month),
                                datasets: [{
                                    label: 'User Growth',
                                    data: data.data.user_growth.map(u => u.users),
                                    borderColor: '#667eea',
                                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                                    tension: 0.4
                                }, {
                                    label: 'Question Growth',
                                    data: data.data.question_growth.map(q => q.questions),
                                    borderColor: '#00b894',
                                    backgroundColor: 'rgba(0, 184, 148, 0.1)',
                                    tension: 0.4
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: {
                                        beginAtZero: true
                                    }
                                }
                            }
                        });
                    } else {
                        showError('Failed to load growth chart: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading growth chart: ' + error.message));
        }

        // Load performers chart
        function loadPerformersChart() {
            fetch('admin_analytics.php?api=1&action=user_engagement')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const ctx = document.getElementById('performersChart').getContext('2d');
                        
                        new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: data.data.map(u => u.name || u.username),
                                datasets: [{
                                    label: 'Total Points',
                                    data: data.data.map(u => u.total_points),
                                    backgroundColor: 'rgba(102, 126, 234, 0.6)'
                                }, {
                                    label: 'Best Answers',
                                    data: data.data.map(u => u.best_answer_count),
                                    backgroundColor: 'rgba(0, 184, 148, 0.6)'
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: {
                                        beginAtZero: true
                                    }
                                }
                            }
                        });
                    } else {
                        showError('Failed to load performers chart: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading performers chart: ' + error.message));
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
            updateCharts();
        });
    </script>
</body>
</html>
