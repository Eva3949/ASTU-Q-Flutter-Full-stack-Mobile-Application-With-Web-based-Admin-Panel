import '../../../../core/types/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

/// Get current user use case
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// Execute get current user
  Future<Either<Failure, User>> call() async {
    return await _repository.getCurrentUser();
  }
}
