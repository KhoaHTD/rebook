import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/router/glass_tab_bar.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';
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
                    shippingNote: l10n.shippingAtCheckout,
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
    final navSide = ref.watch(
      appSettingsControllerProvider.select((s) => s.navSide),
    );
    return FlatCommercePage(
      title: l10n.cartTitle,
      // Giỏ là một mục của thanh tab (như Thông báo, Tài khoản): không có mũi tên quay lại và không tự vẽ
      // thêm biểu tượng túi + số ở góc, số lượng nằm trên biểu tượng giỏ của thanh tab.
      showBack: false,
      // Nút thanh toán thẳng hàng với nút điều hướng nổi: cùng cao (58), cùng tâm (đáy cách mép 23 = lề 18 + đệm
      // 5 của nút), cách nút 12, và cùng lề ngoài với nút ở phía bên kia.
      bottomPadding: () {
        final edge = ExpandingTabBar.buttonEdge(
          MediaQuery.sizeOf(context).width,
        );
        final beside = edge + ExpandingTabBar.button + 12;
        return EdgeInsets.fromLTRB(
          navSide == NavSide.left ? beside : edge,
          8,
          navSide == NavSide.right ? beside : edge,
          18 + ExpandingTabBar.pad,
        );
      }(),
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
                      FlatMoneyRow(
                        l10n.shippingFee,
                        sel.shippingTotal,
                        note: l10n.shippingAtCheckout,
                      ),
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
