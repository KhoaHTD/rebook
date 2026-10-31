import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/shared/data/vietnam_geo.dart';

void main() {
  group('VietnamGeo.normalize', () {
    test('bỏ dấu, chữ thường, bỏ tiền tố', () {
      expect(VietnamGeo.normalize('TP. Hồ Chí Minh'), 'ho chi minh');
      expect(VietnamGeo.normalize('Thành phố Đà Nẵng'), 'da nang');
      expect(VietnamGeo.normalize('Tỉnh Thừa Thiên Huế'), 'thua thien hue');
      expect(VietnamGeo.normalize('Bà Rịa - Vũng Tàu'), 'ba ria vung tau');
    });
  });

  group('VietnamGeo.province', () {
    test('nhận ra tên có dấu / không dấu / có tiền tố', () {
      expect(VietnamGeo.province('TP. Hồ Chí Minh'), (10.78, 106.70));
      expect(VietnamGeo.province('Hà Nội'), (21.03, 105.85));
      expect(VietnamGeo.province('thanh pho can tho'), (10.03, 105.78));
    });

    test('tên không nhận ra thì trả null', () {
      expect(VietnamGeo.province(''), isNull);
      expect(VietnamGeo.province('Atlantis'), isNull);
    });

    test('mọi tỉnh nằm trong khung nhìn của sơ đồ', () {
      for (final name in ['Hà Giang', 'Cà Mau', 'Quảng Ninh', 'Kiên Giang']) {
        final p = VietnamGeo.province(name)!;
        expect(p.$1, inInclusiveRange(VietnamGeo.minLat, VietnamGeo.maxLat));
        expect(p.$2, inInclusiveRange(VietnamGeo.minLon, VietnamGeo.maxLon));
      }
    });
  });

  test('sơ đồ có Hoàng Sa và Trường Sa trong khung nhìn', () {
    for (final g in [...VietnamGeo.paracel, ...VietnamGeo.spratly]) {
      expect(g.$1, inInclusiveRange(VietnamGeo.minLat, VietnamGeo.maxLat));
      expect(g.$2, inInclusiveRange(VietnamGeo.minLon, VietnamGeo.maxLon));
    }
    expect(VietnamGeo.paracel, isNotEmpty);
    expect(VietnamGeo.spratly, isNotEmpty);
  });
}
