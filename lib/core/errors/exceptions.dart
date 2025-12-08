/// App Exceptions
/// 
/// Custom exception classes for error handling.

/// Base Exception
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server Exception
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });
}

/// Network Exception
class NetworkException extends AppException {
  NetworkException({
    super.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Authentication Exception
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory AuthException.invalidCredentials() => AuthException(
        message: 'Email hoặc mật khẩu không đúng.',
        code: 'INVALID_CREDENTIALS',
      );

  factory AuthException.userNotFound() => AuthException(
        message: 'Tài khoản không tồn tại.',
        code: 'USER_NOT_FOUND',
      );

  factory AuthException.emailInUse() => AuthException(
        message: 'Email đã được sử dụng.',
        code: 'EMAIL_IN_USE',
      );

  factory AuthException.weakPassword() => AuthException(
        message: 'Mật khẩu quá yếu.',
        code: 'WEAK_PASSWORD',
      );

  factory AuthException.sessionExpired() => AuthException(
        message: 'Phiên đăng nhập đã hết hạn.',
        code: 'SESSION_EXPIRED',
      );
}

/// Cache Exception
class CacheException extends AppException {
  CacheException({
    super.message = 'Không thể đọc dữ liệu từ bộ nhớ cache.',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// Permission Exception
class PermissionException extends AppException {
  PermissionException({
    super.message = 'Bạn không có quyền thực hiện hành động này.',
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

/// Validation Exception
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
    this.fieldErrors,
  });
}

/// Location Exception
class LocationException extends AppException {
  LocationException({
    super.message = 'Không thể lấy vị trí. Vui lòng bật GPS.',
    super.code = 'LOCATION_ERROR',
    super.originalError,
  });
}
