import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/nav_overlay.dart';
import 'package:book_marketplace/app/router/sidebar.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';

Widget _app({bool showButton = true}) => ProviderScope(
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
      body: NavOverlay(
        icon: Icons.home_rounded,
        showButton: showButton,
        panel: Builder(
          builder: (context) => SidebarItem(
            Icons.search_rounded,
            'Mục thử',
            selected: false,
            onTap: () {},
          ),
        ),
        child: const Center(child: Text('trang')),
      ),
    ),
  ),
);

void main() {
  testWidgets('bấm nút thì sidebar hiện ra, bấm một mục thì sidebar đóng', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.text('Mục thử'), findsNothing);

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Mục thử'), findsOneWidget);

    await tester.tap(find.text('Mục thử'));
    await tester.pumpAndSettle();
    expect(find.text('Mục thử'), findsNothing);
    // Nút quay lại.
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
  });

  testWidgets('bấm ra ngoài (nền mờ) cũng đóng sidebar', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(600, 300));
    await tester.pumpAndSettle();
    expect(find.text('Mục thử'), findsNothing);
  });

  testWidgets('trang con (showButton=false) không có nút', (tester) async {
    await tester.pumpWidget(_app(showButton: false));
    expect(find.byIcon(Icons.home_rounded), findsNothing);
  });

  testWidgets('kéo nút sang nửa phải thì đổi cài đặt sang phải', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavOverlay)),
    );
    expect(container.read(appSettingsControllerProvider).navSide, NavSide.left);

    await tester.drag(find.byIcon(Icons.home_rounded), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(
      container.read(appSettingsControllerProvider).navSide,
      NavSide.right,
    );
  });
}
