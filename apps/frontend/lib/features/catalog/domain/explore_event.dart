import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Các sự kiện hiện ở đầu trang Khám phá. Tất cả dựng từ danh sách tin đang bán, không cần backend riêng.
enum ExploreEventKind {
  /// Đồng giá: sách từ [cheapEventMaxPrice] trở xuống.
  cheap,

  /// Sách xuất bản trước [rareEventBeforeYear].
  rare,

  /// Sách tình trạng Mới / Như mới.
  likeNew,

  /// Tiểu thuyết Việt Nam (thể loại [vietnameseNovelCategory]).
  vnClassics,

  /// Tác giả có nhiều sách đang bán nhất (từ [authorEventMinBooks] cuốn).
  author,
}

/// Mức giá "đồng giá" của sự kiện giá tốt.
const cheapEventMaxPrice = 50000;

/// Sách xuất bản trước năm này thuộc sự kiện "Sách hiếm".
const rareEventBeforeYear = 1975;

/// Tên thể loại của sự kiện "Văn học Việt Nam kinh điển".
const vietnameseNovelCategory = 'Tiểu thuyết Việt Nam';

/// Tác giả phải có ít nhất bấy nhiêu cuốn đang bán mới thành sự kiện.
const authorEventMinBooks = 2;

/// Số tin tối đa mỗi sự kiện.
const exploreEventLimit = 12;

class ExploreEvent {
  const ExploreEvent({
    required this.kind,
    required this.listings,
    this.authorName,
  });

  final ExploreEventKind kind;
  final List<Listing> listings;

  /// Chỉ có ở sự kiện [ExploreEventKind.author].
  final String? authorName;

  int get count => listings.length;

  /// Giá thấp nhất trong các tin của sự kiện.
  int get minPrice =>
      listings.map((l) => l.price).reduce((a, b) => a < b ? a : b);
}

/// Dựng danh sách sự kiện từ các tin đang bán. Sự kiện không có tin nào thì bỏ qua.
/// Thứ tự: đồng giá, sách hiếm, như mới, văn học Việt Nam, tác giả nổi bật.
List<ExploreEvent> buildExploreEvents(List<Listing> listings) {
  final buyable = [
    for (final l in listings)
      if (l.purchasable) l,
  ];
  final events = <ExploreEvent>[];

  void add(
    ExploreEventKind kind,
    List<Listing> items, {
    String? authorName,
    int minItems = 1,
  }) {
    if (items.length < minItems) return;
    events.add(
      ExploreEvent(
        kind: kind,
        listings: items.take(exploreEventLimit).toList(),
        authorName: authorName,
      ),
    );
  }

  // A3. Đồng giá: rẻ nhất trước.
  add(
    ExploreEventKind.cheap,
    [
      for (final l in buyable)
        if (l.price <= cheapEventMaxPrice) l,
    ]..sort((a, b) => a.price.compareTo(b.price)),
  );

  // A4. Sách hiếm: có năm xuất bản trước 1975, cũ nhất trước.
  add(
    ExploreEventKind.rare,
    [
      for (final l in buyable)
        if (l.book.publishYear != null &&
            l.book.publishYear! < rareEventBeforeYear)
          l,
    ]..sort((a, b) => a.book.publishYear!.compareTo(b.book.publishYear!)),
  );

  // A7. Như mới: tình trạng Mới hoặc Như mới, mới lên kệ trước.
  add(
    ExploreEventKind.likeNew,
    [
      for (final l in buyable)
        if (l.book.condition == ConditionGrade.brandNew ||
            l.book.condition == ConditionGrade.likeNew)
          l,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  // A9. Văn học Việt Nam.
  add(ExploreEventKind.vnClassics, [
    for (final l in buyable)
      if (l.book.categoryName == vietnameseNovelCategory) l,
  ]);

  // A11. Tác giả có nhiều sách đang bán nhất (hoà thì theo tên cho ổn định).
  final byAuthor = <String, List<Listing>>{};
  for (final l in buyable) {
    final name = l.book.author.trim();
    if (name.isEmpty) continue;
    byAuthor.putIfAbsent(name, () => []).add(l);
  }
  final authors =
      byAuthor.entries
          .where((e) => e.value.length >= authorEventMinBooks)
          .toList()
        ..sort((a, b) {
          final byCount = b.value.length.compareTo(a.value.length);
          return byCount != 0 ? byCount : a.key.compareTo(b.key);
        });
  if (authors.isNotEmpty) {
    add(
      ExploreEventKind.author,
      authors.first.value,
      authorName: authors.first.key,
    );
  }

  return events;
}
