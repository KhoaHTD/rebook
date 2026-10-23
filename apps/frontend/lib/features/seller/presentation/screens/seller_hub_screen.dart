import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/seller/presentation/providers/seller_providers.dart';
import 'package:book_marketplace/features/seller/presentation/widgets/seller_widgets.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/stat_card.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Kênh người bán: số liệu nhanh, sách đang bán, lối tắt (SRS 4.1, 4.4, 5.2).
/// Chưa mở shop → mời mở shop.
class SellerHubScreen extends ConsumerWidget {
  const SellerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shop = ref.watch(myShopProvider);
    return AppPage(
      title: shop.value?.name ?? l10n.sellerHub,
      subtitle: shop.value == null ? null : l10n.sellerHub,
      onRefresh: () async {
        ref
          ..invalidate(sellerStatsProvider)
          ..invalidate(sellerListingsProvider);
        await ref.refresh(myShopProvider.future).catchError((_) => null);
      },
      actions: [
        if (shop.value != null)
          HeaderAction(
            icon: Icons.add_rounded,
            label: l10n.newListing,
            onPressed: () => context.go(Routes.newListing),
          ),
      ],
      children: [
        AsyncValueView(
          value: shop,
          onRetry: () => ref.invalidate(myShopProvider),
          data: (s) => s == null
              ? EmptyState(
                  icon: Icons.storefront_outlined,
                  title: l10n.openShopTitle,
                  message: l10n.openShopSubtitle,
                  action: FilledButton(
                    onPressed: () => context.go(Routes.openShop),
                    child: Text(l10n.openShopButton),
                  ),
                )
              : _Hub(shop: s),
        ),
      ],
    );
  }
}

class _Hub extends ConsumerWidget {
  const _Hub({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final stats = ref.watch(sellerStatsProvider);
    final listings = ref.watch(sellerListingsProvider).value ?? const [];

    Widget link(IconData icon, String label, VoidCallback onTap) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: c.secondaryText),
      title: Text(label),
      trailing: Icon(Icons.chevron_right_rounded, color: c.tertiaryText),
      onTap: onTap,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          shop.pickupAddress,
          style: context.textStyles.bodyMedium?.copyWith(
            color: c.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: stats,
          onRetry: () => ref.invalidate(sellerStatsProvider),
          data: (s) => StatGrid(
            children: [
              StatCard(
                icon: Icons.notification_important_outlined,
                label: l10n.toConfirm,
                highlight: s.ordersToConfirm > 0,
                value: Text('${s.ordersToConfirm}'),
                onTap: () => context.go(Routes.sellerOrders),
              ),
              StatCard(
                icon: Icons.local_shipping_outlined,
                label: l10n.inProgress,
                value: Text('${s.ordersShipping}'),
                onTap: () => context.go(Routes.sellerOrders),
              ),
              StatCard(
                icon: Icons.task_alt_rounded,
                label: l10n.completedOrders,
                value: Text('${s.ordersCompleted}'),
              ),
              StatCard(
                icon: Icons.menu_book_outlined,
                label: l10n.activeListingsShort,
                value: Text('${s.activeListings}'),
                onTap: () => context.go(Routes.sellerListings),
              ),
              StatCard(
                icon: Icons.trending_up_rounded,
                label: l10n.revenueThisMonth,
                value: PriceText(s.revenueThisMonth),
              ),
              StatCard(
                icon: Icons.savings_outlined,
                label: l10n.revenueTotal,
                value: PriceText(s.revenueTotal),
              ),
              StatCard(
                icon: Icons.lock_clock_outlined,
                label: l10n.pendingBalance,
                value: PriceText(s.pendingBalance),
                onTap: () => context.go(Routes.wallet),
              ),
              StatCard(
                icon: Icons.star_outline_rounded,
                label: l10n.shopRating,
                value: Text('★ ${s.ratingAvg.toStringAsFixed(1)}'),
              ),
            ],
          ),
        ),
        if (listings.isNotEmpty) ...[
          const SizedBox(height: 56),
          SectionHeader(
            l10n.myListings,
            onTap: () => context.go(Routes.sellerListings),
          ),
          const SizedBox(height: AppSpacing.lg),
          PosterGrid(
            children: [
              for (final l in listings.take(4))
                SellerListingTile(
                  listing: l,
                  onTap: () => context.go(Routes.editListing(l.id)),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              link(
                Icons.menu_book_outlined,
                l10n.myListings,
                () => context.go(Routes.sellerListings),
              ),
              link(
                Icons.receipt_long_outlined,
                l10n.shopOrders,
                () => context.go(Routes.sellerOrders),
              ),
              link(
                Icons.inventory_2_outlined,
                l10n.myConsignments,
                () => context.go(Routes.consignments),
              ),
              link(
                Icons.account_balance_wallet_outlined,
                l10n.wallet,
                () => context.go(Routes.wallet),
              ),
              link(
                Icons.storefront_outlined,
                l10n.visitShop,
                () => context.go(Routes.shop(shop.id)),
              ),
              link(
                Icons.edit_outlined,
                l10n.editShop,
                () => context.go(Routes.openShop),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
