import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Khối "Liquid Glass": làm mờ nội dung phía sau, phủ màu kính, viền sáng mảnh, đổ bóng nhẹ.
/// Dùng cho thanh tab nổi, ô tìm kiếm dưới đáy, nút tròn nổi trên ảnh.
///
/// [onDark] = true khi đặt trên nền tối (phòng đấu giá, đầu trang lô).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.pill,
    this.onDark = false,
    this.padding,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool onDark;
  final EdgeInsetsGeometry? padding;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow && !onDark
            ? [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSizes.blur,
            sigmaY: AppSizes.blur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: onDark ? colors.glassOnDark : colors.glass,
              borderRadius: borderRadius,
              border: Border.all(color: colors.separator, width: 0.5),
            ),
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}

/// Nút tròn kính (quay lại, chia sẻ, thu nhỏ phòng...). Luôn có [tooltip] cho trình đọc màn hình.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onDark = false,
    this.size = AppSizes.touch,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? context.appColors.onDark : context.colors.onSurface;
    return GlassSurface(
      onDark: onDark,
      child: SizedBox.square(
        dimension: size,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
  }
}
