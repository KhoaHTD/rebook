import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

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
    this.height,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final CoverRef? cover;
  final Widget child;
  final bool dark;
  final double radius;
  final VoidCallback? onTap;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final body = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          if (cover != null)
            Positioned.fill(
              child: BlurredCover(
                title: cover!.title,
                author: cover!.author,
                coverUrl: cover!.url,
                seed: cover!.seed,
                sigma: 40,
              ),
            )
          else
            Positioned.fill(child: ColoredBox(color: c.fill)),
          Positioned.fill(
            child: ColoredBox(
              color: dark
                  ? CoverPalette.scrim.withValues(alpha: 0.46)
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
    final h = width * 1.5;
    return SizedBox(
      width: width + step * (n - 1),
      height: h + 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = n - 1; i >= 0; i--)
            Positioned(
              left: step * i,
              top: (n - 1 - i) * 5.0,
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

// ───────────────────── Phiên đấu giá nổi bật ─────────────────────

/// Phiên đang LIVE (thẻ lớn, có dải các lô), các phiên sắp diễn ra (thẻ chồng bìa) và phiên vừa kết thúc.
class HomeAuctions extends ConsumerWidget {
  const HomeAuctions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final sessions = ref.watch(homeSessionsProvider).value ?? const [];
    if (sessions.isEmpty) return const SizedBox.shrink();
    final live = sessions.where((s) => s.isLive).toList();
    final upcoming =
        sessions
            .where(
              (s) =>
                  s.status == SessionStatus.published ||
                  s.status == SessionStatus.confirmed,
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final ended = sessions
        .where((s) => s.status == SessionStatus.ended)
        .toList();

    final left = live.isNotEmpty
        ? _LiveCard(session: live.first, compact: compact)
        : BlurPanel(
            cover: null,
            dark: false,
            height: 200,
            child: Center(
              child: Text(
                l10n.hsNoLive,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
            ),
          );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in upcoming.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _UpcomingCard(session: s),
          ),
        for (final s in ended.take(1)) _EndedRow(session: s),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeader(
          l10n.hsAuctionsTitle,
          sub: l10n.hsAuctionsSub,
          onTap: () => context.go(Routes.auctions),
        ),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: AppSpacing.md),
              right,
            ],
          )
        else
          SizedBox(
            height: 444,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 5, child: right),
              ],
            ),
          ),
      ],
    );
  }
}

class _LiveCard extends ConsumerWidget {
  const _LiveCard({required this.session, required this.compact});

  final AuctionSession session;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final onDark = c.onSelected;
    final lots = ref.watch(sessionLotsProvider(session.id)).value ?? const [];
    final current = lots.isEmpty
        ? null
        : lots.firstWhere(
            (l) => l.status == LotStatus.live,
            orElse: () => lots.first,
          );
    final cover = current == null ? null : coverOfBook(current.book);
    final posterW = compact ? 120.0 : 170.0;

    return BlurPanel(
      cover: cover,
      height: compact ? 440 : null,
      onTap: () => context.go(Routes.live(session.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (current != null)
                  BookPoster(
                    title: current.book.title,
                    author: current.book.author,
                    coverUrl: current.book.coverUrl,
                    seed: current.book.id,
                    width: posterW,
                  ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PillBadge(l10n.live, color: c.live),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              l10n.viewers(session.watcherCount),
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: onDark.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.headlineMedium?.copyWith(
                          color: onDark,
                        ),
                      ),
                      if (current != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.lotNumber(current.lotNumber)} · ${current.book.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: onDark.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          formatVnd(current.currentPrice),
                          style: context.textStyles.headlineSmall?.copyWith(
                            color: onDark,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () => context.go(Routes.live(session.id)),
                        child: Text(l10n.enterLiveRoom),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.hsNextLots,
            style: context.textStyles.labelMedium?.copyWith(
              color: onDark.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final lot in lots.take(10))
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: BookPoster(
                      title: lot.book.title,
                      author: lot.book.author,
                      coverUrl: lot.book.coverUrl,
                      seed: lot.book.id,
                      width: 56,
                      shadow: false,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard({required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final onDark = c.onSelected;
    final lots = ref.watch(sessionLotsProvider(session.id)).value ?? const [];
    final covers = [for (final l in lots.take(3)) coverOfBook(l.book)];
    return BlurPanel(
      cover: covers.isEmpty ? null : covers.first,
      height: 168,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go(Routes.session(session.id)),
      child: Row(
        children: [
          CoverFan(covers: covers, width: 62),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PillBadge.auction(context),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleLarge?.copyWith(
                    color: onDark,
                    fontFamily: AppFonts.serif,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.hsStartsAt(formatShortDateTime(session.startAt)),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: onDark.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '${l10n.lotsCount(session.lotCount)} · ${l10n.registeredCount(session.registeredCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: onDark.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndedRow extends ConsumerWidget {
  const _EndedRow({required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lots = ref.watch(sessionLotsProvider(session.id)).value ?? const [];
    final sold = lots
        .where((l) => l.hammerPrice != null)
        .fold<int>(0, (n, l) => n + l.hammerPrice!);
    return BlurPanel(
      cover: lots.isEmpty ? null : coverOfBook(lots.first.book),
      dark: false,
      radius: 22,
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: () => context.go(Routes.results(session.id)),
      child: Row(
        children: [
          Icon(
            Icons.flag_rounded,
            color: context.appColors.secondaryText,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.hsEnded} · ${session.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                if (sold > 0)
                  Text(
                    l10n.soldFor(formatVnd(sold)),
                    style: context.textStyles.bodySmall,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
