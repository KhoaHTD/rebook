import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/cart/presentation/providers/cart_providers.dart';
import 'package:book_marketplace/features/cart/presentation/widgets/cart_widgets.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
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
    final value = cart.value;
    final empty = value == null || value.groups.isEmpty;

    return AppPage(
      title: l10n.cartTitle,
      subtitle: empty ? null : l10n.items(value.itemCount),
      bottomBar: compact && !empty ? _CheckoutBar(cart: value) : null,
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

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.appColors.separator)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.total, style: context.textStyles.bodySmall),
                  PriceText(cart.total, style: context.textStyles.titleLarge),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => context.go(Routes.checkout),
              child: Text(l10n.checkout),
            ),
          ],
        ),
      ),
    );
  }
}
