import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_stage_widgets.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auto_shelf.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/session_watch_button.dart';
import 'package:book_marketplace/shared/domain/auction.dart';

/// Một phiên đấu giá trên trang chủ: tên phiên, trạng thái (LIVE hoặc giờ mở), số lô, số người đăng ký, bên dưới là
/// **các lô của phiên đó chạy liên tục từ trái sang phải** trên một kệ (phiên là cả kệ, không có cuốn đại diện).
/// Bấm vào thẻ mở phiên (LIVE thì vào thẳng phòng); bấm một bìa mở lô đó.
class SessionShelfCard extends ConsumerWidget {
  const SessionShelfCard({super.key, required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final c = context.appColors;
    final lots =
        ref.watch(sessionCatalogueProvider(session.id)).value?.$2 ??
        const <Lot>[];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go(
        session.isLive ? Routes.live(session.id) : Routes.session(session.id),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.fill,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (session.isLive)
                        const LiveBadge()
                      else
                        Text(
                          formatShortDateTime(session.startAt),
                          style: text.labelLarge?.copyWith(
                            color: c.tint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.lotsCount(session.lotCount)} · ${l10n.registeredCount(session.registeredCount)}',
                        style: text.bodySmall?.copyWith(color: c.secondaryText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (lots.isEmpty)
                  const SizedBox(height: 116)
                else
                  AutoShelf(
                    bookWidth: 70,
                    height: 116,
                    books: [
                      for (final l in lots)
                        ShelfBook(
                          id: l.id,
                          title: l.book.title,
                          author: l.book.author,
                          coverUrl: l.book.coverUrl,
                          onTap: () => context.go(Routes.lot(l.id)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: SessionWatchButton(sessionId: session.id),
          ),
        ],
      ),
    );
  }
}
