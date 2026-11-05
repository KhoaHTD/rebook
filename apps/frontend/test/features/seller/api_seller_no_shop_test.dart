import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/seller/data/api_seller_repository.dart';

/// Backend trả một mã lỗi cố định cho mọi request.
class _Status implements HttpClientAdapter {
  _Status(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

ApiSellerRepository _repo(int status, Map<String, dynamic> body) =>
    ApiSellerRepository(
      api.RestClient(Dio()..httpClientAdapter = _Status(status, body)),
    );

void main() {
  test(
    'chưa có shop (403 của backend) thì myShop trả null để hiện form mở shop',
    () async {
      final repo = _repo(403, {
        'code': 'FORBIDDEN',
        'message': 'Bạn cần bật Shop trước khi bán hàng',
      });
      expect(await repo.myShop(), isNull);
    },
  );

  test('404 cũng được coi là chưa có shop', () async {
    expect(await _repo(404, {'code': 'NOT_FOUND'}).myShop(), isNull);
  });

  test('lỗi máy chủ thật vẫn được ném ra', () async {
    final repo = _repo(500, {'code': 'INTERNAL_ERROR'});
    expect(repo.myShop(), throwsA(isA<ServerException>()));
  });
}
