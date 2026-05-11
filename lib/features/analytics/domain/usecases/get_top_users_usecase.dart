import 'package:injectable/injectable.dart';

import '../entities/analytics_data.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/analytics_repository.dart';
import '../../../../core/types/either.dart';

/// Get Top Users Use Case
/// Retrieves top users analytics data for a given date range
@singleton
class GetTopUsersUseCase {
  final AnalyticsRepository _repository;

  GetTopUsersUseCase(this._repository);

  /// Execute the use case
  ///
  /// [params] contains the date range and limit for the analytics data
  /// Returns [List<TopUserData>] on success or [Failure] on error
  Future<Either<Failure, List<TopUserData>>> call(
    GetTopUsersParams params,
  ) async {
    return await _repository.getTopUsers(
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
    );
  }
}

/// Parameters for Get Top Users Use Case
class GetTopUsersParams {
  final DateTime startDate;
  final DateTime endDate;
  final int limit;

  GetTopUsersParams({
    required this.startDate,
    required this.endDate,
    required this.limit,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'limit': limit,
    };
  }
}
