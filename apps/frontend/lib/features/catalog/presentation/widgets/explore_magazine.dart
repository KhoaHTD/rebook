import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/domain/explore_event.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/explore_events.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/explore_sections.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/cover_color.dart';

/// Phần thân trang Khám phá kiểu tạp chí: mỗi khối một kiểu — banner bộ sưu tập lớn, Top 10 đánh số, lưới bento các bộ,
/// tác giả / nhà xuất bản nổi bật, chủ đề, ô thể loại và thẻ mời sang sàn đấu giá. Rộng (≥ 700px) thì chia cột kiểu bento 12 cột.
/// Mọi bộ sưu tập tự dựng từ sách đang bán ([buildExploreEvents]); bộ không đủ sách thì không hiện.
class ExploreMagazine extends ConsumerWidget {
  const ExploreMagazine({super.key});

  static const _bentoKinds = [
    ExploreEventKind.newRelease,
    ExploreEventKind.cheap,
    ExploreEventKind.likeNew,
    ExploreEventKind.classics,
    ExploreEventKind.quickRead,
    ExploreEventKind.thick,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(exploreEventsProvider).value ?? const [];
    if (events.isEmpty) return const SizedBox.shrink();

    ExploreEvent? first(ExploreEventKind k) =>
        events.where((e) => e.kind == k).firstOrNull;
    List<ExploreEvent> all(ExploreEventKind k) =>
        events.where((e) => e.kind == k).toList();

    final top = first(ExploreEventKind.top);
    final pool = [for (final k in _bentoKinds) ...all(k)];
    // Banner lớn: "Dành cho bạn" nếu có, không thì bộ đầu tiên (Top 10 đã có hàng đánh số riêng bên dưới, tránh lặp);
    // chỉ khi chẳng còn bộ nào khác mới dùng Top 10 làm banner.
    final hero =
        first(ExploreEventKind.forYou) ??
        (pool.isEmpty ? top : pool.removeAt(0));
    if (hero == null) return const SizedBox.shrink();
    final authors = all(ExploreEventKind.author);
    final publishers = all(ExploreEventKind.publisher);
    final themes = all(ExploreEventKind.theme);

    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 700;
        final gap = wide ? AppSpacing.lg : AppSpacing.md;

        Widget block(IconData icon, String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExploreHeader(icon: icon, title: title),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        );

        // Hàng banner: trên rộng, banner lớn bên trái + hai ô thấp bên phải.
        final side = wide ? pool.take(2).toList() : const <ExploreEvent>[];
        final rest = wide ? pool.skip(2).toList() : pool;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: wide
                  ? SizedBox(
                      height: 300,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: ExploreEventCard(
                              event: hero,
                              style: EventCardStyle.hero,
                            ),
                          ),
                          if (side.isNotEmpty) ...[
                            SizedBox(width: gap),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  for (final (i, e) in side.indexed) ...[
                                    if (i > 0) SizedBox(height: gap),
                                    Expanded(child: ExploreEventCard(event: e)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ExploreEventCard(
                      event: hero,
                      style: EventCardStyle.hero,
                      height: 236,
                    ),
            ),
            if (top != null)
              block(
                Icons.emoji_events_rounded,
                l10n.exploreBlockTop,
                _TopTenRow(listings: top.listings),
              ),
            if (rest.isNotEmpty)
              block(
                Icons.dashboard_customize_rounded,
                l10n.exploreBlockCollections,
                wide ? _BentoWide(events: rest, gap: gap) : _BentoPhone(rest),
              ),
            if (authors.isNotEmpty || publishers.isNotEmpty)
              wide
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (authors.isNotEmpty)
                            Expanded(
                              child: _GroupBlock(
                                icon: Icons.edit_note_rounded,
                                title: l10n.exploreBlockAuthors,
                                events: authors,
                              ),
                            ),
                          if (authors.isNotEmpty && publishers.isNotEmpty)
                            SizedBox(width: gap),
                          if (publishers.isNotEmpty)
                            Expanded(
                              child: _GroupBlock(
                                icon: Icons.apartment_rounded,
                                title: l10n.exploreBlockPublishers,
                                events: publishers,
                              ),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authors.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxl,
                            ),
                            child: _GroupBlock(
                              icon: Icons.edit_note_rounded,
                              title: l10n.exploreBlockAuthors,
                              events: authors,
                            ),
                          ),
                        if (publishers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxl,
                            ),
                            child: _GroupBlock(
                              icon: Icons.apartment_rounded,
                              title: l10n.exploreBlockPublishers,
                              events: publishers,
                            ),
                          ),
                      ],
                    ),
            if (themes.isNotEmpty)
              block(
                Icons.palette_rounded,
                l10n.exploreBlockThemes,
                _EventGrid(
                  events: themes,
                  columns: wide ? 5 : 2,
                  gap: gap,
                  height: wide ? 150 : 122,
                ),
              ),
            block(
              Icons.category_rounded,
              l10n.exploreBlockCategories,
              _CategoryTiles(wide: wide, gap: gap),
            ),
            const _AuctionTeaser(),
          ],
        );
      },
    );
  }
}

