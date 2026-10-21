import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/domain/book.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_condition_badge.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/price_text.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookDetailProvider(bookId));

    return Scaffold(
      appBar: AppBar(),
      body: AsyncValueView(
        value: book,
        onRetry: () => ref.invalidate(bookDetailProvider(bookId)),
        data: (b) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: MaxWidthBox(
            maxWidth: 960,
            child: context.windowSize.isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 220,
                          child: BookCover(imageUrl: b.imageUrl),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _BookInfo(book: b),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 320,
                        child: BookCover(imageUrl: b.imageUrl),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: _BookInfo(book: b)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _BookInfo extends StatelessWidget {
  const _BookInfo({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(book.title, style: context.textStyles.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(book.author, style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            PriceText(book.price, style: context.textStyles.headlineSmall),
            const SizedBox(width: AppSpacing.md),
            BookConditionBadge(book.condition),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.soldBy(book.sellerName),
          style: context.textStyles.bodyMedium,
        ),
        if (book.description != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.description, style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(book.description!),
        ],
        const SizedBox(height: AppSpacing.lg),
        // TODO(cart): nối vào feature cart khi có.
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.shopping_bag_outlined),
          label: Text(l10n.buyNow),
        ),
      ],
    );
  }
}
