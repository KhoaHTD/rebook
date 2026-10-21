import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/domain/book.dart';
import 'package:book_marketplace/shared/widgets/book_condition_badge.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/price_text.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(child: BookCover(imageUrl: book.imageUrl)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleSmall,
              ),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(child: PriceText(book.price)),
                  BookConditionBadge(book.condition),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
