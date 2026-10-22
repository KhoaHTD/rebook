import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException([this.message, this.code]);

  /// Thông báo backend trả về (`{"code", "message"}`), đã viết cho người dùng đọc.
  final String? message;

  /// Mã lỗi nghiệp vụ của backend, vd `PRICE_CHANGED`, `BID_LIMIT_EXCEEDED`.
  final String? code;

  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
        case DioExceptionType.connectionError:
          return const NetworkException();
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode ?? 0;
          final (code, message) = _body(error.response?.data);
          if (status == 401) return UnauthorizedException(message, code);
          if (status == 403) return ForbiddenException(message, code);
          return ServerException(
            status,
            message ?? error.response?.statusMessage,
            code,
          );
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return UnknownException(error.message);
      }
    }
    return UnknownException(error.toString());
  }

  static (String?, String?) _body(Object? data) {
    if (data is Map) {
      final code = data['code'];
      final message = data['message'];
      return (code is String ? code : null, message is String ? message : null);
    }
    return (null, null);
  }

  @override
  String toString() => '$runtimeType(${code ?? ''} ${message ?? ''})';
}

final class NetworkException extends AppException {
  const NetworkException();
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message, super.code]);
}

/// Đã đăng nhập nhưng không được phép (chưa bật shop, chưa đăng ký phiên, bị cấm...).
final class ForbiddenException extends AppException {
  const ForbiddenException([super.message, super.code]);
}

final class ServerException extends AppException {
  const ServerException(this.statusCode, [super.message, super.code]);
  final int statusCode;

  /// Lỗi do yêu cầu (4xx) — thông báo của backend hiển thị được cho người dùng.
  bool get isClientError => statusCode >= 400 && statusCode < 500;
}

final class UnknownException extends AppException {
  const UnknownException([super.message]);
}

Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } catch (e) {
    throw AppException.from(e);
  }
}
