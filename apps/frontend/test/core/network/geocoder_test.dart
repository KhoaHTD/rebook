import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/network/geocoder.dart';
import 'package:book_marketplace/shared/data/vietnam_geo.dart';

/// Trả lần lượt các thân JSON dựng sẵn và ghi lại chuỗi tìm của từng yêu cầu.
class _Stub implements HttpClientAdapter {
  _Stub(this.bodies);
  final List<String> bodies;
  final queries = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    queries.add('${options.queryParameters['q']}');
    return ResponseBody.fromString(
      bodies[queries.length - 1],
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _hit(double lat, double lon, [String category = 'highway']) =>
    '[{"lat":"$lat","lon":"$lon","category":"$category","display_name":"x"}]';

NominatimGeocoder _geocoder(_Stub stub) =>
    NominatimGeocoder(Dio()..httpClientAdapter = stub, Duration.zero);

void main() {
  const address = (
    street: '84 Vo Van Kiet, hẻm 2',
    ward: 'P. Nguyễn Thái Bình',
    district: 'Quận 1',
    province: 'TP. Hồ Chí Minh',
  );

  test('FakeGeocoder lấy tâm tỉnh', () async {
    expect(
      await FakeGeocoder().locate(address),
      VietnamGeo.province('Hồ Chí Minh'),
    );
  });

  test('địa chỉ đầy đủ tìm thấy ngay thì dừng', () async {
    final stub = _Stub([_hit(10.771, 106.695)]);
    expect(await _geocoder(stub).locate(address), (10.771, 106.695));
    expect(stub.queries, [
      '84 Vo Van Kiet, hẻm 2, Phường Nguyễn Thái Bình, Quận 1, Hồ Chí Minh, Việt Nam',
    ]);
  });

  test('bỏ kết quả ở xa tỉnh rồi thử chuỗi ngắn hơn', () async {
    final stub = _Stub([_hit(21.0, 105.8), _hit(10.77, 106.69)]);
    expect(await _geocoder(stub).locate(address), (10.77, 106.69));
    expect(stub.queries.length, 2);
    expect(
      stub.queries[1],
      '84 Vo Van Kiet, Phường Nguyễn Thái Bình, Quận 1, Hồ Chí Minh, Việt Nam',
    );
  });

  test(
    'không thấy đường thì dò phường, chỉ nhận ranh giới hành chính',
    () async {
      final stub = _Stub([
        '[]',
        '[]',
        '[]',
        '[]',
        _hit(10.85, 106.62, 'shop'), // cửa hàng trùng tên: bỏ
        _hit(10.78, 106.7, 'boundary'),
      ]);
      expect(await _geocoder(stub).locate(address), (10.78, 106.7));
      expect(stub.queries.last, 'Quận 1, Hồ Chí Minh, Việt Nam');
    },
  );

  test('không tìm được gì thì trả null', () async {
    final stub = _Stub(List.filled(6, '[]'));
    expect(await _geocoder(stub).locate(address), isNull);
  });

  test('clean đổi viết tắt thành tên đầy đủ', () {
    expect(NominatimGeocoder.clean('P. 12'), 'Phường 12');
    expect(NominatimGeocoder.clean('Q. 3'), 'Quận 3');
    expect(NominatimGeocoder.clean('TP. Thủ Đức'), 'Thủ Đức');
  });
}
