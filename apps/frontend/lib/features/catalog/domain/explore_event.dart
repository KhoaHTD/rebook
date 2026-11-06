import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Các bộ sưu tập ("sự kiện") ở trang Khám phá. Tất cả dựng từ danh sách tin đang bán, không cần backend riêng.
enum ExploreEventKind {
  /// Top yêu thích: nhiều lượt thả tim nhất.
  top,

  /// Dành cho bạn: cùng thể loại với sách đã thả tim (chỉ khi đã đăng nhập và có sách yêu thích).
  forYou,

  /// Xuất bản từ [newReleaseFromYear].
  newRelease,

  /// Giá tốt: từ [cheapEventMaxPrice] trở xuống.
  cheap,

  /// Sách tình trạng Mới / Như mới.
  likeNew,

  /// Thể loại [classicsCategory].
  classics,

  /// Bộ theo chủ đề ([ExploreTheme]).
  theme,

  /// Đọc nhanh: dưới [quickReadMaxPages] trang.
  quickRead,

  /// Sách dày: từ [thickMinPages] trang.
  thick,

  /// Tác giả có nhiều sách đang bán.
  author,

  /// Nhà xuất bản có nhiều sách đang bán.
  publisher,
}

/// Chủ đề của sự kiện [ExploreEventKind.theme]; mỗi chủ đề gom theo tên thể loại (cả sách thuộc thể loại con).
enum ExploreTheme {
  humor({'Hài hước'}),
  memoir({'Hồi ký – Tự truyện', 'Chân dung nhân vật'}),
  gothic({'Trinh thám – Kinh dị'}),
  food({'Ẩm thực – Nấu ăn'}),
  selfHelp({'Phát triển bản thân', 'Tâm lý học'});

  const ExploreTheme(this.categoryNames);

  /// Sách thuộc thể loại có tên này (hoặc thể loại con của nó) thì thuộc chủ đề.
  final Set<String> categoryNames;
}

/// Mức giá của bộ "Giá tốt".
const cheapEventMaxPrice = 200000;

/// Sách xuất bản từ năm này thuộc bộ "Mới ra mắt".
const newReleaseFromYear = 2025;

/// "Đọc nhanh" (dưới số trang này) và "Sách dày" (từ số trang này).
const quickReadMaxPages = 250;
const thickMinPages = 500;

/// Tên thể loại của bộ "Kinh điển".
const classicsCategory = 'Văn học kinh điển';

/// Tác giả / nhà xuất bản phải có ít nhất bấy nhiêu cuốn mới thành bộ, và hiện tối đa bấy nhiêu bộ.
const authorEventMinBooks = 2;
const authorEventMax = 3;
const publisherEventMinBooks = 4;
const publisherEventMax = 2;

/// Các bộ khác phải có ít nhất bấy nhiêu cuốn mới hiện (bộ quá ít sách trông lẻ loi).
const exploreEventMinBooks = 3;

/// Số cuốn của Top yêu thích.
const topEventSize = 10;

/// Số tin tối đa giữ trong mỗi bộ.
const exploreEventLimit = 30;

class ExploreEvent {
  const ExploreEvent({
    required this.kind,
    required this.listings,
    this.subject,
    this.theme,
  });

  final ExploreEventKind kind;
  final List<Listing> listings;

  /// Tên tác giả / nhà xuất bản của bộ [ExploreEventKind.author] / [ExploreEventKind.publisher].
  final String? subject;

  /// Chủ đề của bộ [ExploreEventKind.theme].
  final ExploreTheme? theme;

  int get count => listings.length;

  /// Giá thấp nhất trong các tin của bộ.
  int get minPrice =>
      listings.map((l) => l.price).reduce((a, b) => a < b ? a : b);

  /// Khoá duy nhất của bộ, dùng trong đường dẫn: `top`, `author:John Steinbeck`, `theme:humor`…
  String get key => switch (kind) {
    ExploreEventKind.author ||
    ExploreEventKind.publisher => '${kind.name}:$subject',
    ExploreEventKind.theme => 'theme:${theme!.name}',
    _ => kind.name,
  };
}

