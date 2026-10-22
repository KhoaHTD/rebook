import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Nhóm danh sách kiểu iOS (inset grouped): tiêu đề nhỏ phía trên, ô bo 24, đường kẻ thụt lề,
/// chú thích phía dưới.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.background,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;

  /// Mặc định: ô trắng trên nền nhóm xám. Trên nền trắng truyền `groupedBackground`.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final caption = context.textStyles.bodySmall?.copyWith(
      color: colors.labelTertiary,
      height: 1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs + AppSpacing.xxs,
            ),
            child: Text(header!, style: caption),
          ),
        ClipRRect(
          borderRadius: AppRadius.group,
          child: ColoredBox(
            color: background ?? colors.groupedCell,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, child) in children.indexed) ...[
                  child,
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: Divider(color: colors.separator),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs + AppSpacing.xxs,
              AppSpacing.md,
              0,
            ),
            child: Text(footer!, style: caption),
          ),
      ],
    );
  }
}

/// Một dòng trong [GroupedSection]: [leading] tuỳ chọn, tiêu đề + phụ đề, [trailing] bên phải.
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.emphasized = false,
    this.minHeight = 48,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Giá trị bên phải màu xám (vd "500.000đ").
  final String? trailingText;
  final VoidCallback? onTap;

  /// Dòng tổng: chữ đậm hơn, cao hơn.
  final bool emphasized;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleStyle = context.textStyles.bodyLarge?.copyWith(
      fontWeight: emphasized ? FontWeight.w600 : null,
    );
    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: emphasized ? minHeight + 8 : minHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xxs,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: titleStyle),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(
                        subtitle!,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.labelTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: emphasized
                    ? context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )
                    : context.textStyles.bodyLarge?.copyWith(
                        color: colors.labelTertiary,
                      ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Ô vuông màu bo góc chứa icon trắng — dùng làm `leading` của [GroupedRow].
class RowIcon extends StatelessWidget {
  const RowIcon({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Icon(icon, size: 18, color: context.appColors.onDark),
    );
  }
}
