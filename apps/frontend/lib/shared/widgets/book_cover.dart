import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Ảnh bìa sách tỉ lệ 2:3, có placeholder khi chưa có ảnh hoặc lỗi tải.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.imageUrl,
    this.borderRadius = AppRadius.card,
  });

  final String? imageUrl;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: context.colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 40,
          color: context.colors.outline,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: imageUrl == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
