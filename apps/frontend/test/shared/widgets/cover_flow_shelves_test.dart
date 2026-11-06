import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/shared/widgets/cover_flow_home.dart';

CoverFlowEntry _entry(String id) =>
    CoverFlowEntry(id: id, title: 'Sách $id', author: 'Tác giả', price: '1 đ');

void main() {
  testWidgets(
    'bấm tab thể loại thì cuộn tới kệ đó; kệ có thẻ "Xem tất cả" cuối hàng',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var seeAllCount = 0;
      final shelves = [
        for (var i = 0; i < 4; i++)
          CoverFlowShelf(
            'Thể loại $i',
            [for (var j = 0; j < 3; j++) _entry('$i-$j')],
            onSeeAll: () => seeAllCount++,
            seeAllLabel: 'Xem tất cả',
            seeAllCaption: 'Xem tất cả 3 cuốn',
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: CoverFlowHome(
              title: 'Khám phá',
              trailing: (_) => const SizedBox.shrink(),
              hero: [_entry('h1'), _entry('h2')],
              tabs: const [
                'Tất cả',
                'Thể loại 0',
                'Thể loại 1',
                'Thể loại 2',
                'Thể loại 3',
              ],
              shelves: shelves,
              emptyText: 'trống',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, 0);

      // Bấm tab "Thể loại 0" (hai bản: thanh trong tờ giấy và thanh dính; lấy bản đầu, đang nằm trong khung nhìn).
      await tester.tap(find.text('Thể loại 0').first);
      await tester.pumpAndSettle();
      // Tiêu đề kệ nằm ngay dưới thanh tiêu đề + thanh tab dính (khoảng 56 + 48 px từ đỉnh).
      final headerTop = tester.getTopLeft(find.text('THỂ LOẠI 0')).dy;
      expect(scrollable.position.pixels, greaterThan(0));
      expect(headerTop, inInclusiveRange(104, 190));

      // Quay về "Tất cả" thì lên đầu trang.
      await tester.tap(find.text('Tất cả').first);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, 0);

      // Tiêu đề kệ có "Xem tất cả ›" và bấm được.
      await tester.tap(find.text('Xem tất cả ›').first);
      expect(seeAllCount, 1);
    },
  );
}
