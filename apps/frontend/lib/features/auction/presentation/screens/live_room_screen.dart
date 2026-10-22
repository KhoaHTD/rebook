import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/domain/live_reducer.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_widgets.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Phòng đấu giá trực tiếp (SRS 6.5, 10.3): server giữ đồng hồ và giá, app chỉ hiển thị.
/// Phủ toàn màn hình, không sidebar / tab bar.
class LiveRoomScreen extends ConsumerWidget {
  const LiveRoomScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(liveRoomProvider(sessionId));
    return Scaffold(
      body: SafeArea(
        child: AsyncValueView(
          value: room,
          onRetry: () => ref.invalidate(liveRoomProvider(sessionId)),
          data: (r) => _Room(sessionId: sessionId, room: r),
        ),
      ),
    );
  }
}

class _Room extends ConsumerWidget {
  const _Room({required this.sessionId, required this.room});

  final String sessionId;
  final RoomState room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = room.snapshot;
    final compact = context.windowSize.isCompact;
    final lot = s.currentLot;
    final upcoming = s.lots
        .where((l) => l.status == LotStatus.scheduled && l.id != lot?.id)
        .toList();

    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 24,
        12,
        compact ? 12 : 24,
        12,
      ),
      child: Row(
        children: [
          CircleBackButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(Routes.session(sessionId)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleLarge,
                ),
                Text(
                  l10n.viewers(s.viewerCount),
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          StatusPill(s.session.status.label(l10n), tone: s.session.status.tone),
          if (s.myRegistration != null) ...[
            const SizedBox(width: AppSpacing.sm),
            PillBadge(
              l10n.paddle(s.myRegistration!.paddleNumber),
              color: context.appColors.selected,
            ),
          ],
        ],
      ),
    );

    final Widget stage;
    if (s.session.status == SessionStatus.ended) {
      stage = EmptyState(
        icon: Icons.flag_rounded,
        title: l10n.sessionEndedHint,
        action: FilledButton(
          onPressed: () => context.go(Routes.results(sessionId)),
          child: Text(l10n.resultsTitle),
        ),
      );
    } else if (lot == null) {
      stage = EmptyState(
        icon: Icons.hourglass_top_rounded,
        title: l10n.waitingNextLot,
      );
    } else {
      final poster = BookPoster(
        title: lot.book.title,
        author: lot.book.author,
        coverUrl: lot.book.coverUrl,
        seed: lot.book.id,
        width: compact ? 170 : 300,
      );
      final lotInfo = Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lotNumber(lot.lotNumber),
            style: context.textStyles.bodySmall,
          ),
          Text(
            lot.book.title,
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: context.textStyles.headlineMedium,
          ),
          Text(
            lot.book.author,
            style: context.textStyles.titleMedium?.copyWith(
              color: context.appColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${l10n.estimate} ${formatVnd(lot.estimateLow)} – ${formatVnd(lot.estimateHigh)}',
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          StatusPill(
            lot.book.condition.label(l10n),
            tone: lot.book.condition.tone,
          ),
        ],
      );
      final panel = _BidPanel(sessionId: sessionId, room: room, lot: lot);
      final feed = _Feed(bids: s.recentBids);

      stage = compact
          ? ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Center(child: poster),
                const SizedBox(height: AppSpacing.lg),
                lotInfo,
                const SizedBox(height: AppSpacing.lg),
                panel,
                const SizedBox(height: AppSpacing.lg),
                feed,
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _UpNext(lots: upcoming),
                ],
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.md,
                AppSpacing.pageX,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      poster,
                      const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            lotInfo,
                            const SizedBox(height: AppSpacing.xl),
                            feed,
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                      SizedBox(width: 360, child: panel),
                    ],
                  ),
                  if (upcoming.isNotEmpty) ...[
                    const SizedBox(height: 56),
                    _UpNext(lots: upcoming),
                  ],
                ],
              ),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Divider(height: 1, color: context.appColors.separator),
        if (s.session.status == SessionStatus.paused)
          Container(
            color: context.appColors.warning.withValues(alpha: 0.12),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              l10n.sessionPausedHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.warning),
            ),
          ),
        Expanded(child: stage),
      ],
    );
  }
}

/// Giá hiện tại, đồng hồ, nhịp gõ búa, nút "Trả Xđ", trả giá tự động, hạn mức.
class _BidPanel extends ConsumerWidget {
  const _BidPanel({
    required this.sessionId,
    required this.room,
    required this.lot,
  });

