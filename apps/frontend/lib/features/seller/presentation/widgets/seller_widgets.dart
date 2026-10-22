import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';

/// Poster một tin của shop: trạng thái, giá, tồn kho, menu ···.
class SellerListingTile extends StatelessWidget {
  const SellerListingTile({
    super.key,
    required this.listing,
    this.onTap,
    this.menu,
    this.onMenuSelected,
  });

  final Listing listing;
  final VoidCallback? onTap;
  final List<PopupMenuEntry<String>>? menu;
  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final book = listing.book;
    return PosterTile(
      poster: BookPoster(
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        seed: book.id,
      ),
      title: book.title,
      onTap: onTap,
      menu: menu,
      onMenuSelected: onMenuSelected,
      meta: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatVnd(listing.price)} · ${l10n.inStock(listing.stock)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          StatusPill(listing.status.label(l10n), tone: listing.status.tone),
        ],
      ),
    );
  }
}
