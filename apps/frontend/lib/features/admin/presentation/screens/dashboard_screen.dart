import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/domain/admin_report.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/admin_charts.dart';
import 'package:book_marketplace/shared/widgets/admin_scope.dart';
import 'package:book_marketplace/shared/widgets/admin_kit.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/skeleton.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Dashboard: lời chào, số liệu kỳ gần nhất, biểu đồ hiệu suất, việc cần xử lý, phiên đang chạy và hoạt động (SRS 8).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = ref.watch(dashboardProvider);
    final name = ref.watch(sessionControllerProvider).user?.fullName ?? '';
    final first = name.trim().isEmpty ? '' : name.trim().split(' ').last;
    final today = DateTime.now();
    final to = DateTime(today.year, today.month, today.day);
    final from = to.subtract(Duration(days: _days - 1));
    return AppPage(
      title: l10n.admHello(first),
      subtitle: l10n.admDashSub,
      showBack: false,
      actions: [
        _DateChip(formatDate(today)),
        FilledButton.icon(
          onPressed: () => context.go(AdminRoutes.reports),
          icon: const Icon(Icons.bar_chart_rounded, size: 18),
          label: Text(l10n.admNavReports),
        ),
      ],
      onRefresh: () async {
        ref
          ..invalidate(adminReportProvider)
          ..invalidate(dashboardProvider);
        await ref.read(dashboardProvider.future);
      },
      children: [
        AsyncValueView(
          value: d,
          onRetry: () => ref.invalidate(dashboardProvider),
          data: (d) => _Body(
            d: d,
            from: from,
            to: to,
            days: _days,
            onDays: (v) => setState(() => _days = v),
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    if (AdminScope.menuOf(context) != null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminPalette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textStyles.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: AdminPalette.muted,
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.d,
    required this.from,
    required this.to,
    required this.days,
    required this.onDays,
  });

  final Dashboard d;
  final DateTime from;
  final DateTime to;
  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(adminReportProvider(from, to));
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiRow(d: d, report: report.value),
        const SizedBox(height: AppSpacing.md),
        _PerformanceCard(
          report: report,
          days: days,
          onDays: onDays,
          onRetry: () => ref.invalidate(adminReportProvider(from, to)),
        ),
        const SizedBox(height: AppSpacing.md),
        _TodoCard(d: d),
      ],
    );
    const side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(),
        SizedBox(height: AppSpacing.md),
        _LiveCard(),
        SizedBox(height: AppSpacing.md),
        _ActivityCard(),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 1100) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              const SizedBox(height: AppSpacing.md),
              side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: main),
            const SizedBox(width: AppSpacing.md),
            const SizedBox(width: 330, child: side),
          ],
        );
      },
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.d, required this.report});

  final Dashboard d;
  final AdminReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = report;
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 720 ? 4 : 2;
        final w = (box.maxWidth - AppSpacing.md * (cols - 1)) / cols;
        Widget k(Widget child) => SizedBox(width: w, child: child);
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            k(
              AdminKpi(
                icon: Icons.payments_outlined,
                label: l10n.admKpiGmv,
                value: r == null ? '…' : formatVnd(r.gmv),
                trend: r?.trendOf((x) => x.gmv),
                note: r?.trendOf((x) => x.gmv) == null
                    ? null
                    : l10n.admVsFirstHalf,
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.receipt_long_outlined,
                label: l10n.admKpiOrders,
                value: r == null ? '…' : '${r.orders}',
                trend: r?.trendOf((x) => x.orders),
                note: r?.trendOf((x) => x.orders) == null
                    ? null
                    : l10n.admVsFirstHalf,
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.person_add_alt_outlined,
                label: l10n.admKpiNewUsers,
                value: r == null ? '…' : '${r.newUsers}',
                trend: r?.trendOf((x) => x.newUsers),
                note: r?.trendOf((x) => x.newUsers) == null
                    ? null
                    : l10n.admVsFirstHalf,
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.gavel_rounded,
                label: l10n.lotSoldRate,
                value: '${(d.lotSoldRate * 100).round()}%',
                note: '${l10n.activeUsers}: ${d.activeUsers}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.report,
    required this.days,
    required this.onDays,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  final AsyncValue<AdminReport> report;
  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.sm,
            children: [
              Text(
                l10n.admPerformance,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              _RangeChips(days: days, onDays: onDays),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              _Legend(AdminPalette.chart[0], l10n.admSeriesRevenue),
              _Legend(AdminPalette.chart[1], l10n.admSeriesOrders),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AsyncValueView(
            value: report,
            onRetry: onRetry,
            loading: const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Skeleton(height: 220, radius: 16),
            ),
            data: (r) => r.orders == 0
                ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        l10n.admNoReportData,
                        style: text.bodyMedium?.copyWith(
                          color: AdminPalette.muted,
                        ),
                      ),
                    ),
                  )
                : SalesTrendChart(report: r),
          ),
        ],
      ),
    );
  }
}

