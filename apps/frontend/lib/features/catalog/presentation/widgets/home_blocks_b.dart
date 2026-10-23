import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/home_blocks.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

String _searchPath({String? category}) => category == null
    ? Routes.search
    : Uri(
        path: Routes.search,
        queryParameters: {'category': category},
      ).toString();

// ───────────────────── Duyệt theo danh mục (mosaic) ─────────────────────

/// Tên tranh theo mã danh mục gốc (`assets/banners/<tên>.webp`); danh mục khác dùng nền bìa mờ.
const _categoryArt = <String, String>{
  'c1': 'cat-vn',
  'c2': 'cat-foreign',
  'c3': 'cat-textbook',
  'c5': 'cat-skills',
  'c6': 'cat-kids',
  'c7': 'cat-rare',
};

/// Mỗi danh mục gốc là một ô nền mờ + quạt bìa; ô đầu và ô cuối rộng gấp đôi cho nhịp không đều.
class HomeCategories extends ConsumerWidget {
  const HomeCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final listings = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final roots = cats.where((c) => c.parentId == null).toList();
    final tiles = <(Category, List<Listing>)>[
      for (final r in roots)
        (
          r,
          [
            for (final l in listings)
              if (l.book.categoryId == r.id ||
                  cats.any(
                    (c) => c.parentId == r.id && c.id == l.book.categoryId,
                  ))
                l,
          ],
        ),
    ].where((t) => t.$2.isNotEmpty).take(6).toList();
    if (tiles.isEmpty) return const SizedBox.shrink();

