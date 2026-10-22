import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/live_auction_card.dart';

/// Tab Đấu giá: lô đang diễn ra + các lô sắp mở theo lịch.
class AuctionListScreen extends ConsumerWidget {
  const AuctionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AsyncValueView(
          value: ref.watch(auctionListProvider),
          onRetry: () => ref.invalidate(auctionListProvider),
          data: (auctions) {
            final now = DateTime.now();
            final live = auctions.where((a) => a.isLiveAt(now)).toList();
            final upcoming =
                auctions
                    .where((a) => a.opensAt != null && a.opensAt!.isAfter(now))
                    .toList()
                  ..sort((a, b) => a.opensAt!.compareTo(b.opensAt!));

            return RefreshIndicator(
              onRefresh: () => ref.refresh(auctionListProvider.future),
              child: MaxWidthBox(
                maxWidth: 720,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.floatingBarInset,
                  ),
                  children: [
                    Text(
                      l10n.navAuctions,
                      style: context.textStyles.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final a in live) ...[
                      LiveAuctionCard(
                        title: a.book.title,
                        imageUrl: a.book.imageUrl,
                        currentPrice: a.currentPrice,
                        endsAt: a.endsAt,
                        sessionTitle: a.sessionTitle,
                        lotNumber: a.lotNumber,
                        lotCount: a.lotCount,
                        durationSeconds: a.lotDurationSeconds,
                        onEnter: () => context.push(Routes.auctionRoom(a.id)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      Text(
                        l10n.upcomingLots,
                        style: context.textStyles.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final a in upcoming) UpcomingLotRow(auction: a),
                    ],
                    if (live.isEmpty && upcoming.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxl),
                        child: Center(child: Text(l10n.noAuctions)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class UpcomingLotRow extends StatelessWidget {
  const UpcomingLotRow({super.key, required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final opens = auction.opensAt!;
    final meta = [
      if (auction.lotNumber != null) l10n.lotNumber(auction.lotNumber!),
      formatTime(opens),
      if (auction.estimateLow != null && auction.estimateHigh != null)
        l10n.estimateShort(
          formatMillionsRange(auction.estimateLow!, auction.estimateHigh!),
        ),
    ].join(' · ');

    return InkWell(
      onTap: () => context.push(Routes.lot(auction.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.separator, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            DateBadge(date: opens),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.book.title,
                    style: context.textStyles.titleSmall,
                  ),
                  if (auction.sessionTitle != null)
                    Text(
                      auction.sessionTitle!,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.labelTertiary,
                      ),
                    ),
                  Text(
                    meta,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.labelTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.labelTertiary),
          ],
        ),
      ),
    );
  }
}
