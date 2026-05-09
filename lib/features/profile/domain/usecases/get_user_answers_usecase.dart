import '../../../../core/types/either.dart';
import 'package:injectable/injectable.dart';

import '../entities/answer.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Get User Answers Use Case Parameters
class GetUserAnswersParams {
  final int userId;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  GetUserAnswersParams({
    required this.userId,
    required this.page,
    required this.limit,
    this.sortBy,
    this.sortOrder,
  });
}

/// Get User Answers Use Case
/// Retrieves answers posted by a specific user with pagination
@singleton
class GetUserAnswersUseCase {
  final ProfileRepository _repository;

  GetUserAnswersUseCase(this._repository);

  /// Execute the use case
  /// Returns [Either] [Failure] or [List] of [Answer]
  Future<Either<Failure, List<Answer>>> call(
    GetUserAnswersParams params,
  ) async {
    return await _repository.getUserAnswers(
      userId: params.userId,
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}
