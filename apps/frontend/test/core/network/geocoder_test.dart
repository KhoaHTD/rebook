import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/network/geocoder.dart';
import 'package:book_marketplace/shared/data/vietnam_geo.dart';

class _Stub implements HttpClientAdapter {
  _Stub(this.bodies);
  final List<String> bodies;
  var calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    bodies[calls++],
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('FakeGeocoder lấy tâm tỉnh có trong chuỗi tìm', () async {
    final hit = await FakeGeocoder().locate([
      '12 Trần Thái Tông, Cầu Giấy, Hà Nội, Việt Nam',
      'Hà Nội, Việt Nam',
    ]);
    expect(hit, VietnamGeo.province('Hà Nội'));
  });

  test('FakeGeocoder không nhận ra thì trả null', () async {
    expect(await FakeGeocoder().locate(['xyz']), isNull);
  });

  test('Nominatim: chuỗi đầu không có kết quả thì thử chuỗi thô hơn', () async {
    final stub = _Stub(['[]', '[{"lat":"10.03","lon":"105.78"}]']);
    final dio = Dio()..httpClientAdapter = stub;
    final hit = await NominatimGeocoder(dio).locate(['a', 'b']);
    expect(hit, (10.03, 105.78));
    expect(stub.calls, 2);
  });
}
