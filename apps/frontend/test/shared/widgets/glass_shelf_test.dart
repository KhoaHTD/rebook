import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/glass_shelf.dart';

Widget _app(List<ShelfEntry> entries) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('vi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: SingleChildScrollView(
      child: GlassShelf(
        title: 'Văn học',
        entries: entries,
        color: ShelfPalette.at(0),
      ),
    ),
  ),
);

List<ShelfEntry> _entries(int n, {void Function(int)? onTap}) => [
  for (var i = 0; i < n; i++)
    ShelfEntry(
      id: 'b$i',
      title: 'Sách $i',
      author: 'Tác giả $i',
      price: '${(i + 1) * 10}.000 đ',
      onTap: onTap == null ? null : () => onTap(i),
    ),
];

void main() {
  testWidgets('hiện tên kệ, số cuốn và chip giá trên bìa', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_entries(5)));
    expect(find.text('Văn học'), findsOneWidget);
    expect(find.text('5 cuốn'), findsOneWidget);
    expect(find.text('10.000 đ'), findsOneWidget);
  });

  testWidgets('bìa vuông góc: không có bo góc ở bìa sách', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_entries(3)));
    final clips = tester.widgetList<ClipRRect>(find.byType(ClipRRect));
    for (final c in clips) {
      expect(c.borderRadius, BorderRadius.zero);
    }
  });

  testWidgets('bấm một cuốn thì gọi onTap của cuốn đó', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int? tapped;
    await tester.pumpWidget(_app(_entries(4, onTap: (i) => tapped = i)));
    await tester.tap(find.text('20.000 đ'));
    expect(tapped, 1);
  });

  testWidgets('mũi tên phải cuộn kệ, mũi tên trái cuộn lại', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_entries(12)));
    final list = find.descendant(
      of: find.byType(GlassShelf),
      matching: find.byType(Scrollable),
    );
    final pos = tester.state<ScrollableState>(list.first).position;
    expect(pos.pixels, 0);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(pos.pixels, greaterThan(0));
    final moved = pos.pixels;

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(pos.pixels, lessThan(moved));
  });
}
