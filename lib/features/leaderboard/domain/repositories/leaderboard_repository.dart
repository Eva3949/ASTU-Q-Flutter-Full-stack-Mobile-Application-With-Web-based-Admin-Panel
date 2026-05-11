import '../entities/leaderboard_user.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/either.dart';

/// Leaderboard Repository Interface
/// Abstract contract for leaderboard data operations
abstract class LeaderboardRepository {
  /// Get leaderboard users with pagination and filtering
  ///
  /// [page] - Page number for pagination (1-based)
  /// [limit] - Number of users per page
  /// [timeFilter] - Time period filter ('all', 'year', 'month', 'week', 'today')
  /// [category] - Category filter ('points', 'questions', 'answers', 'best_answers', 'upvotes')
  ///
  /// Returns [Right] with list of [LeaderboardUser] on success
  /// Returns [Left] with [Failure] on error
  Future<Either<Failure, List<LeaderboardUser>>> getLeaderboard({
    required int page,
    required int limit,
    required String timeFilter,
    required String category,
  });

  /// Get current user's rank in the leaderboard
  ///
  /// [userId] - ID of the user to get rank for
  /// [timeFilter] - Time period filter
  /// [category] - Category filter
  ///
  /// Returns [Right] with user rank on success
  /// Returns [Left] with [Failure] on error
  Future<Either<Failure, int>> getUserRank({
    required int userId,
    required String timeFilter,
    required String category,
  });

  /// Get leaderboard statistics
  ///
  /// [timeFilter] - Time period filter
  /// [category] - Category filter
  ///
  /// Returns [Right] with statistics map on success
  /// Returns [Left] with [Failure] on error
  Future<Either<Failure, Map<String, dynamic>>> getLeaderboardStats({
    required String timeFilter,
    required String category,
  });
}
