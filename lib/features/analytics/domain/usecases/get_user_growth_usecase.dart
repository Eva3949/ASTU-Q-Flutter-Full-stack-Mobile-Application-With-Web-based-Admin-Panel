import 'package:injectable/injectable.dart';

import '../entities/analytics_data.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/analytics_repository.dart';
import '../../../../core/types/either.dart';

/// Get User Growth Use Case
/// Retrieves user growth analytics data for a given date range
@singleton
class GetUserGrowthUseCase {
  final AnalyticsRepository _repository;

  GetUserGrowthUseCase(this._repository);

  /// Execute the use case
  /// 
  /// [params] contains the date range for the analytics data
  /// Returns [List<UserGrowthData>] on success or [Failure] on error
  Future<Either<Failure, List<UserGrowthData>>> call(GetUserGrowthParams params) async {
    return await _repository.getUserGrowth(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for Get User Growth Use Case
class GetUserGrowthParams {
  final DateTime startDate;
  final DateTime endDate;

  GetUserGrowthParams({
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
