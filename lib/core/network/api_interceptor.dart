import 'package:dio/dio.dart';

import '../utils/logger.dart';

/// API Interceptor for Dio HTTP Client
/// Handles request/response interception for logging and error handling
class ApiInterceptor extends Interceptor {
  final Logger _logger;

  ApiInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('API Request: ${options.method} ${options.uri}');
    _logger.d('Request Headers: ${options.headers}');
    
    // Log request body if present (but not sensitive data)
    if (options.data != null) {
      _logger.d('Request Body: ${options.data}');
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('API Response: ${response.statusCode} ${response.requestOptions.uri}');
    _logger.d('Response Headers: ${response.headers}');
    
    // Log response data in debug mode only (avoid logging large responses)
    if (response.data != null) {
      _logger.d('Response Data: ${response.data}');
    }
    
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('API Error: ${err.type} ${err.requestOptions.uri}');
    _logger.e('Error Response: ${err.response?.statusCode} ${err.response?.data}');
    
    super.onError(err, handler);
  }
}
