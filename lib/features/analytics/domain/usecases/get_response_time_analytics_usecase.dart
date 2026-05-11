import 'package:injectable/injectable.dart';

import '../entities/analytics_data.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/analytics_repository.dart';
import '../../../../core/types/either.dart';

/// Get Response Time Analytics Use Case
/// Retrieves response time analytics data for a given date range
@singleton
class GetResponseTimeAnalyticsUseCase {
  final AnalyticsRepository _repository;

  GetResponseTimeAnalyticsUseCase(this._repository);

  /// Execute the use case
  /// 
  /// [params] contains the date range for the analytics data
  /// Returns [List<ResponseTimeData>] on success or [Failure] on error
  Future<Either<Failure, List<ResponseTimeData>>> call(GetResponseTimeAnalyticsParams params) async {
    return await _repository.getResponseTimeAnalytics(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for Get Response Time Analytics Use Case
class GetResponseTimeAnalyticsParams {
  final DateTime startDate;
  final DateTime endDate;

  GetResponseTimeAnalyticsParams({
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}
