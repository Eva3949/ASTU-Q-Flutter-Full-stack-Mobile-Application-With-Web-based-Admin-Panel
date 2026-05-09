import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';

/// Authentication Provider
/// Manages authentication state, user session, and auth-related operations
@singleton
class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final Logger _logger;

  // State variables
  AuthState _authState = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  // Form states
  LoginState _loginState = LoginState.initial;
  RegisterState _registerState = RegisterState.initial;
  ProfileState _profileState = ProfileState.initial;
  PasswordState _passwordState = PasswordState.initial;

  // Getters
  AuthState get authState => _authState;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  LoginState get loginState => _loginState;
  RegisterState get registerState => _registerState;
  ProfileState get profileState => _profileState;
  PasswordState get passwordState => _passwordState;

  // Computed properties
  bool get isLoggedIn => _currentUser != null && _isAuthenticated;
  String get userDisplayName => _currentUser?.name ?? 'Guest';
  String get userEmail => _currentUser?.email ?? '';
  String? get userAvatar => _currentUser?.avatarUrl;
  bool get isEmailVerified => _currentUser?.emailVerifiedAt != null;
  DateTime? get lastLoginAt => _currentUser?.lastLoginAt;

  AuthProvider(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._updateProfileUseCase,
    this._changePasswordUseCase,
    this._logger,
  ) {
    _initializeAuth();
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      _setLoading(true);
      _setAuthState(AuthState.loading);

      // Check if user is already logged in
      final result = await _getCurrentUserUseCase();

      result.fold(
        (failure) {
          _setAuthState(AuthState.unauthenticated);
          _isAuthenticated = false;
          _logger.d('User not authenticated: ${failure.message}');
        },
        (user) {
          _setCurrentUser(user);
          _setAuthState(AuthState.authenticated);
          _isAuthenticated = true;
          _logger.d('User authenticated: ${user.email}');
        },
      );
    } catch (e) {
      _setAuthState(AuthState.unauthenticated);
      _isAuthenticated = false;
      _setError('Failed to initialize authentication');
      _logger.e('Error initializing auth', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// User login
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _setLoginState(LoginState.loading);
      _clearError();
      _setLoading(true);

      _logger.d('Attempting login for: $email');

      final result = await _loginUseCase(
        LoginParams(email: email, password: password, rememberMe: rememberMe),
      );

      return result.fold(
        (failure) {
          _setLoginState(LoginState.error);
          _setError(_getErrorMessage(failure));
          _logger.e('Login failed: ${failure.message}');
          return false;
        },
        (user) {
          _setCurrentUser(user);
          _setLoginState(LoginState.success);
          _setAuthState(AuthState.authenticated);
          _isAuthenticated = true;
          _logger.d('Login successful: ${user.email}');
          return true;
        },
      );
    } catch (e) {
      _setLoginState(LoginState.error);
      _setError('An unexpected error occurred during login');
      _logger.e('Error during login', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// User registration
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    try {
      _setRegisterState(RegisterState.loading);
      _clearError();
      _setLoading(true);

      _logger.d('Attempting registration for: $email');

      final result = await _registerUseCase(
        RegisterParams(
          name: name,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          phone: phone,
        ),
      );

      return result.fold(
        (failure) {
          _setRegisterState(RegisterState.error);
          _setError(_getErrorMessage(failure));
          _logger.e('Registration failed: ${failure.message}');
          return false;
        },
        (user) {
          _setCurrentUser(user);
          _setRegisterState(RegisterState.success);
          _setAuthState(AuthState.authenticated);
          _isAuthenticated = true;
          _logger.d('Registration successful: ${user.email}');
          return true;
        },
      );
    } catch (e) {
      _setRegisterState(RegisterState.error);
      _setError('An unexpected error occurred during registration');
      _logger.e('Error during registration', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// User logout
  Future<bool> logout() async {
    try {
      _setLoading(true);
      _clearError();

      _logger.d('Attempting logout');

      final result = await _logoutUseCase();

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Logout failed: ${failure.message}');
          return false;
        },
        (_) {
          _clearUserSession();
          _setAuthState(AuthState.unauthenticated);
          _isAuthenticated = false;
          _logger.d('Logout successful');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred during logout');
      _logger.e('Error during logout', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
  }) async {
    try {
      _setProfileState(ProfileState.loading);
      _clearError();
      _setLoading(true);

      _logger.d('Updating profile for user: ${_currentUser?.email}');

      final result = await _updateProfileUseCase(
        UpdateProfileParams(name: name, email: email, phone: phone, bio: bio),
      );

      return result.fold(
        (failure) {
          _setProfileState(ProfileState.error);
          _setError(_getErrorMessage(failure));
          _logger.e('Profile update failed: ${failure.message}');
          return false;
        },
        (user) {
          _setCurrentUser(user);
          _setProfileState(ProfileState.success);
          _logger.d('Profile updated successfully');
          return true;
        },
      );
    } catch (e) {
      _setProfileState(ProfileState.error);
      _setError('An unexpected error occurred during profile update');
      _logger.e('Error updating profile', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _setPasswordState(PasswordState.loading);
      _clearError();
      _setLoading(true);

      _logger.d('Changing password for user: ${_currentUser?.email}');

      final result = await _changePasswordUseCase(
        ChangePasswordParams(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );

      return result.fold(
        (failure) {
          _setPasswordState(PasswordState.error);
          _setError(_getErrorMessage(failure));
          _logger.e('Password change failed: ${failure.message}');
          return false;
        },
        (_) {
          _setPasswordState(PasswordState.success);
          _logger.d('Password changed successfully');
          return true;
        },
      );
    } catch (e) {
      _setPasswordState(PasswordState.error);
      _setError('An unexpected error occurred during password change');
      _logger.e('Error changing password', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current user data
  Future<void> refreshUserData() async {
    try {
      _clearError();

      final result = await _getCurrentUserUseCase();

      result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to refresh user data: ${failure.message}');
        },
        (user) {
          _setCurrentUser(user);
          _logger.d('User data refreshed successfully');
        },
      );
    } catch (e) {
      _setError('Failed to refresh user data');
      _logger.e('Error refreshing user data', error: e);
    }
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.roles?.contains(role) ?? false;
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return _currentUser?.permissions?.contains(permission) ?? false;
  }

  /// Get user initials for avatar
  String getUserInitials() {
    if (_currentUser?.name != null) {
      final nameParts = _currentUser!.name.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        return nameParts[0][0].toUpperCase();
      }
    }
    return _currentUser?.email.substring(0, 2).toUpperCase() ?? 'U';
  }

  /// Reset login state
  void resetLoginState() {
    _loginState = LoginState.initial;
    _clearError();
    notifyListeners();
  }

  /// Reset register state
  void resetRegisterState() {
    _registerState = RegisterState.initial;
    _clearError();
    notifyListeners();
  }

  /// Reset profile state
  void resetProfileState() {
    _profileState = ProfileState.initial;
    _clearError();
    notifyListeners();
  }

  /// Reset password state
  void resetPasswordState() {
    _passwordState = PasswordState.initial;
    _clearError();
    notifyListeners();
  }

  /// Reset all states
  void resetAllStates() {
    resetLoginState();
    resetRegisterState();
    resetProfileState();
    resetPasswordState();
  }

  /// Set current user
  void _setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Clear user session
  void _clearUserSession() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Set auth state
  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  /// Set login state
  void _setLoginState(LoginState state) {
    _loginState = state;
    notifyListeners();
  }

  /// Set register state
  void _setRegisterState(RegisterState state) {
    _registerState = state;
    notifyListeners();
  }

  /// Set profile state
  void _setProfileState(ProfileState state) {
    _profileState = state;
    notifyListeners();
  }

  /// Set password state
  void _setPasswordState(PasswordState state) {
    _passwordState = state;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure _:
        return 'No internet connection. Please check your network and try again.';
      case ServerFailure _:
        return 'Server error. Please try again later.';
      case ValidationFailure _:
        return failure.message;
      case UnauthorizedFailure _:
        return 'Authentication failed. Please login again.';
      case TimeoutFailure _:
        return 'Request timeout. Please try again.';
      case NotFoundFailure _:
        return 'The requested resource was not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Authentication states
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Login states
enum LoginState { initial, loading, success, error }

/// Register states
enum RegisterState { initial, loading, success, error }

/// Profile states
enum ProfileState { initial, loading, success, error }

/// Password states
enum PasswordState { initial, loading, success, error }
