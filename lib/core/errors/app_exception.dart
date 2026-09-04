/// Predictable, machine-readable error codes following AGENT.md Rule 6.
enum AppErrorCode {
  networkError,
  unauthorized,
  forbidden,
  notFound,
  invalidTransition,
  validationError,
  serverError,
  unknown;

  String get code {
    return switch (this) {
      AppErrorCode.networkError => 'NETWORK_ERROR',
      AppErrorCode.unauthorized => 'UNAUTHORIZED',
      AppErrorCode.forbidden => 'FORBIDDEN',
      AppErrorCode.notFound => 'NOT_FOUND',
      AppErrorCode.invalidTransition => 'INVALID_TRANSITION',
      AppErrorCode.validationError => 'VALIDATION_ERROR',
      AppErrorCode.serverError => 'SERVER_ERROR',
      AppErrorCode.unknown => 'UNKNOWN_ERROR',
    };
  }
}

/// Standardized domain exception isolating external API failures behind a clean boundary.
class AppException implements Exception {
  final AppErrorCode code;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const AppException({
    required this.code,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  factory AppException.fromDio(dynamic error) {
    // Isolate external Dio/network details behind domain exception
    return AppException(
      code: AppErrorCode.networkError,
      message: error?.toString() ?? 'Network connection failed',
      originalError: error,
    );
  }

  @override
  String toString() => '[${code.code}] $message';
}
