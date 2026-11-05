import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Khối xám nhấp nháy giữ chỗ cho nội dung đang tải (màn loading dạng khung xương).
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;

  /// Hình tròn đường kính [height].
  final bool circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = context.appColors.fill;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        width: widget.circle ? widget.height : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: fill.withValues(alpha: fill.a * (0.55 + 0.45 * _pulse.value)),
          borderRadius: widget.circle
              ? null
              : BorderRadius.circular(widget.radius),
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

/// Khung xương mặc định cho nội dung đang tải: các dòng gồm ô vuông và ba dòng chữ.
/// Không cuộn và tự cắt phần thừa, nên đặt được ở cả vùng nhỏ lẫn trong danh sách cuộn.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: box.hasBoundedWidth ? box.maxWidth : 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Skeleton(width: 64, height: 64, radius: 14),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(width: 150, height: 12),
                              SizedBox(height: AppSpacing.sm),
                              Skeleton(height: 10),
                              SizedBox(height: AppSpacing.sm),
                              Skeleton(width: 90, height: 10),
                            ],
                          ),
                        ),
                      ],
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

/// Khung xương của trang chủ: băng chuyền lớn và các kệ sách (3 sách / hàng trên điện thoại, 4 trên màn lớn).
class SkeletonHome extends StatelessWidget {
  const SkeletonHome({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width =
            (box.hasBoundedWidth ? box.maxWidth : 375) - padding.horizontal;
        final perRow = width < 600 ? 3 : 4;
        final poster = (width - AppSpacing.md * (perRow - 1)) / perRow;
        Widget shelf() => Row(
          children: [
            for (var i = 0; i < perRow; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: poster,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: poster * 1.4, radius: 10),
                    const SizedBox(height: AppSpacing.sm),
                    const Skeleton(height: 12),
                    const SizedBox(height: AppSpacing.sm),
                    Skeleton(width: poster * 0.6, height: 12),
                  ],
                ),
              ),
            ],
          ],
        );
        return ClipRect(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: 150, height: 28),
                const SizedBox(height: AppSpacing.lg),
                const Skeleton(height: 280, radius: 20),
                const SizedBox(height: AppSpacing.xl),
                const Skeleton(width: 110, height: 12),
                const SizedBox(height: AppSpacing.md),
                shelf(),
                const SizedBox(height: AppSpacing.xl),
                const Skeleton(width: 130, height: 12),
                const SizedBox(height: AppSpacing.md),
                shelf(),
              ],
            ),
          ),
        );
      },
    );
  }
}
