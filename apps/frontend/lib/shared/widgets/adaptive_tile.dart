import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Dòng danh sách có cụm nút / nhãn bên phải: đủ rộng thì như [ListTile], hẹp (điện thoại) thì cụm bên phải
/// xuống dưới tiêu đề thay vì ép tiêu đề thành từng chữ một.
class AdaptiveTile extends StatelessWidget {
  const AdaptiveTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.breakpoint = 620,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Dưới bề rộng này cụm [trailing] xuống dòng riêng.
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= breakpoint || trailing == null) {
          return ListTile(
            onTap: onTap,
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          );
        }
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle.merge(
                            style: Theme.of(context).textTheme.bodyLarge,
                            child: title,
                          ),
                          if (subtitle != null)
                            DefaultTextStyle.merge(
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.appColors.secondaryText,
                                  ),
                              child: subtitle!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            ),
          ),
        );
      },
    );
  }
}
