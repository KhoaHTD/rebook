import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/router/sidebar.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';

/// Khung web quản trị: cùng sidebar style Apple Books với app người dùng.
/// Staff chỉ thấy nhóm Kho; Admin thấy thêm nhóm Quản trị.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(sessionControllerProvider).user;
    final isAdmin = user?.role == AuthRole.admin;

    bool under(String p) => p == AdminRoutes.dashboard
        ? location == p
        : (location == p || location.startsWith('$p/'));
    SidebarItem item(IconData icon, String label, String path) => SidebarItem(
      icon,
      label,
      selected: under(path),
      onTap: () => context.go(path),
    );

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SidebarPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 14, 14),
                  child: Text(
                    l10n.adminAppTitle,
                    style: context.textStyles.titleLarge?.copyWith(
                      fontFamily: AppFonts.serif,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      if (isAdmin)
                        item(
                          Icons.space_dashboard_outlined,
                          l10n.navDashboard,
                          AdminRoutes.dashboard,
                        ),
                      SidebarHeading(l10n.staffRole),
                      item(
                        Icons.inventory_2_outlined,
                        l10n.navConsignments,
                        AdminRoutes.consignments,
                      ),
                      item(
                        Icons.qr_code_scanner_rounded,
                        l10n.navAppointments,
                        AdminRoutes.appointments,
                      ),
                      item(
                        Icons.warehouse_outlined,
                        l10n.navWarehouse,
                        AdminRoutes.warehouse,
                      ),
                      item(
                        Icons.local_shipping_outlined,
                        l10n.navAuctionOrders,
                        AdminRoutes.auctionOrders,
                      ),
                      if (isAdmin) ...[
                        SidebarHeading(l10n.adminRole),
                        item(
                          Icons.gavel_rounded,
                          l10n.navSessions,
                          AdminRoutes.sessions,
                        ),
                        item(
                          Icons.fact_check_outlined,
                          l10n.navListingReview,
                          AdminRoutes.listings,
                        ),
                        item(
                          Icons.people_outline_rounded,
                          l10n.navUsers,
                          AdminRoutes.users,
                        ),
                        item(
                          Icons.category_outlined,
                          l10n.navCategories,
                          AdminRoutes.categories,
                        ),
                        item(
                          Icons.account_balance_outlined,
                          l10n.navWithdrawals,
                          AdminRoutes.withdrawals,
                        ),
                        item(
                          Icons.gpp_maybe_outlined,
                          l10n.navDisputes,
                          AdminRoutes.disputes,
                        ),
                        item(
                          Icons.tune_rounded,
                          l10n.navConfig,
                          AdminRoutes.config,
                        ),
                      ],
                    ],
                  ),
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: SidebarItem.user(
                            context,
                            name: user.fullName,
                            selected: false,
                            onTap: () {},
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.logout,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          onPressed: () => ref
                              .read(sessionControllerProvider.notifier)
                              .signOut(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
