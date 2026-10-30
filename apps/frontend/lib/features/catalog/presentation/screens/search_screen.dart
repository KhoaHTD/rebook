import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/recent_searches.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/explore_sections.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/glass_menu.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang Khám phá: ô tìm + nút bộ lọc; chưa tìm / lọc gì thì gợi ý (tìm gần đây, thịnh hành, danh mục),
/// có từ khóa hoặc bộ lọc thì hiện kết quả. Lọc theo thể loại / tình trạng / giá + sắp xếp (SRS 3 — người mua).
/// [initialCategory]: mở từ "Kệ sách" ở sidebar (`?category=`).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory, this.initialText});

  final String? initialCategory;
  final String? initialText;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _text = TextEditingController(text: widget.initialText);

  /// "Xem tất cả": hiện toàn bộ sách (kết quả không từ khóa) thay vì phần gợi ý.
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(searchQueryProvider(null).notifier);
      notifier.update(
        ListingQuery(categoryId: widget.initialCategory, q: widget.initialText),
      );
    });
  }

  @override
  void didUpdateWidget(SearchScreen old) {
    super.didUpdateWidget(old);
    if (old.initialCategory != widget.initialCategory) {
      final q = ref.read(searchQueryProvider(null));
      ref
          .read(searchQueryProvider(null).notifier)
          .update(q.copyWith(categoryId: widget.initialCategory));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _search(String text) {
    ref.read(recentSearchesProvider.notifier).add(text);
    ref.read(searchQueryProvider(null).notifier).setText(text);
    setState(() => _showAll = text.trim().isNotEmpty);
  }

  bool _idle(ListingQuery q) =>
      !_showAll &&
      (q.q == null || q.q!.isEmpty) &&
      q.categoryId == null &&
      q.condition == null &&
      q.minPrice == null &&
      q.maxPrice == null &&
      q.sort == ListingSort.newest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider(null));
    final results = ref.watch(searchResultsProvider(null));
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final notifier = ref.read(searchQueryProvider(null).notifier);
    final catName = cats
        .where((c) => c.id == query.categoryId)
        .firstOrNull
        ?.name;
    final idle = _idle(query);

    // Điện thoại, chưa tìm / lọc: tiêu đề lớn căn giữa nằm trong trang (như "BOOKS" ở ảnh mẫu), thanh đầu để trống.
    final bigTitle = idle && context.windowSize.isCompact;
    return AppPage(
      title: bigTitle ? '' : (catName ?? l10n.navExplore),
      children: [
        if (bigTitle) ...[
          Text(
            l10n.exploreKicker,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.appColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.navExplore,
            textAlign: TextAlign.center,
            style: context.textStyles.displaySmall?.copyWith(
              fontSize: 44,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _text.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _text.clear();
                            notifier.setText('');
                            setState(() => _showAll = false);
                          },
                        ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: _search,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: l10n.filters,
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _filterSheet(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (idle) ...[
          RecentSearchChips(
            onPick: (q) {
              _text.text = q;
              _search(q);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          ExplorePosterFlow(onOpen: (l) => context.go(Routes.listing(l.id))),
          const SizedBox(height: 110),
        ] else
          AsyncValueView(
            value: results,
            onRetry: () => ref.invalidate(searchResultsProvider(null)),
            data: (page) {
              if (page.items.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.noResults,
                  message: l10n.noResultsHint,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.resultsCount(page.total),
                    style: context.textStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PosterGrid(
                    children: [
                      for (final l in page.items)
                        ListingTile(
                          listing: l,
                          onTap: () => context.go(Routes.listing(l.id)),
                        ),
                    ],
                  ),
                  if (page.hasMore) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(searchResultsProvider(null).notifier)
                            .loadMore(),
                        child: Text(l10n.loadMore),
                      ),
                    ),
                  ],
                  const SizedBox(height: 110),
                ],
              );
            },
          ),
      ],
    );
  }

  /// Tờ bộ lọc: thể loại, tình trạng, sắp xếp, khoảng giá (đổi là áp dụng ngay) và nút về mặc định.
  Future<void> _filterSheet(BuildContext context) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) {
          final query = ref.watch(searchQueryProvider(null));
          final cats =
              ref.watch(categoriesProvider).value ?? const <Category>[];
          final notifier = ref.read(searchQueryProvider(null).notifier);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.filters, style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  runSpacing: AppSpacing.sm,
                  children: [
                    _MenuChip<String?>(
                      label:
                          cats
                              .where((c) => c.id == query.categoryId)
                              .firstOrNull
                              ?.name ??
                          l10n.category,
                      active: query.categoryId != null,
                      options: [
                        (null, l10n.allCategories),
                        for (final c in cats) (c.id, c.name),
                      ],
                      onSelected: (id) =>
                          notifier.update(query.copyWith(categoryId: id)),
                    ),
                    _MenuChip<ConditionGrade?>(
                      label: query.condition?.label(l10n) ?? l10n.condition,
                      active: query.condition != null,
                      options: [
                        (null, l10n.anyCondition),
                        for (final g in ConditionGrade.values.where(
                          (g) => g != ConditionGrade.unknown,
                        ))
                          (g, g.label(l10n)),
                      ],
                      onSelected: (g) =>
                          notifier.update(query.copyWith(condition: g)),
                    ),
                    _MenuChip<ListingSort>(
                      label: _sortLabel(l10n, query.sort),
                      active: query.sort != ListingSort.newest,
                      options: [
                        for (final s in ListingSort.values)
                          (s, _sortLabel(l10n, s)),
                      ],
                      onSelected: (s) =>
                          notifier.update(query.copyWith(sort: s)),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(l10n.priceRange),
                      onPressed: () => _priceSheet(context, query),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () {
                    notifier.update(const ListingQuery());
                    _text.clear();
                    setState(() => _showAll = false);
                    Navigator.pop(sheet);
                  },
                  child: Text(l10n.resetFilters),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _sortLabel(AppLocalizations l, ListingSort s) => switch (s) {
    ListingSort.newest => l.sortNewest,
    ListingSort.priceAsc => l.sortPriceAsc,
    ListingSort.priceDesc => l.sortPriceDesc,
    ListingSort.relevance => l.sortRelevance,
  };

  Future<void> _priceSheet(BuildContext context, ListingQuery query) async {
    final l10n = context.l10n;
    final min = TextEditingController(text: query.minPrice?.toString() ?? '');
    final max = TextEditingController(text: query.maxPrice?.toString() ?? '');
    final apply = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(c).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.priceRange, style: c.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: min,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.minPrice),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: max,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.maxPrice),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(l10n.resetFilters),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(l10n.applyFilters),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (apply == null) return;
    final n = ref.read(searchQueryProvider(null).notifier);
    n.update(
      apply
          ? query.copyWith(
              minPrice: int.tryParse(min.text),
              maxPrice: int.tryParse(max.text),
            )
          : query.copyWith(minPrice: null, maxPrice: null),
    );
  }
}

/// Chip mở menu chọn một giá trị (thể loại, tình trạng, sắp xếp).
class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.active,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final bool active;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GlassMenuButton<int>(
        items: [
          for (var i = 0; i < options.length; i++)
            GlassMenuItem(value: i, label: options[i].$2),
        ],
        onSelected: (i) => onSelected(options[i].$1),
        child: Chip(
          label: Text(label),
          backgroundColor: active ? context.appColors.selected : null,
          labelStyle: active
              ? context.textStyles.labelMedium?.copyWith(
                  color: context.appColors.onSelected,
                )
              : null,
          deleteIcon: Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: active ? context.appColors.onSelected : null,
          ),
          onDeleted: () {},
        ),
      ),
    );
  }
}
