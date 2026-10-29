import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Chấm đỏ nhấp nháy + chữ LIVE.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = context.appColors.live;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: live,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: live.withValues(alpha: 0.7), blurRadius: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          context.l10n.live,
          style: context.textStyles.labelMedium?.copyWith(
            color: live,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// "còn 2 ngày 5 giờ" hoặc đồng hồ `HH:MM:SS` khi còn dưới một ngày. Chạy theo [clockProvider].
/// [offset]: chênh lệch giờ server − máy (để khớp đồng hồ phòng live).
class CountdownText extends ConsumerWidget {
  const CountdownText({
    super.key,
    required this.target,
    this.offset = Duration.zero,
    this.style,
  });

  final DateTime target;
  final Duration offset;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = (ref.watch(clockProvider).value ?? DateTime.now()).add(offset);
    final left = target.difference(now);
    final text = left.inDays >= 1
        ? l10n.countdownDays(left.inDays, left.inHours.remainder(24))
        : formatCountdown(left.isNegative ? Duration.zero : left);
    return Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Thẻ lớn cho phiên đang LIVE: bìa lô hiện tại làm nền mờ, giá hiện tại to, đồng hồ lô, nút vào phòng.
class LiveSpotlightCard extends ConsumerWidget {
  const LiveSpotlightCard({super.key, required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final compact = context.windowSize.isCompact;
    final room = ref.watch(liveRoomProvider(session.id)).value;
    final lot = room?.snapshot.currentLot;
    final book = lot?.book;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const LiveBadge(),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                l10n.viewers(
                  room?.snapshot.viewerCount ?? session.watcherCount,
                ),
                style: text.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          session.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall?.copyWith(color: c.secondaryText),
        ),
        const SizedBox(height: 2),
        Text(
          book?.title ?? l10n.waitingNextLot,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (compact ? text.headlineSmall : text.headlineMedium)?.copyWith(
            fontFamily: AppFonts.serif,
          ),
        ),
        if (lot != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.floorCurrentPrice, style: text.labelMedium),
          Text(
            formatVnd(lot.currentPrice),
            style: (compact ? text.headlineMedium : text.displaySmall)
                ?.copyWith(color: c.tint, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: c.live),
              const SizedBox(width: 6),
              if (lot.endsAt != null)
                CountdownText(
                  target: lot.endsAt!,
                  offset: room?.serverOffset ?? Duration.zero,
                  style: text.titleMedium?.copyWith(color: c.live),
                ),
              if (lot.leadingPaddle != null) ...[
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    l10n.leadingPaddle(lot.leadingPaddle!),
                    style: text.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => context.go(Routes.live(session.id)),
          icon: const Icon(Icons.sensors_rounded),
          label: Text(l10n.enterLiveRoom),
        ),
      ],
    );

    final poster = book == null
        ? null
        : BookPoster(
            title: book.title,
            author: book.author,
            coverUrl: book.coverUrl,
            seed: book.id,
            width: compact ? 128 : 168,
          );

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Stack(
        children: [
          if (book != null)
            Positioned.fill(
              child: BlurredCover(
                title: book.title,
                author: book.author,
                coverUrl: book.coverUrl,
                seed: book.id,
                sigma: 40,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colors.surface.withValues(alpha: 0.78),
                    context.colors.surface.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(color: c.live.withValues(alpha: 0.55)),
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (poster != null)
                        Align(alignment: Alignment.centerLeft, child: poster),
                      if (poster != null) const SizedBox(height: AppSpacing.md),
                      info,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (poster != null) ...[
                        poster,
                        const SizedBox(width: AppSpacing.xl),
                      ],
                      Expanded(child: info),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ một sự kiện đấu giá: khối ngày to bên trái, tên phiên, giờ, số lô, tiền cọc, trạng thái đăng ký.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.session,
    this.onTap,
    this.trailing,
  });

  final AuctionSession session;
  final VoidCallback? onTap;

  /// Thay cho nút mặc định ở cuối thẻ.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final start = session.startAt.toLocal();
    final open = session.acceptsRegistration;
    final dateBlock = Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: session.isLive ? c.live.withValues(alpha: 0.18) : c.tintSoft,
        border: Border.all(
          color: (session.isLive ? c.live : c.tint).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'T${start.month}',
            style: text.labelMedium?.copyWith(
              color: session.isLive ? c.live : c.tint,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${start.day}',
            style: text.headlineMedium?.copyWith(
              fontFamily: AppFonts.serif,
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    final compact = context.windowSize.isCompact;
    final ended = SessionTab.ended.matches(session.status);
    // Điện thoại: nút hành động nằm dưới thông tin (đỡ ép chữ), desktop: bên phải.
    final below = compact && trailing != null;
    final row = Row(
      children: [
        dateBlock,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                '${formatShortDateTime(session.startAt)} · ${l10n.lotsCount(session.lotCount)}',
                style: text.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.depositFrom(formatVnd(session.depositAmount))} · ${l10n.registeredCount(session.registeredCount)}',
                style: text.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (session.isLive)
                const LiveBadge()
              else if (!ended)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      open
                          ? Icons.how_to_reg_rounded
                          : Icons.lock_clock_outlined,
                      size: 14,
                      color: open ? c.success : c.tertiaryText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        open ? l10n.scheduleRegOpen : l10n.scheduleRegClosed,
                        style: text.labelMedium?.copyWith(
                          color: open ? c.success : c.tertiaryText,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (trailing != null && !below) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ] else if (trailing == null)
          Icon(Icons.chevron_right_rounded, color: c.tertiaryText),
      ],
    );
    return Glass(
      blur: false,
      shadow: false,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: below
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row,
                const SizedBox(height: AppSpacing.md),
                trailing!,
              ],
            )
          : row,
    );
  }
}

/// Sân khấu LIVE (điện thoại): một thẻ cao chiếm gần cả màn hình cho phiên đang diễn ra — bìa lô hiện tại
/// to giữa sân khấu có quầng sáng, giá hiện tại cỡ chữ lớn, đồng hồ lô, nút vào phòng bản rộng.
class LiveStageCard extends ConsumerWidget {
  const LiveStageCard({super.key, required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final room = ref.watch(liveRoomProvider(session.id)).value;
    final lot = room?.snapshot.currentLot;
    final book = lot?.book;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      child: Stack(
        children: [
          if (book != null)
            Positioned.fill(
              child: BlurredCover(
                title: book.title,
                author: book.author,
                coverUrl: book.coverUrl,
                seed: book.id,
                sigma: 36,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.surface.withValues(alpha: 0.55),
                    context.colors.surface.withValues(alpha: 0.93),
                  ],
                ),
                border: Border.all(color: c.live.withValues(alpha: 0.6)),
                borderRadius: const BorderRadius.all(Radius.circular(32)),
              ),
            ),
          ),
          // Quầng sáng vàng sau bìa, như đèn rọi sân khấu.
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.tint.withValues(alpha: 0.28),
                      c.tint.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const LiveBadge(),
                    const Spacer(),
                    Icon(
                      Icons.visibility_rounded,
                      size: 16,
                      color: c.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.viewers(
                        room?.snapshot.viewerCount ?? session.watcherCount,
                      ),
                      style: text.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (book != null)
                  Center(
                    child: BookPoster(
                      title: book.title,
                      author: book.author,
                      coverUrl: book.coverUrl,
                      seed: book.id,
                      width: 190,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.labelLarge?.copyWith(color: c.secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  book?.title ?? l10n.waitingNextLot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (lot != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.floorCurrentPrice,
                    textAlign: TextAlign.center,
                    style: text.labelMedium,
                  ),
                  Text(
                    formatVnd(lot.currentPrice),
                    textAlign: TextAlign.center,
                    style: text.displaySmall?.copyWith(
                      color: c.tint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: c.live),
                      const SizedBox(width: 6),
                      if (lot.endsAt != null)
                        CountdownText(
                          target: lot.endsAt!,
                          offset: room?.serverOffset ?? Duration.zero,
                          style: text.titleLarge?.copyWith(color: c.live),
                        ),
                      if (lot.leadingPaddle != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text(
                            l10n.leadingPaddle(lot.leadingPaddle!),
                            style: text.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.selected,
                    foregroundColor: c.onSelected,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => context.go(Routes.live(session.id)),
                  icon: const Icon(Icons.sensors_rounded),
                  label: Text(l10n.enterLiveRoom),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
