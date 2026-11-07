import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/generated/app_localizations.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/shared/widgets/cart_fly.dart';

/// Trang có một "bìa sách" làm điểm xuất phát; nút bấm gọi [CartFly.play].
Widget _app({bool onRight = false, VoidCallback? onTap}) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => Column(
        children: [
          const SizedBox(height: 100),
          const FlightSource(
            token: 'book-1',
            child: SizedBox(
              key: ValueKey('cover'),
              width: 200,
              height: 300,
              child: ColoredBox(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: () => CartFly.play(
              context,
              token: 'book-1',
              onRight: onRight,
              bottomInset: 96,
              onTap: onTap,
              cover: (size) => SizedBox(
                key: const ValueKey('flying'),
                width: size.width,
                height: size.height,
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
            child: const Text('add'),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('bìa bay từ chỗ cũ tới góc giỏ rồi tự dọn', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('add'));
    await tester.pump(); // dựng khung đầu

    // Chưa tới 0.06 của thời lượng: sách còn nằm nguyên chỗ, bong bóng đang nhô lên.
    expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('flying')), findsNothing);

    // Giữa chặng: sách đang bay, đã rời bìa gốc (đường cong vòng lên trước khi hạ xuống).
    await tester.pump(const Duration(milliseconds: 600));
    final mid = tester.getCenter(find.byKey(const ValueKey('flying')));
    final origin = tester.getCenter(find.byKey(const ValueKey('cover')));
    expect(mid, isNot(origin));

    // Gần cuối chặng bay: sách đã hạ thấp hơn bìa gốc và nhỏ đi nhiều (tỉ lệ thu nhỏ).
    await tester.pump(const Duration(milliseconds: 280));
    final late = tester.getCenter(find.byKey(const ValueKey('flying')));
    expect(late.dy, greaterThan(origin.dy));
    expect(
      tester.getRect(find.byKey(const ValueKey('flying'))).width,
      lessThan(120),
    );

    // Xong thì overlay được dọn, không còn sách bay lẫn bong bóng.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('flying')), findsNothing);
    expect(find.byIcon(Icons.shopping_bag_rounded), findsNothing);
  });

  testWidgets('bấm vào bong bóng gọi onTap (mở giỏ)', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    var taps = 0;
    await tester.pumpWidget(_app(onTap: () => taps++));
    await tester.tap(find.text('add'));
    await tester.pump(); // khung đầu tiên: hoạt ảnh bắt đầu chạy từ đây
    await tester.pump(const Duration(milliseconds: 700));
    final bubble = find.ancestor(
      of: find.byIcon(Icons.shopping_bag_rounded),
      matching: find.byType(Material),
    );
    await tester.tapAt(tester.getCenter(bubble.last));
    expect(taps, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('không còn bìa trên màn thì vẫn chạy (dùng giữa màn)', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(_app(onRight: true));
    await tester.tap(find.text('add'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
  });
}
