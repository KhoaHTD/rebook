import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Khung sidebar nổi bo góc dùng chung cho app người dùng và web quản trị.
class SidebarPanel extends StatelessWidget {
  const SidebarPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appColors.sidebar,
        borderRadius: AppRadius.sidebar,
        border: Border.all(
          color: context.appColors.separator.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );
  }
}

class SidebarHeading extends StatelessWidget {
  const SidebarHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
    child: Text(
      text,
      style: context.textStyles.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class SidebarItem extends StatelessWidget {
  const SidebarItem(
    this.icon,
    this.label, {
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.leading,
    super.key,
  });

  /// Mục người dùng ở đáy sidebar: ảnh đại diện tròn + tên.
  factory SidebarItem.user(
    BuildContext context, {
    required String name,
    required bool selected,
    required VoidCallback onTap,
  }) => SidebarItem(
    Icons.person,
    name,
    selected: selected,
    onTap: onTap,
    leading: CircleAvatar(
      radius: 15,
      backgroundColor: context.appColors.fill,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: context.textStyles.labelLarge,
      ),
    ),
  );

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fg = selected ? c.onSelected : context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? c.selected : Colors.transparent,
        borderRadius: AppRadius.item,
        child: InkWell(
          borderRadius: AppRadius.item,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: leading == null ? 7 : 6,
            ),
            child: Row(
              children: [
                leading ??
                    Icon(
                      icon,
                      size: 18,
                      color: selected ? fg : c.secondaryText,
                    ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: leading == null ? null : FontWeight.w600,
                    ),
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: context.textStyles.labelMedium?.copyWith(
                      color: selected ? fg : c.secondaryText,
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
