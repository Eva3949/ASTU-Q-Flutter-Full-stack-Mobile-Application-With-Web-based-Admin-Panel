import 'dart:io';

/// Database Configuration
/// Reads database settings from environment variables
class DatabaseConfig {
  static String? _envValue(String key) {
    try {
      return Platform.environment[key];
    } catch (e) {
      return null;
    }
  }

  /// Database Host
  static String get host => _envValue('DB_HOST') ?? 'localhost';

  /// Database Port
  static int get port {
    final portStr = _envValue('DB_PORT') ?? '3306';
    return int.tryParse(portStr) ?? 3306;
  }

  /// Database Name
  static String get databaseName => _envValue('DB_NAME') ?? 'astuq_database';

  /// Database User
  static String get username => _envValue('DB_USER') ?? 'root';

  /// Database Password
  static String get password => _envValue('DB_PASSWORD') ?? '';

  /// Database Charset
  static String get charset => _envValue('DB_CHARSET') ?? 'utf8mb4';

  /// Database Collation
  static String get collation => _envValue('DB_COLLATION') ?? 'utf8mb4_unicode_ci';

  /// Maximum Connections
  static int get maxConnections {
    final maxStr = _envValue('DB_MAX_CONNECTIONS') ?? '10';
    return int.tryParse(maxStr) ?? 10;
  }

  /// Connection Timeout (seconds)
  static int get connectionTimeout {
    final timeoutStr = _envValue('DB_CONNECTION_TIMEOUT') ?? '30';
    return int.tryParse(timeoutStr) ?? 30;
  }

  /// Idle Timeout (seconds)
  static int get idleTimeout {
    final timeoutStr = _envValue('DB_IDLE_TIMEOUT') ?? '60';
    return int.tryParse(timeoutStr) ?? 60;
  }

  /// Environment (development, production)
  static String get environment => _envValue('ENVIRONMENT') ?? 'development';

  /// Debug Mode
  static bool get debug => _envValue('DEBUG')?.toLowerCase() == 'true';

  /// JWT Secret
  static String get jwtSecret => _envValue('JWT_SECRET') ?? 'default_jwt_secret';

  /// API Key
  static String get apiKey => _envValue('API_KEY') ?? 'default_api_key';

  /// App Name
  static String get appName => _envValue('APP_NAME') ?? 'ASTU-Q';

  /// App Version
  static String get appVersion => _envValue('APP_VERSION') ?? '1.0.0';

  /// Get connection string for MySQL/MariaDB
  static String get connectionString {
    return 'mysql://$username:${password.isNotEmpty ? password : ''}'
        '@$host:$port/$databaseName';
  }

  /// Print all configuration values (for debugging)
  static void printConfig() {
    if (debug) {
      print('=== Database Configuration ===');
      print('Host: $host');
      print('Port: $port');
      print('Database: $databaseName');
      print('Username: $username');
      print('Password: ${password.isNotEmpty ? '***' : '(empty)'}');
      print('Charset: $charset');
      print('Collation: $collation');
      print('Max Connections: $maxConnections');
      print('Connection Timeout: ${connectionTimeout}s');
      print('Idle Timeout: ${idleTimeout}s');
      print('Environment: $environment');
      print('Debug: $debug');
      print('==============================');
    }
  }

  /// Validate required configuration
  static bool validateConfig() {
    final errors = <String>[];

    if (host.isEmpty) errors.add('Database host is required');
    if (databaseName.isEmpty) errors.add('Database name is required');
    if (username.isEmpty) errors.add('Database username is required');

    if (errors.isNotEmpty) {
      print('Database Configuration Errors:');
      for (final error in errors) {
        print('- $error');
      }
      return false;
    }

    return true;
  }
}
