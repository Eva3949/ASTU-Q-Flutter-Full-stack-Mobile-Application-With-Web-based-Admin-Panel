import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';

import 'secure_storage.dart';
import '../utils/logger.dart';

/// Authentication Manager
/// Handles authentication flow, auto-login, and session management
@singleton
class AuthManager {
  final SecureStorage _secureStorage;
  final Logger _logger;

  // Stream controllers for authentication state
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();
  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();
  final StreamController<Map<String, dynamic>?> _userController =
      StreamController<Map<String, dynamic>?>.broadcast();

  // Authentication state
  AuthState _currentState = AuthState.unauthenticated;
  String? _currentToken;
  Map<String, dynamic>? _currentUser;

  // Session management
  Timer? _sessionCheckTimer;
  static const Duration _sessionCheckInterval = Duration(minutes: 1);

  AuthManager(this._secureStorage, this._logger) {
    _initializeAuthManager();
  }

  /// Initialize authentication manager
  Future<void> _initializeAuthManager() async {
    try {
      _logger.d('Initializing AuthManager');

      // Check for existing session
      await _checkExistingSession();

      // Start session monitoring
      _startSessionMonitoring();

      _logger.d('AuthManager initialized successfully');
    } catch (e) {
      _logger.e('Error initializing AuthManager', error: e);
    }
  }

  /// Check for existing session (auto-login)
  Future<void> _checkExistingSession() async {
    try {
      _logger.d('Checking for existing session');

      // Check if session is valid
      final isValid = await _secureStorage.isSessionValid();

      if (isValid) {
        // Load existing session data
        final token = await _secureStorage.getToken();
        final userData = await _secureStorage.getUserData();

        if (token != null && userData != null) {
          _currentToken = token;
          _currentUser = userData;
          _currentState = AuthState.authenticated;

          _emitAuthState(_currentState);
          _emitToken(token);
          _emitUser(userData);

          _logger.d('Existing session loaded successfully');
        } else {
          _logger.d('Invalid session data, clearing session');
          await _clearSession();
        }
      } else {
        _logger.d('No valid session found');
        await _clearSession();
      }
    } catch (e) {
      _logger.e('Error checking existing session', error: e);
      await _clearSession();
    }
  }

  /// Login user and save session
  Future<AuthResult> login({
    required String token,
    required String? refreshToken,
    required Map<String, dynamic> userData,
    bool rememberMe = false,
  }) async {
    try {
      _logger.d('Starting login process');

      // Save authentication data
      final tokenSaved = await _secureStorage.saveToken(token);
      final userDataSaved = await _secureStorage.saveUserData(userData);
      final rememberMeSaved = await _secureStorage.saveRememberMe(rememberMe);

      if (refreshToken != null) {
        await _secureStorage.saveRefreshToken(refreshToken);
      }

      if (tokenSaved && userDataSaved && rememberMeSaved) {
        _currentToken = token;
        _currentUser = userData;
        _currentState = AuthState.authenticated;

        _emitAuthState(_currentState);
        _emitToken(token);
        _emitUser(userData);

        _logger.d('Login successful');
        return AuthResult.success();
      } else {
        _logger.e('Failed to save login data');
        await _clearSession();
        return AuthResult.failure('Failed to save login data');
      }
    } catch (e) {
      _logger.e('Error during login', error: e);
      await _clearSession();
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Logout user and clear session
  Future<AuthResult> logout({bool clearAllData = false}) async {
    try {
      _logger.d('Starting logout process');

      // Clear session data
      if (clearAllData) {
        await _secureStorage.clearAll();
      } else {
        await _secureStorage.clearAll();
      }

      _currentToken = null;
      _currentUser = null;
      _currentState = AuthState.unauthenticated;

      _emitAuthState(_currentState);
      _emitToken(null);
      _emitUser(null);

      _logger.d('Logout successful');
      return AuthResult.success();
    } catch (e) {
      _logger.e('Error during logout', error: e);
      return AuthResult.failure('Logout failed: ${e.toString()}');
    }
  }

  /// Refresh authentication token
  Future<AuthResult> refreshToken(
    String newToken, {
    String? newRefreshToken,
  }) async {
    try {
      _logger.d('Refreshing authentication token');

      // Save new token
      final tokenSaved = await _secureStorage.saveToken(newToken);

      if (newRefreshToken != null) {
        await _secureStorage.saveRefreshToken(newRefreshToken);
      }

      if (tokenSaved) {
        _currentToken = newToken;
        _emitToken(newToken);

        // Update last active time
        await _secureStorage.refreshSession();

        _logger.d('Token refreshed successfully');
        return AuthResult.success();
      } else {
        _logger.e('Failed to save new token');
        return AuthResult.failure('Failed to save new token');
      }
    } catch (e) {
      _logger.e('Error refreshing token', error: e);
      return AuthResult.failure('Token refresh failed: ${e.toString()}');
    }
  }

  /// Update user data
  Future<AuthResult> updateUserData(Map<String, dynamic> userData) async {
    try {
      _logger.d('Updating user data');

      final saved = await _secureStorage.saveUserData(userData);

      if (saved) {
        _currentUser = userData;
        _emitUser(userData);

        _logger.d('User data updated successfully');
        return AuthResult.success();
      } else {
        _logger.e('Failed to update user data');
        return AuthResult.failure('Failed to update user data');
      }
    } catch (e) {
      _logger.e('Error updating user data', error: e);
      return AuthResult.failure('User data update failed: ${e.toString()}');
    }
  }

  /// Clear session data
  Future<void> _clearSession() async {
    try {
      await _secureStorage.clearAll();

      _currentToken = null;
      _currentUser = null;
      _currentState = AuthState.unauthenticated;

      _emitAuthState(_currentState);
      _emitToken(null);
      _emitUser(null);

      _logger.d('Session cleared');
    } catch (e) {
      _logger.e('Error clearing session', error: e);
    }
  }

  /// Start session monitoring
  void _startSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(_sessionCheckInterval, (timer) {
      _checkSessionValidity();
    });
    _logger.d('Session monitoring started');
  }

  /// Stop session monitoring
  void _stopSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    _logger.d('Session monitoring stopped');
  }

