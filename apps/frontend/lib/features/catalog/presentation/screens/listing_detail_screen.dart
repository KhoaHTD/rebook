import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Chi tiết một tin bán: thông tin sách, ảnh thật, người bán, và các bản khác của cùng cuốn
/// từ người bán khác (sách là trung tâm, người bán là nguồn cung).
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingProvider(listingId));
    final compact = context.windowSize.isCompact;
    final l = listing.value;
    return AppPage(
      title: l?.book.title ?? '',
      showBack: true,
      // Nền cả trang = chính bìa sách, phóng to + làm mờ; chữ nằm trong khung kính.
      background: l == null
          ? null
          : BookBackdrop(
              title: l.book.title,
              author: l.book.author,
              coverUrl: l.book.coverUrl,
              seed: l.book.id,
            ),
      bottomBar: compact && l != null ? _BuyBar(listing: l) : null,
      children: [
        AsyncValueView(
          value: listing,
          onRetry: () => ref.invalidate(listingProvider(listingId)),
          data: (l) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                Center(
                  child: BookPoster(
                    title: l.book.title,
                    author: l.book.author,
                    coverUrl: l.book.coverUrl,
                    seed: l.book.id,
                    width: 220,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Glass(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _Info(listing: l),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookPoster(
                      title: l.book.title,
                      author: l.book.author,
                      coverUrl: l.book.coverUrl,
                      seed: l.book.id,
                      width: 300,
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: Glass(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: _Info(listing: l),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 56),
              _OtherOffers(listingId: listingId),
            ],
          ),
        ),
      ],
    );
  }
}

/// Thêm vào giỏ (chưa đăng nhập → đăng nhập rồi quay lại). [goToCart]: "Mua ngay".
Future<void> _addToCart(
  BuildContext context,
  WidgetRef ref,
  Listing listing, {
  required bool goToCart,
}) async {
  if (!ref.read(sessionControllerProvider).isSignedIn) {
    context.go(
      Uri(
        path: Routes.login,
        queryParameters: {'from': Routes.listing(listing.id)},
      ).toString(),
    );
    return;
  }
  final ok = await ref
      .read(addToCartControllerProvider.notifier)
      .add(listing.id);
  if (!context.mounted) return;
  if (!ok) {
    showErrorSnack(context, ref.read(addToCartControllerProvider).error!);
  } else if (goToCart) {
    context.go(Routes.cart);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.addedToCart),
        action: SnackBarAction(
          label: context.l10n.viewCart,
          onPressed: () => context.go(Routes.cart),
        ),
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final book = listing.book;
    final c = context.appColors;
    final busy = ref.watch(addToCartControllerProvider).isLoading;
    final sellerPhotos = [for (final i in book.images) i.url];

    Widget fact(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    label,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: c.secondaryText,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(value, style: context.textStyles.bodyMedium),
                ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Desktop đã có tên sách ở tiêu đề trang; mobile tiêu đề nhỏ nên nhắc lại cỡ lớn.
        if (context.windowSize.isCompact) ...[
          Text(book.title, style: context.textStyles.displaySmall),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          book.author,
          style: context.textStyles.titleLarge?.copyWith(
            color: c.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            StatusPill(book.condition.label(l10n), tone: book.condition.tone),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                book.condition.hint(l10n),
                style: context.textStyles.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PriceText(
          listing.price,
          style: context.textStyles.headlineMedium?.copyWith(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          listing.purchasable
              ? l10n.inStock(listing.stock)
              : l10n.lstOutOfStock,
          style: context.textStyles.bodySmall,
        ),
        // Mobile: nút mua nằm ở thanh kính nổi phía dưới ([_BuyBar]).
        if (!context.windowSize.isCompact) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton(
                onPressed: !listing.purchasable || busy
                    ? null
                    : () => _addToCart(context, ref, listing, goToCart: true),
                child: Text(l10n.buyNow),
              ),
              OutlinedButton.icon(
                onPressed: !listing.purchasable || busy
                    ? null
                    : () => _addToCart(context, ref, listing, goToCart: false),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text(l10n.addToCart),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        InfoPanel(
          child: InkWell(
            onTap: () => context.go(Routes.shop(listing.shop.id)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.fill,
                  backgroundImage: null,
                  child: listing.shop.avatarUrl == null
                      ? Icon(Icons.storefront_outlined, color: c.secondaryText)
                      : ClipOval(
                          child: SizedBox.square(
                            dimension: 40,
                            child: AppImage(listing.shop.avatarUrl!),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.soldBy, style: context.textStyles.bodySmall),
                      Text(
                        listing.shop.name,
                        style: context.textStyles.titleMedium,
                      ),
                      Text(
                        listing.shop.ratingCount == 0
                            ? l10n.noReviews
                            : l10n.rating(
                                listing.shop.ratingAvg.toStringAsFixed(1),
                                listing.shop.ratingCount,
                              ),
                        style: context.textStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.visitShop,
                  style: context.textStyles.labelLarge?.copyWith(color: c.info),
                ),
              ],
            ),
          ),
        ),
        if (sellerPhotos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.sellerPhotos, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          PhotoStrip(urls: sellerPhotos),
        ],
        if (book.description != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.aboutBook, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(book.description!, style: context.textStyles.bodyLarge),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.bookDetails, style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        fact(l10n.author, book.author),
        fact(l10n.publisher, book.publisher),
        fact(l10n.publishYear, book.publishYear?.toString()),
        fact(l10n.category, book.categoryName),
        fact(l10n.language, book.language),
        fact(l10n.pages, book.pages?.toString()),
        fact(l10n.isbn, book.isbn),
      ],
    );
  }
}

class _OtherOffers extends ConsumerWidget {
  const _OtherOffers({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers =
        ref.watch(otherOffersProvider(listingId)).value ?? const <Listing>[];
    if (offers.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.otherOffers),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.otherOffersHint, style: context.textStyles.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        PosterGrid(
          children: [
            for (final o in offers)
              ListingTile(
                listing: o,
                showShop: true,
                onTap: () => context.go(Routes.listing(o.id)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Thanh mua hàng nổi bằng kính (mobile): người bán + giá + "Thêm vào giỏ".
/// Đặt phía trên tab bar nổi của khung app.
class _BuyBar extends ConsumerWidget {
  const _BuyBar({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(addToCartControllerProvider).isLoading;
    return SafeArea(
      top: false,
      child: Padding(
        // 64 (tab bar) + 12 (lề dưới tab bar) + 10 khoảng hở.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 86),
        child: Glass(
          borderRadius: AppRadius.chip,
          padding: const EdgeInsets.fromLTRB(22, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall,
                    ),
                    PriceText(
                      listing.price,
                      style: context.textStyles.titleLarge,
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                onPressed: !listing.purchasable || busy
                    ? null
                    : () => _addToCart(context, ref, listing, goToCart: false),
                child: Text(context.l10n.addToCart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
