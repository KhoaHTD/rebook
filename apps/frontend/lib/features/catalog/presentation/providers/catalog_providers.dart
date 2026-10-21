import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/features/catalog/data/catalog_repository_provider.dart';
import 'package:book_marketplace/shared/domain/book.dart';

part 'catalog_providers.g.dart';

/// Từ khoá tìm kiếm hiện tại trên màn Chợ sách.
@riverpod
class BookSearchQuery extends _$BookSearchQuery {
  @override
  String build() => '';

  void set(String value) => state = value;
}

@riverpod
Future<List<Book>> bookList(Ref ref) {
  final query = ref.watch(bookSearchQueryProvider);
  return ref.watch(catalogRepositoryProvider).listBooks(query: query);
}

@riverpod
Future<Book> bookDetail(Ref ref, String id) =>
    ref.watch(catalogRepositoryProvider).getBook(id);
