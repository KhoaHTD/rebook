import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/catalog/domain/book_search_filter.dart';
import 'package:book_marketplace/shared/data/fake_books.dart';
import 'package:book_marketplace/shared/domain/book.dart';

void main() {
  test('không lọc gì thì giữ nguyên danh sách và thứ tự', () {
    expect(const BookSearchFilter().apply(fakeBooks), fakeBooks);
    expect(const BookSearchFilter().activeCount, 0);
  });

  test('lọc theo tình trạng', () {
    final result = const BookSearchFilter(conditions: {BookCondition.likeNew})
        .apply(fakeBooks);
    expect(result, isNotEmpty);
    expect(result.every((b) => b.condition == BookCondition.likeNew), isTrue);
  });

  test('lọc theo khoảng giá và sắp xếp giá tăng dần', () {
    const filter = BookSearchFilter(
      minPrice: 40000,
      maxPrice: 60000,
      sort: BookSort.priceAsc,
    );
    final prices = filter.apply(fakeBooks).map((b) => b.price).toList();
    expect(prices, [40000, 45000, 55000, 60000]);
    expect(filter.activeCount, 1);
  });

  test('sắp xếp giá giảm dần', () {
    final prices = const BookSearchFilter(sort: BookSort.priceDesc)
        .apply(fakeBooks)
        .map((b) => b.price)
        .toList();
    expect(prices.first, 350000);
    expect(prices, [...prices]..sort((a, b) => b.compareTo(a)));
  });
}
