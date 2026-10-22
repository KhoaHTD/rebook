import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/live_badge.dart';

/// Thẻ tối "phiên đang diễn ra": bìa, giá hiện tại, thời gian còn lại, nút vào phòng.
/// Dùng ở Trang chủ (tab Đấu giá) và màn Đấu giá.
class LiveAuctionCard extends ConsumerWidget {
  const LiveAuctionCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.currentPrice,
    required this.endsAt,
    required this.onEnter,
    this.sessionTitle,
    this.lotNumber,
    this.lotCount,
    this.durationSeconds = 60,
  });

  final String title;
  final String? imageUrl;
  final int currentPrice;
  final DateTime endsAt;
  final VoidCallback onEnter;
  final String? sessionTitle;
  final int? lotNumber;
  final int? lotCount;
  final int durationSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final left = endsAt.difference(now);
    final progress = (left.inMilliseconds / (durationSeconds * 1000)).clamp(
      0.0,
      1.0,
    );
    final muted = context.textStyles.bodySmall?.copyWith(
      color: colors.onStrongSurfaceMuted,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.strongSurface,
        borderRadius: AppRadius.group,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const LiveBadge(),
              const Spacer(),
              if (lotNumber != null && lotCount != null)
                Text(l10n.lotOfCount(lotNumber!, lotCount!), style: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(width: 84, child: BookCover(imageUrl: imageUrl)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sessionTitle != null) Text(sessionTitle!, style: muted),
                    Text(
                      title,
                      style: context.textStyles.titleLarge?.copyWith(
                        color: colors.onStrongSurface,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
                    Text(
                      l10n.currentPriceTimeLeft(formatClock(left)),
                      style: muted,
                    ),
                    Text(
                      formatVnd(currentPrice),
                      style: context.textStyles.headlineMedium?.copyWith(
                        color: colors.onStrongSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: colors.onStrongSurface,
              backgroundColor: colors.onStrongSurface.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onEnter,
            style: FilledButton.styleFrom(
              backgroundColor: colors.onStrongSurface,
              foregroundColor: colors.strongSurface,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l10n.enterAuctionRoom),
          ),
        ],
      ),
    );
  }
}

/// Ô ngày kiểu Lịch: "THG 11" đỏ ở trên, số ngày to bên dưới.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: colors.groupedBackground,
        borderRadius: const BorderRadius.all(Radius.circular(13)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.monthShort(date.month),
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.auctionLive,
              fontSize: 10,
            ),
          ),
          Text(
            '${date.day}',
            style: context.textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
