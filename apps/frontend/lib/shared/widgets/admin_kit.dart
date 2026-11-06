import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Thẻ của giao diện quản trị: nền trắng bo lớn, bóng rất nhẹ, không viền ([dark] = thẻ đen nổi bật).
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.dark = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AdminPalette.ink.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: dark ? AdminPalette.ink : AdminPalette.card,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Ô số liệu của dashboard: biểu tượng nhỏ, nhãn, số lớn, mức tăng giảm [trend] (0.12 = +12%) và ghi chú.
class AdminKpi extends StatelessWidget {
  const AdminKpi({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.noteColor = AdminPalette.muted,
    this.onTap,
    this.icon,
    this.trend,
  });

  final String label;
  final String value;
  final String? note;
  final Color noteColor;
  final VoidCallback? onTap;
  final IconData? icon;
  final double? trend;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final up = (trend ?? 0) >= 0;
    final trendColor = up ? AdminPalette.ok : AdminPalette.bad;
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AdminPalette.accentSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: AdminPalette.accent),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: AdminPalette.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: text.headlineSmall?.copyWith(
                      fontFamily: null,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        up
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 11,
                        color: trendColor,
                      ),
                      Text(
                        '${(trend!.abs() * 100).round()}%',
                        style: text.labelSmall?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: noteColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
