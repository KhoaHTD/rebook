import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Ô một phiên đấu giá: poster của phiên, badge LIVE hoặc giờ bắt đầu, số lô.
class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session, this.onTap});

  final AuctionSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PosterTile(
      poster: BookPoster(
        title: session.title,
        author: l10n.lotsCount(session.lotCount),
        coverUrl: session.coverImageUrl,
        seed: session.id,
      ),
      title: session.title,
      onTap: onTap,
      meta: Row(
        children: [
          if (session.isLive) ...[
            PillBadge(l10n.live, color: context.appColors.live),
            const SizedBox(width: 6),
            Flexible(
              child: Text(l10n.registeredCount(session.registeredCount)),
            ),
          ] else ...[
            PillBadge.auction(context),
            const SizedBox(width: 6),
            Flexible(child: Text(formatShortDateTime(session.startAt))),
          ],
        ],
      ),
    );
  }
}
