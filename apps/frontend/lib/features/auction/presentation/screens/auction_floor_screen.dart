import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/mode_switch.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_floor_providers.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/providers/session_watch_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_home_widgets.dart';
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

/// Điện thoại: ô tìm, hàng banner phiên (ghi tên phiên), kệ sách tự trôi từ trái sang phải, tab
/// Khám phá / Sắp diễn ra / Yêu thích / Của tôi; bên dưới là các phiên từ trên xuống, mỗi phiên là một kệ các lô chạy
/// từ trái sang phải.
/// Desktop giữ bố cục thẻ ở trên.
class _MobileFloor extends ConsumerStatefulWidget {
  const _MobileFloor();

  @override
  ConsumerState<_MobileFloor> createState() => _MobileFloorState();
}

class _MobileFloorState extends ConsumerState<_MobileFloor> {
  final _search = TextEditingController();
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final sessions = ref.watch(auctionSessionsProvider);
    final active = ref.watch(activeLotsProvider).value ?? const <Lot>[];
    final watched = ref.watch(watchedLotsProvider).value ?? const <Lot>[];
    final mine = ref.watch(myRegistrationsProvider).value ?? const [];

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
            final q = _search.text.trim().toLowerCase();
            final mineIds = {for (final r in mine) r.sessionId};
            final watchedIds = {
              for (final l in watched) l.sessionId,
              ...ref.watch(watchedSessionIdsProvider),
            };
            var shown = switch (_tab) {
              0 => [...live, ...upcoming],
              1 => live,
              2 => upcoming,
              3 => [
                ...live,
                ...upcoming,
              ].where((s) => watchedIds.contains(s.id)),
              _ => [...live, ...upcoming].where((s) => mineIds.contains(s.id)),
            }.toList();
            if (q.isNotEmpty) {
              // Khớp tên phiên hoặc tên sách / tác giả của một lô trong phiên.
              shown = [
                for (final s in shown)
                  if (s.title.toLowerCase().contains(q) ||
                      active.any(
                        (l) =>
                            l.sessionId == s.id &&
                            (l.book.title.toLowerCase().contains(q) ||
                                l.book.author.toLowerCase().contains(q)),
                      ))
                    s,
              ];
            }
            final tabs = [
              l10n.navExplore,
              l10n.tabLive,
              l10n.floorShelfUpcoming,
              l10n.floorTabFavorite,
              l10n.auctionNavMine,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _search,
                  maxLength: 100,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l10n.auctionSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 22),
                          child: InkResponse(
                            onTap: () => setState(() => _tab = i),
                            child: Text(
                              tabs[i],
                              style: text.titleMedium?.copyWith(
                                fontWeight: i == _tab
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: i == _tab
                                    ? context.colors.onSurface
                                    : c.secondaryText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      l10n.floorShelfEmpty,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: c.secondaryText),
                    ),
                  )
                else
                  for (final s in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: SessionShelfCard(session: s),
                    ),
                const SizedBox(height: 110),
              ],
            );
          },
        ),
      ],
    );
  }
}