/// Top 10: bìa kèm số thứ tự lớn, cuộn ngang.
class _TopTenRow extends StatelessWidget {
  const _TopTenRow({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: listings.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final l = listings[i];
          return GestureDetector(
            onTap: () => context.go(Routes.listing(l.id)),
            child: SizedBox(
              width: 150,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: -6,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 120,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: c.tint.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: BookPoster(
                      title: l.book.title,
                      author: l.book.author,
                      coverUrl: l.book.coverUrl,
                      seed: l.book.id,
                      width: 104,
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

/// Điện thoại: lưới bento hai cột so le — cột trái [cao, thấp], cột phải [thấp, cao]; bộ còn lại xếp từng cặp ô thấp.
class _BentoPhone extends StatelessWidget {
  const _BentoPhone(this.events);

  final List<ExploreEvent> events;

  @override
  Widget build(BuildContext context) {
    const gap = AppSpacing.md;
    const tallH = 212.0;
    const shortH = 124.0;
    Widget card(ExploreEvent e, EventCardStyle s, double h) =>
        ExploreEventCard(event: e, style: s, height: h);

    final head = events.take(4).toList();
    final tail = events.skip(4).toList();
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  if (head.isNotEmpty)
                    card(head[0], EventCardStyle.tall, tallH),
                  if (head.length > 2) ...[
                    const SizedBox(height: gap),
                    card(head[2], EventCardStyle.short, shortH),
                  ],
                ],
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  if (head.length > 1)
                    card(head[1], EventCardStyle.short, shortH),
                  if (head.length > 3) ...[
                    const SizedBox(height: gap),
                    card(head[3], EventCardStyle.tall, tallH),
                  ],
                ],
              ),
            ),
          ],
        ),
        for (var i = 0; i < tail.length; i += 2) ...[
          const SizedBox(height: gap),
          Row(
            children: [
              Expanded(child: card(tail[i], EventCardStyle.short, shortH)),
              const SizedBox(width: gap),
              Expanded(
                child: i + 1 < tail.length
                    ? card(tail[i + 1], EventCardStyle.short, shortH)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Màn rộng: các bộ còn lại xếp bốn ô cao mỗi hàng.
class _BentoWide extends StatelessWidget {
  const _BentoWide({required this.events, required this.gap});

  final List<ExploreEvent> events;
  final double gap;

  @override
  Widget build(BuildContext context) =>
      _EventGrid(events: events, columns: 4, gap: gap, height: 220, tall: true);
}

/// Lưới đều [columns] cột các thẻ bộ sưu tập.
class _EventGrid extends StatelessWidget {
  const _EventGrid({
    required this.events,
    required this.columns,
    required this.gap,
    required this.height,
    this.tall = false,
  });

  final List<ExploreEvent> events;
  final int columns;
  final double gap;
  final double height;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final e in events)
              SizedBox(
                width: w,
                child: ExploreEventCard(
                  event: e,
                  style: tall ? EventCardStyle.tall : EventCardStyle.short,
                  height: height,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Khối tác giả / nhà xuất bản nổi bật: hàng thẻ cuộn ngang, mỗi thẻ là các bìa xếp chồng + tên + số cuốn.
class _GroupBlock extends StatelessWidget {
  const _GroupBlock({
    required this.icon,
    required this.title,
    required this.events,
  });

  final IconData icon;
  final String title;
  final List<ExploreEvent> events;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = context.textStyles;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExploreHeader(icon: icon, title: title),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final e = events[i];
              return GestureDetector(
                onTap: () => context.go(Routes.exploreEvent(e.key)),
                child: Container(
                  width: 170,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.fill,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 84,
                        child: Center(
                          child: ExploreCoverFan(
                            books: e.listings.take(3).toList(),
                            big: false,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        e.subject ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l10n.exploreBookCount(e.count),
                        style: text.bodySmall?.copyWith(color: c.secondaryText),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Ô thể loại: tên + số cuốn + một bìa đại diện; bấm để xem hết sách của thể loại (sắp xếp theo phổ biến).
class _CategoryTiles extends ConsumerWidget {
  const _CategoryTiles({required this.wide, required this.gap});

  final bool wide;
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final text = context.textStyles;
    final l10n = context.l10n;
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final counts = ref.watch(categoryCountsProvider).value ?? const {};
    final listings = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final roots = [
      for (final cat in cats)
        if (cat.parentId == null && (counts[cat.id] ?? 0) > 0) cat,
    ];
    if (roots.isEmpty) return const SizedBox.shrink();

    Listing? coverOf(Category cat) {
      final ids = {
        cat.id,
        for (final x in cats)
          if (x.parentId == cat.id) x.id,
      };
      final inCat = [
        for (final l in listings)
          if (ids.contains(l.book.categoryId)) l,
      ]..sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
      return inCat.firstOrNull;
    }

    final columns = wide ? 4 : 2;
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final cat in roots)
              SizedBox(
                width: w,
                child: GestureDetector(
                  onTap: () => context.go(Routes.searchCategory(cat.id)),
                  child: Container(
                    height: 96,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: c.fill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.exploreBookCount(counts[cat.id] ?? 0),
                                style: text.bodySmall?.copyWith(
                                  color: c.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (coverOf(cat) case final cover?)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: BookPoster(
                              title: cover.book.title,
                              author: cover.book.author,
                              coverUrl: cover.book.coverUrl,
                              seed: cover.book.id,
                              width: 44,
                              shadow: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Thẻ nhỏ mời sang khu đấu giá (sách hiếm). Đấu giá là khu riêng nên ở đây chỉ là một lối vào.
class _AuctionTeaser extends StatelessWidget {
  const _AuctionTeaser();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final base = CoverColor.fallback('auction-teaser');
    return GestureDetector(
      onTap: () => context.go(Routes.auctions),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: exploreEventGradient(base),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CoverPalette.onHero.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: CoverPalette.onHero,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.exploreAuctionTeaserTitle,
                      style: text.titleMedium?.copyWith(
                        color: CoverPalette.onHero,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.exploreAuctionTeaserSub,
                      style: text.bodySmall?.copyWith(
                        color: CoverPalette.onHero.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${l10n.exploreAuctionTeaserCta} ›',
                      style: text.labelLarge?.copyWith(
                        color: CoverPalette.onHero,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
