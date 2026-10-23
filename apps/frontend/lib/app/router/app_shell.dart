import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/router/sidebar.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/cart/presentation/providers/cart_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Khung app người dùng theo style Liquid Glass.
/// - Desktop/tablet: sidebar kính nổi bên trái (Khám phá · Của tôi · Kệ sách, người dùng ở đáy).
/// - Điện thoại: tab bar kính nổi ở đáy (4 nhánh theo SRS 11.2) + nút tìm kiếm tròn.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int i) => navigationShell.goBranch(
    i,
    initialLocation: i == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.windowSize.isCompact) {
      return Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: _TabBar(
          index: navigationShell.currentIndex,
          onSelect: _goBranch,
        ),
      );
    }
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(onBranch: _goBranch),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ───────────────────────── Sidebar (desktop) ─────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.onBranch});

  final ValueChanged<int> onBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loc = GoRouterState.of(context).uri.toString();
    final session = ref.watch(sessionControllerProvider);
    final cart = session.isSignedIn ? ref.watch(cartCountProvider) : 0;
    final unread = session.isSignedIn ? ref.watch(unreadCountProvider) : 0;
    final shelves =
        ref
            .watch(categoriesProvider)
            .value
            ?.where((c) => c.parentId == null)
            .take(8)
            .toList() ??
        const [];

    bool under(String p) =>
        loc == p || loc.startsWith('$p/') || loc.startsWith('$p?');
    final onHome =
        under(Routes.home) && !under(Routes.search) && !under(Routes.cart);

    return SidebarPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 14, 14),
            child: Text(
              l10n.appTitle,
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                SidebarItem(
                  Icons.search_rounded,
                  l10n.search,
                  selected: under(Routes.search),
                  onTap: () => context.go(Routes.search),
                ),
                SidebarItem(
                  Icons.home_outlined,
                  l10n.navHome,
                  selected: onHome,
                  onTap: () => onBranch(0),
                ),
                SidebarItem(
                  Icons.gavel_rounded,
                  l10n.navAuctions,
                  selected: under(Routes.auctions) && !under(Routes.myAuctions),
                  onTap: () => onBranch(1),
                ),
                SidebarItem(
                  Icons.notifications_none_rounded,
                  l10n.navNotifications,
                  selected: under(Routes.notifications),
                  count: unread,
                  onTap: () => onBranch(2),
                ),
                SidebarItem(
                  Icons.shopping_bag_outlined,
                  l10n.navCart,
                  selected: under(Routes.cart),
                  count: cart,
                  onTap: () => context.go(Routes.cart),
                ),
                SidebarHeading(l10n.sidebarMine),
                SidebarItem(
                  Icons.receipt_long_outlined,
                  l10n.myOrders,
                  selected: under(Routes.orders),
                  onTap: () => context.go(Routes.orders),
                ),
                SidebarItem(
                  Icons.timer_outlined,
                  l10n.myAuctions,
                  selected: under(Routes.myAuctions),
                  onTap: () => context.go(Routes.myAuctions),
                ),
                SidebarItem(
                  Icons.account_balance_wallet_outlined,
                  l10n.wallet,
                  selected: under(Routes.wallet),
                  onTap: () => context.go(Routes.wallet),
                ),
                SidebarItem(
                  Icons.storefront_outlined,
                  l10n.sellerHub,
                  selected: under(Routes.seller),
                  onTap: () => context.go(Routes.seller),
                ),
                SidebarItem(
                  Icons.inventory_2_outlined,
                  l10n.myConsignments,
                  selected: under(Routes.consignments),
                  onTap: () => context.go(Routes.consignments),
                ),
                if (shelves.isNotEmpty) SidebarHeading(l10n.sidebarShelves),
                for (final c in shelves)
                  SidebarItem(
                    Icons.format_list_bulleted_rounded,
                    c.name,
                    selected: loc.contains('category=${c.id}'),
                    onTap: () => context.go(
                      Uri(
                        path: Routes.search,
                        queryParameters: {'category': c.id},
                      ).toString(),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: session.isSignedIn
                ? SidebarItem.user(
                    context,
                    name: session.user!.fullName,
                    selected:
                        under(Routes.account) &&
                        !under(Routes.orders) &&
                        !under(Routes.wallet) &&
                        !under(Routes.seller) &&
                        !under(Routes.consignments),
                    onTap: () => onBranch(3),
                  )
                : FilledButton(
                    onPressed: () => context.go(Routes.login),
                    child: Text(l10n.login),
                  ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Tab bar nổi (mobile) ─────────────────────────

class _TabBar extends ConsumerWidget {
  const _TabBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final signedIn = ref.watch(sessionControllerProvider).isSignedIn;
    final unread = signedIn ? ref.watch(unreadCountProvider) : 0;
    final tabs = [
      (Icons.home_rounded, l10n.navHome, 0),
      (Icons.gavel_rounded, l10n.navAuctions, 0),
      (Icons.notifications_rounded, l10n.navNotifications, unread),
      (Icons.person_rounded, l10n.navAccount, 0),
    ];

    // Kiểu iOS 26: viên kính chứa 4 tab + nút tìm kiếm tròn tách riêng.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 64,
                child: Glass(
                  borderRadius: AppRadius.chip,
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _Tab(
                            icon: tabs[i].$1,
                            label: tabs[i].$2,
                            badge: tabs[i].$3,
                            selected: i == index,
                            onTap: () => onSelect(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox.square(
              dimension: 64,
              child: Glass.circle(
                onTap: () => context.go(Routes.search),
                child: Center(
                  child: Icon(
                    Icons.search_rounded,
                    size: 26,
                    semanticLabel: l10n.search,
                    color: c.secondaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        // Tab đang chọn: "thấu kính" sáng nổi lên trong viên kính, chữ và biểu tượng đen.
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
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: c.live,
                child: Icon(
                  icon,
                  size: 24,
                  color: selected ? context.colors.onSurface : c.secondaryText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
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
