import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/seller/presentation/providers/seller_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/order_widgets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Đơn của shop, lọc theo trạng thái (SRS 4.4).
class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  OrderStatus? _status;

  static const _filters = [
    null,
    OrderStatus.pendingConfirm,
    OrderStatus.preparing,
    OrderStatus.shipping,
    OrderStatus.delivered,
    OrderStatus.returnRequested,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orders = ref.watch(shopOrdersProvider);
    return AppPage(
      title: l10n.shopOrders,
      showBack: true,
      onRefresh: () => ref.refresh(shopOrdersProvider.future),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(s == null ? l10n.ordersAll : s.label(l10n)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: orders,
          onRetry: () => ref.invalidate(shopOrdersProvider),
          data: (all) {
            final list = all
                .where((o) => _status == null || o.status == _status)
                .toList();
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.noOrders,
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  for (final o in list)
                    OrderCard(
                      order: o,
                      showBuyer: true,
                      onTap: () => context.go(Routes.sellerOrder(o.id)),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
