import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_widgets.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Chi tiết một lô: ước tính, giá khởi điểm, báo cáo tình trạng, ảnh kiểm định, câu chuyện,
/// chữ ký, theo dõi lô, lịch sử trả giá (SRS 6.2 – 6.3).
class LotScreen extends ConsumerWidget {
  const LotScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lot = ref.watch(lotDetailProvider(lotId));
    final compact = context.windowSize.isCompact;
    return AppPage(
      title: lot.value == null
          ? ''
          : context.l10n.lotNumber(lot.value!.lotNumber),
      showBack: true,
      background: lot.value == null
          ? null
          : BookBackdrop(
              title: lot.value!.book.title,
              author: lot.value!.book.author,
              coverUrl: lot.value!.book.coverUrl,
              seed: lot.value!.book.id,
            ),
      onRefresh: () => ref.refresh(lotDetailProvider(lotId).future),
      children: [
        AsyncValueView(
          value: lot,
          onRetry: () => ref.invalidate(lotDetailProvider(lotId)),
          data: (l) {
            final poster = BookPoster(
              title: l.book.title,
              author: l.book.author,
              coverUrl: l.book.coverUrl,
              seed: l.book.id,
              width: compact ? 220 : 300,
            );
            if (compact) {
              return Column(
                children: [
                  poster,
                  const SizedBox(height: AppSpacing.xl),
                  Glass(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _Info(lot: l),
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                poster,
                const SizedBox(width: 56),
                Expanded(
                  child: Glass(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _Info(lot: l),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final bids = ref.watch(lotBidsProvider(lot.id)).value ?? const <Bid>[];
    final signedIn = ref.watch(sessionControllerProvider).isSignedIn;
    final staffPhotos = [
      for (final i in lot.book.images)
        if (i.fromStaff) i.url,
    ];
    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(t, style: context.textStyles.titleMedium),
    );
    Widget money(String label, int amount) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.bodySmall),
          PriceText(amount, style: context.textStyles.titleLarge),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lot.book.title, style: context.textStyles.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          lot.book.author,
          style: context.textStyles.titleLarge?.copyWith(
            color: c.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusPill(lot.status.label(l10n), tone: lot.status.tone),
            StatusPill(
              lot.book.condition.label(l10n),
              tone: lot.book.condition.tone,
            ),
            if (lot.signature != SignatureStatus.none)
              StatusPill(
                lot.signature == SignatureStatus.verified
                    ? l10n.signatureVerified
                    : l10n.signatureUnverified,
                tone: lot.signature == SignatureStatus.verified
                    ? StatusTone.success
                    : StatusTone.warning,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        InfoPanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.estimate, style: context.textStyles.bodySmall),
              Text(
                '${formatVnd(lot.estimateLow)} – ${formatVnd(lot.estimateHigh)}',
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  money(l10n.startPrice, lot.startPrice),
                  if (lot.hammerPrice != null)
                    money(l10n.hammerPrice, lot.hammerPrice!)
                  else
                    money(l10n.currentPrice, lot.currentPrice),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.bidCount(lot.bidCount),
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: () => context.go(Routes.session(lot.sessionId)),
              child: Text(l10n.viewSession),
            ),
            if (signedIn)
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(auctionActionsProvider.notifier)
                    .watch(lot.id, on: !lot.watched),
                icon: Icon(
                  lot.watched
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  size: 18,
                ),
                label: Text(lot.watched ? l10n.watching : l10n.watchLot),
              ),
          ],
        ),
        if (lot.story != null) ...[
          heading(l10n.lotStory),
          Text(lot.story!, style: context.textStyles.bodyLarge),
        ],
        if (lot.conditionReport != null) ...[
          heading(l10n.conditionReport),
          Text(lot.conditionReport!, style: context.textStyles.bodyLarge),
        ],
        if (staffPhotos.isNotEmpty) ...[
          heading(l10n.staffPhotos),
          PhotoStrip(urls: staffPhotos),
        ],
        heading(l10n.bidHistory),
        if (bids.isEmpty)
          Text(
            l10n.noBids,
            style: context.textStyles.bodyMedium?.copyWith(
              color: c.secondaryText,
            ),
          )
        else
          for (final (i, b) in bids.indexed) BidRow(bid: b, highlight: i == 0),
      ],
    );
  }
}
