import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/countdown_text.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/price_text.dart';

class AuctionListScreen extends ConsumerWidget {
  const AuctionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navAuctions)),
      body: MaxWidthBox(
        maxWidth: 840,
        child: AsyncValueView(
          value: ref.watch(auctionListProvider),
          onRetry: () => ref.invalidate(auctionListProvider),
          data: (auctions) => RefreshIndicator(
            onRefresh: () => ref.refresh(auctionListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: auctions.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _AuctionTile(auction: auctions[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuctionTile extends StatelessWidget {
  const _AuctionTile({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surfaceContainerLow,
      child: InkWell(
        onTap: () => context.go(Routes.auctionRoom(auction.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: BookCover(imageUrl: auction.book.imageUrl),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.book.title,
                      style: context.textStyles.titleMedium,
                    ),
                    Text(
                      context.l10n.auctionBidCount(auction.bidCount),
                      style: context.textStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    CountdownText(endsAt: auction.endsAt),
                  ],
                ),
              ),
              PriceText(auction.currentPrice),
            ],
          ),
        ),
      ),
    );
  }
}
