import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/glass_tab_bar.dart';
import 'package:book_marketplace/app/router/nav_overlay.dart';
import 'package:book_marketplace/app/router/sidebar.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

var _tapped = 0;

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
        panel: SidebarItem(
          Icons.search_rounded,
          'Mục thử',
          selected: false,
          onTap: () {},
        ),
        bar: (context, state) => ExpandingTabBar(
          state: state,
          items: [
            GlassTabItem(
              icon: Icons.home_rounded,
              label: 'Một',
              selected: true,
              onTap: () => _tapped++,
            ),
            GlassTabItem(
              icon: Icons.explore_rounded,
              label: 'Hai',
              selected: false,
              onTap: () {},
            ),
            GlassTabItem(
              icon: Icons.person_rounded,
              label: 'Ba',
              selected: false,
              onTap: () {},
            ),
          ],
        ),
        child: const Center(child: Text('trang')),
      ),
    ),
  ),
);

void _size(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Thanh luôn dựng hai biểu tượng Home: biểu tượng của nút (đầu tiên) và ô tab đầu (cuối cùng).
Finder get _fabIcon => find.byIcon(Icons.home_rounded).first;

/// Viên kính của thanh (nút khi thu, cả thanh khi mở).
Rect _pill(WidgetTester t) => t.getRect(
  find
      .descendant(
        of: find.byType(ExpandingTabBar),
        matching: find.byType(Glass),
      )
      .first,
);

Finder get _firstCellIcon => find.byIcon(Icons.home_rounded).last;

void main() {
  setUp(() => _tapped = 0);

  testWidgets(
    'điện thoại: nút bằng ô icon, xổ ra cân giữa màn hình, ô đầu đúng chỗ nút',
    (tester) async {
      _size(tester, const Size(390, 844));
      await tester.pumpWidget(_app());
      final collapsed = _pill(tester);
      // Nút tròn đường kính đúng bằng ô icon trên thanh.
      expect(collapsed.width, ExpandingTabBar.cell);
      expect(collapsed.height, ExpandingTabBar.cell);
      final fabCenter = tester.getCenter(_fabIcon);

      await tester.tap(_fabIcon);
      await tester.pumpAndSettle();
      final open = _pill(tester);
      expect(open.width, ExpandingTabBar.pad * 2 + ExpandingTabBar.cell * 3);
      // Thanh mở cân giữa màn hình (không lệch trái).
      expect((open.center.dx - 390 / 2).abs(), lessThan(0.5));
      expect(find.text('Hai'), findsOneWidget);
      // Ô đầu tiên nằm đúng tâm cũ của nút.
      final first = tester.getCenter(_firstCellIcon);
      expect((first.dx - fabCenter.dx).abs(), lessThan(1.5));
    },
  );

  testWidgets('chọn một tab thì chạy hành động và thanh thu lại', (
    tester,
  ) async {
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    await tester.tap(_fabIcon);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Một'));
    await tester.pumpAndSettle();
    expect(_tapped, 1);
    expect(_pill(tester).width, ExpandingTabBar.cell);
  });

  testWidgets('bấm ra ngoài thì thanh thu lại', (tester) async {
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    await tester.tap(_fabIcon);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();
    expect(_pill(tester).width, ExpandingTabBar.cell);
  });

  testWidgets('máy tính bảng / desktop: nút mở sidebar, bấm mục thì đóng', (
    tester,
  ) async {
    _size(tester, const Size(1000, 800));
    await tester.pumpWidget(_app());
    expect(find.text('Mục thử'), findsNothing);

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Mục thử'), findsOneWidget);

    await tester.tap(find.text('Mục thử'));
    await tester.pumpAndSettle();
    expect(find.text('Mục thử'), findsNothing);
  });

  testWidgets('trang con (showButton=false) không có nút', (tester) async {
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(_app(showButton: false));
    expect(find.byType(ExpandingTabBar), findsNothing);
  });

  testWidgets('kéo nút sang nửa phải thì đổi cài đặt sang phải', (
    tester,
  ) async {
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavOverlay)),
    );
    expect(container.read(appSettingsControllerProvider).navSide, NavSide.left);

    await tester.drag(_fabIcon, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(
      container.read(appSettingsControllerProvider).navSide,
      NavSide.right,
    );
  });
}
