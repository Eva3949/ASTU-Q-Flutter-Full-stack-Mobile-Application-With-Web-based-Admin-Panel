import '../../../../core/types/either.dart';

import '../entities/user_profile.dart';
import '../entities/question.dart';
import '../entities/answer.dart';
import '../../../../core/errors/failures.dart';

/// Profile Repository Interface
/// Abstract contract for profile data operations
abstract class ProfileRepository {
  /// Get the user's profile
  Future<Either<Failure, UserProfile>> getUserProfile({int? userId});

  /// Get questions posted by a user
  Future<Either<Failure, List<Question>>> getUserQuestions({
    required int userId,
    required int page,
    required int limit,
    String? sortBy,
    String? sortOrder,
  });

  /// Get answers posted by a user
  Future<Either<Failure, List<Answer>>> getUserAnswers({
    required int userId,
    required int page,
    required int limit,
    String? sortBy,
    String? sortOrder,
  });

  /// Logout the current user
  Future<Either<Failure, bool>> logout();
}
