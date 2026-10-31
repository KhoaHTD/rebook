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
import 'package:book_marketplace/features/wallet/presentation/screens/withdraw_screens.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

/// Rút tiền chia ba bước: chọn ngân hàng → số tài khoản (kèm Gần đây) → số tiền → kết quả.
void main() {
  late FakeStore store;
  setUp(() => store = FakeStore()..login('minhanh@rebook.vn', '123456'));
  tearDown(() => store.dispose());

  Widget app() => ProviderScope(
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
        initialLocation: Routes.withdrawBank,
        routes: [
          GoRoute(
            path: Routes.wallet,
            builder: (_, _) => const Scaffold(body: Text('VÍ')),
          ),
          GoRoute(
            path: Routes.withdrawBank,
            builder: (_, _) => const WithdrawBankScreen(),
          ),
          GoRoute(
            path: Routes.withdrawAccount,
            builder: (_, _) => const WithdrawAccountScreen(),
          ),
          GoRoute(
            path: Routes.withdrawAmount,
            builder: (_, _) => const WithdrawAmountScreen(),
          ),
          GoRoute(
            path: Routes.withdrawDone,
            builder: (_, _) => const WithdrawDoneScreen(),
          ),
        ],
      ),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pump();
    await tester.tap(find.text(text).first);
    await settle(tester);
  }

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'tìm ngân hàng, chọn tài khoản gần đây, rút tiền tới màn kết quả',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(app());
      await settle(tester);

      // Bước 1: tìm "tech" chỉ còn Techcombank.
      expect(find.text('Chọn ngân hàng'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'tech');
      await settle(tester);
      expect(find.text('Techcombank'), findsOneWidget);
      expect(find.text('Vietcombank'), findsNothing);
      await tapText(tester, 'Techcombank');

      // Bước 2: chỉ hiện tài khoản Techcombank đã dùng; Vietcombank (yêu thích) không có ở đây.
      expect(find.text('Gần đây'), findsOneWidget);
      expect(find.textContaining('19036789012345'), findsOneWidget);
      expect(find.textContaining('0011004567890'), findsNothing);
      await tapText(tester, 'NGUYEN MINH ANH');

      // Bước 3: gợi ý nhanh, nút Tiếp tắt cho tới khi số tiền hợp lệ.
      expect(find.text('Tổng tiền rút'), findsOneWidget);
      expect(find.text('Rút hết'), findsOneWidget);
      FilledButton next() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp'),
      );
      expect(next().onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, '300000');
      await settle(tester);
      expect(next().onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp'));
      await settle(tester);

      // Kết quả.
      expect(find.text('Đã gửi yêu cầu rút tiền'), findsOneWidget);
      expect(find.textContaining('Techcombank'), findsWidgets);
      final pending = store.myWithdrawals().first;
      expect(pending.amount, 300000);
      expect(pending.bankAccountNumber, '19036789012345');
    },
  );

  testWidgets('số tiền vượt số dư thì không cho bấm Tiếp', (tester) async {
    phone(tester);
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'tech');
    await settle(tester);
    await tapText(tester, 'Techcombank');
    await tapText(tester, 'NGUYEN MINH ANH');
    await tester.enterText(find.byType(TextField).first, '999999999999');
    await settle(tester);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Tiếp'))
          .onPressed,
      isNull,
    );
  });
}
