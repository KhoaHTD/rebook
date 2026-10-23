import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Thẻ phẳng của giao diện quản trị: nền trắng, viền xám nhạt ([dark] = thẻ đen nổi bật).
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.dark = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(14));
    return Material(
      color: dark ? AdminPalette.ink : AdminPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: dark
            ? BorderSide.none
            : const BorderSide(color: AdminPalette.line),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(borderRadius: radius),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Ô số liệu của dashboard: nhãn nhỏ, số lớn, dòng ghi chú.
class AdminKpi extends StatelessWidget {
  const AdminKpi({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.noteColor = AdminPalette.muted,
    this.onTap,
  });

  final String label;
  final String value;
  final String? note;
  final Color noteColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: AdminPalette.muted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: text.headlineSmall?.copyWith(
                fontFamily: null,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: noteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
