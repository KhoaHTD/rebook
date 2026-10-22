import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/live_auction_accessory.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Khung điều hướng chính.
///
/// Điện thoại: thanh tab là viên thuốc kính nổi trên nội dung, nút Tìm kiếm tách riêng
/// thành vòng tròn bên phải, phía trên là thanh "đang đấu giá" khi có lô đang chạy.
/// Tablet / web: NavigationRail bên trái.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // (icon, icon đang chọn, nhãn, hành động). Đăng bán mở sheet thay vì đổi tab.
    final items = <(IconData, IconData, String, VoidCallback, int?)>[
      (
        Icons.home_outlined,
        Icons.home_rounded,
        l10n.navHome,
        () => _onBranch(0),
        0,
      ),
      (
        Icons.gavel_outlined,
        Icons.gavel_rounded,
        l10n.navAuctions,
        () => _onBranch(1),
        1,
      ),
      (
        Icons.add_circle_outline_rounded,
        Icons.add_circle_rounded,
        l10n.navSell,
        () => context.push(Routes.sell),
        null,
      ),
      (
        Icons.person_outline_rounded,
        Icons.person_rounded,
        l10n.navProfile,
        () => _onBranch(2),
        2,
      ),
    ];

    if (!context.windowSize.isCompact) {
      return _RailShell(navigationShell: navigationShell, items: items);
    }

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LiveAuctionAccessory(),
            SizedBox(
              height: AppSizes.tabBarHeight,
              child: Row(
                children: [
                  Expanded(
                    child: GlassSurface(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          for (final (icon, selectedIcon, label, onTap, branch)
                              in items)
                            Expanded(
                              child: _TabItem(
                                icon: icon,
                                selectedIcon: selectedIcon,
                                label: label,
                                selected:
                                    branch == navigationShell.currentIndex,
                                onTap: onTap,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GlassIconButton(
                    icon: Icons.search_rounded,
                    tooltip: l10n.searchTitle,
                    size: AppSizes.tabBarHeight,
                    onPressed: () => context.push(Routes.search),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = selected ? context.colors.primary : context.colors.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.fill : colors.fill.withValues(alpha: 0),
        borderRadius: AppRadius.pill,
        child: InkWell(
          borderRadius: AppRadius.pill,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, size: 24, color: fg),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  color: fg,
                  fontSize: 10,
                  letterSpacing: 0,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({required this.navigationShell, required this.items});

  final StatefulNavigationShell navigationShell;
  final List<(IconData, IconData, String, VoidCallback, int?)> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final branches = items.where((i) => i.$5 != null).toList();
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => branches[i].$4(),
            extended: context.windowSize == WindowSize.expanded,
            labelType: context.windowSize == WindowSize.expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'rail-sell',
                    tooltip: l10n.navSell,
                    onPressed: () => context.push(Routes.sell),
                    child: const Icon(Icons.add_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.searchTitle,
                    onPressed: () => context.push(Routes.search),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
            destinations: [
              for (final (icon, selected, label, _, _) in branches)
                NavigationRailDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selected),
                  label: Text(label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Stack(
              children: [
                navigationShell,
                const Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  width: 420,
                  child: LiveAuctionAccessory(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
