import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/domain/admin_report.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';

/// Báo cáo dạng CSV (mở được bằng Excel): phần tóm tắt, thể loại, trạng thái rồi bảng theo ngày.
/// Có BOM đầu file để Excel đọc đúng tiếng Việt.
String reportCsv(AdminReport r, AppLocalizations l10n) {
  String cell(Object? v) {
    final s = '$v';
    return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  String row(List<Object?> cells) => cells.map(cell).join(',');
  final lines = <String>[
    row([l10n.admReportsTitle, l10n.appTitle]),
    row([l10n.admReportPeriod(formatDate(r.from), formatDate(r.to))]),
    '',
    row([l10n.admKpiGmv, r.gmv]),
    row([l10n.admRevenueDone, r.revenue]),
    row([l10n.admFees, r.platformFees]),
    row([l10n.admKpiOrders, r.orders]),
    row([l10n.admAuctionOrders, r.auctionOrders]),
    row([l10n.admKpiNewUsers, r.newUsers]),
    row([l10n.admAvgOrder, r.averageOrder]),
    row([l10n.admCancelRate, '${(r.cancelRate * 100).toStringAsFixed(1)}%']),
    '',
    row([l10n.admReportByCategory, l10n.admSeriesRevenue]),
    for (final c in r.categories) row([c.name, c.amount]),
    '',
    row([l10n.admReportByStatus, l10n.admKpiOrders]),
    for (final s in r.statuses) row([s.status.label(l10n), s.count]),
    '',
    row([
      l10n.admColDate,
      l10n.admSeriesRevenue,
      l10n.admSeriesOrders,
      l10n.admSeriesUsers,
    ]),
    for (final d in r.days)
      row([formatDate(d.date), d.gmv, d.orders, d.newUsers]),
    row([l10n.admTotal, r.gmv, r.orders, r.newUsers]),
  ];
  return '﻿${lines.join('\r\n')}\r\n';
}

/// Tên file: `rebook-bao-cao-2026-10-08_2026-11-06.csv`.
String reportFileName(AdminReport r, String ext) {
  String d(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  return 'rebook-report-${d(r.from)}_${d(r.to)}.$ext';
}
