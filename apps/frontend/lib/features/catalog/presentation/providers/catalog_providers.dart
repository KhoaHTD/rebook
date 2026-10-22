import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/features/catalog/data/catalog_repository_provider.dart';
import 'package:book_marketplace/features/catalog/domain/book_search_filter.dart';
import 'package:book_marketplace/shared/domain/book.dart';

part 'catalog_providers.g.dart';

/// Bộ lọc hiện tại trên màn Tìm kiếm.
@riverpod
class BookSearch extends _$BookSearch {
  @override
  BookSearchFilter build() => const BookSearchFilter();

  void setQuery(String value) => state = state.copyWith(query: value.trim());

  void toggleCondition(BookCondition c) {
    final next = {...state.conditions};
    if (!next.remove(c)) next.add(c);
    state = state.copyWith(conditions: next);
  }

  void setPriceRange(int? min, int? max) =>
      state = state.copyWith(minPrice: min, maxPrice: max);

  void setSort(BookSort sort) => state = state.copyWith(sort: sort);

  void replace(BookSearchFilter filter) => state = filter;
}

/// Sách backend trả về cho một từ khoá (cache theo từ khoá).
@riverpod
Future<List<Book>> bookQueryResults(Ref ref, String query) => ref
    .watch(catalogRepositoryProvider)
    .listBooks(query: query.isEmpty ? null : query);

/// Kết quả tìm kiếm: chỉ gọi lại backend khi từ khoá đổi; lọc / sắp xếp làm tại chỗ.
@riverpod
Future<List<Book>> searchResults(Ref ref) async {
  final filter = ref.watch(bookSearchProvider);
  final books = await ref.watch(bookQueryResultsProvider(filter.query).future);
  return filter.apply(books);
}

@riverpod
Future<Book> bookDetail(Ref ref, String id) =>
    ref.watch(catalogRepositoryProvider).getBook(id);
