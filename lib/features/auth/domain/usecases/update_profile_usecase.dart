import '../../../../core/types/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

/// Update profile use case
class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  /// Execute profile update
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    return await _repository.updateProfile(
      name: params.name,
      email: params.email,
      phone: params.phone,
      bio: params.bio,
    );
  }
}

/// Update Profile Parameters
class UpdateProfileParams {
  final String? name;
  final String? email;
  final String? phone;
  final String? bio;

  UpdateProfileParams({
    this.name,
    this.email,
    this.phone,
    this.bio,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
    };
  }

  bool get hasChanges => name != null || email != null || phone != null || bio != null;
}
