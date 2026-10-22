import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/catalog/data/catalog_repository_provider.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/search_screen.dart';
import 'package:book_marketplace/shared/domain/book.dart';

class _StubCatalogRepository implements CatalogRepository {
  _StubCatalogRepository(this.books, {this.fail = false});

  final List<Book> books;
  final bool fail;
  final queries = <String?>[];

  @override
  Future<List<Book>> listBooks({String? query}) async {
    queries.add(query);
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
    home: const SearchScreen(),
  ),
);

void main() {
  const books = [
    Book(
      id: 'b1',
      title: 'Số Đỏ',
      author: 'Vũ Trọng Phụng',
      condition: BookCondition.veryGood,
      price: 60000,
      sellerName: 'Minh Anh',
    ),
    Book(
      id: 'b2',
      title: 'Tắt Đèn',
      author: 'Ngô Tất Tố',
      condition: BookCondition.acceptable,
      price: 25000,
      sellerName: 'Gác Xép',
    ),
  ];

  testWidgets('hiển thị kết quả và số lượng', (tester) async {
    await tester.pumpWidget(_wrap(_StubCatalogRepository(books)));
    await tester.pumpAndSettle();

    expect(find.text('Số Đỏ'), findsOneWidget);
    expect(find.text('Tắt Đèn'), findsOneWidget);
    expect(find.text('2 kết quả'), findsOneWidget);
  });

  testWidgets('gõ từ khoá rồi tìm thì gọi lại repository', (tester) async {
    final repo = _StubCatalogRepository(books);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kiều');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repo.queries.last, 'kiều');
  });

  testWidgets('đổi sắp xếp: giá thấp trước', (tester) async {
    await tester.pumpWidget(_wrap(_StubCatalogRepository(books)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mới nhất'));
    await tester.pumpAndSettle();

    expect(find.text('Giá thấp trước'), findsOneWidget);
    final first = tester.getTopLeft(find.text('Tắt Đèn')).dy;
    final second = tester.getTopLeft(find.text('Số Đỏ')).dy;
    expect(first, lessThan(second));
  });

  testWidgets('hiển thị lỗi mạng và nút thử lại', (tester) async {
    await tester.pumpWidget(_wrap(_StubCatalogRepository([], fail: true)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Không kết nối được'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
