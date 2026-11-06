import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/domain/admin_report.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';

PdfColor _pdf(Color c) => PdfColor.fromInt(c.toARGB32());

/// Báo cáo dạng PDF: đầu trang, số liệu chính, biểu đồ doanh thu, thể loại, trạng thái và bảng theo ngày.
/// Font Roboto (có tiếng Việt) tải từ Google Fonts lúc xuất; không có mạng thì dùng font mặc định (mất dấu).
Future<Uint8List> buildReportPdf(AdminReport r, AppLocalizations l10n) async {
  pw.ThemeData theme;
  try {
    theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );
  } on Object {
    theme = pw.ThemeData();
  }
  final ink = _pdf(AdminPalette.ink);
  final muted = _pdf(AdminPalette.muted);
  final accent = _pdf(AdminPalette.accent);
  final orange = _pdf(AdminPalette.chart[1]);
  final line = _pdf(AdminPalette.line);
  final soft = _pdf(AdminPalette.bg);

  pw.Widget heading(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Text(
      t,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: ink,
      ),
    ),
  );

  pw.Widget kpi(String label, String value) => pw.Container(
    width: 160,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: soft,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: muted)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: ink,
          ),
        ),
      ],
    ),
  );

  String shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  pw.Widget revenueChart() {
    final n = r.days.length;
    final maxGmv = r.days.fold<int>(1, (a, d) => d.gmv > a ? d.gmv : a);
    final step = (n / 7).ceil().clamp(1, n);
    final xTicks = [for (var i = 0; i < n; i += step) i];
    return pw.SizedBox(
      height: 190,
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis(
            [for (final i in xTicks) i.toDouble()],
            format: (v) => shortDate(r.days[v.toInt()].date),
            textStyle: pw.TextStyle(fontSize: 7.5, color: muted),
          ),
          yAxis: pw.FixedAxis(
            [for (var i = 0; i <= 4; i++) maxGmv * i / 4],
            format: (v) => formatVndCompact(v),
            textStyle: pw.TextStyle(fontSize: 7.5, color: muted),
          ),
        ),
        datasets: [
          pw.LineDataSet(
            drawSurface: true,
            surfaceOpacity: 0.12,
            isCurved: true,
            color: accent,
            lineWidth: 1.6,
            drawPoints: false,
            data: [
              for (var i = 0; i < n; i++)
                pw.PointChartValue(i.toDouble(), r.days[i].gmv.toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget table(
    List<String> head,
    List<List<String>> rows, {
    List<String>? total,
  }) {
    final all = [...rows, ?total];
    return pw.TableHelper.fromTextArray(
      headers: head,
      data: all,
      headerStyle: pw.TextStyle(
        fontSize: 8.5,
        fontWeight: pw.FontWeight.bold,
        color: muted,
      ),
      cellStyle: pw.TextStyle(fontSize: 8.5, color: ink),
      headerDecoration: pw.BoxDecoration(color: soft),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: line, width: 0.4),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        for (var i = 1; i < head.length; i++) i: pw.Alignment.centerRight,
      },
      cellDecoration: (index, data, rowNum) =>
          total != null && rowNum == all.length - 1
          ? pw.BoxDecoration(color: soft)
          : const pw.BoxDecoration(),
    );
  }

  final catTotal = r.categories.fold<int>(0, (a, c) => a + c.amount);
  final doc = pw.Document(
    theme: theme,
    title: l10n.admReportsTitle,
    author: l10n.appTitle,
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 40),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${ctx.pageNumber} / ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: muted),
        ),
      ),
      build: (ctx) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${l10n.appTitle} · ${l10n.admReportsTitle}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  l10n.admReportPeriod(formatDate(r.from), formatDate(r.to)),
                  style: pw.TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
            pw.Text(
              l10n.admGeneratedAt(formatDateTime(DateTime.now())),
              style: pw.TextStyle(fontSize: 8.5, color: muted),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            kpi(l10n.admKpiGmv, formatVnd(r.gmv)),
            kpi(l10n.admRevenueDone, formatVnd(r.revenue)),
            kpi(l10n.admFees, formatVnd(r.platformFees)),
            kpi(l10n.admKpiOrders, '${r.orders}'),
            kpi(l10n.admAvgOrder, formatVnd(r.averageOrder)),
            kpi(l10n.admKpiNewUsers, '${r.newUsers}'),
            kpi(l10n.admAuctionOrders, '${r.auctionOrders}'),
            kpi(
              l10n.admCancelRate,
              '${(r.cancelRate * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
        heading(l10n.admReportRevenueDay),
        if (r.days.length > 1) revenueChart(),
        pw.Row(
          children: [
            pw.Container(width: 8, height: 8, color: accent),
            pw.SizedBox(width: 4),
            pw.Text(
              l10n.admSeriesRevenue,
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
            pw.SizedBox(width: 12),
            pw.Container(width: 8, height: 8, color: orange),
            pw.SizedBox(width: 4),
            pw.Text(
              l10n.admKpiOrders,
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
        heading(l10n.admReportByCategory),
        table(
          [l10n.admReportByCategory, l10n.admSeriesRevenue, '%'],
          [
            for (final c in r.categories)
              [
                c.name,
                formatVnd(c.amount),
                catTotal == 0 ? '-' : '${(c.amount * 100 / catTotal).round()}%',
              ],
          ],
        ),
        heading(l10n.admReportByStatus),
        table(
          [l10n.admReportByStatus, l10n.admKpiOrders],
          [
            for (final s in r.statuses) [s.status.label(l10n), '${s.count}'],
          ],
        ),
        heading(l10n.admReportDaily),
        table(
          [
            l10n.admColDate,
            l10n.admSeriesRevenue,
            l10n.admSeriesOrders,
            l10n.admSeriesUsers,
          ],
          [
            for (final d in r.days)
              [
                formatDate(d.date),
                formatVnd(d.gmv),
                '${d.orders}',
                '${d.newUsers}',
              ],
          ],
          total: [
            l10n.admTotal,
            formatVnd(r.gmv),
            '${r.orders}',
            '${r.newUsers}',
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

/// Lưu / tải file PDF (trên web là tải về, trên máy là mở hộp chia sẻ).
Future<void> shareReportPdf(Uint8List bytes, String filename) =>
    Printing.sharePdf(bytes: bytes, filename: filename);
