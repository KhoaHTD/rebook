import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';

DioException _response(int status, Map<String, dynamic> body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
);

void main() {
  test('401 sai email / mật khẩu giữ mã INVALID_CREDENTIALS, không thành hết phiên', () {
    final e = AppException.from(
      _response(401, {
        'code': 'INVALID_CREDENTIALS',
        'message': 'Email hoặc mật khẩu không đúng',
      }),
    );
    expect(e, isA<ServerException>());
    expect((e as ServerException).code, ErrorCodes.invalidCredentials);
  });

  test('401 khác (token hết hạn) vẫn là hết phiên đăng nhập', () {
    final e = AppException.from(
      _response(401, {'code': 'UNAUTHORIZED', 'message': 'Cần đăng nhập'}),
    );
    expect(e, isA<UnauthorizedException>());
  });

  test('400 VALIDATION_ERROR mang theo lỗi từng ô của backend', () {
    final e = AppException.from(
      _response(400, {
        'code': 'VALIDATION_ERROR',
        'message': 'Dữ liệu không hợp lệ',
        'fieldErrors': {'amount': 'Rút tối thiểu 50.000đ'},
      }),
    );
    expect((e as ServerException).fieldErrors, {
      'amount': 'Rút tối thiểu 50.000đ',
    });
  });

  test('409 giữ câu giải thích của backend', () {
    final e = AppException.from(
      _response(409, {
        'code': 'HAS_CHILDREN',
        'message': 'Hãy xoá danh mục con trước',
      }),
    );
    expect((e as ServerException).message, 'Hãy xoá danh mục con trước');
    expect(e.statusCode, 409);
  });
}
