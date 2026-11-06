import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/transit_order.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/order_widgets.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

bool _returnPending(Order o) =>
    o.status == OrderStatus.returnRequested &&
    o.returnRequest?.status == ReturnStatus.pending;

bool _returnShipped(Order o) =>
    o.status == OrderStatus.returnRequested &&
    o.returnRequest?.status == ReturnStatus.awaitingGoods &&
    o.returnRequest?.returnShippedAt != null;

/// Lô đã thanh toán: kho đóng gói, xuất giao, xác nhận giao xong (SRS 6.6).
class AuctionOrdersScreen extends ConsumerWidget {
  const AuctionOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orders = ref.watch(staffAuctionOrdersProvider);
    final actions = ref.read(staffActionsProvider.notifier);
    final busy = ref.watch(staffActionsProvider).isLoading;
    void report(bool ok) {
      if (ok || !context.mounted) return;
      final error = ref.read(staffActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    Future<void> failed(String id) async {
      final reason = await showTextSheet(
        context,
        title: l10n.stfCarrierFailed,
        label: l10n.stfCarrierFailedReason,
        lines: 3,
      );
      if (reason == null || !context.mounted) return;
      final picked = await showCancelSheet(
        context,
        l10n.stfFaultOptions,
        title: l10n.stfFaultTitle,
      );
      if (picked == null) return;
      final fault = DeliveryFaultKind
          .values[l10n.stfFaultOptions.split('|').indexOf(picked)];
      report(await actions.auctionDeliveryFailed(id, reason, fault));
    }

    Future<void> decide(String id, bool accept) async {
      String? note;
      if (!accept) {
        note = await showTextSheet(
          context,
          title: l10n.rejectReturn,
          label: l10n.decisionNote,
          lines: 3,
        );
        if (note == null) return;
      }
      report(
        await actions.auctionReturnDecision(id, accept: accept, note: note),
      );
    }

    Future<void> received(String id) async {
      if (!await confirmDialog(context, l10n.returnReceivedQuestion)) return;
      report(await actions.auctionReturnReceived(id));
    }

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
                        LayoutBuilder(
                          builder: (context, box) {
                            final narrow = box.maxWidth < 600;
                            final buttons = <Widget>[
                              if (o.status == OrderStatus.shipping)
                                OutlinedButton(
                                  onPressed: busy ? null : () => failed(o.id),
                                  child: Text(l10n.stfCarrierFailed),
                                ),
                              if (_returnPending(o)) ...[
                                FilledButton(
                                  onPressed: busy
                                      ? null
                                      : () => decide(o.id, true),
                                  child: Text(l10n.acceptReturn),
                                ),
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => decide(o.id, false),
                                  child: Text(l10n.rejectReturn),
                                ),
                              ],
                              if (_returnShipped(o))
                                FilledButton(
                                  onPressed: busy ? null : () => received(o.id),
                                  child: Text(l10n.returnReceivedButton),
                                ),
                              if (o.status == OrderStatus.preparing ||
                                  o.status == OrderStatus.shipping)
                                FilledButton(
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
                            ];
                            final card = OrderCard(
                              order: o,
                              showBuyer: true,
                              onTap: () {},
                            );
                            if (buttons.isEmpty) return card;
                            if (narrow) {
                              // Điện thoại: nút nằm dưới thẻ để thẻ không bị ép hẹp.
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  card,
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      alignment: WrapAlignment.end,
                                      children: buttons,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: card),
                                const SizedBox(width: AppSpacing.md),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.md,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: buttons,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
