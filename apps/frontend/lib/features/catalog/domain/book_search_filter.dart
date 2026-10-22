import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/book.dart';

part 'book_search_filter.freezed.dart';

enum BookSort { newest, priceAsc, priceDesc }

/// Bộ lọc màn Tìm kiếm: từ khoá (gửi backend) + tình trạng, khoảng giá, sắp xếp (lọc tại chỗ
/// cho tới khi spec API có tham số tương ứng).
@freezed
abstract class BookSearchFilter with _$BookSearchFilter {
  const BookSearchFilter._();

  const factory BookSearchFilter({
    @Default('') String query,
    @Default(<BookCondition>{}) Set<BookCondition> conditions,
    int? minPrice,
    int? maxPrice,
    @Default(BookSort.newest) BookSort sort,
  }) = _BookSearchFilter;

  /// Số bộ lọc đang bật (không tính từ khoá và sắp xếp).
  int get activeCount =>
      (conditions.isEmpty ? 0 : 1) +
      (minPrice == null && maxPrice == null ? 0 : 1);

  bool matches(Book b) =>
      (conditions.isEmpty || conditions.contains(b.condition)) &&
      (minPrice == null || b.price >= minPrice!) &&
      (maxPrice == null || b.price <= maxPrice!);

  /// Lọc + sắp xếp. Giữ nguyên thứ tự backend (mới nhất) khi sort = newest.
  List<Book> apply(List<Book> books) {
    final result = books.where(matches).toList();
    switch (sort) {
      case BookSort.newest:
        break;
      case BookSort.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case BookSort.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
    }
    return result;
  }
}
