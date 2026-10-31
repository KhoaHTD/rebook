import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/catalog/presentation/providers/recent_searches.dart';

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  List<String> read() => container.read(recentSearchesProvider);
  RecentSearches ctrl() => container.read(recentSearchesProvider.notifier);

  test(
    'từ khóa mới nằm đầu, trùng (không phân biệt hoa thường) thì dồn lên đầu',
    () {
      ctrl()
        ..add('Atomic Habits')
        ..add('Don Norman')
        ..add('atomic habits');
      expect(read(), ['atomic habits', 'Don Norman']);
    },
  );

  test('bỏ qua từ rỗng, chỉ giữ tối đa 8', () {
    ctrl().add('   ');
    expect(read(), isEmpty);
    for (var i = 0; i < 12; i++) {
      ctrl().add('q$i');
    }
    expect(read(), hasLength(RecentSearches.maxItems));
    expect(read().first, 'q11');
  });

  test('xóa một từ và xóa tất cả', () {
    ctrl()
      ..add('a')
      ..add('b');
    ctrl().remove('a');
    expect(read(), ['b']);
    ctrl().clear();
    expect(read(), isEmpty);
  });
}
