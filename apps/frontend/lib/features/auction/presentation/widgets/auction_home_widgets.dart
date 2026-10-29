import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_stage_widgets.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Hàng banner lướt ngang ở đầu trang chủ đấu giá: mỗi banner là một phiên, ghi **tên phiên**,
/// trạng thái (LIVE hoặc giờ mở), số lô và số người đăng ký. Bấm vào mở phiên (LIVE thì vào thẳng phòng).
class SessionBannerCarousel extends StatefulWidget {
  const SessionBannerCarousel({super.key, required this.sessions});

  final List<AuctionSession> sessions;

  @override
  State<SessionBannerCarousel> createState() => _SessionBannerCarouselState();
}

class _SessionBannerCarouselState extends State<SessionBannerCarousel> {
  final _pages = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final list = widget.sessions;
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pages,
            itemCount: list.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _Banner(session: list[i]),
            ),
          ),
        ),
        if (list.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < list.length; i++)
                AnimatedContainer(
                  duration: AppDurations.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == _page ? c.tint : c.tertiaryText,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final url = session.coverImageUrl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go(
        session.isLive ? Routes.live(session.id) : Routes.session(session.id),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              AppImage(url)
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AuctionPalette.entry,
                  ),
                ),
              ),
            // Lớp tối dần xuống dưới để chữ tên phiên luôn đọc được trên mọi ảnh.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CoverPalette.scrim.withValues(alpha: 0),
                    CoverPalette.scrim.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (session.isLive)
                    const LiveBadge()
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CoverPalette.onHero.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        formatShortDateTime(session.startAt),
                        style: text.labelMedium?.copyWith(
                          color: CoverPalette.onHero,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineSmall?.copyWith(
                      color: CoverPalette.onHero,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.lotsCount(session.lotCount)} · ${l10n.registeredCount(session.registeredCount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: CoverPalette.onHero.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ một lô (kiểu danh sách "Khám phá"): bìa lớn trên nền mờ, đồng hồ đếm ngược ở góc dưới trái ảnh,
/// thẻ giá ở góc dưới phải, nút tim theo dõi; dưới ảnh là tên sách và tên phiên.
class AuctionLotCard extends ConsumerWidget {
  const AuctionLotCard({super.key, required this.lot, this.session});

  final Lot lot;

  /// Phiên của lô (để lấy giờ mở khi lô chưa có giờ kết thúc, và hiện tên phiên).
  final AuctionSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final text = context.textStyles;
    final signedIn = ref.watch(sessionControllerProvider).isSignedIn;
    final book = lot.book;
    // Lô đã chốt thì không đếm; lô đang trong phiên LIVE mà chưa có giờ kết thúc thì hiện nhãn LIVE.
    final liveNow = (session?.isLive ?? false) && lot.hammerPrice == null;
    final target = lot.hammerPrice != null
        ? null
        : (lot.endsAt ?? (liveNow ? null : session?.startAt));
    const radius = BorderRadius.all(Radius.circular(24));
    return Glass(
      blur: false,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      onTap: () => context.go(Routes.lot(lot.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BlurredCover(
                    title: book.title,
                    author: book.author,
                    coverUrl: book.coverUrl,
                    seed: book.id,
                    sigma: 30,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.surface.withValues(alpha: 0.35),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 34),
                    child: Center(
                      child: BookPoster(
                        title: book.title,
                        author: book.author,
                        coverUrl: book.coverUrl,
                        seed: book.id,
                        width: 104,
                      ),
                    ),
                  ),
                  if (signedIn)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Glass.circle(
                          clear: true,
                          onTap: () => ref
                              .read(auctionActionsProvider.notifier)
                              .watch(lot.id, on: !lot.watched),
                          child: Icon(
                            lot.watched
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: lot.watched ? c.live : CoverPalette.onHero,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: target == null
                        ? (liveNow
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CoverPalette.scrim.withValues(
                                      alpha: 0.6,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const LiveBadge(),
                                )
                              : const SizedBox.shrink())
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: CoverPalette.scrim.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 15,
                                  color: CoverPalette.onHero,
                                ),
                                const SizedBox(width: 6),
                                CountdownText(
                                  target: target,
                                  style: text.labelLarge?.copyWith(
                                    color: CoverPalette.onHero,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.selected,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                        ),
                      ),
                      child: Text(
                        formatVnd(lot.currentPrice),
                        style: text.titleMedium?.copyWith(
                          color: c.onSelected,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session == null
                      ? book.author
                      : '${book.author} · ${session!.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
