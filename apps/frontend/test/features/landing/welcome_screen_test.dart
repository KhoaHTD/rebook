import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/features/landing/presentation/screens/welcome_screen.dart';

Widget _app(double offset) => MaterialApp(
  locale: const Locale('vi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: WelcomeScreen(key: ValueKey(offset), initialOffset: offset),
);

void main() {
  // Mỗi vị trí cuộn là một lần dựng mới (initialOffset chỉ có tác dụng lúc tạo).
  // Chữ trong test là font Ahem (rộng hơn Inter nhiều) nên bỏ qua lỗi "overflowed"; mọi lỗi khác vẫn làm test hỏng.
  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    testWidgets('trang giới thiệu dựng được mọi cảnh ở ${size.width}px', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) {
        if (!d.exceptionAsString().contains('overflowed')) {
          errors.add(d.exceptionAsString());
        }
      };
      try {
        for (final y in <double>[
          0,
          700,
          2500,
          4500,
          7000,
          9000,
          11000,
          13500,
          15300,
          16500,
          17500,
        ]) {
          await tester.pumpWidget(_app(y));
          await tester.pump(const Duration(milliseconds: 300));
        }
      } finally {
        FlutterError.onError = previous;
      }
      expect(errors, isEmpty);
    });
  }
}
