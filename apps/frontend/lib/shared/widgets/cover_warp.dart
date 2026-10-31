import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Phép chiếu từ hình vuông đơn vị (u, v ∈ [0, 1]) lên một tứ giác bất kỳ (Heckbert, 1989).
/// Dùng để "làm phẳng" bìa sách chụp nghiêng: ảnh ra là hình chữ nhật, mỗi điểm lấy mẫu từ tứ giác trong ảnh gốc.
class Homography {
  const Homography(
    this.a,
    this.b,
    this.c,
    this.d,
    this.e,
    this.f,
    this.g,
    this.h,
  );

  /// [q]: bốn góc theo thứ tự trên-trái, trên-phải, dưới-phải, dưới-trái (toạ độ điểm ảnh của ảnh gốc).
  factory Homography.fromQuad(List<Offset> q) {
    assert(q.length == 4);
    final x0 = q[0].dx, y0 = q[0].dy;
    final x1 = q[1].dx, y1 = q[1].dy;
    final x2 = q[2].dx, y2 = q[2].dy;
    final x3 = q[3].dx, y3 = q[3].dy;
    final dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3;
    final dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
    if (dx3.abs() < 1e-9 && dy3.abs() < 1e-9) {
      // Hình bình hành: chỉ cần phép afin.
      return Homography(x1 - x0, x3 - x0, x0, y1 - y0, y3 - y0, y0, 0, 0);
    }
    final den = dx1 * dy2 - dy1 * dx2;
    final g = (dx3 * dy2 - dy3 * dx2) / den;
    final h = (dx1 * dy3 - dy1 * dx3) / den;
    return Homography(
      x1 - x0 + g * x1,
      x3 - x0 + h * x3,
      x0,
      y1 - y0 + g * y1,
      y3 - y0 + h * y3,
      y0,
      g,
      h,
    );
  }

  final double a, b, c, d, e, f, g, h;

  /// Điểm của tứ giác ứng với (u, v) trên hình vuông đơn vị.
  Offset map(double u, double v) {
    final w = g * u + h * v + 1;
    return Offset((a * u + b * v + c) / w, (d * u + e * v + f) / w);
  }
}

/// Kích thước ảnh ra (rộng, cao) cho tứ giác [q]: trung bình hai cạnh đối, co về tối đa [maxSide] điểm ảnh.
({int width, int height}) warpSize(List<Offset> q, {int maxSide = 1000}) {
  double dist(Offset p, Offset r) => (p - r).distance;
  final w0 = (dist(q[0], q[1]) + dist(q[3], q[2])) / 2;
  final h0 = (dist(q[0], q[3]) + dist(q[1], q[2])) / 2;
  final scale = math.min(1.0, maxSide / math.max(w0, h0));
  return (
    width: math.max(1, (w0 * scale).round()),
    height: math.max(1, (h0 * scale).round()),
  );
}

/// Làm phẳng bìa sách: lấy tứ giác [q] của [src] (trên-trái, trên-phải, dưới-phải, dưới-trái) thành ảnh PNG
/// hình chữ nhật. Chia lưới mịn rồi vẽ bằng `drawVertices` nên không phải duyệt từng điểm ảnh.
Future<Uint8List> warpCover(
  ui.Image src,
  List<Offset> q, {
  int maxSide = 1000,
}) async {
  final size = warpSize(q, maxSide: maxSide);
  final w = size.width, h = size.height;
  final proj = Homography.fromQuad(q);

  const cols = 24, rows = 32;
  final positions = Float32List((cols + 1) * (rows + 1) * 2);
  final tex = Float32List(positions.length);
  var k = 0;
  for (var j = 0; j <= rows; j++) {
    final v = j / rows;
    for (var i = 0; i <= cols; i++) {
      final u = i / cols;
      positions[k] = u * w;
      positions[k + 1] = v * h;
      final p = proj.map(u, v);
      tex[k] = p.dx;
      tex[k + 1] = p.dy;
      k += 2;
    }
  }
  final indices = Uint16List(cols * rows * 6);
  var n = 0;
  for (var j = 0; j < rows; j++) {
    for (var i = 0; i < cols; i++) {
      final a = j * (cols + 1) + i;
      final b = a + 1;
      final c = a + cols + 1;
      final d = c + 1;
      indices
        ..[n++] = a
        ..[n++] = b
        ..[n++] = c
        ..[n++] = b
        ..[n++] = d
        ..[n++] = c;
    }
  }
  final vertices = ui.Vertices.raw(
    ui.VertexMode.triangles,
    positions,
    textureCoordinates: tex,
    indices: indices,
  );
  final paint = Paint()
    ..shader = ui.ImageShader(
      src,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList(const [
        1,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    )
    ..filterQuality = FilterQuality.high;
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawVertices(vertices, BlendMode.srcOver, paint);
  final image = await recorder.endRecording().toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
