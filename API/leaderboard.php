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
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
$timeFilter = isset($_GET['time_filter']) ? $_GET['time_filter'] : 'all';
$category = isset($_GET['category']) ? $_GET['category'] : 'points';

// Validate inputs
$page = max(1, $page);
$limit = max(1, min(100, $limit)); // Limit to 100 max

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
        $orderBy = "ORDER BY sub.total_points DESC, sub.level DESC";
        break;
    case 'points':
    default:
        $orderBy = "ORDER BY sub.total_points DESC, sub.level DESC";
        break;
}

try {
    // Get total count for pagination
    $countQuery = "
        SELECT COUNT(*) as total
        FROM users u
        WHERE u.status = 'active'
    ";
    $countStmt = $pdo->prepare($countQuery);
    $countStmt->execute();
    $totalUsers = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Get leaderboard users with pagination
    $offset = ($page - 1) * $limit;
    
    $query = "
        SELECT
            sub.user_id as id,
            CONCAT(sub.first_name, ' ', sub.last_name) as name,
            sub.email,
            sub.profile_picture as avatar_url,
            sub.total_points as points,
            sub.level,
            sub.email_verified_at as is_verified,
            sub.created_at as joined_at,
            sub.questions_count,
            sub.answers_count,
            sub.best_answers_count,
            0 as upvotes_received,
            CASE
                WHEN sub.total_points >= 1000 THEN 'Diamond'
                WHEN sub.total_points >= 500 THEN 'Platinum'
                WHEN sub.total_points >= 200 THEN 'Gold'
                WHEN sub.total_points >= 100 THEN 'Silver'
                WHEN sub.total_points >= 50 THEN 'Bronze'
                ELSE 'Newcomer'
            END as badge
        FROM (
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
                (SELECT COUNT(*) FROM answers WHERE user_id = u.user_id AND status = 'approved' AND is_best = 1) as best_answers_count
            FROM users u
            WHERE u.status = 'active' $whereClause
        ) as sub
        $orderBy
        LIMIT :limit OFFSET :offset
    ";
    
    $stmt = $pdo->prepare($query);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    
    $users = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $users[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'avatarUrl' => $row['avatar_url'] ?: null,
            'points' => (int)$row['points'],
            'level' => (int)$row['level'],
            'badge' => $row['badge'],
            'questionsCount' => (int)$row['questions_count'],
            'answersCount' => (int)$row['answers_count'],
            'joinedAt' => $row['created_at']
        ];
    }
    
    // Calculate pagination info
    $totalPages = ceil($totalUsers / $limit);
    $hasNextPage = $page < $totalPages;
    $hasPreviousPage = $page > 1;
    
    echo json_encode([
        'success' => true,
        'users' => $users,
        'pagination' => [
            'currentPage' => $page,
            'totalPages' => $totalPages,
            'totalUsers' => $totalUsers,
            'limit' => $limit,
            'hasNextPage' => $hasNextPage,
            'hasPreviousPage' => $hasPreviousPage
        ],
        'filters' => [
            'timeFilter' => $timeFilter,
            'category' => $category
        ]
    ]);
    
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
