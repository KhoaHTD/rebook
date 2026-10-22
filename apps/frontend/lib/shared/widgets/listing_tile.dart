import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Ô một tin bán: poster lớn, tên sách, badge "MỚI" (đăng trong 3 ngày), tình trạng · giá.
class ListingTile extends StatelessWidget {
  const ListingTile({
    super.key,
    required this.listing,
    this.onTap,
    this.menu,
    this.onMenuSelected,
    this.showShop = false,
  });

  final Listing listing;
  final VoidCallback? onTap;
  final List<PopupMenuEntry<String>>? menu;
  final ValueChanged<String>? onMenuSelected;

  /// Hiện tên shop thay cho tình trạng (dùng ở danh sách "các bản khác").
  final bool showShop;

  static bool isNew(Listing l) =>
      DateTime.now().difference(l.createdAt).inDays < 3;

  @override
  Widget build(BuildContext context) {
    final book = listing.book;
    final l10n = context.l10n;
    return PosterTile(
      poster: BookPoster(
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        seed: book.id,
        badge: isNew(listing) ? PillBadge.newItem(context) : null,
      ),
      title: book.title,
      onTap: onTap,
      menu: menu,
      onMenuSelected: onMenuSelected,
      meta: Row(
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                text:
                    '${showShop ? listing.shop.name : book.condition.label(l10n)} · ',
                children: [
                  TextSpan(
                    text: formatVnd(listing.price),
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
