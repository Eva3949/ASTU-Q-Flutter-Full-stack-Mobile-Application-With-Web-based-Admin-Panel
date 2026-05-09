import '../../../../core/types/either.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

/// Logout use case
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  /// Execute user logout
  Future<Either<Failure, void>> call() async {
    return await _repository.logout();
  }
}
