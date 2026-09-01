import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/storage_service.dart';
import '../utils/app_logger.dart';

class ApiClient {
  final StorageService storage;
  late final Dio dio;
  late final Dio _tokenDio; // Dedicated client for refresh requests without interceptor loops

  static String get defaultBaseUrl => AppConfig.defaultBaseUrl;

  ApiClient({
    required this.storage,
    String? baseUrl,
  }) {
    final effectiveBaseUrl = baseUrl ?? storage.getBaseUrl() ?? defaultBaseUrl;
    AppLogger.i('🚀 ApiClient initialized with Base URL: $effectiveBaseUrl');

    dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _tokenDio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void updateBaseUrl(String rawUrl) {
    final normalized = AppConfig.normalizeBaseUrl(rawUrl);
    dio.options.baseUrl = normalized;
    _tokenDio.options.baseUrl = normalized;
    storage.saveBaseUrl(normalized);
    AppLogger.i('🌐 ApiClient Base URL updated and saved: $normalized');
  }

  Future<({bool success, String message})> testConnection(String rawUrl) async {
    final testUrl = AppConfig.normalizeBaseUrl(rawUrl);
    AppLogger.d('🔍 Testing connection to: $testUrl');

    final testDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    try {
      final response = await testDio.get(testUrl);
      if (response.statusCode == 200) {
        return (success: true, message: 'Server reached successfully! (HTTP 200)');
      }
      return (success: false, message: 'Server responded with status ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return (success: false, message: 'Connection timed out. Check IP or firewall.');
      }
      if (e.type == DioExceptionType.connectionError) {
        return (success: false, message: 'Connection refused. Is backend running on this URL?');
      }
      return (success: false, message: e.message ?? 'Failed to reach server');
    } catch (e) {
      return (success: false, message: 'Unexpected error: $e');
    }
  }

  void _setupInterceptors() {
    // 1. Logger Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.d('➡️ [HTTP REQ] ${options.method} ${options.baseUrl}${options.path}\n'
              'Headers: ${options.headers}\n'
              'Query: ${options.queryParameters}\n'
              'Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.i('✅ [HTTP RES] ${response.statusCode} ${response.requestOptions.path}\n'
              'Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          AppLogger.e(
            '❌ [HTTP ERR] ${error.response?.statusCode} ${error.requestOptions.path}\n'
            'Message: ${error.message}\n'
            'Response: ${error.response?.data}',
            error,
            error.stackTrace,
          );
          return handler.next(error);
        },
      ),
    );

    // 2. Auth & Token Refresh Interceptor
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          final token = storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If 401 Unauthorized and not already a login/refresh attempt
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            AppLogger.w('⚠️ Received 401 Unauthorized. Attempting token refresh...');
            final refreshToken = storage.getRefreshToken();

            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Attempt to rotate refresh token
                final response = await _tokenDio.post(
                  '/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 && response.data['success'] == true) {
                  final data = response.data['data'] as Map<String, dynamic>;
                  final newAccessToken = data['accessToken'] as String;
                  final newRefreshToken = data['refreshToken'] as String;

                  AppLogger.i('🔄 Token refreshed successfully. Retrying failed request...');

                  // Save new tokens
                  await storage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Update header and retry original request
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                  final clonedRequest = await dio.request(
                    retryOptions.path,
                    options: Options(
                      method: retryOptions.method,
                      headers: retryOptions.headers,
                      responseType: retryOptions.responseType,
                      contentType: retryOptions.contentType,
                    ),
                    data: retryOptions.data,
                    queryParameters: retryOptions.queryParameters,
                  );

                  return handler.resolve(clonedRequest);
                }
              } catch (refreshErr) {
                AppLogger.e('🚫 Refresh failed. Clearing user session.', refreshErr);
                await storage.clearSession();
              }
            } else {
              AppLogger.w('⚠️ No refresh token found. Clearing user session.');
              await storage.clearSession();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }
}
