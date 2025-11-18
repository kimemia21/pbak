import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'comms_config.dart';

/// Global communications service for handling network requests
/// Provides a centralized way to make HTTP requests with built-in
/// error handling, interceptors, and configuration
class CommsService {
  static CommsService? _instance;
  late Dio _dio;

  // Base URL for API requests (from config)
  static String get baseUrl => CommsConfig.baseUrl;

  // Timeout durations (from config)
  static Duration get connectTimeout =>
      Duration(seconds: CommsConfig.connectTimeout);
  static Duration get receiveTimeout =>
      Duration(seconds: CommsConfig.receiveTimeout);
  static Duration get sendTimeout => Duration(seconds: CommsConfig.sendTimeout);

  // Private constructor
  CommsService._internal() {
    _initializeDio();
  }

  /// Get the singleton instance of CommsService
  static CommsService get instance {
    _instance ??= CommsService._internal();
    return _instance!;
  }

  /// Initialize Dio with default configurations
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-api-key': 'nokey', // API key required by backend
        },
        validateStatus: (status) {
          // Accept all status codes to handle them manually
          return status != null && status < 500;
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_LogInterceptor());
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  /// Get the Dio instance for advanced usage
  Dio get dio => _dio;

  /// Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authentication token
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Update base URL (useful for switching environments)
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Generic GET request
  Future<CommsResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    print("this is the path $path");
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return CommsResponse<T>.fromResponse(response);
    } on DioException catch (e) {
      return CommsResponse<T>.fromError(e);
    } catch (e) {
      return CommsResponse<T>.fromException(e);
    }
  }

  /// Generic POST request
  Future<CommsResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return CommsResponse<T>.fromResponse(response);
    } on DioException catch (e) {
      return CommsResponse<T>.fromError(e);
    } catch (e) {
      return CommsResponse<T>.fromException(e);
    }
  }

  /// Generic PUT request
  Future<CommsResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return CommsResponse<T>.fromResponse(response);
    } on DioException catch (e) {
      return CommsResponse<T>.fromError(e);
    } catch (e) {
      return CommsResponse<T>.fromException(e);
    }
  }

  /// Generic PATCH request
  Future<CommsResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return CommsResponse<T>.fromResponse(response);
    } on DioException catch (e) {
      return CommsResponse<T>.fromError(e);
    } catch (e) {
      return CommsResponse<T>.fromException(e);
    }
  }

  /// Generic DELETE request
  Future<CommsResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return CommsResponse<T>.fromResponse(response);
    } on DioException catch (e) {
      return CommsResponse<T>.fromError(e);
    } catch (e) {
      return CommsResponse<T>.fromException(e);
    }
  }

  /// Upload file with multipart/form-data
  Future<CommsResponse<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return CommsResponse<T>.fromResponse(response);
    } on DioException catch (e) {
      return CommsResponse<T>.fromError(e);
    } catch (e) {
      return CommsResponse<T>.fromException(e);
    }
  }

  /// Download file
  Future<CommsResponse<void>> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      return CommsResponse<void>.fromResponse(response);
    } on DioException catch (e) {
      return CommsResponse<void>.fromError(e);
    } catch (e) {
      return CommsResponse<void>.fromException(e);
    }
  }

  /// Clear all interceptors
  void clearInterceptors() {
    _dio.interceptors.clear();
  }

  /// Add custom interceptor
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
}

/// Response wrapper class
class CommsResponse<T> {
  final T? data;
  final int? statusCode;
  final String? message;
  final bool success;
  final CommsErrorType? errorType;
  final Map<String, dynamic>? rawData;

  CommsResponse({
    this.data,
    this.statusCode,
    this.message,
    required this.success,
    this.errorType,
    this.rawData,
  });

  factory CommsResponse.fromResponse(Response response) {
    final bool isSuccess =
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;

    return CommsResponse<T>(
      data: response.data is T ? response.data : null,
      statusCode: response.statusCode,
      message: isSuccess ? 'Success' : _extractErrorMessage(response),
      success: isSuccess,
      rawData: response.data is Map<String, dynamic> ? response.data : null,
      errorType: isSuccess ? null : _determineErrorType(response.statusCode),
    );
  }

  factory CommsResponse.fromError(DioException error) {
    return CommsResponse<T>(
      data: null,
      statusCode: error.response?.statusCode,
      message: _extractDioErrorMessage(error),
      success: false,
      errorType: _determineErrorTypeFromDio(error),
      rawData: error.response?.data is Map<String, dynamic>
          ? error.response?.data
          : null,
    );
  }

  factory CommsResponse.fromException(Object exception) {
    return CommsResponse<T>(
      data: null,
      statusCode: null,
      message: exception.toString(),
      success: false,
      errorType: CommsErrorType.unknown,
    );
  }

  static String _extractErrorMessage(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['message'] ??
          data['error'] ??
          data['msg'] ??
          'Request failed';
    }
    return 'Request failed';
  }

  static String _extractDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        if (error.response?.data is Map<String, dynamic>) {
          final data = error.response!.data as Map<String, dynamic>;
          return data['message'] ??
              data['error'] ??
              data['msg'] ??
              'Request failed';
        }
        return 'Bad response from server';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return 'No internet connection';
        }
        return 'An unexpected error occurred';
      default:
        return error.message ?? 'An error occurred';
    }
  }

  static CommsErrorType _determineErrorType(int? statusCode) {
    if (statusCode == null) return CommsErrorType.unknown;

    if (statusCode == 401) return CommsErrorType.unauthorized;
    if (statusCode == 403) return CommsErrorType.forbidden;
    if (statusCode == 404) return CommsErrorType.notFound;
    if (statusCode == 422) return CommsErrorType.validationError;
    if (statusCode >= 400 && statusCode < 500)
      return CommsErrorType.clientError;
    if (statusCode >= 500) return CommsErrorType.serverError;

    return CommsErrorType.unknown;
  }

  static CommsErrorType _determineErrorTypeFromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CommsErrorType.timeout;
      case DioExceptionType.badResponse:
        return _determineErrorType(error.response?.statusCode);
      case DioExceptionType.cancel:
        return CommsErrorType.cancelled;
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return CommsErrorType.network;
        }
        return CommsErrorType.unknown;
      default:
        return CommsErrorType.unknown;
    }
  }
}

/// Error types for better error handling
enum CommsErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validationError,
  clientError,
  serverError,
  cancelled,
  unknown,
}

/// Logging interceptor
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────');
      print('│ REQUEST: ${options.method} ${options.uri}');
      print('│ Headers: ${options.headers}');
      if (options.data != null) {
        print('│ Data: ${options.data}');
      }
      print('└─────────────────────────────────────────────────────');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────');
      print(
        '│ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
      );
      print('│ Data: ${response.data}');
      print('└─────────────────────────────────────────────────────');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────');
      print('│ ERROR: ${err.requestOptions.method} ${err.requestOptions.uri}');
      print('│ Message: ${err.message}');
      print('│ Response: ${err.response?.data}');
      print('└─────────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }
}

/// Authentication interceptor
class _AuthInterceptor extends Interceptor {
  // This interceptor can be used to refresh tokens automatically
  // or add any authentication-related logic

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add any pre-request authentication logic here
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 errors, refresh tokens, etc.
    if (err.response?.statusCode == 401) {
      // TODO: Implement token refresh logic
      // For now, just pass the error along
    }
    super.onError(err, handler);
  }
}

/// Error handling interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Global error handling logic
    // You can show global error messages, log to crash reporting, etc.
    super.onError(err, handler);
  }
}
