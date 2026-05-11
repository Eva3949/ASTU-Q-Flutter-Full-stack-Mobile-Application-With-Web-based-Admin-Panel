import 'package:injectable/injectable.dart';

import '../entities/analytics_data.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/analytics_repository.dart';
import '../../../../core/types/either.dart';

/// Get Subject Distribution Use Case
/// Retrieves subject distribution analytics data for a given date range
@singleton
class GetSubjectDistributionUseCase {
  final AnalyticsRepository _repository;

  GetSubjectDistributionUseCase(this._repository);

  /// Execute the use case
  ///
  /// [params] contains the date range for the analytics data
  /// Returns [List<SubjectDistributionData>] on success or [Failure] on error
  Future<Either<Failure, List<SubjectDistributionData>>> call(
    GetSubjectDistributionParams params,
  ) async {
    return await _repository.getSubjectDistribution(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for Get Subject Distribution Use Case
class GetSubjectDistributionParams {
  final DateTime startDate;
  final DateTime endDate;

  GetSubjectDistributionParams({
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
