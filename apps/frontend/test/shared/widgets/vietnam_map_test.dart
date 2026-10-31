import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/shared/widgets/vietnam_map.dart';

Widget _app(String? province) => MaterialApp(
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
    body: Center(
      child: SizedBox(
        width: 360,
        child: RepaintBoundary(
          key: const ValueKey('map'),
          child: VietnamMap(province: province),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('có ghim khi nhận ra tỉnh, không ghim khi không nhận ra', (
    tester,
  ) async {
    await tester.pumpWidget(_app('TP. Hồ Chí Minh'));
    expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);

    await tester.pumpWidget(_app('Atlantis'));
    expect(find.byIcon(Icons.location_on_rounded), findsNothing);

    await tester.pumpWidget(_app(null));
    expect(find.byIcon(Icons.location_on_rounded), findsNothing);
  });

  testWidgets('ghim nằm trong khung sơ đồ', (tester) async {
    await tester.pumpWidget(_app('Hà Nội'));
    final map = tester.getRect(find.byType(VietnamMap));
    final pin = tester.getCenter(find.byIcon(Icons.location_on_rounded));
    expect(map.contains(pin), isTrue);
  });

  // Xuất ảnh sơ đồ ra file để mắt người kiểm tra hình dạng (chỉ khi đặt MAP_PNG).
  testWidgets('xuất ảnh sơ đồ', (tester) async {
    final out = Platform.environment['MAP_PNG'];
    if (out == null) return;
    await tester.runAsync(() async {
      await tester.pumpWidget(_app('TP. Hồ Chí Minh'));
      await tester.pump();
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('map')),
      ) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(out).writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
