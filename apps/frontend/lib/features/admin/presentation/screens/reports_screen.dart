import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/file_download.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/domain/admin_report.dart';
import 'package:book_marketplace/features/admin/presentation/export/report_csv.dart';
import 'package:book_marketplace/features/admin/presentation/export/report_pdf.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:book_marketplace/shared/widgets/admin_charts.dart';
import 'package:book_marketplace/shared/widgets/admin_kit.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Báo cáo: chọn khoảng ngày, xem số liệu / biểu đồ / bảng theo ngày và xuất file.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _to;
  late DateTime _from;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 29));
  }

  int get _span => _to.difference(_from).inDays + 1;

  void _last(int days) {
    final now = DateTime.now();
    setState(() {
      _to = DateTime(now.year, now.month, now.day);
      _from = _to.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range == null) return;
    // Backend giới hạn 366 ngày.
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    var start = DateTime(range.start.year, range.start.month, range.start.day);
    if (end.difference(start).inDays > 365) {
      start = end.subtract(const Duration(days: 365));
    }
    setState(() {
      _from = start;
      _to = end;
    });
  }

  bool _exporting = false;

  Future<void> _exportPdf(AdminReport r) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final name = reportFileName(r, 'pdf');
    setState(() => _exporting = true);
    try {
      await shareReportPdf(await buildReportPdf(r, l10n), name);
      messenger.showSnackBar(SnackBar(content: Text(l10n.admExportDone(name))));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.admExportFailed)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv(AdminReport r) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final name = reportFileName(r, 'csv');
    final ok = await downloadTextFile(name, reportCsv(r, l10n));
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.admExportDone(name) : l10n.admExportFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final report = ref.watch(adminReportProvider(_from, _to));
    final r = report.value;
    return AppPage(
      title: l10n.admReportsTitle,
      subtitle: l10n.admReportsSub,
      showBack: false,
      onRefresh: () => ref.refresh(adminReportProvider(_from, _to).future),
      actions: [
        FilledButton.icon(
          onPressed: r == null || _exporting ? null : () => _exportPdf(r),
          icon: _exporting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(l10n.admExportPdf),
        ),
        if (canDownloadFiles)
          OutlinedButton.icon(
            onPressed: r == null ? null : () => _exportCsv(r),
            icon: const Icon(Icons.table_view_outlined, size: 18),
            label: Text(l10n.admExportCsv),
          ),
      ],
      children: [
        _RangeBar(
          from: _from,
          to: _to,
          span: _span,
          onLast: _last,
          onPick: _pick,
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncValueView(
          value: report,
          onRetry: () => ref.invalidate(adminReportProvider(_from, _to)),
          data: (r) => _ReportBody(r: r),
        ),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.from,
    required this.to,
    required this.span,
    required this.onLast,
    required this.onPick,
  });

  final DateTime from;
  final DateTime to;
  final int span;
  final ValueChanged<int> onLast;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget chip(int v, String label) {
      final on = span == v;
      return ChoiceChip(
        label: Text(label),
        selected: on,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: on ? AdminPalette.accent : AdminPalette.ink,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: AdminPalette.accentSoft,
        backgroundColor: AdminPalette.card,
        side: BorderSide.none,
        onSelected: (_) => onLast(v),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip(7, l10n.admRange7),
        chip(30, l10n.admRange30),
        chip(90, l10n.admRange90),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.date_range_outlined, size: 18),
          label: Text('${formatDate(from)} – ${formatDate(to)}'),
        ),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.r});

  final AdminReport r;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    if (r.orders == 0 && r.newUsers == 0) {
      return AdminCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Text(
              l10n.admNoReportData,
              style: text.bodyMedium?.copyWith(color: AdminPalette.muted),
            ),
          ),
        ),
      );
    }
    String shortDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    Widget panel(String title, Widget child) => AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );

    final kpis = LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1000 ? 6 : (box.maxWidth >= 640 ? 3 : 2);
        final w = (box.maxWidth - AppSpacing.md * (cols - 1)) / cols;
        Widget k(AdminKpi child) => SizedBox(width: w, child: child);
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            k(
              AdminKpi(
                icon: Icons.payments_outlined,
                label: l10n.admKpiGmv,
                value: formatVnd(r.gmv),
                trend: r.trendOf((x) => x.gmv),
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.verified_outlined,
                label: l10n.admRevenueDone,
                value: formatVnd(r.revenue),
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.admFees,
                value: formatVnd(r.platformFees),
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.receipt_long_outlined,
                label: l10n.admKpiOrders,
                value: '${r.orders}',
                trend: r.trendOf((x) => x.orders),
                note: '${l10n.admAuctionOrders}: ${r.auctionOrders}',
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.shopping_basket_outlined,
                label: l10n.admAvgOrder,
                value: formatVnd(r.averageOrder),
              ),
            ),
            k(
              AdminKpi(
                icon: Icons.person_add_alt_outlined,
                label: l10n.admKpiNewUsers,
                value: '${r.newUsers}',
                trend: r.trendOf((x) => x.newUsers),
                note:
                    '${l10n.admCancelRate}: ${(r.cancelRate * 100).toStringAsFixed(1)}%',
              ),
            ),
          ],
        );
      },
    );

    final categories = panel(
      l10n.admReportByCategory,
      r.categories.isEmpty
          ? Text(
              l10n.admNoReportData,
              style: text.bodySmall?.copyWith(color: AdminPalette.muted),
            )
          : DonutChart(
              slices: [
                for (final (i, c) in r.categories.indexed)
                  (
                    c.name,
                    c.amount.toDouble(),
                    AdminPalette.chart[i % AdminPalette.chart.length],
                  ),
              ],
              valueFormat: (v) => formatVndCompact(v),
            ),
    );
    final statuses = panel(
      l10n.admReportByStatus,
      DonutChart(
        slices: [
          for (final (i, s) in r.statuses.indexed)
            (
              s.status.label(l10n),
              s.count.toDouble(),
              AdminPalette.chart[(i + 2) % AdminPalette.chart.length],
            ),
        ],
        valueFormat: (v) => '${v.round()}',
        center: Text(
          '${r.orders}',
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
    final users = panel(
      l10n.admReportUsersDay,
      ColumnChart(
        labels: [for (final d in r.days) shortDate(d.date)],
        values: [for (final d in r.days) d.newUsers.toDouble()],
        color: AdminPalette.chart[2],
        valueFormat: (v) => '${v.round()}',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kpis,
        const SizedBox(height: AppSpacing.md),
        panel(
          l10n.admReportRevenueDay,
          SalesTrendChart(report: r, height: 280),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  categories,
                  const SizedBox(height: AppSpacing.md),
                  statuses,
                  const SizedBox(height: AppSpacing.md),
                  users,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: categories),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: statuses),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                users,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        panel(l10n.admReportDaily, _DailyTable(r: r)),
      ],
    );
  }
}

