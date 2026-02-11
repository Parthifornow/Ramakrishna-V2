import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:retry/retry.dart';
import '../core/constants/app_constants.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  Dio? _dio;
  final Connectivity _connectivity = Connectivity();
  bool _isInitialized = false;

  void init() {
    // Prevent double initialization
    if (_isInitialized && _dio != null) {
      print('⚠️ NetworkService already initialized, skipping...');
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    _setupInterceptors();
    _isInitialized = true;
    print('✅ NetworkService initialized successfully');
  }

  void _setupInterceptors() {
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Check internet connectivity
        final hasConnection = await checkConnectivity();
        if (!hasConnection) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: 'No internet connection',
              type: DioExceptionType.connectionError,
            ),
          );
        }

        print('📡 ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ ${response.requestOptions.method} ${response.requestOptions.path} - ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ ${error.requestOptions.method} ${error.requestOptions.path} - ${error.message}');

        // Handle specific error types
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          // Retry on timeout
          try {
            final retryResponse = await _retry(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            return handler.next(error);
          }
        }

        return handler.next(error);
      },
    ));
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return await _dio!.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // Generic request method with retry logic
  Future<Map<String, dynamic>> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? token,
    bool useRetry = true,
  }) async {
    // Ensure initialized
    if (!_isInitialized || _dio == null) {
      throw Exception('NetworkService not initialized. Call init() first.');
    }

    try {
      final options = Options(
        method: method,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      Response response;

      if (useRetry) {
        response = await retry(
          () => _dio!.request(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ),
          retryIf: (e) => e is DioException && _shouldRetry(e),
          maxAttempts: 3,
          delayFactor: const Duration(seconds: 2),
        );
      } else {
        response = await _dio!.request(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      }

      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
        'code': 'UNKNOWN_ERROR',
      };
    }
  }

  bool _shouldRetry(DioException error) {
    // Retry on network errors and timeouts
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null && error.response!.statusCode! >= 500);
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    return {
      'success': response.statusCode == 200,
      'data': response.data,
      'statusCode': response.statusCode,
    };
  }

  Map<String, dynamic> _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return {
          'success': false,
          'message': 'Request timeout. Please check your connection and try again.',
          'code': 'TIMEOUT',
        };

      case DioExceptionType.connectionError:
        return {
          'success': false,
          'message': 'No internet connection. Please check your network settings.',
          'code': 'NO_CONNECTION',
        };

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data is Map<String, dynamic>) {
          return data;
        }

        return {
          'success': false,
          'message': _getStatusCodeMessage(statusCode),
          'code': 'HTTP_ERROR',
          'statusCode': statusCode,
        };

      case DioExceptionType.cancel:
        return {
          'success': false,
          'message': 'Request cancelled',
          'code': 'CANCELLED',
        };

      default:
        return {
          'success': false,
          'message': error.message ?? 'An error occurred',
          'code': 'NETWORK_ERROR',
        };
    }
  }

  String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied';
      case 404:
        return 'Resource not found';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Convenience methods
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? token,
    bool useRetry = true,
  }) {
    return request(
      endpoint: endpoint,
      method: 'GET',
      queryParameters: queryParameters,
      token: token,
      useRetry: useRetry,
    );
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
    bool useRetry = false,
  }) {
    return request(
      endpoint: endpoint,
      method: 'POST',
      data: data,
      token: token,
      useRetry: useRetry,
    );
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
    bool useRetry = false,
  }) {
    return request(
      endpoint: endpoint,
      method: 'PUT',
      data: data,
      token: token,
      useRetry: useRetry,
    );
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
    bool useRetry = false,
  }) {
    return request(
      endpoint: endpoint,
      method: 'DELETE',
      data: data,
      token: token,
      useRetry: useRetry,
    );
  }
}