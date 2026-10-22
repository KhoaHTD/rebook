import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/home/domain/home_feed.dart';
import 'package:book_marketplace/features/home/presentation/providers/home_providers.dart';
import 'package:book_marketplace/shared/domain/book.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_condition_badge.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/live_auction_card.dart';
import 'package:book_marketplace/shared/widgets/section_header.dart';
import 'package:book_marketplace/shared/widgets/segmented_pill.dart';

/// Trang chủ: tiêu đề lớn + chuyển kênh Mua sách / Đấu giá.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final channel = ref.watch(homeChannelSelectionProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(homeFeedProvider.future),
          child: MaxWidthBox(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.lg,
                0,
                AppSpacing.floatingBarInset,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.navHome,
                          style: context.textStyles.headlineLarge,
                        ),
                      ),
                      IconButton.filled(
                        tooltip: l10n.navProfile,
                        onPressed: () => context.go(Routes.profile),
                        icon: const Icon(Icons.person_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: SegmentedPill<HomeChannel>(
                    segments: [
                      (HomeChannel.buy, l10n.channelBuy),
                      (HomeChannel.auction, l10n.channelAuction),
                    ],
                    selected: channel,
                    onChanged: ref
                        .read(homeChannelSelectionProvider.notifier)
                        .select,
                  ),
                ),
                const SizedBox(height: 28),
                AsyncValueView(
                  value: ref.watch(homeFeedProvider),
                  onRetry: () => ref.invalidate(homeFeedProvider),
                  loading: const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  data: (feed) => AnimatedSwitcher(
                    duration: AppDurations.normal,
                    child: channel == HomeChannel.buy
                        ? _BuyChannel(key: const ValueKey('buy'), feed: feed)
                        : _AuctionChannel(
                            key: const ValueKey('auction'),
                            feed: feed,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Mua sách

class _BuyChannel extends StatelessWidget {
  const _BuyChannel({super.key, required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (feed.collection != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _CollectionHero(collection: feed.collection!),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (feed.newListings.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionHeader(
              title: l10n.newNearYou,
              onTap: () => context.push(Routes.search),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          SizedBox(
            height: 284,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                4,
                AppSpacing.md,
                8,
              ),
              itemCount: feed.newListings.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _BookTile(book: feed.newListings[i]),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (feed.categories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionHeader(title: l10n.browseByCategory),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: GridView.count(
              crossAxisCount: context.windowSize.isCompact ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.85,
              children: [
                for (final (i, c) in feed.categories.indexed)
                  _CategoryTile(
                    name: c.name,
                    color: AppPalette
                        .categoryTiles[i % AppPalette.categoryTiles.length],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _EscrowNote(),
        ),
      ],
    );
  }
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({required this.collection});

  final FeaturedCollection collection;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final covers = collection.coverUrls;
    return InkWell(
      onTap: () => context.push(Routes.search),
      borderRadius: AppRadius.group,
      child: Container(
        height: 210,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.collection,
          borderRadius: AppRadius.group,
        ),
        child: Stack(
          children: [
            // Ba bìa xếp quạt bên phải
            for (final (i, (dx, dy, angle, w)) in const [
              (0.0, 18.0, -10.0, 84.0),
              (70.0, 26.0, 9.0, 84.0),
              (34.0, 0.0, 0.0, 92.0),
            ].indexed)
              if (i < covers.length)
                Positioned(
                  right: 170 - dx - w - 6,
                  top: 26 + dy,
                  width: w,
                  child: Transform.rotate(
                    angle: angle * math.pi / 180,
                    child: BookCover(imageUrl: covers[i]),
                  ),
                ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.collectionCaps,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: colors.onDarkMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Flexible(
                    child: SizedBox(
                      width: 168,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              collection.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.headlineSmall?.copyWith(
                                color: colors.onDark,
                                height: 1.12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            collection.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: colors.onDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 124,
      child: InkWell(
        onTap: () => context.push(Routes.bookDetail(book.id)),
        borderRadius: AppRadius.chip,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(imageUrl: book.imageUrl, elevated: false),
            const SizedBox(height: AppSpacing.sm),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.titleSmall,
            ),
            Text(
              '${conditionLabel(context, book.condition)} · ${book.sellerName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.labelTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(formatVnd(book.price), style: context.textStyles.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: AppRadius.tile,
      child: InkWell(
        borderRadius: AppRadius.tile,
        onTap: () => context.push(Routes.search),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              name,
              style: context.textStyles.titleMedium?.copyWith(
                color: context.appColors.onDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EscrowNote extends StatelessWidget {
  const _EscrowNote();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.groupedBackground,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 28, color: colors.success),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.escrowTitle, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.escrowBody,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.labelTertiary,
                    height: 1.35,
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

// ---------------------------------------------------------------- Đấu giá

class _AuctionChannel extends StatelessWidget {
  const _AuctionChannel({super.key, required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final live = feed.liveLot;
    final showLive = live != null && live.endsAt.isAfter(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLive) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: LiveAuctionCard(
              title: live.title,
              imageUrl: live.imageUrl,
              currentPrice: live.currentPrice,
              endsAt: live.endsAt,
              sessionTitle: live.sessionTitle,
              lotNumber: live.lotNumber,
              lotCount: live.lotCount,
              onEnter: () => context.push(Routes.auctionRoom(live.id)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (feed.upcomingSessions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionHeader(title: l10n.upcomingSessions),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final s in feed.upcomingSessions)
            InkWell(
              onTap: () => context.push(Routes.lot(s.firstLotId)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.separator, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    DateBadge(date: s.startsAt),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: context.textStyles.titleSmall),
                          Text(
                            [
                              l10n.lotsCount(s.lotCount),
                              formatTime(s.startsAt),
                              if (s.deposit != null)
                                l10n.depositShort(formatVnd(s.deposit!)),
                            ].join(' · '),
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colors.labelTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.labelTertiary,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (feed.featuredLots.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionHeader(
              title: l10n.featuredLots,
              onTap: () => context.go(Routes.auctions),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                4,
                AppSpacing.md,
                8,
              ),
              itemCount: feed.featuredLots.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _LotTile(lot: feed.featuredLots[i]),
            ),
          ),
        ],
        if (!showLive &&
            feed.upcomingSessions.isEmpty &&
            feed.featuredLots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(child: Text(l10n.noAuctions)),
          ),
      ],
    );
  }
}

class _LotTile extends StatelessWidget {
  const _LotTile({required this.lot});

  final LotTeaser lot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return SizedBox(
      width: 124,
      child: InkWell(
        onTap: () => context.push(Routes.lot(lot.id)),
        borderRadius: AppRadius.chip,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(imageUrl: lot.imageUrl, elevated: false),
            const SizedBox(height: AppSpacing.sm),
            if (lot.lotNumber != null)
              Text(
                l10n.lotNumber(lot.lotNumber!).toUpperCase(),
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.labelTertiary,
                ),
              ),
            Text(
              lot.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.titleSmall,
            ),
            if (lot.estimateLow != null && lot.estimateHigh != null)
              Text(
                l10n.estimateShort(
                  formatMillionsRange(lot.estimateLow!, lot.estimateHigh!),
                ),
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.labelTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
