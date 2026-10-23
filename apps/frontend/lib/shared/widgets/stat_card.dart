import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Ô số liệu của kênh người bán: biểu tượng, nhãn, giá trị lớn.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget value;

  /// Cần người bán xử lý (vd. đơn chờ xác nhận) → biểu tượng màu cảnh báo.
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: c.sidebar,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: AppRadius.card,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: highlight ? c.warning : c.secondaryText,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  color: c.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              DefaultTextStyle.merge(
                style: context.textStyles.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lưới ô số liệu: 4 cột trên desktop, 2 cột trên mobile.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 720 ? 4 : 2;
        const gap = AppSpacing.md;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: w, child: child),
          ],
        );
      },
    );
  }
}
