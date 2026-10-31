import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auction_stage_widgets.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Lịch đấu giá: mọi phiên đang diễn ra và sắp diễn ra, gom theo ngày, đăng ký ngay từ lịch.
class AuctionScheduleScreen extends ConsumerStatefulWidget {
  const AuctionScheduleScreen({super.key});

  @override
  ConsumerState<AuctionScheduleScreen> createState() =>
      _AuctionScheduleScreenState();
}

class _AuctionScheduleScreenState extends ConsumerState<AuctionScheduleScreen> {
  bool _openOnly = false;

  String _dayLabel(BuildContext context, DateTime day) {
    final l10n = context.l10n;
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = DateUtils.dateOnly(day.toLocal()).difference(today).inDays;
    if (diff == 0) return l10n.scheduleToday;
    if (diff == 1) return l10n.scheduleTomorrow;
    return formatDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessions = ref.watch(auctionSessionsProvider);

    return AppPage(
      title: l10n.scheduleTitle,
      subtitle: l10n.scheduleSub,
      onRefresh: () => ref.refresh(auctionSessionsProvider.future),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: Text(l10n.scheduleRegOpen),
            selected: _openOnly,
            onSelected: (v) => setState(() => _openOnly = v),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: sessions,
          onRetry: () => ref.invalidate(auctionSessionsProvider),
          data: (all) {
            final list =
                all
                    .where(
                      (s) =>
                          SessionTab.live.matches(s.status) ||
                          SessionTab.upcoming.matches(s.status),
                    )
                    .where((s) => !_openOnly || s.acceptsRegistration)
                    .toList()
                  ..sort((a, b) => a.startAt.compareTo(b.startAt));
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.event_busy_outlined,
                title: l10n.scheduleEmpty,
              );
            }
            // Gom theo ngày (giờ địa phương).
            final byDay = <DateTime, List<AuctionSession>>{};
            for (final s in list) {
              byDay
                  .putIfAbsent(
                    DateUtils.dateOnly(s.startAt.toLocal()),
                    () => [],
                  )
                  .add(s);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in byDay.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      _dayLabel(context, entry.key),
                      style: context.textStyles.titleMedium?.copyWith(
                        color: context.appColors.tint,
                      ),
                    ),
                  ),
                  for (final s in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: EventCard(
                          session: s,
                          onTap: () => context.go(Routes.session(s.id)),
                          trailing: s.isLive
                              ? FilledButton(
                                  onPressed: () =>
                                      context.go(Routes.live(s.id)),
                                  child: Text(l10n.enterLiveRoom),
                                )
                              : s.acceptsRegistration
                              ? FilledButton(
                                  onPressed: () =>
                                      context.go(Routes.sessionRegister(s.id)),
                                  child: Text(l10n.register),
                                )
                              : null,
                        ),
                      ),
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
