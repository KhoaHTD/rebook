import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/seller/presentation/providers/seller_providers.dart';
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

/// Xử lý một đơn của shop: xác nhận → giao shipper → (giao thành công) → hoàn tất;
/// hủy, chấp nhận yêu cầu hủy, xử lý yêu cầu trả hàng (SRS 4.4).
class SellerOrderDetailScreen extends ConsumerWidget {
  const SellerOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final order = ref.watch(shopOrderProvider(orderId));
    final compact = context.windowSize.isCompact;
    return AppPage(
      title: order.value == null
          ? l10n.shopOrders
          : l10n.orderCode(order.value!.code),
      showBack: true,
      onRefresh: () => ref.refresh(shopOrderProvider(orderId).future),
      children: [
        AsyncValueView(
          value: order,
          onRetry: () => ref.invalidate(shopOrderProvider(orderId)),
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
    final ret = order.returnRequest;
    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(t, style: context.textStyles.titleMedium),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusPill(order.status.label(l10n), tone: order.status.tone),
            if (order.cancelRequested)
              StatusPill(l10n.buyerRequestedCancel, tone: StatusTone.warning),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.orderedAt(formatDateTime(order.createdAt)),
          style: context.textStyles.bodySmall,
        ),
        if (order.status == OrderStatus.pendingConfirm &&
            order.confirmDeadline != null)
          Text(
            l10n.confirmBefore(formatDateTime(order.confirmDeadline!)),
            style: context.textStyles.bodyMedium?.copyWith(color: c.warning),
          ),
        if (order.trackingCode != null)
          Text(
            l10n.trackingCode(order.trackingCode!),
            style: context.textStyles.bodySmall,
          ),
        if (ret != null) ...[
          heading(l10n.returnRequestFrom),
          StatusPill(ret.status.label(l10n), tone: StatusTone.warning),
          if (ret.status == ReturnStatus.pending && ret.respondBy != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                ret.respondBy!.isAfter(DateTime.now())
                    ? l10n.returnRespondBySeller(
                        formatDateTime(ret.respondBy!),
                        ret.respondBy!.difference(DateTime.now()).inHours,
                      )
                    : l10n.returnOverdue,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: c.warning,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(ret.reason, style: context.textStyles.bodyMedium),
          if (ret.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            PhotoStrip(urls: ret.imageUrls, size: 72),
          ],
          if (ret.resolution != null)
            Text(ret.resolution!, style: context.textStyles.bodySmall),
        ],
        heading(l10n.buyer),
        Text(order.buyerName ?? '', style: context.textStyles.titleSmall),
        if (order.address != null)
          Text(
            '${order.address!.receiver} · ${order.address!.phone}\n${order.address!.oneLine}',
            style: context.textStyles.bodyMedium,
          ),
        if (order.paymentMethod != null)
          Text(
            order.paymentMethod!.label(l10n),
            style: context.textStyles.bodySmall,
          ),
        heading(l10n.orderItems),
        OrderItemsList(items: order.items),
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
    final actions = ref.read(sellerActionsProvider.notifier);
    final busy = ref.watch(sellerActionsProvider).isLoading;
    final s = order.status;

    void after() {
      if (!context.mounted) return;
      final error = ref.read(sellerActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    Future<void> cancel() async {
      final reason = order.cancelRequested
          ? (await confirmDialog(context, l10n.acceptCancel)
                ? l10n.acceptCancel
                : null)
          : await showCancelSheet(
              context,
              l10n.shopCancelReasons,
              title: l10n.shopCancel,
            );
      if (reason == null) return;
      await actions.cancel(order.id, reason);
      after();
    }

    Future<void> ship() async {
      final code = await showTextSheet(
        context,
        title: l10n.handToShipper,
        label: l10n.trackingCodeLabel,
        optional: true,
      );
      if (code == null) return;
      await actions.ship(order.id, trackingCode: code.isEmpty ? null : code);
      after();
    }

    Future<void> decideReturn({required bool accept}) async {
      final note = accept
          ? null
          : await showTextSheet(
              context,
              title: l10n.rejectReturn,
              label: l10n.decisionNote,
              lines: 3,
            );
      if (!accept && note == null) return;
      await actions.decideReturn(order.id, accept: accept, note: note);
      after();
    }

    final returnPending =
        s == OrderStatus.returnRequested &&
        order.returnRequest?.status == ReturnStatus.pending;
    final buttons = <Widget>[
      if (s == OrderStatus.pendingConfirm)
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  await actions.confirm(order.id);
                  after();
                },
          child: Text(l10n.confirmOrder),
        ),
      if (s == OrderStatus.preparing)
        FilledButton(
          onPressed: busy ? null : ship,
          child: Text(l10n.handToShipper),
        ),
      // Chế độ mock: giả lập đơn vị vận chuyển báo giao thành công.
      if (s == OrderStatus.shipping && Env.useMock)
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  await actions.markDelivered(order.id);
                  after();
                },
          child: Text(l10n.markDeliveredDemo),
        ),
      if (returnPending) ...[
        FilledButton(
          onPressed: busy ? null : () => decideReturn(accept: true),
          child: Text(l10n.acceptReturn),
        ),
        OutlinedButton(
          onPressed: busy ? null : () => decideReturn(accept: false),
          child: Text(l10n.rejectReturn),
        ),
      ],
      if (s == OrderStatus.pendingConfirm || s == OrderStatus.preparing)
        OutlinedButton(
          onPressed: busy ? null : cancel,
          child: Text(
            order.cancelRequested ? l10n.acceptCancel : l10n.shopCancel,
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
