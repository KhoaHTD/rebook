import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_searches.g.dart';

/// Các từ khóa vừa tìm (mới nhất trước, tối đa 8), hiện thành chip ở trang Khám phá.
/// Chỉ nhớ trong phiên chạy.
@Riverpod(keepAlive: true)
class RecentSearches extends _$RecentSearches {
  static const maxItems = 8;

  @override
  List<String> build() => const [];

  void add(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    state = [
      t,
      for (final x in state)
        if (x.toLowerCase() != t.toLowerCase()) x,
    ].take(maxItems).toList();
  }

  void remove(String text) => state = [
    for (final x in state)
      if (x != text) x,
  ];

  void clear() => state = const [];
}
