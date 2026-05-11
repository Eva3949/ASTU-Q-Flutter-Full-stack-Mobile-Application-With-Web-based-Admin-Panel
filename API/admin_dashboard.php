<?php
/**
 * Admin Dashboard
 * ASTU-Q Admin Control Panel - Full Application Control
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
    
    try {
        // Questions awaiting approval
        $stmt = $pdo->prepare("SELECT COUNT(*) as pending_questions FROM questions WHERE status = 'pending'");
        $stmt->execute();
        $pendingQuestions = $stmt->fetch(PDO::FETCH_ASSOC)['pending_questions'];
        
        // Total questions
        $stmt = $pdo->prepare("SELECT COUNT(*) as total_questions FROM questions");
        $stmt->execute();
        $totalQuestions = $stmt->fetch(PDO::FETCH_ASSOC)['total_questions'];
        
        // Total users
        $stmt = $pdo->prepare("SELECT COUNT(*) as total_users FROM users");
        $stmt->execute();
        $totalUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total_users'];
        
        // Total answers
        $stmt = $pdo->prepare("SELECT COUNT(*) as total_answers FROM answers");
        $stmt->execute();
        $totalAnswers = $stmt->fetch(PDO::FETCH_ASSOC)['total_answers'];
        
        // Recent questions (last 7 days)
        $stmt = $pdo->prepare("SELECT COUNT(*) as recent_questions FROM questions WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
        $stmt->execute();
        $recentQuestions = $stmt->fetch(PDO::FETCH_ASSOC)['recent_questions'];
        
        // Recent users (last 7 days)
        $stmt = $pdo->prepare("SELECT COUNT(*) as recent_users FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
        $stmt->execute();
        $recentUsers = $stmt->fetch(PDO::FETCH_ASSOC)['recent_users'];
        
        // Get questions awaiting approval with details
        $stmt = $pdo->prepare("
            SELECT q.*, u.username as author_name 
            FROM questions q 
            LEFT JOIN users u ON q.user_id = u.user_id 
            WHERE q.status = 'pending' 
            ORDER BY q.created_at DESC 
            LIMIT 10
        ");
        $stmt->execute();
        $pendingQuestionsList = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get recent activities
        $stmt = $pdo->prepare("
            SELECT 'question' as activity_type, q.title as description, q.created_at as activity_time, u.username as user_name
            FROM questions q 
            LEFT JOIN users u ON q.user_id = u.user_id 
            WHERE q.created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
            UNION ALL
            SELECT 'answer' as activity_type, a.content as description, a.created_at as activity_time, u.username as user_name
            FROM answers a 
            LEFT JOIN users u ON a.user_id = u.user_id 
            WHERE a.created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
            ORDER BY activity_time DESC 
            LIMIT 10
        ");
        $stmt->execute();
        $recentActivities = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get Top Users (similar logic to leaderboard.php)
        $topUsersQuery = "
            SELECT
                sub.user_id as id,
                CONCAT(COALESCE(sub.first_name, ''), ' ', COALESCE(sub.last_name, '')) as name,
                sub.profile_picture as avatar_url,
                sub.total_points as points,
                sub.level,
                sub.questions_count,
                sub.answers_count,
                sub.best_answers_count
            FROM (
                SELECT
                    u.user_id,
                    u.first_name,
                    u.last_name,
                    u.profile_picture,
                    u.level,
                    COALESCE(SUM(up.points), 0) as total_points,
                    COALESCE(COUNT(DISTINCT q.question_id), 0) as questions_count,
                    COALESCE(COUNT(DISTINCT a.answer_id), 0) as answers_count,
                    COALESCE(SUM(CASE WHEN a.is_best = 1 THEN 1 ELSE 0 END), 0) as best_answers_count
                FROM users u
                LEFT JOIN user_points up ON u.user_id = up.user_id
                LEFT JOIN questions q ON u.user_id = q.user_id AND q.status = 'approved'
                LEFT JOIN answers a ON u.user_id = a.user_id AND a.status = 'approved'
                WHERE u.status = 'active'
                GROUP BY u.user_id, u.first_name, u.last_name, u.profile_picture, u.level
            ) as sub
            ORDER BY sub.total_points DESC, sub.level DESC
            LIMIT 5
        ";
        $topUsersStmt = $pdo->prepare($topUsersQuery);
        $topUsersStmt->execute();
        $topUsers = $topUsersStmt->fetchAll(PDO::FETCH_ASSOC);
        
        $dashboardData = [
            'stats' => [
                'pending_questions' => (int)$pendingQuestions,
                'total_questions' => (int)$totalQuestions,
                'total_users' => (int)$totalUsers,
                'total_answers' => (int)$totalAnswers,
                'recent_questions' => (int)$recentQuestions,
                'recent_users' => (int)$recentUsers,
            ],
            'pending_questions' => $pendingQuestionsList,
            'recent_activities' => $recentActivities,
            'top_users' => $topUsers, // Add top users data here
            'admin_info' => [
                'username' => $_SESSION['admin_username'] ?? 'Unknown',
                'login_time' => $_SESSION['login_time'] ?? date('Y-m-d H:i:s'),
                'role' => $_SESSION['admin_role'] ?? 'Administrator',
            ]
        ];
        
        echo json_encode(['success' => true, 'data' => $dashboardData]);
        
    } catch (PDOException $e) {
        error_log("Database error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    } catch (Exception $e) {
        error_log("General error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'General error: ' . $e->getMessage()]);
    }
    exit;
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - ASTU-Q Control Panel</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        /* Custom styles for specific elements not covered by Bootstrap */
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
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
        .stat-card .text-xs {
            font-size: 0.7rem;
        }
        .stat-card .h5 {
            font-size: 1.25rem;
        }
        .stat-card .fa-2x {
            font-size: 2em;
        }
        .border-left-primary {
            border-left: 0.25rem solid #4e73df !important;
        }
        .border-left-success {
            border-left: 0.25rem solid #1cc88a !important;
        }
        .border-left-info {
            border-left: 0.25rem solid #36b9cc !important;
        }
        .border-left-warning {
            border-left: 0.25rem solid #f6c23e !important;
        }
        .border-left-secondary {
            border-left: 0.25rem solid #858796 !important;
        }
        .border-left-dark {
            border-left: 0.25rem solid #5a5c69 !important;
        }
        .text-gray-300 {
            color: #dddfeb !important;
        }
        .text-gray-800 {
            color: #5a5c69 !important;
        }
        .font-weight-bold {
            font-weight: 700 !important;
        }
        .text-uppercase {
            text-transform: uppercase !important;
        }
        .no-gutters {
            margin-right: 0;
            margin-left: 0;
        }
        .no-gutters > .col,
        .no-gutters > [class*="col-"] {
            padding-right: 0;
            padding-left: 0;
        }
        .sidebar {
            width: 250px;
            transition: all 0.3s;
        }
        @media (min-width: 992px) {
            .sidebar {
                position: sticky;
                top: 56px;
                height: calc(100vh - 56px);
                z-index: 1000;
                transform: none !important;
                visibility: visible !important;
                flex-shrink: 0;
            }
            #main-content {
                flex-grow: 1;
                margin-left: 0 !important; /* No margin needed with flex-row */
            }
            .offcanvas-backdrop {
                display: none !important;
            }
        }
        @media (max-width: 991.98px) {
            .sidebar {
                position: fixed;
                top: 0;
                left: 0;
                z-index: 1045;
            }
        }
    </style>
