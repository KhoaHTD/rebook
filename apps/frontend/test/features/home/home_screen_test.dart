import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/features/home/data/fake_home_repository.dart';
import 'package:book_marketplace/features/home/data/home_repository_provider.dart';
import 'package:book_marketplace/features/home/presentation/screens/home_screen.dart';

void main() {
  test('Fake feed có đủ hai kênh', () async {
    final feed = await FakeHomeRepository(latency: Duration.zero).getFeed();
    expect(feed.newListings, isNotEmpty);
    expect(feed.categories, hasLength(4));
    expect(feed.liveLot, isNotNull);
    expect(feed.upcomingSessions, isNotEmpty);
    expect(feed.featuredLots, isNotEmpty);
  });

  testWidgets('chuyển kênh Mua sách ↔ Đấu giá', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        // ignore: riverpod_lint/scoped_providers_should_specify_dependencies
        overrides: [
          clockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          homeRepositoryProvider.overrideWithValue(
            FakeHomeRepository(latency: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Mới đăng gần bạn'), findsOneWidget);
    expect(find.text('Tiền được giữ an toàn'), findsOneWidget);

    await tester.tap(find.text('Đấu giá'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Phiên sắp tới'), findsOneWidget);
    expect(find.text('Vào phòng đấu giá'), findsOneWidget);
  });
}