    Widget tile((Category, List<Listing>) t, double w, double h) {
      final covers = [for (final l in t.$2.take(3)) coverOfBook(l.book)];
      final onDark = context.appColors.onSelected;
      return SizedBox(
        width: w,
        child: BlurPanel(
          art: _categoryArt[t.$1.id],
          cover: covers.first,
          height: h,
          onTap: () => context.go(_searchPath(category: t.$1.id)),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: CoverFan(
                  covers: covers,
                  width: (h * 0.34).clamp(48, 92),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.$1.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.headlineSmall?.copyWith(
                        color: onDark,
                      ),
                    ),
                    Text(
                      l10n.hsListingsN(t.$2.length),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: onDark.withValues(alpha: 0.85),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeader(l10n.hsCategoriesTitle, sub: l10n.hsCategoriesSub),
        LayoutBuilder(
          builder: (context, box) {
            const gap = AppSpacing.md;
            final cols = compact ? 2 : 4;
            final unit = (box.maxWidth - gap * (cols - 1)) / cols;
            double span(int i) =>
                compact ? (i == 0 ? 2 : 1) : (i == 0 || i == 5 ? 2 : 1);
            final h = compact ? 168.0 : 232.0;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (i, t) in tiles.indexed)
                  tile(t, unit * span(i) + gap * (span(i) - 1), h),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ───────────────────── Bảng xếp hạng ─────────────────────

/// Danh sách đánh số lớn (kiểu bảng xếp hạng Apple Books) trên nền mờ của cuốn đứng đầu.
class HomeChart extends ConsumerWidget {
  const HomeChart({super.key, required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final c = context.appColors;
    final top = feed.trending.take(compact ? 5 : 6).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    Widget row(int i, Listing l) => InkWell(
      borderRadius: AppRadius.card,
      onTap: () => context.go(Routes.listing(l.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '${i + 1}',
                textAlign: TextAlign.center,
                style: context.textStyles.displaySmall?.copyWith(
                  color: c.tertiaryText,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            BookPoster(
              title: l.book.title,
              author: l.book.author,
              coverUrl: l.book.coverUrl,
              seed: l.book.id,
              width: 52,
              shadow: false,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleMedium,
                  ),
                  Text(
                    l.book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall,
                  ),
                ],
              ),
            ),
            PriceText(l.price),
          ],
        ),
      ),
    );

    final half = (top.length / 2).ceil();
    final body = compact
        ? Column(children: [for (final (i, l) in top.indexed) row(i, l)])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final (i, l) in top.take(half).indexed) row(i, l),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    for (final (i, l) in top.skip(half).indexed)
                      row(i + half, l),
                  ],
                ),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeader(l10n.hsChartTitle, sub: l10n.hsChartSub),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: BlurredCover(
                  title: top.first.book.title,
                  author: top.first.book.author,
                  coverUrl: top.first.book.coverUrl,
                  seed: top.first.book.id,
                  sigma: 48,
                ),
              ),
              Positioned.fill(
                child: ColoredBox(color: c.background.withValues(alpha: 0.6)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────── Sách hiếm & cổ ─────────────────────

/// Một cuốn đắt nhất được "chiếu sáng": poster nghiêng lớn, mô tả, giá, cùng 3 cuốn kế bên — nền tối mờ.
class HomeRare extends ConsumerWidget {
  const HomeRare({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final onDark = context.appColors.onSelected;
    final all = [...(ref.watch(allListingsProvider).value ?? const <Listing>[])]
      ..sort((a, b) => b.price.compareTo(a.price));
    if (all.length < 3) return const SizedBox.shrink();
    final hero = all.first;
    final rest = all.skip(1).take(3).toList();

    final posterW = compact ? 130.0 : 210.0;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.hsRareTitle.toUpperCase(),
          style: context.textStyles.labelSmall?.copyWith(
            color: onDark.withValues(alpha: 0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hero.book.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.displaySmall?.copyWith(color: onDark),
        ),
        Text(
          hero.book.author,
          style: context.textStyles.titleMedium?.copyWith(
            color: onDark.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (hero.book.description != null)
          Text(
            hero.book.description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium?.copyWith(
              color: onDark.withValues(alpha: 0.85),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              formatVnd(hero.price),
              style: context.textStyles.headlineSmall?.copyWith(color: onDark),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go(Routes.listing(hero.id)),
              child: Text(l10n.hsRareCta),
            ),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeader(l10n.hsRareTitle, sub: l10n.hsRareSub),
        BlurPanel(
          art: 'rare-spotlight',
          cover: coverOfBook(hero.book),
          radius: 32,
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
          child: compact
              ? Column(
                  children: [
                    Transform.rotate(
                      angle: -0.05,
                      child: BookPoster(
                        title: hero.book.title,
                        author: hero.book.author,
                        coverUrl: hero.book.coverUrl,
                        seed: hero.book.id,
                        width: posterW,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    info,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.05,
                      child: BookPoster(
                        title: hero.book.title,
                        author: hero.book.author,
                        coverUrl: hero.book.coverUrl,
                        seed: hero.book.id,
                        width: posterW,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    Expanded(child: info),
                    const SizedBox(width: AppSpacing.xl),
                    for (final l in rest)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: GestureDetector(
                          onTap: () => context.go(Routes.listing(l.id)),
                          child: BookPoster(
                            title: l.book.title,
                            author: l.book.author,
                            coverUrl: l.book.coverUrl,
                            seed: l.book.id,
                            width: 104,
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

// ───────────────────── Cùng một cuốn, nhiều ấn bản ─────────────────────

class HomeEditions extends ConsumerWidget {
  const HomeEditions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final listings = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final groups = <String, List<Listing>>{};
    for (final l in listings) {
      groups.putIfAbsent(l.book.title, () => []).add(l);
    }
    final multi = groups.values.where((g) => g.length >= 2).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (multi.isEmpty) return const SizedBox.shrink();

    Widget card(List<Listing> g) {
      final cheapest = g.reduce((a, b) => a.price <= b.price ? a : b);
      final covers = [for (final l in g.take(3)) coverOfBook(l.book)];
      return SizedBox(
        width: compact ? 300 : null,
        child: BlurPanel(
          cover: covers.first,
          dark: false,
          height: 290,
          onTap: () => context.go(Routes.listing(cheapest.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(child: CoverFan(covers: covers, width: 88)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                cheapest.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleLarge,
              ),
              Text(
                '${l10n.hsEditionsN(g.length)} · ${l10n.hsFrom(formatVnd(cheapest.price))}',
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final cards = multi.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeader(l10n.hsEditionsTitle, sub: l10n.hsEditionsSub),
        if (compact)
          SizedBox(
            height: 290,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                for (final g in cards)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: card(g),
                  ),
              ],
            ),
          )
        else
          Row(
            children: [
              for (final (i, g) in cards.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: card(g)),
              ],
            ],
          ),
      ],
    );
  }
}

// ───────────────────── Theo túi tiền ─────────────────────

class HomePriceBands extends ConsumerWidget {
  const HomePriceBands({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final onDark = context.appColors.onSelected;
    final listings = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final bands = [
      (l10n.hsPriceLow, listings.where((l) => l.price < 50000).toList()),
      (
        l10n.hsPriceMid,
        listings.where((l) => l.price >= 50000 && l.price <= 100000).toList(),
      ),
      (l10n.hsPriceHigh, listings.where((l) => l.price > 100000).toList()),
    ].where((b) => b.$2.isNotEmpty).toList();
    if (bands.isEmpty) return const SizedBox.shrink();

    Widget tile((String, List<Listing>) b) {
      final covers = [for (final l in b.$2.take(3)) coverOfBook(l.book)];
      return BlurPanel(
        cover: covers.first,
        height: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () => context.go(_searchPath()),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.$1,
                    style: context.textStyles.headlineSmall?.copyWith(
                      color: onDark,
                    ),
                  ),
                  Text(
                    l10n.hsListingsN(b.$2.length),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: onDark.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            CoverFan(covers: covers, width: 54),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeader(l10n.hsPriceTitle),
        if (compact)
          Column(
            children: [
              for (final b in bands)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: tile(b),
                ),
            ],
          )
        else
          Row(
            children: [
              for (final (i, b) in bands.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: tile(b)),
              ],
            ],
          ),
      ],
    );
  }
}

// ───────────────────── Shop nổi bật ─────────────────────

class HomeShops extends ConsumerWidget {
  const HomeShops({super.key, required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final listings = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final shops = feed.featuredShops.take(6).toList();
    if (shops.isEmpty) return const SizedBox.shrink();

    Widget card(ShopSummary s) {
      final books = listings.where((l) => l.shop.id == s.id).toList();
      final covers = [for (final l in books.take(3)) coverOfBook(l.book)];
      return SizedBox(
        width: 290,
        child: BlurPanel(
          cover: covers.isEmpty ? null : covers.first,
          dark: false,
          height: 210,
          onTap: () => context.go(Routes.shop(s.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: context.appColors.tint,
                    child: Text(
                      s.name.isEmpty ? '?' : s.name.characters.first,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: context.appColors.onSelected,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.titleMedium,
                        ),
                        Text(
                          '★ ${s.ratingAvg.toStringAsFixed(1)} · ${l10n.hsShopBooks(books.length)}',
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  for (final cv in covers)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: BookPoster(
                        title: cv.title,
                        author: cv.author,
                        coverUrl: cv.url,
                        seed: cv.seed,
                        width: 58,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeader(l10n.hsShopsTitle),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              for (final s in shops)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: card(s),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
