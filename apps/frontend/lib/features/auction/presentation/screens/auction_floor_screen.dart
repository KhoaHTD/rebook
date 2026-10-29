import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/mode_switch.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_floor_providers.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_stage_widgets.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_widgets.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang chủ khu đấu giá ("Sàn"): phiên đang LIVE, sự kiện sắp diễn ra, lô nổi bật, tóm tắt của tôi.
/// Khu này có khung và bảng màu riêng (xem `auction_shell.dart`), không bán sách giá cố định.
class AuctionFloorScreen extends ConsumerWidget {
  const AuctionFloorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    if (compact) return const _MobileFloor();
    final sessions = ref.watch(auctionSessionsProvider);

    return AppPage(
      title: l10n.auctionAppTitle,
      subtitle: l10n.auctionsTagline,
      onRefresh: () => ref.refresh(auctionSessionsProvider.future),
      children: [
        AsyncValueView(
          value: sessions,
          onRetry: () => ref.invalidate(auctionSessionsProvider),
          data: (all) {
            final live = all
                .where((s) => SessionTab.live.matches(s.status))
                .toList();
            final upcoming =
                all.where((s) => SessionTab.upcoming.matches(s.status)).toList()
                  ..sort((a, b) => a.startAt.compareTo(b.startAt));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (live.isEmpty)
                  _NoLiveCard(next: upcoming.isEmpty ? null : upcoming.first)
                else
                  for (final s in live)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: LiveSpotlightCard(session: s),
                    ),
                const SizedBox(height: AppSpacing.xl),
                const _MySummary(),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Heading(l10n.tabUpcoming, l10n.floorUpcomingSub),
                  _EventGrid(sessions: upcoming.take(4).toList()),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.go(Routes.auctionSchedule),
                      child: Text(l10n.seeAll),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                const _FeaturedLots(),
                const SizedBox(height: 110),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.sub);

  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.headlineSmall),
        const SizedBox(height: 2),
        Text(sub, style: context.textStyles.bodySmall),
      ],
    ),
  );
}

/// Danh sách sự kiện: một cột trên điện thoại, hai cột trên màn rộng.
class _EventGrid extends StatelessWidget {
  const _EventGrid({required this.sessions});

  final List<AuctionSession> sessions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final two = box.maxWidth >= 760;
        final w = two ? (box.maxWidth - AppSpacing.md) / 2 : box.maxWidth;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final s in sessions)
              SizedBox(
                width: w,
                child: EventCard(
                  session: s,
                  onTap: () => context.go(Routes.session(s.id)),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Khi chưa có phiên LIVE: đếm ngược tới phiên kế tiếp.
class _NoLiveCard extends StatelessWidget {
  const _NoLiveCard({required this.next});

  final AuctionSession? next;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    return Glass(
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel_rounded, size: 32, color: c.tint),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.floorNoLive,
            style: text.headlineSmall?.copyWith(fontFamily: AppFonts.serif),
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(next!.title, style: text.bodyMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: c.live),
                const SizedBox(width: 6),
                CountdownText(
                  target: next!.startAt,
                  style: text.titleLarge?.copyWith(color: c.live),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.go(Routes.session(next!.id)),
              child: Text(l10n.register),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dải tóm tắt "Bạn đã đăng ký N phiên" (chỉ khi đã đăng nhập).
class _MySummary extends ConsumerWidget {
  const _MySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionControllerProvider).isSignedIn) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final regs = ref.watch(myRegistrationsProvider).value;
    if (regs == null) return const SizedBox.shrink();
    return Glass(
      blur: false,
      shadow: false,
      onTap: () => context.go(Routes.myAuctions),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            color: context.appColors.tint,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              regs.isEmpty
                  ? l10n.floorMySummaryNone
                  : l10n.floorMySummary(regs.length),
              style: context.textStyles.titleSmall,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.appColors.tertiaryText,
          ),
        ],
      ),
    );
  }
}

class _FeaturedLots extends ConsumerWidget {
  const _FeaturedLots();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final compact = context.windowSize.isCompact;
    final lots = ref.watch(featuredLotsProvider).value ?? const <Lot>[];
    if (lots.isEmpty) return const SizedBox.shrink();
    final tiles = [
      for (final l in lots)
        LotTile(lot: l, onTap: () => context.go(Routes.lot(l.id))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(l10n.floorFeaturedLots, l10n.floorFeaturedSub),
        if (compact)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  SizedBox(width: 160, child: tiles[i]),
                ],
              ],
            ),
          )
        else
          PosterGrid(children: tiles.take(8).toList()),
      ],
    );
  }
}

/// Điện thoại: "Sàn" kiểu sân khấu — thẻ LIVE cao chiếm gần cả màn hình, rồi dòng thời gian các phiên sắp tới
/// (gom theo ngày) và lưới 2 cột lô nổi bật. Khác hẳn trang chủ khu mua sách; desktop giữ bố cục thẻ ở trên.
class _MobileFloor extends ConsumerWidget {
  const _MobileFloor();

  String _dayLabel(BuildContext context, DateTime day) {
    final l10n = context.l10n;
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = DateUtils.dateOnly(day.toLocal()).difference(today).inDays;
    if (diff == 0) return l10n.scheduleToday;
    if (diff == 1) return l10n.scheduleTomorrow;
    return formatDate(day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sessions = ref.watch(auctionSessionsProvider);
    final lots = ref.watch(featuredLotsProvider).value ?? const <Lot>[];

    return AppPage(
      title: l10n.auctionAppTitle,
      onRefresh: () => ref.refresh(auctionSessionsProvider.future),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: ModeButton(mode: AppMode.auction),
        ),
      ],
      children: [
        AsyncValueView(
          value: sessions,
          onRetry: () => ref.invalidate(auctionSessionsProvider),
          data: (all) {
            final live = all
                .where((s) => SessionTab.live.matches(s.status))
                .toList();
            final upcoming =
                all.where((s) => SessionTab.upcoming.matches(s.status)).toList()
                  ..sort((a, b) => a.startAt.compareTo(b.startAt));
            final days = <DateTime, List<AuctionSession>>{};
            for (final s in upcoming) {
              days
                  .putIfAbsent(
                    DateUtils.dateOnly(s.startAt.toLocal()),
                    () => [],
                  )
                  .add(s);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (live.isEmpty)
                  _NoLiveCard(next: upcoming.isEmpty ? null : upcoming.first)
                else
                  for (final s in live)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: LiveStageCard(session: s),
                    ),
                const SizedBox(height: AppSpacing.xl),
                const _MySummary(),
                if (days.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Heading(l10n.tabUpcoming, l10n.floorUpcomingSub),
                  for (final entry in days.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        _dayLabel(context, entry.key).toUpperCase(),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: context.appColors.tint,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (final s in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: EventCard(
                          session: s,
                          onTap: () => context.go(Routes.session(s.id)),
                        ),
                      ),
                  ],
                ],
                if (lots.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Heading(l10n.floorFeaturedLots, l10n.floorFeaturedSub),
                  LayoutBuilder(
                    builder: (context, box) {
                      final w = (box.maxWidth - AppSpacing.md) / 2;
                      return Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.lg,
                        children: [
                          for (final l in lots.take(8))
                            SizedBox(
                              width: w,
                              child: LotTile(
                                lot: l,
                                onTap: () => context.go(Routes.lot(l.id)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 110),
              ],
            );
          },
        ),
      ],
    );
  }
}
