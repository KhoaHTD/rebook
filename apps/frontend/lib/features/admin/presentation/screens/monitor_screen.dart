import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Giám sát phiên đang chạy: lô hiện tại, diễn biến, tạm dừng / tiếp tục / hủy lô (SRS 7.2).
class MonitorScreen extends ConsumerWidget {
  const MonitorScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(monitorStateProvider(sessionId));
    final s = state.value;
    final paused = s?.session.status == SessionStatus.paused;
    final busy = ref.watch(adminActionsProvider).isLoading;

    Future<void> run(Future<Object?> Function() action) async {
      await action();
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    return AppPage(
      title: s?.session.title ?? l10n.navSessions,
      subtitle: s?.session.status.label(l10n),
      showBack: true,
      actions: [
        if (s != null && s.session.isLive)
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(
                    () => ref.read(adminActionsProvider.notifier).run(
                      (r) => paused ? r.resume(sessionId) : r.pause(sessionId),
                      [DataArea.auctions],
                    ),
                  ),
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 18,
            ),
            label: Text(paused ? l10n.resume : l10n.pause),
          ),
      ],
      children: [
        AsyncValueView(
          value: state,
          onRetry: () => ref.invalidate(monitorStateProvider(sessionId)),
          data: (s) {
            final current = _CurrentLot(state: s, onCancel: run);
            final feed = _Feed(state: s);
            if (context.windowSize == WindowSize.expanded) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: current),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(flex: 2, child: feed),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                current,
                const SizedBox(height: AppSpacing.lg),
                feed,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CurrentLot extends ConsumerWidget {
  const _CurrentLot({required this.state, required this.onCancel});

  final SessionState state;
  final Future<void> Function(Future<Object?> Function()) onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final lot = state.currentLot;
    if (lot == null) {
      return InfoPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(l10n.waitingNextLot),
      );
    }
    final offset = state.serverTime.difference(DateTime.now());
    final now = (ref.watch(clockProvider).value ?? DateTime.now()).add(offset);
    final remaining = lot.endsAt?.difference(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookPoster(
          title: lot.book.title,
          author: lot.book.author,
          coverUrl: lot.book.coverUrl,
          seed: lot.book.id,
          width: 180,
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.lotNumber(lot.lotNumber),
                style: context.textStyles.labelLarge?.copyWith(
                  color: c.secondaryText,
                ),
              ),
              Text(lot.book.title, style: context.textStyles.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              PriceText(
                lot.currentPrice,
                style: context.textStyles.displaySmall,
              ),
              Text(l10n.bidCount(lot.bidCount)),
              if (lot.leadingPaddle != null)
                Text(l10n.leadingPaddle(lot.leadingPaddle!)),
              if (remaining != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20, color: c.live),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      formatCountdown(
                        remaining.isNegative ? Duration.zero : remaining,
                      ),
                      style: context.textStyles.titleLarge,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                '${l10n.viewers(state.viewerCount)} · ${l10n.registeredCount(state.session.registeredCount)}',
                style: context.textStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.error,
                ),
                icon: const Icon(Icons.block_rounded, size: 18),
                label: Text(l10n.cancelLot),
                onPressed: () async {
                  final reason = await showCancelSheet(
                    context,
                    l10n.cancelLotReasons,
                    title: l10n.cancelLot,
                  );
                  if (reason == null) return;
                  await onCancel(
                    () => ref.read(adminActionsProvider.notifier).run(
                      (r) => r.cancelLot(lot.id, reason),
                      [DataArea.auctions],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.state});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          value,
        ],
      ),
    );

    return InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.liveFeed, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final b in state.recentBids.take(15))
            row(
              '${l10n.paddle(b.paddleNumber)} · ${formatDateTime(b.createdAt)}',
              Text(formatVnd(b.amount), style: context.textStyles.titleSmall),
            ),
          Divider(height: AppSpacing.xl, color: c.separator),
          for (final l in state.lots)
            row(
              '${l.lotNumber}. ${l.book.title}',
              StatusPill(l.status.label(l10n), tone: l.status.tone),
            ),
        ],
      ),
    );
  }
}
