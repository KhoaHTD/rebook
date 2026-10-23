import 'package:dio/dio.dart';

/// Mã lỗi nghiệp vụ backend trả về trong `ErrorResponse.code` (openapi.yaml).
/// UI dịch từng mã sang câu dễ hiểu; mã lạ hiện thông báo chung.
abstract final class ErrorCodes {
  static const ownListing = 'OWN_LISTING';
  static const priceChanged = 'PRICE_CHANGED';
  static const bidTooLow = 'BID_TOO_LOW';
  static const alreadyLeading = 'ALREADY_LEADING';
  static const limitExceeded = 'LIMIT_EXCEEDED';
  static const notRegistered = 'NOT_REGISTERED';
  static const lotClosed = 'LOT_CLOSED';
  static const registrationClosed = 'REGISTRATION_CLOSED';
  static const auctionBanned = 'AUCTION_BANNED';
  static const outOfStock = 'OUT_OF_STOCK';
  static const insufficientBalance = 'INSUFFICIENT_BALANCE';
  static const invalidTransition = 'INVALID_TRANSITION';
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const invalidOtp = 'INVALID_OTP';
  static const emailTaken = 'EMAIL_TAKEN';
  static const notFound = 'NOT_FOUND';
}

/// Lỗi chuẩn hoá của app. Tầng data bắt mọi exception và ném lại dạng này
/// (qua [guardApi]); UI chỉ cần biết các case dưới đây.
/// Mã lỗi backend → mã UI đã có chuỗi dịch ([ErrorCodes]). Mã lạ giữ nguyên.
String? _normalizeCode(String? code, String? message) {
  switch (code) {
    case 'BID_LIMIT_EXCEEDED':
      return ErrorCodes.limitExceeded;
    case 'LOT_NOT_OPEN':
    case 'SESSION_CLOSED':
    case 'SESSION_NOT_LIVE':
    case 'SESSION_NOT_ACTIVE':
      return ErrorCodes.lotClosed;
    case 'INVALID_STATUS_TRANSITION':
      return ErrorCodes.invalidTransition;
    case 'FORBIDDEN':
      // Backend gộp các lý do cấm đấu giá vào FORBIDDEN, chỉ khác câu chữ.
      final m = message ?? '';
      if (m.contains('cấm tham gia đấu giá')) return ErrorCodes.auctionBanned;
      if (m.contains('chưa đăng ký')) return ErrorCodes.notRegistered;
      return code;
    default:
      return code;
  }
}

sealed class AppException implements Exception {
  const AppException([this.message]);

  /// Thông điệp kỹ thuật — không hiển thị trực tiếp cho người dùng.
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
          if (status == 401) return const UnauthorizedException();
          final data = error.response?.data;
          final code = data is Map ? data['code'] as String? : null;
          final msg = data is Map ? data['message'] as String? : null;
          return ServerException(
            status,
            code: _normalizeCode(code, msg),
            message: msg,
          );
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
  const ServerException(this.statusCode, {this.code, String? message})
    : super(message);
  final int statusCode;

  /// Mã nghiệp vụ, xem [ErrorCodes].
  final String? code;
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
