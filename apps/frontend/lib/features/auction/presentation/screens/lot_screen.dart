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
    if (compact) return _CompactLot(lotId: lotId);
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

/// Điện thoại: ảnh bìa phủ đầu trang kèm nút quay lại / tim, thẻ giá hiện tại + đếm ngược đè lên mép ảnh,
/// tên sách, bốn thông số, câu chuyện / báo cáo tình trạng, danh sách người trả giá và nút vào phòng ở đáy.
class _CompactLot extends ConsumerWidget {
  const _CompactLot({required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lot = ref.watch(lotDetailProvider(lotId));
    return AsyncValueView(
      value: lot,
      onRetry: () => ref.invalidate(lotDetailProvider(lotId)),
      data: (l) => _CompactLotBody(lot: l),
    );
  }
}

class _CompactLotBody extends ConsumerWidget {
  const _CompactLotBody({required this.lot});

  final Lot lot;

  static const _heroHeight = 380.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final book = lot.book;
    final safe = MediaQuery.paddingOf(context);
    final signedIn = ref.watch(sessionControllerProvider).isSignedIn;
    final bids = ref.watch(lotBidsProvider(lot.id)).value ?? const <Bid>[];
    final sessions = ref.watch(auctionSessionsProvider).value ?? const [];
    final session = sessions.where((s) => s.id == lot.sessionId).firstOrNull;
    // Lô đã chốt hoặc đang LIVE mà chưa có giờ kết thúc thì không có đồng hồ.
    final target = lot.hammerPrice != null
        ? null
        : (lot.endsAt ??
              ((session?.isLive ?? false) ? null : session?.startAt));
    final staffPhotos = [
      for (final i in book.images)
        if (i.fromStaff) i.url,
    ];
    Widget section(String title, Widget body) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );
    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
        ],
      ),
    );

    void goBack() => context.canPop()
        ? context.pop()
        : context.go(Routes.session(lot.sessionId));

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: _heroHeight + 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: _heroHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Nền đặc (không làm mờ ảnh): khu đấu giá là nền đen phẳng.
                          ColoredBox(
                            color: Color.alphaBlend(
                              c.fill,
                              context.colors.surface,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: safe.top + 56,
                              bottom: 64,
                            ),
                            child: Center(
                              child: BookPoster(
                                title: book.title,
                                author: book.author,
                                coverUrl: book.coverUrl,
                                seed: book.id,
                                width: 170,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 0,
                      child: Glass(
                        blur: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatVnd(
                                      lot.hammerPrice ?? lot.currentPrice,
                                    ),
                                    style: text.titleLarge?.copyWith(
                                      color: c.tint,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    lot.hammerPrice != null
                                        ? l10n.hammerPrice
                                        : l10n.currentPrice,
                                    style: text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (target != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 18,
                                          color: c.live,
                                        ),
                                        const SizedBox(width: 6),
                                        CountdownText(
                                          target: target,
                                          style: text.titleLarge?.copyWith(
                                            color: c.live,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(l10n.lotEndsIn, style: text.bodySmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: text.bodyMedium?.copyWith(color: c.secondaryText),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        stat(book.condition.label(l10n), l10n.condition),
                        stat('${book.publishYear ?? '—'}', l10n.publishYear),
                        stat(l10n.lotNumber(lot.lotNumber), l10n.lotsInSession),
                        stat(formatVnd(lot.startPrice), l10n.startPrice),
                      ],
                    ),
                    if (lot.story != null)
                      section(
                        l10n.lotStory,
                        Text(lot.story!, style: text.bodyLarge),
                      ),
                    if (lot.conditionReport != null)
                      section(
                        l10n.conditionReport,
                        Text(lot.conditionReport!, style: text.bodyLarge),
                      ),
                    if (staffPhotos.isNotEmpty)
                      section(l10n.staffPhotos, PhotoStrip(urls: staffPhotos)),
                    section(
                      l10n.lotBidders,
                      bids.isEmpty
                          ? Text(
                              l10n.noBids,
                              style: text.bodyMedium?.copyWith(
                                color: c.secondaryText,
                              ),
                            )
                          : Column(
                              children: [
                                for (final (i, b) in bids.take(6).indexed)
                                  BidRow(bid: b, highlight: i == 0),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: safe.top + 8,
          left: 12,
          right: 12,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Glass.circle(
                  clear: true,
                  onTap: goBack,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: CoverPalette.onHero,
                  ),
                ),
              ),
              const Spacer(),
              if (signedIn)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Glass.circle(
                    clear: true,
                    onTap: () => ref
                        .read(auctionActionsProvider.notifier)
                        .watch(lot.id, on: !lot.watched),
                    child: Icon(
                      lot.watched
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: lot.watched ? c.live : CoverPalette.onHero,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + safe.bottom,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.selected,
              foregroundColor: c.onSelected,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: () => context.go(
              (session?.isLive ?? false)
                  ? Routes.live(lot.sessionId)
                  : Routes.session(lot.sessionId),
            ),
            icon: const Icon(Icons.gavel_rounded),
            label: Text(l10n.lotBidNow),
          ),
        ),
      ],
    );
  }
}
