import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Thẻ "đang diễn ra" đầu trang Mua sách: bìa lô hiện tại phóng to + làm mờ làm nền,
/// thẻ kính trả giá (giá, người dẫn, đồng hồ) và nút vào phòng. Tự làm mới mỗi 2 giây.
class LiveHero extends ConsumerWidget {
  const LiveHero({super.key, required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveStateProvider(session.id)).value;
    final lot = state?.currentLot;
    if (state == null || lot == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final c = context.appColors;
    final compact = context.windowSize.isCompact;
    final onDark = c.onSelected;
    final offset = state.serverTime.difference(DateTime.now());
    final now = (ref.watch(clockProvider).value ?? DateTime.now()).add(offset);
    final left = lot.endsAt?.difference(now);

    final poster = BookPoster(
      title: lot.book.title,
      author: lot.book.author,
      coverUrl: lot.book.coverUrl,
      seed: lot.book.id,
      width: compact ? 88 : 124,
    );
    final live = PillBadge(
      '${l10n.live} · ${l10n.viewers(state.viewerCount)}',
      color: c.live,
    );
    final price = Text(
      formatVnd(lot.currentPrice),
      style:
          (compact
                  ? context.textStyles.titleLarge
                  : context.textStyles.headlineMedium)
              ?.copyWith(
                color: onDark,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
    );
    final facts = Text(
      [
        if (lot.leadingPaddle != null) l10n.leadingPaddle(lot.leadingPaddle!),
        if (left != null)
          l10n.timeLeft(
            formatCountdown(left.isNegative ? Duration.zero : left),
          ),
      ].join(' · '),
      style: context.textStyles.bodySmall?.copyWith(
        color: onDark.withValues(alpha: 0.85),
      ),
    );
    final enter = FilledButton(
      onPressed: () => context.go(Routes.live(session.id)),
      child: Text(l10n.enterLiveRoom),
    );
    final title = Text(
      lot.book.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style:
          (compact
                  ? context.textStyles.titleLarge
                  : context.textStyles.headlineSmall)
              ?.copyWith(color: onDark),
    );
    final subtitle = Text(
      '${l10n.lotNumber(lot.lotNumber)} · ${session.title}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textStyles.bodyMedium?.copyWith(
        color: onDark.withValues(alpha: 0.85),
      ),
    );

    final Widget body;
    if (compact) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            poster,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  live,
                  const SizedBox(height: AppSpacing.sm),
                  title,
                  price,
                  facts,
                  const SizedBox(height: AppSpacing.sm),
                  enter,
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            poster,
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  live,
                  const SizedBox(height: AppSpacing.md),
                  title,
                  const SizedBox(height: AppSpacing.xs),
                  subtitle,
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: 300,
              child: Glass(
                clear: true,
                shadow: false,
                padding: const EdgeInsets.all(AppSpacing.lg - 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.currentPrice,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: onDark.withValues(alpha: 0.8),
                      ),
                    ),
                    price,
                    facts,
                    const SizedBox(height: AppSpacing.md),
                    enter,
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: Stack(
        children: [
          // Nền: chính bìa lô đang bán, phóng to và làm mờ.
          Positioned.fill(
            child: BlurredCover(
              title: lot.book.title,
              author: lot.book.author,
              coverUrl: lot.book.coverUrl,
              seed: lot.book.id,
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: CoverPalette.scrim)),
          body,
        ],
      ),
    );
  }
}
