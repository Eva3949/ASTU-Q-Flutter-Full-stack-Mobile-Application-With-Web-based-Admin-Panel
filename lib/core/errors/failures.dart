/// Base Failure Class
/// All failures should extend this class
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'Failure(message: $message)';
}

/// Network Failure
/// Occurs when there's no internet connection or network issues
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

/// Server Failure
/// Occurs when the server returns an error (5xx, 4xx)
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

/// Validation Failure
/// Occurs when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Unauthorized Failure
/// Occurs when user is not authenticated or token is expired
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(String message) : super(message);
}

/// Timeout Failure
/// Occurs when a request times out
class TimeoutFailure extends Failure {
  const TimeoutFailure(String message) : super(message);
}

/// Not Found Failure
/// Occurs when requested resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Cache Failure
/// Occurs when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// File Upload Failure
/// Occurs when file/image upload operations fail
class FileUploadFailure extends Failure {
  const FileUploadFailure(String message) : super(message);
}

/// Unknown Failure
/// Catch-all for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}
