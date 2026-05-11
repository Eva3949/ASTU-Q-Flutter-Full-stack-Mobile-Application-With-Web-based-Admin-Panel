import 'package:injectable/injectable.dart';

import '../entities/analytics_data.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/analytics_repository.dart';
import '../../../../core/types/either.dart';

/// Get Daily Activity Use Case
/// Retrieves daily activity analytics data for a given date range
@singleton
class GetDailyActivityUseCase {
  final AnalyticsRepository _repository;

  GetDailyActivityUseCase(this._repository);

  /// Execute the use case
  ///
  /// [params] contains the date range for the analytics data
  /// Returns [List<DailyActivityData>] on success or [Failure] on error
  Future<Either<Failure, List<DailyActivityData>>> call(
    GetDailyActivityParams params,
  ) async {
    return await _repository.getDailyActivity(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for Get Daily Activity Use Case
class GetDailyActivityParams {
  final DateTime startDate;
  final DateTime endDate;

  GetDailyActivityParams({required this.startDate, required this.endDate});

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}
