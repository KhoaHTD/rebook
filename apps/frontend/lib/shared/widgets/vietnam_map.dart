import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/data/vietnam_geo.dart';

/// Sơ đồ Việt Nam cơ bản tự vẽ trong app: đường bờ biển, biên giới, các đảo lớn, **Quần đảo Hoàng Sa và Quần
/// đảo Trường Sa của Việt Nam** (có ghi tên), kèm ghim ở tỉnh / thành [province]. Không cần mạng, khoá API hay
/// package bản đồ. Ghim chỉ chính xác tới cấp tỉnh / thành.
class VietnamMap extends StatelessWidget {
  const VietnamMap({super.key, this.province, this.aspectRatio = 0.86});

  /// Tên tỉnh / thành của địa chỉ cần ghim (không nhận ra thì không ghim).
  final String? province;

  /// Rộng / cao của khung vẽ.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pin = province == null ? null : VietnamGeo.province(province!);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, box) {
          final proj = _Projection(box.biggest);
          final at = pin == null ? null : proj.offset(pin);
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPainter(
                      proj: proj,
                      textStyle: context.textStyles.labelSmall!,
                      paracel: l10n.mapParacel,
                      spratly: l10n.mapSpratly,
                      eastSea: l10n.mapEastSea,
                    ),
                  ),
                ),
                if (at != null)
                  Positioned(
                    // Mũi ghim chạm đúng điểm: icon cao 40, mũi ở đáy giữa.
                    left: at.dx - 20,
                    top: at.dy - 38,
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 40,
                      color: MapPalette.pin,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Chiếu (vĩ độ, kinh độ) lên khung vẽ, giữ đúng tỉ lệ ngang / dọc (kinh độ co theo cos của vĩ độ giữa).
class _Projection {
  _Projection(this.size) {
    const midLat = (VietnamGeo.minLat + VietnamGeo.maxLat) / 2;
    final lonSpan = (VietnamGeo.maxLon - VietnamGeo.minLon) * _cos(midLat);
    const latSpan = VietnamGeo.maxLat - VietnamGeo.minLat;
    final s = size.width / lonSpan < size.height / latSpan
        ? size.width / lonSpan
        : size.height / latSpan;
    scale = s;
    _lonK = _cos(midLat);
    _ox = (size.width - lonSpan * s) / 2;
    _oy = (size.height - latSpan * s) / 2;
  }

  final Size size;
  late final double scale;
  late final double _lonK;
  late final double _ox;
  late final double _oy;

  static double _cos(double deg) {
    // cos xấp xỉ đủ chính xác cho vĩ độ 6–24° (sai số < 0,001): 1 - x²/2 + x⁴/24, x tính bằng rad.
    final x = deg * 3.141592653589793 / 180;
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24;
  }

  Offset offset(GeoPoint p) => Offset(
    _ox + (p.$2 - VietnamGeo.minLon) * _lonK * scale,
    _oy + (VietnamGeo.maxLat - p.$1) * scale,
  );
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.proj,
    required this.textStyle,
    required this.paracel,
    required this.spratly,
    required this.eastSea,
  });

  final _Projection proj;
  final TextStyle textStyle;
  final String paracel;
  final String spratly;
  final String eastSea;

  Path _poly(List<GeoPoint> pts) {
    final p = Path()
      ..moveTo(proj.offset(pts.first).dx, proj.offset(pts.first).dy);
    for (final q in pts.skip(1)) {
      final o = proj.offset(q);
      p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  void _label(Canvas canvas, String text, Offset center, {Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: color ?? MapPalette.label,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: proj.size.width * 0.5);
    // Giữ nhãn nằm trọn trong khung (không bị cắt ở mép).
    final left = (center.dx - tp.width / 2).clamp(
      6.0,
      proj.size.width - tp.width - 6,
    );
    tp.paint(canvas, Offset(left, center.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = MapPalette.sea);

    final land = _poly(VietnamGeo.mainland);
    canvas
      ..drawPath(land, Paint()..color = MapPalette.land)
      ..drawPath(
        land,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round
          ..color = MapPalette.border,
      );

    final islandFill = Paint()..color = MapPalette.land;
    final islandLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = MapPalette.border;
    for (final isle in VietnamGeo.coastalIslands) {
      final p = _poly(isle);
      canvas
        ..drawPath(p, islandFill)
        ..drawPath(p, islandLine);
    }

    // Hoàng Sa, Trường Sa: nhiều đảo nhỏ, vẽ thành chấm; cụm được khoanh bằng vòng nét đứt.
    final dot = Paint()..color = MapPalette.border;
    final r = (proj.scale * 0.085).clamp(1.6, 3.4);
    for (final g in [...VietnamGeo.paracel, ...VietnamGeo.spratly]) {
      canvas.drawCircle(proj.offset(g), r, dot);
    }
    _dashedRing(canvas, VietnamGeo.paracel);
    _dashedRing(canvas, VietnamGeo.spratly);

    _label(
      canvas,
      eastSea.toUpperCase(),
      proj.offset((lat: 14.2, lon: 114.6).toPoint()),
      color: MapPalette.sea.withValues(alpha: 1).darken(),
    );
    _label(canvas, paracel, proj.offset(VietnamGeo.paracelLabel.toPoint()));
    _label(canvas, spratly, proj.offset(VietnamGeo.spratlyLabel.toPoint()));
  }

  /// Vòng nét đứt bao quanh một cụm đảo.
  void _dashedRing(Canvas canvas, List<GeoPoint> pts) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final g in pts) {
      final o = proj.offset(g);
      if (o.dx < minX) minX = o.dx;
      if (o.dy < minY) minY = o.dy;
      if (o.dx > maxX) maxX = o.dx;
      if (o.dy > maxY) maxY = o.dy;
    }
    final rect = Rect.fromLTRB(minX - 10, minY - 10, maxX + 10, maxY + 10);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = MapPalette.border;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.proj.size != proj.size ||
      old.paracel != paracel ||
      old.spratly != spratly ||
      old.eastSea != eastSea;
}

extension on ({double lat, double lon}) {
  GeoPoint toPoint() => (lat, lon);
}

extension on Color {
  Color darken() {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.4).clamp(0.0, 1.0)).toColor();
  }
}
