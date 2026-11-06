import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/catalog/domain/explore_event.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

Listing _listing(
  String id, {
  int price = 100000,
  int? year,
  String author = 'Tác giả',
  String? category,
  ConditionGrade condition = ConditionGrade.good,
  int stock = 3,
  ListingStatus status = ListingStatus.active,
  int ageDays = 30,
}) => Listing(
  id: id,
  book: Book(
    id: id,
    title: 'Sách $id',
    author: author,
    condition: condition,
    publishYear: year,
    categoryName: category,
  ),
  shop: const ShopSummary(id: '1', name: 'Shop', ratingAvg: 4, ratingCount: 1),
  price: price,
  stock: stock,
  status: status,
  createdAt: DateTime(2026, 1, 1).subtract(Duration(days: ageDays)),
);

ExploreEvent? _event(List<ExploreEvent> events, ExploreEventKind kind) =>
    events.where((e) => e.kind == kind).firstOrNull;

List<String> _ids(ExploreEvent? e) => [for (final l in e!.listings) l.id];

void main() {
  test('không có tin nào thì không có sự kiện nào', () {
    expect(buildExploreEvents(const []), isEmpty);
  });

  test('đồng giá: chỉ tin đang bán còn hàng, rẻ nhất trước', () {
    final events = buildExploreEvents([
      _listing('a', price: 45000),
      _listing('b', price: 20000),
      _listing('hidden', price: 10000, status: ListingStatus.hidden),
      _listing('out', price: 10000, stock: 0),
      _listing('dear', price: 80000),
    ]);
    final cheap = _event(events, ExploreEventKind.cheap);
    expect(_ids(cheap), ['b', 'a']);
    expect(cheap!.minPrice, 20000);
  });

  test('sách hiếm: chỉ trước 1975 và có năm xuất bản, cũ nhất trước', () {
    final events = buildExploreEvents([
      _listing('new', year: 2020),
      _listing('none'),
      _listing('b', year: 1960),
      _listing('a', year: 1936),
      _listing('edge', year: 1975),
    ]);
    expect(_ids(_event(events, ExploreEventKind.rare)), ['a', 'b']);
  });

  test('như mới: gồm Mới và Như mới, mới lên kệ trước', () {
    final events = buildExploreEvents([
      _listing('old', condition: ConditionGrade.likeNew, ageDays: 20),
      _listing('fresh', condition: ConditionGrade.brandNew, ageDays: 1),
      _listing('worn', condition: ConditionGrade.acceptable),
    ]);
    expect(_ids(_event(events, ExploreEventKind.likeNew)), ['fresh', 'old']);
  });

  test('văn học Việt Nam: theo tên thể loại tiểu thuyết Việt Nam', () {
    final events = buildExploreEvents([
      _listing('vn', category: vietnameseNovelCategory),
      _listing('foreign', category: 'Văn học nước ngoài'),
      _listing('none'),
    ]);
    expect(_ids(_event(events, ExploreEventKind.vnClassics)), ['vn']);
  });

  test('tác giả nổi bật: nhiều sách nhất, từ 2 cuốn, hoà thì theo tên', () {
    final events = buildExploreEvents([
      _listing('1', author: 'Vũ Trọng Phụng'),
      _listing('2', author: 'Vũ Trọng Phụng'),
      _listing('3', author: 'Nam Cao'),
      _listing('4', author: 'Nam Cao'),
      _listing('5', author: 'Nguyễn Du'),
    ]);
    final e = _event(events, ExploreEventKind.author)!;
    expect(e.authorName, 'Nam Cao');
    expect(_ids(e), ['3', '4']);
    // Mỗi tác giả chỉ một cuốn thì không có sự kiện.
    expect(
      _event(
        buildExploreEvents([
          _listing('a', author: 'A'),
          _listing('b', author: 'B'),
        ]),
        ExploreEventKind.author,
      ),
      isNull,
    );
  });

  test('sự kiện giữ đúng thứ tự và mỗi sự kiện tối đa 12 tin', () {
    final many = [
      for (var i = 0; i < 20; i++)
        _listing(
          'm$i',
          price: 30000,
          year: 1950,
          author: 'Một người',
          category: vietnameseNovelCategory,
          condition: ConditionGrade.likeNew,
        ),
    ];
    final events = buildExploreEvents(many);
    expect(
      [for (final e in events) e.kind],
      [
        ExploreEventKind.cheap,
        ExploreEventKind.rare,
        ExploreEventKind.likeNew,
        ExploreEventKind.vnClassics,
        ExploreEventKind.author,
      ],
    );
    expect(events.every((e) => e.count == exploreEventLimit), isTrue);
  });
}
