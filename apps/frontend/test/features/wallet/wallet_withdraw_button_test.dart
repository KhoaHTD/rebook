import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/features/wallet/data/fake_wallet_repository.dart';
import 'package:book_marketplace/features/wallet/data/wallet_repository_provider.dart';
import 'package:book_marketplace/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

/// Người mua (chưa mở shop) cũng rút được tiền dư trong ví: nút "Rút tiền" hiện cho mọi người dùng ở ví mua sách,
/// và không hiện ở ví khu đấu giá (đó là tiền cọc).
void main() {
  late FakeStore store;
  setUp(() => store = FakeStore()..login('khoa@rebook.vn', '123456'));
  tearDown(() => store.dispose());

  Widget app(FakeStore store, {required bool auction}) => ProviderScope(
    overrides: [
      // ignore: riverpod_lint/scoped_providers_should_specify_dependencies, ghi đè trong test
      walletRepositoryProvider.overrideWithValue(FakeWalletRepository(store)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: GoRouter(
        initialLocation: Routes.wallet,
        routes: [
          GoRoute(
            path: Routes.wallet,
            builder: (_, _) => WalletScreen(auction: auction),
          ),
        ],
      ),
    ),
  );

  testWidgets('người mua không có shop vẫn thấy nút Rút tiền', (tester) async {
    expect(store.me.hasShop, isFalse);

    await tester.pumpWidget(app(store, auction: false));
    await tester.pumpAndSettle();

    expect(find.text('Rút tiền'), findsOneWidget);
  });

  testWidgets('ví khu đấu giá không có nút Rút tiền', (tester) async {

    await tester.pumpWidget(app(store, auction: true));
    await tester.pumpAndSettle();

    expect(find.text('Rút tiền'), findsNothing);
  });
}