/// Dựng các bộ sưu tập từ tin đang bán. Bộ không đủ sách thì bỏ qua.
///
/// [categories]: cây thể loại (để gom theo chủ đề / thể loại cha). [favorites]: sách người dùng đã thả tim (cho "Dành cho bạn").
/// Thứ tự: Top yêu thích, Dành cho bạn, Mới ra mắt, Giá tốt, Như mới, Kinh điển, các chủ đề, Đọc nhanh, Sách dày,
/// tác giả nổi bật, nhà xuất bản nổi bật.
List<ExploreEvent> buildExploreEvents(
  List<Listing> listings, {
  List<Category> categories = const [],
  List<Listing> favorites = const [],
}) {
  final buyable = [
    for (final l in listings)
      if (l.purchasable) l,
  ];
  final byId = {for (final c in categories) c.id: c};

  /// Tên thể loại của sách và của thể loại cha (nếu có).
  Set<String> namesOf(Listing l) {
    final c = byId[l.book.categoryId];
    if (c == null) return const {};
    final parent = c.parentId == null ? null : byId[c.parentId];
    return {c.name, ?parent?.name};
  }

  int byPopular(Listing a, Listing b) {
    final fav = b.favoriteCount.compareTo(a.favoriteCount);
    return fav != 0 ? fav : b.createdAt.compareTo(a.createdAt);
  }

  final events = <ExploreEvent>[];
  void add(
    ExploreEventKind kind,
    List<Listing> items, {
    String? subject,
    ExploreTheme? theme,
    int minItems = exploreEventMinBooks,
  }) {
    if (items.length < minItems) return;
    events.add(
      ExploreEvent(
        kind: kind,
        listings: items.take(exploreEventLimit).toList(),
        subject: subject,
        theme: theme,
      ),
    );
  }

  // Top yêu thích: chỉ tính sách đã có người thả tim.
  add(
    ExploreEventKind.top,
    ([
      for (final l in buyable)
        if (l.favoriteCount > 0) l,
    ]..sort(byPopular)).take(topEventSize).toList(),
  );

  // Dành cho bạn: cùng thể loại (hoặc cùng nhóm cha) với sách đã thả tim, trừ chính các sách đó.
  if (favorites.isNotEmpty) {
    final likedIds = {for (final f in favorites) f.id};
    final likedCats = <String>{};
    for (final f in favorites) {
      final id = f.book.categoryId;
      if (id == null) continue;
      likedCats.add(id);
      final parent = byId[id]?.parentId;
      if (parent != null) likedCats.add(parent);
    }
    add(
      ExploreEventKind.forYou,
      [
        for (final l in buyable)
          if (!likedIds.contains(l.id) &&
              l.book.categoryId != null &&
              (likedCats.contains(l.book.categoryId) ||
                  likedCats.contains(byId[l.book.categoryId]?.parentId)))
            l,
      ]..sort(byPopular),
    );
  }

  add(
    ExploreEventKind.newRelease,
    [
      for (final l in buyable)
        if ((l.book.publishYear ?? 0) >= newReleaseFromYear) l,
    ]..sort((a, b) {
      final y = (b.book.publishYear ?? 0).compareTo(a.book.publishYear ?? 0);
      return y != 0 ? y : b.createdAt.compareTo(a.createdAt);
    }),
  );

  add(
    ExploreEventKind.cheap,
    [
      for (final l in buyable)
        if (l.price <= cheapEventMaxPrice) l,
    ]..sort((a, b) => a.price.compareTo(b.price)),
  );

  add(
    ExploreEventKind.likeNew,
    [
      for (final l in buyable)
        if (l.book.condition == ConditionGrade.brandNew ||
            l.book.condition == ConditionGrade.likeNew)
          l,
    ]..sort(byPopular),
  );

  add(
    ExploreEventKind.classics,
    [
      for (final l in buyable)
        if (namesOf(l).contains(classicsCategory)) l,
    ]..sort(byPopular),
  );

  for (final theme in ExploreTheme.values) {
    add(
      ExploreEventKind.theme,
      [
        for (final l in buyable)
          if (namesOf(l).any(theme.categoryNames.contains)) l,
      ]..sort(byPopular),
      theme: theme,
    );
  }

  add(
    ExploreEventKind.quickRead,
    [
      for (final l in buyable)
        if (l.book.pages != null && l.book.pages! < quickReadMaxPages) l,
    ]..sort((a, b) => a.book.pages!.compareTo(b.book.pages!)),
  );

  add(
    ExploreEventKind.thick,
    [
      for (final l in buyable)
        if (l.book.pages != null && l.book.pages! >= thickMinPages) l,
    ]..sort((a, b) => b.book.pages!.compareTo(a.book.pages!)),
  );

  // Tác giả / nhà xuất bản có nhiều sách nhất (hoà thì theo tên cho ổn định).
  void addGroups(
    ExploreEventKind kind,
    String? Function(Listing) nameOf,
    int minBooks,
    int max,
  ) {
    final groups = <String, List<Listing>>{};
    for (final l in buyable) {
      final name = nameOf(l)?.trim();
      if (name == null || name.isEmpty) continue;
      groups.putIfAbsent(name, () => []).add(l);
    }
    final top = groups.entries.where((e) => e.value.length >= minBooks).toList()
      ..sort((a, b) {
        final n = b.value.length.compareTo(a.value.length);
        return n != 0 ? n : a.key.compareTo(b.key);
      });
    for (final e in top.take(max)) {
      add(kind, [...e.value]..sort(byPopular), subject: e.key, minItems: 1);
    }
  }

  addGroups(
    ExploreEventKind.author,
    (l) => l.book.author,
    authorEventMinBooks,
    authorEventMax,
  );
  addGroups(
    ExploreEventKind.publisher,
    (l) => l.book.publisher,
    publisherEventMinBooks,
    publisherEventMax,
  );

  return events;
}
