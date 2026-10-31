import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/recent_searches.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';

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

enum _FlowTab { trending, fresh, cheap, categories }

/// Băng chuyền poster kiểu "bảng xếp hạng" của trang Khám phá: hàng tab nhỏ, poster lớn ở giữa (hai bên ló một
/// phần) với số hạng to ở góc dưới trái, nút thêm vào giỏ, rồi tên sách, ba chỉ số và nút "Xem sách".
/// Nút ở góc dưới phải đổi giữa băng chuyền và lưới. Bìa vuông góc, cao theo ảnh thật.
class ExplorePosterFlow extends ConsumerStatefulWidget {
  const ExplorePosterFlow({super.key, required this.onOpen});

  final ValueChanged<Listing> onOpen;

  @override
  ConsumerState<ExplorePosterFlow> createState() => _ExplorePosterFlowState();
}

class _ExplorePosterFlowState extends ConsumerState<ExplorePosterFlow> {
  _FlowTab _tab = _FlowTab.trending;
  String? _categoryId;
  bool _grid = false;
  int _index = 0;
  final _pages = PageController(viewportFraction: 0.56);

  /// Tự lướt sang cuốn kế tiếp; chạm / vuốt thì tạm dừng, thả ra một lúc sau mới chạy tiếp.
  static const _autoEvery = Duration(seconds: 4);
  Timer? _auto;
  Timer? _resume;
  bool _held = false;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(_autoEvery, (_) => _advance());
  }

  void _advance() {
    if (!mounted || _held || _grid || _count < 2 || !_pages.hasClients) return;
    final next = (_index + 1) % _count;
    if (next == 0) {
      // Hết vòng: quay về cuốn đầu bằng một cú lướt mượt thay vì nhảy.
      _pages.animateToPage(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _pages.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _hold() {
    _resume?.cancel();
    _held = true;
  }

  void _release() {
    _resume?.cancel();
    _resume = Timer(const Duration(seconds: 3), () => _held = false);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _resume?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _setTab(_FlowTab t) {
    setState(() {
      _tab = t;
      _index = 0;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  Future<void> _addToCart(Listing l) async {
    final l10n = context.l10n;
    if (!ref.read(sessionControllerProvider).isSignedIn) {
      context.go(
        Uri(
          path: Routes.login,
          queryParameters: {'from': Routes.search},
        ).toString(),
      );
      return;
    }
    final ok = await ref.read(addToCartControllerProvider.notifier).add(l.id);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedToCart),
        action: SnackBarAction(
          label: l10n.viewCart,
          onPressed: () => context.go(Routes.cart),
        ),
      ),
    );
  }

  List<Listing> _items(HomeFeed? feed, List<Listing> all, List<Category> cats) {
    switch (_tab) {
      case _FlowTab.trending:
        return (feed?.trending.isNotEmpty ?? false)
            ? feed!.trending
            : (feed?.newArrivals ?? const <Listing>[]);
      case _FlowTab.fresh:
        return feed?.newArrivals ??
            ([...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
      case _FlowTab.cheap:
        return [...all]..sort((a, b) => a.price.compareTo(b.price));
      case _FlowTab.categories:
        final id = _categoryId;
        if (id == null) return const <Listing>[];
        bool inCat(Listing l) {
          final c = l.book.categoryId;
          return c == id || cats.any((x) => x.id == c && x.parentId == id);
        }

        return all.where(inCat).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final feed = ref.watch(homeFeedProvider).value;
    final all = ref.watch(allListingsProvider).value ?? const <Listing>[];
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final roots = cats.where((x) => x.parentId == null).toList();
    if (_tab == _FlowTab.categories &&
        _categoryId == null &&
        roots.isNotEmpty) {
      _categoryId = roots.first.id;
    }
    final items = _items(feed, all, cats).take(20).toList();
    if (_index >= items.length) _index = 0;
    _count = items.length;

    Widget tab(String label, _FlowTab t) {
      final on = _tab == t;
      return Padding(
        padding: const EdgeInsets.only(right: 22),
        child: InkResponse(
          onTap: () => _setTab(t),
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: on ? context.colors.onSurface : Colors.transparent,
                ),
              ),
            ),
            child: Text(
              label,
              style: text.titleSmall?.copyWith(
                fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                color: on ? context.colors.onSurface : c.secondaryText,
              ),
            ),
          ),
        ),
      );
    }

    final current = items.isEmpty ? null : items[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              tab(l10n.exploreTabTrending, _FlowTab.trending),
              tab(l10n.newArrivals, _FlowTab.fresh),
              tab(l10n.homeShelfCheap, _FlowTab.cheap),
              tab(l10n.exploreTabCategories, _FlowTab.categories),
            ],
          ),
        ),
        if (_tab == _FlowTab.categories)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final cat in roots)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: _categoryId == cat.id,
                        onSelected: (_) => setState(() {
                          _categoryId = cat.id;
                          _index = 0;
                          if (_pages.hasClients) _pages.jumpToPage(0);
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.homeShelfEmpty,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: c.secondaryText),
            ),
          )
        else if (_grid)
          _FlowGrid(items: items, onOpen: widget.onOpen)
        else ...[
          SizedBox(
            height: 380,
            child: Listener(
              onPointerDown: (_) => _hold(),
              onPointerUp: (_) => _release(),
              onPointerCancel: (_) => _release(),
              child: PageView.builder(
                controller: _pages,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _FlowPoster(
                  controller: _pages,
                  index: i,
                  rank: i + 1,
                  listing: items[i],
                  onTap: () {
                    if (i == _index) {
                      widget.onOpen(items[i]);
                    } else {
                      _pages.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  onCart: () => _addToCart(items[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (current != null)
            _FlowInfo(listing: current, onOpen: widget.onOpen),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _grid = !_grid),
              icon: Icon(
                _grid ? Icons.view_carousel_outlined : Icons.grid_view_rounded,
                size: 18,
              ),
              label: Text(
                _grid ? l10n.exploreViewCarousel : l10n.exploreViewGrid,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Một poster của băng chuyền: to dần khi tới giữa, số hạng ở góc dưới trái, nút giỏ ở góc dưới phải.
class _FlowPoster extends StatelessWidget {
  const _FlowPoster({
    required this.controller,
    required this.index,
    required this.rank,
    required this.listing,
    required this.onTap,
    required this.onCart,
  });

  final PageController controller;
  final int index;
  final int rank;
  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final b = listing.book;
    final text = context.textStyles;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? index.toDouble())
            : index.toDouble();
        final t = (1 - (index - page).abs()).clamp(0.0, 1.0);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scale: 0.8 + 0.2 * t,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: 210,
                height: 380,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 210,
                    child: Stack(
                      children: [
                        BookPoster(
                          square: true,
                          title: b.title,
                          author: b.author,
                          coverUrl: b.coverUrl,
                          seed: b.id,
                          width: 210,
                        ),
                        Positioned(
                          left: 10,
                          bottom: 4,
                          child: Text(
                            '$rank',
                            style: text.displaySmall?.copyWith(
                              fontSize: 58,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: CoverPalette.onHero,
                              shadows: const [
                                Shadow(
                                  color: CoverPalette.scrim,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: GestureDetector(
                            onTap: onCart,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CoverPalette.scrim.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 18,
                                color: CoverPalette.onHero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dưới poster: tên sách, dòng ba chỉ số (tình trạng · giá · điểm shop), nút "Xem sách".
class _FlowInfo extends StatelessWidget {
  const _FlowInfo({required this.listing, required this.onOpen});

  final Listing listing;
  final ValueChanged<Listing> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final b = listing.book;
    final shop = listing.shop;
    Widget stat(IconData icon, String value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c.secondaryText),
        const SizedBox(width: 4),
        Text(
          value,
          style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
    Widget bar() => Container(width: 1, height: 12, color: c.separator);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            b.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              stat(Icons.verified_outlined, b.condition.label(l10n)),
              bar(),
              stat(Icons.sell_outlined, formatVnd(listing.price)),
              bar(),
              stat(
                Icons.star_rounded,
                shop.ratingCount == 0 ? '—' : shop.ratingAvg.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 42),
              shape: const StadiumBorder(),
              side: BorderSide(color: c.separator),
            ),
            onPressed: () => onOpen(listing),
            child: Text(l10n.exploreViewBook),
          ),
        ],
      ),
    );
  }
}

/// Dạng lưới: hai cột bìa, mỗi bìa có số hạng, bên dưới tên và giá.
class _FlowGrid extends StatelessWidget {
  const _FlowGrid({required this.items, required this.onOpen});

  final List<Listing> items;
  final ValueChanged<Listing> onOpen;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - 18) / 2;
          return Wrap(
            spacing: 18,
            runSpacing: 22,
            children: [
              for (final (i, l) in items.indexed)
                SizedBox(
                  width: w,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onOpen(l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            BookPoster(
                              square: true,
                              title: l.book.title,
                              author: l.book.author,
                              coverUrl: l.book.coverUrl,
                              seed: l.book.id,
                              width: w,
                            ),
                            Positioned(
                              left: 8,
                              bottom: 2,
                              child: Text(
                                '${i + 1}',
                                style: text.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: CoverPalette.onHero,
                                  shadows: const [
                                    Shadow(
                                      color: CoverPalette.scrim,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatVnd(l.price),
                          style: text.labelMedium?.copyWith(
                            color: context.appColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
