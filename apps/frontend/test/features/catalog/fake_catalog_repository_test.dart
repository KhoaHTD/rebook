import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/catalog/data/fake_catalog_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

void main() {
  late FakeStore store;
  late FakeCatalogRepository repo;

  setUp(() {
    store = FakeStore();
    repo = FakeCatalogRepository(store);
  });
  tearDown(() => store.dispose());

  test('feed có sách thịnh hành, sách mới và phiên LIVE', () async {
    final feed = await repo.homeFeed();
    expect(feed.trending, isNotEmpty);
    expect(feed.newArrivals, isNotEmpty);
    expect(feed.liveSessions.every((s) => s.isLive), isTrue);
  });

  test('tìm theo tên và sắp xếp giá tăng dần', () async {
    final all = await repo.search(
      const ListingQuery(sort: ListingSort.priceAsc),
    );
    final prices = all.items.map((l) => l.price).toList();
    expect(prices, [...prices]..sort());

    final hit = await repo.search(const ListingQuery(q: 'mắt biếc'));
    expect(hit.items.single.book.title, 'Mắt Biếc');
  });

  test('lọc theo tình trạng và khoảng giá', () async {
    final page = await repo.search(
      const ListingQuery(
        condition: ConditionGrade.likeNew,
        minPrice: 50000,
        maxPrice: 200000,
      ),
    );
    for (final l in page.items) {
      expect(l.book.condition, ConditionGrade.likeNew);
      expect(l.price, inInclusiveRange(50000, 200000));
    }
  });

  test('thêm vào giỏ cần đăng nhập', () async {
    await expectLater(repo.addToCart('l1', 1), throwsA(anything));
    store.login('khoa@rebook.vn', '123456');
    await repo.addToCart('l1', 1);
    expect(store.cart().itemCount, 1);
  });
}
