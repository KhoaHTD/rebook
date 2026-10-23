import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Thẻ một đơn trong danh sách (người mua, shop, kho): nguồn, trạng thái, sách đầu tiên, tổng tiền.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showBuyer = false,
  });

  final Order order;
  final VoidCallback onTap;

  /// Shop / kho xem đơn: hiện tên người mua thay cho tên shop.
  final bool showBuyer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final first = order.items.first;
    final source = showBuyer
        ? (order.buyerName ?? '')
        : (order.type == OrderType.auction
              ? l10n.auctionInvoice
              : order.shop?.name ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.sidebar,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.card,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookPoster(
                  title: first.title,
                  author: '',
                  coverUrl: first.imageUrl,
                  seed: first.listingId ?? first.lotId ?? first.id,
                  width: 56,
                  shadow: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodySmall,
                            ),
                          ),
                          StatusPill(
                            order.status.label(l10n),
                            tone: order.status.tone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        first.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium,
                      ),
                      if (order.items.length > 1)
                        Text(
                          l10n.moreItems(order.items.length - 1),
                          style: context.textStyles.bodySmall,
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.orderedAt(
                                formatShortDateTime(order.createdAt),
                              ),
                              style: context.textStyles.bodySmall,
                            ),
                          ),
                          PriceText(order.total),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hành trình đơn: các mốc trạng thái theo thời gian (bảng order_status_history).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.history});

  final List<OrderStatusChange> history;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final items = history.reversed.toList();
    return Column(
      children: [
        for (final (i, h) in items.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: i == 0 ? c.selected : c.tertiaryText,
                      ),
                      if (i < items.length - 1)
                        Expanded(
                          child: VerticalDivider(color: c.separator, width: 1),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.to.label(l10n),
                          style: context.textStyles.titleSmall,
                        ),
                        Text(
                          formatDateTime(h.at),
                          style: context.textStyles.bodySmall,
                        ),
                        if (h.note != null)
                          Text(h.note!, style: context.textStyles.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bảng tiền của một đơn (dùng chung người mua / shop / kho).
class OrderMoney extends StatelessWidget {
  const OrderMoney({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SummaryPanel(
      subtotal: order.subtotal,
      shipping: order.shippingFee,
      total: order.total,
      extra: [
        if (order.buyerPremium > 0) (l10n.buyerPremium, order.buyerPremium),
        if (order.depositApplied > 0)
          (l10n.depositApplied, -order.depositApplied),
      ],
    );
  }
}

/// Các sách trong đơn: poster nhỏ, tên, đơn giá × số lượng.
class OrderItemsList extends StatelessWidget {
  const OrderItemsList({super.key, required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                BookPoster(
                  title: it.title,
                  author: '',
                  coverUrl: it.imageUrl,
                  seed: it.listingId ?? it.lotId ?? it.id,
                  width: 48,
                  shadow: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    it.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleMedium,
                  ),
                ),
                Text(
                  '${formatVnd(it.unitPrice)} × ${it.quantity}',
                  style: context.textStyles.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
