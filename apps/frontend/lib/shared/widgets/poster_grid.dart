import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Một ô trong lưới / kệ: poster lớn, tên sách, dòng meta (badge, giá…), nút ···.
class PosterTile extends StatelessWidget {
  const PosterTile({
    super.key,
    required this.poster,
    required this.title,
    this.meta,
    this.menu,
    this.onMenuSelected,
    this.onTap,
  });

  final Widget poster;
  final String title;

  /// Dòng dưới tên: badge + giá / số bản / đồng hồ.
  final Widget? meta;
  final List<PopupMenuEntry<String>>? menu;
  final ValueChanged<String>? onMenuSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: onTap == null
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            child: poster,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleSmall,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                style: context.textStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: meta ?? const SizedBox.shrink(),
              ),
            ),
            if (menu != null)
              DotsButton(
                items: menu!,
                onSelected: onMenuSelected,
                compact: true,
              ),
          ],
        ),
      ],
    );
  }
}

/// Lưới poster: 4 cột trên desktop, 3 trên tablet, 2 trên điện thoại (như mockup).
class PosterGrid extends StatelessWidget {
  const PosterGrid({super.key, required this.children, this.maxColumns = 4});

  final List<Widget> children;
  final int maxColumns;

  static int columnsFor(double width, int max) {
    final c = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
    return c > max ? max : c;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = columnsFor(box.maxWidth, maxColumns);
        final gapX = cols == 2 ? AppSpacing.md : AppSpacing.posterGapX;
        final tileW = (box.maxWidth - gapX * (cols - 1)) / cols;
        return Wrap(
          spacing: gapX,
          runSpacing: AppSpacing.posterGapY,
          children: [
            for (final c in children) SizedBox(width: tileW, child: c),
          ],
        );
      },
    );
  }
}

/// Kệ cuộn ngang (mobile & trang khám phá): tiêu đề "Tên kệ ›" + dải poster.
class Shelf extends StatelessWidget {
  const Shelf({
    super.key,
    required this.title,
    required this.children,
    this.onSeeAll,
    this.alt = false,
    this.itemWidth = 160,
    this.horizontalPadding = 20,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onSeeAll;

  /// Nền xám nhạt — xen kẽ các kệ cho dễ phân biệt (như mockup).
  final bool alt;
  final double itemWidth;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: alt ? context.appColors.shelfAlt : context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SectionHeader(title, onTap: onSeeAll),
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    SizedBox(width: itemWidth, child: children[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
