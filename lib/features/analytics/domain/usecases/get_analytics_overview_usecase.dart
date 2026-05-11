import '../../../../core/types/either.dart';
import 'package:injectable/injectable.dart';

import '../entities/analytics_data.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/analytics_repository.dart';

/// Get Analytics Overview Use Case
/// Retrieves overview analytics data for a given date range
@singleton
class GetAnalyticsOverviewUseCase {
  final AnalyticsRepository _repository;

  GetAnalyticsOverviewUseCase(this._repository);

  /// Execute the use case
  ///
  /// [params] contains the date range for the analytics data
  /// Returns [AnalyticsOverview] on success or [Failure] on error
  Future<Either<Failure, AnalyticsOverview>> call(
    GetAnalyticsOverviewParams params,
  ) async {
    return await _repository.getAnalyticsOverview(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for Get Analytics Overview Use Case
class GetAnalyticsOverviewParams {
  final DateTime startDate;
  final DateTime endDate;

  GetAnalyticsOverviewParams({required this.startDate, required this.endDate});

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}
