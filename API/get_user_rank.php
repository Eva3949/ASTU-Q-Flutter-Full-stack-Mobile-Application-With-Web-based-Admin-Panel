<?php
require_once 'db_connection.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}



// Get parameters
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$timeFilter = isset($_GET['time_filter']) ? $_GET['time_filter'] : 'all';
$category = isset($_GET['category']) ? $_GET['category'] : 'points';

// Validate inputs
if ($userId <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid user ID'
    ]);
    exit;
}

// Build WHERE clause for time filter
$whereClause = '';
$params = [];

switch ($timeFilter) {
    case 'today':
        $whereClause = "AND DATE(u.created_at) = CURDATE()";
        break;
    case 'week':
        $whereClause = "AND u.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
        break;
    case 'month':
        $whereClause = "AND u.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
        break;
    case 'year':
        $whereClause = "AND u.created_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)";
        break;
    case 'all':
    default:
        $whereClause = "";
        break;
}

// Build ORDER BY clause based on category
$orderBy = '';
switch ($category) {
    case 'questions':
        $orderBy = "ORDER BY sub.questions_count DESC, sub.total_points DESC";
        break;
    case 'answers':
        $orderBy = "ORDER BY sub.answers_count DESC, sub.total_points DESC";
        break;
    case 'best_answers':
        $orderBy = "ORDER BY sub.best_answers_count DESC, sub.total_points DESC";
        break;
    case 'upvotes':
        $orderBy = "ORDER BY sub.upvotes_received DESC, sub.total_points DESC";
        break;
    case 'points':
    default:
        $orderBy = "ORDER BY sub.total_points DESC, sub.level DESC";
        break;
}

try {
    // Subquery to calculate points, questions asked, answers given, and best answers
    $subQuery = "
        SELECT
            u.user_id,
            u.first_name,
            u.last_name,
            u.email,
            u.profile_picture,
            u.level,
            u.email_verified_at,
            u.created_at,
            (SELECT COALESCE(SUM(points), 0) FROM user_points WHERE user_id = u.user_id) as total_points,
            (SELECT COUNT(*) FROM questions WHERE user_id = u.user_id AND status = 'approved') as questions_count,
            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND status = 'approved') as answers_count,
            (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND status = 'approved' AND is_best = 1) as best_answers_count,
            0 as upvotes_received
        FROM users u
        WHERE u.status = 'active' $whereClause
    ";

    // Check if user exists and is active
    $userCheckQuery = "
        SELECT user_id as id, status FROM users
        WHERE user_id = :user_id AND status = 'active'
    ";
    $userCheckStmt = $pdo->prepare($userCheckQuery);
    $userCheckStmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $userCheckStmt->execute();
    
    if ($userCheckStmt->rowCount() === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'User not found or inactive'
        ]);
        exit;
    }
    
    // Get user rank using a simplified ranking query
    $rankQuery = "
        SELECT
            user_rank.rank
        FROM (
            SELECT
                sub.user_id as id,
                ROW_NUMBER() OVER ($orderBy) as rank
            FROM ($subQuery) as sub
        ) user_rank
        WHERE user_rank.id = :user_id
    ";
    
    $rankStmt = $pdo->prepare($rankQuery);
    $rankStmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $rankStmt->execute();
    
    $rankResult = $rankStmt->fetch(PDO::FETCH_ASSOC);
    
    if ($rankResult) {
        $rank = (int)$rankResult['rank'];
        
        // Get additional user info for context
        $userInfoQuery = "
            SELECT
                CONCAT(sub.first_name, ' ', sub.last_name) as name,
                sub.total_points as points,
                sub.level,
                sub.questions_count,
                sub.answers_count,
                sub.best_answers_count,
                0 as upvotes_received
            FROM ($subQuery) as sub
            WHERE sub.user_id = :user_id
        ";
        
        $userInfoStmt = $pdo->prepare($userInfoQuery);
        $userInfoStmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $userInfoStmt->execute();
        $userInfo = $userInfoStmt->fetch(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'rank' => $rank,
            'userInfo' => [
                'name' => $userInfo['name'],
                'points' => (int)$userInfo['points'],
                'level' => (int)$userInfo['level'],
                'questionsCount' => (int)$userInfo['questions_count'],
                'answersCount' => (int)$userInfo['answers_count'],
                'bestAnswersCount' => (int)$userInfo['best_answers_count'],
                'upvotesReceived' => (int)$userInfo['upvotes_received']
            ],
            'filters' => [
                'timeFilter' => $timeFilter,
                'category' => $category
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'User rank not found'
        ]);
    }
    
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>
