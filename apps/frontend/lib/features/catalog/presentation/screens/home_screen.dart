import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/mode_switch.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/hero_carousel.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/home_blocks.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/home_blocks_b.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/cover_flow_home.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang "Mua sách": desktop là các khối lưới 4 poster/hàng; điện thoại là [CoverFlowHome]
/// (nền màu theo bìa, hàng bìa lớn, tờ giấy trượt lên chứa tab thể loại và các kệ 3,5 cuốn).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(sessionControllerProvider).user;
    final feed = ref.watch(homeFeedProvider);
    final compact = context.windowSize.isCompact;
    if (compact) return const _MobileHome();

    Widget content(HomeFeed f) => _DesktopSections(feed: f);

    return AppPage(
      title: user == null
          ? l10n.homeGreetingGuest
          : l10n.homeGreeting(user.fullName.split(' ').last),
      subtitle: l10n.homeTagline,
      onRefresh: () => ref.refresh(homeFeedProvider.future),
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
        gap(const AuctionEntryBanner()),
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

/// Điện thoại: dữ liệu thật cho [CoverFlowHome]. Tab "Tất cả" là các kệ Mới / Đang được săn / theo danh mục;
/// tab một danh mục chỉ gồm sách của danh mục đó (và danh mục con), kệ mới nhất rồi kệ giá tốt.
class _MobileHome extends ConsumerStatefulWidget {
  const _MobileHome();

  @override
  ConsumerState<_MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends ConsumerState<_MobileHome> {
  int _tab = 0;

  CoverFlowEntry _entry(BuildContext context, Listing l) => CoverFlowEntry(
    id: l.id,
    title: l.book.title,
    author: l.book.author,
    coverUrl: l.book.coverUrl,
    price: formatVnd(l.price),
    onTap: () => _openListing(context, l.id),
  );

  CoverFlowShelf? _shelf(
    BuildContext context,
    String label,
    Iterable<Listing> items,
  ) {
    final entries = [for (final l in items.take(10)) _entry(context, l)];
    return entries.isEmpty ? null : CoverFlowShelf(label, entries);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feed = ref.watch(homeFeedProvider);
    final all = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final allCats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final cats = allCats.where((c) => c.parentId == null).toList();
    // Sách có thể nằm ở danh mục con: tính cả con của danh mục gốc.
    bool inCategory(Listing l, Category c) {
      final id = l.book.categoryId;
      return id == c.id || allCats.any((x) => x.id == id && x.parentId == c.id);
    }

    final tab = _tab.clamp(0, cats.length);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(homeFeedProvider),
          child: Text(l10n.retry),
        ),
      ),
      data: (f) {
        final shelves = <CoverFlowShelf>[];
        if (tab == 0) {
          shelves.addAll([
            ?_shelf(context, l10n.newArrivals, f.newArrivals),
            ?_shelf(context, l10n.trending, f.trending),
          ]);
          for (final c in cats) {
            final shelf = _shelf(
              context,
              c.name,
              all.where((l) => inCategory(l, c)),
            );
            if (shelf != null) shelves.add(shelf);
          }
        } else {
          final cat = cats[tab - 1];
          final inCat = all.where((l) => inCategory(l, cat)).toList();
          final newest = [...inCat]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final cheap = [...inCat]..sort((a, b) => a.price.compareTo(b.price));
          shelves.addAll([
            ?_shelf(context, l10n.newArrivals, newest),
            if (inCat.length > 3) ?_shelf(context, l10n.homeShelfCheap, cheap),
          ]);
        }
        final heroSource = f.trending.isNotEmpty ? f.trending : f.newArrivals;
        return CoverFlowHome(
          title: l10n.homeExploreTitle,
          top: const ModeSwitch(mode: AppMode.books, onHero: true),
          onSearch: () => context.go(Routes.search),
          hero: [for (final l in heroSource.take(5)) _entry(context, l)],
          tabs: [l10n.allCategories, for (final c in cats) c.name],
          tabIndex: tab,
          onTab: (i) => setState(() => _tab = i),
          shelves: shelves,
          emptyText: l10n.homeShelfEmpty,
        );
      },
    );
  }
}
