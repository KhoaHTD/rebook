import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/glass_tab_bar.dart';
import 'package:book_marketplace/app/router/mode_switch.dart';
import 'package:book_marketplace/app/router/nav_overlay.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/router/sidebar.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/cart/presentation/providers/cart_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';

/// Khung app người dùng theo style Liquid Glass: nội dung phủ hết màn hình, điều hướng là một nút kính
/// ở góc dưới (xem [NavOverlay]); bấm vào thì sidebar kính trượt ra (Khám phá · Của tôi · Kệ sách, người dùng ở đáy).
/// Đấu giá là một khu riêng với khung riêng (xem `auction_shell.dart`); công tắc [ModeSwitch] chuyển qua lại.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int i) => navigationShell.goBranch(
    i,
    initialLocation: i == navigationShell.currentIndex,
  );

  /// Trang gốc của từng mục: ở điện thoại chỉ ở đây mới hiện nút (trang con có nút quay lại và thanh mua hàng).
  static const _roots = {
    Routes.home,
    Routes.cart,
    Routes.notifications,
    Routes.account,
  };

  IconData _icon(String loc) {
    if (loc == Routes.cart || loc.startsWith('${Routes.cart}/')) {
      return Icons.shopping_bag_rounded;
    }
    return switch (navigationShell.currentIndex) {
      1 => Icons.notifications_rounded,
      2 => Icons.person_rounded,
      _ => Icons.home_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: NavOverlay(
        icon: _icon(loc),
        showButton: !context.windowSize.isCompact || _roots.contains(loc),
        panel: _Sidebar(onBranch: _goBranch),
        bar: _TabBar(index: navigationShell.currentIndex, onSelect: _goBranch),
        child: navigationShell,
      ),
    );
  }
}

// ───────────────────────── Sidebar (trượt ra từ nút điều hướng) ─────────────────────────

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
            padding: const EdgeInsets.fromLTRB(22, 22, 14, 10),
            child: Text(
              l10n.appTitle,
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: ModeSwitch(mode: AppMode.books),
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
                  Icons.notifications_none_rounded,
                  l10n.navNotifications,
                  selected: under(Routes.notifications),
                  count: unread,
                  onTap: () => onBranch(1),
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
                    onTap: () => onBranch(2),
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

// ───────────────────────── Tab bar nổi (điện thoại, nở ra từ nút) ─────────────────────────

class _TabBar extends ConsumerWidget {
  const _TabBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final signedIn = ref.watch(sessionControllerProvider).isSignedIn;
    final unread = signedIn ? ref.watch(unreadCountProvider) : 0;
    final cart = signedIn ? ref.watch(cartCountProvider) : 0;
    final loc = GoRouterState.of(context).uri.path;
    // Giỏ hàng là route con của nhánh Mua sách nên tab này chọn theo địa chỉ, không theo nhánh.
    final inCart = loc == Routes.cart || loc.startsWith('${Routes.cart}/');
    return GlassTabBar(
      items: [
        GlassTabItem(
          icon: Icons.home_rounded,
          label: l10n.navHome,
          selected: !inCart && index == 0,
          onTap: () => onSelect(0),
        ),
        GlassTabItem(
          icon: Icons.shopping_bag_rounded,
          label: l10n.navCart,
          badge: cart,
          selected: inCart,
          onTap: () => context.go(Routes.cart),
        ),
        GlassTabItem(
          icon: Icons.notifications_rounded,
          label: l10n.navNotifications,
          badge: unread,
          selected: index == 1,
          onTap: () => onSelect(1),
        ),
        GlassTabItem(
          icon: Icons.person_rounded,
          label: l10n.navAccount,
          selected: index == 2,
          onTap: () => onSelect(2),
        ),
      ],
    );
  }
}
