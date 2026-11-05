import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';

void main() {
  test('tìm kiếm không phân biệt dấu tiếng Việt', () {
    final store = FakeStore();
    List<String> titles(String q) => store
        .searchListings(ListingQuery(q: q))
        .items
        .map((l) => l.book.title)
        .toList();

    expect(titles('so do'), contains('Số Đỏ'));
    expect(titles('SỐ ĐỎ'), contains('Số Đỏ'));
    expect(titles('Sổ Đỏ'), contains('Số Đỏ'));
    expect(titles('tat den'), contains('Tắt Đèn'));
    expect(titles('khong co sach nay'), isEmpty);
  });
}
