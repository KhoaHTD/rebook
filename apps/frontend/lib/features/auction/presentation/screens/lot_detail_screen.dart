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
import 'package:book_marketplace/features/auction/presentation/widgets/max_bid_sheet.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_condition_badge.dart';
import 'package:book_marketplace/shared/widgets/book_cover.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/grouped_section.dart';

/// Catalogue một lô: đầu trang tối theo màu bìa, dải thông số, báo cáo kiểm định,
/// chi phí nếu thắng, điều kiện tham gia; thanh kính dưới đáy để đăng ký / vào phòng.
class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncValueView(
        value: ref.watch(lotDetailProvider(lotId)),
        onRetry: () => ref.invalidate(lotDetailProvider(lotId)),
        data: (lot) => Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(lot: lot)),
                SliverToBoxAdapter(child: _StatStrip(lot: lot)),
                SliverToBoxAdapter(
                  child: MaxWidthBox(
                    maxWidth: 720,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.bottomBarInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (lot.inspection.isNotEmpty) ...[
                            _Inspection(lot: lot),
                            const SizedBox(height: 28),
                          ],
                          _IfYouWin(lot: lot),
                          if (lot.deposit != null) ...[
                            const SizedBox(height: 28),
                            _Participation(lot: lot),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: AppSpacing.md,
              top: MediaQuery.paddingOf(context).top + AppSpacing.md,
              child: GlassIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: context.l10n.back,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(Routes.auctions),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              child: MaxWidthBox(maxWidth: 560, child: _BottomBar(lot: lot)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.lot});

  final LotDetail lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final following =
        ref.watch(lotFollowProvider(lot.id)).value ?? lot.following;
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: colors.onDarkMuted,
    );

    Future<void> setMaxBid() async {
      final amount = await showMaxBidSheet(
        context,
        minimum: lot.startPrice,
        limit: lot.bidLimit,
        suggested: lot.estimateLow ?? lot.startPrice,
      );
      if (amount == null || !context.mounted) return;
      final ok = await ref
          .read(bidControllerProvider(lot.id).notifier)
          .setProxy(amount);
      if (!context.mounted) return;
      final error = ref.read(bidControllerProvider(lot.id)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? l10n.maxBidOn(formatVnd(amount))
                : errorMessage(context, error!),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.lotHeader,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: MaxWidthBox(
          maxWidth: 560,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
            child: Column(
              children: [
                SizedBox(
                  width: 172,
                  child: BookCover(imageUrl: lot.book.imageUrl, elevated: true),
                ),
                const SizedBox(height: 18),
                if (lot.lotNumber != null && lot.lotCount != null)
                  Text(
                    [
                      l10n.lotOfCount(lot.lotNumber!, lot.lotCount!),
                      ?lot.sessionTitle,
                    ].join(' · ').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: colors.onDarkMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  lot.book.title,
                  textAlign: TextAlign.center,
                  style: context.textStyles.headlineMedium?.copyWith(
                    color: colors.onDark,
                  ),
                ),
                Text(
                  lot.book.author,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: colors.onDark.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (lot.edition != null)
                  Text(lot.edition!, textAlign: TextAlign.center, style: muted),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: setMaxBid,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.onDark,
                          foregroundColor: context.colors.onSurface,
                        ),
                        child: Text(l10n.setMaxBid),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassSurface(
                        onDark: true,
                        child: TextButton.icon(
                          onPressed: () => ref
                              .read(lotFollowProvider(lot.id).notifier)
                              .toggle(),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.onDark,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          icon: Icon(
                            following
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                          label: Text(following ? l10n.following : l10n.follow),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.lot});

  final LotDetail lot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = [
      if (lot.estimateLow != null && lot.estimateHigh != null)
        (
          l10n.statEstimate,
          formatMillionsRange(lot.estimateLow!, lot.estimateHigh!),
          l10n.millionDong,
        ),
      (l10n.statStartPrice, formatMillions(lot.startPrice), l10n.millionDong),
      (l10n.statCondition, conditionLabel(context, lot.book.condition), ''),
      (l10n.statOpens, formatDayMonth(lot.opensAt), formatTime(lot.opensAt)),
      (l10n.statIncrement, formatVnd(lot.minIncrement), ''),
    ];
    return Container(
      height: 92,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.appColors.separator, width: 0.5),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: stats.length,
        separatorBuilder: (_, _) =>
            VerticalDivider(color: context.appColors.separator),
        itemBuilder: (context, i) {
          final (label, value, unit) = stats[i];
          return SizedBox(
            width: 112,
            child: Column(
              children: [
                Text(
                  label.toUpperCase(),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.appColors.labelTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleLarge?.copyWith(
                    fontSize: 19,
                    color: context.appColors.labelSecondary,
                  ),
                ),
                Text(
                  unit,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.appColors.labelTertiary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Inspection extends StatelessWidget {
  const _Inspection({required this.lot});

  final LotDetail lot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final inspectedBy = [
      ?lot.inspector,
      if (lot.inspectedAt != null) formatDate(lot.inspectedAt!),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.inspectionReport, style: context.textStyles.titleLarge),
        const SizedBox(height: 10),
        GroupedSection(
          background: colors.groupedBackground,
          footer: l10n.reserveHiddenNote,
          children: [
            GroupedRow(
              minHeight: 64,
              leading: Icon(
                Icons.verified_user_rounded,
                size: 32,
                color: colors.success,
              ),
              title: l10n.inspectedAtWarehouse,
              subtitle: inspectedBy.isEmpty ? null : inspectedBy,
            ),
            if (lot.conditionReport != null)
              GroupedRow(
                leading: Icon(
                  Icons.description_outlined,
                  size: 22,
                  color: colors.labelTertiary,
                ),
                title: lot.conditionReport!,
              ),
            for (final item in lot.inspection)
              GroupedRow(
                leading: Icon(
                  item.ok ? Icons.check_circle_rounded : Icons.error_rounded,
                  size: 22,
                  color: item.ok ? colors.success : colors.caution,
                ),
                title: _inspectionLabel(context, item),
              ),
          ],
        ),
      ],
    );
  }
}

String _inspectionLabel(BuildContext context, InspectionItem item) {
  final l10n = context.l10n;
  return switch (item.check) {
    InspectionCheck.fullPages =>
      item.ok ? l10n.inspFullPagesOk : l10n.inspFullPagesBad,
    InspectionCheck.edition =>
      item.ok ? l10n.inspEditionOk : l10n.inspEditionBad,
    InspectionCheck.mold => item.ok ? l10n.inspMoldOk : l10n.inspMoldBad,
    InspectionCheck.notes => item.ok ? l10n.inspNotesOk : l10n.inspNotesBad,
    InspectionCheck.signature => l10n.inspSignature(item.note ?? '—'),
  };
}

class _IfYouWin extends StatelessWidget {
  const _IfYouWin({required this.lot});

  final LotDetail lot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hammer = lot.estimateLow ?? lot.startPrice;
    final premium = lot.totalIfWon(hammer) - hammer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ifYouWinAt(formatVnd(hammer)),
          style: context.textStyles.titleLarge,
        ),
        const SizedBox(height: 10),
        GroupedSection(
          background: context.appColors.groupedBackground,
          footer: l10n.payWithin48h,
          children: [
            GroupedRow(
              title: l10n.hammerPrice,
              trailingText: formatVnd(hammer),
            ),
            GroupedRow(
              title: l10n.buyerPremium(lot.buyerPremiumPercent),
              trailingText: formatVnd(premium),
            ),
            GroupedRow(
              title: l10n.shipFromWarehouse,
              trailingText: l10n.shipFeeRange,
            ),
            GroupedRow(
              title: l10n.totalPayment,
              trailingText: l10n.approx(formatVnd(lot.totalIfWon(hammer))),
              emphasized: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Participation extends StatelessWidget {
  const _Participation({required this.lot});

  final LotDetail lot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.joinSession, style: context.textStyles.titleLarge),
        const SizedBox(height: 10),
        GroupedSection(
          background: context.appColors.groupedBackground,
          footer: l10n.participationNote(lot.softCloseSeconds ?? 15),
          children: [
            GroupedRow(
              title: l10n.deposit,
              trailingText: formatVnd(lot.deposit!),
            ),
            if (lot.bidLimit != null)
              GroupedRow(
                title: l10n.bidLimit,
                trailingText: formatVnd(lot.bidLimit!),
              ),
            if (lot.lotDurationSeconds != null)
              GroupedRow(
                title: l10n.timePerLot,
                trailingText: l10n.seconds(lot.lotDurationSeconds!),
              ),
          ],
        ),
      ],
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.lot});

  final LotDetail lot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final registering = ref.watch(lotRegistrationProvider(lot.id)).isLoading;
    final left = lot.opensAt.difference(now);
    final live = lot.isLive || left <= Duration.zero;

    Future<void> register() async {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.registerConfirmTitle),
          content: Text(
            l10n.registerConfirmBody(
              lot.deposit == null ? '—' : formatVnd(lot.deposit!),
              lot.bidLimit == null ? '—' : formatVnd(lot.bidLimit!),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.agreeAndRegister),
            ),
          ],
        ),
      );
      if (agreed != true || !context.mounted) return;
      final ok = await ref
          .read(lotRegistrationProvider(lot.id).notifier)
          .register();
      if (!context.mounted) return;
      final error = ref.read(lotRegistrationProvider(lot.id)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.registeredSuccess : errorMessage(context, error!),
          ),
        ),
      );
    }

    final String caption;
    final String value;
    if (live) {
      caption = l10n.auctionLive;
      value = lot.book.title;
    } else {
      caption = l10n.sessionStartsIn;
      value = l10n.daysAndClock(
        left.inDays,
        formatCountdown(left - Duration(days: left.inDays)),
      );
    }

    final Widget action;
    if (live) {
      action = FilledButton(
        onPressed: () => context.push(Routes.auctionRoom(lot.id)),
        child: Text(l10n.enterAuctionRoom),
      );
    } else if (lot.registered) {
      action = FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_rounded),
        label: Text(l10n.registered),
      );
    } else {
      action = FilledButton(
        onPressed: registering ? null : register,
        child: Text(
          lot.deposit == null
              ? l10n.register
              : l10n.registerWithDeposit(formatMillionsShort(lot.deposit!)),
        ),
      );
    }

    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.labelSecondary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }
}
