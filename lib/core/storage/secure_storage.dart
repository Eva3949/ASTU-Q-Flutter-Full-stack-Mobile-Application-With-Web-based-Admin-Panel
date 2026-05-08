import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

import '../utils/logger.dart';

/// Secure Storage Service
/// Handles secure storage of authentication tokens and user session data
@singleton
class SecureStorage {
  final Logger _logger;
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _userIdKey = 'user_id';
  static const String _loginTimeKey = 'login_time';
  static const String _rememberMeKey = 'remember_me';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _sessionTimeoutKey = 'session_timeout';
  static const String _lastActiveTimeKey = 'last_active_time';

  SecureStorage(this._logger);

  /// Save authentication token
  Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_tokenKey, token);

      if (success) {
        await _saveLoginTime();
        _logger.d('Token saved successfully');
      } else {
        _logger.e('Failed to save token');
      }

      return success;
    } catch (e) {
      _logger.e('Error saving token', error: e);
      return false;
    }
  }

  /// Save refresh token
  Future<bool> saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_refreshTokenKey, refreshToken);

      if (success) {
        _logger.d('Refresh token saved successfully');
      } else {
        _logger.e('Failed to save refresh token');
      }

      return success;
    } catch (e) {
      _logger.e('Error saving refresh token', error: e);
      return false;
    }
  }

  /// Get authentication token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null) {
        _logger.d('Token retrieved successfully');
      } else {
        _logger.d('No token found');
      }

      return token;
    } catch (e) {
      _logger.e('Error getting token', error: e);
      return null;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken != null) {
        _logger.d('Refresh token retrieved successfully');
      } else {
        _logger.d('No refresh token found');
      }

      return refreshToken;
    } catch (e) {
      _logger.e('Error getting refresh token', error: e);
      return null;
    }
  }

  /// Save user data
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      _logger.d('Attempting to save user data: $userData');
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(userData);
      final success = await prefs.setString(_userKey, userJson);

      if (success) {
        // Also save explicit User ID for easier access
        final userId =
            userData['id']?.toString() ?? userData['user_id']?.toString();
        if (userId != null) {
          await prefs.setString(_userIdKey, userId);
          _logger.d('Explicit User ID saved: $userId');
        }
        _logger.d('User data saved successfully to key: $_userKey');

        // Verification log
        final verify = prefs.getString(_userKey);
        _logger.d('Verification check - stored data: $verify');
      } else {
        _logger.e('Failed to save user data to SharedPreferences');
      }

      return success;
    } catch (e) {
      _logger.e('Error saving user data', error: e);
      return false;
    }
  }

  /// Save user ID explicitly
  Future<bool> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_userIdKey, userId);
      if (success) {
        _logger.d('User ID saved successfully: $userId');
      }
      return success;
    } catch (e) {
      _logger.e('Error saving user ID', error: e);
      return false;
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData({bool quiet = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _logger.d('User data retrieved successfully');
        return userData;
      } else {
        if (!quiet) _logger.d('No user data found');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting user data', error: e);
      return null;
    }
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(_userIdKey);

      if (userId != null) {
        _logger.d('User ID found in explicit key: $userId');
        return userId;
      }

      // Fallback to user_data if explicit ID not found
      _logger.d('No explicit User ID found, checking user_data...');
      final userData = await getUserData(quiet: true);
      if (userData != null) {
        userId = userData['id']?.toString() ?? userData['user_id']?.toString();
        _logger.d('User ID extracted from user_data: $userId');
      }

      return userId;
    } catch (e) {
      _logger.e('Error getting user ID', error: e);
      return null;
    }
  }

  /// Clear user ID
  Future<bool> clearUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_userIdKey);
    } catch (e) {
      _logger.e('Error clearing user ID', error: e);
      return false;
    }
  }

  /// Save remember me preference
  Future<bool> saveRememberMe(bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_rememberMeKey, rememberMe);

      if (success) {
        _logger.d('Remember me preference saved: $rememberMe');
      } else {
        _logger.e('Failed to save remember me preference');
      }

      return success;
    } catch (e) {
      _logger.e('Error saving remember me preference', error: e);
      return false;
    }
  }

  /// Get remember me preference
  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      _logger.d('Remember me preference: $rememberMe');
      return rememberMe;
    } catch (e) {
      _logger.e('Error getting remember me preference', error: e);
      return false;
    }
  }

  /// Save biometric enabled preference
  Future<bool> saveBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_biometricEnabledKey, enabled);

      if (success) {
        _logger.d('Biometric enabled preference saved: $enabled');
      } else {
        _logger.e('Failed to save biometric enabled preference');
      }

      return success;
    } catch (e) {
      _logger.e('Error saving biometric enabled preference', error: e);
      return false;
    }
  }

  /// Get biometric enabled preference
  Future<bool> getBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_biometricEnabledKey) ?? false;

      _logger.d('Biometric enabled preference: $enabled');
      return enabled;
    } catch (e) {
      _logger.e('Error getting biometric enabled preference', error: e);
      return false;
    }
  }

  /// Save session timeout duration (in minutes)
  Future<bool> saveSessionTimeout(int timeoutMinutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setInt(_sessionTimeoutKey, timeoutMinutes);

      if (success) {
        _logger.d('Session timeout saved: $timeoutMinutes minutes');
      } else {
        _logger.e('Failed to save session timeout');
      }

      return success;
    } catch (e) {
      _logger.e('Error saving session timeout', error: e);
      return false;
    }
  }

  /// Get session timeout duration (in minutes)
  Future<int> getSessionTimeout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeout =
          prefs.getInt(_sessionTimeoutKey) ?? 30; // Default 30 minutes

      _logger.d('Session timeout: $timeout minutes');
      return timeout;
    } catch (e) {
      _logger.e('Error getting session timeout', error: e);
      return 30; // Default fallback
    }
  }

  /// Save login time
  Future<bool> _saveLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTime = DateTime.now().millisecondsSinceEpoch;
      final success = await prefs.setInt(_loginTimeKey, loginTime);

      if (success) {
        await _updateLastActiveTime();
        _logger.d('Login time saved: $loginTime');
      } else {
        _logger.e('Failed to save login time');
      }

      return success;
    } catch (e) {
      _logger.e('Error saving login time', error: e);
      return false;
    }
  }

  /// Get login time
  Future<DateTime?> getLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTimeMillis = prefs.getInt(_loginTimeKey);

      if (loginTimeMillis != null && loginTimeMillis > 0) {
        final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimeMillis);
        _logger.d('Login time retrieved: $loginTime');
        return loginTime;
      } else {
        _logger.d('No login time found');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting login time', error: e);
      return null;
    }
  }

  /// Update last active time
  Future<bool> _updateLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveTime = DateTime.now().millisecondsSinceEpoch;
      final success = await prefs.setInt(_lastActiveTimeKey, lastActiveTime);

      if (success) {
        _logger.d('Last active time updated: $lastActiveTime');
      } else {
        _logger.e('Failed to update last active time');
      }

      return success;
    } catch (e) {
      _logger.e('Error updating last active time', error: e);
      return false;
    }
  }

  /// Get last active time
  Future<DateTime?> getLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveTimeMillis = prefs.getInt(_lastActiveTimeKey);

      if (lastActiveTimeMillis != null && lastActiveTimeMillis > 0) {
        final lastActiveTime = DateTime.fromMillisecondsSinceEpoch(
          lastActiveTimeMillis,
        );
        _logger.d('Last active time retrieved: $lastActiveTime');
        return lastActiveTime;
      } else {
        _logger.d('No last active time found');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting last active time', error: e);
      return null;
    }
  }

  /// Check if session is valid (not expired)
  Future<bool> isSessionValid() async {
    try {
      final token = await getToken();
      if (token == null) {
        _logger.d('No token found, session invalid');
        return false;
      }

      final rememberMe = await getRememberMe();
      if (rememberMe) {
        _logger.d('Remember me is enabled, session always valid');
        return true;
      }

      final sessionTimeout = await getSessionTimeout();
      final lastActiveTime = await getLastActiveTime();

      if (lastActiveTime == null) {
        _logger.d('No last active time found, session invalid');
        return false;
      }

      final now = DateTime.now();
      final sessionExpiryTime = lastActiveTime.add(
        Duration(minutes: sessionTimeout),
      );

      final isValid = now.isBefore(sessionExpiryTime);

      if (isValid) {
        await _updateLastActiveTime();
        _logger.d('Session is valid');
      } else {
        _logger.d('Session expired');
      }

      return isValid;
    } catch (e) {
      _logger.e('Error checking session validity', error: e);
      return false;
    }
  }

  /// Refresh session (update last active time)
  Future<bool> refreshSession() async {
    try {
      final isValid = await isSessionValid();
      if (isValid) {
        final success = await _updateLastActiveTime();
        if (success) {
          _logger.d('Session refreshed successfully');
        } else {
          _logger.e('Failed to refresh session');
        }
        return success;
      } else {
        _logger.d('Cannot refresh expired session');
        return false;
      }
    } catch (e) {
      _logger.e('Error refreshing session', error: e);
      return false;
    }
  }

  /// Clear all authentication data
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all auth-related keys
      final keysToClear = [
        _tokenKey,
        _refreshTokenKey,
        _userKey,
        _userIdKey,
        _loginTimeKey,
        _lastActiveTimeKey,
      ];

      bool success = true;
      for (final key in keysToClear) {
        final cleared = await prefs.remove(key);
        if (!cleared) {
          success = false;
          _logger.e('Failed to clear key: $key');
        }
      }

      if (success) {
        _logger.d('All authentication data cleared successfully');
      } else {
        _logger.e('Some authentication data failed to clear');
      }

      return success;
    } catch (e) {
      _logger.e('Error clearing authentication data', error: e);
      return false;
    }
  }

  /// Clear token only
  Future<bool> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_tokenKey);

      if (success) {
        _logger.d('Token cleared successfully');
      } else {
        _logger.e('Failed to clear token');
      }

      return success;
    } catch (e) {
      _logger.e('Error clearing token', error: e);
      return false;
    }
  }

  /// Clear refresh token only
  Future<bool> clearRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_refreshTokenKey);

      if (success) {
        _logger.d('Refresh token cleared successfully');
      } else {
        _logger.e('Failed to clear refresh token');
      }

      return success;
    } catch (e) {
      _logger.e('Error clearing refresh token', error: e);
      return false;
    }
  }

  /// Clear user data only
  Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_userKey);
      await prefs.remove(_userIdKey);

      if (success) {
        _logger.d('User data and ID cleared successfully');
      } else {
        _logger.e('Failed to clear user data');
      }

      return success;
    } catch (e) {
      _logger.e('Error clearing user data', error: e);
      return false;
    }
  }

  /// Check if user is logged in (has valid token)
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final isValid = await isSessionValid();

      final loggedIn = token != null && isValid;

      _logger.d('User logged in: $loggedIn');
      return loggedIn;
    } catch (e) {
      _logger.e('Error checking login status', error: e);
      return false;
    }
  }

  /// Get session information
  Future<SessionInfo> getSessionInfo() async {
    try {
      final token = await getToken();
      final refreshToken = await getRefreshToken();
      final userData = await getUserData();
      final loginTime = await getLoginTime();
      final lastActiveTime = await getLastActiveTime();
      final sessionTimeout = await getSessionTimeout();
      final rememberMe = await getRememberMe();
      final biometricEnabled = await getBiometricEnabled();
      final isValid = await isSessionValid();

      return SessionInfo(
        hasToken: token != null,
        hasRefreshToken: refreshToken != null,
        hasUserData: userData != null,
        loginTime: loginTime,
        lastActiveTime: lastActiveTime,
        sessionTimeoutMinutes: sessionTimeout,
        rememberMe: rememberMe,
        biometricEnabled: biometricEnabled,
        isValid: isValid,
      );
    } catch (e) {
      _logger.e('Error getting session info', error: e);
      return SessionInfo(
        hasToken: false,
        hasRefreshToken: false,
        hasUserData: false,
        sessionTimeoutMinutes: 30,
        rememberMe: false,
        biometricEnabled: false,
        isValid: false,
      );
    }
  }

  /// Export session data for backup
  Future<Map<String, dynamic>?> exportSessionData() async {
    try {
      final token = await getToken();
      final refreshToken = await getRefreshToken();
      final userData = await getUserData();
      final loginTime = await getLoginTime();
      final rememberMe = await getRememberMe();
      final biometricEnabled = await getBiometricEnabled();
      final sessionTimeout = await getSessionTimeout();

      if (token == null) {
        _logger.d('No session data to export');
        return null;
      }

      return {
        'token': token,
        'refreshToken': refreshToken,
        'userData': userData,
        'loginTime': loginTime?.millisecondsSinceEpoch,
        'rememberMe': rememberMe,
        'biometricEnabled': biometricEnabled,
        'sessionTimeout': sessionTimeout,
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _logger.e('Error exporting session data', error: e);
      return null;
    }
  }

  /// Import session data from backup
  Future<bool> importSessionData(Map<String, dynamic> sessionData) async {
    try {
      // Clear existing session first
      await clearAll();

      final token = sessionData['token'] as String?;
      final refreshToken = sessionData['refreshToken'] as String?;
      final userData = sessionData['userData'] as Map<String, dynamic>?;
      final loginTime = sessionData['loginTime'] as int?;
      final rememberMe = sessionData['rememberMe'] as bool? ?? false;
      final biometricEnabled =
          sessionData['biometricEnabled'] as bool? ?? false;
      final sessionTimeout = sessionData['sessionTimeout'] as int? ?? 30;

      bool success = true;

      if (token != null) {
        success &= await saveToken(token);
      }

      if (refreshToken != null) {
        success &= await saveRefreshToken(refreshToken);
      }

      if (userData != null) {
        success &= await saveUserData(userData);
      }

      success &= await saveRememberMe(rememberMe);
      success &= await saveBiometricEnabled(biometricEnabled);
      success &= await saveSessionTimeout(sessionTimeout);

      if (loginTime != null) {
        final prefs = await SharedPreferences.getInstance();
        success &= await prefs.setInt(_loginTimeKey, loginTime);
      }

      if (success) {
        _logger.d('Session data imported successfully');
      } else {
        _logger.e('Some session data failed to import');
      }

      return success;
    } catch (e) {
      _logger.e('Error importing session data', error: e);
      return false;
    }
  }

  /// Clear all app data (for testing or reset)
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.clear();

      if (success) {
        _logger.d('All app data cleared successfully');
      } else {
        _logger.e('Failed to clear all app data');
      }

      return success;
    } catch (e) {
      _logger.e('Error clearing all app data', error: e);
      return false;
    }
  }
}

