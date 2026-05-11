import '../../domain/entities/leaderboard_user.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/either.dart';


class MockLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<Either<Failure, List<LeaderboardUser>>> getLeaderboard({
    required int page,
    required int limit,
    required String timeFilter,
    required String category,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate mock data
    final mockUsers = _generateMockUsers(page, limit);
    return Either.right(mockUsers);
  }

  @override
  Future<Either<Failure, int>> getUserRank({
    required int userId,
    required String timeFilter,
    required String category,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return mock rank (between 1 and 100)
    return Either.right(userId % 100 + 1);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLeaderboardStats({
    required String timeFilter,
    required String category,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Return mock stats
    final stats = {
      'overview': {
        'totalUsers': 1250,
        'totalPoints': 45678,
        'avgPoints': 36.5,
        'maxPoints': 1250,
        'minPoints': 0,
        'totalQuestions': 3420,
        'totalAnswers': 8920,
        'totalBestAnswers': 1250,
        'totalUpvotes': 15670
      },
      'topPerformer': {
        'name': 'John Doe',
        'points': 1250,
        'level': 25,
        'questionsCount': 85,
        'answersCount': 220,
        'bestAnswersCount': 45,
        'upvotesReceived': 380
      },
      'badgeDistribution': [
        {'badge': 'Diamond', 'count': 5},
        {'badge': 'Platinum', 'count': 15},
        {'badge': 'Gold', 'count': 50},
        {'badge': 'Silver', 'count': 120},
        {'badge': 'Bronze', 'count': 300},
        {'badge': 'Newcomer', 'count': 760}
      ],
      'levelDistribution': [
        {'level_range': '50+', 'count': 10},
        {'level_range': '40-49', 'count': 25},
        {'level_range': '30-39', 'count': 45},
        {'level_range': '20-29', 'count': 120},
        {'level_range': '10-19', 'count': 280},
        {'level_range': '1-9', 'count': 770}
      ],
      'activityTrends': [
        {'date': '2024-01-07', 'new_users': 12},
        {'date': '2024-01-06', 'new_users': 8},
        {'date': '2024-01-05', 'new_users': 15},
        {'date': '2024-01-04', 'new_users': 10},
        {'date': '2024-01-03', 'new_users': 18},
        {'date': '2024-01-02', 'new_users': 14},
        {'date': '2024-01-01', 'new_users': 20}
      ]
    };
    
    return Either.right(stats);
  }

  List<LeaderboardUser> _generateMockUsers(int page, int limit) {
    final startIndex = (page - 1) * limit;
    final users = <LeaderboardUser>[];
    
    final names = [
      'Alice Johnson', 'Bob Smith', 'Charlie Brown', 'Diana Prince', 
      'Edward Norton', 'Fiona Apple', 'George Lucas', 'Helen Hunt',
      'Ivan Drago', 'Julia Roberts', 'Kevin Hart', 'Linda Hamilton',
      'Mark Zuckerberg', 'Natalie Portman', 'Oscar Wilde', 'Penelope Cruz',
      'Quentin Tarantino', 'Rachel Green', 'Steven Spielberg', 'Tina Turner'
    ];
    
    final badges = ['Diamond', 'Platinum', 'Gold', 'Silver', 'Bronze', 'Newcomer'];
    
    for (int i = 0; i < limit; i++) {
      final index = startIndex + i;
      if (index >= names.length) break;
      
      final user = LeaderboardUser(
        id: index + 1,
        name: names[index % names.length],
        points: 1000 - (index * 20),
        level: 20 - (index ~/ 2),
        rank: index + 1,
        badges: [badges[index % badges.length]],
        questions: 50 - (index * 2),
        answers: 100 - (index * 3),
        lastActiveAt: DateTime.now().subtract(Duration(days: index)),
      );
      
      users.add(user);
    }
    
    return users;
  }
}
