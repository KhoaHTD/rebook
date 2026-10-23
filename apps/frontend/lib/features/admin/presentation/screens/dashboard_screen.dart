import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/admin_kit.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Dashboard: số liệu tổng quan, việc cần xử lý và phiên đang chạy (SRS 8).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(dashboardProvider);
    return AppPage(
      title: l10n.navDashboard,
      showBack: false,
      onRefresh: () => ref.refresh(dashboardProvider.future),
      children: [
        AsyncValueView(
          value: d,
          onRetry: () => ref.invalidate(dashboardProvider),
          data: (d) => _Body(d: d),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.d});

  final Dashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final disputes = ref.watch(adminDisputesProvider).value?.length ?? 0;
    final withdrawals = ref
        .watch(adminWithdrawalsProvider)
        .value
        ?.where((w) => w.status == WithdrawalStatus.pending)
        .toList();
    final withdrawalSum =
        withdrawals?.fold<int>(0, (a, w) => a + w.amount) ?? 0;

    Widget todo(
      int count,
      String label,
      String path, {
      String? note,
      bool primary = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: count == 0 ? AdminPalette.faint : AdminPalette.ink,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: AdminPalette.muted,
                    ),
                  ),
              ],
            ),
          ),
          primary && count > 0
              ? FilledButton(
                  onPressed: () => context.go(path),
                  child: Text(l10n.adminReviewNow),
                )
              : OutlinedButton(
                  onPressed: () => context.go(path),
                  child: Text(l10n.adminView),
                ),
        ],
      ),
    );

    final todoCard = AdminCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminTodoTitle,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          todo(
            d.pendingListings,
            l10n.adminTodoListings,
            AdminRoutes.listings,
            primary: true,
          ),
          const Divider(height: 1, color: AdminPalette.lineSoft),
          todo(
            d.pendingConsignments,
            l10n.adminTodoConsign,
            AdminRoutes.consignments,
          ),
          const Divider(height: 1, color: AdminPalette.lineSoft),
          todo(disputes, l10n.adminTodoDisputes, AdminRoutes.disputes),
          const Divider(height: 1, color: AdminPalette.lineSoft),
          todo(
            withdrawals?.length ?? 0,
            l10n.adminTodoWithdrawals,
            AdminRoutes.withdrawals,
            note: withdrawalSum > 0 ? formatVnd(withdrawalSum) : null,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 1000
                ? 5
                : (box.maxWidth >= 640 ? 3 : 2);
            final w = (box.maxWidth - AppSpacing.md * (cols - 1)) / cols;
            Widget k(String label, String value, {String? note}) => SizedBox(
              width: w,
              child: AdminKpi(label: label, value: value, note: note),
            );
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                k(l10n.revenue, formatVnd(d.revenueTotal)),
                k(l10n.platformFees, formatVnd(d.platformFees)),
                k(l10n.orderCount, '${d.orderCount}'),
                k(l10n.lotSoldRate, '${(d.lotSoldRate * 100).round()}%'),
                k(l10n.activeUsers, '${d.activeUsers}'),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, box) {
            const live = _LiveCard();
            if (box.maxWidth < 860) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  todoCard,
                  const SizedBox(height: AppSpacing.md),
                  live,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: todoCard),
                const SizedBox(width: AppSpacing.md),
                const Expanded(flex: 2, child: _LiveCard()),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Thẻ đen: phiên đang chạy (lô hiện tại, giá, số người xem) hoặc báo chưa có phiên.
class _LiveCard extends ConsumerWidget {
  const _LiveCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sessions = ref.watch(adminSessionsProvider).value ?? const [];
    final live = sessions.where((s) => s.isLive).toList();
    final session = live.isEmpty ? null : live.first;
    final state = session == null
        ? null
        : ref.watch(monitorStateProvider(session.id)).value;
    final lot = state?.currentLot;
    const onDark = AdminPalette.card;
    final dim = AdminPalette.card.withValues(alpha: 0.7);

    return AdminCard(
      dark: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: session == null
                      ? AdminPalette.card.withValues(alpha: 0.15)
                      : AdminPalette.bad,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '● ${l10n.adminLiveSession}',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: onDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (session == null)
            Text(
              l10n.adminNoLive,
              style: context.textStyles.bodyMedium?.copyWith(color: dim),
            )
          else ...[
            Text(
              session.title,
              style: context.textStyles.titleLarge?.copyWith(
                color: onDark,
                fontFamily: AppFonts.serif,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (lot != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.lotNumber(lot.lotNumber)} · ${lot.book.title}',
                style: context.textStyles.bodyMedium?.copyWith(color: dim),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                formatVnd(lot.currentPrice),
                style: context.textStyles.headlineMedium?.copyWith(
                  color: onDark,
                  fontFamily: null,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                [
                  if (lot.leadingPaddle != null)
                    l10n.leadingPaddle(lot.leadingPaddle!),
                  l10n.viewers(state?.viewerCount ?? 0),
                ].join(' · '),
                style: context.textStyles.bodySmall?.copyWith(color: dim),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminPalette.card,
                foregroundColor: AdminPalette.ink,
              ),
              onPressed: () => context.go(AdminRoutes.monitor(session.id)),
              child: Text(l10n.adminOpenMonitor),
            ),
          ],
        ],
      ),
    );
  }
}