/// Session Information Model
class SessionInfo {
  final bool hasToken;
  final bool hasRefreshToken;
  final bool hasUserData;
  final DateTime? loginTime;
  final DateTime? lastActiveTime;
  final int sessionTimeoutMinutes;
  final bool rememberMe;
  final bool biometricEnabled;
  final bool isValid;

  const SessionInfo({
    required this.hasToken,
    required this.hasRefreshToken,
    required this.hasUserData,
    this.loginTime,
    this.lastActiveTime,
    required this.sessionTimeoutMinutes,
    required this.rememberMe,
    required this.biometricEnabled,
    required this.isValid,
  });

  /// Get session duration
  Duration? get sessionDuration {
    if (loginTime == null) return null;
    return DateTime.now().difference(loginTime!);
  }

  /// Get session expiry time
  DateTime? get sessionExpiryTime {
    if (lastActiveTime == null) return null;
    return lastActiveTime!.add(Duration(minutes: sessionTimeoutMinutes));
  }

  /// Get time until session expires
  Duration? get timeUntilExpiry {
    final expiryTime = sessionExpiryTime;
    if (expiryTime == null) return null;
    return expiryTime.difference(DateTime.now());
  }

  /// Check if session is about to expire (within 5 minutes)
  bool get isAboutToExpire {
    final timeUntil = timeUntilExpiry;
    if (timeUntil == null) return false;
    return timeUntil.inMinutes <= 5 && timeUntil.inMinutes > 0;
  }

  @override
  String toString() {
    return 'SessionInfo('
        'hasToken: $hasToken, '
        'hasRefreshToken: $hasRefreshToken, '
        'hasUserData: $hasUserData, '
        'loginTime: $loginTime, '
        'lastActiveTime: $lastActiveTime, '
        'sessionTimeoutMinutes: $sessionTimeoutMinutes, '
        'rememberMe: $rememberMe, '
        'biometricEnabled: $biometricEnabled, '
        'isValid: $isValid'
        ')';
  }
}

/// Token Validation Result
class TokenValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool needsRefresh;

  const TokenValidationResult({
    required this.isValid,
    this.errorMessage,
    this.needsRefresh = false,
  });

  factory TokenValidationResult.valid() {
    return const TokenValidationResult(isValid: true);
  }

  factory TokenValidationResult.invalid(String message) {
    return TokenValidationResult(isValid: false, errorMessage: message);
  }

  factory TokenValidationResult.needsRefresh() {
    return const TokenValidationResult(isValid: false, needsRefresh: true);
  }
}