  final String sessionId;
  final RoomState room;
  final Lot lot;

  Future<void> _proxy(
    BuildContext context,
    WidgetRef ref,
    int minAmount,
  ) async {
    final l10n = context.l10n;
    final ctrl = TextEditingController(text: '$minAmount');
    final max = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(c).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.proxyBid, style: c.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.proxyBidHint, style: c.textStyles.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.proxyMax),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(c, int.tryParse(ctrl.text)),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
    if (max == null || max < minAmount) return;
    final ok = await ref
        .read(bidActionProvider(sessionId).notifier)
        .setProxy(lot.id, max);
    if (!context.mounted) return;
    ok
        ? showInfoSnack(context, l10n.proxySet)
        : showErrorSnack(
            context,
            ref.read(bidActionProvider(sessionId)).error!,
          );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final s = room.snapshot;
    final reg = s.myRegistration;
    final now = (ref.watch(clockProvider).value ?? DateTime.now()).add(
      room.serverOffset,
    );
    final remaining = lot.endsAt == null
        ? Duration.zero
        : lot.endsAt!.difference(now);
    final phase = hammerPhase(remaining);
    final next = nextBidAmount(
      currentPrice: lot.currentPrice,
      bidCount: lot.bidCount,
    );
    final block = bidBlockFor(s, nextAmount: next);
    final busy = ref.watch(bidActionProvider(sessionId)).isLoading;

    final phaseText = switch (phase) {
      HammerPhase.open => null,
      HammerPhase.firstCall => l10n.hammerFirst,
      HammerPhase.secondCall => l10n.hammerSecond,
      HammerPhase.closed =>
        lot.bidCount > 0 ? l10n.hammerSold : l10n.hammerUnsold,
    };
    final blockText = switch (block) {
      BidBlock.none => null,
      BidBlock.notRegistered => l10n.notRegisteredHint,
      BidBlock.notLive => l10n.waitingNextLot,
      BidBlock.leading => l10n.youLeading,
      BidBlock.overLimit => l10n.overLimitHint,
    };

    return InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.currentPrice, style: context.textStyles.bodySmall),
          PriceText(
            lot.currentPrice,
            style: context.textStyles.displaySmall?.copyWith(
              fontFamily: AppFonts.sans,
            ),
          ),
          Text(
            lot.leadingPaddle == null
                ? l10n.bidCount(lot.bidCount)
                : (reg != null && lot.leadingPaddle == reg.paddleNumber
                      ? l10n.youLeading
                      : l10n.leadingPaddle(lot.leadingPaddle!)),
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.timer_outlined, color: c.live),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatCountdown(remaining),
                style: context.textStyles.headlineMedium?.copyWith(
                  fontFamily: AppFonts.sans,
                  color: phase == HammerPhase.open ? null : c.live,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (phaseText != null)
                Flexible(
                  child: Text(
                    phaseText,
                    style: context.textStyles.titleMedium?.copyWith(
                      color: c.live,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed:
                block != BidBlock.none || busy || phase == HammerPhase.closed
                ? null
                : () async {
                    final ok = await ref
                        .read(bidActionProvider(sessionId).notifier)
                        .bid(lot.id, next);
                    if (!ok && context.mounted) {
                      showErrorSnack(
                        context,
                        ref.read(bidActionProvider(sessionId)).error!,
                      );
                    }
                  },
            child: Text(l10n.placeBid(formatVnd(next))),
          ),
          if (blockText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              blockText,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall,
            ),
          ],
          if (block == BidBlock.notRegistered && s.session.isLive) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => context.go(Routes.sessionRegister(sessionId)),
              child: Text(l10n.registerToBid),
            ),
          ],
          if (reg != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: busy ? null : () => _proxy(context, ref, next),
              child: Text(l10n.proxyBid),
            ),
            Text(
              l10n.limitLeft(formatVnd(reg.remainingLimit)),
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.bids});

  final List<Bid> bids;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.liveFeed, style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (bids.isEmpty)
          Text(
            l10n.noBids,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.appColors.secondaryText,
            ),
          )
        else
          for (final (i, b) in bids.take(8).indexed)
            BidRow(bid: b, highlight: i == 0),
      ],
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext({required this.lots});

  final List<Lot> lots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.l10n.nextLots),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final l in lots)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: SizedBox(
                    width: 120,
                    child: LotTile(
                      lot: l,
                      onTap: () => context.push(Routes.lot(l.id)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
