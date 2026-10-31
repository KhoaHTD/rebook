import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/external_link.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/orders/presentation/providers/orders_providers.dart';
import 'package:book_marketplace/features/orders/presentation/widgets/order_sheets.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/order_widgets.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Chi tiết đơn của người mua: hành trình, sách, địa chỉ, tiền, và hành động hợp lệ theo trạng thái (SRS 4.3–4.4, 6.6).
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final order = ref.watch(orderDetailProvider(orderId));
    final compact = context.windowSize.isCompact;
    return AppPage(
      title: order.value == null
          ? l10n.myOrders
          : l10n.orderCode(order.value!.code),
      showBack: true,
      onRefresh: () => ref.refresh(orderDetailProvider(orderId).future),
      children: [
        AsyncValueView(
          value: order,
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          data: (o) {
            final main = _Main(order: o);
            final side = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrderMoney(order: o),
                const SizedBox(height: AppSpacing.lg),
                _Actions(order: o),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  main,
                  const SizedBox(height: AppSpacing.lg),
                  side,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(width: 340, child: side),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(t, style: context.textStyles.titleMedium),
    );
    Widget deadline(String label, DateTime? at) => at == null
        ? const SizedBox.shrink()
        : Text(
            '$label: ${formatDateTime(at)}',
            style: context.textStyles.bodySmall,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusPill(order.status.label(l10n), tone: order.status.tone),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                order.type == OrderType.auction
                    ? l10n.auctionInvoice
                    : (order.shop?.name ?? ''),
                style: context.textStyles.bodyMedium?.copyWith(
                  color: c.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.orderedAt(formatDateTime(order.createdAt)),
          style: context.textStyles.bodySmall,
        ),
        if (order.status == OrderStatus.pendingPayment)
          deadline(l10n.payBefore, order.paymentDeadline),
        if (order.status == OrderStatus.pendingConfirm)
          deadline(l10n.shopConfirmBefore, order.confirmDeadline),
        if (order.status == OrderStatus.delivered)
          deadline(l10n.complaintBefore, order.complaintDeadline),
        if (order.trackingCode != null)
          Text(
            l10n.trackingCode(order.trackingCode!),
            style: context.textStyles.bodySmall,
          ),
        if (order.cancelRequested)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.cancelRequestedNote,
              style: context.textStyles.bodyMedium?.copyWith(color: c.warning),
            ),
          ),
        heading(l10n.orderItems),
        OrderItemsList(items: order.items),
        if (order.address != null || order.pickupAtWarehouse) ...[
          heading(l10n.deliveryAddress),
          Text(
            order.pickupAtWarehouse
                ? l10n.pickupAtWarehouse
                : '${order.address!.receiver} · ${order.address!.phone}\n${order.address!.oneLine}',
            style: context.textStyles.bodyMedium,
          ),
        ],
        if (order.paymentMethod != null) ...[
          heading(l10n.paymentMethod),
          Text(
            order.paymentMethod!.label(l10n),
            style: context.textStyles.bodyMedium,
          ),
        ],
        if (order.returnRequest != null) ...[
          heading(l10n.returnStatus(order.returnRequest!.status.label(l10n))),
          Text(
            order.returnRequest!.reason,
            style: context.textStyles.bodyMedium,
          ),
          if (order.returnRequest!.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            PhotoStrip(urls: order.returnRequest!.imageUrls, size: 72),
          ],
          if (order.returnRequest!.status == ReturnStatus.pending &&
              order.returnRequest!.respondBy != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.returnRespondBy(
                  formatDateTime(order.returnRequest!.respondBy!),
                ),
                style: context.textStyles.bodySmall,
              ),
            ),
          if (order.returnRequest!.resolution != null)
            Text(
              order.returnRequest!.resolution!,
              style: context.textStyles.bodySmall,
            ),
        ],
        if (order.review != null) ...[
          heading(l10n.yourReview),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= order.review!.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 18,
                  color: c.warning,
                ),
            ],
          ),
          if (order.review!.comment != null)
            Text(order.review!.comment!, style: context.textStyles.bodyMedium),
        ],
        heading(l10n.orderTimeline),
        StatusTimeline(history: order.history),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.read(orderActionsProvider(order.id).notifier);
    final busy = ref.watch(orderActionsProvider(order.id)).isLoading;

    Future<void> run(Future<Object?> Function() action, {String? done}) async {
      await action();
      if (!context.mounted) return;
      final error = ref.read(orderActionsProvider(order.id)).error;
      if (error != null) {
        showErrorSnack(context, error);
      } else if (done != null) {
        showInfoSnack(context, done);
      }
    }

    final buttons = <Widget>[
      if (order.type == OrderType.auction &&
          order.status == OrderStatus.pendingPayment)
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  final choice = await showPayInvoiceSheet(context, ref, order);
                  if (choice == null || !context.mounted) return;
                  final result = await actions.pay(
                    choice.method,
                    addressId: choice.addressId,
                    pickup: choice.pickup,
                  );
                  if (!context.mounted) return;
                  final error = ref.read(orderActionsProvider(order.id)).error;
                  if (error != null) return showErrorSnack(context, error);
                  final p = result?.payment;
                  if (p != null && choice.method == PaymentMethod.vnpay) {
                    if (isMockUrl(p.paymentUrl)) {
                      context.go(Routes.paymentResult(p.id));
                    } else {
                      await openExternal(p.paymentUrl!);
                    }
                  } else {
                    showInfoSnack(context, l10n.paymentDone);
                  }
                },
          child: Text(l10n.payInvoice),
        ),
      if (order.status == OrderStatus.delivered) ...[
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  final ok = await confirmDialog(
                    context,
                    l10n.confirmReceivedQuestion,
                  );
                  if (ok) await run(actions.confirmReceived);
                },
          child: Text(l10n.confirmReceived),
        ),
        OutlinedButton(
          onPressed: busy
              ? null
              : () async {
                  final r = await showReturnSheet(context);
                  if (r != null) {
                    await run(
                      () => actions.requestReturn(r.$1, r.$2),
                      done: l10n.returnSent,
                    );
                  }
                },
          child: Text(l10n.requestReturn),
        ),
      ],
      // Đang yêu cầu trả hàng mà bấm "Đã nhận hàng" = rút yêu cầu, đơn hoàn tất (SRS 4.4).
      if (order.status == OrderStatus.returnRequested &&
          (order.returnRequest?.status == ReturnStatus.pending ||
              order.returnRequest?.status == ReturnStatus.escalated))
        OutlinedButton(
          onPressed: busy
              ? null
              : () async {
                  final ok = await confirmDialog(
                    context,
                    l10n.withdrawReturnQuestion,
                  );
                  if (ok) await run(actions.confirmReceived);
                },
          child: Text(l10n.withdrawReturnAndConfirm),
        ),
      if (order.canReview)
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  final r = await showReviewSheet(context);
                  if (r != null) {
                    await run(
                      () => actions.review(r.$1, r.$2),
                      done: l10n.reviewThanks,
                    );
                  }
                },
          child: Text(l10n.writeReview),
        ),
      if (order.buyerCanCancelDirectly || order.buyerCanRequestCancel)
        OutlinedButton(
          onPressed: busy
              ? null
              : () async {
                  final reason = await showCancelSheet(
                    context,
                    l10n.cancelReasons,
                  );
                  if (reason != null) {
                    await run(
                      () => actions.cancel(reason),
                      done: order.buyerCanCancelDirectly
                          ? l10n.orderCancelled
                          : l10n.cancelRequestedNote,
                    );
                  }
                },
          child: Text(
            order.buyerCanCancelDirectly
                ? l10n.cancelOrder
                : l10n.requestCancel,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in buttons)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: b,
          ),
      ],
    );
  }
}