/// Biểu đồ doanh thu (xanh, có vùng tô) và số đơn (cam) theo ngày, chú thích thêm người dùng mới.
class SalesTrendChart extends StatelessWidget {
  const SalesTrendChart({super.key, required this.report, this.height = 240});

  final AdminReport report;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = report.days;
    String shortDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return TrendChart(
      height: height,
      labels: [for (final d in days) shortDate(d.date)],
      series: [
        ChartSeries(l10n.admSeriesRevenue, AdminPalette.chart[0], [
          for (final d in days) d.gmv.toDouble(),
        ]),
        ChartSeries(l10n.admSeriesOrders, AdminPalette.chart[1], [
          for (final d in days) d.orders.toDouble(),
        ]),
      ],
      axisFormat: formatVndCompact,
      tooltipTitle: (i) => formatDate(days[i].date),
      tooltip: (i) => [
        (AdminPalette.chart[0], l10n.admSeriesRevenue, formatVnd(days[i].gmv)),
        (AdminPalette.chart[1], l10n.admSeriesOrders, '${days[i].orders}'),
        (AdminPalette.chart[2], l10n.admSeriesUsers, '${days[i].newUsers}'),
      ],
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.days, required this.onDays});

  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    Widget chip(int v, String label) {
      final on = v == days;
      return InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => onDays(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AdminPalette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: text.labelMedium?.copyWith(
              color: on ? AdminPalette.accent : AdminPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip(7, l10n.admRange7),
        chip(30, l10n.admRange30),
        chip(90, l10n.admRange90),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: context.textStyles.labelMedium?.copyWith(
          color: AdminPalette.muted,
        ),
      ),
    ],
  );
}

/// "Việc cần xử lý" dạng bảng: biểu tượng, tên việc, nhãn trạng thái, nút đi tới.
class _TodoCard extends ConsumerWidget {
  const _TodoCard({required this.d});

  final Dashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final disputes = ref.watch(adminDisputesProvider).value?.length ?? 0;
    final withdrawals = ref
        .watch(adminWithdrawalsProvider)
        .value
        ?.where((w) => w.status == WithdrawalStatus.pending)
        .toList();
    final withdrawalSum =
        withdrawals?.fold<int>(0, (a, w) => a + w.amount) ?? 0;

