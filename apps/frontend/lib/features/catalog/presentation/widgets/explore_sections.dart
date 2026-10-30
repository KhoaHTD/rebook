import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/recent_searches.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/glass_shelf.dart';

/// Tiêu đề một mục của trang Khám phá: biểu tượng nhỏ, tên, và "Xem tất cả" bên phải.
class ExploreHeader extends StatelessWidget {
  const ExploreHeader({
    super.key,
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.fill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: c.secondaryText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// "Tìm gần đây": các từ khóa vừa tìm dạng chip có dấu ×, kèm "Xóa tất cả".
class RecentSearchChips extends ConsumerWidget {
  const RecentSearchChips({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentSearchesProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final c = context.appColors;
    final notifier = ref.read(recentSearchesProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.exploreRecent,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: notifier.clear,
              child: Text(l10n.exploreClearAll),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final q in items)
              Material(
                color: c.fill,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onPick(q),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(q, style: context.textStyles.bodyMedium),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 16,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => notifier.remove(q),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Một cuốn trong thẻ nhẹ: bìa vuông góc, tên một dòng, tác giả xám.
class _BookCard extends StatelessWidget {
  const _BookCard({required this.listing, required this.width, this.onTap});

  final Listing listing;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = listing.book;
    final c = context.appColors;
    final text = context.textStyles;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.fill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: BookPoster(
                  square: true,
                  title: b.title,
                  author: b.author,
                  coverUrl: b.coverUrl,
                  seed: b.id,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              b.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelLarge,
            ),
            Text(
              b.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Thịnh hành tuần này": hàng thẻ sách cuộn ngang (các tin đang được săn nhiều).
class ExploreTrending extends ConsumerWidget {
  const ExploreTrending({
    super.key,
    required this.onSeeAll,
    required this.onOpen,
  });

  final VoidCallback onSeeAll;
  final ValueChanged<Listing> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider).value;
    final items = (feed?.trending.isNotEmpty ?? false)
        ? feed!.trending
        : (feed?.newArrivals ?? const <Listing>[]);
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExploreHeader(
          icon: Icons.local_fire_department_rounded,
          title: l10n.exploreTrending,
          actionLabel: l10n.seeAll,
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, box) {
            // ~3 cuốn rưỡi trên điện thoại; rộng hơn thì thẻ không phình quá 170.
            final w = ((box.maxWidth - 24) / 3.4).clamp(96.0, 170.0);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in items.take(10))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BookCard(
                        listing: l,
                        width: w,
                        onTap: () => onOpen(l),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// "Khám phá theo danh mục": mỗi danh mục gốc là một bìa đại diện kèm tên; bấm để lọc theo danh mục.
class ExploreCategories extends ConsumerWidget {
  const ExploreCategories({
    super.key,
    required this.onSeeAll,
    required this.onPick,
  });

  final VoidCallback onSeeAll;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final listings = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final roots = all.where((c) => c.parentId == null).toList();
    if (roots.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final c = context.appColors;

    Listing? cover(Category cat) {
      for (final l in listings) {
        final id = l.book.categoryId;
        if (id == cat.id ||
            all.any((x) => x.id == id && x.parentId == cat.id)) {
          return l;
        }
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExploreHeader(
          icon: Icons.category_rounded,
          title: l10n.exploreCategories,
          actionLabel: l10n.seeAll,
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: c.fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = ((box.maxWidth - 36) / 4.3).clamp(64.0, 120.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final cat in roots)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onPick(cat.id),
                          child: SizedBox(
                            width: w,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (cover(cat) case final l?)
                                  BookPoster(
                                    square: true,
                                    title: l.book.title,
                                    author: l.book.author,
                                    coverUrl: l.book.coverUrl,
                                    seed: l.book.id,
                                  )
                                else
                                  AspectRatio(
                                    aspectRatio: 2 / 3,
                                    child: ColoredBox(color: c.separator),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  cat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: context.textStyles.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Các kệ kính của trang Khám phá: một kệ "Thịnh hành" rồi mỗi thể loại gốc một kệ (tối đa 12 cuốn),
/// mỗi kệ một màu ván. Bấm tên kệ thì lọc theo thể loại đó.
class ExploreShelves extends ConsumerWidget {
  const ExploreShelves({
    super.key,
    required this.onOpen,
    required this.onCategory,
    required this.onTrending,
  });

  final ValueChanged<Listing> onOpen;
  final ValueChanged<String> onCategory;
  final VoidCallback onTrending;

  static const maxPerShelf = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feed = ref.watch(homeFeedProvider).value;
    final all = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final roots = cats.where((c) => c.parentId == null).toList();

    ShelfEntry entry(Listing l) => ShelfEntry(
      id: l.id,
      title: l.book.title,
      author: l.book.author,
      coverUrl: l.book.coverUrl,
      price: formatVnd(l.price),
      onTap: () => onOpen(l),
    );

    bool inCategory(Listing l, Category c) {
      final id = l.book.categoryId;
      return id == c.id || cats.any((x) => x.id == id && x.parentId == c.id);
    }

    final trending = (feed?.trending.isNotEmpty ?? false)
        ? feed!.trending
        : (feed?.newArrivals ?? const <Listing>[]);
    final shelves = <(String, List<ShelfEntry>, VoidCallback?)>[
      if (trending.isNotEmpty)
        (
          l10n.exploreTrending,
          [for (final l in trending.take(maxPerShelf)) entry(l)],
          onTrending,
        ),
      for (final c in roots)
        (
          c.name,
          [
            for (final l
                in all.where((l) => inCategory(l, c)).take(maxPerShelf))
              entry(l),
          ],
          () => onCategory(c.id),
        ),
    ].where((s) => s.$2.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in shelves.indexed) ...[
          GlassShelf(
            title: s.$1,
            entries: s.$2,
            color: ShelfPalette.at(i),
            onTitleTap: s.$3,
          ),
          const SizedBox(height: 30),
        ],
      ],
    );
  }
}
