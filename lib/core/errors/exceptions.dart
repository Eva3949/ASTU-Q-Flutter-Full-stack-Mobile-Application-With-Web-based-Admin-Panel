/// Base Exception Class
/// All custom exceptions should extend this class
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() =>
      'ApiException(message: $message, statusCode: $statusCode)';
}

/// Generic API Exception for fallback cases
class ApiExceptionImpl extends ApiException {
  const ApiExceptionImpl(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Server Exception
/// Occurs when the server returns an error response
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, super.originalError});
}

/// Network Exception
/// Occurs when there's no internet connection or network issues
class NetworkException extends ApiException {
  const NetworkException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Timeout Exception
/// Occurs when a request times out
class TimeoutException extends ApiException {
  const TimeoutException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Validation Exception
/// Occurs when input validation fails
class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Unauthorized Exception
/// Occurs when user is not authenticated or token is expired
class UnauthorizedException extends ApiException {
  const UnauthorizedException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Not Found Exception
/// Occurs when requested resource is not found
class NotFoundException extends ApiException {
  const NotFoundException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Forbidden Exception
/// Occurs when user doesn't have permission to access resource
class ForbiddenException extends ApiException {
  const ForbiddenException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Request Cancelled Exception
/// Occurs when a request is cancelled
class RequestCancelledException extends ApiException {
  const RequestCancelledException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// File Size Exceeded Exception
/// Occurs when uploaded file is too large
class FileSizeExceededException extends ApiException {
  const FileSizeExceededException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Unsupported File Type Exception
/// Occurs when uploaded file type is not supported
class UnsupportedFileTypeException extends ApiException {
  const UnsupportedFileTypeException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Rate Limit Exception
/// Occurs when too many requests are made
class RateLimitException extends ApiException {
  const RateLimitException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}
