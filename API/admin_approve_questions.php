<?php
/**
 * Admin Question Approval System
 * ASTU-Q Admin Control Panel - Question Management
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
                $status = $_GET['status'] ?? 'pending';
                $search = $_GET['search'] ?? '';
                $limit = 10;
                $offset = ($page - 1) * $limit;
                
                $where = "1=1";
                $params = [];
                
                if ($status !== 'all') {
                    $where .= " AND q.status = :status";
                    $params[':status'] = $status;
                }
                
                if (!empty($search)) {
                    $where .= " AND (q.title LIKE :search OR q.content LIKE :search)";
                    $params[':search'] = "%$search%";
                }
                
                $stmt = $pdo->prepare("
                    SELECT q.*, u.username as author_name 
                    FROM questions q 
                    LEFT JOIN users u ON q.user_id = u.user_id 
                    WHERE $where
                    ORDER BY q.created_at DESC 
                    LIMIT :limit OFFSET :offset
                ");
                
                foreach ($params as $key => $val) {
                    $stmt->bindValue($key, $val);
                }
                $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
                $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
                $stmt->execute();
                $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM questions q WHERE $where");
                foreach ($params as $key => $val) {
                    $countStmt->bindValue($key, $val);
                }
                $countStmt->execute();
                $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'questions' => $questions,
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
                $questionId = $_GET['question_id'] ?? null;
                if (!$questionId) {
                    echo json_encode(['success' => false, 'message' => 'Question ID is required']);
                    exit;
                }
                
                $stmt = $pdo->prepare("
                    SELECT q.*, u.username as author_name 
                    FROM questions q 
                    LEFT JOIN users u ON q.user_id = u.user_id 
                    WHERE q.question_id = :question_id
                ");
                $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
                $stmt->execute();
                $question = $stmt->fetch(PDO::FETCH_ASSOC);
                
                if ($question) {
                    $answerStmt = $pdo->prepare("
                        SELECT a.*, u.username as author_name 
                        FROM answers a 
                        LEFT JOIN users u ON a.user_id = u.user_id 
                        WHERE a.question_id = :question_id 
                        ORDER BY a.created_at DESC
                    ");
                    $answerStmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
                    $answerStmt->execute();
                    $answers = $answerStmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    echo json_encode([
                        'success' => true,
                        'data' => ['question' => $question, 'answers' => $answers]
                    ]);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Question not found']);
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

// Handle POST actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header("Content-Type: application/json");
    
    // Debug: Log the raw POST data
    error_log("POST data received: " . file_get_contents('php://input'));
    error_log("POST array: " . print_r($_POST, true));
    
    $action = $_POST['action'] ?? '';
    $adminUsername = $_SESSION['admin_username'] ?? '';
    
    // Debug: Log the action
    error_log("Action to execute: " . $action);
    error_log("Admin username: " . $adminUsername);
    
    try {
        switch ($action) {
            case 'approve':
                $questionId = $_POST['question_id'] ?? null;
                if (!$questionId) {
                    echo json_encode(['success' => false, 'message' => 'Question ID is required']);
                    exit;
                }
                
                // Check if question exists and is pending
                $checkStmt = $pdo->prepare("SELECT question_id, user_id, status FROM questions WHERE question_id = :question_id");
                $checkStmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
                $checkStmt->execute();
                $question = $checkStmt->fetch(PDO::FETCH_ASSOC);
                
                if (!$question) {
                    echo json_encode(['success' => false, 'message' => 'Question not found']);
                    exit;
                }
                
                if ($question['status'] !== 'pending') {
                    echo json_encode(['success' => false, 'message' => 'Question is not in pending status']);
                    exit;
                }
                
                try {
                    $pdo->beginTransaction();

                    $stmt = $pdo->prepare("UPDATE questions SET status = 'approved', moderated_at = NOW() WHERE question_id = :question_id");
                    $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
                    $stmt->execute();
                    
                    // Give 5 points to the question author
                    $authorId = $question['user_id'];
                    
                    // a. Insert into user_points table for history
                    $pointStmt = $pdo->prepare("INSERT INTO user_points (user_id, points, reason, reference_id, created_at) VALUES (:user_id, 5, 'question_posted', :source_id, NOW())");
                    $pointStmt->bindParam(':user_id', $authorId, PDO::PARAM_INT);
                    $pointStmt->bindParam(':source_id', $questionId, PDO::PARAM_INT);
                    $pointStmt->execute();

                    $pdo->commit();
                    echo json_encode(['success' => true, 'message' => 'Question approved successfully and points awarded']);
                } catch (Exception $e) {
                    if ($pdo->inTransaction()) {
                        $pdo->rollBack();
                    }
                    error_log("Error approving question: " . $e->getMessage());
                    echo json_encode(['success' => false, 'message' => 'Failed to approve question: ' . $e->getMessage()]);
                }
                break;
                
            case 'reject':
                $questionId = $_POST['question_id'] ?? null;
                $reason = $_POST['reason'] ?? '';
                
                if (!$questionId) {
                    echo json_encode(['success' => false, 'message' => 'Question ID is required']);
                    exit;
                }
                
                // Check if question exists and is pending
                $checkStmt = $pdo->prepare("SELECT question_id, status FROM questions WHERE question_id = :question_id");
                $checkStmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
                $checkStmt->execute();
                $question = $checkStmt->fetch(PDO::FETCH_ASSOC);
                
                if (!$question) {
                    echo json_encode(['success' => false, 'message' => 'Question not found']);
                    exit;
                }
                
                if ($question['status'] !== 'pending') {
                    echo json_encode(['success' => false, 'message' => 'Question is not in pending status']);
                    exit;
                }
                
                $stmt = $pdo->prepare("UPDATE questions SET status = 'rejected', moderation_reason = :reason, moderated_at = NOW() WHERE question_id = :question_id");
                $stmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
                $stmt->bindParam(':reason', $reason, PDO::PARAM_STR);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    echo json_encode(['success' => true, 'message' => 'Question rejected successfully']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Failed to update question status']);
                }
                break;

            case 'mark_best':
                $answerId = $_POST['answer_id'] ?? null;
                $questionId = $_POST['question_id'] ?? null;

                if (!$answerId || !$questionId) {
                    echo json_encode(['success' => false, 'message' => 'Answer ID and Question ID are required']);
                    exit;
                }

                try {
                    $pdo->beginTransaction();

                    // 1. Get the answer author ID
                    $authorStmt = $pdo->prepare("SELECT user_id FROM answers WHERE answer_id = :answer_id");
                    $authorStmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
                    $authorStmt->execute();
                    $answer = $authorStmt->fetch(PDO::FETCH_ASSOC);
                    
                    if (!$answer) {
                        throw new Exception("Answer not found");
                    }
                    $authorId = $answer['user_id'];

                    // 2. Reset all answers for this question to NOT best
                    $resetStmt = $pdo->prepare("UPDATE answers SET is_best = 0 WHERE question_id = :question_id");
                    $resetStmt->bindParam(':question_id', $questionId, PDO::PARAM_INT);
                    $resetStmt->execute();

                    // 3. Mark specific answer as best
                    $markStmt = $pdo->prepare("UPDATE answers SET is_best = 1 WHERE answer_id = :answer_id");
                    $markStmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
                    $markStmt->execute();

                    // 4. Give 10 points to the answer author
                    // a. Insert into user_points table for history
                    $pointStmt = $pdo->prepare("INSERT INTO user_points (user_id, points, reason, reference_id, created_at) VALUES (:user_id, 10, 'best_answer', :source_id, NOW())");
                    $pointStmt->bindParam(':user_id', $authorId, PDO::PARAM_INT);
                    $pointStmt->bindParam(':source_id', $answerId, PDO::PARAM_INT);
                    $pointStmt->execute();

                    $pdo->commit();
                    echo json_encode(['success' => true, 'message' => 'Answer marked as best successfully and points awarded']);
                } catch (Exception $e) {
                    if ($pdo->inTransaction()) {
                        $pdo->rollBack();
                    }
                    echo json_encode(['success' => false, 'message' => 'Failed to mark best answer: ' . $e->getMessage()]);
                }
                break;

            case 'unmark_best':
                $answerId = $_POST['answer_id'] ?? null;

                if (!$answerId) {
                    echo json_encode(['success' => false, 'message' => 'Answer ID is required']);
                    exit;
                }

                try {
                    $stmt = $pdo->prepare("UPDATE answers SET is_best = 0 WHERE answer_id = :answer_id");
                    $stmt->bindParam(':answer_id', $answerId, PDO::PARAM_INT);
                    $stmt->execute();

                    echo json_encode(['success' => true, 'message' => 'Answer unmarked successfully']);
                } catch (PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Failed to unmark answer: ' . $e->getMessage()]);
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
    <title>Question Management - ASTU-Q Admin Panel</title>
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
        }

        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1200px;
            margin: 0 auto;
        }

        .nav-links {
            display: flex;
            gap: 2rem;
            align-items: center;
        }

        .nav-links a {
            color: white;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 5px;
            transition: background 0.3s;
        }

        .nav-links a:hover {
            background: rgba(255, 255, 255, 0.2);
        }

        .nav-links a.active {
            background: rgba(255, 255, 255, 0.3);
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .logout-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #666;
        }

        .logout-btn:hover {
            background: rgba(255, 255, 255, 0.2);
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
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

        .questions-table {
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

        .question-title {
            font-weight: bold;
            color: #333;
            margin-bottom: 0.25rem;
        }

        .question-content {
            color: #666;
            font-size: 14px;
            margin-bottom: 0.5rem;
        }

        .question-meta {
            font-size: 12px;
            color: #666;
        }

        .status-badge {
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: 500;
        }

        .status-pending {
            background: #fff3cd;
            color: #856404;
        }

        .status-approved {
            background: #d4edda;
            color: #155724;
        }

        .status-rejected {
            background: #f8d7da;
            color: #721c24;
        }

        .actions {
            display: flex;
            gap: 0.5rem;
        }

        .btn-sm {
            padding: 4px 8px;
            font-size: 12px;
        }

        .btn-approve {
            background: #00b894;
            color: white;
        }

        .btn-approve:hover {
            background: #00a885;
        }

        .btn-reject {
            background: #ff4757;
            color: white;
        }

        .btn-reject:hover {
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
            max-width: 800px;
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

        .question-details {
            margin-bottom: 2rem;
        }

        .question-details h3 {
            color: #333;
            margin-bottom: 1rem;
        }

        .question-details p {
            color: #666;
            line-height: 1.6;
            margin-bottom: 1rem;
        }

        .answers-section {
            border-top: 1px solid #eee;
            padding-top: 1.5rem;
        }

        .answers-section h3 {
            color: #333;
            margin-bottom: 1rem;
        }

        .answer-item {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 5px;
            margin-bottom: 1rem;
            border-left: 4px solid transparent;
        }

        .answer-item.is-best {
            border-left-color: #f1c40f;
            background: #fffdf0;
        }

        .best-badge {
            background: #f1c40f;
            color: #fff;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 10px;
            font-weight: bold;
            text-transform: uppercase;
            margin-left: 10px;
        }

        .btn-best {
            background: #f1c40f;
            color: white;
        }

        .btn-unmark {
            background: #636e72;
            color: white;
        }

        .btn-unmark:hover {
            background: #2d3436;
        }

        .answer-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 0.5rem;
        }

        .answer-meta {
            font-size: 12px;
            color: #666;
            margin-bottom: 0.5rem;
        }

        .answer-content {
            color: #333;
            line-height: 1.6;
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

        .question-images {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 1rem;
            margin-bottom: 1rem;
        }
        .question-image-item {
            width: 150px;
            height: 150px;
            object-fit: cover;
            border-radius: 8px;
            cursor: pointer;
            border: 1px solid #ddd;
            transition: transform 0.2s;
        }
        .question-image-item:hover {
            transform: scale(1.05);
        }

        @media (max-width: 768px) {
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
            <div class="nav-links">
                <a href="admin_dashboard.php">Dashboard</a>
                <a href="admin_approve_questions.php" class="active">Questions</a>
                <a href="admin_users.php">Users</a>
                <a href="admin_approve_answers.php">Answers</a>
                <a href="admin_content_moderation.php">Moderation</a>
                <a href="admin_settings.php">Settings</a>
            </div>
            <div class="user-info">
                <span>Welcome, <strong><?php echo htmlspecialchars($_SESSION['admin_username']); ?></strong></span>
                <button class="logout-btn" onclick="logout()">Logout</button>
            </div>
        </div>
    </div>

    <div class="container">
        <div id="error-message" class="error" style="display: none;"></div>
        <div id="success-message" class="success" style="display: none;"></div>
        
        <div class="page-header">
            <h1>Question Management</h1>
            <p>Review and manage pending questions</p>
        </div>

        <div class="filters">
            <div class="filter-group">
                <label for="status-filter">Status:</label>
                <select id="status-filter" onchange="filterQuestions()">
                    <option value="pending">Pending</option>
                    <option value="approved">Approved</option>
                    <option value="rejected">Rejected</option>
                    <option value="all">All</option>
                </select>
            </div>
            <div class="filter-group">
                <label for="search-input">Search:</label>
                <input type="text" id="search-input" placeholder="Search questions..." onkeyup="filterQuestions()">
            </div>
            <button class="btn btn-primary" onclick="filterQuestions()">Search</button>
        </div>

        <div class="questions-table">
            <div class="table-header">Pending Questions</div>
            <div class="table-content">
                <table id="questions-table">
                    <thead>
                        <tr>
                            <th>Question</th>
                            <th>Author</th>
                            <th>Subject</th>
                            <th>Status</th>
                            <th>Created</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="questions-tbody">
                        <tr>
                            <td colspan="6" class="loading">Loading questions...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="pagination" id="pagination">
            <!-- Pagination will be generated dynamically -->
        </div>
    </div>

    <!-- Question Details Modal -->
    <div id="question-modal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>Question Details</h2>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <div id="modal-body">
                <!-- Question details will be loaded here -->
            </div>
        </div>
    </div>

    <script>
        let currentPage = 1;
        let currentStatus = 'pending';

        // Load questions
        function loadQuestions(page = 1, status = 'pending', search = '') {
            currentPage = page;
            currentStatus = status;
            
            fetch(`admin_approve_questions.php?api=1&action=list&page=${page}&status=${status}&search=${encodeURIComponent(search)}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        renderQuestions(data.data.questions);
                        renderPagination(data.data.pagination);
                    } else {
                        showError('Failed to load questions: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading questions: ' + error.message));
        }

        // Render questions
        function renderQuestions(questions) {
            const tbody = document.getElementById('questions-tbody');
            
            if (questions.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #666;">No questions found</td></tr>';
                return;
            }

            tbody.innerHTML = questions.map(question => `
                <tr>
                    <td>
                        <div class="question-title">${question.title}</div>
                        <div class="question-content">${question.content.substring(0, 100)}${question.content.length > 100 ? '...' : ''}</div>
                        <div class="question-meta">
                            ID: ${question.question_id} | By ${question.author_name || 'Anonymous'}
                        </div>
                    </td>
                    <td>${question.author_name || 'Anonymous'}</td>
                    <td>${question.subject || 'N/A'}</td>
                    <td><span class="status-badge status-${question.status}">${question.status}</span></td>
                    <td>${new Date(question.created_at).toLocaleString()}</td>
                    <td>
                        <div class="actions">
                            <button class="btn btn-sm btn-view" onclick="viewQuestion(${question.question_id})">View</button>
                            ${question.status === 'pending' ? `
                                <button class="btn btn-sm btn-approve" onclick="approveQuestion(${question.question_id})">Approve</button>
                                <button class="btn btn-sm btn-reject" onclick="rejectQuestion(${question.question_id})">Reject</button>
                            ` : ''}
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
            html += `<button ${pagination.current_page <= 1 ? 'disabled' : ''} onclick="loadQuestions(${pagination.current_page - 1}, '${currentStatus}')">Previous</button>`;
            
            // Page numbers
            for (let i = 1; i <= pagination.total_pages; i++) {
                html += `<button class="${i === pagination.current_page ? 'active' : ''}" onclick="loadQuestions(${i}, '${currentStatus}')">${i}</button>`;
            }
            
            // Next button
            html += `<button ${pagination.current_page >= pagination.total_pages ? 'disabled' : ''} onclick="loadQuestions(${pagination.current_page + 1}, '${currentStatus}')">Next</button>`;
            
            container.innerHTML = html;
        }

        // Filter questions
        function filterQuestions() {
            const status = document.getElementById('status-filter').value;
            const search = document.getElementById('search-input').value;
            loadQuestions(1, status, search);
        }

        // View question details
        function viewQuestion(questionId) {
            fetch(`admin_approve_questions.php?api=1&action=details&question_id=${questionId}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showQuestionModal(data.data);
                    } else {
                        showError('Failed to load question details: ' + data.message);
                    }
                })
                .catch(error => showError('Error loading question details: ' + error.message));
        }

        // Show question modal
        function showQuestionModal(data) {
            const modal = document.getElementById('question-modal');
            const modalBody = document.getElementById('modal-body');
            
            modalBody.innerHTML = `
                <div class="question-details">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
                        <h3 style="margin-bottom: 0;">${data.question.title}</h3>
                        <div class="question-actions-top">
                            ${data.question.status === 'pending' ? `
                                <button class="btn btn-sm btn-approve" onclick="approveQuestion(${data.question.question_id}, true)">Approve</button>
                                <button class="btn btn-sm btn-reject" onclick="rejectQuestion(${data.question.question_id}, true)">Reject</button>
                            ` : ''}
                        </div>
                    </div>
                    <p>${data.question.content}</p>
                    ${(() => {
                        try {
                            const images = typeof data.question.images === 'string' ? JSON.parse(data.question.images) : data.question.images;
                            if (images && Array.isArray(images) && images.length > 0) {
                                return `
                                    <div class="question-images">
                                        ${images.map(img => `
                                            <a href="${img}" target="_blank">
                                                <img src="${img}" class="question-image-item" alt="Question Image">
                                            </a>
                                        `).join('')}
                                    </div>
                                `;
                            }
                        } catch (e) {
                            console.error('Error parsing question images:', e);
                        }
                        return '';
                    })()}
                    <div class="question-meta">
                        <strong>Author:</strong> ${data.question.author_name || 'Anonymous'}<br>
                        <strong>Subject:</strong> ${data.question.subject || 'N/A'}<br>
                        <strong>Status:</strong> <span class="status-badge status-${data.question.status}">${data.question.status}</span><br>
                        <strong>Created:</strong> ${new Date(data.question.created_at).toLocaleString()}
                    </div>
                </div>
                
                <div class="answers-section">
                    <h3>Answers (${data.answers.length})</h3>
                    ${data.answers.length === 0 ? '<p style="color: #666;">No answers yet</p>' : data.answers.map(answer => `
                        <div class="answer-item ${answer.is_best == 1 ? 'is-best' : ''}">
                            <div class="answer-header">
                                <div class="answer-meta">
                                    <strong>By:</strong> ${answer.author_name || 'Anonymous'} | 
                                    <strong>Created:</strong> ${new Date(answer.created_at).toLocaleString()}
                                    ${answer.is_best == 1 ? '<span class="best-badge">Best Answer</span>' : ''}
                                </div>
                                <div class="answer-actions">
                                    ${answer.is_best == 0 ? `
                                        <button class="btn btn-sm btn-best" onclick="markAsBest(${answer.answer_id}, ${data.question.question_id})">Mark Best</button>
                                    ` : `
                                        <button class="btn btn-sm btn-unmark" onclick="unmarkAsBest(${answer.answer_id}, ${data.question.question_id})">Unmark Best</button>
                                    `}
                                </div>
                            </div>
                            <div class="answer-content">${answer.content}</div>
                        </div>
                    `).join('')}
                </div>
                
                <div class="modal-actions">
                    ${data.question.status === 'pending' ? `
                        <button class="btn btn-approve" onclick="approveQuestion(${data.question.question_id}, true)">Approve</button>
                        <button class="btn btn-reject" onclick="rejectQuestion(${data.question.question_id}, true)">Reject</button>
                    ` : ''}
                    <button class="btn" onclick="closeModal()">Close</button>
                </div>
            `;
            
            modal.style.display = 'block';
        }

        // Close modal
        function closeModal() {
            document.getElementById('question-modal').style.display = 'none';
        }

        // Approve question
        function approveQuestion(questionId, shouldCloseModal = false) {
            if (confirm('Are you sure you want to approve this question?')) {
                fetch('admin_approve_questions.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `action=approve&question_id=${questionId}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess('Question approved successfully');
                        if (shouldCloseModal) closeModal();
                        loadQuestions(currentPage, currentStatus);
                    } else {
                        showError('Failed to approve question: ' + data.message);
                    }
                })
                .catch(error => showError('Error approving question: ' + error.message));
            }
        }

        // Reject question
        function rejectQuestion(questionId, shouldCloseModal = false) {
            const reason = prompt('Please provide a reason for rejection:');
            if (reason) {
                fetch('admin_approve_questions.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `action=reject&question_id=${questionId}&reason=${encodeURIComponent(reason)}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess('Question rejected successfully');
                        if (shouldCloseModal) closeModal();
                        loadQuestions(currentPage, currentStatus);
                    } else {
                        showError('Failed to reject question: ' + data.message);
                    }
                })
                .catch(error => showError('Error rejecting question: ' + error.message));
            }
        }

        // Mark as best answer
        function markAsBest(answerId, questionId) {
            if (confirm('Are you sure you want to mark this answer as the best? This will replace any existing best answer for this question.')) {
                fetch('admin_approve_questions.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `action=mark_best&answer_id=${answerId}&question_id=${questionId}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess(data.message);
                        // Refresh the view
                        viewQuestion(questionId);
                    } else {
                        showError('Failed to mark best answer: ' + data.message);
                    }
                })
                .catch(error => showError('Error marking best answer: ' + error.message));
            }
        }

        // Unmark best answer
        function unmarkAsBest(answerId, questionId) {
            if (confirm('Are you sure you want to unmark this answer as the best?')) {
                fetch('admin_approve_questions.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: `action=unmark_best&answer_id=${answerId}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showSuccess(data.message);
                        // Refresh the view
                        viewQuestion(questionId);
                    } else {
                        showError('Failed to unmark answer: ' + data.message);
                    }
                })
                .catch(error => showError('Error unmarking answer: ' + error.message));
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
            const modal = document.getElementById('question-modal');
            if (event.target === modal) {
                closeModal();
            }
        }

        // Load questions on page load
        document.addEventListener('DOMContentLoaded', () => {
            const urlParams = new URLSearchParams(window.location.search);
            const status = urlParams.get('status') || 'pending';
            document.getElementById('status-filter').value = status;
            loadQuestions(1, status);
        });
    </script>
</body>
</html>
