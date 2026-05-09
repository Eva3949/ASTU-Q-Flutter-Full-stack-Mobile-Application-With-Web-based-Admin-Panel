import '../../../../core/types/either.dart';
import '../entities/user.dart';
import '../../../../core/errors/failures.dart';

/// Authentication repository interface
/// Defines the contract for authentication data operations
abstract class AuthRepository {
  /// User login with email and password
  Future<Either<Failure, User>> login(
    String email,
    String password,
    bool rememberMe,
  );

  /// User registration
  Future<Either<Failure, User>> register(
    String name,
    String email,
    String password,
    String confirmPassword, {
    String? username,
    String? phone,
  });

  /// User logout
  Future<Either<Failure, void>> logout();

  /// Get current authenticated user
  Future<Either<Failure, User>> getCurrentUser();

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
  });

  /// Change user password
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );

  /// Refresh authentication token
  Future<Either<Failure, String>> refreshToken();

  /// Check if user is authenticated
  bool isAuthenticated();

  /// Save authentication token
  Future<void> saveToken(String token);

  /// Get authentication token
  Future<String?> getToken();

  /// Clear authentication data
  Future<void> clearAuthData();
}
