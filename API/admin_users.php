<?php
/**
 * Admin User Management System
 * ASTU-Q Admin Control Panel - User Management
 */

require_once 'db_connection.php';

// Check admin session
session_start();
if (!isset($_SESSION['admin_logged_in'])) {
    if (isset($_GET['api'])) {
        header("Content-Type: application/json");
        echo json_encode(['success' => false, 'message' => 'Unauthorized access']);
        exit;
    }
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
                $status = $_GET['status'] ?? '';
                
                $where = "1=1";
                $params = [];
                
                if (!empty($search)) {
                    $where .= " AND (username LIKE :search OR email LIKE :search OR first_name LIKE :search OR last_name LIKE :search)";
                    $params[':search'] = "%$search%";
                }
                
                if (!empty($status)) {
                    $where .= " AND status = :status";
                    $params[':status'] = $status;
                }
                
                $stmt = $pdo->prepare("
                    SELECT user_id, username, email, first_name, last_name, role, status, created_at, profile_picture
                    FROM users 
                    WHERE $where
                    ORDER BY created_at DESC 
                    LIMIT :limit OFFSET :offset
                ");
                
                foreach ($params as $key => $val) {
                    $stmt->bindValue($key, $val);
                }
                $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
                $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
                $stmt->execute();
                $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE $where");
                foreach ($params as $key => $val) {
                    $countStmt->bindValue($key, $val);
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
                
            case 'details':
                $userId = $_GET['user_id'] ?? null;
                if (!$userId) {
                    echo json_encode(['success' => false, 'message' => 'User ID is required']);
                    exit;
                }
                
                $stmt = $pdo->prepare("
                    SELECT u.*, 
                           (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id) as question_count,
                           (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id) as answer_count,
                           (SELECT SUM(points) FROM user_points WHERE user_id = u.user_id) as total_points
                    FROM users u 
                    WHERE u.user_id = :user_id
                ");
                $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $stmt->execute();
                $user = $stmt->fetch(PDO::FETCH_ASSOC);
                
                if ($user) {
                    echo json_encode([
                        'success' => true,
                        'data' => $user
                    ]);
                } else {
                    echo json_encode(['success' => false, 'message' => 'User not found']);
                }
                break;
                
            default:
                echo json_encode(['success' => false, 'message' => 'Invalid action']);
        }
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Management - ASTU-Q Admin</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            background-color: #f5f7fb;
            color: #333;
        }

        .header {
            background: #667eea;
            color: white;
            padding: 1rem 2rem;
            position: sticky;
            top: 0;
            z-index: 100;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1400px;
            margin: 0 auto;
        }

        .nav-links {
            display: flex;
            gap: 2rem;
        }

        .nav-links a {
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            font-weight: 500;
            transition: color 0.3s;
        }

        .nav-links a:hover, .nav-links a.active {
            color: white;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .logout-btn {
            background: rgba(255,255,255,0.2);
            border: none;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 5px;
            cursor: pointer;
            transition: background 0.3s;
        }

        .logout-btn:hover {
            background: rgba(255,255,255,0.3);
        }

        .container {
            max-width: 1400px;
            margin: 2rem auto;
            padding: 0 2rem;
        }

        .page-header {
            margin-bottom: 2rem;
        }

        .page-header h1 {
            font-size: 1.8rem;
            color: #2d3436;
        }

        .filters {
            background: white;
            padding: 1.5rem;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            display: flex;
            gap: 1.5rem;
            margin-bottom: 2rem;
            align-items: flex-end;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }

        .filter-group label {
            font-size: 0.9rem;
            font-weight: 600;
            color: #636e72;
        }

        .filter-group input, .filter-group select {
            padding: 0.6rem 1rem;
            border: 1px solid #ddd;
            border-radius: 5px;
            outline: none;
            transition: border-color 0.3s;
        }

        .filter-group input:focus, .filter-group select:focus {
            border-color: #667eea;
        }

        .btn {
            padding: 0.6rem 1.5rem;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
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
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            overflow: hidden;
        }

        .table-header {
            padding: 1.5rem;
            border-bottom: 1px solid #eee;
            font-weight: bold;
            font-size: 1.1rem;
            background: #fcfcfc;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            text-align: left;
            padding: 1rem 1.5rem;
            background: #f8f9fa;
            color: #636e72;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.8rem;
            letter-spacing: 0.5px;
        }

        td {
            padding: 1rem 1.5rem;
            border-bottom: 1px solid #eee;
            vertical-align: middle;
        }

        .user-cell {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            object-fit: cover;
            background: #eee;
        }

        .user-name {
            font-weight: 600;
            color: #2d3436;
        }

        .user-email {
            font-size: 0.85rem;
            color: #636e72;
        }

        .status-badge {
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: 500;
        }

        .status-active { background: #d4edda; color: #155724; }
        .status-inactive { background: #fff3cd; color: #856404; }
        .status-suspended { background: #f8d7da; color: #721c24; }

        .role-badge {
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: 500;
            background: #e9ecef;
            color: #495057;
        }

        .actions {
            display: flex;
            gap: 0.5rem;
        }

        .btn-sm {
            padding: 4px 8px;
            font-size: 12px;
        }

        .btn-view { background: #667eea; color: white; }
        .btn-view:hover { background: #5a67d8; }

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

        .pagination button.active {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }

        /* Modal Styles */
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

        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #666;
        }

        .user-details-card {
            text-align: center;
            padding: 1rem;
        }

        .large-avatar {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            margin-bottom: 1rem;
            border: 3px solid #667eea;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 1rem;
            margin-top: 2rem;
            border-top: 1px solid #eee;
            padding-top: 2rem;
        }

        .stat-item {
            text-align: center;
        }

        .stat-value {
            font-size: 1.5rem;
            font-weight: bold;
            color: #667eea;
        }

        .stat-label {
            font-size: 0.8rem;
            color: #636e72;
            text-transform: uppercase;
        }

        .loading {
            text-align: center;
            padding: 2rem;
            color: #666;
        }

        .success-message {
            background: #00b894;
            color: white;
            padding: 1rem;
            border-radius: 5px;
            margin-bottom: 1rem;
            display: none;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="nav-links">
                <a href="admin_dashboard.php">Dashboard</a>
                <a href="admin_approve_questions.php">Questions</a>
                <a href="admin_approve_answers.php">Answers</a>
                <a href="admin_users.php" class="active">Users</a>
                <a href="admin_settings.php">Settings</a>
            </div>
            <div class="user-info">
                <span>Welcome, <strong><?php echo htmlspecialchars($_SESSION['admin_username']); ?></strong></span>
                <button class="logout-btn" onclick="logout()">Logout</button>
            </div>
        </div>
    </div>

    <div class="container">
        <div id="success-message" class="success-message"></div>
        
        <div class="page-header">
            <h1>User Management</h1>
            <p>Manage application users and view their statistics</p>
        </div>

        <div class="filters">
            <div class="filter-group">
                <label for="status-filter">Status:</label>
                <select id="status-filter" onchange="filterUsers()">
                    <option value="">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="suspended">Suspended</option>
                </select>
            </div>
            <div class="filter-group">
                <label for="search-input">Search:</label>
                <input type="text" id="search-input" placeholder="Username or Email..." onkeyup="filterUsers()">
            </div>
            <button class="btn btn-primary" onclick="filterUsers()">Apply Filters</button>
        </div>

        <div class="users-table">
            <div class="table-header">System Users</div>
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Role</th>
                        <th>Status</th>
                        <th>Joined Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="users-tbody">
                    <tr>
                        <td colspan="5" class="loading">Loading users...</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="pagination" id="pagination"></div>
    </div>

    <!-- User Detail Modal -->
    <div id="user-modal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>User Details</h2>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <div id="modal-body"></div>
        </div>
    </div>

    <script>
        let currentPage = 1;
        let currentStatus = '';
        let currentSearch = '';

        document.addEventListener('DOMContentLoaded', () => {
            loadUsers();
        });

        function loadUsers(page = 1, status = '', search = '') {
            currentPage = page;
            currentStatus = status;
            currentSearch = search;
            
            const tbody = document.getElementById('users-tbody');
            tbody.innerHTML = '<tr><td colspan="5" class="loading">Loading users...</td></tr>';
            
            fetch(`admin_users.php?api=1&action=list&page=${page}&status=${status}&search=${search}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderUsers(data.data.users);
                        renderPagination(data.data.pagination);
                    } else {
                        tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: red;">Error: ${data.message}</td></tr>`;
                    }
                })
                .catch(error => {
                    tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: red;">Error loading data</td></tr>`;
                });
        }

        function renderUsers(users) {
            const tbody = document.getElementById('users-tbody');
            if (users.length === 0) {
                tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; padding: 2rem;">No users found</td></tr>';
                return;
            }

            tbody.innerHTML = users.map(user => `
                <tr>
                    <td>
                        <div class="user-cell">
                            <img src="${user.profile_picture || 'https://via.placeholder.com/40'}" class="user-avatar" alt="Avatar">
                            <div>
                                <div class="user-name">${user.first_name} ${user.last_name} (@${user.username})</div>
                                <div class="user-email">${user.email}</div>
                            </div>
                        </div>
                    </td>
                    <td><span class="role-badge">${user.role}</span></td>
                    <td><span class="status-badge status-${user.status}">${user.status}</span></td>
                    <td>${new Date(user.created_at).toLocaleDateString()}</td>
                    <td>
                        <div class="actions">
                            <button class="btn btn-sm btn-view" onclick="viewUser(${user.user_id})">View Details</button>
                        </div>
                    </td>
                </tr>
            `).join('');
        }

        function renderPagination(pagination) {
            const container = document.getElementById('pagination');
            let html = '';
            
            if (pagination.total_pages > 1) {
                html += `<button ${pagination.current_page <= 1 ? 'disabled' : ''} onclick="loadUsers(${pagination.current_page - 1}, '${currentStatus}', '${currentSearch}')">Previous</button>`;
                
                for (let i = 1; i <= pagination.total_pages; i++) {
                    html += `<button class="${i === pagination.current_page ? 'active' : ''}" onclick="loadUsers(${i}, '${currentStatus}', '${currentSearch}')">${i}</button>`;
                }
                
                html += `<button ${pagination.current_page >= pagination.total_pages ? 'disabled' : ''} onclick="loadUsers(${pagination.current_page + 1}, '${currentStatus}', '${currentSearch}')">Next</button>`;
            }
            
            container.innerHTML = html;
        }

        function filterUsers() {
            const status = document.getElementById('status-filter').value;
            const search = document.getElementById('search-input').value;
            loadUsers(1, status, search);
        }

        function viewUser(userId) {
            fetch(`admin_users.php?api=1&action=details&user_id=${userId}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showUserModal(data.data);
                    }
                });
        }

        function showUserModal(user) {
            const modal = document.getElementById('user-modal');
            const modalBody = document.getElementById('modal-body');
            
            modalBody.innerHTML = `
                <div class="user-details-card">
                    <img src="${user.profile_picture || 'https://via.placeholder.com/100'}" class="large-avatar" alt="Avatar">
                    <h2>${user.first_name} ${user.last_name}</h2>
                    <p style="color: #666; margin-bottom: 0.5rem;">@${user.username}</p>
                    <p style="color: #666;">${user.email}</p>
                    <div style="margin-top: 1rem;">
                        <span class="role-badge">${user.role}</span>
                        <span class="status-badge status-${user.status}">${user.status}</span>
                    </div>
                    
                    <div class="stats-grid">
                        <div class="stat-item">
                            <div class="stat-value">${user.question_count}</div>
                            <div class="stat-label">Questions</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-value">${user.answer_count}</div>
                            <div class="stat-label">Answers</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-value">${user.total_points || 0}</div>
                            <div class="stat-label">Points</div>
                        </div>
                    </div>
                    
                    <div style="margin-top: 2rem; text-align: left; padding: 1rem; background: #f8f9fa; border-radius: 5px;">
                        <p><strong>Joined:</strong> ${new Date(user.created_at).toLocaleString()}</p>
                        <p><strong>Level:</strong> ${user.level || 1}</p>
                        <p><strong>Bio:</strong> ${user.bio || 'No bio provided'}</p>
                    </div>
                </div>
            `;
            
            modal.style.display = 'block';
        }

        function closeModal() {
            document.getElementById('user-modal').style.display = 'none';
        }

        function logout() {
            if (confirm('Are you sure you want to logout?')) {
                window.location.href = 'admin_logout.php';
            }
        }

        window.onclick = function(event) {
            const modal = document.getElementById('user-modal');
            if (event.target == modal) {
                closeModal();
            }
        }
    </script>
</body>
</html>
