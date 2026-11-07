import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Đánh dấu một widget (thường là bìa sách) là điểm xuất phát của hiệu ứng "sách bay vào giỏ"
/// ([CartFly.play]). Tìm theo [token] (vd. id tin đăng), không dùng GlobalKey nên hai trang cùng lúc cũng không đụng nhau.
class FlightSource extends StatefulWidget {
  const FlightSource({super.key, required this.token, required this.child});

  final Object token;
  final Widget child;

  @override
  State<FlightSource> createState() => _FlightSourceState();
}

class _FlightSourceState extends State<FlightSource> {
  @override
  void initState() {
    super.initState();
    _FlightRegistry.live[widget.token] = context;
  }

  @override
  void didUpdateWidget(FlightSource old) {
    super.didUpdateWidget(old);
    if (old.token != widget.token) {
      _FlightRegistry.forget(old.token, context);
      _FlightRegistry.live[widget.token] = context;
    }
  }

  @override
  void dispose() {
    _FlightRegistry.forget(widget.token, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

abstract final class _FlightRegistry {
  static final live = <Object, BuildContext>{};

  static void forget(Object token, BuildContext context) {
    if (live[token] == context) live.remove(token);
  }

  /// Hình chữ nhật (toạ độ màn hình) của widget xuất phát, null nếu không còn trên màn.
  static Rect? rectOf(Object token) {
    final c = live[token];
    if (c == null || !c.mounted) return null;
    final box = c.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// Hiệu ứng thêm vào giỏ: bìa sách bay theo đường cong tới một bong bóng giỏ hàng nhô lên ở góc nút điều hướng,
/// bong bóng nảy lên rồi tắt dần. Bấm vào bong bóng thì mở giỏ ([onTap]).
abstract final class CartFly {
  static const _duration = Duration(milliseconds: 1500);
  static const _bubble = 52.0;
  static const _margin = 18.0;

  static void play(
    BuildContext context, {
    required Object token,
    required Widget Function(Size size) cover,
    required bool onRight,
    required double bottomInset,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final media = MediaQuery.of(context);
    final from =
        _FlightRegistry.rectOf(token) ??
        Rect.fromCenter(
          center: Offset(media.size.width / 2, media.size.height / 2),
          width: 120,
          height: 180,
        );
    final target = Offset(
      onRight
          ? media.size.width - _margin - _bubble / 2
          : _margin + _bubble / 2,
      media.size.height - media.padding.bottom - bottomInset - _bubble / 2,
    );
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Flight(
        from: from,
        target: target,
        cover: cover(from.size),
        onTap: onTap,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Flight extends StatefulWidget {
  const _Flight({
    required this.from,
    required this.target,
    required this.cover,
    required this.onDone,
    this.onTap,
  });

  final Rect from;
  final Offset target;
  final Widget cover;
  final VoidCallback onDone;
  final VoidCallback? onTap;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CartFly._duration,
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Điểm trên đường cong bậc hai từ [a] qua [ctrl] tới [b] tại [t].
  static Offset _bezier(Offset a, Offset ctrl, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + ctrl * (2 * u * t) + b * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final start = widget.from.center;
    final end = widget.target;
    final ctrl = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - 90,
    );
    final endScale = 30 / math.max(1.0, widget.from.width);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        // Bong bóng: nhô lên (0–0.18), nảy khi sách tới (0.55–0.7), tắt dần (0.88–1).
        final appear = Curves.easeOutBack.transform((t / 0.18).clamp(0.0, 1.0));
        final bump = t < 0.55 || t > 0.7
            ? 0.0
            : math.sin(math.pi * (t - 0.55) / 0.15);
        final fade = t < 0.88 ? 1.0 : 1 - (t - 0.88) / 0.12;
        final bubbleScale = appear * (1 + 0.28 * bump);

        // Sách: rời chỗ cũ (0.06), tới bong bóng (0.62), nhỏ dần.
        final p = Curves.easeInCubic.transform(
          ((t - 0.06) / 0.56).clamp(0.0, 1.0),
        );
        final pos = _bezier(start, ctrl, end, p);
        final flying = t >= 0.06 && t < 0.62;
        final scale = 1 + (endScale - 1) * p;

        // expand: phủ kín màn để vùng bấm của bong bóng nằm trong hộp của chính Stack.
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            if (flying)
              Positioned(
                left: pos.dx - widget.from.width / 2,
                top: pos.dy - widget.from.height / 2,
                width: widget.from.width,
                height: widget.from.height,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 1 - 0.3 * p,
                    child: Transform.scale(scale: scale, child: widget.cover),
                  ),
                ),
              ),
            Positioned(
              left: widget.target.dx - CartFly._bubble / 2,
              top: widget.target.dy - CartFly._bubble / 2,
              width: CartFly._bubble,
              height: CartFly._bubble,
              child: Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: bubbleScale,
                  child: Semantics(
                    button: true,
                    label: l10n.viewCart,
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: Material(
                        type: MaterialType.circle,
                        color: c.onSurface,
                        elevation: 6,
                        child: Center(
                          child: Badge(
                            isLabelVisible: t > 0.6,
                            label: const Text('+1'),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              color: c.surface,
                              size: 24,
                            ),
                          ),
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
    );
  }
}
