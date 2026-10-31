import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_stage_widgets.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Kết quả & lịch sử: các phiên đã kết thúc (mới nhất trước), bấm vào xem bảng kết quả từng lô.
class AuctionHistoryScreen extends ConsumerWidget {
  const AuctionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sessions = ref.watch(auctionSessionsProvider);

    return AppPage(
      title: l10n.historyTitle,
      subtitle: l10n.historySub,
      onRefresh: () => ref.refresh(auctionSessionsProvider.future),
      children: [
        AsyncValueView(
          value: sessions,
          onRetry: () => ref.invalidate(auctionSessionsProvider),
          data: (all) {
            final ended =
                all.where((s) => SessionTab.ended.matches(s.status)).toList()
                  ..sort((a, b) => b.startAt.compareTo(a.startAt));
            if (ended.isEmpty) {
              return EmptyState(
                icon: Icons.emoji_events_outlined,
                title: l10n.historyEmpty,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in ended)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: EventCard(
                        session: s,
                        onTap: () => context.go(Routes.results(s.id)),
                        trailing: TextButton(
                          onPressed: () => context.go(Routes.results(s.id)),
                          child: Text(l10n.historyViewResults),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Glass(
                  blur: false,
                  shadow: false,
                  onTap: () => context.go(Routes.orders),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: context.appColors.tint,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.historyWonHint,
                          style: context.textStyles.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.appColors.tertiaryText,
                      ),
                    ],
                  ),
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