  /// Check session validity
  Future<void> _checkSessionValidity() async {
    try {
      if (_currentState == AuthState.authenticated) {
        final isValid = await _secureStorage.isSessionValid();

        if (!isValid) {
          _logger.d('Session expired, logging out');
          await logout();
          _emitAuthState(AuthState.sessionExpired);
        }
      }
    } catch (e) {
      _logger.e('Error checking session validity', error: e);
    }
  }

  /// Refresh session (update last active time)
  Future<bool> refreshSession() async {
    try {
      if (_currentState == AuthState.authenticated) {
        final refreshed = await _secureStorage.refreshSession();

        if (refreshed) {
          _logger.d('Session refreshed successfully');
        } else {
          _logger.d('Session refresh failed, logging out');
          await logout();
        }

        return refreshed;
      }
      return false;
    } catch (e) {
      _logger.e('Error refreshing session', error: e);
      return false;
    }
  }

  /// Get current authentication state
  AuthState get currentState => _currentState;

  /// Get current token
  String? get currentToken => _currentToken;

  /// Get current user data
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentState == AuthState.authenticated;

  /// Check if user is guest (not authenticated)
  bool get isGuest => _currentState == AuthState.unauthenticated;

  /// Get authentication state stream
  Stream<AuthState> get authStateStream => _authStateController.stream;

  /// Get token stream
  Stream<String?> get tokenStream => _tokenController.stream;

  /// Get user data stream
  Stream<Map<String, dynamic>?> get userStream => _userController.stream;

  /// Get session information
  Future<SessionInfo> getSessionInfo() async {
    return await _secureStorage.getSessionInfo();
  }

  /// Check if session is about to expire
  Future<bool> isSessionAboutToExpire() async {
    try {
      final sessionInfo = await getSessionInfo();
      return sessionInfo.isAboutToExpire;
    } catch (e) {
      _logger.e('Error checking if session is about to expire', error: e);
      return false;
    }
  }

  /// Extend session (update timeout)
  Future<bool> extendSession(int additionalMinutes) async {
    try {
      final currentTimeout = await _secureStorage.getSessionTimeout();
      final newTimeout = currentTimeout + additionalMinutes;

      final saved = await _secureStorage.saveSessionTimeout(newTimeout);

      if (saved) {
        await refreshSession();
        _logger.d('Session extended to $newTimeout minutes');
      }

      return saved;
    } catch (e) {
      _logger.e('Error extending session', error: e);
      return false;
    }
  }

  /// Force session expiry (for testing or manual logout)
  Future<void> forceSessionExpiry() async {
    try {
      _logger.d('Forcing session expiry');
      await logout();
      _emitAuthState(AuthState.sessionExpired);
    } catch (e) {
      _logger.e('Error forcing session expiry', error: e);
    }
  }

  /// Emit authentication state
  void _emitAuthState(AuthState state) {
    if (!_authStateController.isClosed) {
      _authStateController.add(state);
    }
  }

  /// Emit token
  void _emitToken(String? token) {
    if (!_tokenController.isClosed) {
      _tokenController.add(token);
    }
  }

  /// Emit user data
  void _emitUser(Map<String, dynamic>? userData) {
    if (!_userController.isClosed) {
      _userController.add(userData);
    }
  }

  /// Dispose resources
  void dispose() {
    _stopSessionMonitoring();

    _authStateController.close();
    _tokenController.close();
    _userController.close();

    _logger.d('AuthManager disposed');
  }

