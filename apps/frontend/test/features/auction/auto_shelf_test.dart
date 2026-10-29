import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/features/auction/presentation/widgets/auto_shelf.dart';

Widget _app(List<ShelfBook> books) => MaterialApp(
  theme: AppTheme.auction(),
  locale: const Locale('vi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: Center(child: AutoShelf(books: books)),
  ),
);

/// Trôi theo nhịp 50 ms (bước lớn hơn 0,1 giây bị bỏ qua để sách không giật vọt).
Future<void> _run(WidgetTester tester, Duration total) async {
  for (
    var t = Duration.zero;
    t < total;
    t += const Duration(milliseconds: 50)
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

List<ShelfBook> _books(int n) => [
  for (var i = 0; i < n; i++)
    ShelfBook(id: 'b$i', title: 'Sách $i', author: 'Tác giả $i'),
];

void main() {
  testWidgets('kệ tự trôi theo một chiều và lặp vô tận', (tester) async {
    await tester.pumpWidget(_app(_books(3)));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    final start = scrollable.position.pixels;

    // Mỗi lần pump là một nhịp ticker; trôi liên tục, không tự dừng.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final later = scrollable.position.pixels;
    expect(later, greaterThan(start));

    // Có nhiều hơn 3 cuốn được dựng khi trôi xa: danh sách lặp, không hết.
    await _run(tester, const Duration(seconds: 5));
    expect(scrollable.position.pixels, greaterThan(later));
  });

  testWidgets('chạm giữ thì dừng, thả một lúc sau thì trôi tiếp', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_books(3)));
    await tester.pump(const Duration(milliseconds: 100));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AutoShelf)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final held = scrollable.position.pixels;
    await _run(tester, const Duration(seconds: 1));
    expect(scrollable.position.pixels, held);

    await gesture.up();
    await _run(tester, const Duration(seconds: 2));
    await _run(tester, const Duration(seconds: 1));
    expect(scrollable.position.pixels, greaterThan(held));
  });

  testWidgets('không có sách thì không dựng gì', (tester) async {
    await tester.pumpWidget(_app(const []));
    expect(find.byType(ListView), findsNothing);
  });
}
