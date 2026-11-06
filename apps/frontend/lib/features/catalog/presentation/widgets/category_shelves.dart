import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/see_all_book.dart';

/// Trang Mua sách trên desktop: thanh tab thể loại ("Tất cả" đầu tiên) rồi mỗi thể loại một hàng cuộn ngang gồm các cuốn
/// phổ biến nhất và một "cuốn sách giả" cuối hàng dẫn tới Khám phá. Bấm tab thì trang cuộn xuống hàng đó.
class CategoryShelvesDesktop extends StatefulWidget {
  const CategoryShelvesDesktop({super.key, required this.shelves});

  final List<CategoryShelf> shelves;

  @override
  State<CategoryShelvesDesktop> createState() => _CategoryShelvesDesktopState();
}

class _CategoryShelvesDesktopState extends State<CategoryShelvesDesktop> {
  final _topKey = GlobalKey();
  var _keys = <GlobalKey>[];
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(CategoryShelvesDesktop old) {
    super.didUpdateWidget(old);
    _syncKeys();
    if (_active > widget.shelves.length) _active = 0;
  }

  void _syncKeys() {
    if (_keys.length > widget.shelves.length) {
      _keys = _keys.sublist(0, widget.shelves.length);
    }
    while (_keys.length < widget.shelves.length) {
      _keys.add(GlobalKey());
    }
  }

  void _goTo(int tab) {
    setState(() => _active = tab);
    final ctx = (tab == 0 ? _topKey : _keys[tab - 1]).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [
      l10n.allCategories,
      for (final s in widget.shelves) s.category.name,
    ];
    return Column(
      key: _topKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < tabs.length; i++)
              ChoiceChip(
                label: Text(tabs[i]),
                selected: i == _active,
                onSelected: (_) => _goTo(i),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < widget.shelves.length; i++)
          _DesktopShelf(key: _keys[i], shelf: widget.shelves[i]),
      ],
    );
  }
}

class _DesktopShelf extends StatefulWidget {
  const _DesktopShelf({super.key, required this.shelf});

  final CategoryShelf shelf;

  @override
  State<_DesktopShelf> createState() => _DesktopShelfState();
}

class _DesktopShelfState extends State<_DesktopShelf> {
  static const _itemWidth = 190.0;
  static const _gap = 20.0;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _by(double sign) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    _scroll.animateTo(
      (pos.pixels + sign * pos.viewportDimension * 0.8).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final shelf = widget.shelf;
    void seeAll() => context.go(Routes.searchCategory(shelf.category.id));
    return Padding(
      padding: const EdgeInsets.only(bottom: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shelf.category.name,
                  style: context.textStyles.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: '‹',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _by(-1),
              ),
              IconButton(
                tooltip: '›',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _by(1),
              ),
              TextButton(
                onPressed: seeAll,
                child: Text(
                  '${l10n.seeAll} ›',
                  style: TextStyle(color: c.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: Row(
              // Canh đáy: bìa cao thấp khác nhau cùng đứng trên một đường kẻ như trên giá.
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final l in shelf.items.take(10)) ...[
                  SizedBox(
                    width: _itemWidth,
                    child: ListingTile(
                      listing: l,
                      onTap: () => context.go(Routes.listing(l.id)),
                    ),
                  ),
                  const SizedBox(width: _gap),
                ],
                SizedBox(
                  width: _itemWidth,
                  child: SeeAllBookCard(
                    title: shelf.category.name,
                    caption: l10n.seeAllCount(shelf.total),
                    onTap: seeAll,
                    belowHeight: 56,
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
