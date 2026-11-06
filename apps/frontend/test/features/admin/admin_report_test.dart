import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/generated/app_localizations_vi.dart';
import 'package:book_marketplace/features/admin/data/fake_admin_repository.dart';
import 'package:book_marketplace/features/admin/domain/admin_report.dart';
import 'package:book_marketplace/features/admin/presentation/export/report_csv.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

void main() {
  late FakeStore store;
  tearDown(() => store.dispose());

  test(
    'báo cáo có đủ mọi ngày, tổng khớp từng ngày và cùng kỳ ra cùng số',
    () async {
      store = FakeStore()..login('admin@rebook.vn', '123456');
      final repo = FakeAdminRepository(store);
      final from = DateTime(2026, 10, 1);
      final to = DateTime(2026, 10, 14);
      final a = await repo.report(from, to);
      final b = await repo.report(from, to);

      expect(a.days.length, 14);
      expect(a.days.first.date, from);
      expect(a.days.last.date, to);
      expect(a.gmv, a.days.fold<int>(0, (s, d) => s + d.gmv));
      expect(a.orders, a.days.fold<int>(0, (s, d) => s + d.orders));
      expect(a.gmv, b.gmv);
      expect(a.categories, isNotEmpty);
    },
  );

  test('chỉ số suy ra: giá trị trung bình, tỉ lệ huỷ và xu hướng', () {
    AdminReport report(List<int> gmv) => AdminReport(
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 4),
      gmv: gmv.fold(0, (a, b) => a + b),
      revenue: 0,
      platformFees: 0,
      orders: 10,
      completedOrders: 5,
      cancelledOrders: 2,
      auctionOrders: 3,
      newUsers: 0,
      days: [
        for (final (i, g) in gmv.indexed)
          ReportDay(
            date: DateTime(2026, 10, 1 + i),
            gmv: g,
            orders: 1,
            newUsers: 0,
          ),
      ],
      categories: const [],
      statuses: const [],
    );

    final up = report([100, 100, 150, 150]);
    expect(up.averageOrder, 50);
    expect(up.cancelRate, closeTo(0.2, 1e-9));
    expect(up.normalOrders, 7);
    expect(up.trendOf((d) => d.gmv), closeTo(0.5, 1e-9));
    expect(report([0, 0, 5, 5]).trendOf((d) => d.gmv), isNull);
  });

  test('CSV có BOM, tiêu đề cột và dòng tổng', () async {
    store = FakeStore()..login('admin@rebook.vn', '123456');
    final r = await FakeAdminRepository(store)
        .report(DateTime(2026, 10, 1), DateTime(2026, 10, 3));
    final csv = reportCsv(r, AppLocalizationsVi());

    expect(csv.startsWith('﻿'), isTrue);
    expect(csv, contains('01/10/2026'));
    expect(csv, contains('Tổng,${r.gmv},${r.orders},${r.newUsers}'));
    expect(reportFileName(r, 'csv'), 'rebook-report-2026-10-01_2026-10-03.csv');
  });
}
