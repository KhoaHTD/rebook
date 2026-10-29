import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_floor_providers.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_widgets.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Các phiên đã đăng ký: số bài, tiền cọc, hạn mức còn lại, trạng thái cọc.
class MyAuctionsScreen extends ConsumerWidget {
  const MyAuctionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final regs = ref.watch(myRegistrationsProvider);
    return AppPage(
      title: l10n.myAuctions,
      showBack: false,
      onRefresh: () => ref.refresh(myRegistrationsProvider.future),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l10n.mineRegistrations,
            style: context.textStyles.headlineSmall,
          ),
        ),
        AsyncValueView(
          value: regs,
          onRetry: () => ref.invalidate(myRegistrationsProvider),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.gavel_rounded,
                  title: l10n.noRegistrations,
                  action: FilledButton(
                    onPressed: () => context.go(Routes.auctionSchedule),
                    child: Text(l10n.scheduleTitle),
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      for (final r in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            borderRadius: AppRadius.card,
                            onTap: () =>
                                context.go(Routes.session(r.sessionId)),
                            child: InfoPanel(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: context.appColors.selected,
                                    child: Text(
                                      r.paddleNumber,
                                      style: context.textStyles.labelLarge
                                          ?.copyWith(
                                            color: context.appColors.onSelected,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.sessionTitle,
                                          style: context.textStyles.titleMedium,
                                        ),
                                        Text(
                                          '${l10n.deposited(formatVnd(r.depositAmount))} · ${l10n.limitLeft(formatVnd(r.remainingLimit))}',
                                          style: context.textStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusPill(
                                    r.status.label(l10n),
                                    tone: r.status.tone,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l10n.mineWatching,
            style: context.textStyles.headlineSmall,
          ),
        ),
        _WatchedLots(),
        const SizedBox(height: 110),
      ],
    );
  }
}

class _WatchedLots extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lots = ref.watch(watchedLotsProvider).value ?? const <Lot>[];
    if (lots.isEmpty) {
      return Text(l10n.mineWatchingEmpty, style: context.textStyles.bodyMedium);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < lots.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 160,
              child: LotTile(
                lot: lots[i],
                onTap: () => context.go(Routes.lot(lots[i].id)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
