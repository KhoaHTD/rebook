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
import 'package:book_marketplace/features/auction/presentation/widgets/auto_shelf.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Catalogue một phiên: thông tin phiên, nút đăng ký / vào phòng / kết quả, danh mục lô (SRS 6.3).
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(sessionCatalogueProvider(sessionId));
    return AppPage(
      title: data.value?.$1.title ?? l10n.auctionsTitle,
      showBack: true,
      onRefresh: () => ref.refresh(sessionCatalogueProvider(sessionId).future),
      children: [
        AsyncValueView(
          value: data,
          onRetry: () => ref.invalidate(sessionCatalogueProvider(sessionId)),
          data: (d) {
            final (session, lots) = d;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(session: session, lots: lots),
                const SizedBox(height: 56),
                SectionHeader(l10n.lotsInSession),
                const SizedBox(height: AppSpacing.lg),
                PosterGrid(
                  children: [
                    for (final lot in lots)
                      LotTile(
                        lot: lot,
                        onTap: () => context.go(Routes.lot(lot.id)),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.session, required this.lots});

  final AuctionSession session;
  final List<Lot> lots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final signedIn = ref.watch(sessionControllerProvider).isSignedIn;
    final reg = signedIn
        ? ref.watch(sessionRegistrationProvider(session.id)).value
        : null;
    final compact = context.windowSize.isCompact;

    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (session.isLive)
          FilledButton.icon(
            onPressed: () => context.go(Routes.live(session.id)),
            icon: const Icon(Icons.sensors_rounded, size: 18),
            label: Text(l10n.enterLiveRoom),
          ),
        if (reg != null)
          OutlinedButton(
            onPressed: null,
            child: Text(
              '${l10n.registered} · ${l10n.paddle(reg.paddleNumber)}',
            ),
          )
        else if (session.acceptsRegistration || session.isLive)
          (session.isLive ? OutlinedButton.new : FilledButton.new)(
            onPressed: () => context.go(Routes.sessionRegister(session.id)),
            child: Text(l10n.registerToBid),
          ),
        if (session.status == SessionStatus.ended)
          FilledButton(
            onPressed: () => context.go(Routes.results(session.id)),
            child: Text(l10n.resultsTitle),
          ),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SessionFacts(session: session),
        if (reg != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${l10n.deposited(formatVnd(reg.depositAmount))} · ${l10n.limitLeft(formatVnd(reg.remainingLimit))}',
            style: context.textStyles.bodySmall,
          ),
        ],
        if (session.description != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(session.description!, style: context.textStyles.bodyLarge),
        ],
        const SizedBox(height: AppSpacing.lg),
        actions,
      ],
    );

    // Cả phiên là một kệ: các lô của phiên chạy liên tục từ trái sang phải (không có cuốn đại diện).
    final shelf = AutoShelf(
      bookWidth: compact ? 92 : 120,
      height: compact ? 190 : 250,
      books: [
        for (final l in lots)
          ShelfBook(
            id: l.id,
            title: l.book.title,
            author: l.book.author,
            coverUrl: l.book.coverUrl,
            onTap: () => context.go(Routes.lot(l.id)),
          ),
      ],
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          shelf,
          const SizedBox(height: AppSpacing.xl),
          info,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: shelf),
        const SizedBox(width: 48),
        Expanded(flex: 4, child: info),
      ],
    );
  }
}
