import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/wallet/data/wallet_repository_provider.dart';
import 'package:book_marketplace/features/wallet/domain/debt.dart';
import 'package:book_marketplace/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Nợ phạt / phí kho còn lại, kèm nút thu từ số dư ví. Không có nợ thì không hiện gì.
class DebtPanel extends ConsumerStatefulWidget {
  const DebtPanel({super.key});

  @override
  ConsumerState<DebtPanel> createState() => _DebtPanelState();
}

class _DebtPanelState extends ConsumerState<DebtPanel> {
  bool _busy = false;

  Future<void> _collect() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final r = await ref.read(walletRepositoryProvider).collectDebts();
      ref.read(dataChangesProvider.notifier).bump(DataArea.wallet);
      if (!mounted) return;
      showInfoSnack(
        context,
        l10n.walletDebtCollected(
          formatVnd(r.collected),
          formatVnd(r.stillOwed),
        ),
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final debts = ref.watch(myDebtsProvider).value ?? const <Debt>[];
    if (debts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InfoPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.walletDebtTitle,
              style: text.titleMedium?.copyWith(color: c.warning),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.walletDebtHint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            for (final d in debts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        switch (d.kind) {
                          DebtKind.storageFee => l10n.walletDebtStorage,
                          DebtKind.chargeback => l10n.walletDebtChargeback,
                          DebtKind.auctionPenalty => l10n.walletDebtPenalty,
                        },
                        style: text.bodyMedium,
                      ),
                    ),
                    Text(
                      l10n.walletDebtRemaining(formatVnd(d.remaining)),
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _busy ? null : _collect,
              child: Text(l10n.walletDebtCollect),
            ),
          ],
        ),
      ),
    );
  }
}
