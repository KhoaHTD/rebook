import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/session_tile.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Lịch phiên đấu giá: đang diễn ra / sắp diễn ra / đã kết thúc (SRS 3 — người mua).
class AuctionsScreen extends ConsumerStatefulWidget {
  const AuctionsScreen({super.key});

  @override
  ConsumerState<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends ConsumerState<AuctionsScreen> {
  SessionTab? _tab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessions = ref.watch(auctionSessionsProvider);
    // Mặc định: có phiên đang chạy thì mở tab "Đang diễn ra", không thì "Sắp diễn ra".
    final tab =
        _tab ??
        ((sessions.value ?? const []).any(
              (s) => SessionTab.live.matches(s.status),
            )
            ? SessionTab.live
            : SessionTab.upcoming);
    String label(SessionTab t) => switch (t) {
      SessionTab.live => l10n.tabLive,
      SessionTab.upcoming => l10n.tabUpcoming,
      SessionTab.ended => l10n.tabEnded,
    };

    return AppPage(
      title: l10n.auctionsTitle,
      subtitle: l10n.auctionsTagline,
      onRefresh: () => ref.refresh(auctionSessionsProvider.future),
      actions: [
        HeaderAction(
          icon: Icons.timer_outlined,
          label: l10n.myAuctions,
          onPressed: () => context.go(Routes.myAuctions),
          primary: false,
        ),
      ],
      children: [
        Row(
          children: [
            for (final t in SessionTab.values)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(label(t)),
                  selected: tab == t,
                  onSelected: (_) => setState(() => _tab = t),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AsyncValueView(
          value: sessions,
          onRetry: () => ref.invalidate(auctionSessionsProvider),
          data: (all) {
            final list = all.where((s) => tab.matches(s.status)).toList();
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.gavel_rounded,
                title: l10n.noSessions,
              );
            }
            return PosterGrid(
              children: [
                for (final s in list)
                  SessionTile(
                    session: s,
                    onTap: () => context.go(Routes.session(s.id)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
