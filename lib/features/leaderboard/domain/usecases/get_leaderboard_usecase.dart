import '../entities/leaderboard_user.dart';
import '../repositories/leaderboard_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/either.dart';

/// Get Leaderboard Use Case
/// Retrieves leaderboard data with pagination and filtering
class GetLeaderboardUseCase {
  final LeaderboardRepository _repository;

  GetLeaderboardUseCase(this._repository);

  /// Execute the use case
  /// Returns [Either.right] with list of leaderboard users on success
  /// Returns [Either.left] with [Failure] on error
  Future<Either<Failure, List<LeaderboardUser>>> call(
    GetLeaderboardParams params,
  ) async {
    return _repository.getLeaderboard(
      page: params.page,
      limit: params.limit,
      timeFilter: params.timeFilter,
      category: params.category,
    );
  }
}

/// Parameters for getting leaderboard data
class GetLeaderboardParams {
  final int page;
  final int limit;
  final String timeFilter;
  final String category;

  const GetLeaderboardParams({
    required this.page,
    required this.limit,
    required this.timeFilter,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'time_filter': timeFilter,
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetLeaderboardParams &&
        other.page == page &&
        other.limit == limit &&
        other.timeFilter == timeFilter &&
        other.category == category;
  }

  @override
  int get hashCode {
    return Object.hash(page, limit, timeFilter, category);
  }
}
