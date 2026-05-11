import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/types/either.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';

@LazySingleton(as: AnalyticsRepository)
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final DioClient _dioClient;
  final Logger _logger;
  static const String _baseUrl = 'https://evadevstudio.com/sami';

  AnalyticsRepositoryImpl(this._dioClient, this._logger);

  @override
  Future<Either<Failure, AnalyticsOverview>> getAnalyticsOverview({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.get('$_baseUrl/get_question_stats.php');

      if (response.statusCode == 200) {
        // Map the flat stats from PHP to the AnalyticsOverview entity
        final data = response.data['data'];
        return Either.right(
          AnalyticsOverview(
            totalQuestions: data['total_questions'] ?? 0,
            totalAnswers: data['total_answers'] ?? 0,
            totalUsers: 0, // Not provided by get_question_stats.php yet
            averageResponseTime: 0.0,
            todayActivity: data['pending_questions'] ?? 0,
          ),
        );
      } else {
        return Either.left(ServerFailure('Failed to fetch analytics overview'));
      }
    } catch (e) {
      _logger.e('Error fetching analytics overview', error: e);
      return Either.left(ServerFailure('Failed to fetch analytics overview'));
    }
  }

  @override
  Future<Either<Failure, List<DailyActivityData>>> getDailyActivity({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Backend doesn't have daily activity script yet, returning empty list
    return Either.right([]);
  }

  @override
  Future<Either<Failure, List<SubjectDistributionData>>>
  getSubjectDistribution({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/get_popular_subjects.php',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final distribution = data
            .map(
              (item) => SubjectDistributionData(
                subject: item['subject'],
                count: item['question_count'],
              ),
            )
            .toList();
        return Either.right(distribution);
      } else {
        return Either.left(
          ServerFailure('Failed to fetch subject distribution'),
        );
      }
    } catch (e) {
      _logger.e('Error fetching subject distribution', error: e);
      return Either.left(ServerFailure('Failed to fetch subject distribution'));
    }
  }

  @override
  Future<Either<Failure, List<UserGrowthData>>> getUserGrowth({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return Either.right([]);
  }

  @override
  Future<Either<Failure, List<ResponseTimeData>>> getResponseTimeAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return Either.right([]);
  }

  @override
  Future<Either<Failure, List<TopUserData>>> getTopUsers({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
  }) async {
    return Either.right([]);
  }
}