</head>
<body class="bg-light">
    <div class="wrapper d-flex flex-row min-vh-100">
    <header class="navbar navbar-expand-lg navbar-dark bg-primary shadow-sm fixed-top">
        <div class="container-fluid">
            <button class="btn btn-primary me-3 d-lg-none" type="button" data-bs-toggle="offcanvas" data-bs-target="#sidebarOffcanvas" aria-controls="sidebarOffcanvas">
                <i class="fas fa-bars"></i> Menu
            </button>
            <a class="navbar-brand fw-bold" href="#">ASTU-Q Admin Panel</a>
            <div class="d-flex align-items-center">
                <span class="navbar-text me-3 d-none d-md-block">Welcome, <strong><?php echo htmlspecialchars($_SESSION['admin_username']); ?></strong></span>
                <span class="navbar-text me-3 d-none d-md-block">Role: <?php echo htmlspecialchars($_SESSION['admin_role'] ?? 'Administrator'); ?></span>
                <button class="btn btn-outline-light" onclick="logout()">Logout</button>
            </div>
        </div>
    </header>

    <div class="offcanvas offcanvas-start bg-dark text-white sidebar" tabindex="-1" id="sidebarOffcanvas" aria-labelledby="sidebarOffcanvasLabel">
        <div class="offcanvas-header">
            <h5 class="offcanvas-title text-white" id="sidebarOffcanvasLabel">Navigation</h5>
            <button type="button" class="btn-close text-reset" data-bs-dismiss="offcanvas" aria-label="Close"></button>
        </div>
        <div class="offcanvas-body p-0">
            <nav class="nav flex-column">
                <a class="nav-link text-white active bg-primary" href="admin_dashboard.php">
                    <i class="fas fa-tachometer-alt me-2"></i> Dashboard
                </a>
                
                <a class="nav-link text-white" href="admin_approve_questions.php?status=all">
                    <i class="fas fa-question-circle me-2"></i> Questions
                </a>

                <a class="nav-link text-white" href="admin_users.php">
                    <i class="fas fa-users me-2"></i> Users
                </a>

                <a class="nav-link text-white" data-bs-toggle="collapse" href="#contentCollapse" role="button" aria-expanded="false" aria-controls="contentCollapse">
                    <i class="fas fa-file-alt me-2"></i> Content Management
                </a>
                <div class="collapse" id="contentCollapse">
                    <a class="nav-link text-white ps-4" href="admin_approve_questions.php">
                        <i class="fas fa-question-circle me-2"></i> Questions
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_approve_answers.php">
                        <i class="fas fa-comment-alt me-2"></i> Answers
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_content_moderation.php">
                        <i class="fas fa-shield-alt me-2"></i> Content Moderation
                    </a>
                </div>
                
                <a class="nav-link text-white" data-bs-toggle="collapse" href="#userCollapse" role="button" aria-expanded="false" aria-controls="userCollapse">
                    <i class="fas fa-users me-2"></i> User Management
                </a>
                <div class="collapse" id="userCollapse">
                    <a class="nav-link text-white ps-4" href="admin_users.php">
                        <i class="fas fa-user me-2"></i> All Users
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_user_roles.php">
                        <i class="fas fa-user-tag me-2"></i> User Roles
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_user_activity.php">
                        <i class="fas fa-chart-line me-2"></i> User Activity
                    </a>
                </div>
                
                <a class="nav-link text-white" data-bs-toggle="collapse" href="#analyticsCollapse" role="button" aria-expanded="false" aria-controls="analyticsCollapse">
                    <i class="fas fa-chart-pie me-2"></i> Analytics
                </a>
                <div class="collapse" id="analyticsCollapse">
                    <a class="nav-link text-white ps-4" href="admin_analytics.php">
                        <i class="fas fa-chart-bar me-2"></i> Analytics Dashboard
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_reports.php">
                        <i class="fas fa-file-invoice me-2"></i> Reports
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_leaderboard.php">
                        <i class="fas fa-trophy me-2"></i> Leaderboard
                    </a>
                </div>
                
                <a class="nav-link text-white" data-bs-toggle="collapse" href="#systemCollapse" role="button" aria-expanded="false" aria-controls="systemCollapse">
                    <i class="fas fa-cogs me-2"></i> System Control
                </a>
                <div class="collapse" id="systemCollapse">
                    <a class="nav-link text-white ps-4" href="admin_settings.php">
                        <i class="fas fa-cog me-2"></i> Settings
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_system_health.php">
                        <i class="fas fa-heartbeat me-2"></i> System Health
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_logs.php">
                        <i class="fas fa-clipboard-list me-2"></i> System Logs
                    </a>
                    <a class="nav-link text-white ps-4" href="admin_maintenance.php">
                        <i class="fas fa-tools me-2"></i> Maintenance
                    </a>
                </div>
            </nav>
        </div>
    </div>

    <main class="flex-grow-1 p-3 pt-5 mt-5" id="main-content">
        <div class="container-fluid">
            <div id="error-message" class="error" style="display: none;"></div>
            
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1 class="h3 mb-0 text-gray-800">Dashboard Overview</h1>
                <p class="mb-0 text-muted">Complete application analytics and control center</p>
            </div>
            
            <div class="row g-4 mb-4" id="stats-grid">
                <div class="loading">Loading dashboard...</div>
            </div>

            <div class="row mb-4">
                <div class="col-lg-8">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">User Activity Chart</h6>
                        </div>
                        <div class="card-body">
                            <canvas id="userActivityChart" width="400" height="200"></canvas>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">Question Statistics</h6>
                        </div>
                        <div class="card-body">
                            <canvas id="questionStatsChart" width="400" height="200"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row mb-4">
                <div class="col-lg-8">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">Weekly Growth</h6>
                        </div>
                        <div class="card-body">
                            <canvas id="growthChart" width="400" height="200"></canvas>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">Subject Distribution</h6>
                        </div>
                        <div class="card-body">
                            <canvas id="subjectChart" width="400" height="200"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row mb-4">
                <div class="col-lg-6">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">Pending Questions</h6>
                        </div>
                        <div class="card-body">
                            <div class="pending-questions" id="pending-questions">
                                <div class="loading">Loading pending questions...</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">Recent Activity</h6>
                        </div>
                        <div class="card-body">
                            <div class="activity-list" id="recent-activities">
                                <div class="loading">Loading recent activity...</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row mb-4">
                <div class="col-lg-6">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">Top Users</h6>
                        </div>
                        <div class="card-body">
                            <div id="top-users">
                                <div class="loading">Loading top users...</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6">
                    <div class="card shadow mb-4">
                        <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                            <h6 class="m-0 font-weight-bold text-primary">System Health</h6>
                        </div>
                        <div class="card-body">
                            <div id="system-health">
                                <div class="loading">Loading system health...</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
    </div> <!-- End of wrapper -->

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

        // Load dashboard data
        function loadDashboard() {
            fetch('admin_dashboard.php?api=1')
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Network response was not ok: ' + response.statusText);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('Dashboard data:', data);
                    if (data.success) {
                        try {
                            renderStats(data.data.stats);
                            renderPendingQuestions(data.data.pending_questions);
                            renderRecentActivities(data.data.recent_activities);
                            renderTopUsers(data.data.top_users);
                            renderSystemHealth();
                            initializeCharts(data.data.stats);
                        } catch (renderError) {
                            console.error('Rendering error:', renderError);
                            showError('Error rendering dashboard components: ' + renderError.message);
                        }
                    } else {
                        showError('Failed to load dashboard data: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Fetch error:', error);
                    showError('Error loading dashboard: ' + error.message);
                });
        }

        // Render statistics
        function renderStats(stats) {
            const statsGrid = document.getElementById('stats-grid');
            statsGrid.innerHTML = `
                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-primary shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col me-2">
                                    <div class="text-xs font-weight-bold text-primary text-uppercase mb-1">Pending Questions</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">${stats.pending_questions}</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-comments fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-success shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col me-2">
                                    <div class="text-xs font-weight-bold text-success text-uppercase mb-1">Total Questions</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">${stats.total_questions}</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-question-circle fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-info shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col me-2">
                                    <div class="text-xs font-weight-bold text-info text-uppercase mb-1">Total Users</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">${stats.total_users}</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-users fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-warning shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col me-2">
                                    <div class="text-xs font-weight-bold text-warning text-uppercase mb-1">Total Answers</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">${stats.total_answers}</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-lightbulb fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-secondary shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col me-2">
                                    <div class="text-xs font-weight-bold text-secondary text-uppercase mb-1">Active Users</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">${Math.floor(stats.total_users * 0.7)}</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-user-check fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-dark shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col me-2">
                                    <div class="text-xs font-weight-bold text-dark text-uppercase mb-1">Response Rate</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">${stats.total_questions > 0 ? Math.floor((stats.total_answers / stats.total_questions) * 100) : 0}%</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-percentage fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }

        // Render top users
        function renderTopUsers(topUsers) {
            const container = document.getElementById('top-users');
            
            if (!topUsers || topUsers.length === 0) {
                container.innerHTML = '<div style="text-align: center; color: #666;">No users found</div>';
                return;
            }

            container.innerHTML = topUsers.map((user, index) => `
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 0; border-bottom: 1px solid #eee;">
                    <div>
                        <strong>${index + 1}. ${user.name}</strong>
                        <div style="font-size: 12px; color: #666;">${user.questions_count} questions, ${user.answers_count} answers</div>
                    </div>
                    <div style="text-align: right;">
                        <div style="font-weight: bold; color: #667eea;">${user.points} pts</div>
                    </div>
                </div>
            `).join('');
        }

        // Render system health
        function renderSystemHealth() {
            const container = document.getElementById('system-health');
            const healthData = [
                { name: 'Database', status: 'healthy', value: 95 },
                { name: 'API Server', status: 'healthy', value: 98 },
                { name: 'Storage', status: 'warning', value: 78 },
                { name: 'Memory', status: 'healthy', value: 82 },
                { name: 'CPU Usage', status: 'healthy', value: 45 }
            ];

            container.innerHTML = healthData.map(item => {
                const statusColor = item.status === 'healthy' ? '#00b894' : item.status === 'warning' ? '#fdcb6e' : '#ff4757';
                return `
                    <div style="margin-bottom: 1rem;">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 0.25rem;">
                            <span>${item.name}</span>
                            <span style="color: ${statusColor}; font-weight: bold;">${item.value}%</span>
                        </div>
                        <div style="background: #eee; height: 8px; border-radius: 4px;">
                            <div style="background: ${statusColor}; height: 100%; width: ${item.value}%; border-radius: 4px;"></div>
                        </div>
                    </div>
                `;
            }).join('');
        }

        // Initialize charts
        function initializeCharts(stats) {
            // User Activity Chart
            const userActivityCtx = document.getElementById('userActivityChart').getContext('2d');
            new Chart(userActivityCtx, {
                type: 'line',
                data: {
                    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    datasets: [{
                        label: 'Active Users',
                        data: [120, 145, 160, 155, 180, 140, 110],
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102, 126, 234, 0.1)',
                        tension: 0.4
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
                            beginAtZero: true
                        }
                    }
                }
            });

            // Question Statistics Chart
            const questionStatsCtx = document.getElementById('questionStatsChart').getContext('2d');
            new Chart(questionStatsCtx, {
                type: 'bar',
                data: {
                    labels: ['Pending', 'Approved', 'Rejected'],
                    datasets: [{
                        label: 'Questions',
                        data: [stats.pending_questions, Math.floor(stats.total_questions * 0.8), Math.floor(stats.total_questions * 0.1)],
                        backgroundColor: ['#fdcb6e', '#00b894', '#ff4757']
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
                            beginAtZero: true
                        }
                    }
                }
            });

            // Weekly Growth Chart
            const growthCtx = document.getElementById('growthChart').getContext('2d');
            new Chart(growthCtx, {
                type: 'line',
                data: {
                    labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
                    datasets: [{
                        label: 'Users',
                        data: [450, 520, 580, 650],
                        borderColor: '#00b894',
                        backgroundColor: 'rgba(0, 184, 148, 0.1)',
                        tension: 0.4
                    }, {
                        label: 'Questions',
                        data: [120, 150, 180, 220],
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102, 126, 234, 0.1)',
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

            // Subject Distribution Chart
            const subjectCtx = document.getElementById('subjectChart').getContext('2d');
            new Chart(subjectCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Mathematics', 'Science', 'Programming', 'Engineering', 'Other'],
                    datasets: [{
                        data: [30, 25, 20, 15, 10],
                        backgroundColor: ['#667eea', '#00b894', '#fdcb6e', '#ff4757', '#6c5ce7']
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
        }

        // Render pending questions
        function renderPendingQuestions(questions) {
            const container = document.getElementById('pending-questions');
            
            if (questions.length === 0) {
                container.innerHTML = '<div style="text-align: center; color: #666;">No pending questions</div>';
                return;
            }

            container.innerHTML = questions.map(question => `
                <div class="question-item">
                    <div class="question-title">${question.title}</div>
                    <div class="question-meta">
                        By ${question.author_name || 'Anonymous'} | ${new Date(question.created_at).toLocaleString()}
                    </div>
                    <div class="question-actions">
                        <button class="btn btn-view" onclick="viewQuestion(${question.question_id})">View</button>
                        <button class="btn btn-approve" onclick="approveQuestion(${question.question_id})">Approve</button>
                        <button class="btn btn-reject" onclick="rejectQuestion(${question.question_id})">Reject</button>
                    </div>
                </div>
            `).join('');
        }

        // Render recent activities
        function renderRecentActivities(activities) {
            const container = document.getElementById('recent-activities');
            
            if (activities.length === 0) {
                container.innerHTML = '<div style="text-align: center; color: #666;">No recent activity</div>';
                return;
            }

            container.innerHTML = activities.map(activity => `
                <div class="activity-item">
                    <div class="activity-type">${activity.activity_type}</div>
                    <div class="activity-description">${activity.description.substring(0, 50)}${activity.description.length > 50 ? '...' : ''}</div>
                    <div class="activity-meta">
                        By ${activity.user_name || 'Anonymous'} | ${new Date(activity.activity_time).toLocaleString()}
                    </div>
                </div>
            `).join('');
        }

        // Question actions
        function viewQuestion(questionId) {
            window.location.href = `admin_approve_questions.php?action=details&question_id=${questionId}`;
        }

        function approveQuestion(questionId) {
            if (confirm('Are you sure you want to approve this question?')) {
                fetch('admin_approve_questions.php?action=approve', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `question_id=${questionId}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        loadDashboard();
                    } else {
                        showError('Failed to approve question: ' + data.message);
                    }
                })
                .catch(error => showError('Error approving question: ' + error.message));
            }
        }

        function rejectQuestion(questionId) {
            const reason = prompt('Please provide a reason for rejection:');
            if (reason) {
                fetch('admin_approve_questions.php?action=reject', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `question_id=${questionId}&reason=${encodeURIComponent(reason)}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        loadDashboard();
                    } else {
                        showError('Failed to reject question: ' + data.message);
                    }
                })
                .catch(error => showError('Error rejecting question: ' + error.message));
            }
        }

        // Logout function
        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'admin_logout.php';
            }
        }

        // Show error message
        function showError(message) {
            const errorDiv = document.getElementById('error-message');
            errorDiv.textContent = message;
            errorDiv.style.display = 'block';
            setTimeout(() => {
                errorDiv.style.display = 'none';
            }, 5000);
        }

        // Load dashboard on page load
        document.addEventListener('DOMContentLoaded', loadDashboard);

        // Refresh dashboard every 30 seconds
        setInterval(loadDashboard, 30000);
    </script>
    <!-- Bootstrap Bundle with Popper -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
