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
import 'package:book_marketplace/shared/widgets/cover_flow_home.dart';
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

/// Điện thoại: "Sàn" dùng [CoverFlowHome] (nền màu theo bìa lô, hàng bìa lớn, tab Đang LIVE / Sắp diễn ra /
/// Của tôi, các kệ phiên và lô). Desktop giữ bố cục thẻ ở trên.
class _MobileFloor extends ConsumerStatefulWidget {
  const _MobileFloor();

  @override
  ConsumerState<_MobileFloor> createState() => _MobileFloorState();
}

class _MobileFloorState extends ConsumerState<_MobileFloor> {
  int _tab = 0;

  CoverFlowEntry _lot(BuildContext context, Lot l) => CoverFlowEntry(
    id: l.id,
    title: l.book.title,
    author: l.book.author,
    coverUrl: l.book.coverUrl,
    price: formatVnd(l.currentPrice),
    onTap: () => context.go(Routes.lot(l.id)),
  );

  CoverFlowEntry _session(BuildContext context, AuctionSession s) =>
      CoverFlowEntry(
        id: s.id,
        title: s.title,
        author: s.description ?? '',
        coverUrl: s.coverImageUrl,
        onTap: () => context.go(Routes.session(s.id)),
      );

  CoverFlowShelf? _shelf(String label, List<CoverFlowEntry> entries) =>
      entries.isEmpty ? null : CoverFlowShelf(label, entries);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessions = ref.watch(auctionSessionsProvider);
    final featured = ref.watch(featuredLotsProvider).value ?? const <Lot>[];
    final active = ref.watch(activeLotsProvider).value ?? const <Lot>[];
    final watched = ref.watch(watchedLotsProvider).value ?? const <Lot>[];

    return sessions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(auctionSessionsProvider),
          child: Text(l10n.retry),
        ),
      ),
      data: (all) {
        final live = all
            .where((s) => SessionTab.live.matches(s.status))
            .toList();
        final upcoming =
            all.where((s) => SessionTab.upcoming.matches(s.status)).toList()
              ..sort((a, b) => a.startAt.compareTo(b.startAt));
        final tab = _tab.clamp(0, 2);
        final shelves = <CoverFlowShelf>[
          ...switch (tab) {
            0 => [
              ?_shelf(l10n.floorShelfLive, [
                for (final s in live) _session(context, s),
              ]),
              ?_shelf(l10n.floorShelfLots, [
                for (final l in featured) _lot(context, l),
              ]),
            ],
            1 => [
              ?_shelf(l10n.floorShelfUpcoming, [
                for (final s in upcoming) _session(context, s),
              ]),
              ?_shelf(l10n.floorShelfLots, [
                for (final l in active) _lot(context, l),
              ]),
            ],
            _ => [
              ?_shelf(l10n.floorShelfWatched, [
                for (final l in watched) _lot(context, l),
              ]),
            ],
          },
        ];
        final heroLots = featured.isNotEmpty ? featured : active;
        return CoverFlowHome(
          title: l10n.auctionAppTitle,
          trailing: (onHero) =>
              ModeButton(mode: AppMode.auction, onHero: onHero),
          hero: [for (final l in heroLots.take(5)) _lot(context, l)],
          tabs: [l10n.tabLive, l10n.tabUpcoming, l10n.auctionNavMine],
          tabIndex: tab,
          onTab: (i) => setState(() => _tab = i),
          shelves: shelves,
          emptyText: l10n.floorShelfEmpty,
        );
      },
    );
  }
}