  /// Validate token format and structure
  bool validateTokenFormat(String token) {
    try {
      // Basic JWT token validation (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      // Check if parts are not empty
      for (final part in parts) {
        if (part.isEmpty) {
          return false;
        }
      }

      // Check if payload is valid base64
      final payload = parts[1];
      final paddedPayload = _padBase64(payload);

      try {
        final decoded = String.fromCharCodes(base64.decode(paddedPayload));
        final payloadMap = Map<String, dynamic>.from(jsonDecode(decoded));

        // Check for required claims
        if (!payloadMap.containsKey('exp') || !payloadMap.containsKey('iat')) {
          return false;
        }

        // Check if token is expired
        final exp = payloadMap['exp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        if (exp <= now) {
          return false;
        }

        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Pad base64 string if needed
  String _padBase64(String base64) {
    while (base64.length % 4 != 0) {
      base64 += '=';
    }
    return base64;
  }

  /// Get token expiry time
  DateTime? getTokenExpiryTime(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final paddedPayload = _padBase64(payload);

      final decoded = String.fromCharCodes(base64.decode(paddedPayload));
      final payloadMap = Map<String, dynamic>.from(jsonDecode(decoded));

      final exp = payloadMap['exp'] as int;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }

  /// Get token issue time
  DateTime? getTokenIssueTime(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final paddedPayload = _padBase64(payload);

      final decoded = String.fromCharCodes(base64.decode(paddedPayload));
      final payloadMap = Map<String, dynamic>.from(jsonDecode(decoded));

      final iat = payloadMap['iat'] as int;
      return DateTime.fromMillisecondsSinceEpoch(iat * 1000);
    } catch (e) {
      return null;
    }
  }

  /// Get token user ID
  String? getTokenUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final paddedPayload = _padBase64(payload);

      final decoded = String.fromCharCodes(base64.decode(paddedPayload));
      final payloadMap = Map<String, dynamic>.from(jsonDecode(decoded));

      // Try common user ID fields
      return payloadMap['sub'] as String? ??
          payloadMap['user_id'] as String? ??
          payloadMap['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check if token needs refresh
  bool tokenNeedsRefresh(
    String token, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    try {
      final expiryTime = getTokenExpiryTime(token);
      if (expiryTime == null) return true;

      final now = DateTime.now();
      final timeUntilExpiry = expiryTime.difference(now);

      return timeUntilExpiry <= threshold;
    } catch (e) {
      return true;
    }
  }
}

/// Authentication State
enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  sessionExpired,
  error,
}

/// Authentication Result
class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => const AuthResult._(success: true);

  factory AuthResult.failure(String message) =>
      AuthResult._(success: false, errorMessage: message);

  @override
  String toString() {
    return 'AuthResult(success: $success, errorMessage: $errorMessage)';
  }
}

/// Authentication Event
class AuthEvent {
  final AuthEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const AuthEvent({required this.type, required this.timestamp, this.data});

  factory AuthEvent.login({Map<String, dynamic>? userData}) => AuthEvent(
    type: AuthEventType.login,
    timestamp: DateTime.now(),
    data: userData,
  );

  factory AuthEvent.logout() =>
      AuthEvent(type: AuthEventType.logout, timestamp: DateTime.now());

  factory AuthEvent.sessionExpired() =>
      AuthEvent(type: AuthEventType.sessionExpired, timestamp: DateTime.now());

  factory AuthEvent.tokenRefreshed() =>
      AuthEvent(type: AuthEventType.tokenRefreshed, timestamp: DateTime.now());

  factory AuthEvent.error(String error) => AuthEvent(
    type: AuthEventType.error,
    timestamp: DateTime.now(),
    data: {'error': error},
  );

  @override
  String toString() {
    return 'AuthEvent(type: $type, timestamp: $timestamp, data: $data)';
  }
}

/// Authentication Event Type
enum AuthEventType { login, logout, sessionExpired, tokenRefreshed, error }

/// Authentication Listener
abstract class AuthListener {
  void onAuthStateChanged(AuthState state);
  void onTokenChanged(String? token);
  void onUserChanged(Map<String, dynamic>? userData);
  void onSessionExpired();
  void onError(String error);
}

/// Simple Authentication Listener Implementation
class SimpleAuthListener implements AuthListener {
  final void Function(AuthState)? onStateChanged;
  final void Function(String?)? onTokenChangedCallback;
  final void Function(Map<String, dynamic>?)? onUserChangedCallback;
  final void Function()? onSessionExpiredCallback;
  final void Function(String)? onErrorCallback;

  const SimpleAuthListener({
    this.onStateChanged,
    this.onTokenChangedCallback,
    this.onUserChangedCallback,
    this.onSessionExpiredCallback,
    this.onErrorCallback,
  });

  @override
  void onAuthStateChanged(AuthState state) {
    onStateChanged?.call(state);
  }

  @override
  void onTokenChanged(String? token) {
    onTokenChangedCallback?.call(token);
  }

  @override
  void onUserChanged(Map<String, dynamic>? userData) {
    onUserChangedCallback?.call(userData);
  }

  @override
  void onSessionExpired() {
    onSessionExpiredCallback?.call();
  }

  @override
  void onError(String error) {
    onErrorCallback?.call(error);
  }
}
