import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Bảng kết quả phiên: số bài + giá, không hiện tên thật (SRS 6.5).
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final results = ref.watch(sessionResultsProvider(sessionId));
    return AppPage(
      title: l10n.resultsTitle,
      subtitle: results.value?.session.title,
      showBack: true,
      children: [
        AsyncValueView(
          value: results,
          onRetry: () => ref.invalidate(sessionResultsProvider(sessionId)),
          data: (r) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                for (final lot in r.results)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: lot.wonByMe
                          ? c.success.withValues(alpha: 0.1)
                          : c.sidebar,
                      borderRadius: AppRadius.card,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            l10n.lotNumber(lot.lotNumber),
                            style: context.textStyles.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            lot.title,
                            style: context.textStyles.titleMedium,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(switch (lot.outcome) {
                              LotOutcome.sold => formatVnd(
                                lot.hammerPrice ?? 0,
                              ),
                              LotOutcome.belowReserve =>
                                l10n.outcomeBelowReserve,
                              LotOutcome.noBids => l10n.noBids,
                              LotOutcome.cancelled => l10n.lsCancelled,
                            }, style: context.textStyles.titleSmall),
                            if (lot.winnerPaddle != null)
                              Text(
                                l10n.paddle(lot.winnerPaddle!),
                                style: context.textStyles.bodySmall,
                              ),
                            if (lot.wonByMe)
                              TextButton(
                                onPressed: () => context.go(Routes.orders),
                                child: Text(l10n.youWon),
                              ),
                          ],
                        ),
                      ],
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
