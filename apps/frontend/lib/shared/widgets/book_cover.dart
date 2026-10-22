import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Ảnh bìa sách tỉ lệ 2:3 trông như sách thật: góc gần vuông, bóng đổ,
/// vệt sáng ở gáy bên trái. Có placeholder khi chưa có ảnh hoặc lỗi tải.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.imageUrl,
    this.borderRadius = AppRadius.cover,
    this.elevated = true,
  });

  final String? imageUrl;
  final BorderRadius borderRadius;

  /// Bóng đổ lớn hơn cho bìa nổi bật (đầu trang lô, phòng đấu giá).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final placeholder = ColoredBox(
      color: colors.groupedBackground,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 32,
          color: colors.labelTertiary,
        ),
      ),
    );

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: elevated ? 24 : 10,
              offset: Offset(0, elevated ? 12 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl == null)
                placeholder
              else
                CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
              // Vệt gáy sách
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    stops: const [0, 0.02, 0.06],
                    colors: [
                      colors.shadow,
                      colors.onDark.withValues(alpha: 0.22),
                      colors.onDark.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
