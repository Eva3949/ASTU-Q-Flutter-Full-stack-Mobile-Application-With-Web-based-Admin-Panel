import 'dart:developer' as developer;

/// Logger Utility
/// Provides logging functionality throughout the app
class Logger {
  final String _tag;
  
  const Logger([String? tag]) : _tag = tag ?? 'App';
  
  /// Log debug message
  void d(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '[$_tag] $message',
      name: 'DEBUG',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log info message
  void i(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '[$_tag] $message',
      name: 'INFO',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log warning message
  void w(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '[$_tag] $message',
      name: 'WARNING',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log error message
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '[$_tag] $message',
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
