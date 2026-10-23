import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/stat_card.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Dashboard: doanh thu, phí sàn, số đơn, tỉ lệ lô bán được, người dùng, việc chờ duyệt (SRS 8).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(dashboardProvider);
    return AppPage(
      title: l10n.navDashboard,
      showBack: false,
      onRefresh: () => ref.refresh(dashboardProvider.future),
      children: [
        AsyncValueView(
          value: d,
          onRetry: () => ref.invalidate(dashboardProvider),
          data: (d) => StatGrid(
            children: [
              StatCard(
                icon: Icons.payments_outlined,
                label: l10n.revenue,
                value: PriceText(d.revenueTotal),
              ),
              StatCard(
                icon: Icons.account_balance_outlined,
                label: l10n.platformFees,
                value: PriceText(d.platformFees),
              ),
              StatCard(
                icon: Icons.receipt_long_outlined,
                label: l10n.orderCount,
                value: Text('${d.orderCount}'),
              ),
              StatCard(
                icon: Icons.gavel_rounded,
                label: l10n.lotSoldRate,
                value: Text('${(d.lotSoldRate * 100).round()}%'),
              ),
              StatCard(
                icon: Icons.people_outline_rounded,
                label: l10n.activeUsers,
                value: Text('${d.activeUsers}'),
                onTap: () => context.go(AdminRoutes.users),
              ),
              StatCard(
                icon: Icons.fact_check_outlined,
                label: l10n.pendingListingsCount,
                highlight: d.pendingListings > 0,
                value: Text('${d.pendingListings}'),
                onTap: () => context.go(AdminRoutes.listings),
              ),
              StatCard(
                icon: Icons.inventory_2_outlined,
                label: l10n.pendingConsignmentsCount,
                highlight: d.pendingConsignments > 0,
                value: Text('${d.pendingConsignments}'),
                onTap: () => context.go(AdminRoutes.consignments),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