/// Bảng chi tiết theo ngày, dòng cuối là tổng.
class _DailyTable extends StatelessWidget {
  const _DailyTable({required this.r});

  final AdminReport r;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    TableRow row(List<String> cells, {bool head = false, bool total = false}) =>
        TableRow(
          decoration: BoxDecoration(
            color: head || total ? AdminPalette.bg : null,
            border: const Border(
              bottom: BorderSide(color: AdminPalette.lineSoft),
            ),
          ),
          children: [
            for (final (i, c) in cells.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 10,
                ),
                child: Text(
                  c,
                  textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                  style: (head ? text.labelMedium : text.bodySmall)?.copyWith(
                    fontWeight: head || total ? FontWeight.w700 : null,
                    color: head ? AdminPalette.muted : null,
                  ),
                ),
              ),
          ],
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 480),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            row([
              l10n.admColDate,
              l10n.admSeriesRevenue,
              l10n.admSeriesOrders,
              l10n.admSeriesUsers,
            ], head: true),
            for (final d in r.days.reversed)
              row([
                formatDate(d.date),
                formatVnd(d.gmv),
                '${d.orders}',
                '${d.newUsers}',
              ]),
            row([
              l10n.admTotal,
              formatVnd(r.gmv),
              '${r.orders}',
              '${r.newUsers}',
            ], total: true),
          ],
        ),
      ),
    );
  }
}
