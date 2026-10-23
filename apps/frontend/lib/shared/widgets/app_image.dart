import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/network/upload_service.dart';

/// Ảnh từ URL thật (cache), ảnh vừa upload ở chế độ mock (`mem://`) hoặc ảnh đóng gói sẵn trong app (`assets/...`, bìa sách mẫu).
class AppImage extends StatelessWidget {
  const AppImage(this.url, {super.key, this.fit = BoxFit.cover, this.fallback});

  final String url;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final placeholder = fallback ?? ColoredBox(color: context.appColors.fill);
    if (MemoryImages.isMemory(url)) {
      final bytes = MemoryImages.get(url);
      return bytes == null ? placeholder : Image.memory(bytes, fit: fit);
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: fit, errorBuilder: (_, _, _) => placeholder);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

/// Dải ảnh vuông bo góc (ảnh thật của tin đăng, ảnh kiểm định, ảnh trả hàng).
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.urls, this.size = 88});

  final List<String> urls;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                child: AppImage(urls[i], fit: BoxFit.contain),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.item,
            child: SizedBox.square(dimension: size, child: AppImage(urls[i])),
          ),
        ),
      ),
    );
  }
}
