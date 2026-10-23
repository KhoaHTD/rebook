import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/admin_scope.dart';

/// Kính lỏng (Liquid Glass): làm mờ + tăng bão hòa phần phía sau, phủ dải trắng trong,
/// viền sáng mảnh, vệt phản chiếu phía trên và bóng mềm.
///
/// [blur] = false → kính "trong" không làm mờ (rẻ hơn): dùng cho khối nằm trong danh sách cuộn.
/// Làm mờ chỉ dành cho phần nổi: sidebar, tab bar, thanh đầu trang, thanh mua hàng, nút tròn.
/// Web trên điện thoại (Safari iOS, Chrome Android): làm mờ nền phía sau từng khối kính rất nặng
/// với CanvasKit nên chỉ giữ ở thanh nổi (tab bar, thanh đầu trang, sidebar); khối kính trong
/// danh sách chỉ còn lớp phủ trong suốt — nhìn gần như y hệt nhưng cuộn mượt.
bool get lightEffects =>
    kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.card,
    this.padding,
    this.blur = true,
    this.shadow = true,
    this.tint,
    this.clear = false,
    this.onTap,
  });

  /// Nút tròn bằng kính (quay lại, ···, giỏ hàng…).
  const Glass.circle({
    super.key,
    required this.child,
    this.blur = true,
    this.shadow = true,
    this.tint,
    this.clear = false,
    this.onTap,
  }) : borderRadius = AppRadius.chip,
       padding = null;

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool blur;
  final bool shadow;

  /// Kính nhuộm màu (vd. màu nhấn cho nút chính, đỏ cho LIVE).
  final Color? tint;

  /// Kính rất trong — đặt trên nền tối / ảnh (chữ trắng phía trên).
  final bool clear;
  final VoidCallback? onTap;

  /// Làm mờ + tăng bão hoà phía sau kính (dùng chung cho sidebar / thanh đầu trang).
  static final filter = ui.ImageFilter.compose(
    outer: const ColorFilter.matrix(_saturate),
    inner: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
  );

  /// Tăng bão hòa 1.8 lần cho màu phía sau kính.
  static const _saturate = <double>[
    1.6296, -0.5724, -0.0572, 0, 0, //
    -0.1704, 1.2276, -0.0572, 0, 0, //
    -0.1704, -0.5724, 1.7428, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    if (AdminScope.active(context)) return _flat(context);
    final c = context.appColors;
    final (top, bottom) = switch ((tint, clear)) {
      (final t?, _) => (t.withValues(alpha: 0.78), t.withValues(alpha: 0.62)),
      (null, true) => (
        c.onSelected.withValues(alpha: 0.26),
        c.onSelected.withValues(alpha: 0.08),
      ),
      _ => (c.glassTop, c.glassBottom),
    };

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        border: Border.all(color: c.glassBorder),
      ),
      // Vệt phản chiếu: sáng ở mép trên, tắt dần xuống giữa.
      position: DecorationPosition.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              c.glassBorder.withValues(alpha: 0.35),
              c.glassBorder.withValues(alpha: 0),
            ],
          ),
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
    if (onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: borderRadius, onTap: onTap, child: body),
      );
    }
    if (blur && !lightEffects) {
      body = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(filter: filter, child: body),
      );
    }
    if (!shadow) return body;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: c.glassShadow,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: body,
    );
  }
}

/// Khối phẳng của giao diện quản trị: nền trắng, viền xám nhạt, không bóng.
extension on Glass {
  Widget _flat(BuildContext context) {
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? AdminPalette.card,
        borderRadius: borderRadius,
        border: tint == null ? Border.all(color: AdminPalette.line) : null,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: borderRadius, onTap: onTap, child: body),
      );
    }
    return body;
  }
}

/// Nền màu loang phía sau kính. Vị trí các vệt màu tính theo **toạ độ màn hình**,
/// nên nền trong khung app và nền trong từng trang khớp nhau tuyệt đối —
/// trang vẫn đặc (không lộ trang cũ khi chuyển trang) mà nhìn như một nền liền.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _Ambient(
      screen: MediaQuery.sizeOf(context),
      base: c.background,
      blobs: dark ? AmbientPalette.dark : AmbientPalette.light,
      child: child,
    );
  }
}

class _Ambient extends SingleChildRenderObjectWidget {
  const _Ambient({
    required this.screen,
    required this.base,
    required this.blobs,
    super.child,
  });

  final Size screen;
  final Color base;
  final List<(Color, Alignment, double)> blobs;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAmbient(screen, base, blobs);

  @override
  void updateRenderObject(BuildContext context, _RenderAmbient r) => r
    ..screen = screen
    ..base = base
    ..blobs = blobs;
}

class _RenderAmbient extends RenderProxyBox {
  _RenderAmbient(this._screen, this._base, this._blobs);

  Size _screen;
  Color _base;
  List<(Color, Alignment, double)> _blobs;

  set screen(Size v) {
    if (v == _screen) return;
    _screen = v;
    markNeedsPaint();
  }

  set base(Color v) {
    if (v == _base) return;
    _base = v;
    markNeedsPaint();
  }

  set blobs(List<(Color, Alignment, double)> v) {
    if (identical(v, _blobs)) return;
    _blobs = v;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final rect = offset & size;
    canvas
      ..save()
      ..clipRect(rect)
      ..drawRect(rect, Paint()..color = _base);
    // Gốc màn hình trong hệ toạ độ cục bộ.
    final origin = offset - localToGlobal(Offset.zero);
    final screenRect = origin & _screen;
    final shortest = _screen.shortestSide;
    for (final (color, at, r) in _blobs) {
      final center = at.withinRect(screenRect);
      final radius = shortest * r;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
    canvas.restore();
    super.paint(context, offset);
  }
}
