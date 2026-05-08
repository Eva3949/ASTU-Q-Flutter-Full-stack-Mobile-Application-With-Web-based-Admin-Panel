import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../errors/exceptions.dart';
import '../utils/logger.dart';
import 'api_interceptor.dart';
import 'network_info.dart';

/// Dio HTTP Client Configuration
/// Provides a configured Dio instance for API requests
@singleton
class DioClient {
  Dio? _dio;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  DioClient(this._networkInfo, this._logger);

  /// Get the Dio instance
  Dio get dio {
    _dio ??= _createDioInstance();
    return _dio!;
  }

  /// Create and configure Dio instance
  Dio _createDioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://evadevstudio.com/sami',
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
        sendTimeout: const Duration(milliseconds: 30000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ASTU-Q/1.0.0',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.addAll([
      ApiInterceptor(_logger),
      LogInterceptor(
        request: kDebugMode,
        requestHeader: kDebugMode,
        requestBody: kDebugMode,
        responseHeader: kDebugMode,
        responseBody: kDebugMode,
        error: kDebugMode,
        logPrint: (object) => _logger.d('Dio: $object'),
      ),
    ]);

    return dio;
  }

  /// Make GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();

      final response = await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();

      final response = await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();

      final response = await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();

      final response = await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();

      final response = await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload file
  Future<Response<T>> upload<T>(
    String path,
    dynamic file, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();

      String fileName;
      int fileSize;
      dynamic fileData;

      if (file is File) {
        fileName = file.path.split('/').last;
        fileSize = await file.length();
        fileData = await MultipartFile.fromFile(file.path, filename: fileName);
      } else if (file is Uint8List) {
        fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        fileSize = file.length;
        fileData = MultipartFile.fromBytes(file, filename: fileName);
      } else {
        throw const ApiExceptionImpl('Invalid file type for upload');
      }

      // Check file size (10MB limit)
      if (fileSize > 10 * 1024 * 1024) {
        throw const FileSizeExceededException(
          'File size exceeds maximum limit',
        );
      }

      final formData = FormData.fromMap({'file': fileData, ...?data});

      final response = await dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options ?? Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Download file
  Future<Response> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _checkConnectivity();

      final response = await dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle successful response
  Response<T> _handleResponse<T>(Response<T> response) {
    _logger.d('Response received: ${response.statusCode}');

    // Check if response is successful
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response;
    }

    throw ServerException(
      'Server returned status code: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  /// Handle Dio errors
  ApiException _handleDioError(DioException error) {
    _logger.e('Dio error: ${error.type}', error: error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Request timeout');

      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');

      case DioExceptionType.badResponse:
        return _handleHttpError(error);

      case DioExceptionType.cancel:
        return const RequestCancelledException('Request was cancelled');

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return const NetworkException('No internet connection');
        }
        return ApiExceptionImpl(
          error.message ?? 'Unknown error occurred',
          statusCode: error.response?.statusCode,
        );
    }
  }

  /// Handle HTTP error responses
  ApiException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'An error occurred';

    // Try to extract error message from response
    if (responseData != null) {
      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? responseData['error'] ?? message;
      } else if (responseData is String) {
        try {
          final decoded = jsonDecode(responseData);
          message = decoded['message'] ?? decoded['error'] ?? message;
        } catch (e) {
          message = responseData;
        }
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 413:
        return const FileSizeExceededException(
          'File size exceeds maximum limit',
        );
      case 415:
        return const UnsupportedFileTypeException('Unsupported file type');
      case 422:
        return ValidationException(message);
      case 429:
        return const RateLimitException('Too many requests');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(message, statusCode: statusCode);
      default:
        return ApiExceptionImpl(message, statusCode: statusCode);
    }
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        throw const NetworkException('No internet connection');
      }
    } catch (e) {
      // Log connectivity check failure but don't block the request
      // This allows the actual HTTP request to attempt and fail with more specific error
      _logger.w('Connectivity check failed: $e');
    }
  }

  /// Update authorization token
  void updateAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    _logger.d('Auth token updated');
  }

  /// Clear authorization token
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
    _logger.d('Auth token cleared');
  }

  /// Update base URL
  void updateBaseUrl(String baseUrl) {
    dio.options.baseUrl = baseUrl;
    _logger.d('Base URL updated to: $baseUrl');
  }

  /// Cancel all requests
  void cancelRequests(CancelToken cancelToken) {
    cancelToken.cancel('Requests cancelled');
    _logger.d('All requests cancelled');
  }
}
