import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/generated/app_localizations.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/widgets/book_form.dart';

const _cats = [
  Category(id: '1', name: 'Văn học'),
  Category(id: '2', name: 'Tiểu thuyết Việt Nam', parentId: '1'),
  Category(id: '3', name: 'Văn học nước ngoài', parentId: '1'),
  Category(id: '9', name: 'Thiếu nhi'),
];

Widget _app(GlobalKey<BookFormState> key) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('vi'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: BookForm(key: key, categories: _cats, photoFolder: 'test'),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'ô thể loại đầu chỉ có thể loại cha, chọn cha có con thì hiện ô con',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey<BookFormState>();
      await tester.pumpWidget(_app(key));
      await tester.pumpAndSettle();

      // Chưa chọn cha: chưa có ô thể loại con.
      expect(find.text('Thể loại con'), findsNothing);

      await tester.tap(find.text('Thể loại'));
      await tester.pumpAndSettle();
      // Menu chỉ liệt kê thể loại cha.
      expect(find.text('Văn học'), findsOneWidget);
      expect(find.text('Thiếu nhi'), findsOneWidget);
      expect(find.text('Tiểu thuyết Việt Nam'), findsNothing);

      await tester.tap(find.text('Văn học'));
      await tester.pumpAndSettle();
      // Cha "Văn học" có thể loại con: ô thứ hai xuất hiện.
      expect(find.text('Thể loại con'), findsOneWidget);

      await tester.tap(find.text('Thể loại con'));
      await tester.pumpAndSettle();
      expect(find.text('Tiểu thuyết Việt Nam'), findsOneWidget);
      expect(find.text('Văn học nước ngoài'), findsOneWidget);
    },
  );

  testWidgets('cha không có thể loại con thì không hiện ô thứ hai', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey<BookFormState>();
    await tester.pumpWidget(_app(key));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thể loại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thiếu nhi'));
    await tester.pumpAndSettle();
    expect(find.text('Thể loại con'), findsNothing);
  });
}
