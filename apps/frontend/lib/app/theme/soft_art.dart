import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/soft_palette.dart';

/// Ba tranh minh hoạ của màn giới thiệu, vẽ bằng hình khối bo tròn (không dùng file ảnh):
/// chồng sách, búa đấu giá với sách cổ, hộp sách và đồng xu. Sách nào cũng có mặt cười cho dễ thương.
enum SoftArtKind { books, auction, box }

class SoftArt extends StatelessWidget {
  const SoftArt(this.kind, {super.key, this.size = 300});

  final SoftArtKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ArtPainter(kind)),
  );
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.kind);

  final SoftArtKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300);
    switch (kind) {
      case SoftArtKind.books:
        _books(canvas);
      case SoftArtKind.auction:
        _auction(canvas);
      case SoftArtKind.box:
        _box(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.kind != kind;

  // ── Hình dùng chung ────────────────────────────────────────────────────────

  static Paint _fill(Color c) => Paint()..color = c;

  static void _rr(Canvas c, Rect r, double radius, Color color) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    _fill(color),
  );

  static void _shadow(Canvas c, double cx, double y, double w) => c.drawOval(
    Rect.fromCenter(center: Offset(cx, y), width: w, height: 16),
    _fill(SoftPalette.ink.withValues(alpha: 0.12)),
  );

  /// Mặt cười: hai mắt chấm, miệng cong, hai má hồng. [s] là cỡ mặt.
  static void _face(Canvas c, Offset o, double s) {
    c.drawCircle(o + Offset(-s * 0.9, 0), s * 0.34, _fill(SoftPalette.ink));
    c.drawCircle(o + Offset(s * 0.9, 0), s * 0.34, _fill(SoftPalette.ink));
    c.drawCircle(
      o + Offset(-s * 0.9 - 1, -s * 0.12),
      s * 0.1,
      _fill(SoftPalette.paper),
    );
    c.drawCircle(
      o + Offset(s * 0.9 - 1, -s * 0.12),
      s * 0.1,
      _fill(SoftPalette.paper),
    );
    final mouth = Path()
      ..moveTo(o.dx - s * 0.32, o.dy + s * 0.5)
      ..quadraticBezierTo(
        o.dx,
        o.dy + s * 1.0,
        o.dx + s * 0.32,
        o.dy + s * 0.5,
      );
    c.drawPath(
      mouth,
      Paint()
        ..color = SoftPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.22
        ..strokeCap = StrokeCap.round,
    );
    final blush = _fill(SoftPalette.rose.withValues(alpha: 0.75));
    c.drawCircle(o + Offset(-s * 1.65, s * 0.55), s * 0.4, blush);
    c.drawCircle(o + Offset(s * 1.65, s * 0.55), s * 0.4, blush);
  }

  /// Ngôi sao lấp lánh bốn cánh.
  static void _sparkle(Canvas c, Offset o, double r, Color color) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    c.drawPath(p, _fill(color));
  }

  /// Một cuốn sách nằm ngang nhìn từ gáy: thân màu, mép giấy bên phải, dải trang trí.
  static void _flatBook(Canvas c, Rect r, Color cover, Color band) {
    _rr(c, r, 8, cover);
    _rr(
      c,
      Rect.fromLTWH(
        r.right - r.height * 0.55,
        r.top + 5,
        r.height * 0.55 - 5,
        r.height - 10,
      ),
      5,
      SoftPalette.pages,
    );
    _rr(c, Rect.fromLTWH(r.left + 18, r.top, 9, r.height), 0, band);
    _rr(c, Rect.fromLTWH(r.left + 36, r.top, 4, r.height), 0, band);
  }

  // ── Tranh 1: chồng sách có cuốn dựa nghiêng ───────────────────────────────

  void _books(Canvas c) {
    _shadow(c, 150, 262, 230);
    // Cuốn dựa nghiêng phía sau bên phải.
    c.save();
    c.translate(212, 168);
    c.rotate(0.2);
    _rr(c, const Rect.fromLTWH(-44, -100, 88, 132), 10, SoftPalette.sage);
    _rr(
      c,
      const Rect.fromLTWH(-44, -100, 14, 132),
      6,
      SoftPalette.teal.withValues(alpha: 0.35),
    );
    _rr(c, const Rect.fromLTWH(-20, -84, 56, 10), 5, SoftPalette.pages);
    _face(c, const Offset(4, -34), 9);
    c.restore();
    // Chồng ba cuốn.
    _flatBook(
      c,
      const Rect.fromLTWH(46, 214, 190, 44),
      SoftPalette.teal,
      SoftPalette.gold,
    );
    _flatBook(
      c,
      const Rect.fromLTWH(64, 174, 164, 40),
      SoftPalette.orange,
      SoftPalette.pages,
    );
    _flatBook(
      c,
      const Rect.fromLTWH(54, 138, 150, 36),
      SoftPalette.tan,
      SoftPalette.teal,
    );
    // Trái tim nhỏ trên đỉnh chồng.
    _heart(c, const Offset(96, 122), 13, SoftPalette.rose);
    _sparkle(c, const Offset(58, 84), 11, SoftPalette.gold);
    _sparkle(c, const Offset(250, 70), 8, SoftPalette.paper);
    _sparkle(c, const Offset(36, 150), 6, SoftPalette.paper);
  }

  static void _heart(Canvas c, Offset o, double s, Color color) {
    final p = Path()
      ..moveTo(o.dx, o.dy + s * 0.9)
      ..cubicTo(
        o.dx - s * 1.6,
        o.dy - s * 0.2,
        o.dx - s * 0.7,
        o.dy - s * 1.2,
        o.dx,
        o.dy - s * 0.4,
      )
      ..cubicTo(
        o.dx + s * 0.7,
        o.dy - s * 1.2,
        o.dx + s * 1.6,
        o.dy - s * 0.2,
        o.dx,
        o.dy + s * 0.9,
      )
      ..close();
    c.drawPath(p, _fill(color));
  }

  // ── Tranh 2: búa đấu giá và sách cổ ───────────────────────────────────────

  void _auction(Canvas c) {
    _shadow(c, 150, 264, 240);
    // Đế gõ búa.
    _rr(c, const Rect.fromLTWH(160, 236, 112, 24), 10, SoftPalette.wood);
    _rr(c, const Rect.fromLTWH(172, 228, 88, 14), 7, SoftPalette.tan);
    // Sách cổ đứng, bìa xanh đậm, viền vàng, có mặt cười.
    _rr(c, const Rect.fromLTWH(46, 112, 112, 150), 12, SoftPalette.teal);
    _rr(
      c,
      const Rect.fromLTWH(46, 112, 18, 150),
      8,
      SoftPalette.ink.withValues(alpha: 0.25),
    );
    _rr(c, const Rect.fromLTWH(76, 126, 70, 8), 4, SoftPalette.gold);
    _rr(c, const Rect.fromLTWH(76, 244, 70, 8), 4, SoftPalette.gold);
    _face(c, const Offset(110, 184), 11);
    // Búa: đầu và cán xoay nghiêng, đang giáng xuống đế.
    c.save();
    c.translate(210, 116);
    c.rotate(-math.pi / 5.2);
    _rr(c, const Rect.fromLTWH(-8, 14, 16, 112), 8, SoftPalette.wood);
    _rr(c, const Rect.fromLTWH(-46, -26, 92, 48), 16, SoftPalette.orange);
    _rr(c, const Rect.fromLTWH(-6, -26, 10, 48), 0, SoftPalette.gold);
    c.restore();
    // Tia vui khi búa chạm đế.
    for (final a in const [-0.5, -0.1, 0.35]) {
      final from = Offset(
        222 + 22 * math.cos(a - 1.2),
        222 + 22 * math.sin(a - 1.2),
      );
      final to = Offset(
        222 + 38 * math.cos(a - 1.2),
        222 + 38 * math.sin(a - 1.2),
      );
      c.drawLine(
        from,
        to,
        Paint()
          ..color = SoftPalette.ink
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    _sparkle(c, const Offset(60, 80), 12, SoftPalette.paper);
    _sparkle(c, const Offset(130, 60), 7, SoftPalette.gold);
    _sparkle(c, const Offset(270, 150), 8, SoftPalette.paper);
  }

  // ── Tranh 3: hộp sách và đồng xu ──────────────────────────────────────────

  void _box(Canvas c) {
    _shadow(c, 150, 266, 220);
    // Mấy cuốn sách thò ra khỏi hộp.
    c.save();
    c.translate(112, 140);
    c.rotate(-0.12);
    _rr(c, const Rect.fromLTWH(-30, -70, 58, 120), 8, SoftPalette.teal);
    _rr(c, const Rect.fromLTWH(-20, -58, 38, 8), 4, SoftPalette.gold);
    c.restore();
    c.save();
    c.translate(166, 148);
    c.rotate(0.1);
    _rr(c, const Rect.fromLTWH(-32, -84, 64, 130), 8, SoftPalette.sage);
    _rr(
      c,
      const Rect.fromLTWH(-32, -84, 10, 130),
      5,
      SoftPalette.ink.withValues(alpha: 0.18),
    );
    _face(c, const Offset(2, -34), 8);
    c.restore();
    c.save();
    c.translate(214, 156);
    c.rotate(0.28);
    _rr(c, const Rect.fromLTWH(-24, -66, 48, 110), 8, SoftPalette.rose);
    _rr(c, const Rect.fromLTWH(-12, -54, 24, 8), 4, SoftPalette.pages);
    c.restore();
    // Thân hộp cạc-tông (hình thang) và nắp mở hai bên.
    final body = Path()
      ..moveTo(58, 170)
      ..lineTo(242, 170)
      ..lineTo(228, 262)
      ..quadraticBezierTo(226, 270, 218, 270)
      ..lineTo(82, 270)
      ..quadraticBezierTo(74, 270, 72, 262)
      ..close();
    c.drawPath(body, _fill(SoftPalette.tan));
    c.drawPath(
      Path()
        ..moveTo(58, 170)
        ..lineTo(32, 140)
        ..lineTo(70, 150)
        ..lineTo(86, 170)
        ..close(),
      _fill(SoftPalette.sand),
    );
    c.drawPath(
      Path()
        ..moveTo(242, 170)
        ..lineTo(268, 140)
        ..lineTo(230, 150)
        ..lineTo(214, 170)
        ..close(),
      _fill(SoftPalette.sand),
    );
    // Nhãn dán trên hộp.
    _rr(c, const Rect.fromLTWH(112, 200, 76, 28), 8, SoftPalette.pages);
    _rr(c, const Rect.fromLTWH(122, 210, 40, 7), 3.5, SoftPalette.tan);
    // Đồng xu bay lên.
    _coin(c, const Offset(68, 84), 26);
    _coin(c, const Offset(246, 74), 18);
    _sparkle(c, const Offset(150, 54), 9, SoftPalette.paper);
    _sparkle(c, const Offset(34, 190), 7, SoftPalette.gold);
  }

  static void _coin(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, _fill(SoftPalette.gold));
    c.drawCircle(
      o,
      r * 0.72,
      Paint()
        ..color = SoftPalette.wood.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14,
    );
    _rr(
      c,
      Rect.fromCenter(center: o, width: r * 0.28, height: r * 0.8),
      r * 0.1,
      SoftPalette.wood.withValues(alpha: 0.55),
    );
  }
}
