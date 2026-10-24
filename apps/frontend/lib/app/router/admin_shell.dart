import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/admin_scope.dart';

/// Khung web quản trị: sidebar trắng phẳng, mục đang chọn tô đen (dashboard chuyên nghiệp).
/// Staff chỉ thấy nhóm Kho + Giám sát phiên; Admin thấy đủ các nhóm.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get location => widget.location;
  Widget get child => widget.child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 900;
    final user = ref.watch(sessionControllerProvider).user;
    final isAdmin = user?.role == AuthRole.admin;

    // Số việc chờ xử lý hiện trên sidebar (chỉ Admin gọi được các API này).
    final pendingListings = isAdmin
        ? ref.watch(pendingListingsProvider).value?.length ?? 0
        : 0;
    final disputes = isAdmin
        ? ref.watch(adminDisputesProvider).value?.length ?? 0
        : 0;
    final withdrawals = isAdmin
        ? ref
                  .watch(adminWithdrawalsProvider)
                  .value
                  ?.where((w) => w.status == WithdrawalStatus.pending)
                  .length ??
              0
        : 0;
    final live =
        ref.watch(adminSessionsProvider).value?.any((s) => s.isLive) ?? false;

    bool under(String p) => p == AdminRoutes.dashboard
        ? location == p
        : (location == p || location.startsWith('$p/'));
    Widget item(
      IconData icon,
      String label,
      String path, {
      int count = 0,
      bool liveDot = false,
    }) => _NavItem(
      icon: icon,
      label: label,
      selected: under(path),
      count: count,
      liveDot: liveDot,
      onTap: () {
        if (compact) Navigator.of(context).pop();
        context.go(path);
      },
    );

    final warehouse = [
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
      item(Icons.warehouse_outlined, l10n.navWarehouse, AdminRoutes.warehouse),
      item(
        Icons.local_shipping_outlined,
        l10n.navAuctionOrders,
        AdminRoutes.auctionOrders,
      ),
    ];
    final auction = item(
      Icons.gavel_rounded,
      l10n.navSessions,
      AdminRoutes.sessions,
      liveDot: live,
    );

    final sidebar = Container(
      width: compact ? null : 240,
      decoration: const BoxDecoration(
        color: AdminPalette.card,
        border: Border(right: BorderSide(color: AdminPalette.line)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AdminPalette.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    l10n.appTitle,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin ? AdminPalette.ink : AdminPalette.info,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isAdmin ? l10n.adminBadgeAdmin : l10n.adminBadgeStaff,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (isAdmin) ...[
                    _Group(l10n.adminGroupOverview),
                    item(
                      Icons.space_dashboard_outlined,
                      l10n.navDashboard,
                      AdminRoutes.dashboard,
                    ),
                    _Group(l10n.adminGroupReview),
                    item(
                      Icons.fact_check_outlined,
                      l10n.navListingReview,
                      AdminRoutes.listings,
                      count: pendingListings,
                    ),
                    item(
                      Icons.gpp_maybe_outlined,
                      l10n.navDisputes,
                      AdminRoutes.disputes,
                      count: disputes,
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
                    _Group(l10n.adminGroupAuction),
                    auction,
                    _Group(l10n.adminGroupWarehouse),
                    ...warehouse,
                    _Group(l10n.adminGroupSystem),
                    item(
                      Icons.tune_rounded,
                      l10n.navConfig,
                      AdminRoutes.config,
                    ),
                    item(
                      Icons.account_balance_outlined,
                      l10n.navWithdrawals,
                      AdminRoutes.withdrawals,
                      count: withdrawals,
                    ),
                  ] else ...[
                    _Group(l10n.adminGroupWarehouse),
                    ...warehouse,
                    _Group(l10n.adminGroupAuction),
                    auction,
                  ],
                ],
              ),
            ),
            if (user != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AdminPalette.line)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: isAdmin
                          ? AdminPalette.ink
                          : AdminPalette.info,
                      child: Text(
                        user.fullName.isEmpty
                            ? '?'
                            : user.fullName.characters.first.toUpperCase(),
                        style: context.textStyles.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelLarge,
                          ),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: AdminPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.logout,
                      icon: const Icon(Icons.logout_rounded, size: 19),
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
    );

    final content = AdminScope(
      onMenu: compact ? () => _scaffoldKey.currentState?.openDrawer() : null,
      child: Theme(data: _adminTheme(Theme.of(context)), child: child),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminPalette.bg,
      drawer: compact ? Drawer(width: 280, child: sidebar) : null,
      body: compact
          ? content
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sidebar,
                Expanded(child: content),
              ],
            ),
    );
  }
}

/// Nút đen, bo 10 — dùng cho mọi màn quản trị (không phải nút xanh của app người mua).
ThemeData _adminTheme(ThemeData base) {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AdminPalette.ink,
        foregroundColor: Colors.white,
        shape: shape,
        minimumSize: const Size(0, 40),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: AdminPalette.ink,
      checkmarkColor: Colors.white,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminPalette.ink,
        side: const BorderSide(color: AdminPalette.ink, width: 1.4),
        shape: shape,
        minimumSize: const Size(0, 40),
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 16, 10, 5),
    child: Text(
      label,
      style: context.textStyles.labelMedium?.copyWith(
        color: AdminPalette.faint,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.liveDot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final bool liveDot;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AdminPalette.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? AdminPalette.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AdminPalette.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AdminPalette.badSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$count',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: selected ? AdminPalette.ink : AdminPalette.bad,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (liveDot)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AdminPalette.bad,
                      shape: BoxShape.circle,
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
