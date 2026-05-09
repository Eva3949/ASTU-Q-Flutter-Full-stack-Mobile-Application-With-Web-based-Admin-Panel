import '../../../../core/types/either.dart';
import 'package:injectable/injectable.dart';

import '../entities/user_profile.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Get User Profile Use Case
/// Retrieves the current user's profile information
@singleton
class GetUserProfileUseCase {
  final ProfileRepository _repository;

  GetUserProfileUseCase(this._repository);

  /// Execute the use case
  /// Returns [Either] [Failure] or [UserProfile]
  Future<Either<Failure, UserProfile>> call({int? userId}) async {
    return await _repository.getUserProfile(userId: userId);
  }
}
