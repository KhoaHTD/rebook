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
  static const receiptMismatch = 'RECEIPT_AMOUNT_MISMATCH';
  static const topupLocked = 'TOPUP_LOCKED';
  static const withdrawDailyLimit = 'WITHDRAW_DAILY_LIMIT';
  static const codNotAllowed = 'COD_NOT_ALLOWED';
  static const debtOpen = 'DEBT_OPEN';
  static const staffCannotBid = 'STAFF_CANNOT_BID';
  static const invalidIsbn = 'INVALID_ISBN';
  static const invalidPrice = 'INVALID_PRICE';
  static const bookInWarehouse = 'BOOK_IN_WAREHOUSE';
  static const tooManyRequests = 'TOO_MANY_REQUESTS';
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
          final data = error.response?.data;
          final code = data is Map ? data['code'] as String? : null;
          final msg = data is Map ? data['message'] as String? : null;
          // 401 vì sai email / mật khẩu không phải hết phiên: giữ mã để báo đúng nguyên nhân.
          if (status == 401 && code != ErrorCodes.invalidCredentials) {
            return const UnauthorizedException();
          }
          final fields = data is Map && data['fieldErrors'] is Map
              ? {
                  for (final e in (data['fieldErrors'] as Map).entries)
                    '${e.key}': '${e.value}',
                }
              : const <String, String>{};
          return ServerException(
            status,
            code: _normalizeCode(code, msg),
            message: msg,
            fieldErrors: fields,
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
  const ServerException(
    this.statusCode, {
    this.code,
    String? message,
    this.fieldErrors = const {},
  }) : super(message);
  final int statusCode;

  /// Lỗi theo từng ô nhập (`VALIDATION_ERROR`): tên ô → câu báo lỗi của backend.
  final Map<String, String> fieldErrors;

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
