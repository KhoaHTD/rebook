import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/domain/book_search_filter.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/filter_sheet.dart';
import 'package:book_marketplace/shared/domain/book.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_condition_badge.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Tìm kiếm: ô tìm kiếm nằm dưới đáy gần ngón cái, chip bộ lọc, danh sách kết quả kiểu iOS.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(bookSearchProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: MaxWidthBox(
              maxWidth: 720,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.searchTitle,
                        style: context.textStyles.headlineLarge,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _FilterChips(filter: filter)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                      AppSpacing.bottomBarInset,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AsyncValueView(
                        value: results,
                        onRetry: () => ref.invalidate(searchResultsProvider),
                        loading: const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        data: (books) => _Results(books: books, filter: filter),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
            child: const MaxWidthBox(maxWidth: 720, child: _SearchBar()),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.filter});

  final BookSearchFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final conditions = filter.conditions.isEmpty
        ? l10n.anyCondition
        : filter.conditions.map((c) => conditionLabel(context, c)).join(', ');
    final price = filter.minPrice == null && filter.maxPrice == null
        ? l10n.anyPrice
        : '${filter.minPrice == null ? '0' : formatMillionsShort(filter.minPrice!)} – '
              '${filter.maxPrice == null ? '∞' : formatMillionsShort(filter.maxPrice!)}';

    Widget chip(
      String label, {
      bool active = false,
      bool strong = false,
      IconData? icon,
    }) {
      final (bg, fg) = strong
          ? (colors.strongSurface, colors.onStrongSurface)
          : active
          ? (colors.accentTint, colors.onAccentTint)
          : (colors.fill, context.colors.onSurface);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ActionChip(
          onPressed: () => showFilterSheet(context),
          avatar: icon == null ? null : Icon(icon, size: 16, color: fg),
          label: Text(label),
          labelStyle: context.textStyles.labelLarge?.copyWith(color: fg),
          backgroundColor: bg,
          side: BorderSide.none,
          shape: const StadiumBorder(),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          chip(
            l10n.filtersCount(filter.activeCount),
            strong: true,
            icon: Icons.tune_rounded,
          ),
          chip(conditions, active: filter.conditions.isNotEmpty),
          chip(
            price,
            active: filter.minPrice != null || filter.maxPrice != null,
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.books, required this.filter});

  final List<Book> books;
  final BookSearchFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final sortLabel = switch (filter.sort) {
      BookSort.newest => l10n.sortNewest,
      BookSort.priceAsc => l10n.sortPriceAsc,
      BookSort.priceDesc => l10n.sortPriceDesc,
    };
    final nextSort =
        BookSort.values[(filter.sort.index + 1) % BookSort.values.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resultCount(books.length),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.labelTertiary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    ref.read(bookSearchProvider.notifier).setSort(nextSort),
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                label: Text(sortLabel),
              ),
            ],
          ),
        ),
        if (books.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(child: Text(l10n.emptyBooks)),
          ),
        for (final b in books) _ResultRow(book: b),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    void open() => context.push(Routes.bookDetail(book.id));
    return InkWell(
      onTap: open,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, AppSpacing.md, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.separator, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: BookCover(imageUrl: book.imageUrl, elevated: false),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: context.textStyles.titleMedium),
                  Text(
                    book.author,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.labelTertiary,
                    ),
                  ),
                  Text(
                    '${conditionLabel(context, book.condition)} · ${book.sellerName}',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.labelTertiary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: open,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: colors.fill,
                foregroundColor: context.colors.primary,
              ),
              child: Text(formatVnd(book.price)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đáy màn: nút về Trang chủ + ô tìm kiếm kính.
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final _controller = TextEditingController(
    text: ref.read(bookSearchProvider).query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.home_rounded,
            tooltip: l10n.backHome,
            size: 56,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlassSurface(
              padding: const EdgeInsets.only(left: AppSpacing.md, right: 6),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: colors.labelSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: ref.read(bookSearchProvider).query.isEmpty,
                        textInputAction: TextInputAction.search,
                        style: context.textStyles.bodyLarge?.copyWith(
                          fontSize: 17,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchBooksHint,
                          filled: false,
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: ref
                            .read(bookSearchProvider.notifier)
                            .setQuery,
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        tooltip: l10n.clearSearch,
                        onPressed: () {
                          _controller.clear();
                          ref.read(bookSearchProvider.notifier).setQuery('');
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.cancel_rounded,
                          color: colors.labelTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
