import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/shared/widgets/cover_warp.dart';

/// Ảnh đơn sắc w×h với một khối đỏ hình chữ nhật [red] (toạ độ điểm ảnh).
Future<ui.Image> _image(int w, int h, Rect red) async {
  final rec = ui.PictureRecorder();
  Canvas(rec)
    ..drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    )
    ..drawRect(red, Paint()..color = const Color(0xFFFF0000));
  return rec.endRecording().toImage(w, h);
}

Future<Color> _pixel(Uint8List png, int x, int y) async {
  final codec = await ui.instantiateImageCodec(png);
  final img = (await codec.getNextFrame()).image;
  final data = (await img.toByteData())!;
  final i = (y * img.width + x) * 4;
  return Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

void main() {
  test('Homography: bốn góc và tâm của hình vuông đơn vị', () {
    final q = [
      const Offset(10, 5),
      const Offset(110, 20),
      const Offset(100, 210),
      const Offset(0, 180),
    ];
    final h = Homography.fromQuad(q);
    expect((h.map(0, 0) - q[0]).distance, lessThan(1e-6));
    expect((h.map(1, 0) - q[1]).distance, lessThan(1e-6));
    expect((h.map(1, 1) - q[2]).distance, lessThan(1e-6));
    expect((h.map(0, 1) - q[3]).distance, lessThan(1e-6));
    final c = h.map(0.5, 0.5);
    expect(c.dx, inInclusiveRange(10, 100));
    expect(c.dy, inInclusiveRange(20, 190));
  });

  test('Homography: hình chữ nhật thì khớp phép afin', () {
    final h = Homography.fromQuad([
      const Offset(0, 0),
      const Offset(200, 0),
      const Offset(200, 300),
      const Offset(0, 300),
    ]);
    expect((h.map(0.5, 0.5) - const Offset(100, 150)).distance, lessThan(1e-6));
  });

  test('warpSize: trung bình hai cạnh đối, co về maxSide', () {
    final s = warpSize([
      const Offset(0, 0),
      const Offset(200, 0),
      const Offset(200, 300),
      const Offset(0, 300),
    ]);
    expect((s.width, s.height), (200, 300));
    final big = warpSize([
      const Offset(0, 0),
      const Offset(4000, 0),
      const Offset(4000, 6000),
      const Offset(0, 6000),
    ], maxSide: 1000);
    expect((big.width, big.height), (667, 1000));
  });

  testWidgets('warpCover cắt đúng vùng tứ giác', (tester) async {
    await tester.runAsync(() async {
      // Ảnh 400×400, khối đỏ 100..300 ở giữa; tứ giác nghiêng bao đúng khối đỏ → ảnh ra gần như đỏ hết.
      final img = await _image(
        400,
        400,
        const Rect.fromLTWH(100, 100, 200, 200),
      );
      final out = await warpCover(img, [
        const Offset(100, 100),
        const Offset(300, 100),
        const Offset(300, 300),
        const Offset(100, 300),
      ]);
      final mid = await _pixel(out, 100, 100);
      expect(mid.r, greaterThan(0.9));
      expect(mid.g, lessThan(0.1));
      // Lấy tứ giác rộng hơn thì viền ảnh ra phải trắng.
      final wide = await warpCover(img, [
        const Offset(0, 0),
        const Offset(400, 0),
        const Offset(400, 400),
        const Offset(0, 400),
      ]);
      final edge = await _pixel(wide, 5, 5);
      expect(edge.g, greaterThan(0.9));
    });
  });
}
