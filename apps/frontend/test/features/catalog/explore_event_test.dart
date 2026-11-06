import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/catalog/domain/explore_event.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

const _cats = [
  Category(id: 'lit', name: 'Văn học'),
  Category(id: 'classic', name: classicsCategory, parentId: 'lit'),
  Category(id: 'food', name: 'Ẩm thực – Nấu ăn'),
  Category(id: 'home-cook', name: 'Nấu ăn gia đình', parentId: 'food'),
  Category(id: 'humor', name: 'Hài hước'),
];

Listing _listing(
  String id, {
  int price = 300000,
  int? year,
  int? pages,
  String author = 'Tác giả',
  String? publisher,
  String? categoryId,
  int favorites = 0,
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
    pages: pages,
    publisher: publisher,
    categoryId: categoryId,
  ),
  shop: const ShopSummary(id: '1', name: 'Shop', ratingAvg: 4, ratingCount: 1),
  price: price,
  stock: stock,
  status: status,
  favoriteCount: favorites,
  createdAt: DateTime(2026, 1, 1).subtract(Duration(days: ageDays)),
);

List<ExploreEvent> _of(ExploreEventKind kind, List<ExploreEvent> events) =>
    events.where((e) => e.kind == kind).toList();

ExploreEvent? _event(List<ExploreEvent> events, ExploreEventKind kind) =>
    _of(kind, events).firstOrNull;

List<String> _ids(ExploreEvent? e) => [for (final l in e!.listings) l.id];

void main() {
  test('không có tin nào thì không có bộ sưu tập nào', () {
    expect(buildExploreEvents(const []), isEmpty);
  });

  test('bộ quá ít sách (dưới 3) thì bỏ qua', () {
    final events = buildExploreEvents([
      _listing('a', price: 100000),
      _listing('b', price: 120000),
    ]);
    expect(_event(events, ExploreEventKind.cheap), isNull);
  });

  test(
    'Top yêu thích: chỉ sách có lượt thích, nhiều nhất trước, tối đa 10',
    () {
      final events = buildExploreEvents([
        _listing('none'),
        for (var i = 0; i < 12; i++) _listing('f$i', favorites: 12 - i),
      ]);
      final top = _event(events, ExploreEventKind.top)!;
      expect(top.count, topEventSize);
      expect(_ids(top).first, 'f0');
      expect(_ids(top), isNot(contains('none')));
    },
  );

  test('Giá tốt: từ ngưỡng trở xuống, rẻ nhất trước', () {
    final events = buildExploreEvents([
      _listing('a', price: 190000),
      _listing('b', price: 90000),
      _listing('c', price: 150000),
      _listing('d', price: cheapEventMaxPrice + 1000),
    ]);
    expect(_ids(_event(events, ExploreEventKind.cheap)), ['b', 'c', 'a']);
  });

  test('Mới ra mắt, Đọc nhanh và Sách dày theo năm / số trang', () {
    final events = buildExploreEvents([
      for (var i = 0; i < 3; i++)
        _listing('n$i', year: newReleaseFromYear + (i % 2), pages: 100 + i),
      for (var i = 0; i < 3; i++) _listing('t$i', year: 2010, pages: 600 + i),
      _listing('old', year: 1999, pages: 300),
    ]);
    expect(_ids(_event(events, ExploreEventKind.newRelease)).length, 3);
    expect(
      _ids(_event(events, ExploreEventKind.newRelease)),
      isNot(contains('old')),
    );
    expect(_ids(_event(events, ExploreEventKind.quickRead)), [
      'n0',
      'n1',
      'n2',
    ]);
    expect(_ids(_event(events, ExploreEventKind.thick)), ['t2', 't1', 't0']);
  });

  test('Như mới: tình trạng Mới và Như mới', () {
    final events = buildExploreEvents([
      _listing('a', condition: ConditionGrade.brandNew),
      _listing('b', condition: ConditionGrade.likeNew),
      _listing('c', condition: ConditionGrade.likeNew),
      _listing('d', condition: ConditionGrade.good),
    ]);
    expect(_ids(_event(events, ExploreEventKind.likeNew)).toSet(), {
      'a',
      'b',
      'c',
    });
  });

  test('Kinh điển và chủ đề gom cả sách thuộc thể loại con', () {
    final events = buildExploreEvents([
      for (var i = 0; i < 3; i++) _listing('k$i', categoryId: 'classic'),
      for (var i = 0; i < 3; i++) _listing('c$i', categoryId: 'home-cook'),
      for (var i = 0; i < 3; i++) _listing('h$i', categoryId: 'humor'),
    ], categories: _cats);
    expect(_ids(_event(events, ExploreEventKind.classics)).length, 3);
    final themes = _of(ExploreEventKind.theme, events);
    expect(
      {for (final t in themes) t.theme},
      {ExploreTheme.food, ExploreTheme.humor},
    );
    final food = themes.firstWhere((t) => t.theme == ExploreTheme.food);
    expect(_ids(food).toSet(), {'c0', 'c1', 'c2'});
    expect(food.key, 'theme:food');
  });

  test(
    'Tác giả / nhà xuất bản nổi bật: nhiều sách nhất trước, tối đa mỗi loại',
    () {
      final events = buildExploreEvents([
        for (var i = 0; i < 3; i++)
          _listing('s$i', author: 'Steinbeck', publisher: 'Penguin'),
        for (var i = 0; i < 2; i++)
          _listing('j$i', author: 'Jackson', publisher: 'Penguin'),
        _listing('x', author: 'Solo', publisher: 'Penguin'),
        _listing('y', author: 'Other', publisher: 'Penguin'),
      ]);
      final authors = _of(ExploreEventKind.author, events);
      expect([for (final a in authors) a.subject], ['Steinbeck', 'Jackson']);
      expect(authors.first.key, 'author:Steinbeck');
      final publishers = _of(ExploreEventKind.publisher, events);
      expect(publishers.single.subject, 'Penguin');
      expect(publishers.single.count, 7);
    },
  );

  test(
    'Dành cho bạn: cùng thể loại với sách đã thả tim, trừ chính sách đó',
    () {
      final liked = _listing('liked', categoryId: 'humor');
      final events = buildExploreEvents(
        [
          liked,
          for (var i = 0; i < 3; i++) _listing('h$i', categoryId: 'humor'),
          _listing('other', categoryId: 'classic'),
        ],
        categories: _cats,
        favorites: [liked],
      );
      final forYou = _event(events, ExploreEventKind.forYou)!;
      expect(_ids(forYou).toSet(), {'h0', 'h1', 'h2'});
      // Chưa có sách yêu thích thì không có bộ này.
      expect(
        _event(
          buildExploreEvents([liked], categories: _cats),
          ExploreEventKind.forYou,
        ),
        isNull,
      );
    },
  );

  test('chỉ tính sách mua được (đang bán, còn hàng)', () {
    final events = buildExploreEvents([
      _listing('a', price: 90000),
      _listing('b', price: 90000),
      _listing('c', price: 90000),
      _listing('gone', price: 90000, stock: 0),
      _listing('hidden', price: 90000, status: ListingStatus.hidden),
    ]);
    expect(_ids(_event(events, ExploreEventKind.cheap)).toSet(), {
      'a',
      'b',
      'c',
    });
  });
}
