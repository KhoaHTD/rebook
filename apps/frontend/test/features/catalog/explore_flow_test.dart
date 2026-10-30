import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/explore_sections.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';

Widget _app(void Function(Listing) onOpen) => ProviderScope(
  child: MaterialApp(
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
      body: SingleChildScrollView(child: ExplorePosterFlow(onOpen: onOpen)),
    ),
  ),
);

/// Dữ liệu giả có độ trễ: đợi tới khi tải xong rồi mới kiểm tra.
Future<void> _load(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
}

/// Chữ trong test (font mặc định) rộng hơn thật nên có thể nằm ngoài màn hình: cuộn tới rồi mới bấm.
Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
}

void main() {
  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('có bốn tab, số hạng 1 trên poster giữa và nút Xem sách', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(_app((_) {}));
    await _load(tester);

    expect(find.text('Thịnh hành'), findsOneWidget);
    expect(find.text('Mới lên kệ'), findsOneWidget);
    expect(find.text('Giá tốt'), findsOneWidget);
    expect(find.text('Thể loại'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Xem sách'), findsOneWidget);
  });

  testWidgets('bấm Xem sách thì mở sách đang ở giữa', (tester) async {
    phone(tester);
    Listing? opened;
    await tester.pumpWidget(_app((l) => opened = l));
    await _load(tester);

    await _tapText(tester, 'Xem sách');
    expect(opened, isNotNull);
  });

  testWidgets('đổi sang dạng lưới rồi trở lại băng chuyền', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app((_) {}));
    await _load(tester);

    await _tapText(tester, 'Dạng lưới');
    await _load(tester);
    expect(find.text('Xem sách'), findsNothing);
    expect(find.text('Băng chuyền'), findsOneWidget);

    await _tapText(tester, 'Băng chuyền');
    await _load(tester);
    expect(find.text('Xem sách'), findsOneWidget);
  });

  testWidgets('tab Thể loại hiện hàng chip thể loại', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app((_) {}));
    await _load(tester);

    await _tapText(tester, 'Thể loại');
    await _load(tester);
    expect(find.byType(ChoiceChip), findsWidgets);
  });
}
