import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Staff đối chiếu hãng vận chuyển: đơn đang giao đã giao thành công hay thất bại.
/// Đơn COD chỉ đi tiếp (tiền về sàn rồi mới về shop) khi có kết quả này.
class CarrierScreen extends ConsumerWidget {
  const CarrierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final orders = ref.watch(staffInTransitProvider);
    final actions = ref.read(staffActionsProvider.notifier);
    final busy = ref.watch(staffActionsProvider).isLoading;

    Future<void> report(Future<bool> Function() run) async {
      final ok = await run();
      if (!context.mounted) return;
      if (ok) {
        showInfoSnack(context, l10n.stfCarrierDone);
      } else {
        showErrorSnack(context, ref.read(staffActionsProvider).error!);
      }
    }

    return AppPage(
      title: l10n.stfCarrierTitle,
      showBack: false,
      onRefresh: () => ref.refresh(staffInTransitProvider.future),
      children: [
        Text(l10n.stfCarrierHint, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        AsyncValueView(
          value: orders,
          onRetry: () => ref.invalidate(staffInTransitProvider),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: InfoPanel(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.stfCarrierShopLine(
                                          o.shopName,
                                          o.code,
                                        ),
                                        style: text.titleSmall,
                                      ),
                                    ),
                                    StatusPill(
                                      o.isCod
                                          ? l10n.stfCarrierCod
                                          : l10n.stfCarrierPrepaid,
                                      tone: o.isCod
                                          ? StatusTone.warning
                                          : StatusTone.neutral,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  formatVnd(o.total),
                                  style: text.bodyMedium,
                                ),
                                if (o.trackingCode != null)
                                  Text(
                                    l10n.stfCarrierTracking(o.trackingCode!),
                                    style: text.bodySmall,
                                  ),
                                if (o.overdue)
                                  Text(
                                    l10n.stfCarrierOverdue,
                                    style: text.bodySmall?.copyWith(
                                      color: c.warning,
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    FilledButton(
                                      onPressed: busy
                                          ? null
                                          : () => report(
                                              () => actions.carrierDelivered(
                                                o.id,
                                              ),
                                            ),
                                      child: Text(l10n.stfCarrierDelivered),
                                    ),
                                    OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              final reason =
                                                  await showTextSheet(
                                                    context,
                                                    title:
                                                        l10n.stfCarrierFailed,
                                                    label: l10n
                                                        .stfCarrierFailedReason,
                                                    lines: 3,
                                                  );
                                              if (reason == null) return;
                                              await report(
                                                () => actions.carrierFailed(
                                                  o.id,
                                                  reason,
                                                ),
                                              );
                                            },
                                      child: Text(l10n.stfCarrierFailed),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
