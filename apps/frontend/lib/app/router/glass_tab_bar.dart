import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Một tab trên thanh tab kính.
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

/// Trạng thái thanh điều hướng do `NavOverlay` giữ và đưa cho thanh vẽ ra.
class NavBarState {
  const NavBarState({
    required this.open,
    required this.onRight,
    required this.icon,
    required this.toggle,
    required this.close,
  });

  final bool open;

  /// Nút nằm sát mép phải (thanh xổ sang trái).
  final bool onRight;

  /// Biểu tượng của mục đang đứng, hiện trên nút khi thanh đang thu.
  final IconData icon;
  final VoidCallback toggle;
  final VoidCallback close;
}

/// Thanh điều hướng kính nằm ngang, **xổ ra từ chính nút**: lúc thu là một viên tròn mang biểu tượng của mục
/// đang đứng; bấm vào thì viên kính giãn ngang sang bên kia, và ô đầu tiên nằm đúng chỗ của nút. Dùng chung
/// cho khu mua sách và khu đấu giá ([solidSelected]: tab đang chọn là viên đặc thay cho "thấu kính" sáng).
class ExpandingTabBar extends StatelessWidget {
  const ExpandingTabBar({
    super.key,
    required this.items,
    required this.state,
    this.solidSelected = false,
  });

  final List<GlassTabItem> items;
  final NavBarState state;
  final bool solidSelected;

  /// Chiều cao cả thanh.
  static const height = 68.0;

  /// Khoảng đệm giữa viên kính và các ô bên trong.
  static const pad = 5.0;

  /// Lề hai bên của thanh so với mép màn hình: thanh phủ hết bề ngang trừ hai lề này, như thanh tab của Apple.
  static const sideMargin = 16.0;

  /// Đường kính của nút khi thanh thu lại = chiều cao của một ô icon (viên chọn của ô đang chọn cũng cao bằng).
  static const button = height - pad * 2;

  /// Bề rộng thanh khi mở, theo bề ngang màn hình.
  static double fullWidth(double screenWidth) => screenWidth - sideMargin * 2;

  @override
  Widget build(BuildContext context) {
    final full = fullWidth(MediaQuery.sizeOf(context).width);
    // Các ô chia đều bề ngang còn lại; nút nằm giữa ô đầu tiên (hoặc ô cuối khi nút ở bên phải).
    final cellW = (full - pad * 2) / items.length;
    final open = state.open;
    final onRight = state.onRight;
    // Nhiều tab trên màn hẹp làm ô nhỏ hơn nút → không để lề âm (AnimatedContainer sẽ báo lỗi).
    final inset = (pad + (cellW - button) / 2).clamp(0.0, double.infinity);
    return SizedBox(
      width: full,
      height: height,
      child: Align(
        alignment: onRight ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
          width: open ? full : button,
          height: open ? height : button,
          margin: EdgeInsets.only(
            left: !open && !onRight ? inset : 0,
            right: !open && onRight ? inset : 0,
          ),
          child: Glass(
            borderRadius: AppRadius.chip,
            padding: EdgeInsets.zero,
            // Material trong suốt nằm TRÊN nền kính, để viên tab đang chọn (Ink) vẽ lên trên lớp kính chứ không bị che.
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  // Lúc thu: biểu tượng của mục đang đứng, nằm ở tâm nút (cũng là tâm ô đầu tiên khi mở).
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: open,
                      child: AnimatedOpacity(
                        duration: AppDurations.fast,
                        opacity: open ? 0 : 1,
                        child: Semantics(
                          button: true,
                          label: context.l10n.navMenu,
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: state.toggle,
                            child: Center(
                              child: Icon(
                                state.icon,
                                size: 26,
                                color: context.colors.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Lúc mở: các ô tab, neo vào phía nút để thanh trông như giãn ra từ nút.
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !open,
                      child: AnimatedOpacity(
                        duration: AppDurations.fast,
                        opacity: open ? 1 : 0,
                        child: OverflowBox(
                          minWidth: 0,
                          maxWidth: full,
                          alignment: onRight
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: SizedBox(
                            width: full,
                            child: Padding(
                              padding: const EdgeInsets.all(pad),
                              child: Row(
                                children: [
                                  for (final item in items)
                                    SizedBox(
                                      width: cellW,
                                      child: _Tab(
                                        item: item,
                                        solid: solidSelected,
                                        onClose: state.close,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.solid, required this.onClose});

  final GlassTabItem item;
  final bool solid;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final selected = item.selected;
    final fg = selected
        ? (solid ? c.onSelected : context.colors.onSurface)
        : c.secondaryText;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          item.onTap();
          onClose();
        },
        // Tab đang chọn: "thấu kính" nổi lên trong viên kính (khu đấu giá: viên đặc).
        child: Ink(
          decoration: ShapeDecoration(
            color: selected
                ? (solid ? c.selected : c.tabBar)
                : Colors.transparent,
            shape: const StadiumBorder(),
            shadows: selected && !solid
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
                child: Icon(item.icon, size: 26, color: fg),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  color: fg,
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
