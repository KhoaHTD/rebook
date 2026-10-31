import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/network/admin_units.dart';

class _Stub implements HttpClientAdapter {
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final Object body = switch (options.path) {
      '/p/' => [
        {'name': 'Thành phố Hồ Chí Minh', 'code': 79},
        {'name': 'Tỉnh Bà Rịa - Vũng Tàu', 'code': 77},
      ],
      '/p/79' => {
        'districts': [
          {'name': 'Thành phố Thủ Đức', 'code': 769},
          {'name': 'Quận 1', 'code': 760},
        ],
      },
      '/d/769' => {
        'wards': [
          {'name': 'Phường Long Thạnh Mỹ', 'code': 26800},
        ],
      },
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('unitKey bỏ dấu và tiền tố cấp để tên khớp nhau', () {
    expect(unitKey('Thành phố Thủ Đức'), unitKey('TP. Thủ Đức'));
    expect(unitKey('Phường 12'), unitKey('P. 12'));
    expect(unitKey('Quận 1'), unitKey('Q. 1'));
  });

  test('quận theo tên tỉnh, phường theo mã quận, có cache', () async {
    final stub = _Stub();
    final units = OpenApiAdminUnits(Dio()..httpClientAdapter = stub);
    final d = await units.districts('TP. Hồ Chí Minh');
    expect(d.map((e) => e.name), ['Thành phố Thủ Đức', 'Quận 1']);
    expect(await units.districts('TP. Hồ Chí Minh'), d);
    final w = await units.wards(d.first.code);
    expect(w.single.name, 'Phường Long Thạnh Mỹ');
    expect(stub.paths, ['/p/', '/p/79', '/d/769']);
  });

  test('tỉnh lạ thì không có quận', () async {
    final units = OpenApiAdminUnits(Dio()..httpClientAdapter = _Stub());
    expect(await units.districts('Atlantis'), isEmpty);
  });
}
