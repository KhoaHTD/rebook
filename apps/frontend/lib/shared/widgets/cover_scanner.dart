import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/cover_warp.dart';

/// Mở tờ "Chỉnh bìa sách": người bán kéo 4 chấm về 4 góc bìa trước, app làm phẳng thành ảnh chữ nhật.
/// Trả về ảnh PNG đã nắn, hoặc null nếu huỷ.
Future<Uint8List?> showCoverScanner(BuildContext context, Uint8List photo) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    // Kéo chấm không được làm tờ trượt đóng lại.
    enableDrag: false,
    isDismissible: false,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.96,
      child: CoverScanner(photo: photo),
    ),
  );
}

class CoverScanner extends StatefulWidget {
  const CoverScanner({super.key, required this.photo});

  final Uint8List photo;

  @override
  State<CoverScanner> createState() => _CoverScannerState();
}

class _CoverScannerState extends State<CoverScanner> {
  /// Bốn góc theo toạ độ chuẩn hoá của ảnh (0..1): trên-trái, trên-phải, dưới-phải, dưới-trái.
  static const _initial = [
    Offset(0.14, 0.08),
    Offset(0.86, 0.08),
    Offset(0.86, 0.92),
    Offset(0.14, 0.92),
  ];

  ui.Image? _image;
  var _corners = [..._initial];
  var _busy = false;

  @override
  void initState() {
    super.initState();
    ui.decodeImageFromList(widget.photo, (img) {
      if (mounted) setState(() => _image = img);
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _use() async {
    final img = _image;
    if (img == null) return;
    setState(() => _busy = true);
    final size = Offset(img.width.toDouble(), img.height.toDouble());
    final q = [
      for (final c in _corners) Offset(c.dx * size.dx, c.dy * size.dy),
    ];
    final bytes = await warpCover(img, q);
    if (mounted) Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final c = context.appColors;
    final img = _image;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.coverScanTitle, style: text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.coverScanHint,
            style: text.bodySmall?.copyWith(color: c.secondaryText),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: img == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, box) {
                      // Khung ảnh nằm giữa vùng, giữ tỉ lệ.
                      final scale = (box.maxWidth / img.width).clamp(
                        0.0,
                        box.maxHeight / img.height,
                      );
                      final w = img.width * scale, h = img.height * scale;
                      final rect = Rect.fromLTWH(
                        (box.maxWidth - w) / 2,
                        (box.maxHeight - h) / 2,
                        w,
                        h,
                      );
                      Offset toScreen(Offset n) =>
                          rect.topLeft + Offset(n.dx * w, n.dy * h);
                      return Stack(
                        children: [
                          Positioned.fromRect(
                            rect: rect,
                            child: Image.memory(
                              widget.photo,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _QuadPainter([
                                  for (final n in _corners) toScreen(n),
                                ], rect),
                              ),
                            ),
                          ),
                          for (var i = 0; i < 4; i++)
                            Positioned(
                              left: toScreen(_corners[i]).dx - 24,
                              top: toScreen(_corners[i]).dy - 24,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (d) {
                                  final p = toScreen(_corners[i]) + d.delta;
                                  setState(() {
                                    _corners[i] = Offset(
                                      ((p.dx - rect.left) / w).clamp(0.0, 1.0),
                                      ((p.dy - rect.top) / h).clamp(0.0, 1.0),
                                    );
                                  });
                                },
                                child: SizedBox.square(
                                  dimension: 48,
                                  child: Center(
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: c.tint,
                                        border: Border.all(
                                          color: CoverPalette.onHero,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _corners = [..._initial]),
                child: Text(l10n.coverReset),
              ),
              const Spacer(),
              FilledButton(
                onPressed: img == null || _busy ? null : _use,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.coverUse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Làm tối phần ngoài tứ giác và vẽ viền tứ giác.
class _QuadPainter extends CustomPainter {
  _QuadPainter(this.points, this.image);

  final List<Offset> points;
  final Rect image;

  @override
  void paint(Canvas canvas, Size size) {
    final quad = Path()..addPolygon(points, true);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(image),
      quad,
    );
    canvas
      ..drawPath(
        outside,
        Paint()..color = CoverPalette.scrim.withValues(alpha: 0.5),
      )
      ..drawPath(
        quad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = CoverPalette.onHero,
      );
  }

  @override
  bool shouldRepaint(_QuadPainter old) =>
      old.points != points || old.image != image;
}
