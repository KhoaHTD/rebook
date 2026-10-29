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
            final groups = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in c.groups) ...[
                  CartGroupView(
                    group: g,
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
                    subtotal: c.subtotal,
                    shipping: c.shippingTotal,
                    total: c.total,
                    action: FilledButton(
                      onPressed: () => context.go(Routes.checkout),
                      child: Text(l10n.checkout),
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
              label: l10n.cartToCheckout,
              onPressed: () => context.go(Routes.checkout),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in c.groups) ...[
                  FlatCartGroup(
                    group: g,
                    onQuantity: (item, q) => ref
                        .read(cartControllerProvider.notifier)
                        .setQuantity(item.id, q),
                  ),
                  const SizedBox(height: 16),
                ],
                FlatCard(
                  child: Column(
                    children: [
                      FlatMoneyRow(l10n.subtotal, c.subtotal),
                      FlatMoneyRow(l10n.shippingFee, c.shippingTotal),
                      Divider(color: context.appColors.separator),
                      FlatMoneyRow(
                        l10n.bagTotal(c.itemCount),
                        c.total,
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
