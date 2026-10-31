import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/favorites_providers.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Sách yêu thích: các tin tôi đã thả tim; bấm "Bỏ yêu thích" ở menu ba chấm để gỡ.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(favoriteListingsProvider);
    return AppPage(
      title: l10n.favTitle,
      showBack: true,
      onRefresh: () => ref.refresh(favoriteListingsProvider.future),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(favoriteListingsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: l10n.favEmpty,
                  message: l10n.favEmptyHint,
                  action: FilledButton(
                    onPressed: () => context.go(Routes.home),
                    child: Text(l10n.continueShopping),
                  ),
                )
              : PosterGrid(
                  children: [
                    for (final l in items)
                      ListingTile(
                        listing: l,
                        showShop: true,
                        onTap: () => context.go(Routes.listing(l.id)),
                        menu: [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(l10n.favRemove),
                          ),
                        ],
                        onMenuSelected: (_) => ref
                            .read(favoriteActionsProvider.notifier)
                            .setFavorite(l.id, on: false),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
