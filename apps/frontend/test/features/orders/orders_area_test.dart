import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/features/orders/presentation/providers/orders_providers.dart';
import 'package:book_marketplace/features/orders/presentation/screens/orders_screen.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

Order _order(String code, OrderType type) => Order(
  id: 'o$code',
  code: code,
  type: type,
  status: OrderStatus.pendingPayment,
  items: [
    OrderItem(id: 'i$code', title: 'Sách $code', unitPrice: 1000, quantity: 1),
  ],
  subtotal: 1000,
  shippingFee: 0,
  buyerPremium: 0,
  depositApplied: 0,
  total: 1000,
  createdAt: DateTime(2026, 10, 30),
  history: const [],
  canReview: false,
);

Widget _app(bool auction) => ProviderScope(
  overrides: [
    // ignore: riverpod_lint/scoped_providers_should_specify_dependencies, ghi đè trong test
    myOrdersProvider.overrideWith(
      (ref) async => [
        _order('NORMAL1', OrderType.normal),
        _order('AUCTION1', OrderType.auction),
      ],
    ),
  ],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => OrdersScreen(auction: auction),
        ),
      ],
    ),
    theme: AppTheme.light(),
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  ),
);

void main() {
  testWidgets('khu mua sách chỉ hiện đơn giá cố định', (tester) async {
    await tester.pumpWidget(_app(false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('NORMAL1'), findsWidgets);
    expect(find.textContaining('AUCTION1'), findsNothing);
  });

  testWidgets('khu đấu giá chỉ hiện hoá đơn lô đã thắng', (tester) async {
    await tester.pumpWidget(_app(true));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('AUCTION1'), findsWidgets);
    expect(find.textContaining('NORMAL1'), findsNothing);
    expect(find.text('Lô đã thắng'), findsWidgets);
  });
}