    Widget row(
      IconData icon,
      int count,
      String label,
      String path, {
      String? note,
      bool primary = false,
    }) {
      final pill = StatusPill(
        count == 0 ? l10n.admTodoDone : l10n.admTodoCount(count),
        tone: count == 0 ? StatusTone.success : StatusTone.warning,
      );
      final button = primary && count > 0
          ? FilledButton(
              onPressed: () => context.go(path),
              child: Text(l10n.adminReviewNow),
            )
          : OutlinedButton(
              onPressed: () => context.go(path),
              child: Text(l10n.adminView),
            );
      final lead = [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: count == 0 ? AdminPalette.bg : AdminPalette.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
            color: count == 0 ? AdminPalette.faint : AdminPalette.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (note != null)
                Text(
                  note,
                  style: text.bodySmall?.copyWith(color: AdminPalette.muted),
                ),
            ],
          ),
        ),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: lead),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [pill, const Spacer(), button]),
                ],
              );
            }
            return Row(
              children: [
                ...lead,
                pill,
                const SizedBox(width: AppSpacing.md),
                button,
              ],
            );
          },
        ),
      );
    }

    const divider = Divider(height: 1, color: AdminPalette.lineSoft);
    return AdminCard(
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
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          row(
            Icons.fact_check_outlined,
            d.pendingListings,
            l10n.adminTodoListings,
            AdminRoutes.listings,
            primary: true,
          ),
          divider,
          row(
            Icons.inventory_2_outlined,
            d.pendingConsignments,
            l10n.adminTodoConsign,
            AdminRoutes.consignments,
          ),
          divider,
          row(
            Icons.gpp_maybe_outlined,
            disputes,
            l10n.adminTodoDisputes,
            AdminRoutes.disputes,
          ),
          divider,
          row(
            Icons.account_balance_outlined,
            withdrawals?.length ?? 0,
            l10n.adminTodoWithdrawals,
            AdminRoutes.withdrawals,
            note: withdrawalSum > 0 ? formatVnd(withdrawalSum) : null,
          ),
        ],
      ),
    );
  }
}

/// Thẻ người đang đăng nhập (ảnh, tên, vai trò, email).
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final user = ref.watch(sessionControllerProvider).user;
    if (user == null) return const SizedBox.shrink();
    return AdminCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AdminPalette.accentSoft,
            child: Text(
              user.fullName.isEmpty
                  ? '?'
                  : user.fullName.characters.first.toUpperCase(),
              style: text.headlineSmall?.copyWith(
                color: AdminPalette.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.fullName,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            style: text.bodySmall?.copyWith(color: AdminPalette.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusPill(l10n.adminBadgeAdmin, tone: StatusTone.info),
        ],
      ),
    );
  }
}

/// Phiên đang chạy (lô hiện tại, giá, số người xem) hoặc báo chưa có phiên.
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
              style: context.textStyles.titleMedium?.copyWith(
                color: onDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (lot != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.lotNumber(lot.lotNumber)} · ${lot.book.title}',
                style: context.textStyles.bodySmall?.copyWith(color: dim),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                formatVnd(lot.currentPrice),
                style: context.textStyles.headlineSmall?.copyWith(
                  color: onDark,
                  fontFamily: null,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                [
                  if (lot.leadingPaddle != null)
                    l10n.leadingPaddle(lot.leadingPaddle!),
                  if ((state?.viewerCount ?? 0) > 0)
                    l10n.viewers(state!.viewerCount),
                ].join(' · '),
                style: context.textStyles.bodySmall?.copyWith(color: dim),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
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

/// Cột "Hoạt động gần đây": thao tác mới nhất của các Admin.
class _ActivityCard extends ConsumerWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final logs = ref.watch(adminActivityLogsProvider).value ?? const [];
    final items = logs.take(6).toList();
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.admRecentActivity,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AdminRoutes.activity),
                child: Text(l10n.admSeeAll),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.admNoActivity,
                style: text.bodySmall?.copyWith(color: AdminPalette.muted),
              ),
            ),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AdminPalette.accentSoft,
                    child: Text(
                      e.adminName.isEmpty
                          ? '?'
                          : e.adminName.characters.first.toUpperCase(),
                      style: text.labelMedium?.copyWith(
                        color: AdminPalette.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.adminName,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [e.action.label(l10n), ?e.target].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: AdminPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatShortDateTime(e.createdAt),
                    style: text.labelSmall?.copyWith(color: AdminPalette.faint),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
