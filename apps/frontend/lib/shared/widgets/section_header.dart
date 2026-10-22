import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Tiêu đề mục kiểu App Store: chữ 22 đậm, có mũi tên khi bấm được.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onTap,
    this.action,
  });

  final String title;
  final VoidCallback? onTap;

  /// Liên kết bên phải (vd "Xem 6 ảnh").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: context.textStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            color: context.appColors.labelTertiary,
          ),
      ],
    );
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: onTap == null
                ? heading
                : InkWell(
                    onTap: onTap,
                    borderRadius: AppRadius.chip,
                    child: heading,
                  ),
          ),
        ),
        ?action,
      ],
    );
  }
}
