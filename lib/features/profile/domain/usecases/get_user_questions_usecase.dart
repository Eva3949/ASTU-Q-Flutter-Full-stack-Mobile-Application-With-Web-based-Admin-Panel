import '../../../../core/types/either.dart';
import 'package:injectable/injectable.dart';

import '../entities/question.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Get User Questions Use Case Parameters
class GetUserQuestionsParams {
  final int userId;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  GetUserQuestionsParams({
    required this.userId,
    required this.page,
    required this.limit,
    this.sortBy,
    this.sortOrder,
  });
}

/// Get User Questions Use Case
/// Retrieves questions posted by a specific user with pagination
@singleton
class GetUserQuestionsUseCase {
  final ProfileRepository _repository;

  GetUserQuestionsUseCase(this._repository);

  /// Execute the use case
  /// Returns [Either] [Failure] or [List] of [Question]
  Future<Either<Failure, List<Question>>> call(GetUserQuestionsParams params) async {
    return await _repository.getUserQuestions(
      userId: params.userId,
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}
