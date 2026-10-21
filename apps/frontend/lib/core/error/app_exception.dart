import 'package:dio/dio.dart';

/// Lỗi chuẩn hoá của app. Tầng data bắt mọi exception và ném lại dạng này
/// (qua [guardApi]); UI chỉ cần biết các case dưới đây.
sealed class AppException implements Exception {
  const AppException([this.message]);

  /// Thông điệp kỹ thuật từ server (nếu có) — không hiển thị trực tiếp cho người dùng.
  final String? message;

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
          if (status == 401 || status == 403) {
            return const UnauthorizedException();
          }
          return ServerException(status, error.response?.statusMessage);
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return UnknownException(error.message);
      }
    }
    return UnknownException(error.toString());
  }

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

final class NetworkException extends AppException {
  const NetworkException();
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException();
}

final class ServerException extends AppException {
  const ServerException(this.statusCode, [super.message]);
  final int statusCode;
}

final class UnknownException extends AppException {
  const UnknownException([super.message]);
}

/// Bọc mọi lời gọi API trong repository:
/// `Future<Book> getBook(String id) => guardApi(() async => ...);`
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } catch (e) {
    throw AppException.from(e);
  }
}
