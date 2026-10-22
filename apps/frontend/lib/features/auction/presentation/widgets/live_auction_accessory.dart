import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/live_badge.dart';

/// Thanh kính phía trên thanh tab (như mini player của Apple Music) khi có lô đang đấu.
/// Không có lô nào đang diễn ra thì không chiếm chỗ.
class LiveAuctionAccessory extends ConsumerWidget {
  const LiveAuctionAccessory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveAuctionProvider).value;
    if (live == null) return const SizedBox.shrink();
    final auction = ref.watch(auctionRoomProvider(live.id)).value ?? live;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    if (!auction.isLiveAt(now)) return const SizedBox.shrink();
    return _Bar(auction: auction, now: now);
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.auction, required this.now});

  final Auction auction;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    void open() => context.push(Routes.auctionRoom(auction.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassSurface(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: open,
            child: SizedBox(
              height: AppSizes.accessoryHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: BookCover(
                        imageUrl: auction.book.imageUrl,
                        elevated: false,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auction.book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.titleSmall,
                          ),
                          Row(
                            children: [
                              const LiveDot(),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  l10n.accessoryStatus(
                                    formatVnd(auction.currentPrice),
                                    formatClock(auction.endsAt.difference(now)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: colors.labelSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: open,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: context.textStyles.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        auction.youAreLeading
                            ? l10n.leadingShort
                            : l10n.bidShort(
                                formatMillionsShort(auction.nextMinBid),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
