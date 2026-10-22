import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Poster sách kiểu Apple Books: tỉ lệ 2:3, gáy sáng bên trái, bóng đổ mềm.
/// Có ảnh bìa ([coverUrl]) thì hiện ảnh; chưa có thì tự vẽ bìa từ tên sách.
class BookPoster extends StatelessWidget {
  const BookPoster({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl,
    this.seed,
    this.width,
    this.shadow = true,
  });

  final String title;
  final String author;
  final String? coverUrl;

  /// Giữ màu/hình bìa tự vẽ ổn định cho cùng một cuốn (thường là id sách).
  final String? seed;
  final double? width;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final fallback = DrawnCover(
      title: title,
      author: author,
      seed: seed ?? title,
    );
    final cover = coverUrl == null
        ? fallback
        : CachedNetworkImage(
            imageUrl: coverUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          );

    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.poster,
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: context.appColors.posterShadow,
                      blurRadius: 28,
                      spreadRadius: -10,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: context.appColors.posterShadow.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.poster,
            child: Stack(
              fit: StackFit.expand,
              children: [
                cover,
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: CoverPalette.spine,
                        stops: CoverPalette.spineStops,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bìa tự vẽ: nền một màu, tên sách serif, tác giả, một hình vẽ phẳng.
/// Màu và hình chọn theo [seed] nên cùng một cuốn luôn giống nhau.
class DrawnCover extends StatelessWidget {
  const DrawnCover({
    super.key,
    required this.title,
    required this.author,
    required this.seed,
  });

  final String title;
  final String author;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final h = _hash(seed);
    final (bg, ink) = CoverPalette.pairs[h % CoverPalette.pairs.length];
    final motifColor = CoverPalette.motif[(h ~/ 7) % CoverPalette.motif.length];
    final motif = _Motif.values[(h ~/ 31) % _Motif.values.length];

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return ColoredBox(
          color: bg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _MotifPainter(motif, ink, motifColor)),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.1, w * 0.1, w * 0.1, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.serif,
                        fontWeight: FontWeight.w600,
                        fontSize: w * 0.12,
                        height: 1.05,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: w * 0.03),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontSize: w * 0.058,
                        color: ink.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static int _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }
}

enum _Motif { circle, bars, leaf, arch, dots, hills }

/// Hình vẽ phẳng ở nửa dưới bìa, toạ độ theo tỉ lệ khung 2:3.
class _MotifPainter extends CustomPainter {
  _MotifPainter(this.motif, this.ink, this.accent);

  final _Motif motif;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final fill = Paint()..color = accent;
    final inkPaint = Paint()..color = ink.withValues(alpha: 0.9);
    switch (motif) {
      case _Motif.circle:
        canvas.drawCircle(Offset(w * 0.62, h * 0.6), w * 0.17, fill);
        for (var i = 0; i < 3; i++) {
          final inset = w * 0.15 * i;
          canvas.drawRect(
            Rect.fromLTWH(
              inset,
              h * (0.77 + 0.06 * i),
              w - inset * 2,
              h * 0.02,
            ),
            inkPaint,
          );
        }
      case _Motif.bars:
        for (var i = 0; i < 4; i++) {
          final bh = h * (0.16 + 0.07 * ((i * 3) % 4));
          canvas.drawRect(
            Rect.fromLTWH(w * (0.14 + 0.19 * i), h * 0.92 - bh, w * 0.12, bh),
            i.isEven ? fill : inkPaint,
          );
        }
      case _Motif.leaf:
        final p = Path()
          ..moveTo(w * 0.28, h * 0.84)
          ..quadraticBezierTo(w * 0.4, h * 0.5, w * 0.86, h * 0.56)
          ..quadraticBezierTo(w * 0.7, h * 0.86, w * 0.28, h * 0.84);
        canvas.drawPath(p, fill);
        canvas.drawRect(
          Rect.fromLTWH(w * 0.08, h * 0.7, w * 0.32, h * 0.012),
          inkPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.16, h * 0.74, w * 0.24, h * 0.012),
          inkPaint,
        );
      case _Motif.arch:
        final r = Rect.fromLTWH(w * 0.24, h * 0.5, w * 0.52, h * 0.5);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            r,
            topLeft: Radius.circular(w * 0.26),
            topRight: Radius.circular(w * 0.26),
          ),
          fill,
        );
        canvas.drawCircle(Offset(w * 0.5, h * 0.66), w * 0.06, inkPaint);
      case _Motif.dots:
        for (var i = 0; i < 12; i++) {
          final c = Offset(
            w * (0.23 + (i % 4) * 0.18),
            h * (0.62 + (i ~/ 4) * 0.1),
          );
          canvas.drawCircle(c, w * 0.045, i == 0 ? fill : inkPaint);
        }
      case _Motif.hills:
        final p = Path()
          ..moveTo(0, h)
          ..lineTo(0, h * 0.78)
          ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.5, h * 0.76)
          ..quadraticBezierTo(w * 0.75, h * 0.9, w, h * 0.7)
          ..lineTo(w, h)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawCircle(Offset(w * 0.74, h * 0.58), w * 0.07, inkPaint);
    }
  }

  @override
  bool shouldRepaint(_MotifPainter old) =>
      old.motif != motif || old.ink != ink || old.accent != accent;
}
