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
    final compact = context.windowSize.isCompact;
    if (compact) return _CompactBook(listingId: listingId);
    final listing = ref.watch(listingProvider(listingId));
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
  const _OtherOffers({required this.listingId, this.compactStyle = false});

  final String listingId;

  /// Điện thoại: tiêu đề kiểu nhãn chữ hoa nhỏ + đường kẻ như các mục khác của trang.
  final bool compactStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers =
        ref.watch(otherOffersProvider(listingId)).value ?? const <Listing>[];
    if (offers.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compactStyle) ...[
          Text(
            l10n.otherOffers.toUpperCase(),
            style: context.textStyles.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.otherOffersHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.appColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.appColors.separator),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          SectionHeader(l10n.otherOffers),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.otherOffersHint, style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),
        ],
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

/// Điện thoại: chi tiết sách kiểu phẳng — nền trắng, bìa giữa, tên + tác giả giữa, thẻ ba thông số, mô tả,
/// dải ảnh thực tế, rồi người bán / thông tin / các bản khác; thanh đáy phẳng có Thêm vào giỏ, Mua ngay và giá.
class _CompactBook extends ConsumerWidget {
  const _CompactBook({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final listing = ref.watch(listingProvider(listingId));
    final l = listing.value;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                  ),
                  Expanded(
                    child: Text(
                      l10n.bookDetailTitle,
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleSmall?.copyWith(
                        color: c.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView(
                value: listing,
                onRetry: () => ref.invalidate(listingProvider(listingId)),
                data: (l) => _CompactBookBody(listing: l),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: l == null ? null : _BuyBar(listing: l),
    );
  }
}

class _CompactBookBody extends ConsumerWidget {
  const _CompactBookBody({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final book = listing.book;
    final photos = [for (final i in book.images) i.url];
    final width = MediaQuery.sizeOf(context).width;

    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: c.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    Widget heading(String title, {String? sub}) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: text.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub, style: text.bodySmall?.copyWith(color: c.secondaryText)),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: c.separator),
        ],
      ),
    );

    Widget fact(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: text.bodyMedium?.copyWith(color: c.secondaryText),
                  ),
                ),
                Expanded(child: Text(value, style: text.bodyMedium)),
              ],
            ),
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: BookPoster(
            square: true,
            title: book.title,
            author: book.author,
            coverUrl: book.coverUrl,
            seed: book.id,
            width: width * 0.55,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          book.title,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.bookByAuthor(book.author),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: c.secondaryText),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: c.fill,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              stat(l10n.condition, book.condition.label(l10n)),
              stat(
                l10n.pages,
                book.pages == null ? '—' : l10n.statPages(book.pages!),
              ),
              stat(
                l10n.language,
                (book.language == null || book.language!.isEmpty)
                    ? '—'
                    : book.language!,
              ),
            ],
          ),
        ),
        if (book.description != null) ...[
          const SizedBox(height: 20),
          Text(book.description!, style: text.bodyLarge),
        ],
        if (photos.isNotEmpty) ...[
          heading(l10n.realPhotos, sub: l10n.realPhotosCount(photos.length)),
          PhotoStrip(urls: photos, size: 120),
        ],
        heading(l10n.bookDetails),
        fact(l10n.author, book.author),
        fact(l10n.publisher, book.publisher),
        fact(l10n.publishYear, book.publishYear?.toString()),
        fact(l10n.category, book.categoryName),
        fact(l10n.isbn, book.isbn),
        heading(l10n.soldBy),
        InkWell(
          onTap: () => context.go(Routes.shop(listing.shop.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.fill,
                  child: listing.shop.avatarUrl == null
                      ? Icon(Icons.storefront_outlined, color: c.secondaryText)
                      : ClipOval(
                          child: SizedBox.square(
                            dimension: 40,
                            child: AppImage(listing.shop.avatarUrl!),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.shop.name, style: text.titleMedium),
                      Text(
                        listing.shop.ratingCount == 0
                            ? l10n.noReviews
                            : l10n.rating(
                                listing.shop.ratingAvg.toStringAsFixed(1),
                                listing.shop.ratingCount,
                              ),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.visitShop,
                  style: text.labelLarge?.copyWith(color: c.info),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _OtherOffers(listingId: listing.id, compactStyle: true),
      ],
    );
  }
}

/// Thanh đáy phẳng (điện thoại): Thêm vào giỏ + Mua ngay bên trái, giá bên phải.
class _BuyBar extends ConsumerWidget {
  const _BuyBar({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(addToCartControllerProvider).isLoading;
    final enabled = listing.purchasable && !busy;
    return Material(
      color: context.colors.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.appColors.separator)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: context.colors.onSurface,
                      foregroundColor: context.colors.surface,
                    ),
                    onPressed: enabled
                        ? () =>
                              _addToCart(context, ref, listing, goToCart: false)
                        : null,
                    child: Text(l10n.addToCart, maxLines: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: enabled
                        ? () =>
                              _addToCart(context, ref, listing, goToCart: true)
                        : null,
                    child: Text(l10n.buyNow, maxLines: 1),
                  ),
                ),
                const SizedBox(width: 12),
                PriceText(
                  listing.price,
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
