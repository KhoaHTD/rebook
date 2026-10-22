import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/max_bid_sheet.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/live_badge.dart';

/// Phòng đấu giá trực tiếp: nền tối ấm, giá hiện tại to, vòng đếm ngược,
/// dòng lượt trả giá, nút "Trả X đ" một chạm và công tắc giá tối đa tự trả.
class AuctionRoomScreen extends ConsumerWidget {
  const AuctionRoomScreen({super.key, required this.auctionId});

  final String auctionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.room.last,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.4, -1),
            radius: 1.4,
            colors: colors.room,
            stops: const [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Theme(
            data: context.theme.copyWith(
              textTheme: context.textStyles.apply(
                bodyColor: colors.onDark,
                displayColor: colors.onDark,
              ),
            ),
            child: AsyncValueView(
              value: ref.watch(auctionRoomProvider(auctionId)),
              onRetry: () => ref.invalidate(auctionRoomProvider(auctionId)),
              data: (auction) =>
                  MaxWidthBox(maxWidth: 520, child: _Room(auction: auction)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Room extends ConsumerWidget {
  const _Room({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final ended = auction.isEndedAt(now);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(auction: auction, ended: ended),
          const SizedBox(height: 14),
          _LotInfo(auction: auction),
          const SizedBox(height: 14),
          _PriceCard(auction: auction, now: now),
          const SizedBox(height: 14),
          Expanded(
            child: _BidFeed(auction: auction, now: now),
          ),
          const SizedBox(height: 14),
          if (ended)
            _ResultCard(auction: auction)
          else
            _BidControls(auction: auction),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.auction, required this.ended});

  final Auction auction;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Row(
      children: [
        GlassIconButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: l10n.minimizeRoom,
          onDark: true,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.lot(auction.id)),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!ended) const LiveBadge(),
              if (auction.lotNumber != null && auction.lotCount != null) ...[
                if (!ended) const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.lotOfCount(auction.lotNumber!, auction.lotCount!),
                  style: context.textStyles.labelLarge,
                ),
              ],
            ],
          ),
        ),
        if (auction.viewerCount != null)
          GlassSurface(
            onDark: true,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: AppSizes.touch,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: colors.onDark,
                    semanticLabel: l10n.viewers,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${auction.viewerCount}',
                    style: context.textStyles.labelLarge,
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(width: AppSizes.touch),
      ],
    );
  }
}

class _LotInfo extends StatelessWidget {
  const _LotInfo({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: colors.onDarkMuted,
    );
    final reserve = auction.reserveMet;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: 104, child: BookCover(imageUrl: auction.book.imageUrl)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (auction.sessionTitle != null)
                Text(auction.sessionTitle!, style: muted),
              Text(
                auction.book.title,
                style: context.textStyles.headlineSmall?.copyWith(height: 1.1),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [auction.book.author, ?auction.edition].join(' · '),
                style: muted,
              ),
              if (auction.estimateLow != null && auction.estimateHigh != null)
                Text(
                  l10n.estimateMillions(
                    formatMillionsRange(
                      auction.estimateLow!,
                      auction.estimateHigh!,
                    ),
                  ),
                  style: muted,
                ),
              if (reserve != null) ...[
                const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: reserve
                        ? colors.positiveOnDark.withValues(alpha: 0.2)
                        : colors.glassOnDark,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    reserve ? l10n.reserveMet : l10n.reserveNotMet,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: reserve
                          ? colors.positiveOnDark
                          : colors.onDarkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.auction, required this.now});

  final Auction auction;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final left = auction.endsAt.difference(now);
    final ended = left <= Duration.zero;
    final ratio = (left.inMilliseconds / (auction.lotDurationSeconds * 1000))
        .clamp(0.0, 1.0);
    final youBid = auction.recentBids.any((b) => b.isYou);
    final (status, statusColor) = ended
        ? (l10n.hammerDown, colors.onDarkMuted)
        : auction.youAreLeading
        ? (l10n.youAreLeading, colors.positiveOnDark)
        : auction.bidCount == 0
        ? (l10n.noBidsYet, colors.onDarkMuted)
        : youBid
        ? (l10n.outbid, colors.warningOnDark)
        : (l10n.leadingBy(auction.highestBidder ?? ''), colors.onDarkMuted);

