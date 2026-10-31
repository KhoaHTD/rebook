import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/cart/presentation/providers/cart_providers.dart';
import 'package:book_marketplace/features/cart/presentation/widgets/cart_widgets.dart';
import 'package:book_marketplace/features/cart/presentation/widgets/flat_commerce_widgets.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Giỏ hàng nhiều shop: mỗi shop một nhóm, giao và tính phí ship riêng (SRS 4.2).
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cart = ref.watch(cartControllerProvider);
    final compact = context.windowSize.isCompact;
    if (compact) return const _CompactCart();
    final value = cart.value;
    final empty = value == null || value.groups.isEmpty;

    return AppPage(
      title: l10n.cartTitle,
      subtitle: empty ? null : l10n.items(value.itemCount),
      children: [
        AsyncValueView(
          value: cart,
          onRetry: () => ref.invalidate(cartControllerProvider),
          data: (c) {
            if (c.groups.isEmpty) {
              return EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: l10n.cartEmpty,
                message: l10n.cartEmptyHint,
                action: FilledButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text(l10n.continueShopping),
                ),
              );
            }
            final excluded = ref.watch(cartExcludedProvider);
            final allIds = [
              for (final g in c.groups) ...g.items.map((i) => i.id),
            ];
            final selectedCart = ref.watch(selectedCartProvider).value ?? c;
            final nothing = allIds.every(excluded.contains);
            final groups = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CartSelectAllBar(
                  selectedCount: allIds
                      .where((i) => !excluded.contains(i))
                      .length,
                  totalCount: allIds.length,
                  onChanged: (on) => ref
                      .read(cartExcludedProvider.notifier)
                      .setSelected(allIds, selected: on),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final g in c.groups) ...[
                  CartGroupView(
                    group: g,
                    excluded: excluded,
                    onToggleItem: (i) =>
                        ref.read(cartExcludedProvider.notifier).toggle(i.id),
                    onToggleShop: (on) => ref
                        .read(cartExcludedProvider.notifier)
                        .setSelected(g.items.map((i) => i.id), selected: on),
                    onQuantity: (item, q) => ref
                        .read(cartControllerProvider.notifier)
                        .setQuantity(item.id, q),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text(l10n.splitOrdersNote, style: context.textStyles.bodySmall),
              ],
            );
            if (compact) return groups;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: groups),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(
                  width: 340,
                  child: SummaryPanel(
                    subtotal: selectedCart.subtotal,
                    shipping: selectedCart.shippingTotal,
                    total: selectedCart.total,
                    action: FilledButton(
                      onPressed: nothing
                          ? null
                          : () => context.go(Routes.checkout),
                      child: Text(
                        nothing ? l10n.cartNothingSelected : l10n.checkout,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Điện thoại: giỏ phẳng — nền xám nhạt, mỗi shop một thẻ trắng (bìa nhỏ, tên, giá, − 02 +, dấu ×),
/// thẻ tổng kết (tạm tính, ship, tổng) và nút đen ghim ở đáy.
class _CompactCart extends ConsumerWidget {
  const _CompactCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cart = ref.watch(cartControllerProvider);
    final value = cart.value;
    final empty = value == null || value.groups.isEmpty;
    return FlatCommercePage(
      title: l10n.cartTitle,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      trailing: empty
          ? null
          : Badge(
              label: Text('${value.itemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
      bottom: empty
          ? null
          : FlatBlackButton(
              label: ref.watch(selectedCartItemIdsProvider).isEmpty
                  ? l10n.cartNothingSelected
                  : l10n.cartToCheckout,
              onPressed: ref.watch(selectedCartItemIdsProvider).isEmpty
                  ? null
                  : () => context.go(Routes.checkout),
            ),
      children: [
        AsyncValueView(
          value: cart,
          onRetry: () => ref.invalidate(cartControllerProvider),
          data: (c) {
            if (c.groups.isEmpty) {
              return EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: l10n.cartEmpty,
                message: l10n.cartEmptyHint,
                action: FilledButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text(l10n.continueShopping),
                ),
              );
            }
            final excluded = ref.watch(cartExcludedProvider);
            final allIds = [
              for (final g in c.groups) ...g.items.map((i) => i.id),
            ];
            final sel = ref.watch(selectedCartProvider).value ?? c;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CartSelectAllBar(
                  selectedCount: allIds
                      .where((i) => !excluded.contains(i))
                      .length,
                  totalCount: allIds.length,
                  onChanged: (on) => ref
                      .read(cartExcludedProvider.notifier)
                      .setSelected(allIds, selected: on),
                ),
                const SizedBox(height: 12),
                for (final g in c.groups) ...[
                  FlatCartGroup(
                    group: g,
                    excluded: excluded,
                    onToggleItem: (i) =>
                        ref.read(cartExcludedProvider.notifier).toggle(i.id),
                    onToggleShop: (on) => ref
                        .read(cartExcludedProvider.notifier)
                        .setSelected(g.items.map((i) => i.id), selected: on),
                    onQuantity: (item, q) => ref
                        .read(cartControllerProvider.notifier)
                        .setQuantity(item.id, q),
                  ),
                  const SizedBox(height: 16),
                ],
                FlatCard(
                  child: Column(
                    children: [
                      FlatMoneyRow(l10n.subtotal, sel.subtotal),
                      FlatMoneyRow(l10n.shippingFee, sel.shippingTotal),
                      Divider(color: context.appColors.separator),
                      FlatMoneyRow(
                        l10n.bagTotal(sel.itemCount),
                        sel.total,
                        strong: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.splitOrdersNote,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.appColors.secondaryText,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
