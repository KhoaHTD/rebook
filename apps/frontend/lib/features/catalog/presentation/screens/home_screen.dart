import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/session_tile.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (feed.trending.isNotEmpty)
          section(l10n.trending, () => context.go(Routes.search), [
            for (final l in feed.trending.take(8))
              ListingTile(listing: l, onTap: () => _openListing(context, l.id)),
          ]),
        if (feed.liveSessions.isNotEmpty)
          section(l10n.liveAuctions, () => context.go(Routes.auctions), [
            for (final s in feed.liveSessions.take(4))
              SessionTile(
                session: s,
                onTap: () => context.go(Routes.session(s.id)),
              ),
          ]),
        if (feed.newArrivals.isNotEmpty)
          section(l10n.newArrivals, () => context.go(Routes.search), [
            for (final l in feed.newArrivals.take(8))
              ListingTile(listing: l, onTap: () => _openListing(context, l.id)),
          ]),
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
      if (feed.liveSessions.isNotEmpty)
        Shelf(
          title: l10n.liveAuctions,
          onSeeAll: () => context.go(Routes.auctions),
          children: [
            for (final s in feed.liveSessions)
              SessionTile(
                session: s,
                onTap: () => context.go(Routes.session(s.id)),
              ),
          ],
        ),
      if (feed.newArrivals.isNotEmpty)
        Shelf(
          title: l10n.newArrivals,
          onSeeAll: () => context.go(Routes.search),
          children: [
            for (final l in feed.newArrivals)
              ListingTile(listing: l, onTap: () => _openListing(context, l.id)),
          ],
        ),
    ];
    return Column(
      children: [
        for (var i = 0; i < shelves.length; i++)
          // Kệ chẵn nền xám nhạt, kệ lẻ nền trắng — như mockup.
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
