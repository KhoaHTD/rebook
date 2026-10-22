import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Sidebar kính tràn hết chiều cao màn hình, sát mép trái (như Apple Books / Music trên macOS),
/// ngăn với nội dung bằng một đường kẻ sáng mảnh. Dùng chung cho app người dùng và web quản trị.
class SidebarPanel extends StatelessWidget {
  const SidebarPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      width: 268,
      child: ClipRect(
        child: BackdropFilter(
          filter: Glass.filter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.glassTop, c.glassBottom],
              ),
              border: Border(right: BorderSide(color: c.glassBorder)),
            ),
            child: SafeArea(right: false, child: child),
          ),
        ),
      ),
    );
  }
}

class SidebarHeading extends StatelessWidget {
  const SidebarHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
    child: Text(
      text,
      style: context.textStyles.labelMedium?.copyWith(
        color: context.appColors.tertiaryText,
        fontWeight: FontWeight.w600,
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
    // Mục đang chọn: viên kính ánh xanh, chữ và biểu tượng màu nhấn.
    final fg = selected ? c.tint : context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? c.tintSoft : Colors.transparent,
        shape: StadiumBorder(
          side: selected
              ? BorderSide(color: c.tint.withValues(alpha: 0.22), width: 0.5)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
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
                      fontWeight: selected || leading != null
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: context.textStyles.labelMedium?.copyWith(
                      color: c.secondaryText,
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
