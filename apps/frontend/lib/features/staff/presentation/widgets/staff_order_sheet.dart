import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/widgets/order_widgets.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';

/// Chi tiết một đơn cho nhân viên kho (chỉ xem): người mua, trạng thái, sách, địa chỉ giao, tiền, hành trình.
Future<void> showStaffOrderSheet(BuildContext context, Order order) {
  final l10n = context.l10n;
  return showAppSheet<void>(
    context,
    title: l10n.orderCode(order.code),
    body: (c, _) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.7),
      child: SingleChildScrollView(child: _StaffOrderLoader(summary: order)),
    ),
  );
}

/// Lấy chi tiết đầy đủ của đơn; trong lúc tải (hoặc nếu lỗi) vẫn hiện dữ liệu tóm tắt của dòng vừa bấm.
class _StaffOrderLoader extends ConsumerWidget {
  const _StaffOrderLoader({required this.summary});

  final Order summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final full = ref.watch(staffOrderProvider(summary.id));
    return _StaffOrderBody(order: full.value ?? summary);
  }
}

class _StaffOrderBody extends StatelessWidget {
  const _StaffOrderBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final c = context.appColors;
    final address = order.address;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(order.status.label(l10n), tone: order.status.tone),
            Text(
              l10n.orderedAt(formatShortDateTime(order.createdAt)),
              style: text.bodySmall?.copyWith(color: c.secondaryText),
            ),
          ],
        ),
        if (order.buyerName != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text('${l10n.buyer}: ${order.buyerName}', style: text.titleSmall),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.orderItems, style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        OrderItemsList(items: order.items),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.deliveryAddress, style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        if (order.pickupAtWarehouse)
          Text(l10n.pickupAtWarehouse, style: text.bodyMedium)
        else if (address != null) ...[
          Text(
            '${address.receiver} · ${address.phone}',
            style: text.bodyMedium,
          ),
          Text(address.oneLine, style: text.bodyMedium),
        ],
        if (order.paymentMethod != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.paymentMethod, style: text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(order.paymentMethod!.label(l10n), style: text.bodyMedium),
        ],
        if (order.trackingCode != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.trackingCode(order.trackingCode!), style: text.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.lg),
        OrderMoney(order: order),
        if (order.history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.orderTimeline, style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          StatusTimeline(history: order.history),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