    return GlassSurface(
      onDark: true,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.auctionCurrentPrice,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onDarkMuted,
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppDurations.normal,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: FittedBox(
                    key: ValueKey(auction.currentPrice),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatVnd(auction.currentPrice),
                      style: context.textStyles.displaySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                Text(
                  status,
                  style: context.textStyles.titleSmall?.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: left.inSeconds <= 10
                        ? colors.dangerOnDark
                        : colors.onDark,
                    backgroundColor: colors.onDark.withValues(alpha: 0.18),
                    semanticsLabel: l10n.timeLeft(formatClock(left)),
                  ),
                ),
                Center(
                  child: Text(
                    formatClock(left),
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (auction.softCloseExtended && !ended)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.warningOnDark,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        l10n.softCloseBonus,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.strongSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BidFeed extends StatelessWidget {
  const _BidFeed({required this.auction, required this.now});

  final Auction auction;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bids = auction.recentBids;

    return GlassSurface(
      onDark: true,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: bids.isEmpty
          ? Center(
              child: Text(
                l10n.noBidsYet,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onDarkMuted,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: bids.length,
              separatorBuilder: (_, _) => Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Divider(color: colors.onDark.withValues(alpha: 0.12)),
              ),
              itemBuilder: (context, i) {
                final b = bids[i];
                final ago = now.difference(b.at).inSeconds;
                final note = b.auto
                    ? l10n.autoBidNote
                    : ago < 5
                    ? l10n.justNow
                    : l10n.secondsAgo(ago);
                return Opacity(
                  key: ValueKey('${b.paddle}-${b.amount}'),
                  opacity: i == 0 ? 1 : (0.9 - i * 0.12).clamp(0.45, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: b.isYou
                              ? context.colors.primary
                              : colors.onDark.withValues(alpha: 0.22),
                          child: Text(
                            b.isYou ? l10n.youInitials : b.paddle,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: colors.onDark,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.isYou
                                    ? l10n.you
                                    : l10n.bidderPaddle(b.paddle),
                                style: context.textStyles.titleSmall,
                              ),
                              Text(
                                note,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: colors.onDarkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatVnd(b.amount),
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BidControls extends ConsumerWidget {
  const _BidControls({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bid = ref.watch(bidControllerProvider(auction.id));
    final next = auction.nextMinBid;
    final overLimit = auction.exceedsLimit(next);
    final leading = auction.youAreLeading;
    final disabled = leading || overLimit || bid.isLoading;
    final controller = ref.read(bidControllerProvider(auction.id).notifier);

    void report(bool ok, String success) {
      if (!context.mounted) return;
      final error = ref.read(bidControllerProvider(auction.id)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? success : _bidError(context, error!))),
      );
    }

    Future<void> placeBid() async {
      final ok = await controller.placeBid(next);
      report(ok, l10n.bidPlaced);
    }

    Future<void> toggleProxy(bool on) async {
      if (!on) {
        final ok = await controller.setProxy(null);
        report(ok, l10n.maxBidOff);
        return;
      }
      final amount = await showMaxBidSheet(
        context,
        minimum: next,
        limit: auction.bidLimit,
        suggested: next + auction.minIncrement * 4,
      );
      if (amount == null) return;
      final ok = await controller.setProxy(amount);
      report(ok, l10n.maxBidOn(formatVnd(amount)));
    }

    final label = leading
        ? l10n.youAreLeading
        : overLimit
        ? l10n.overBidLimit
        : l10n.placeBid(formatVnd(next));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSurface(
          onDark: true,
          borderRadius: AppRadius.group,
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.proxyMax == null
                          ? l10n.maxBidTitle
                          : l10n.maxBidTitleWithAmount(
                              formatVnd(auction.proxyMax!),
                            ),
                      style: context.textStyles.titleSmall,
                    ),
                    Text(
                      l10n.maxBidHint,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.onDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: auction.proxyMax != null,
                onChanged: bid.isLoading ? null : toggleProxy,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        SizedBox(
          height: AppSizes.bidButtonHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: FilledButton(
              onPressed: disabled ? null : placeBid,
              style: FilledButton.styleFrom(
                disabledBackgroundColor: colors.glassOnDark,
                disabledForegroundColor: colors.onDarkMuted,
                textStyle: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: bid.isLoading
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colors.onDark,
                      ),
                    )
                  : Text(label),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Text(
          [
            if (auction.bidLimit != null)
              l10n.bidLimitInfo(formatVnd(auction.bidLimit!)),
            l10n.bidStepInfo(formatVnd(auction.minIncrement)),
            l10n.buyerPremiumInfo(10),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.onDarkMuted,
          ),
        ),
      ],
    );
  }
}

/// Lỗi 409 khi trả giá = người khác vừa trả trước hoặc lô đã đóng → báo rõ thay vì "lỗi máy chủ".
String _bidError(BuildContext context, Object error) {
  final e = AppException.from(error);
  if (e is ServerException && e.statusCode == 409) {
    return context.l10n.bidPriceChanged;
  }
  if (e is ServerException && e.statusCode == 400) {
    return context.l10n.overBidLimit;
  }
  return errorMessage(context, error);
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final premium = (auction.currentPrice * 0.1).round();
    final (title, body) = auction.reserveMet == false
        ? (l10n.resultReserveNotMet, l10n.resultReserveNotMetBody)
        : auction.youAreLeading
        ? (
            l10n.resultYouWon,
            l10n.resultYouWonBody(
              formatVnd(auction.currentPrice),
              formatVnd(premium),
            ),
          )
        : (
            l10n.resultSold,
            l10n.resultSoldBody(
              auction.highestBidder ?? '',
              formatVnd(auction.currentPrice),
            ),
          );

    return GlassSurface(
      onDark: true,
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            l10n.hammerDownCaps,
            style: context.textStyles.labelMedium?.copyWith(
              color: colors.onDarkMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: context.textStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.onDarkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go(Routes.auctions),
              style: FilledButton.styleFrom(
                backgroundColor: colors.onDark,
                foregroundColor: colors.strongSurface,
              ),
              child: Text(l10n.backToAuctions),
            ),
          ),
        ],
      ),
    );
  }
}
