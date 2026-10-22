import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Ô một lô trong catalogue: poster, "Lô n · tên", ước tính hoặc giá búa.
class LotTile extends StatelessWidget {
  const LotTile({super.key, required this.lot, this.onTap});

  final Lot lot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final book = lot.book;
    final meta = switch (lot.status) {
      LotStatus.sold || LotStatus.completed => l10n.soldFor(
        formatVnd(lot.hammerPrice ?? lot.currentPrice),
      ),
      LotStatus.live =>
        '${formatVnd(lot.currentPrice)} · ${l10n.bidCount(lot.bidCount)}',
      _ =>
        '${l10n.estimate} ${formatVnd(lot.estimateLow)}–${formatVnd(lot.estimateHigh)}',
    };
    return PosterTile(
      poster: BookPoster(
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        seed: book.id,
        badge: lot.status == LotStatus.live
            ? PillBadge(l10n.live, color: context.appColors.live)
            : null,
      ),
      title: '${l10n.lotNumber(lot.lotNumber)} · ${book.title}',
      onTap: onTap,
      meta: Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Nhãn đăng ký phiên.
extension RegistrationStatusL10n on RegistrationStatus {
  String label(AppLocalizations l) => switch (this) {
    RegistrationStatus.pendingDeposit => l.regPending,
    RegistrationStatus.approved => l.regApproved,
    RegistrationStatus.refunded => l.regRefunded,
    RegistrationStatus.applied => l.regApplied,
    RegistrationStatus.forfeited => l.regForfeited,
  };

  StatusTone get tone => switch (this) {
    RegistrationStatus.pendingDeposit => StatusTone.warning,
    RegistrationStatus.approved => StatusTone.success,
    RegistrationStatus.refunded ||
    RegistrationStatus.applied => StatusTone.neutral,
    RegistrationStatus.forfeited => StatusTone.danger,
  };
}

/// Khối thông tin phiên: trạng thái, giờ, hạn đăng ký, số lô, số người, cọc.
class SessionFacts extends StatelessWidget {
  const SessionFacts({super.key, required this.session});

  final AuctionSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget fact(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.appColors.secondaryText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusPill(session.status.label(l10n), tone: session.status.tone),
        const SizedBox(height: AppSpacing.md),
        fact(
          Icons.event_rounded,
          l10n.startsAt(formatDateTime(session.startAt)),
        ),
        fact(
          Icons.how_to_reg_outlined,
          l10n.registrationCloses(formatDateTime(session.registrationDeadline)),
        ),
        fact(Icons.menu_book_outlined, l10n.lotsCount(session.lotCount)),
        fact(
          Icons.groups_outlined,
          '${l10n.registeredCount(session.registeredCount)} · ${l10n.minParticipants}: ${session.minParticipants}',
        ),
        fact(
          Icons.lock_outline_rounded,
          l10n.depositFrom(formatVnd(session.depositAmount)),
        ),
      ],
    );
  }
}

/// Dòng một lượt trả giá: "Bài #027 trả 1.200.000 ₫" + giờ.
class BidRow extends StatelessWidget {
  const BidRow({super.key, required this.bid, this.highlight = false});

  final Bid bid;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            bid.isAuto ? Icons.smart_toy_outlined : Icons.pan_tool_alt_outlined,
            size: 16,
            color: context.appColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.bidPlacedBy(bid.paddleNumber, formatVnd(bid.amount)),
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: highlight ? FontWeight.w700 : null,
              ),
            ),
          ),
          Text(
            formatShortDateTime(bid.createdAt),
            style: context.textStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
