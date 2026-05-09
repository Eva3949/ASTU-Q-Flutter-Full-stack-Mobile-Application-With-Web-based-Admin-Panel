import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/types/either.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;
  final Logger _logger;
  static const String _baseUrl = 'https://evadevstudio.com/sami';

  AuthRepositoryImpl(this._dioClient, this._secureStorage, this._logger);

  @override
  Future<Either<Failure, User>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    try {
      _logger.d('Logging in user: $email');
      final response = await _dioClient.post(
        '$_baseUrl/login.php',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final userData = data['user'] ?? data;

        _logger.d('Login data received: $userData');

        final user = User.fromJson(userData);

        if (data['token'] != null) {
          await saveToken(data['token']);
        }

        final saved = await _secureStorage.saveUserData(userData);
        if (!saved) {
          _logger.e('CRITICAL: Failed to save user data to storage!');
        }

        _logger.d('Login successful: ${user.email}');
        return Either.right(user);
      } else {
        return Either.left(
          ServerFailure(response.data['message'] ?? 'Login failed'),
        );
      }
    } catch (e) {
      _logger.e('Login error', error: e);
      return Either.left(ServerFailure('An error occurred during login'));
    }
  }

  @override
  Future<Either<Failure, User>> register(
    String name,
    String email,
    String password,
    String confirmPassword, {
    String? username,
    String? phone,
  }) async {
    try {
      _logger.d('Registering user: $email');
      final response = await _dioClient.post(
        '$_baseUrl/signup.php',
        data: {
          'name': name,
          if (username != null) 'username': username,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
          if (phone != null) 'phone': phone,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        final data = response.data['data'];
        final userData = data['user'] ?? data;

        _logger.d('Registration data received: $userData');

        final user = User.fromJson(userData);

        if (data['token'] != null) {
          await saveToken(data['token']);
        }

        final saved = await _secureStorage.saveUserData(userData);
        if (!saved) {
          _logger.e('CRITICAL: Failed to save user data to storage!');
        }

        _logger.d('Registration successful: ${user.email}');
        return Either.right(user);
      } else {
        return Either.left(
          ServerFailure(response.data['message'] ?? 'Registration failed'),
        );
      }
    } catch (e) {
      _logger.e('Registration error', error: e);
      return Either.left(
        ServerFailure('An error occurred during registration'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _secureStorage.clearAll();
      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure('Logout failed'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // First check if user data exists in local storage
      final userData = await _secureStorage.getUserData(quiet: true);
      if (userData != null) {
        _logger.d('Returning cached user from storage');
        final user = User.fromJson(userData);
        return Either.right(user);
      }

      // If no cached data, check if we have a user ID to fetch from server
      final userId = await _secureStorage.getUserId();
      if (userId == null) {
        return Either.left(UnauthorizedFailure('No user logged in'));
      }

      final response = await _dioClient.get(
        '$_baseUrl/get_user.php',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']);
        return Either.right(user);
      } else {
        return Either.left(ServerFailure('Failed to get user data'));
      }
    } catch (e) {
      return Either.left(ServerFailure('An error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
  }) async {
    return Either.left(ServerFailure('Not implemented'));
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    return Either.left(ServerFailure('Not implemented'));
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    return Either.left(ServerFailure('Not implemented'));
  }

  @override
  bool isAuthenticated() {
    // Check if user is authenticated by checking if token exists
    // This is a synchronous check, so we can't check async storage here
    // The actual check is done in getCurrentUser()
    return true; // Placeholder - actual check is async
  }

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.saveToken(token);
  }

  @override
  Future<String?> getToken() async {
    return await _secureStorage.getToken();
  }

  @override
  Future<void> clearAuthData() async {
    await _secureStorage.clearToken();
    await _secureStorage.clearUserData();
  }
}
