import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Kho: vị trí kệ, trạng thái lưu kho, xuất kho / trả người gửi (SRS 6.2, 6.6).
class WarehouseScreen extends ConsumerStatefulWidget {
  const WarehouseScreen({super.key});

  @override
  ConsumerState<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends ConsumerState<WarehouseScreen> {
  WarehouseStatus? _status = WarehouseStatus.inStock;

  Future<void> _onMenu(WarehouseItem w, String action) async {
    final l10n = context.l10n;
    final actions = ref.read(staffActionsProvider.notifier);
    switch (action) {
      case 'move':
        final shelf = await showTextSheet(
          context,
          title: l10n.moveShelf,
          label: l10n.shelfCode,
        );
        if (shelf == null) return;
        await actions.updateWarehouse(w.id, shelf: shelf);
      case 'ship':
        await actions.updateWarehouse(w.id, status: WarehouseStatus.shipped);
      case 'return':
        await actions.updateWarehouse(w.id, status: WarehouseStatus.returned);
    }
    if (!mounted) return;
    final error = ref.read(staffActionsProvider).error;
    if (error != null) showErrorSnack(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final items = ref.watch(warehouseItemsProvider);
    return AppPage(
      title: l10n.navWarehouse,
      showBack: false,
      onRefresh: () => ref.refresh(warehouseItemsProvider.future),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in [...WarehouseStatus.values, null])
              ChoiceChip(
                label: Text(s == null ? l10n.ordersAll : s.label(l10n)),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = s),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: items,
          onRetry: () => ref.invalidate(warehouseItemsProvider),
          data: (all) {
            final list = all
                .where((w) => _status == null || w.status == _status)
                .toList();
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.warehouse_outlined,
                title: l10n.nothingToDo,
              );
            }
            return InfoPanel(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (final (i, w) in list.indexed) ...[
                    if (i > 0)
                      Divider(height: 1, indent: 104, color: c.separator),
                    ListTile(
                      leading: Container(
                        width: 72,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: c.fill,
                          borderRadius: AppRadius.item,
                        ),
                        child: Text(
                          w.shelfCode,
                          style: context.textStyles.labelMedium,
                        ),
                      ),
                      title: Text(w.bookTitle),
                      subtitle: Text(
                        [
                          if (w.sellerName != null) w.sellerName!,
                          formatDate(w.checkedInAt),
                          w.status.label(l10n),
                          if (w.lotStatus != null) w.lotStatus!.label(l10n),
                        ].join(' · '),
                      ),
                      trailing:
                          w.status == WarehouseStatus.inStock ||
                              w.status == WarehouseStatus.reserved
                          ? DotsButton(
                              onSelected: (v) => _onMenu(w, v),
                              items: [
                                PopupMenuItem(
                                  value: 'move',
                                  child: Text(l10n.moveShelf),
                                ),
                                PopupMenuItem(
                                  value: 'ship',
                                  child: Text(l10n.markShipped),
                                ),
                                PopupMenuItem(
                                  value: 'return',
                                  child: Text(l10n.markReturned),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
