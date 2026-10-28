import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Sidebar kính tràn hết chiều cao màn hình, sát mép trái (như Apple Books / Music trên macOS),
/// ngăn với nội dung bằng một đường kẻ sáng mảnh. Dùng chung cho app người dùng và web quản trị.
class SidebarPanel extends StatelessWidget {
  const SidebarPanel({super.key, required this.child});

  final Widget child;

  /// Bề rộng sidebar; nội dung trang chừa đúng bằng này ở mép trái (xem `ShellInset`).
  static const width = 268.0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      width: width,
      child: ClipRect(
        child: BackdropFilter(
          filter: Glass.filter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Nền app trắng nên kính cần thêm lớp xám nhạt để còn nhìn thấy khung.
                colors: [
                  Color.alphaBlend(c.fill, c.glassTop),
                  Color.alphaBlend(c.fill, c.glassBottom),
                ],
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
    // Mục đang chọn: viên đặc màu đen (sáng thì đen chữ trắng, tối thì ngược lại).
    final fg = selected ? context.colors.surface : context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? context.colors.onSurface : Colors.transparent,
        shape: const StadiumBorder(),
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
