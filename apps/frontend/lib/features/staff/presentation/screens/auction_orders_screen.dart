import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/order_widgets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Lô đã thanh toán: kho đóng gói, xuất giao, xác nhận giao xong (SRS 6.6).
class AuctionOrdersScreen extends ConsumerWidget {
  const AuctionOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orders = ref.watch(staffAuctionOrdersProvider);
    final actions = ref.read(staffActionsProvider.notifier);
    final busy = ref.watch(staffActionsProvider).isLoading;
    return AppPage(
      title: l10n.navAuctionOrders,
      showBack: false,
      onRefresh: () => ref.refresh(staffAuctionOrdersProvider.future),
      children: [
        AsyncValueView(
          value: orders,
          onRetry: () => ref.invalidate(staffAuctionOrdersProvider),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: l10n.nothingToDo,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      for (final o in list)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: OrderCard(
                                order: o,
                                showBuyer: true,
                                onTap: () {},
                              ),
                            ),
                            if (o.status == OrderStatus.preparing ||
                                o.status == OrderStatus.shipping) ...[
                              const SizedBox(width: AppSpacing.md),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: FilledButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          final r = await actions.advanceOrder(
                                            o.id,
                                          );
                                          if (r == null && context.mounted) {
                                            showErrorSnack(
                                              context,
                                              ref
                                                  .read(staffActionsProvider)
                                                  .error!,
                                            );
                                          }
                                        },
                                  child: Text(
                                    o.status == OrderStatus.preparing
                                        ? l10n.advanceShip
                                        : l10n.advanceDelivered,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
