import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Một tab trên thanh tab kính nổi.
class GlassTabItem {
  const GlassTabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Số đỏ nhỏ ở góc biểu tượng (0 = ẩn).
  final int badge;
}

/// Thanh tab kính nổi ở đáy điện thoại (kiểu iOS 26): một viên kính dài chứa các tab,
/// tab đang chọn là "thấu kính" sáng nổi lên. Dùng chung cho khu mua sách và khu đấu giá
/// (màu lấy từ theme nên mỗi khu có diện mạo riêng).
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.items});

  final List<GlassTabItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: SizedBox(
          height: 64,
          child: Glass(
            borderRadius: AppRadius.chip,
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (final item in items) Expanded(child: _Tab(item: item)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item});

  final GlassTabItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final selected = item.selected;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: item.onTap,
        // Tab đang chọn: "thấu kính" nổi lên trong viên kính.
        child: Ink(
          decoration: ShapeDecoration(
            color: selected ? c.tabBar : Colors.transparent,
            shape: const StadiumBorder(),
            shadows: selected
                ? [
                    BoxShadow(
                      color: c.glassShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: item.badge > 0,
                label: Text('${item.badge}'),
                backgroundColor: c.live,
                child: Icon(
                  item.icon,
                  size: 24,
                  color: selected ? context.colors.onSurface : c.secondaryText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  color: selected ? context.colors.onSurface : c.secondaryText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
