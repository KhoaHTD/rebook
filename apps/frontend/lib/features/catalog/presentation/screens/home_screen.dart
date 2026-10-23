import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/hero_carousel.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/home_blocks.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/home_blocks_b.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang "Mua sách": desktop là các khối lưới 4 poster/hàng, điện thoại là các kệ cuộn ngang.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(sessionControllerProvider).user;
    final feed = ref.watch(homeFeedProvider);
    final compact = context.windowSize.isCompact;

    Widget content(HomeFeed f) =>
        compact ? _MobileShelves(feed: f) : _DesktopSections(feed: f);

    return AppPage(
      title: compact
          ? l10n.navHome
          : (user == null
                ? l10n.homeGreetingGuest
                : l10n.homeGreeting(user.fullName.split(' ').last)),
      subtitle: compact ? null : l10n.homeTagline,
      onRefresh: () => ref.refresh(homeFeedProvider.future),
      contentPadding: compact ? EdgeInsets.zero : null,
      actions: [
        if (compact)
          IconButton(
            tooltip: l10n.search,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(Routes.search),
          ),
      ],
      children: [
        AsyncValueView(
          value: feed,
          onRetry: () => ref.invalidate(homeFeedProvider),
          loading: const Padding(
            padding: EdgeInsets.all(80),
            child: Center(child: CircularProgressIndicator()),
          ),
          data: content,
        ),
      ],
    );
  }
}

void _openListing(BuildContext context, String id) =>
    context.go(Routes.listing(id));

class _DesktopSections extends StatelessWidget {
  const _DesktopSections({required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget section(String title, VoidCallback onMore, List<Widget> tiles) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title, onTap: onMore),
              const SizedBox(height: AppSpacing.lg),
              PosterGrid(children: tiles),
            ],
          ),
        );

    Widget gap(Widget w) =>
        Padding(padding: const EdgeInsets.only(bottom: 56), child: w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: HeroCarousel(feed: feed),
        ),
        if (feed.trending.isNotEmpty)
          section(l10n.trending, () => context.go(Routes.search), [
            for (final l in feed.trending.take(8))
              ListingTile(listing: l, onTap: () => _openListing(context, l.id)),
          ]),
        gap(const HomeAuctions()),
        gap(const HomeCategories()),
        gap(HomeChart(feed: feed)),
        if (feed.newArrivals.isNotEmpty)
          section(l10n.newArrivals, () => context.go(Routes.search), [
            for (final l in feed.newArrivals.take(8))
              ListingTile(listing: l, onTap: () => _openListing(context, l.id)),
          ]),
        gap(const HomeRare()),
        gap(const HomeEditions()),
        gap(const HomePriceBands()),
        gap(HomeShops(feed: feed)),
      ],
    );
  }
}

class _MobileShelves extends StatelessWidget {
  const _MobileShelves({required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shelves = <Widget>[
      if (feed.trending.isNotEmpty)
        Shelf(
          title: l10n.trending,
          onSeeAll: () => context.go(Routes.search),
          children: [
            for (final l in feed.trending)
              ListingTile(listing: l, onTap: () => _openListing(context, l.id)),
          ],
        ),
      const _Pad(HomeAuctions()),
      const _Pad(HomeCategories()),
      if (feed.newArrivals.isNotEmpty)
        Shelf(
          title: l10n.newArrivals,
          onSeeAll: () => context.go(Routes.search),
          children: [
            for (final l in feed.newArrivals)
              ListingTile(listing: l, onTap: () => _openListing(context, l.id)),
          ],
        ),
      _Pad(HomeChart(feed: feed)),
      const _Pad(HomeRare()),
      const _Pad(HomeEditions()),
      const _Pad(HomePriceBands()),
      _Pad(HomeShops(feed: feed)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: HeroCarousel(feed: feed),
        ),
        for (var i = 0; i < shelves.length; i++)
          // Kệ chẵn phủ kính trong, kệ lẻ để lộ nền màu loang.
          shelves[i] is Shelf
              ? _alt(shelves[i] as Shelf, i.isEven)
              : shelves[i],
        const SizedBox(height: 110),
      ],
    );
  }

  Shelf _alt(Shelf s, bool alt) => Shelf(
    title: s.title,
    onSeeAll: s.onSeeAll,
    alt: alt,
    children: s.children,
  );
}

/// Khối trang chủ trên điện thoại: lề 20 hai bên + khoảng cách dọc.
class _Pad extends StatelessWidget {
  const _Pad(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 8), child: child);
}
