import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';

/// Thông tin tối thiểu để vẽ một poster / nền mờ.
typedef CoverRef = ({String title, String author, String? url, String seed});

CoverRef coverOfBook(Book b) =>
    (title: b.title, author: b.author, url: b.coverUrl, seed: b.id);

/// Khối nền mờ: bìa sách phóng to + làm mờ làm nền, phủ lớp tối ([dark]) hoặc sáng để chữ đọc được.
/// Dùng cho mọi khối ở trang chủ để mỗi khối có "màu" riêng của cuốn sách bên trong.
class BlurPanel extends StatelessWidget {
  const BlurPanel({
    super.key,
    required this.cover,
    required this.child,
    this.dark = true,
    this.radius = 28,
    this.onTap,
    this.art,
    this.height,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final CoverRef? cover;

  /// Tên tranh trong `assets/banners/<art>.jpg` (người dùng vẽ); thiếu file thì dùng nền bìa mờ.
  final String? art;
  final Widget child;
  final bool dark;
  final double radius;
  final VoidCallback? onTap;
  final double? height;
  final EdgeInsets padding;

  /// Nền khi chưa có tranh: bìa sách phóng to + làm mờ (hoặc màu trơn nếu không có bìa).
  Widget _fallback(AppColors c) => cover == null
      ? ColoredBox(color: c.fill)
      : BlurredCover(
          title: cover!.title,
          author: cover!.author,
          coverUrl: cover!.url,
          seed: cover!.seed,
          sigma: 40,
        );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final body = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          if (art != null)
            Positioned.fill(
              child: Image.asset(
                'assets/banners/$art.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(c),
              ),
            )
          else
            Positioned.fill(child: _fallback(c)),
          Positioned.fill(
            child: ColoredBox(
              color: dark
                  ? CoverPalette.scrim.withValues(
                      alpha: art != null ? 0.22 : 0.46,
                    )
                  : c.background.withValues(alpha: 0.52),
            ),
          ),
          // Có chiều cao cố định → nội dung lấp đầy (để canh giữa được); không → khối co theo nội dung.
          if (height == null)
            Padding(padding: padding, child: child)
          else
            Positioned.fill(
              child: Padding(padding: padding, child: child),
            ),
        ],
      ),
    );
    final sized = height == null ? body : SizedBox(height: height, child: body);
    if (onTap == null) return sized;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: sized,
      ),
    );
  }
}

/// Tiêu đề khối: serif lớn + dòng phụ + "Xem tất cả ›".
class BlockHeader extends StatelessWidget {
  const BlockHeader(this.title, {super.key, this.sub, this.onTap});

  final String title;
  final String? sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.headlineSmall),
                if (sub != null)
                  Text(
                    sub!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: c.secondaryText,
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            TextButton(onPressed: onTap, child: Text(context.l10n.hsSeeAll)),
        ],
      ),
    );
  }
}

/// Chồng 1–3 bìa xếp quạt (nghiêng nhẹ) — dùng trong thẻ danh mục / ấn bản / mức giá.
class CoverFan extends StatelessWidget {
  const CoverFan({super.key, required this.covers, required this.width});

  final List<CoverRef> covers;
  final double width;

  @override
  Widget build(BuildContext context) {
    final n = covers.length.clamp(0, 3);
    if (n == 0) return const SizedBox.shrink();
    final step = width * 0.55;
    // Bìa cao thấp theo ảnh thật (tỉ lệ ~0,6–0,75 → cao 1,33–1,65 × bề rộng): chừa đủ chỗ cho cuốn cao nhất
    // và canh đáy để các cuốn đứng trên cùng một đường kẻ.
    final h = width * 1.7;
    return SizedBox(
      width: width + step * (n - 1),
      height: h + 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = n - 1; i >= 0; i--)
            Positioned(
              left: step * i,
              bottom: 10 - (n - 1 - i) * 5.0,
              child: Transform.rotate(
                angle: (i - (n - 1) / 2) * 0.09,
                alignment: Alignment.bottomCenter,
                child: BookPoster(
                  title: covers[i].title,
                  author: covers[i].author,
                  coverUrl: covers[i].url,
                  seed: covers[i].seed,
                  width: width,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────── Lối sang khu đấu giá ─────────────────────

/// Khu đấu giá là một khu riêng (khung, màu và trang chủ riêng): ở app mua sách chỉ còn thẻ mời sang đó.
class AuctionEntryBanner extends StatelessWidget {
  const AuctionEntryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final text = context.textStyles;
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.auctionAppTitle,
          style: (compact ? text.headlineSmall : text.headlineMedium)?.copyWith(
            fontFamily: AppFonts.serif,
            color: AuctionPalette.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.modeToAuctionBody,
          style: text.bodyMedium?.copyWith(
            color: AuctionPalette.ink.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
    final button = FilledButton.icon(
      onPressed: () => context.go(Routes.auctions),
      style: FilledButton.styleFrom(
        backgroundColor: AuctionPalette.ink,
        foregroundColor: AppColors.auction.onSelected,
      ),
      icon: const Icon(Icons.gavel_rounded),
      label: Text(l10n.modeToAuction),
    );
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AuctionPalette.entry,
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                head,
                const SizedBox(height: AppSpacing.md),
                button,
              ],
            )
          : Row(
              children: [
                Expanded(child: head),
                const SizedBox(width: AppSpacing.lg),
                button,
              ],
            ),
    );
  }
}
