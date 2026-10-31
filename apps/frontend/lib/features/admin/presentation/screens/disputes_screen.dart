import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Khiếu nại trả hàng shop đã từ chối — ReBook phân xử (SRS 4.4).
class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(adminDisputesProvider);
    final busy = ref.watch(adminActionsProvider).isLoading;

    Future<void> resolve(String id, {required bool refund}) async {
      final note = await showTextSheet(
        context,
        title: refund ? l10n.refundBuyer : l10n.keepSale,
        label: l10n.decisionNote,
        lines: 3,
      );
      if (note == null) return;
      await ref.read(adminActionsProvider.notifier).run(
        (r) => r.resolveDispute(id, refund: refund, note: note),
        [DataArea.orders, DataArea.wallet],
      );
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    return AppPage(
      title: l10n.navDisputes,
      showBack: false,
      onRefresh: () => ref.refresh(adminDisputesProvider.future),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(adminDisputesProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: l10n.nothingToDo,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      for (final o in items)
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
                                        '${l10n.orderCode(o.code)} · ${o.buyerName ?? ''} → ${o.shop?.name ?? ''}',
                                        style: context.textStyles.titleMedium,
                                      ),
                                    ),
                                    PriceText(o.total),
                                  ],
                                ),
                                if (o.returnRequest case final ret?) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  StatusPill(
                                    ret.status.label(l10n),
                                    tone: StatusTone.warning,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    ret.reason,
                                    style: context.textStyles.bodyMedium,
                                  ),
                                  if (ret.resolution != null)
                                    Text(
                                      ret.resolution!,
                                      style: context.textStyles.bodySmall,
                                    ),
                                  if (ret.imageUrls.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    PhotoStrip(urls: ret.imageUrls, size: 72),
                                  ],
                                ],
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  children: [
                                    FilledButton(
                                      onPressed: busy
                                          ? null
                                          : () => resolve(o.id, refund: true),
                                      child: Text(l10n.refundBuyer),
                                    ),
                                    OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () => resolve(o.id, refund: false),
                                      child: Text(l10n.keepSale),
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
        const SizedBox(height: AppSpacing.xl),
        const _ResolvedDisputes(),
      ],
    );
  }
}

/// Yêu cầu đã phân xử, kèm Admin phân xử và thời gian (SRS 8.1).
class _ResolvedDisputes extends ConsumerWidget {
  const _ResolvedDisputes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final items =
        ref.watch(adminResolvedDisputesProvider).value ?? const <Order>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.admResolvedDisputesTitle,
          style: context.textStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: InfoPanel(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final (i, o) in items.indexed) ...[
                  if (i > 0) Divider(height: 1, indent: 16, color: c.separator),
                  ListTile(
                    title: Text(
                      '${l10n.orderCode(o.code)} · ${o.buyerName ?? ''}',
                    ),
                    subtitle: Text(
                      l10n.admResolvedBy(
                        o.returnRequest?.resolvedBy ?? '',
                        formatDateTime(
                          o.returnRequest?.resolvedAt ?? o.createdAt,
                        ),
                      ),
                    ),
                    trailing: StatusPill(
                      o.returnRequest!.status.label(l10n),
                      tone: StatusTone.neutral,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
