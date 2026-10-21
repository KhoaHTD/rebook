import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/countdown_text.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/price_text.dart';

class AuctionRoomScreen extends ConsumerWidget {
  const AuctionRoomScreen({super.key, required this.auctionId});

  final String auctionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: AsyncValueView(
        value: ref.watch(auctionRoomProvider(auctionId)),
        onRetry: () => ref.invalidate(auctionRoomProvider(auctionId)),
        data: (auction) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: MaxWidthBox(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 200,
                    child: BookCover(imageUrl: auction.book.imageUrl),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  auction.book.title,
                  style: context.textStyles.headlineSmall,
                ),
                Text(
                  auction.book.author,
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PricePanel(auction: auction),
                const SizedBox(height: AppSpacing.lg),
                _BidButton(auction: auction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.auctionCurrentPrice,
              style: context.textStyles.labelLarge,
            ),
            AnimatedSwitcher(
              duration: AppDurations.normal,
              child: PriceText(
                auction.currentPrice,
                key: ValueKey(auction.currentPrice),
                style: context.textStyles.displaySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.auctionBidCount(auction.bidCount)),
            if (auction.highestBidder != null)
              Text(l10n.auctionHighestBidder(auction.highestBidder!)),
            const SizedBox(height: AppSpacing.sm),
            CountdownText(endsAt: auction.endsAt),
          ],
        ),
      ),
    );
  }
}

class _BidButton extends ConsumerWidget {
  const _BidButton({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bid = ref.watch(bidControllerProvider(auction.id));
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final ended = auction.isEndedAt(now);

    Future<void> submit() async {
      final ok = await ref
          .read(bidControllerProvider(auction.id).notifier)
          .placeBid(auction.nextMinBid);
      if (!context.mounted) return;
      final state = ref.read(bidControllerProvider(auction.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? context.l10n.bidPlaced : errorMessage(context, state.error!),
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: ended || bid.isLoading ? null : submit,
      icon: bid.isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.gavel),
      label: Text(context.l10n.placeBid(formatVnd(auction.nextMinBid))),
    );
  }
}
