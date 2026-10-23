import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang shop: giới thiệu ngắn, sách đang bán (lưới poster), đánh giá của người mua.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shop = ref.watch(shopProvider(shopId));
    final listings = ref.watch(searchResultsProvider(shopId));
    final reviews =
        ref.watch(shopReviewsProvider(shopId)).value ?? const <Review>[];

    return AppPage(
      title: shop.value?.name ?? '',
      showBack: true,
      children: [
        AsyncValueView(
          value: shop,
          onRetry: () => ref.invalidate(shopProvider(shopId)),
          data: (s) => _Header(shop: s),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(l10n.shopListings),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: listings,
          onRetry: () => ref.invalidate(searchResultsProvider(shopId)),
          data: (page) => page.items.isEmpty
              ? EmptyState(title: l10n.noResults)
              : PosterGrid(
                  children: [
                    for (final l in page.items)
                      ListingTile(
                        listing: l,
                        onTap: () => context.go(Routes.listing(l.id)),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 56),
        SectionHeader(l10n.shopReviews),
        const SizedBox(height: AppSpacing.md),
        if (reviews.isEmpty)
          Text(
            l10n.noReviews,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.appColors.secondaryText,
            ),
          )
        else
          for (final r in reviews) _ReviewRow(review: r),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    return InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: c.fill,
            child: Icon(Icons.storefront_outlined, color: c.secondaryText),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.ratingCount == 0
                      ? l10n.noReviews
                      : l10n.rating(
                          shop.ratingAvg.toStringAsFixed(1),
                          shop.ratingCount,
                        ),
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.activeListings(shop.activeListings)} · ${l10n.joinedSince(formatDate(shop.createdAt))}',
                  style: context.textStyles.bodySmall,
                ),
                if (shop.description != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(shop.description!, style: context.textStyles.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: c.warning,
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${review.reviewerName} · ${formatDate(review.createdAt)}',
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 4),
            Text(review.comment!, style: context.textStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Divider(color: c.separator),
        ],
      ),
    );
  }
}
