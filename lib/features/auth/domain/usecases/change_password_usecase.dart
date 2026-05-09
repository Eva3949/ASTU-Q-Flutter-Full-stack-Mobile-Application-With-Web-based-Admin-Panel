import '../../../../core/types/either.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

/// Change password use case
class ChangePasswordUseCase {
  final AuthRepository _repository;

  ChangePasswordUseCase(this._repository);

  /// Execute password change
  Future<Either<Failure, void>> call(ChangePasswordParams params) async {
    return await _repository.changePassword(
      params.currentPassword,
      params.newPassword,
      params.confirmPassword,
    );
  }
}

/// Change Password Parameters
class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    };
  }
}
