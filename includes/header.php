<?php
/**
 * Header Component
 * ASTU-Q Admin Panel
 */
session_start();

// Check authentication
if (!isset($_SESSION['admin_user'])) {
    header('Location: login.php');
    exit;
}

$current_user = $_SESSION['admin_user'];
$page_title = $page_title ?? 'Admin Panel';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($page_title); ?> - ASTU-Q Admin Panel</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <!-- Custom CSS -->
    <link href="assets/css/admin.css" rel="stylesheet">
    
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="assets/images/favicon.ico">
</head>
<body>
    <!-- Top Navbar -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary fixed-top top-navbar">
        <div class="container-fluid">
            <a class="navbar-brand d-flex align-items-center" href="dashboard.php">
                <i class="bi bi-mortarboard-fill me-2"></i>
                <span class="fw-bold">ASTU-Q Admin</span>
            </a>
            
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <!-- Notifications -->
                    <li class="nav-item dropdown">
                        <a class="nav-link position-relative" href="#" id="notificationDropdown" role="button" data-bs-toggle="dropdown">
                            <i class="bi bi-bell"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" id="notificationBadge">
                                0
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg" id="notificationDropdownMenu">
                            <li><h6 class="dropdown-header">Notifications</h6></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item text-center" href="notifications.php">View All</a></li>
                        </ul>
                    </li>
                    
                    <!-- User Menu -->
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle d-flex align-items-center" href="#" id="userDropdown" role="button" data-bs-toggle="dropdown">
                            <div class="avatar-sm bg-light rounded-circle d-flex align-items-center justify-content-center me-2">
                                <i class="bi bi-person-fill text-primary"></i>
                            </div>
                            <span class="d-none d-md-inline"><?php echo htmlspecialchars($current_user['first_name']); ?></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><h6 class="dropdown-header"><?php echo htmlspecialchars($current_user['first_name'] . ' ' . $current_user['last_name']); ?></h6></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="profile.php"><i class="bi bi-person me-2"></i>Profile</a></li>
                            <li><a class="dropdown-item" href="settings.php"><i class="bi bi-gear me-2"></i>Settings</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item text-danger" href="api/logout.php"><i class="bi bi-box-arrow-right me-2"></i>Logout</a></li>
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </nav>
    
    <!-- Sidebar -->
    <nav class="sidebar bg-dark text-white">
        <div class="sidebar-header p-3">
            <h5 class="mb-0">Navigation</h5>
        </div>
        
        <ul class="nav nav-pills flex-column">
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'dashboard.php' ? 'active' : ''; ?>" href="dashboard.php">
                    <i class="bi bi-speedometer2 me-2"></i>
                    Dashboard
                </a>
            </li>
            
            <?php if (hasPermission('users.read')): ?>
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'users.php' ? 'active' : ''; ?>" href="users.php">
                    <i class="bi bi-people me-2"></i>
                    Users
                    <?php if (hasPermission('users.read') && getPendingUserCount() > 0): ?>
                    <span class="badge bg-warning ms-auto"><?php echo getPendingUserCount(); ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <?php endif; ?>
            
            <?php if (hasPermission('questions.read')): ?>
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'questions.php' ? 'active' : ''; ?>" href="questions.php">
                    <i class="bi bi-question-circle me-2"></i>
                    Questions
                    <?php if (hasPermission('questions.read') && getPendingQuestionCount() > 0): ?>
                    <span class="badge bg-warning ms-auto"><?php echo getPendingQuestionCount(); ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <?php endif; ?>
            
            <?php if (hasPermission('answers.read')): ?>
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'answers.php' ? 'active' : ''; ?>" href="answers.php">
                    <i class="bi bi-chat-dots me-2"></i>
                    Answers
                    <?php if (hasPermission('answers.read') && getPendingAnswerCount() > 0): ?>
                    <span class="badge bg-warning ms-auto"><?php echo getPendingAnswerCount(); ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <?php endif; ?>
            
            <?php if (hasPermission('reports.read')): ?>
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'reports.php' ? 'active' : ''; ?>" href="reports.php">
                    <i class="bi bi-flag me-2"></i>
                    Reports
                    <?php if (hasPermission('reports.read') && getPendingReportCount() > 0): ?>
                    <span class="badge bg-danger ms-auto"><?php echo getPendingReportCount(); ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <?php endif; ?>
            
            <?php if (hasPermission('analytics.read')): ?>
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'analytics.php' ? 'active' : ''; ?>" href="analytics.php">
                    <i class="bi bi-graph-up me-2"></i>
                    Analytics
                </a>
            </li>
            <?php endif; ?>
            
            <?php if (hasPermission('notifications.read')): ?>
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'notifications.php' ? 'active' : ''; ?>" href="notifications.php">
                    <i class="bi bi-bell me-2"></i>
                    Notifications
                </a>
            </li>
            <?php endif; ?>
            
            <?php if (hasPermission('system.settings')): ?>
            <li class="nav-item">
                <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) === 'settings.php' ? 'active' : ''; ?>" href="settings.php">
                    <i class="bi bi-gear me-2"></i>
                    Settings
                </a>
            </li>
            <?php endif; ?>
        </ul>
        
        <!-- Sidebar Footer -->
        <div class="sidebar-footer mt-auto p-3 border-top">
            <div class="d-flex align-items-center">
                <div class="avatar-sm bg-light rounded-circle d-flex align-items-center justify-content-center me-2">
                    <i class="bi bi-person-fill text-primary"></i>
                </div>
                <div class="flex-grow-1">
                    <div class="small fw-bold"><?php echo htmlspecialchars($current_user['first_name']); ?></div>
                    <div class="small text-muted"><?php echo htmlspecialchars($current_user['role_name']); ?></div>
                </div>
            </div>
        </div>
    </nav>
    
    <!-- Main Content -->
    <main class="main-content">
        <div class="container-fluid p-4">
