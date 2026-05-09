import '../../../../core/types/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

/// Register use case
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  /// Execute user registration
  Future<Either<Failure, User>> call(RegisterParams params) async {
    return await _repository.register(
      params.name,
      params.email,
      params.password,
      params.confirmPassword,
      username: params.username,
      phone: params.phone,
    );
  }
}

/// Register Parameters
class RegisterParams {
  final String name;
  final String? username;
  final String email;
  final String password;
  final String confirmPassword;
  final String? phone;

  RegisterParams({
    required this.name,
    this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (username != null) 'username': username,
      'email': email,
      'password': password,
      'password_confirmation': confirmPassword,
      if (phone != null) 'phone': phone,
    };
  }
}
