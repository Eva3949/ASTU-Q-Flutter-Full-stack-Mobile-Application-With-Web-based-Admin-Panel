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
$timeFilter = isset($_GET['time_filter']) ? $_GET['time_filter'] : 'all';
$category = isset($_GET['category']) ? $_GET['category'] : 'points';

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

    // Get total users count
    $totalUsersQuery = "
        SELECT COUNT(*) as total
        FROM ($subQuery) as sub
    ";
    $totalUsersStmt = $pdo->prepare($totalUsersQuery);
    $totalUsersStmt->execute();
    $totalUsers = (int)$totalUsersStmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Get top performer stats
    $topPerformerQuery = "
        SELECT
            CONCAT(sub.first_name, ' ', sub.last_name) as name,
            sub.total_points as points,
            sub.level,
            sub.questions_count,
            sub.answers_count,
            sub.best_answers_count,
            0 as upvotes_received
        FROM ($subQuery) as sub
        $orderBy
        LIMIT 1
    ";
    $topPerformerStmt = $pdo->prepare($topPerformerQuery);
    $topPerformerStmt->execute();
    $topPerformer = $topPerformerStmt->fetch(PDO::FETCH_ASSOC);
    
    // Get distribution stats
    $distributionQuery = "
        SELECT
            COUNT(*) as total_users,
            SUM(sub.total_points) as total_points,
            AVG(sub.total_points) as avg_points,
            MAX(sub.total_points) as max_points,
            MIN(sub.total_points) as min_points,
            SUM(sub.questions_count) as total_questions,
            SUM(sub.answers_count) as total_answers,
            SUM(sub.best_answers_count) as total_best_answers,
            0 as total_upvotes
        FROM ($subQuery) as sub
    ";
    $distributionStmt = $pdo->prepare($distributionQuery);
    $distributionStmt->execute();
    $distribution = $distributionStmt->fetch(PDO::FETCH_ASSOC);
    
    // Get badge distribution
    $badgeQuery = "
        SELECT
            CASE
                WHEN sub.total_points >= 1000 THEN 'Diamond'
                WHEN sub.total_points >= 500 THEN 'Platinum'
                WHEN sub.total_points >= 200 THEN 'Gold'
                WHEN sub.total_points >= 100 THEN 'Silver'
                WHEN sub.total_points >= 50 THEN 'Bronze'
                ELSE 'Newcomer'
            END as badge,
            COUNT(*) as count
        FROM ($subQuery) as sub
        GROUP BY
            CASE
                WHEN sub.total_points >= 1000 THEN 'Diamond'
                WHEN sub.total_points >= 500 THEN 'Platinum'
                WHEN sub.total_points >= 200 THEN 'Gold'
                WHEN sub.total_points >= 100 THEN 'Silver'
                WHEN sub.total_points >= 50 THEN 'Bronze'
                ELSE 'Newcomer'
            END
        ORDER BY
            CASE
                WHEN sub.total_points >= 1000 THEN 1
                WHEN sub.total_points >= 500 THEN 2
                WHEN sub.total_points >= 200 THEN 3
                WHEN sub.total_points >= 100 THEN 4
                WHEN sub.total_points >= 50 THEN 5
                ELSE 6
            END
    ";
    $badgeStmt = $pdo->prepare($badgeQuery);
    $badgeStmt->execute();
    $badgeDistribution = $badgeStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get level distribution
    $levelQuery = "
        SELECT
            CASE
                WHEN sub.level >= 50 THEN '50+'
                WHEN sub.level >= 40 THEN '40-49'
                WHEN sub.level >= 30 THEN '30-39'
                WHEN sub.level >= 20 THEN '20-29'
                WHEN sub.level >= 10 THEN '10-19'
                ELSE '1-9'
            END as level_range,
            COUNT(*) as count
        FROM ($subQuery) as sub
        GROUP BY
            CASE
                WHEN sub.level >= 50 THEN '50+'
                WHEN sub.level >= 40 THEN '40-49'
                WHEN sub.level >= 30 THEN '30-39'
                WHEN sub.level >= 20 THEN '20-29'
                WHEN sub.level >= 10 THEN '10-19'
                ELSE '1-9'
            END
        ORDER BY
            CASE
                WHEN sub.level >= 50 THEN 1
                WHEN sub.level >= 40 THEN 2
                WHEN sub.level >= 30 THEN 3
                WHEN sub.level >= 20 THEN 4
                WHEN sub.level >= 10 THEN 5
                ELSE 6
            END
    ";
    $levelStmt = $pdo->prepare($levelQuery);
    $levelStmt->execute();
    $levelDistribution = $levelStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get activity trends (last 7 days)
    $activityQuery = "
        SELECT
            DATE(created_at) as date,
            COUNT(*) as new_users
        FROM users
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            AND status = 'active'
        GROUP BY DATE(created_at)
        ORDER BY date DESC
    ";
    $activityStmt = $pdo->prepare($activityQuery);
    $activityStmt->execute();
    $activityTrends = $activityStmt->fetchAll(PDO::FETCH_ASSOC);
    
    $stats = [
        'overview' => [
            'totalUsers' => $totalUsers,
            'totalPoints' => (int)$distribution['total_points'],
            'avgPoints' => round((float)$distribution['avg_points'], 2),
            'maxPoints' => (int)$distribution['max_points'],
            'minPoints' => (int)$distribution['min_points'],
            'totalQuestions' => (int)$distribution['total_questions'],
            'totalAnswers' => (int)$distribution['total_answers'],
            'totalBestAnswers' => (int)$distribution['total_best_answers'],
            'totalUpvotes' => (int)$distribution['total_upvotes']
        ],
        'topPerformer' => [
            'name' => $topPerformer['name'],
            'points' => (int)$topPerformer['points'],
            'level' => (int)$topPerformer['level'],
            'questionsCount' => (int)$topPerformer['questions_count'],
            'answersCount' => (int)$topPerformer['answers_count'],
            'bestAnswersCount' => (int)$topPerformer['best_answers_count'],
            'upvotesReceived' => (int)$topPerformer['upvotes_received']
        ],
        'badgeDistribution' => $badgeDistribution,
        'levelDistribution' => $levelDistribution,
        'activityTrends' => $activityTrends,
        'filters' => [
            'timeFilter' => $timeFilter,
            'category' => $category
        ]
    ];
    
    echo json_encode([
        'success' => true,
        'stats' => $stats
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
