import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/catalog/data/catalog_repository_provider.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:book_marketplace/shared/domain/book.dart';

class _StubCatalogRepository implements CatalogRepository {
  _StubCatalogRepository(this.books, {this.fail = false});

  final List<Book> books;
  final bool fail;

  @override
  Future<List<Book>> listBooks({String? query}) async {
    if (fail) throw const NetworkException();
    return books;
  }

  @override
  Future<Book> getBook(String id) async => books.firstWhere((b) => b.id == id);
}

Widget _wrap(CatalogRepository repo) => ProviderScope(
  // ProviderScope này là gốc của cây widget trong test, không phải scope lồng nhau.
  // ignore: riverpod_lint/scoped_providers_should_specify_dependencies
  overrides: [catalogRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const CatalogScreen(),
  ),
);

void main() {
  const book = Book(
    id: 'b1',
    title: 'Số Đỏ',
    author: 'Vũ Trọng Phụng',
    condition: BookCondition.good,
    price: 60000,
    sellerName: 'Minh Anh',
  );

  testWidgets('hiển thị danh sách sách', (tester) async {
    await tester.pumpWidget(_wrap(_StubCatalogRepository([book])));
    await tester.pumpAndSettle();

    expect(find.text('Số Đỏ'), findsOneWidget);
    expect(find.text('Vũ Trọng Phụng'), findsOneWidget);
    expect(find.text('Tốt'), findsOneWidget);
  });

  testWidgets('hiển thị lỗi mạng và nút thử lại', (tester) async {
    await tester.pumpWidget(_wrap(_StubCatalogRepository([], fail: true)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Không kết nối được'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
