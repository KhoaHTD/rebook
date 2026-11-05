import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/skeleton.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

Widget _loading() => AsyncValueView<int>(
  value: const AsyncLoading(),
  data: (_) => const SizedBox.shrink(),
);

void main() {
  testWidgets('AsyncValueView đang tải hiện khung xương, không có vòng quay', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_loading()));
    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('khung xương không tràn trong vùng nhỏ', (tester) async {
    await tester.pumpWidget(
      _app(Center(child: SizedBox(width: 120, height: 60, child: _loading()))),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('khung xương nằm được trong danh sách cuộn', (tester) async {
    await tester.pumpWidget(_app(ListView(children: [_loading()])));
    expect(tester.takeException(), isNull);
    expect(find.byType(Skeleton), findsWidgets);
  });

  testWidgets('khung xương trang chủ không tràn ở 375 và 1400px', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    for (final width in [375.0, 1400.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(_app(const SkeletonHome()));
      expect(tester.takeException(), isNull);
    }
  });
}
