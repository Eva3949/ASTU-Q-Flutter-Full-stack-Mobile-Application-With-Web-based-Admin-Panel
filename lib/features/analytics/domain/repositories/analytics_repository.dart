import '../../../../core/types/either.dart';

import '../entities/analytics_data.dart';
import '../../../../core/errors/failures.dart';

/// Analytics Repository Interface
/// Defines the contract for analytics data operations
abstract class AnalyticsRepository {
  /// Get analytics overview for a date range
  Future<Either<Failure, AnalyticsOverview>> getAnalyticsOverview({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get daily activity data for a date range
  Future<Either<Failure, List<DailyActivityData>>> getDailyActivity({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get subject distribution data for a date range
  Future<Either<Failure, List<SubjectDistributionData>>>
  getSubjectDistribution({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get user growth data for a date range
  Future<Either<Failure, List<UserGrowthData>>> getUserGrowth({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get response time analytics for a date range
  Future<Either<Failure, List<ResponseTimeData>>> getResponseTimeAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get top users for a date range
  Future<Either<Failure, List<TopUserData>>> getTopUsers({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
  });
}
