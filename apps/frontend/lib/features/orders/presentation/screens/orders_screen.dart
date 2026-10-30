import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/orders/presentation/providers/orders_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/order_widgets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Đơn mua, lọc theo nhóm trạng thái. Khu mua sách chỉ hiện đơn giá cố định; khu đấu giá ([auction]) chỉ hiện hóa đơn
/// các lô đã thắng.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, this.auction = false});

  final bool auction;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  var _filter = OrderFilter.all;

  String _label(AppLocalizations l, OrderFilter f) => switch (f) {
    OrderFilter.all => l.ordersAll,
    OrderFilter.toDo => l.ordersToPay,
    OrderFilter.inTransit => l.ordersInTransit,
    OrderFilter.delivered => l.ordersDelivered,
    OrderFilter.done => l.ordersDone,
    OrderFilter.cancelled => l.ordersCancelled,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orders = ref.watch(myOrdersProvider);
    return AppPage(
      title: widget.auction ? l10n.wonLots : l10n.myOrders,
      onRefresh: () => ref.refresh(myOrdersProvider.future),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in OrderFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_label(l10n, f)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: orders,
          onRetry: () => ref.invalidate(myOrdersProvider),
          data: (all) {
            final type = widget.auction ? OrderType.auction : OrderType.normal;
            final list = all
                .where((o) => o.type == type && _filter.matches(o.status))
                .toList();
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.noOrders,
                message: l10n.noOrdersHint,
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  for (final o in list)
                    OrderCard(
                      order: o,
                      onTap: () => context.go(
                        widget.auction
                            ? Routes.auctionOrder(o.id)
                            : Routes.order(o.id),
                      ),
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
