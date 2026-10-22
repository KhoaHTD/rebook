import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Huy hiệu đỏ "● LIVE" cho phiên đấu giá đang diễn ra.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.auctionLive,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveDot(color: colors.onAuctionLive),
          const SizedBox(width: 6),
          Text(
            context.l10n.liveBadge,
            style: context.textStyles.labelMedium?.copyWith(
              color: colors.onAuctionLive,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveDot extends StatelessWidget {
  const LiveDot({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color ?? context.appColors.auctionLive,
        shape: BoxShape.circle,
      ),
    );
  }
}
