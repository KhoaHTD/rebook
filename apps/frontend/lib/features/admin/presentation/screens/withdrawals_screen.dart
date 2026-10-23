import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Yêu cầu rút tiền: kế toán chuyển khoản rồi đánh dấu đã chuyển (SRS 5.2).
class WithdrawalsScreen extends ConsumerWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final list = ref.watch(adminWithdrawalsProvider);
    final busy = ref.watch(adminActionsProvider).isLoading;

    Future<void> markPaid(String id) async {
      await ref.read(adminActionsProvider.notifier).run(
        (r) => r.completeWithdrawal(id),
        [DataArea.wallet],
      );
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    return AppPage(
      title: l10n.navWithdrawals,
      showBack: false,
      onRefresh: () => ref.refresh(adminWithdrawalsProvider.future),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(adminWithdrawalsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: l10n.nothingToDo,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: InfoPanel(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        for (final (i, w) in items.indexed) ...[
                          if (i > 0)
                            Divider(height: 1, indent: 16, color: c.separator),
                          ListTile(
                            title: Text(w.userName ?? ''),
                            subtitle: Text(formatDateTime(w.createdAt)),
                            leading: SizedBox(
                              width: 120,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: PriceText(w.amount),
                              ),
                            ),
                            trailing: w.status == WithdrawalStatus.pending
                                ? FilledButton(
                                    onPressed: busy
                                        ? null
                                        : () => markPaid(w.id),
                                    child: Text(l10n.markPaid),
                                  )
                                : StatusPill(
                                    w.status.label(l10n),
                                    tone: w.status.tone,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
