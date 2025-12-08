/// Failures
/// 
/// Failure classes for domain layer error handling.
/// Uses Either pattern with dartz package.

import 'package:equatable/equatable.dart';

/// Base Failure class
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server Failure
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Network Failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Không có kết nối mạng.',
    super.code = 'NETWORK_FAILURE',
  });
}

/// Cache Failure
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Lỗi đọc dữ liệu từ bộ nhớ.',
    super.code = 'CACHE_FAILURE',
  });
}

/// Auth Failure
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
  
  factory AuthFailure.invalidCredentials() => const AuthFailure(
    message: 'Email hoặc mật khẩu không đúng.',
    code: 'INVALID_CREDENTIALS',
  );

  factory AuthFailure.sessionExpired() => const AuthFailure(
    message: 'Phiên đăng nhập đã hết hạn.',
    code: 'SESSION_EXPIRED',
  );
}

/// Permission Failure
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Không có quyền thực hiện.',
    super.code = 'PERMISSION_DENIED',
  });
}

/// Validation Failure
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_FAILURE',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}
