import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/login_usecase.dart';
import '../../../auth/domain/usecases/register_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';

/// Authentication Provider
/// Manages authentication state and user session
@singleton
class AuthenticationProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final Logger _logger;

  AuthenticationProvider(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._logger,
  ) {
    // Defer loading to avoid calling notifyListeners() during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUser();
    });
  }

  // State variables
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isInitialLoadComplete = false;

  /// Safe notify listeners to avoid "setState() called during build" errors
  void _safeNotify() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;
  bool get isAuthenticated => _user != null;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

  /// Load current user from cache
  Future<void> _loadCurrentUser() async {
    try {
      _setLoading(true);
      final result = await _getCurrentUserUseCase();
      result.fold(
        (failure) {
          _logger.d('No cached user found: ${failure.message}');
        },
        (user) {
          _user = user;
          _logger.d('Current user loaded: ${user.email}');
        },
      );
    } catch (e) {
      _logger.e('Error loading current user', error: e);
    } finally {
      _setLoading(false);
      _isInitialLoadComplete = true;
      _safeNotify();
    }
  }

  /// Login user with email and password
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _clearError();
    _setLoading(true);
    _rememberMe = rememberMe;

    try {
      _logger.d('Attempting login for email: $email');

      final result = await _loginUseCase(
        LoginParams(email: email, password: password, rememberMe: rememberMe),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Login failed: ${failure.message}');
          return false;
        },
        (user) {
          _user = user;
          _logger.d('Login successful for user: ${user.email}');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Login error', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    String? username,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      _logger.d('Attempting registration for email: $email');

      final result = await _registerUseCase(
        RegisterParams(
          name: name,
          username: username,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          phone: phone,
        ),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Registration failed: ${failure.message}');
          return false;
        },
        (user) {
          _user = user;
          _logger.d('Registration successful for user: ${user.email}');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred during registration');
      _logger.e('Registration error', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _logger.d('Logging out user: ${_user?.email}');

      await _logoutUseCase();

      _user = null;
      _rememberMe = false;
      _logger.d('Logout successful');
    } catch (e) {
      _logger.e('Logout error', error: e);
      // Even if logout fails, clear local state
      _user = null;
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    _safeNotify();
  }

  /// Toggle remember me
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    _safeNotify();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotify();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _safeNotify();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  /// Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'No internet connection. Please check your network and try again.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case ValidationFailure:
        return failure.message;
      case UnauthorizedFailure:
        return 'Invalid email or password. Please try again.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    if (_user != null) {
      await _loadCurrentUser();
    }
  }

  /// Check if user is authenticated
  bool isAuthenticatedUser() {
    return _user != null;
  }

  /// Get user display name
  String? get userDisplayName {
    if (_user == null) return null;
    return _user!.name;
  }

  /// Get user initials
  String? get userInitials {
    if (_user == null) return null;
    final nameParts = _user!.name.split(' ');
    String initials = '';
    for (final part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0];
      }
    }
    return initials.isNotEmpty ? initials.toUpperCase() : null;
  }
}
