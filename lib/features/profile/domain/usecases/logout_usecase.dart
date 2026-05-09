import '../../../../core/types/either.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Logout Use Case
/// Logs out the current user and clears session data
@singleton
class LogoutUseCase {
  final ProfileRepository _repository;

  LogoutUseCase(this._repository);

  /// Execute the use case
  /// Returns [Either] [Failure] or [bool] indicating success
  Future<Either<Failure, bool>> call() async {
    return await _repository.logout();
  }
}
